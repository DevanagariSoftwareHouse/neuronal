//! Recordings and their descriptors: from `data/neuronal/catalog.json`
//! (written by `neuronal_catalog_json.m`), or guessed from `data/raw/*`.

use std::path::{Path, PathBuf};

use serde::Deserialize;

use crate::store::{resolve, Descriptor, Dtype};

#[derive(Deserialize)]
struct JsonCatalog {
    datasets: Vec<JsonDataset>,
}

#[derive(Deserialize)]
struct JsonDataset {
    #[serde(default)]
    alias: String,
    records: Vec<JsonRecord>,
}

#[derive(Deserialize)]
struct JsonRecord {
    id: String,
    #[serde(default)]
    source_id: String,
    files: Vec<JsonFile>,
}

#[derive(Deserialize)]
struct JsonFile {
    #[serde(default)]
    name: String,
    #[serde(default, rename = "type")]
    kind: String,
    path: String,
    dtype: String,
    shape: Vec<f64>,
    #[serde(default = "le")]
    endian: String,
    #[serde(default)]
    offset_bytes: f64,
    #[serde(default)]
    sampling_rate_hz: Option<f64>,
}

fn le() -> String {
    "ieee-le".into()
}

/// Where a recording's descriptors came from.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Provenance {
    Catalog,
    /// Shapes inferred from byte counts; LFP channels/waveform units guessed.
    Guessed,
}

#[derive(Clone, Debug)]
pub struct Record {
    pub dataset: String,
    pub id: String,
    pub source_id: String,
    pub files: Vec<Descriptor>,
    pub provenance: Provenance,
}

impl Record {
    pub fn file(&self, name: &str) -> Option<&Descriptor> {
        self.files.iter().find(|d| d.name == name)
    }

    pub fn lfp_names(&self) -> Vec<String> {
        self.files
            .iter()
            .filter(|d| d.kind == "lfp" || d.name.starts_with("lfp_"))
            .map(|d| d.name.clone())
            .collect()
    }
}

pub struct Loaded {
    pub records: Vec<Record>,
    pub note: String,
}

/// `root` is the neuronal repository root (the folder holding `data/`).
pub fn load(root: &Path) -> Loaded {
    let json = root.join("data/neuronal/catalog.json");
    match std::fs::read_to_string(&json) {
        Ok(text) => match from_json(root, &text) {
            Ok(records) => Loaded {
                note: format!("{} recordings from {}", records.len(), json.display()),
                records,
            },
            Err(e) => {
                let mut l = guess(root);
                l.note = format!("catalog.json unreadable ({e}); {}", l.note);
                l
            }
        },
        Err(_) => guess(root),
    }
}

fn from_json(root: &Path, text: &str) -> Result<Vec<Record>, String> {
    let cat: JsonCatalog = serde_json::from_str(text).map_err(|e| e.to_string())?;
    let mut out = Vec::new();
    for ds in cat.datasets {
        for r in ds.records {
            let mut files = Vec::new();
            for f in r.files {
                if f.endian != "ieee-le" {
                    return Err(format!("{}: only ieee-le supported, got {}", f.path, f.endian));
                }
                let dtype = Dtype::from_matlab(&f.dtype)
                    .ok_or_else(|| format!("{}: unsupported dtype {}", f.path, f.dtype))?;
                let shape = match f.shape.as_slice() {
                    [n] => [*n as usize, 1],
                    [r, c] => [*r as usize, *c as usize],
                    s => return Err(format!("{}: shape {s:?} is not 2-D", f.path)),
                };
                let name = if f.name.is_empty() { stem(&f.path) } else { f.name };
                files.push(Descriptor {
                    path: relocate(root, &r.id, &f.path),
                    kind: f.kind,
                    name,
                    dtype,
                    shape,
                    offset_bytes: f.offset_bytes as usize,
                    sampling_rate_hz: f.sampling_rate_hz.filter(|x| x.is_finite()),
                });
            }
            out.push(Record {
                dataset: ds.alias.clone(),
                id: r.id,
                source_id: r.source_id,
                files,
                provenance: Provenance::Catalog,
            });
        }
    }
    Ok(out)
}

/// Catalog paths may be absolute from another machine/checkout. If the
/// resolved path is missing, look for the same file under `data/raw/<id>/`.
fn relocate(root: &Path, id: &str, path: &str) -> PathBuf {
    let p = resolve(root, path);
    if p.exists() {
        return p;
    }
    let fallback = root.join("data/raw").join(id).join(
        Path::new(&path.replace('\\', "/"))
            .file_name()
            .unwrap_or_default(),
    );
    if fallback.exists() {
        fallback
    } else {
        p
    }
}

fn stem(path: &str) -> String {
    Path::new(&path.replace('\\', "/"))
        .file_stem()
        .map(|s| s.to_string_lossy().into_owned())
        .unwrap_or_default()
}

/// Known CON2PHYS digest outputs (digest/+con2phys/digest.m).
/// LFP: double, samples x channels, 500 Hz. Spikes: double / int32 vectors.
/// Waveforms: single, samples x units, 30 kHz.
pub fn guess(root: &Path) -> Loaded {
    let raw = root.join("data/raw");
    let mut ids: Vec<String> = std::fs::read_dir(&raw)
        .into_iter()
        .flatten()
        .flatten()
        .filter(|e| e.path().is_dir())
        .map(|e| e.file_name().to_string_lossy().into_owned())
        .collect();
    ids.sort();
    let records: Vec<Record> = ids
        .into_iter()
        .map(|id| {
            let dir = raw.join(&id);
            let mut files = Vec::new();
            let size = |n: &str| std::fs::metadata(dir.join(n)).ok().map(|m| m.len() as usize);
            let mut push = |name: &str, kind: &str, dtype: Dtype, shape: [usize; 2], fs: Option<f64>| {
                files.push(Descriptor {
                    name: name.into(),
                    kind: kind.into(),
                    path: dir.join(format!("{name}.bin")),
                    dtype,
                    shape,
                    offset_bytes: 0,
                    sampling_rate_hz: fs,
                })
            };
            for k in 1..=3 {
                let name = format!("lfp_{k}");
                if let Some(b) = size(&format!("{name}.bin")) {
                    // Unknown channel count: start as 1 column; the UI lets
                    // you set channels and reshapes.
                    push(&name, "lfp", Dtype::F64, [b / 8, 1], Some(500.0));
                }
            }
            if let Some(b) = size("spike_time.bin") {
                push("spike_time", "spike_times", Dtype::F64, [b / 8, 1], None);
            }
            if let Some(b) = size("spike_cluster.bin") {
                push("spike_cluster", "spike_clusters", Dtype::I32, [b / 4, 1], None);
            }
            if let Some(b) = size("waveforms.bin") {
                push("waveforms", "waveforms", Dtype::F32, [b / 4, 1], Some(30000.0));
            }
            infer_shapes(&mut files);
            Record {
                dataset: "con2phys".into(),
                id: id.clone(),
                source_id: String::new(),
                files,
                provenance: Provenance::Guessed,
            }
        })
        .collect();
    Loaded {
        note: format!(
            "no catalog.json — {} recordings guessed from {}; set LFP channels / waveform units by hand \
             (or run neuronal_catalog_json('data/neuronal/catalog.mat') in MATLAB)",
            records.len(),
            raw.display()
        ),
        records,
    }
}

fn gcd(a: usize, b: usize) -> usize {
    if b == 0 { a } else { gcd(b, a % b) }
}

/// Best guess at shapes without the catalog:
/// - digest.m asserts the three LFP regions share N samples, so N divides
///   G = gcd(element counts); and the last spike must fall inside the
///   recording, so N >= t_max * fs. Take the smallest divisor of G that
///   satisfies it (exact whenever the channel counts are coprime).
/// - waveforms: samples x units with units = number of distinct clusters,
///   if that divides evenly.
/// Still only a guess: the "?" stays on the record.
pub fn infer_shapes(files: &mut [Descriptor]) {
    let spikes = files
        .iter()
        .find(|d| d.name == "spike_time")
        .and_then(|d| crate::store::BinMap::open(d.clone()).ok())
        .map(|m| m.column(0));
    let clusters = files
        .iter()
        .find(|d| d.name == "spike_cluster")
        .and_then(|d| crate::store::BinMap::open(d.clone()).ok())
        .map(|m| {
            let mut v: Vec<i64> = m.column(0).into_iter().map(|x| x as i64).collect();
            v.sort_unstable();
            v.dedup();
            v.len()
        });

    let lfp: Vec<usize> = files
        .iter()
        .enumerate()
        .filter(|(_, d)| d.kind == "lfp")
        .map(|(i, _)| i)
        .collect();
    if !lfp.is_empty() {
        let totals: Vec<usize> = lfp.iter().map(|&i| files[i].shape[0] * files[i].shape[1]).collect();
        let g = totals.iter().copied().fold(0, gcd);
        let fs = files[lfp[0]].sampling_rate_hz.unwrap_or(500.0);
        let t_max = spikes
            .as_ref()
            .and_then(|t| t.iter().copied().filter(|x| x.is_finite()).reduce(f64::max))
            .unwrap_or(0.0);
        let need = (t_max * fs).floor() as usize;
        // Divisors of g that leave >= 1 channel and cover the spikes.
        let max_c = totals.iter().copied().min().unwrap_or(1).max(1);
        let n = (1..=max_c.min(1024))
            .filter(|c| g % c == 0)
            .map(|c| g / c)
            .filter(|&n| n >= need.max(1))
            .min();
        if let Some(n) = n {
            for (&i, &tot) in lfp.iter().zip(&totals) {
                files[i].shape = [n, tot / n];
            }
        }
    }

    if let (Some(u), Some(w)) = (clusters, files.iter_mut().find(|d| d.name == "waveforms")) {
        let tot = w.shape[0] * w.shape[1];
        if u > 0 && tot % u == 0 {
            w.shape = [tot / u, u];
        }
    }
}

/// Re-split a guessed descriptor into `cols` columns. Fails unless the
/// element count divides evenly.
pub fn reshape(d: &Descriptor, cols: usize) -> Result<Descriptor, String> {
    let total = d.shape[0] * d.shape[1];
    if cols == 0 || total % cols != 0 {
        return Err(format!("{total} values do not split into {cols} columns"));
    }
    let mut out = d.clone();
    out.shape = [total / cols, cols];
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_exporter_output() {
        // Shape of jsonencode output from neuronal_catalog_json.m
        let text = r#"{"schema_version":1,"source":"data/neuronal/catalog.mat","datasets":[
          {"alias":"con2phys","records":[{"id":"00001","source_id":"01","files":[
            {"name":"lfp_1","type":"lfp","path":"data/raw/00001/lfp_1.bin","dtype":"double",
             "shape":[900000,16],"endian":"ieee-le","offset_bytes":0,"sampling_rate_hz":500},
            {"name":"spike_time","type":"spike_times","path":"data/raw/00001/spike_time.bin",
             "dtype":"double","shape":[1234,1],"endian":"ieee-le","offset_bytes":0,
             "sampling_rate_hz":null}]}]}]}"#;
        let recs = from_json(Path::new("/repo"), text).unwrap();
        assert_eq!(recs.len(), 1);
        let lfp = recs[0].file("lfp_1").unwrap();
        assert_eq!(lfp.shape, [900_000, 16]);
        assert_eq!(lfp.dtype, Dtype::F64);
        assert_eq!(lfp.path, PathBuf::from("/repo/data/raw/00001/lfp_1.bin"));
        assert_eq!(recs[0].file("spike_time").unwrap().sampling_rate_hz, None);
        assert_eq!(recs[0].lfp_names(), vec!["lfp_1".to_string()]);
    }

    #[test]
    fn reshape_requires_divisor() {
        let d = Descriptor {
            name: "lfp_1".into(),
            kind: "lfp".into(),
            path: "x".into(),
            dtype: Dtype::F64,
            shape: [32, 1],
            offset_bytes: 0,
            sampling_rate_hz: Some(500.0),
        };
        assert_eq!(reshape(&d, 4).unwrap().shape, [8, 4]);
        assert!(reshape(&d, 5).is_err());
    }
}
