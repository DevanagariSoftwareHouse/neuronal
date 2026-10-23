//! a00_first_look — egui viewer for the neuronal BIN catalog (data/raw/*).
//!
//!   cargo run -p a00_first_look --release -- [REPO_ROOT]
//!   cargo run -p a00_first_look --release -- [REPO_ROOT] --dump
//!   cargo run -p a00_first_look --release -- [REPO_ROOT] --record 00003 [--tab waveforms|files]
//!
//! REPO_ROOT is the folder holding `data/` (default: $NEURONAL_ROOT, else the
//! first ancestor of the cwd that has `data/raw`). `--dump` validates every
//! file and prints a summary without opening a window.

mod catalog;
mod store;

use std::collections::{BTreeMap, HashMap};
use std::path::{Path, PathBuf};

use eframe::egui;
use egui_plot::{Legend, Line, Plot, PlotPoints, Points};

use catalog::{Loaded, Provenance, Record};
use store::BinMap;

fn main() -> eframe::Result<()> {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let dump = args.iter().any(|a| a == "--dump");
    let flag = |name: &str| {
        args.iter()
            .position(|a| a == name)
            .and_then(|i| args.get(i + 1))
            .cloned()
    };
    let record = flag("--record");
    let tab_arg = flag("--tab");
    let tab = match tab_arg.as_deref() {
        Some("waveforms") => Tab::Waveforms,
        Some("files") => Tab::Files,
        _ => Tab::Signals,
    };
    let values: Vec<&String> = [&record, &tab_arg].into_iter().flatten().collect();
    let root = args
        .iter()
        .find(|a| !a.starts_with("--") && !values.iter().any(|v| v == a))
        .map(PathBuf::from)
        .or_else(|| std::env::var_os("NEURONAL_ROOT").map(PathBuf::from))
        .or_else(find_root)
        .unwrap_or_else(|| PathBuf::from("."));

    if dump {
        dump_all(&root);
        return Ok(());
    }

    eframe::run_native(
        "neuronal · first look",
        eframe::NativeOptions {
            viewport: egui::ViewportBuilder::default().with_inner_size([1400.0, 900.0]),
            ..Default::default()
        },
        Box::new(move |_cc| {
            let mut app = App::new(root);
            app.tab = tab;
            if let Some(id) = record {
                if let Some(i) = app.loaded.records.iter().position(|r| r.id == id) {
                    app.open(i);
                }
            }
            Ok(Box::new(app))
        }),
    )
}

fn find_root() -> Option<PathBuf> {
    let cwd = std::env::current_dir().ok()?;
    cwd.ancestors()
        .find(|p| p.join("data/raw").is_dir())
        .map(Path::to_path_buf)
}

fn dump_all(root: &Path) {
    let loaded = catalog::load(root);
    println!("{}", loaded.note);
    for r in &loaded.records {
        println!("\n{} {} ({:?})", r.dataset, r.id, r.provenance);
        for d in &r.files {
            let status = match BinMap::open(d.clone()) {
                Ok(m) => {
                    let first = m.read(0..3.min(m.rows()), 0);
                    format!("ok  first={first:.4?}")
                }
                Err(e) => format!("ERR {e}"),
            };
            println!(
                "  {:<14} {:<6} {:>10} x {:<5} fs={:<8} {status}",
                d.name,
                d.dtype.matlab(),
                d.shape[0],
                d.shape[1],
                d.sampling_rate_hz.map_or("—".into(), |f| format!("{f}")),
            );
        }
        if let Some(s) = Spikes::open(r) {
            match s {
                Ok(s) => println!(
                    "  spikes: n={} clusters={} t∈[{:.4}, {:.4}] (raw units) sorted={}",
                    s.t.len(),
                    s.clusters.len(),
                    s.t_min,
                    s.t_max,
                    s.was_sorted
                ),
                Err(e) => println!("  spikes: ERR {e}"),
            }
        }
    }
}

// ───────────────────────────── spikes ─────────────────────────────

struct Spikes {
    /// Raw spike_time values (units unknown in the catalog; default seconds).
    t: Vec<f64>,
    cluster: Vec<i32>,
    /// Sorted unique cluster ids -> raster row.
    clusters: Vec<i32>,
    rank: HashMap<i32, usize>,
    count: BTreeMap<i32, usize>,
    t_min: f64,
    t_max: f64,
    was_sorted: bool,
}

impl Spikes {
    fn open(r: &Record) -> Option<Result<Self, String>> {
        let td = r.file("spike_time")?.clone();
        let cd = r.file("spike_cluster")?.clone();
        Some((|| {
            let t = BinMap::open(td)?.column(0);
            let c: Vec<i32> = BinMap::open(cd)?.column(0).into_iter().map(|v| v as i32).collect();
            if t.len() != c.len() {
                return Err(format!("{} times vs {} clusters", t.len(), c.len()));
            }
            let was_sorted = t.windows(2).all(|w| w[0] <= w[1]);
            let (t, cluster) = if was_sorted {
                (t, c)
            } else {
                let mut idx: Vec<usize> = (0..t.len()).collect();
                idx.sort_by(|&a, &b| t[a].total_cmp(&t[b]));
                (idx.iter().map(|&i| t[i]).collect(), idx.iter().map(|&i| c[i]).collect())
            };
            let mut count = BTreeMap::new();
            for &k in &cluster {
                *count.entry(k).or_insert(0) += 1;
            }
            let clusters: Vec<i32> = count.keys().copied().collect();
            let rank = clusters.iter().enumerate().map(|(i, &k)| (k, i)).collect();
            Ok(Self {
                t_min: t.first().copied().unwrap_or(0.0),
                t_max: t.last().copied().unwrap_or(0.0),
                t,
                cluster,
                clusters,
                rank,
                count,
                was_sorted,
            })
        })())
    }
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum TimeUnit {
    Seconds,
    Millis,
    Samples30k,
}

impl TimeUnit {
    fn to_seconds(self) -> f64 {
        match self {
            Self::Seconds => 1.0,
            Self::Millis => 1e-3,
            Self::Samples30k => 1.0 / 30_000.0,
        }
    }
    fn label(self) -> &'static str {
        match self {
            Self::Seconds => "s",
            Self::Millis => "ms",
            Self::Samples30k => "samples @ 30 kHz",
        }
    }
}

// ───────────────────────────── app ─────────────────────────────

#[derive(Clone, Copy, PartialEq, Eq)]
enum Tab {
    Signals,
    Waveforms,
    Files,
}

struct Opened {
    record: Record,
    /// name -> map (or why it failed)
    maps: BTreeMap<String, Result<BinMap, String>>,
    spikes: Option<Result<Spikes, String>>,
}

impl Opened {
    fn new(record: Record) -> Self {
        let maps = record
            .files
            .iter()
            .filter(|d| d.name != "spike_time" && d.name != "spike_cluster")
            .map(|d| (d.name.clone(), BinMap::open(d.clone())))
            .collect();
        let spikes = Spikes::open(&record);
        Self { record, maps, spikes }
    }

    fn remap(&mut self, name: &str, cols: usize) -> Result<(), String> {
        let d = self.record.file(name).ok_or("no such file")?;
        let d = catalog::reshape(d, cols)?;
        let m = BinMap::open(d.clone())?;
        if let Some(slot) = self.record.files.iter_mut().find(|x| x.name == name) {
            *slot = d;
        }
        self.maps.insert(name.into(), Ok(m));
        Ok(())
    }
}

/// Key for the cached LFP envelope.
#[derive(Clone, PartialEq)]
struct ViewKey {
    record: String,
    file: String,
    shape: [usize; 2],
    rows: (usize, usize),
    chans: (usize, usize),
    buckets: usize,
}

struct App {
    root: String,
    loaded: Loaded,
    selected: Option<usize>,
    opened: Option<Opened>,
    tab: Tab,

    lfp_file: String,
    start_s: f64,
    window_s: f64,
    chan_from: usize,
    chan_to: usize,
    spacing: f64,
    auto_spacing: bool,
    guess_cols: usize,
    reshape_msg: String,
    cache: Option<(ViewKey, Vec<Vec<[f64; 2]>>, f64)>,

    spike_unit: TimeUnit,
    show_raster: bool,

    wf_units: Vec<usize>,
    wf_guess_cols: usize,
}

impl App {
    fn new(root: PathBuf) -> Self {
        let loaded = catalog::load(&root);
        Self {
            root: root.display().to_string(),
            loaded,
            selected: None,
            opened: None,
            tab: Tab::Signals,
            lfp_file: "lfp_1".into(),
            start_s: 0.0,
            window_s: 10.0,
            chan_from: 0,
            chan_to: 7,
            spacing: 1.0,
            auto_spacing: true,
            guess_cols: 16,
            reshape_msg: String::new(),
            cache: None,
            spike_unit: TimeUnit::Seconds,
            show_raster: true,
            wf_units: vec![0],
            wf_guess_cols: 1,
        }
    }

    fn reload(&mut self) {
        self.loaded = catalog::load(Path::new(&self.root));
        self.selected = None;
        self.opened = None;
        self.cache = None;
    }

    fn open(&mut self, i: usize) {
        self.selected = Some(i);
        let rec = self.loaded.records[i].clone();
        let o = Opened::new(rec);
        if !o.maps.contains_key(&self.lfp_file) {
            if let Some(n) = o.record.lfp_names().first() {
                self.lfp_file = n.clone();
            }
        }
        if let Some(d) = o.record.file(&self.lfp_file) {
            self.guess_cols = d.shape[1];
        }
        if let Some(d) = o.record.file("waveforms") {
            self.wf_guess_cols = d.shape[1];
        }
        self.opened = Some(o);
        self.cache = None;
        self.reshape_msg.clear();
    }

    fn side(&mut self, ui: &mut egui::Ui) {
        ui.horizontal(|ui| {
            ui.label("root");
            let r = ui.text_edit_singleline(&mut self.root);
            if ui.button("⟳").clicked() || (r.lost_focus() && ui.input(|i| i.key_pressed(egui::Key::Enter))) {
                self.reload();
            }
        });
        ui.small(&self.loaded.note);
        ui.separator();
        let mut pick = None;
        egui::ScrollArea::vertical().show(ui, |ui| {
            for (i, r) in self.loaded.records.iter().enumerate() {
                let tag = match r.provenance {
                    Provenance::Catalog => "",
                    Provenance::Guessed => " ?",
                };
                let label = if r.source_id.is_empty() {
                    format!("{}{tag}", r.id)
                } else {
                    format!("{}  (animal {}){tag}", r.id, r.source_id)
                };
                if ui.selectable_label(self.selected == Some(i), label).clicked() {
                    pick = Some(i);
                }
            }
        });
        if let Some(i) = pick {
            self.open(i);
        }
    }

    fn signals(&mut self, ui: &mut egui::Ui) {
        let Some(o) = self.opened.as_mut() else {
            ui.label("pick a recording");
            return;
        };

        // ── controls
        let lfps = o.record.lfp_names();
        ui.horizontal_wrapped(|ui| {
            egui::ComboBox::from_label("")
                .selected_text(&self.lfp_file)
                .show_ui(ui, |ui| {
                    for n in &lfps {
                        ui.selectable_value(&mut self.lfp_file, n.clone(), n);
                    }
                });
            let guessed = o.record.provenance == Provenance::Guessed;
            if guessed {
                ui.label("channels");
                ui.add(egui::DragValue::new(&mut self.guess_cols).range(1..=1024));
                if ui.button("reshape").clicked() {
                    self.reshape_msg = match o.remap(&self.lfp_file, self.guess_cols) {
                        Ok(()) => format!("{} → {} channels", self.lfp_file, self.guess_cols),
                        Err(e) => e,
                    };
                    self.cache = None;
                }
                if !self.reshape_msg.is_empty() {
                    ui.small(&self.reshape_msg);
                }
            }
        });

        let map = match o.maps.get(&self.lfp_file) {
            Some(Ok(m)) => m,
            Some(Err(e)) => {
                ui.colored_label(ui.visuals().error_fg_color, e);
                return;
            }
            None => {
                ui.label("no LFP in this recording");
                return;
            }
        };
        let fs = map.desc.sampling_rate_hz.unwrap_or(500.0);
        let duration = map.rows() as f64 / fs;
        let nch = map.cols();
        self.chan_to = self.chan_to.min(nch - 1);
        self.chan_from = self.chan_from.min(self.chan_to);

        ui.horizontal_wrapped(|ui| {
            ui.label(format!(
                "{} x {} {} · {fs} Hz · {:.1} s ({:.1} min)",
                map.rows(),
                nch,
                map.desc.dtype.matlab(),
                duration,
                duration / 60.0
            ));
        });
        ui.horizontal_wrapped(|ui| {
            ui.label("start (s)");
            ui.spacing_mut().slider_width = (ui.available_width() - 320.0).max(160.0);
            ui.add(
                egui::Slider::new(&mut self.start_s, 0.0..=(duration - self.window_s).max(0.0))
                    .clamping(egui::SliderClamping::Always),
            );
            ui.label("window (s)");
            ui.add(egui::DragValue::new(&mut self.window_s).range(0.01..=duration.max(0.01)).speed(0.1));
            if ui.button("◀").clicked() {
                self.start_s = (self.start_s - self.window_s).max(0.0);
            }
            if ui.button("▶").clicked() {
                self.start_s = (self.start_s + self.window_s).min((duration - self.window_s).max(0.0));
            }
        });
        ui.horizontal_wrapped(|ui| {
            ui.label("channels");
            ui.add(egui::DragValue::new(&mut self.chan_from).range(0..=self.chan_to).prefix("from "));
            ui.add(egui::DragValue::new(&mut self.chan_to).range(self.chan_from..=nch - 1).prefix("to "));
            ui.label("(0-based, deep→superficial)");
            ui.checkbox(&mut self.auto_spacing, "auto spacing");
            if !self.auto_spacing {
                ui.add(egui::DragValue::new(&mut self.spacing).speed(0.01).prefix("Δ "));
            }
            ui.checkbox(&mut self.show_raster, "raster");
            if self.show_raster {
                egui::ComboBox::from_id_salt("spike_unit")
                    .selected_text(format!("spike_time in {}", self.spike_unit.label()))
                    .show_ui(ui, |ui| {
                        for u in [TimeUnit::Seconds, TimeUnit::Millis, TimeUnit::Samples30k] {
                            ui.selectable_value(&mut self.spike_unit, u, u.label());
                        }
                    });
            }
        });

        // ── envelope (cached)
        let first = (self.start_s * fs).round() as usize;
        let last = (first + (self.window_s * fs).round() as usize).min(map.rows());
        let buckets = (ui.available_width() as usize).clamp(200, 4000);
        let key = ViewKey {
            record: o.record.id.clone(),
            file: self.lfp_file.clone(),
            shape: map.desc.shape,
            rows: (first, last),
            chans: (self.chan_from, self.chan_to),
            buckets,
        };
        if self.cache.as_ref().map_or(true, |(k, _, _)| *k != key) {
            let mut traces = Vec::new();
            let mut spread = 0.0f64;
            for c in self.chan_from..=self.chan_to {
                let env = map.envelope(first..last, c, buckets);
                let mean = env.iter().map(|p| p.1).sum::<f64>() / env.len().max(1) as f64;
                let var = env.iter().map(|p| (p.1 - mean).powi(2)).sum::<f64>() / env.len().max(1) as f64;
                spread = spread.max(var.sqrt());
                traces.push(env.into_iter().map(|(k, v)| [k as f64 / fs, v - mean]).collect());
            }
            self.cache = Some((key, traces, spread));
        }
        let (_, traces, spread) = self.cache.as_ref().unwrap();
        let step = if self.auto_spacing { (6.0 * spread).max(f64::EPSILON) } else { self.spacing };
        if self.auto_spacing {
            self.spacing = step;
        }

        let t0 = first as f64 / fs;
        let t1 = last as f64 / fs;
        let raster_h = if self.show_raster && o.spikes.is_some() { 220.0 } else { 0.0 };
        let lfp_h = (ui.available_height() - raster_h - 8.0).max(150.0);

        Plot::new("lfp")
            .height(lfp_h)
            .link_axis(egui::Id::unique("time"), [true, false])
            .link_cursor(egui::Id::unique("time"), [true, false])
            .include_x(t0)
            .include_x(t1)
            .x_axis_label("time (s)")
            .y_axis_label("channel (offset, raw units)")
            .show(ui, |pui| {
                for (i, tr) in traces.iter().enumerate() {
                    let ch = self.chan_from + i;
                    let off = -(i as f64) * step;
                    let pts: Vec<[f64; 2]> = tr.iter().map(|p| [p[0], p[1] + off]).collect();
                    pui.line(Line::new(format!("ch {ch}"), PlotPoints::from(pts)).width(1.0));
                }
            });

        if raster_h > 0.0 {
            match o.spikes.as_ref().unwrap() {
                Err(e) => {
                    ui.colored_label(ui.visuals().error_fg_color, format!("spikes: {e}"));
                }
                Ok(s) => {
                    let k = self.spike_unit.to_seconds();
                    let lo = s.t.partition_point(|&t| t * k < t0);
                    let hi = s.t.partition_point(|&t| t * k < t1);
                    const CAP: usize = 200_000;
                    let stride = ((hi - lo) / CAP).max(1);
                    let pts: Vec<[f64; 2]> = (lo..hi)
                        .step_by(stride)
                        .map(|i| [s.t[i] * k, s.rank[&s.cluster[i]] as f64])
                        .collect();
                    let n = pts.len();
                    Plot::new("raster")
                        .height(raster_h)
                        .link_axis(egui::Id::unique("time"), [true, false])
                        .link_cursor(egui::Id::unique("time"), [true, false])
                        .include_x(t0)
                        .include_x(t1)
                        .include_y(-0.5)
                        .include_y(s.clusters.len() as f64 - 0.5)
                        .x_axis_label(format!(
                            "{} spikes in window{} · {} clusters · file range [{:.3}, {:.3}] {}",
                            hi - lo,
                            if stride > 1 { format!(" (1/{stride} drawn)") } else { String::new() },
                            s.clusters.len(),
                            s.t_min,
                            s.t_max,
                            self.spike_unit.label()
                        ))
                        .y_axis_label("cluster rank")
                        .show(ui, |pui| {
                            pui.points(Points::new(format!("{n} spikes"), PlotPoints::from(pts)).radius(1.2));
                        });
                }
            }
        }
    }

    fn waveforms(&mut self, ui: &mut egui::Ui) {
        let Some(o) = self.opened.as_mut() else {
            ui.label("pick a recording");
            return;
        };
        if o.record.provenance == Provenance::Guessed {
            ui.horizontal(|ui| {
                ui.label("units");
                ui.add(egui::DragValue::new(&mut self.wf_guess_cols).range(1..=4096));
                if ui.button("reshape").clicked() {
                    self.reshape_msg = match o.remap("waveforms", self.wf_guess_cols) {
                        Ok(()) => format!("waveforms → {} units", self.wf_guess_cols),
                        Err(e) => e,
                    };
                }
                ui.small(&self.reshape_msg);
            });
        }
        let map = match o.maps.get("waveforms") {
            Some(Ok(m)) => m,
            Some(Err(e)) => {
                ui.colored_label(ui.visuals().error_fg_color, e);
                return;
            }
            None => {
                ui.label("no waveforms.bin");
                return;
            }
        };
        let fs = map.desc.sampling_rate_hz.unwrap_or(30_000.0);
        let units = map.cols();
        self.wf_units.retain(|&u| u < units);
        let clusters: Option<&Vec<i32>> = match &o.spikes {
            Some(Ok(s)) => Some(&s.clusters),
            _ => None,
        };

        ui.label(format!(
            "{} samples x {units} units · {fs} Hz · {:.2} ms per unit{}",
            map.rows(),
            map.rows() as f64 / fs * 1e3,
            match clusters {
                Some(c) if c.len() == units => " · column j ↔ j-th sorted cluster id (assumed)".to_string(),
                Some(c) => format!(" · {} clusters ≠ {units} units: mapping unknown", c.len()),
                None => String::new(),
            }
        ));

        egui::Panel::left("units").resizable(true).default_size(140.0).show(ui, |ui| {
            ui.horizontal(|ui| {
                if ui.small_button("all").clicked() {
                    self.wf_units = (0..units).collect();
                }
                if ui.small_button("none").clicked() {
                    self.wf_units.clear();
                }
            });
            egui::ScrollArea::vertical().show(ui, |ui| {
                for u in 0..units {
                    let mut on = self.wf_units.contains(&u);
                    let label = match clusters {
                        Some(c) if c.len() == units => format!("unit {u} (cl {})", c[u]),
                        _ => format!("unit {u}"),
                    };
                    if ui.checkbox(&mut on, label).changed() {
                        if on {
                            self.wf_units.push(u);
                        } else {
                            self.wf_units.retain(|&x| x != u);
                        }
                    }
                }
            });
        });

        Plot::new("waveforms")
            .legend(Legend::default())
            .x_axis_label("time (ms)")
            .y_axis_label("amplitude (raw units)")
            .show(ui, |pui| {
                for &u in &self.wf_units {
                    let pts: Vec<[f64; 2]> = map
                        .column(u)
                        .into_iter()
                        .enumerate()
                        .map(|(k, v)| [k as f64 / fs * 1e3, v])
                        .collect();
                    pui.line(Line::new(format!("unit {u}"), PlotPoints::from(pts)));
                }
            });
    }

    fn files(&mut self, ui: &mut egui::Ui) {
        let Some(o) = self.opened.as_ref() else {
            ui.label("pick a recording");
            return;
        };
        egui::Grid::new("files").striped(true).show(ui, |ui| {
            for h in ["name", "dtype", "shape", "fs (Hz)", "status", "path"] {
                ui.strong(h);
            }
            ui.end_row();
            for d in &o.record.files {
                ui.label(&d.name);
                ui.label(d.dtype.matlab());
                ui.label(format!("{} x {}", d.shape[0], d.shape[1]));
                ui.label(d.sampling_rate_hz.map_or("—".into(), |f| format!("{f}")));
                let status = match o.maps.get(&d.name) {
                    Some(Ok(_)) => Ok(()),
                    Some(Err(e)) => Err(e.clone()),
                    None => match &o.spikes {
                        Some(Ok(_)) => Ok(()),
                        Some(Err(e)) => Err(e.clone()),
                        None => Err("not opened".into()),
                    },
                };
                match status {
                    Ok(()) => ui.colored_label(egui::Color32::from_rgb(80, 170, 90), "ok"),
                    Err(e) => ui.colored_label(ui.visuals().error_fg_color, e),
                };
                ui.small(d.path.display().to_string());
                ui.end_row();
            }
        });
        if let Some(Ok(s)) = &o.spikes {
            ui.separator();
            ui.label(format!(
                "{} spikes, {} clusters, raw time range [{}, {}]{}",
                s.t.len(),
                s.clusters.len(),
                s.t_min,
                s.t_max,
                if s.was_sorted { "" } else { " — file was NOT time-sorted (sorted in memory)" }
            ));
            egui::ScrollArea::vertical().show(ui, |ui| {
                egui::Grid::new("clusters").striped(true).show(ui, |ui| {
                    ui.strong("cluster");
                    ui.strong("spikes");
                    ui.end_row();
                    for (k, n) in &s.count {
                        ui.label(k.to_string());
                        ui.label(n.to_string());
                        ui.end_row();
                    }
                });
            });
        }
    }
}

impl eframe::App for App {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        egui::Panel::left("records")
            .resizable(true)
            .default_size(260.0)
            .show(ui, |ui| self.side(ui));
        egui::Panel::top("tabs").show(ui, |ui| {
            ui.horizontal(|ui| {
                if let Some(o) = &self.opened {
                    ui.strong(format!("{} {}", o.record.dataset, o.record.id));
                    ui.separator();
                }
                ui.selectable_value(&mut self.tab, Tab::Signals, "LFP + spikes");
                ui.selectable_value(&mut self.tab, Tab::Waveforms, "waveforms");
                ui.selectable_value(&mut self.tab, Tab::Files, "files");
            });
        });
        egui::CentralPanel::default().show(ui, |ui| match self.tab {
            Tab::Signals => self.signals(ui),
            Tab::Waveforms => self.waveforms(ui),
            Tab::Files => self.files(ui),
        });
    }
}
