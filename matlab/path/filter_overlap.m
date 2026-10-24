function node = filter_overlap(fs, width_hz, overlap, k)
%FILTER_OVERLAP Lazy sliding frequency intervals of explicit width in Hz.
% N = filter_overlap(FS,WIDTH_HZ,OVERLAP)
% NODE = filter_overlap(...,K); K is 1-based or 'all'.
% Full intervals only. A final partial tail is omitted.
% Example: bands = filter_overlap(500,5,.5,'all');
if nargin < 4, k = []; end
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(width_hz,{'numeric'},{'scalar','real','finite','positive','<=',fs/2});
node=filter_frequency_node(fs,width_hz,overlap,k);
end
