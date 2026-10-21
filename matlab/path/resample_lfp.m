function [output, new_srate, time] = resample_lfp(signal, srate, numerator, denominator)
%RESAMPLE_LFP Polyphase rate conversion with antialias filtering.
%   [Y,NEW_FS,T] = resample_lfp(X,FS,P,Q)
%   Converts samples-by-channels by rational P/Q; vectors retain
%   orientation. MATLAB RESAMPLE designs the FIR antialias filter.
%   Record original acquisition filters separately; no digital resampling
%   recovers frequencies already lost or aliased during acquisition.
%
%   Example:
%       y = resample_lfp(x, 2000, 1, 4); % 500 Hz output
%
%   See also RESAMPLE, FILTER_RESPONSE.
    validateattributes(signal, {'numeric'}, ...
        {'2d','real','finite','nonempty'});
    validateattributes(srate, {'numeric'}, ...
        {'scalar','real','finite','positive'});
    validateattributes(numerator, {'numeric'}, ...
        {'scalar','integer','positive'});
    validateattributes(denominator, {'numeric'}, ...
        {'scalar','integer','positive'});
    was_row = isrow(signal);
    if isvector(signal), x = double(signal(:)); else, x = double(signal); end
    [p,q] = rat(double(numerator)/double(denominator),1e-12);
    assert(p>0 && q>0 && p<=1e4 && q<=1e4, ...
        'Rational conversion factors exceed safety limits');
    output = resample(x,p,q);
    new_srate = srate*p/q;
    time = (0:size(output,1)-1)'/new_srate;
    if was_row, output = output.'; end
end
