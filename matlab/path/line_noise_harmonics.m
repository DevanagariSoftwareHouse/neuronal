function [filtered, centers] = line_noise_harmonics(signal, srate, fundamental_hz, bandwidth_hz, max_harmonics)
%LINE_NOISE_HARMONICS Sequentially attenuate line-frequency harmonics.
%   [Y,CENTERS] = line_noise_harmonics(X,FS,F0,BANDWIDTH,MAX_HARMONICS)
%   F0 defaults 60 Hz, BW defaults 2 Hz, MAX_HARMONICS all below
%   Nyquist. Uses NOTCH_LFP (zero-phase Butterworth bandstop).
%   Diagnose interference in the raw PSD BEFORE using this function.
%   Each notch removes neuronal activity in the same frequency range;
%   cumulative filtering can smear transients and distort ripple bands.
%
%   Example:
%       [clean,centers] = line_noise_harmonics(lfp,1000,60,2,3);
%
%   See also NOTCH_LFP, WELCH_PSD, FILTER_RESPONSE.
    if nargin < 3 || isempty(fundamental_hz), fundamental_hz = 60; end
    if nargin < 4 || isempty(bandwidth_hz), bandwidth_hz = 2; end
    validateattributes(signal, {'numeric'}, ...
        {'2d','real','finite','nonempty'});
    validateattributes(srate, {'numeric'}, ...
        {'scalar','real','finite','positive'});
    validateattributes(fundamental_hz, {'numeric'}, ...
        {'scalar','real','finite','positive'});
    validateattributes(bandwidth_hz, {'numeric'}, ...
        {'scalar','real','finite','positive'});
    available = floor((srate/2-bandwidth_hz/2-1e-9)/fundamental_hz);
    if nargin < 5 || isempty(max_harmonics)
        max_harmonics = max(0,available);
    end
    validateattributes(max_harmonics, {'numeric'}, ...
        {'scalar','integer','nonnegative'});
    centers = fundamental_hz*(1:min(available,max_harmonics));
    filtered = signal;
    for k = 1:numel(centers)
        filtered = notch_lfp(filtered,srate,centers(k),bandwidth_hz);
    end
end
