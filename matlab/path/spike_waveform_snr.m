function metric = spike_waveform_snr(template,baseline_noise)
%SPIKE_WAVEFORM_SNR Template peak amplitude divided by robust noise.
% Channel x waveform and channel x baseline samples, respectively.
%
%   SYNTAX
%     metric = spike_waveform_snr(template,baseline_noise)
%
%   INPUTS
%     template: Finite channels-by-waveform-samples matrix with >=2 samples.
%     baseline_noise: Matching channels-by-baseline-samples matrix with >=10 samples and
%       positive robust noise scale per channel.
%
%   OUTPUTS
%     metric: Struct: snr (maximum channel SNR), channel (1-based maximizing channel),
%       by_channel (column of amplitude/robust-SD ratios).
%
%   EXAMPLE
%     rng(7); template = [-1 -3 1 0;-0.5 -1 0.5 0];
%     metric = spike_waveform_snr(template,0.2*randn(2,1000));
%     % SNR uses peak absolute template amplitude, not peak-to-peak amplitude.
%
a=double(template); b=double(baseline_noise);
assert(size(a,1)==size(b,1) && size(a,2)>=2 && size(b,2)>=10);
assert(all(isfinite(a(:))) && all(isfinite(b(:))));
sigma=median(abs(bsxfun(@minus,b,median(b,2))),2)/.67448975;
assert(all(sigma>0));
values=max(abs(a),[],2)./sigma;
[metric.snr,metric.channel]=max(values);
metric.by_channel=values;
end
