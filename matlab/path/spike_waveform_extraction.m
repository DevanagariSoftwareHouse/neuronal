function [waves,kept] = spike_waveform_extraction(recording,indices,before,after)
%SPIKE_WAVEFORM_EXTRACTION Event-aligned AP snippets from multichannel data.
% Input recording=channels x samples, indices=MATLAB one-based sample indices.
% Output spikes x channels x waveform_samples. NOT for downsampled LFP.
%
%   SYNTAX
%     [waves,kept] = spike_waveform_extraction(recording,indices,before,after)
%
%   INPUTS
%     recording: Real channels-by-samples numeric broadband recording.
%     indices: Finite positive integer event sample indices (1-based).
%     before: Nonnegative integer samples before each event.
%     after: Nonnegative integer samples after each event.
%
%   OUTPUTS
%     waves: Retained-spikes-by-channels-by-(before+after+1) single tensor; allocation limited
%       to 2e7 elements.
%     kept: Column of positions in the input indices vector with complete windows (not the
%       sample indices themselves).
%
%   EXAMPLE
%     recording = randn(2,1000); indices = [5;200;700];
%     [waves, kept] = spike_waveform_extraction(recording,indices,20,40);
%     % kept=[2;3]; the event at sample 5 lacks the requested pre-window.
%
assert(isnumeric(recording) && ismatrix(recording) && isreal(recording));
[nchannels,nsamples]=size(recording);
indices=double(indices(:));
assert(all(isfinite(indices)) && all(indices==floor(indices)) && all(indices>=1));
assert(before>=0 && after>=0 && before==floor(before) && after==floor(after));
kept=find(indices>before & indices+after<=nsamples);
width=before+after+1;
assert(numel(kept)*nchannels*width<=2e7,'Use smaller spike batches');
waves=zeros(numel(kept),nchannels,width,'single');
for k=1:numel(kept)
    fragment=recording(:,indices(kept(k))+(-before:after));
    waves(k,:,:)=reshape(single(fragment),[1 nchannels width]);
end
end
