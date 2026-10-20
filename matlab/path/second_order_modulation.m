function result = second_order_modulation(lfp,srate,band_hz,varargin)
%SECOND_ORDER_MODULATION Slow-phase dependence of PAC depth and PM index.
%   RESULT = SECOND_ORDER_MODULATION(LFP,SRATE,BAND_HZ) takes one LFP vector,
%   its sampling rate (Hz) and a 3 x 2 matrix of passbands [slow; middle;
%   fast] and estimates how a slow phase phi_s modulates (i) the depth of
%   middle-phase -> fast-amplitude coupling (second-order AM) and (ii) the
%   index of middle-phase -> fast-phase modulation (second-order PM).
%
%   Pipeline: zero-phase Butterworth bandpass (BANDPASS_LFP), Hilbert
%   phase/envelope (ANALYTIC_PHASE), removal of EdgeSeconds at both ends,
%   then, in M equal bins of phi_s on [-pi,pi):
%     m_hat(b)    = 2*|mean((A_f-mean(A_f)) .* exp(1i*phi_m))| / mean(A_f)
%     beta_hat(b) = 2*|mean((d_f-mean(d_f)) .* exp(1i*phi_m))|
%   (means within the bin; centring is the phase-clustering correction of
%   van Driel et al. 2015, DOI 10.1016/j.jneumeth.2015.07.014)
%   with d_f the zero-phase high-passed unwrapped fast phase (the carrier
%   ramp and phase-diffusion drift removed). For the model in
%   SIMULATE_LFP_MODULATION these targets equal m_f(phi_s) and b_f(phi_s).
%   Each profile y(b) is fitted by least squares to c0 + c*cos + s*sin of
%   the bin centres; the first-harmonic amplitude is divided by
%   sinc(1/M) = sin(pi/M)/(pi/M) to undo the averaging inside bins.
%     delta = |c + i*s|/sinc  (absolute second-order term, e.g. m0*kappa)
%     ratio = delta/c0        (relative term, e.g. kappa; unstable if c0~0)
%     phase = atan2(s,c)      (slow phase of maximal coupling, e.g. psi_2)
%
%   Name/value options (defaults in brackets):
%     'Bins'             number of slow-phase bins M >= 4 [12]
%     'EdgeSeconds'      samples removed at each end after filtering [5]
%     'FilterOrder'      Butterworth order for BANDPASS_LFP [4]
%     'PhaseHighpassHz'  cutoff for d_f [0.75*BAND_HZ(2,1)]
%     'Surrogates'       number of circular shifts of phi_s only [0]
%     'MinShiftSeconds'  minimum circular shift [10]
%     'Seed'             private RandStream seed for surrogates [0]
%
%   The surrogate rotates phi_s relative to (phi_m, A_f, d_f). It keeps
%   first-order coupling and every within-band property, and destroys only
%   the slow-phase relation, so it tests "no second-order dependence". It
%   does NOT control waveform harmonics of the middle rhythm or modulator
%   frequency modulation interacting with filter roll-off (see book,
%   chapter on second-order modulation); both produce genuine, surrogate-
%   significant slow-phase dependence without a second-order mechanism.
%
%   Requires Signal Processing Toolbox (BUTTER, ZP2SOS, FILTFILT, HILBERT).
%   MATLAB R2019a+.
%   See also SIMULATE_LFP_MODULATION, PAC_MEAN_VECTOR_LENGTH, BANDPASS_LFP.

validateattributes(lfp,{'numeric'},{'real','vector','finite','nonempty'},mfilename,'lfp',1);
validateattributes(srate,{'numeric'},{'scalar','real','finite','positive'},mfilename,'srate',2);
validateattributes(band_hz,{'numeric'},{'real','finite','size',[3 2]},mfilename,'band_hz',3);
assert(all(band_hz(:,1)<band_hz(:,2)),'Each band must be [low high].');
assert(band_hz(1,2)<=band_hz(2,1) && band_hz(2,2)<=band_hz(3,1), ...
    'Bands must be ordered and non-overlapping: slow < middle < fast.');

p = inputParser;
p.FunctionName = mfilename;
addParameter(p,'Bins',12,@(x) isnumeric(x) && isscalar(x) && x>=4 && x==floor(x));
addParameter(p,'EdgeSeconds',5,@(x) isnumeric(x) && isscalar(x) && isfinite(x) && x>=0);
addParameter(p,'FilterOrder',4,@(x) isnumeric(x) && isscalar(x) && x>=1 && x==floor(x));
addParameter(p,'PhaseHighpassHz',[],@(x) isempty(x) || (isnumeric(x) && isscalar(x) && x>0));
addParameter(p,'Surrogates',0,@(x) isnumeric(x) && isscalar(x) && x>=0 && x==floor(x));
addParameter(p,'MinShiftSeconds',10,@(x) isnumeric(x) && isscalar(x) && isfinite(x) && x>=0);
addParameter(p,'Seed',0,@(x) isnumeric(x) && isscalar(x) && x>=0 && x==floor(x));
parse(p,varargin{:});
cfg = p.Results;
fs = double(srate);
if isempty(cfg.PhaseHighpassHz), cfg.PhaseHighpassHz = 0.75*band_hz(2,1); end
assert(cfg.PhaseHighpassHz < band_hz(2,1), ...
    'PhaseHighpassHz must lie below the middle band so d_f keeps its PM content.');

x = double(lfp(:));
[phi_s,~] = analytic_phase(bandpass_lfp(x,fs,band_hz(1,:),cfg.FilterOrder));
[phi_m,~] = analytic_phase(bandpass_lfp(x,fs,band_hz(2,:),cfg.FilterOrder));
[phi_f,amp_f] = analytic_phase(bandpass_lfp(x,fs,band_hz(3,:),cfg.FilterOrder));
[zhp,php,khp] = butter(2,cfg.PhaseHighpassHz/(fs/2),'high');
[sos_hp,g_hp] = zp2sos(zhp,php,khp);
dev_f = filtfilt(sos_hp,g_hp,unwrap(phi_f));

edge = round(cfg.EdgeSeconds*fs);
keep = (edge+1):(numel(x)-edge);
assert(numel(keep) >= 20*cfg.Bins,'Too few samples after edge removal.');
phi_s = phi_s(keep); phi_m = phi_m(keep); amp_f = amp_f(keep); dev_f = dev_f(keep);

M = cfg.Bins;
edges = linspace(-pi,pi,M+1);
centers = (edges(1:end-1)+edges(2:end)).'/2;
sinc_gain = sin(pi/M)/(pi/M);
carrier = exp(1i*phi_m);

[am,pm,counts] = profiles(phi_s,carrier,dev_f,amp_f,edges,M);
assert(all(counts>0),'Empty slow-phase bin; use fewer bins or more data.');
fit_am = harmonic_fit(centers,am,sinc_gain);
fit_pm = harmonic_fit(centers,pm,sinc_gain);

result = struct();
result.bin_centers_rad = centers;
result.bin_counts = counts;
result.am_depth_by_slow_phase = am;
result.pm_index_by_slow_phase = pm;
result.am = fit_am;
result.pm = fit_pm;
zbar = mean((amp_f-mean(amp_f)).*carrier);
result.first_order.normalized_mvl = abs(zbar)/mean(amp_f);
result.first_order.am_depth = 2*abs(zbar)/mean(amp_f);
result.first_order.preferred_phase_rad = angle(zbar);
result.first_order.pm_index = 2*abs(mean((dev_f-mean(dev_f)).*carrier));
result.surrogate = struct('count',cfg.Surrogates,'am_delta',[],'pm_delta',[], ...
    'am_p',NaN,'pm_p',NaN);
if cfg.Surrogates>0
    stream = RandStream('mt19937ar','Seed',cfg.Seed);
    n = numel(phi_s);
    min_shift = round(cfg.MinShiftSeconds*fs);
    assert(n > 2*min_shift+1,'Recording too short for the minimum shift.');
    null_am = zeros(cfg.Surrogates,1); null_pm = zeros(cfg.Surrogates,1);
    for r = 1:cfg.Surrogates
        shift = min_shift + randi(stream,n-2*min_shift);
        [a_r,p_r] = profiles(circshift(phi_s,shift),carrier,dev_f,amp_f,edges,M);
        f_am = harmonic_fit(centers,a_r,sinc_gain);
        f_pm = harmonic_fit(centers,p_r,sinc_gain);
        null_am(r) = f_am.delta; null_pm(r) = f_pm.delta;
    end
    result.surrogate.am_delta = null_am;
    result.surrogate.pm_delta = null_pm;
    result.surrogate.am_p = (1+sum(null_am>=fit_am.delta))/(cfg.Surrogates+1);
    result.surrogate.pm_p = (1+sum(null_pm>=fit_pm.delta))/(cfg.Surrogates+1);
end
result.band_hz = band_hz;
result.config = cfg;
result.n_samples_used = numel(keep);
result.note = ['Descriptive estimate. Bin-wise |mean| is biased upward by noise ' ...
    '(compare with surrogates); harmonics and modulator FM can create ' ...
    'slow-phase dependence without second-order coupling.'];
end

function [am,pm,counts] = profiles(phi_s,carrier,dev_f,amp_f,edges,M)
idx = discretize(mod(phi_s+pi,2*pi)-pi,edges);
idx(isnan(idx)) = M;  % phase exactly +pi after wrapping
am = zeros(M,1); pm = zeros(M,1); counts = zeros(M,1);
for b = 1:M
    sel = idx==b;
    counts(b) = nnz(sel);
    if counts(b)==0, am(b) = NaN; pm(b) = NaN; continue; end
    % Centred (debiased) projections: subtracting the bin mean removes the
    % leakage of mean(A)*mean(exp(1i*phi_m)) caused by finite-sample phase
    % clustering (van Driel et al., 2015). Same target under uniformity.
    a_b = amp_f(sel); d_b = dev_f(sel); c_b = carrier(sel);
    am(b) = 2*abs(mean((a_b-mean(a_b)).*c_b))/mean(a_b);
    pm(b) = 2*abs(mean((d_b-mean(d_b)).*c_b));
end
end

function fit = harmonic_fit(theta,y,sinc_gain)
X = [ones(size(theta)) cos(theta) sin(theta)];
c = X\y;
fit.c0 = c(1);
fit.delta = hypot(c(2),c(3))/sinc_gain;
fit.ratio = fit.delta/c(1);
fit.phase_rad = atan2(c(3),c(2));
fit.coefficients = c;
end
