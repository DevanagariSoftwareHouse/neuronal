function study = second_order_modulation_study(varargin)
%SECOND_ORDER_MODULATION_STUDY Reproduce every number in the book chapter
%   "A simulation of second-order amplitude and phase modulation".
%
%   STUDY = SECOND_ORDER_MODULATION_STUDY() runs, with the MATLAB
%   implementations of SIMULATE_LFP_MODULATION and SECOND_ORDER_MODULATION:
%     A  recovery at the default parameters and recommended bands;
%     B  calibration of the slow-phase circular-shift null;
%     C  instability of the ratio Delta/c0 without coupling;
%     D  waveform harmonics of the middle rhythm (confound 1);
%     E  modulator FM against filter roll-off (confound 2), including the
%        PM-to-AM conversion of the middle envelope in a narrow band;
%     F  the instantaneous-frequency PM estimator (confound 3) and its
%        analytic prediction;
%     G  AM leaking into PM through phase noise (confound 4).
%   It writes, under OutputDir:
%     second_order_results.tex   LaTeX tables input by the chapter
%     second_order_study.mat     all per-seed values
%     fig_second_order_recovery.{eps,pdf}
%   and, unless 'CopyToBook' is false, copies the .tex and .pdf into
%   books/electrophysiology/figures/generated/, where the chapter picks
%   them up with \IfFileExists (otherwise it shows the NumPy-mirror table).
%
%   Name/value options (defaults reproduce the chapter):
%     'Seeds'          seeds for A [8]          'Duration'      s for A [200]
%     'NullRuns'       realisations for B [40]  'NullDuration'  s for B [120]
%     'ConfoundSeeds'  seeds for C-G [6]        'Surrogates'    shifts [99]
%     'OutputDir'      [matlab/build/second_order_modulation]
%     'CopyToBook'     [true]
%     'Quick'          true -> 2 seeds, 60 s, 6 nulls, 2 confound seeds, 39
%                      shifts (smoke run, numbers not for the book) [false]
%
%   Requires Signal Processing Toolbox. MATLAB R2019a+. About 15-30 min at
%   the defaults on a laptop. Seeds differ from the NumPy mirror, so values
%   agree in distribution, not digit by digit.
%
%   Run from the repository root:
%     addpath(fullfile(pwd,'examples','matlab'));
%     study = second_order_modulation_study();

repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
p = inputParser;
p.FunctionName = mfilename;
addParameter(p,'Seeds',8,@count_ok);
addParameter(p,'Duration',200,@positive_ok);
addParameter(p,'NullRuns',40,@count_ok);
addParameter(p,'NullDuration',120,@positive_ok);
addParameter(p,'ConfoundSeeds',6,@count_ok);
addParameter(p,'Surrogates',99,@count_ok);
addParameter(p,'OutputDir',fullfile(repo,'matlab','build','second_order_modulation'), ...
    @(x) ischar(x) || isstring(x));
addParameter(p,'CopyToBook',true,@(x) islogical(x) && isscalar(x));
addParameter(p,'Quick',false,@(x) islogical(x) && isscalar(x));
parse(p,varargin{:});
cfg = p.Results;
if cfg.Quick
    cfg.Seeds = 2; cfg.Duration = 60; cfg.NullRuns = 6; cfg.NullDuration = 60;
    cfg.ConfoundSeeds = 2; cfg.Surrogates = 39; cfg.CopyToBook = false;
end
cfg.OutputDir = char(cfg.OutputDir);
if ~exist(cfg.OutputDir,'dir'), mkdir(cfg.OutputDir); end

old_path = path;
path_cleanup = onCleanup(@() path(old_path)); %#ok<NASGU>
addpath(fullfile(repo,'matlab','path'), fullfile(repo,'matlab','figures','helpers'));

study = struct('config',cfg,'started',datestr(now,31));
H = 0.6./(2:10);                                   % sawtooth-like harmonics
none = {'FastAM',[0 0],'FastPM',[0 0],'SecondOrderAM',[0 0],'SecondOrderPM',[0 0]};
default_bands = [0.6 2.4; 2.96 13.04];             % slow, middle (defaults)
tic_all = tic;

%% A. Recovery at the defaults
fprintf('A. recovery (%d x %g s)\n',cfg.Seeds,cfg.Duration);
names = {'m0','m0kappa','kappa','psi2','b0','b0lambda','lambda','chi2','mvl'};
A = nan(cfg.Seeds,numel(names));
for k = 1:cfg.Seeds
    s = simulate_lfp_modulation('DurationSeconds',cfg.Duration,'Seed',k);
    r = second_order_modulation(s.lfp,s.srate,s.recommended_band_hz);
    A(k,:) = [r.am.c0 r.am.delta r.am.ratio r.am.phase_rad ...
              r.pm.c0 r.pm.delta r.pm.ratio r.pm.phase_rad ...
              r.first_order.normalized_mvl];
    if k==1, example = struct('sim',s,'est',r); end
end
truth = [0.5 0.3 0.6 pi/3 0.6 0.3 0.5 -pi/4 0.25];
study.A = struct('names',{names},'truth',truth,'values',A, ...
    'mean',mean(A,1),'sd',std(A,0,1));

%% B. Null calibration of the slow-phase shift
fprintf('B. null calibration (%d x %g s)\n',cfg.NullRuns,cfg.NullDuration);
B = nan(cfg.NullRuns,4);
for k = 1:cfg.NullRuns
    s = simulate_lfp_modulation('DurationSeconds',cfg.NullDuration,'Seed',1000+k, ...
        'SecondOrderAM',[0 0],'SecondOrderPM',[0 0]);
    r = second_order_modulation(s.lfp,s.srate,s.recommended_band_hz, ...
        'Surrogates',cfg.Surrogates,'Seed',k);
    B(k,:) = [r.am.delta r.pm.delta r.surrogate.am_p r.surrogate.pm_p];
end
study.B = struct('values',B,'am_reject',mean(B(:,3)<0.05), ...
    'pm_reject',mean(B(:,4)<0.05),'am_count',sum(B(:,3)<0.05), ...
    'pm_count',sum(B(:,4)<0.05),'binomial_tail',binomial_tail( ...
    max(sum(B(:,3)<0.05),sum(B(:,4)<0.05)),cfg.NullRuns,0.05));

%% C-G. Confounds
nc = cfg.ConfoundSeeds;
run_case = @(args,bands,nsur) confound_case(args,bands,nsur,nc,cfg.Duration);
fprintf('C. no coupling\n');
study.C = run_case(none,[],0);
fprintf('D. harmonics\n');
warn_id = 'neuronal:simulate_lfp_modulation:constraints';   % expected here
warn_state = warning('off',warn_id);
warn_cleanup = onCleanup(@() warning(warn_state)); %#ok<NASGU>
study.D.with_slow_am = run_case([none {'MiddleHarmonics',H}],[],cfg.Surrogates);
study.D.without_slow_am = run_case([none {'MiddleHarmonics',H,'MiddleAM',[0 0]}],[],0);
warning(warn_state);
fprintf('E. modulator FM and roll-off\n');
k0 = {'SecondOrderAM',[0 0]};
study.E.narrow_fm = run_case(k0,[default_bands; 35 85],cfg.Surrogates);
study.E.narrow_nofm = run_case([k0 {'MiddlePM',[0 0]}],[default_bands; 35 85],cfg.Surrogates);
study.E.wide_fm = run_case(k0,[default_bands; 25 95],cfg.Surrogates);
study.E.middle_depth = middle_depth_case(nc,cfg.Duration);
fprintf('F. instantaneous-frequency estimator\n');
study.F = inst_freq_case(nc,cfg.Duration);
fprintf('G. AM leaking into PM\n');
study.G.psi2_pi3 = run_case({},[],0);
study.G.kappa0 = run_case({'SecondOrderAM',[0 0]},[],0);
study.G.psi2_m3pi4 = run_case({'SecondOrderAM',[0.6 -3*pi/4]},[],0);
study.G.noiseless = run_case({'AperiodicStd',0,'WhiteStd',0},[],0);
study.elapsed_seconds = toc(tic_all);

%% Outputs
save(fullfile(cfg.OutputDir,'second_order_study.mat'),'study','-v7');
tex_path = fullfile(cfg.OutputDir,'second_order_results.tex');
write_tables(tex_path,study);
fig_paths = draw_figure(example,cfg.OutputDir);
study.outputs = struct('tex',tex_path,'pdf',fig_paths.pdf_path,'eps',fig_paths.eps_path);
if cfg.CopyToBook
    dest = fullfile(repo,'books','electrophysiology','figures','generated');
    if ~exist(dest,'dir'), mkdir(dest); end
    copyfile(tex_path,dest);
    copyfile(fig_paths.pdf_path,dest);
end
fprintf('done in %.1f min; outputs in %s\n',study.elapsed_seconds/60,cfg.OutputDir);
end

%% ------------------------------------------------------------------------
function out = confound_case(args,bands,nsur,nseeds,duration)
% Run SECOND_ORDER_MODULATION over seeds 50+k. Empty BANDS -> recommended.
v = nan(nseeds,9);
for k = 1:nseeds
    s = simulate_lfp_modulation('DurationSeconds',duration,'Seed',50+k,args{:});
    b = bands; if isempty(b), b = s.recommended_band_hz; end
    r = second_order_modulation(s.lfp,s.srate,b,'Surrogates',nsur,'Seed',k);
    v(k,:) = [r.am.c0 r.am.delta r.am.ratio r.am.phase_rad ...
              r.pm.c0 r.pm.delta r.pm.ratio r.pm.phase_rad ...
              r.first_order.normalized_mvl];
    pv(k,:) = [r.surrogate.am_p r.surrogate.pm_p]; %#ok<AGROW>
end
out = struct('values',v,'mean',mean(v,1),'sd',std(v,0,1), ...
    'p',pv,'am_significant',sum(pv(:,1)<0.05),'pm_significant',sum(pv(:,2)<0.05), ...
    'columns',{{'am_c0','am_delta','am_ratio','am_phase','pm_c0','pm_delta', ...
    'pm_ratio','pm_phase','mvl'}},'surrogates',nsur);
end

function out = middle_depth_case(nseeds,duration)
% First-order AM depth of the middle rhythm from a harmonic fit of its
% envelope on the slow phase, in a conventional band and the Carson band.
cases = {{'MiddlePM',[0 0]},[5 11]; {},[5 11]; {},[]};
v = nan(nseeds,size(cases,1));
for c = 1:size(cases,1)
    for k = 1:nseeds
        s = simulate_lfp_modulation('DurationSeconds',duration,'Seed',50+k,cases{c,1}{:});
        b = cases{c,2}; if isempty(b), b = s.recommended_band_hz(2,:); end
        x = s.lfp(:);
        [phi_s,~] = analytic_phase(bandpass_lfp(x,s.srate,s.recommended_band_hz(1,:)));
        [~,amp_m] = analytic_phase(bandpass_lfp(x,s.srate,b));
        keep = trim(numel(phi_s),s.srate);
        phi_s = phi_s(keep); amp_m = amp_m(keep);
        c_ = [ones(numel(keep),1) cos(phi_s(:)) sin(phi_s(:))] \ amp_m(:);
        v(k,c) = hypot(c_(2),c_(3))/c_(1);
    end
end
out = struct('values',v,'mean',mean(v,1),'labels',{{'beta_m=0, 5-11 Hz', ...
    'beta_m=0.8, 5-11 Hz','beta_m=0.8, Carson band'}},'truth',0.4);
end

function out = inst_freq_case(nseeds,duration)
% PM index from the fast instantaneous frequency regressed on the middle
% phase in each slow-phase bin, divided by the mean middle frequency.
labels = {'beta_m=0.8','beta_m=0'};
args = {{},{'MiddlePM',[0 0]}};
v = nan(nseeds,2,2);
for c = 1:2
    for k = 1:nseeds
        s = simulate_lfp_modulation('DurationSeconds',duration,'Seed',50+k,args{c}{:});
        fs = s.srate;
        bands = [default_slow(s); s.recommended_band_hz(2,:); 35 85];
        x = s.lfp(:);
        [phi_s,~] = analytic_phase(bandpass_lfp(x,fs,bands(1,:)));
        [phi_m,~] = analytic_phase(bandpass_lfp(x,fs,bands(2,:)));
        [phi_f,~] = analytic_phase(bandpass_lfp(x,fs,bands(3,:)));
        phi_s = phi_s(:); phi_m = phi_m(:);
        f_m = gradient(unwrap(phi_m))*fs/(2*pi);
        f_f = gradient(unwrap(phi_f(:)))*fs/(2*pi);
        keep = trim(numel(phi_s),fs);
        phi_s = phi_s(keep); phi_m = phi_m(keep); f_m = f_m(keep); f_f = f_f(keep);
        edges = linspace(-pi,pi,13); centers = (edges(1:end-1)+edges(2:end))/2;
        idx = bin_index(phi_s,edges);
        beta = nan(12,1);
        for b = 1:12
            sel = idx==b;
            X = [ones(nnz(sel),1) cos(phi_m(sel)) sin(phi_m(sel))];
            c_ = X \ f_f(sel);
            beta(b) = hypot(c_(2),c_(3))/mean(f_m);
        end
        c_ = [ones(12,1) cos(centers(:)) sin(centers(:))] \ beta;
        v(k,c,:) = [hypot(c_(2),c_(3))/c_(1)/(sin(pi/12)/(pi/12)) atan2(c_(3),c_(2))];
    end
end
z = 0.5*exp(-1i*(-pi/4)) + 0.8*1.5/8;    % lambda e^{-i chi2} + beta_m f_s/f_m
out = struct('labels',{labels},'values',v, ...
    'ratio_mean',mean(v(:,:,1),1),'phase_mean',mean(v(:,:,2),1), ...
    'prediction_ratio',abs(z),'prediction_phase',-angle(z));
end

function b = default_slow(s)
b = s.recommended_band_hz(1,:);
end

function keep = trim(n,fs)
e = round(5*fs);
keep = (e+1):(n-e);
end

function idx = bin_index(phi,edges)
idx = discretize(mod(phi+pi,2*pi)-pi,edges);
idx(isnan(idx)) = numel(edges)-1;
end

function t = binomial_tail(k,n,q)
% P(X >= k) for X ~ Binomial(n,q).
j = k:n;
t = sum(arrayfun(@(x) nchoosek(n,x),j).*q.^j.*(1-q).^(n-j));
end

function write_tables(path_,st)
fid = fopen(path_,'w');
assert(fid~=-1,'Cannot write %s',path_);
c = onCleanup(@() fclose(fid));
A = st.A; cfg = st.config;
labels = {'$m_0$','$m_0\kappa$','$\kappa$','$\psi_2$ (rad)','$b_0$', ...
    '$b_0\lambda$','$\lambda$','$\chi_2$ (rad)','normalised MVL'};
fprintf(fid,'%% Generated by examples/matlab/second_order_modulation_study.m\n');
runtime = sprintf('MATLAB %s',version);
if exist('OCTAVE_VERSION','builtin'), runtime = sprintf('GNU Octave %s',version); end
fprintf(fid,'%% %s, %s. Do not edit by hand.\n',runtime,st.started);
fprintf(fid,'\\begin{center}\n\\begin{tabular}{lrrr}\n\\toprule\n');
fprintf(fid,'Quantity & True & Mean & SD\\\\\n\\midrule\n');
for k = 1:numel(labels)
    fprintf(fid,'%s & $%.3f$ & $%.3f$ & $%.3f$\\\\\n',labels{k},A.truth(k),A.mean(k),A.sd(k));
end
fprintf(fid,'\\bottomrule\n\\end{tabular}\n\\end{center}\n');
fprintf(fid,['\\noindent %s, %d seeds of $%g$\\,s. Null calibration: ' ...
    '%d realisations of $%g$\\,s, %d shifts; nominal-$5\\%%$ rejections ' ...
    '%d (AM) and %d (PM); $P(X\\ge%d)=%.2f$ under a $5\\%%$ rate.\n\n'], ...
    runtime,cfg.Seeds,cfg.Duration,cfg.NullRuns,cfg.NullDuration,cfg.Surrogates, ...
    st.B.am_count,st.B.pm_count,max(st.B.am_count,st.B.pm_count),st.B.binomial_tail);
fprintf(fid,'\\begin{center}\n\\small\n\\begin{tabular}{lrrrrc}\n\\toprule\n');
fprintf(fid,'Scenario & $\\hat c_0^{\\mathrm{AM}}$ & $\\hat\\Delta_{\\mathrm{AM}}$ & $\\hat\\Delta_{\\mathrm{AM}}/\\hat c_0$ & $\\hat\\Delta_{\\mathrm{PM}}$ & sig.\\ AM/PM\\\\\n\\midrule\n');
rows = {'No coupling',st.C; 'Harmonics, slow AM of middle',st.D.with_slow_am; ...
    'Harmonics, no slow AM',st.D.without_slow_am; ...
    '$\kappa=0$ ($\lambda=0.5$), $35$--$85$\,Hz, $\beta_m=0.8$',st.E.narrow_fm; ...
    '$\kappa=0$, $35$--$85$\,Hz, $\beta_m=0$',st.E.narrow_nofm; ...
    '$\kappa=0$, $25$--$95$\,Hz, $\beta_m=0.8$',st.E.wide_fm};
for k = 1:size(rows,1)
    r = rows{k,2};
    sig = '--';
    if r.surrogates>0
        sig = sprintf('%d/%d, %d/%d',r.am_significant,size(r.values,1),r.pm_significant,size(r.values,1));
    end
    fprintf(fid,'%s & $%.3f$ & $%.4f$ & $%.2f\\pm%.2f$ & $%.4f$ & %s\\\\\n',rows{k,1}, ...
        r.mean(1),r.mean(2),r.mean(3),r.sd(3),r.mean(6),sig);
end
fprintf(fid,'\\bottomrule\n\\end{tabular}\n\\end{center}\n');
F = st.F; G = st.G; E = st.E.middle_depth;
fprintf(fid,['\\noindent Middle AM depth (truth $0.4$): $%.3f$ ($\\beta_m=0$, $5$--$11$\\,Hz), ' ...
    '$%.3f$ ($\\beta_m=0.8$, $5$--$11$\\,Hz), $%.3f$ (Carson band). ' ...
    'Instantaneous-frequency PM estimator ($35$--$85$\\,Hz): ratio $%.3f$, phase $%.3f$ with ' ...
    '$\\beta_m=0.8$ (prediction $%.3f$, $%.3f$); $%.3f$, $%.3f$ with $\\beta_m=0$ (truth $0.5$, $-0.785$). ' ...
    '$\\hat\\chi_2$: $%.3f$ ($\\psi_2=\\pi/3$), $%.3f$ ($\\kappa=0$), $%.3f$ ($\\psi_2=-3\\pi/4$), ' ...
    '$%.3f$ (no background noise).\n'], E.mean(1),E.mean(2),E.mean(3), ...
    F.ratio_mean(1),F.phase_mean(1),F.prediction_ratio,F.prediction_phase, ...
    F.ratio_mean(2),F.phase_mean(2),G.psi2_pi3.mean(8),G.kappa0.mean(8), ...
    G.psi2_m3pi4.mean(8),G.noiseless.mean(8));
end

function paths = draw_figure(ex,out_dir)
s = ex.sim; r = ex.est;
th = linspace(-pi,pi,200);
pp = s.truth.parameters;
m_true = pp.fast_am(1)*(1+pp.second_order_am(1)*cos(th-pp.second_order_am(2)));
b_true = pp.fast_pm(1)*(1+pp.second_order_pm(1)*cos(th-pp.second_order_pm(2)));
blue = [42 120 214]/255; orange = [235 104 52]/255; ink = [0.32 0.32 0.31];
fig = figure('Visible','off');
fig_cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
seg = 50*s.srate+(1:s.srate);
subplot(1,3,1);
plot(s.time_seconds(seg)-s.time_seconds(seg(1)),s.lfp(seg),'Color',blue,'LineWidth',0.8);
xlabel('Time (s)'); ylabel('LFP (a.u.)'); title('1 s of simulated LFP');
subplot(1,3,2);
plot(th,m_true,'Color',ink,'LineWidth',1.6); hold on;
plot(r.bin_centers_rad,r.am_depth_by_slow_phase,'o','Color',blue, ...
    'MarkerFaceColor',blue,'MarkerEdgeColor','w','MarkerSize',6);
xlim([-pi pi]); ylim([0 1.25]); set(gca,'XTick',[-pi 0 pi],'XTickLabel',{'-\pi','0','\pi'});
xlabel('Slow phase \phi_s (rad)'); title('Second-order AM: depth');
legend({'true m_f(\phi_s)','estimated'},'Box','off','Location','north','Orientation','horizontal');
subplot(1,3,3);
plot(th,b_true,'Color',ink,'LineWidth',1.6); hold on;
plot(r.bin_centers_rad,r.pm_index_by_slow_phase,'o','Color',orange, ...
    'MarkerFaceColor',orange,'MarkerEdgeColor','w','MarkerSize',6);
xlim([-pi pi]); ylim([0 1.25]); set(gca,'XTick',[-pi 0 pi],'XTickLabel',{'-\pi','0','\pi'});
xlabel('Slow phase \phi_s (rad)'); title('Second-order PM: index');
legend({'true b_f(\phi_s)','estimated'},'Box','off','Location','north','Orientation','horizontal');
neuronal_figure_style(fig);
set(fig,'Position',[1 1 7.2 2.8]);
paths = export_figure_eps_pdf(fig,fullfile(out_dir,'fig_second_order_recovery'));
end

function ok = count_ok(x)
ok = isnumeric(x) && isscalar(x) && x>=0 && x==floor(x);
end

function ok = positive_ok(x)
ok = isnumeric(x) && isscalar(x) && isfinite(x) && x>0;
end
