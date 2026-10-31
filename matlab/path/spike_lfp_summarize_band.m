function s = spike_lfp_summarize_band(phase_mean,phase_strength,amplitude_mean,phase_count,spike_count,exposure_seconds,min_spikes)
%SPIKE_LFP_SUMMARIZE_BAND Descriptive neuron-level statistics for one band.
% Observations are neurons, not independent spikes/channels/time windows.
% n >= MIN_SPIKES controls inclusion in per-neuron descriptive summaries.
% PPC=(n*R^2-1)/(n-1) is an unbiased estimate of pairwise phase consistency
% for independent, identically distributed spike-phase samples; negative
% PPC is legitimate. It is not a hypothesis test or surrogate correction.
if nargin < 7 || isempty(min_spikes), min_spikes = 10; end
validateattributes(min_spikes,{'numeric'},{'scalar','integer','>=',2});
validateattributes(exposure_seconds,{'numeric'},{'scalar','real','finite','nonnegative'});

phi = double(phase_mean(:));
R   = double(phase_strength(:));
amp = double(amplitude_mean(:));
n   = double(phase_count(:));
n0  = double(spike_count(:));
assert(isequal(size(phi),size(R),size(amp),size(n),size(n0)), ...
    'All per-neuron vectors must have identical shapes.');
assert(all(isfinite(n)) && all(isfinite(n0)) && all(n >= 0) && ...
    all(n0 >= 0) && all(n == fix(n)) && all(n0 == fix(n0)) && ...
    all(n <= n0), 'Invalid counts or phase_count exceeds spike_count.');

valid_r   = isfinite(R) & R >= 0 & R <= 1+1e-5;
valid_amp = isfinite(amp) & amp >= 0;
valid_phi = isfinite(phi) | (valid_r & R <= 1e-8);
quality   = valid_r & valid_amp & valid_phi;
eligible  = (n >= min_spikes) & quality;
bad_units = nnz(n > 0 & ~quality);

s = struct();
s.units_total          = numel(n);
s.units_eligible       = nnz(eligible);
s.units_bad            = bad_units;
s.spikes_valid         = sum(n);
s.spikes_window        = sum(n0);
s.exposure_seconds     = double(exposure_seconds);
s.phase_valid_fraction = NaN;
s.eligible_fraction    = nnz(eligible)/numel(n);
s.median_plv           = NaN;
s.mean_plv             = NaN;
s.median_ppc           = NaN;
s.mean_ppc             = NaN;
s.pooled_plv           = NaN;
s.pooled_phase_rad     = NaN;
s.mean_amplitude       = NaN;
s.eligible_rate_hz     = NaN;
if s.spikes_window > 0
    s.phase_valid_fraction = s.spikes_valid/s.spikes_window;
end
if ~any(eligible), return; end

re = min(1,R(eligible));
ne = n(eligible);
ae = amp(eligible);
pe = phi(eligible);
ppc = (ne.*re.^2-1)./(ne-1);
s.median_plv = median(re);
s.mean_plv   = mean(re);
s.median_ppc = median(ppc);
s.mean_ppc   = mean(ppc);
s.mean_amplitude = sum(ne.*ae)/sum(ne);

% The pooled phase vector weights neurons by their valid spike counts.
% This is not a neuron-averaged phase direction or an independent replicate.
zero_direction = ~isfinite(pe) & re <= 1e-8;
pe(zero_direction) = 0;
z = sum(ne.*re.*exp(1i*pe))/sum(ne);
s.pooled_plv = abs(z);
if abs(z) > 1e-12
    s.pooled_phase_rad = angle(z);
end
if exposure_seconds > 0
    s.eligible_rate_hz = sum(ne)/(nnz(eligible)*exposure_seconds);
end
end
