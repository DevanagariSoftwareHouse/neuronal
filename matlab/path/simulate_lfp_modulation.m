function result = simulate_lfp_modulation(varargin)
%SIMULATE_LFP_MODULATION Synthetic LFP with first- and second-order modulation.
%   RESULT = SIMULATE_LFP_MODULATION() returns one channel (1 x samples) of
%   a three-rhythm LFP: a slow rhythm (default 1.5 Hz, "delta"), a middle
%   rhythm (8 Hz, "theta") and a fast rhythm (60 Hz, "gamma"), plus a
%   1/f^chi aperiodic background and white measurement noise.
%
%   Model (phases phi_s, phi_m, phi_f; Wiener phase diffusion W):
%     phi_s = 2*pi*f_s*t + u_s + sigma_s*W_s
%     A_m   = a_m*(1 + m_m*cos(phi_s - psi_m))                 first-order AM
%     phi_m = 2*pi*f_m*t + u_m + sigma_m*W_m
%             + beta_m*sin(phi_s - chi_m)                      first-order PM
%     m_f   = m0*(1 + kappa*cos(phi_s - psi_2))                second-order AM
%     b_f   = b0*(1 + lambda*cos(phi_s - chi_2))               second-order PM
%     A_f   = a_f*(1 + m_f.*cos(phi_m - psi_f))
%     phi_f = 2*pi*f_f*t + u_f + sigma_f*W_f + b_f.*sin(phi_m - chi_f)
%     lfp   = a_s*cos(phi_s) + A_m.*(cos(phi_m) + H(phi_m)) + A_f.*cos(phi_f)
%             + background + white
%   where H(phi) = sum_k h_k*cos(k*phi), k = 2..K+1, is an optional
%   non-sinusoidal waveform for the middle rhythm (a known PAC confound).
%   "Second order" means a coupling coefficient (m_f, b_f) is itself
%   modulated by a third, slower phase; first-order modulation is the case
%   kappa = lambda = 0. u_* are uniform random initial phases.
%
%   Name/value options (defaults in brackets):
%     'SamplingRate'      Hz [1000]
%     'DurationSeconds'   s [300]
%     'Seed'              nonnegative integer for a private RandStream [0]
%     'Frequencies'       [f_s f_m f_f] Hz [1.5 8 60]
%     'Amplitudes'        [a_s a_m a_f] signal units [1 1 0.35]
%     'PhaseDiffusion'    [sigma_s sigma_m sigma_f] rad/sqrt(s) [0.4 0.8 1.5]
%     'MiddleAM'          [m_m psi_m] [0.4 0]
%     'MiddlePM'          [beta_m chi_m] [0.8 0]
%     'FastAM'            [m0 psi_f] [0.5 0]
%     'FastPM'            [b0 chi_f] [0.6 0]
%     'SecondOrderAM'     [kappa psi_2] [0.6 pi/3]
%     'SecondOrderPM'     [lambda chi_2] [0.5 -pi/4]
%     'MiddleHarmonics'   vector h_2..h_{K+1} [] (sinusoidal middle rhythm)
%     'AperiodicExponent' chi of the 1/f^chi background [1.5]
%     'AperiodicStd'      background standard deviation [0.6]
%     'WhiteStd'          measurement-noise standard deviation [0.05]
%     'BandMargin'        factor >= 1 on Carson half-widths [1.2]
%
%   RESULT fields: lfp (1 x n), time_seconds (1 x n), srate, components
%   (3 x n: slow, middle, fast rhythms, middle including harmonics),
%   background (1 x n), truth (exact phases, envelopes, m_f(t), b_f(t),
%   parameters and ground-truth estimator targets), recommended_band_hz
%   (3 x 2), constraints (Bedrosian/Carson/Nyquist checks, each a logical),
%   note and provenance.
%
%   Ground truth for estimators (conditional uniformity of phi_m given
%   phi_s, which phase diffusion supplies):
%     E[A_f exp(i phi_m) | phi_s] / E[A_f | phi_s] = (m_f(phi_s)/2) exp(i psi_f)
%     2|E[d_f exp(i phi_m) | phi_s]| = b_f(phi_s),  d_f = b_f sin(phi_m-chi_f).
%   Hence normalized MVL = m0/2 marginally and the second-order AM term
%   has absolute size m0*kappa (truth.delta_m) as a function of phi_s.
%
%   No toolbox is required. MATLAB R2019a+.
%   See also SECOND_ORDER_MODULATION, PAC_MEAN_VECTOR_LENGTH, MODULATION_INDEX.

p = inputParser;
p.FunctionName = mfilename;
addParameter(p,'SamplingRate',1000,@positive_scalar);
addParameter(p,'DurationSeconds',300,@positive_scalar);
addParameter(p,'Seed',0,@(x) isnumeric(x) && isscalar(x) && x>=0 && x==floor(x));
addParameter(p,'Frequencies',[1.5 8 60],@(x) numeric_vector(x,3) && all(x>0));
addParameter(p,'Amplitudes',[1 1 0.35],@(x) numeric_vector(x,3) && all(x>=0));
addParameter(p,'PhaseDiffusion',[0.4 0.8 1.5],@(x) numeric_vector(x,3) && all(x>=0));
addParameter(p,'MiddleAM',[0.4 0],@(x) numeric_vector(x,2));
addParameter(p,'MiddlePM',[0.8 0],@(x) numeric_vector(x,2));
addParameter(p,'FastAM',[0.5 0],@(x) numeric_vector(x,2));
addParameter(p,'FastPM',[0.6 0],@(x) numeric_vector(x,2));
addParameter(p,'SecondOrderAM',[0.6 pi/3],@(x) numeric_vector(x,2));
addParameter(p,'SecondOrderPM',[0.5 -pi/4],@(x) numeric_vector(x,2));
addParameter(p,'MiddleHarmonics',[],@(x) isempty(x) || (isnumeric(x) && isvector(x) && all(isfinite(x))));
addParameter(p,'AperiodicExponent',1.5,@(x) isnumeric(x) && isscalar(x) && isfinite(x) && x>=0);
addParameter(p,'AperiodicStd',0.6,@nonnegative_scalar);
addParameter(p,'WhiteStd',0.05,@nonnegative_scalar);
addParameter(p,'BandMargin',1.2,@(x) positive_scalar(x) && x>=1);
parse(p,varargin{:});
cfg = p.Results;

fs = double(cfg.SamplingRate);
f = double(cfg.Frequencies(:)).';
a = double(cfg.Amplitudes(:)).';
sigma = double(cfg.PhaseDiffusion(:)).';
m_m = cfg.MiddleAM(1);       psi_m = cfg.MiddleAM(2);
beta_m = cfg.MiddlePM(1);    chi_m = cfg.MiddlePM(2);
m0 = cfg.FastAM(1);          psi_f = cfg.FastAM(2);
b0 = cfg.FastPM(1);          chi_f = cfg.FastPM(2);
kappa = cfg.SecondOrderAM(1); psi_2 = cfg.SecondOrderAM(2);
lambda = cfg.SecondOrderPM(1); chi_2 = cfg.SecondOrderPM(2);
h = double(cfg.MiddleHarmonics(:)).';

assert(f(1)<f(2) && f(2)<f(3),'Frequencies must be strictly increasing (slow < middle < fast).');
assert(m_m>=0 && m_m<=1,'Middle AM depth must lie in [0,1] so the envelope is nonnegative.');
assert(m0>=0 && kappa>=0 && m0*(1+kappa)<=1, ...
    'Need m0 >= 0, kappa >= 0 and m0*(1+kappa) <= 1 so the fast envelope is nonnegative.');
assert(beta_m>=0 && b0>=0 && lambda>=0,'Phase-modulation indices must be nonnegative.');
assert(lambda<=1,'lambda <= 1 keeps the fast PM index nonnegative.');

n = round(cfg.DurationSeconds*fs);
assert(n>=16,'Duration is too short for the sampling rate.');
dt = 1/fs;
t = (0:n-1)*dt;
stream = RandStream('mt19937ar','Seed',cfg.Seed);

u = 2*pi*rand(stream,1,3)-pi;
W = zeros(3,n);
for k = 1:3
    W(k,2:end) = cumsum(sigma(k)*sqrt(dt)*randn(stream,1,n-1));
end

phi_s = 2*pi*f(1)*t + u(1) + W(1,:);
A_s = a(1)*ones(1,n);
A_m = a(2)*(1 + m_m*cos(phi_s - psi_m));
phi_m = 2*pi*f(2)*t + u(2) + W(2,:) + beta_m*sin(phi_s - chi_m);
depth_f = m0*(1 + kappa*cos(phi_s - psi_2));
index_f = b0*(1 + lambda*cos(phi_s - chi_2));
A_f = a(3)*(1 + depth_f.*cos(phi_m - psi_f));
dev_f = index_f.*sin(phi_m - chi_f);
phi_f = 2*pi*f(3)*t + u(3) + W(3,:) + dev_f;

waveform_m = cos(phi_m);
for k = 1:numel(h)
    waveform_m = waveform_m + h(k)*cos((k+1)*phi_m);
end
components = [A_s.*cos(phi_s); A_m.*waveform_m; A_f.*cos(phi_f)];

% Aperiodic background: white Gaussian noise shaped to |f|^(-chi/2) in
% amplitude, zero mean (DC removed), rescaled to the requested std.
background = zeros(1,n);
if cfg.AperiodicStd>0
    freq = [0:ceil(n/2)-1, -floor(n/2):-1]*fs/n;
    gain = zeros(1,n);
    gain(2:end) = abs(freq(2:end)).^(-cfg.AperiodicExponent/2);
    background = real(ifft(fft(randn(stream,1,n)).*gain));
    background = cfg.AperiodicStd*background/std(background,1);
end
white = cfg.WhiteStd*randn(stream,1,n);
lfp = sum(components,1) + background + white;

% Spectral bookkeeping. Carson half-width for PM index beta and modulating
% frequency fm is (beta+1)*fm; an AM envelope with modulating content up to
% B widens it by B. Margins guard against filter roll-off (see book).
b_max = b0*(1+lambda);
K = numel(h)+1;
env_bw_m = f(1);                         % middle envelope bandwidth
env_bw_f = f(2)+f(1);                    % fast envelope bandwidth
hw_m = cfg.BandMargin*((beta_m+1)*f(1) + env_bw_m);
hw_f = cfg.BandMargin*((b_max+1)*f(2) + env_bw_f);
hw_s = cfg.BandMargin*f(1)/2;
bands = [max(f(1)-hw_s,fs/n*4) f(1)+hw_s; f(2)-hw_m f(2)+hw_m; f(3)-hw_f f(3)+hw_f];

c = struct();
c.nyquist = bands(3,2) < fs/2;
c.positive_lower_edges = all(bands(:,1)>0);
c.bands_disjoint = bands(1,2)<=bands(2,1) && bands(2,2)<=bands(3,1);
% Bedrosian sufficient condition at each modulated level: envelope
% spectrum inside (-B,B), PM carrier spectrum outside it.
c.bedrosian_middle = env_bw_m < f(2) - (beta_m+1)*f(1);
c.bedrosian_fast = env_bw_f < f(3) - (b_max+1)*f(2);
c.harmonics_outside_fast_band = isempty(h) || ...
    (K*(f(2)+hw_m) < bands(3,1)) || all(h==0);
c.all = c.nyquist && c.positive_lower_edges && c.bands_disjoint && ...
    c.bedrosian_middle && c.bedrosian_fast && c.harmonics_outside_fast_band;
if ~c.all
    warning('neuronal:simulate_lfp_modulation:constraints', ...
        'Spectral separation constraints violated; see RESULT.constraints.');
end

truth = struct();
truth.phase = [phi_s; phi_m; phi_f];
truth.amplitude = [A_s; A_m; A_f];
truth.fast_am_depth = depth_f;
truth.fast_pm_index = index_f;
truth.fast_phase_deviation = dev_f;
truth.parameters = struct('frequencies_hz',f,'amplitudes',a, ...
    'phase_diffusion',sigma,'middle_am',[m_m psi_m], ...
    'middle_pm',[beta_m chi_m],'fast_am',[m0 psi_f], ...
    'fast_pm',[b0 chi_f],'second_order_am',[kappa psi_2], ...
    'second_order_pm',[lambda chi_2],'middle_harmonics',h);
truth.normalized_mvl = m0/2;
truth.delta_m = m0*kappa;
truth.delta_beta = b0*lambda;
truth.initial_phase = u;

result = struct();
result.lfp = lfp;
result.time_seconds = t;
result.srate = fs;
result.components = components;
result.component_names = {'slow','middle','fast'};
result.background = background + white;
result.truth = truth;
result.recommended_band_hz = bands;
result.constraints = c;
result.config = cfg;
result.note = ['Synthetic model with known coupling. Recovery checks numerical ' ...
    'behaviour of estimators; it does not validate claims about real LFPs.'];
result.provenance = struct('generator','mt19937ar','seed',cfg.Seed, ...
    'orientation','channels x samples','time_origin_seconds',0, ...
    'n_samples',n);
end

function ok = positive_scalar(x)
ok = isnumeric(x) && isscalar(x) && isreal(x) && isfinite(x) && x>0;
end

function ok = nonnegative_scalar(x)
ok = isnumeric(x) && isscalar(x) && isreal(x) && isfinite(x) && x>=0;
end

function ok = numeric_vector(x,len)
ok = isnumeric(x) && isreal(x) && numel(x)==len && all(isfinite(x(:)));
end
