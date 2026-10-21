function results = filter_compare(signal, srate, frequencies, cycles)
%FILTER_COMPARE Probe a family of kernels and return reproducible diagnostics.
%   RESULTS = filter_compare(SIGNAL, SRATE, FREQUENCIES, CYCLES)
%   FREQUENCIES is a vector of center frequencies (Hz).
%   CYCLES is a scalar or a per-frequency vector, default 6.
%
%   Each RESULTS(k) is a FILTER_PROBE struct plus center_hz and cycles.
%   No implicit event detection or assumption of spectral peaks.
%
%   Example:
%       fs = 1000; t = (0:fs*2-1)'/fs;
%       x = sin(2*pi*80*t);
%       r = filter_compare(x, fs, [40 80 120], [4 6 8]);
%
%   See also FILTER_PROBE.
    if nargin < 4 || isempty(cycles), cycles = 6; end
    validateattributes(frequencies, {'numeric'}, ...
        {'vector', 'real', 'finite', 'nonempty', 'positive'});
    frequencies = double(frequencies(:));
    assert(all(frequencies < srate/2), 'Frequency must be below Nyquist');

    if isscalar(cycles), cycles = repmat(cycles, numel(frequencies), 1); end
    cycles = double(cycles(:));
    assert(numel(cycles) == numel(frequencies), ...
        'One cycle count required per frequency');
    assert(numel(frequencies) <= 100, 'At most 100 probes per call');

    results = repmat(struct(), numel(frequencies), 1);
    for k = 1:numel(frequencies)
        r = filter_probe(signal, srate, frequencies(k), cycles(k));
        r.center_hz = frequencies(k);
        r.cycles = cycles(k);
        results(k) = r;
    end
end
