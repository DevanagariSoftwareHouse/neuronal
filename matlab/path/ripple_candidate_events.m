function events = ripple_candidate_events(signal,srate,band_hz,onset_z,peak_z)
%RIPPLE_CANDIDATE_EVENTS Robust-envelope high-frequency candidate screen.
% Liu et al. (2022): detections require review before claiming sharp-wave ripples.
% Defaults 120..200 Hz, suitable only if Nyquist > 200 Hz.
%
%   SYNTAX
%     events = ripple_candidate_events(signal,srate,band_hz,onset_z,peak_z)
%
%   INPUTS
%     signal: Finite real signal vector long enough for bandpass_lfp.
%     srate: Positive sampling rate in Hz; default band requires >400 Hz.
%     band_hz: [low high] strictly inside (0,srate/2); default [120 200].
%     onset_z: Envelope excursion threshold in robust z units; default 2.
%     peak_z: Minimum within-event robust z peak; default 5.
%
%   OUTPUTS
%     events: Table with start_s, exclusive stop_s, duration_s and peak_robust_z; only 25-150
%       ms nonboundary candidates retained; may be empty.
%
%   Requires Signal Processing Toolbox (filtering and hilbert).
%
%   EXAMPLE
%     rng(7); fs = 1000; t = (0:4999)'/fs;
%     x = 0.1*randn(size(t))+sin(2*pi*150*t).*exp(-((t-2)/0.03).^2);
%     events = ripple_candidate_events(x,fs,[120 200],2,5);
%     % A detected candidate still needs artifact and physiological checks.
%
if nargin<3 || isempty(band_hz), band_hz=[120 200]; end
if nargin<4 || isempty(onset_z), onset_z=2; end
if nargin<5 || isempty(peak_z), peak_z=5; end
x=double(signal(:)); assert(all(isfinite(x)),'Finite input required');
y=bandpass_lfp(x,srate,band_hz);
a=abs(hilbert(y)); baseline=median(a);
sigma=1.4826*median(abs(a-baseline));
assert(sigma>0,'Envelope has no robust variance');
z=(a-baseline)/sigma;
active=z>=onset_z;
starts=find(diff([false;active])==1);
stops=find(diff([active;false])==-1);
rows=zeros(0,4);
for k=1:numel(starts)
    first=starts(k); last=stops(k);
    length_s=(last-first+1)/srate;
    if first==1 || last==numel(x) || length_s<.025 || length_s>.150
        continue
    end
    peak=max(z(first:last));
    if peak>=peak_z
        rows(end+1,:)=[(first-1)/srate,last/srate,length_s,peak]; %#ok<AGROW>
    end
end
events=array2table(rows,'VariableNames', ...
    {'start_s','stop_s','duration_s','peak_robust_z'});
end
