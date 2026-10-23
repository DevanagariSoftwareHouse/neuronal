function [filtered, b] = fir_filter_lfp(signal, srate, mode, cutoff_hz, order, window)
%FIR_FILTER_LFP General linear-phase FIR low/high/bandpass/bandstop filter.
%   [Y,B] = fir_filter_lfp(X, FS, MODE, CUTOFF, ORDER, WINDOW)
%   X is samples-by-channels, or a vector preserving orientation.
%   MODE: 'low', 'high', 'bandpass', or 'stop'/'bandstop'.
%   CUTOFF is a scalar for low/high, [LOW HIGH] for band/stop.
%   ORDER defaults to 100 and must be even (type-I symmetric FIR).
%   WINDOW defaults to 'hamming'; 'hann', 'blackman', 'kaiser' supported.
%   Alternatively WINDOW may be a numeric vector of ORDER+1 weights.
%   Filtering uses FILTFILT, which squares the designed filter magnitude
%   response and is acausal; inspect the effective response and edges.
%
%   Example:
%       fs = 1000; t = (0:fs*4-1)'/fs;
%       x = sin(2*pi*8*t) + sin(2*pi*100*t);
%       [y,b] = fir_filter_lfp(x, fs, 'bandpass', [4 12], 100, 'kaiser');
%
%   Requires MATLAB Signal Processing Toolbox.
    if nargin < 5 || isempty(order), order = 100; end
    if nargin < 6 || isempty(window), window = 'hamming'; end
    validateattributes(signal, {'numeric'}, {'2d','real','finite','nonempty'});
    validateattributes(srate, {'numeric'}, {'scalar','real','finite','positive'});
    validateattributes(order, {'numeric'}, {'scalar','integer','positive'});
    assert(mod(order,2) == 0, 'FIR order must be even');
    assert(ischar(mode) || (isstring(mode) && isscalar(mode)));
    mode = lower(char(mode));
    cutoff_hz = double(cutoff_hz(:)');
    assert(all(isfinite(cutoff_hz)) && all(cutoff_hz > 0) ...
        && all(cutoff_hz < srate/2), 'Cutoffs must lie below Nyquist');
    switch mode
        case {'low','lowpass'}
            kind = 'low'; assert(numel(cutoff_hz)==1);
        case {'high','highpass'}
            kind = 'high'; assert(numel(cutoff_hz)==1);
        case {'bandpass','pass'}
            kind = 'bandpass'; assert(numel(cutoff_hz)==2);
        case {'bandstop','stop','notch'}
            kind = 'stop'; assert(numel(cutoff_hz)==2);
        otherwise
            error('Unknown filter mode');
    end
    assert(issorted(cutoff_hz) && numel(unique(cutoff_hz))==numel(cutoff_hz), ...
        'Cutoffs must be strictly increasing');
    if isnumeric(window)
        w = double(window(:));
        assert(numel(w)==order+1 && all(isfinite(w)));
    else
        switch lower(char(window))
            case 'hamming', w = hamming(order+1);
            case 'hann', w = hann(order+1);
            case 'blackman', w = blackman(order+1);
            case 'kaiser', w = kaiser(order+1,8);
            otherwise, error('Unsupported FIR window');
        end
    end
    b = fir1(order,cutoff_hz/(srate/2),kind,w);
    was_row = isrow(signal);
    if isvector(signal), x = double(signal(:)); else, x = double(signal); end
    assert(size(x,1) > 3*order, 'Insufficient samples for filtfilt padding');
    filtered = filtfilt(b,1,x);
    if was_row, filtered = filtered.'; end
end
