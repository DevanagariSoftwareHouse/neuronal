function model = aperiodic_slope(frequency,power,fit_band,exclude_bands)
%APERIODIC_SLOPE Log-log linear 1/f fit; NOT full FOOOF/specparam.
% Donoghue et al. (2020). Exclude peaks explicitly before fitting.
%
%   SYNTAX
%     model = aperiodic_slope(frequency,power,fit_band,exclude_bands)
%
%   INPUTS
%     frequency: Frequency vector in Hz.
%     power: Matching PSD vector; only finite positive frequency/power pairs enter the fit.
%     fit_band: Inclusive [low high] frequency range in Hz.
%     exclude_bands: K-by-2 excluded frequency ranges in Hz; default zeros(0,2).
%
%   OUTPUTS
%     model: Struct: slope, exponent=-slope, intercept (base-10 log power), background (PSD),
%       frequency_hz and fit_mask.
%
%   EXAMPLE
%     f = (1:100)'; p = 2*f.^(-1.5);
%     model = aperiodic_slope(f,p,[2 90],[7 12]);
%     % model.exponent is 1.5 for this ideal power law.
%
if nargin<4, exclude_bands=zeros(0,2); end
frequency=double(frequency(:)); power=double(power(:));
assert(numel(frequency)==numel(power) && numel(fit_band)==2, ...
    'Frequency, PSD and fit_band dimensions mismatch');
keep=isfinite(frequency)&isfinite(power)&frequency>0&power>0 ...
    &frequency>=fit_band(1)&frequency<=fit_band(2);
for k=1:size(exclude_bands,1)
    keep=keep & ~(frequency>=exclude_bands(k,1) & ...
                    frequency<=exclude_bands(k,2));
end
assert(nnz(keep)>=3,'Insufficient valid bins for log-log fitting');
p=polyfit(log10(frequency(keep)),log10(power(keep)),1);
model.slope=p(1); model.exponent=-p(1); model.intercept=p(2);
model.background=10.^polyval(p,log10(max(frequency,realmin)));
model.frequency_hz=frequency; model.fit_mask=keep;
model.note='Linear log-log approximation, not specparam peak decomposition';
end
