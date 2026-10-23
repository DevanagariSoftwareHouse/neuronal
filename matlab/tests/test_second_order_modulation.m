%% Synthetic recovery test: simulate_lfp_modulation + second_order_modulation
% Requires Signal Processing Toolbox. MATLAB R2019a+.
% Tolerances come from an independent NumPy mirror of both functions
% (8 seeds x 200 s): m0 0.478+-0.003, m0*kappa 0.280+-0.004,
% kappa 0.586+-0.005, psi_2 1.060+-0.012, b0 0.600+-0.007,
% b0*lambda 0.289+-0.007, lambda 0.482+-0.013, chi_2 -0.705+-0.030.
% They are deliberately several standard deviations wide; the remaining
% downward bias of the depths is filter attenuation of the outer sidebands.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'path'));

%% 1. Generator contract and reproducibility
s1 = simulate_lfp_modulation('DurationSeconds',20,'Seed',3);
s2 = simulate_lfp_modulation('DurationSeconds',20,'Seed',3);
s3 = simulate_lfp_modulation('DurationSeconds',20,'Seed',4);
assert(isequal(s1.lfp,s2.lfp),'Same seed must reproduce the signal');
assert(~isequal(s1.lfp,s3.lfp),'Different seeds must differ');
assert(isequal(size(s1.lfp),[1 20000]) && isequal(size(s1.components),[3 20000]));
assert(max(abs(sum(s1.components,1)+s1.background-s1.lfp))<1e-10);
assert(all(s1.truth.amplitude(:)>=0),'Envelopes must be nonnegative');
assert(s1.constraints.all,'Default parameters must satisfy all spectral constraints');
assert(abs(s1.truth.delta_m-0.3)<1e-12 && abs(s1.truth.delta_beta-0.3)<1e-12);
b = s1.recommended_band_hz;
assert(isequal(size(b),[3 2]) && b(1,2)<=b(2,1) && b(2,2)<=b(3,1));
threw = false;
try
    simulate_lfp_modulation('FastAM',[0.8 0],'SecondOrderAM',[0.5 0]);
catch
    threw = true;
end
assert(threw,'m0*(1+kappa) > 1 must be rejected');

%% 2. Ground-truth identity on the exact phases (no filtering, no noise)
s = simulate_lfp_modulation('DurationSeconds',200,'Seed',1);
phi_s = s.truth.phase(1,:); phi_m = s.truth.phase(2,:);
A_f = s.truth.amplitude(3,:); d_f = s.truth.fast_phase_deviation;
edges = linspace(-pi,pi,13);
idx = discretize(mod(phi_s+pi,2*pi)-pi,edges);
for k = 1:12
    sel = idx==k;
    % Centred projections (phase-clustering correction); the NumPy mirror
    % gives a worst-bin error <= 0.024 over 6 seeds, from sampling only.
    a_b = A_f(sel); d_b = d_f(sel); c_b = exp(1i*phi_m(sel));
    m_hat = 2*abs(mean((a_b-mean(a_b)).*c_b))/mean(a_b);
    m_true = mean(s.truth.fast_am_depth(sel));
    assert(abs(m_hat-m_true)<0.04,'Conditional MVL identity failed in bin %d',k);
    b_hat = 2*abs(mean((d_b-mean(d_b)).*c_b));
    assert(abs(b_hat-mean(s.truth.fast_pm_index(sel)))<0.04, ...
        'Conditional PM identity failed in bin %d',k);
end

%% 3. Recovery from the noisy, filtered signal
r = second_order_modulation(s.lfp,s.srate,s.recommended_band_hz, ...
    'Surrogates',99,'Seed',1);
p = s.truth.parameters;
wrap = @(x) mod(x+pi,2*pi)-pi;
assert(abs(r.am.c0-p.fast_am(1))<0.06,'m0');
assert(abs(r.am.delta-s.truth.delta_m)<0.06,'m0*kappa');
assert(abs(r.am.ratio-p.second_order_am(1))<0.10,'kappa');
assert(abs(wrap(r.am.phase_rad-p.second_order_am(2)))<0.20,'psi_2');
assert(abs(r.pm.c0-p.fast_pm(1))<0.06,'b0');
assert(abs(r.pm.delta-s.truth.delta_beta)<0.06,'b0*lambda');
assert(abs(r.pm.ratio-p.second_order_pm(1))<0.12,'lambda');
assert(abs(wrap(r.pm.phase_rad-p.second_order_pm(2)))<0.25,'chi_2');
assert(abs(r.first_order.normalized_mvl-s.truth.normalized_mvl)<0.03,'MVL');
assert(r.surrogate.am_p<=0.02 && r.surrogate.pm_p<=0.02,'Surrogates must reject');

%% 4. First-order coupling only: the second-order terms vanish
s0 = simulate_lfp_modulation('DurationSeconds',200,'Seed',2, ...
    'SecondOrderAM',[0 0],'SecondOrderPM',[0 0]);
r0 = second_order_modulation(s0.lfp,s0.srate,s0.recommended_band_hz);
assert(abs(r0.am.c0-0.5)<0.06 && r0.am.delta<0.02,'kappa=0 AM');
assert(abs(r0.pm.c0-0.6)<0.06 && r0.pm.delta<0.04,'lambda=0 PM');

%% 5. Known failure, kept as a regression: harmonics fake coupling
% No AM or PM coupling at all, but a sawtooth-like middle rhythm whose
% harmonics enter the fast band, with its amplitude modulated by phi_s.
sh = simulate_lfp_modulation('DurationSeconds',200,'Seed',5, ...
    'FastAM',[0 0],'FastPM',[0 0],'SecondOrderAM',[0 0], ...
    'SecondOrderPM',[0 0],'MiddleHarmonics',0.6./(2:10));
assert(~sh.constraints.harmonics_outside_fast_band, ...
    'The generator must flag harmonics inside the fast band');
rh = second_order_modulation(sh.lfp,sh.srate,sh.recommended_band_hz);
assert(rh.first_order.normalized_mvl>0.03,'Harmonics should create spurious PAC');
assert(rh.am.delta>0.05,'and spurious slow-phase dependence of it');
%% 6. Known lack of power: periodic slow phase only rotates the profile
% Disable phase diffusion, noise and middle-rhythm modulation so a circular
% shift cannot destroy the imposed second-order AM. Do not require rejection:
% the harmonic amplitude, unlike preferred phase, is rotation invariant.
sp = simulate_lfp_modulation('SamplingRate',500,'DurationSeconds',120, ...
    'Seed',7,'Frequencies',[2 9 70],'PhaseDiffusion',[0 0 0], ...
    'MiddleAM',[0 0],'MiddlePM',[0 0],'FastPM',[0 0], ...
    'SecondOrderPM',[0 0],'AperiodicStd',0,'WhiteStd',0);
rp = second_order_modulation(sp.lfp,sp.srate,sp.recommended_band_hz, ...
    'Surrogates',19,'MinShiftSeconds',10,'Seed',7);
assert(rp.am.delta>0.20,'Periodic example must retain strong second-order AM');
assert(numel(rp.surrogate.am_delta)==19 && all(isfinite(rp.surrogate.am_delta)));
assert(max(abs(rp.surrogate.am_delta-rp.am.delta))<0.06, ...
    'Periodic shifts should retain modulation amplitude, within bin/edge error');
assert(contains(rp.surrogate.note,'periodic'), ...
    'Surrogate output must document the periodic-phase limitation');
fprintf('test_second_order_modulation: all checks passed\n');
