function [coefficient,meta,tree] = filter_wpt(x,fs,level,wavelet)
%FILTER_WPT Decimated terminal wavelet packet coefficients in frequency order.
% [C,M,TREE] = filter_wpt(X,FS,LEVEL,WAVELET); C is a cell per packet.
% Boundary extension follows WPDEC; coefficient counts need not sum to N.
% M.node_position gives zero-based tree positions (Gray-code ordering).
% These coefficients are not full-rate time-aligned signals.
% Example: [c,m,tr]=filter_wpt(randn(4096,1),500,4,'db4');
filter_require('wpdec');
validateattributes(x,{'numeric'},{'vector','real','finite','nonempty'});
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(level,{'numeric'},{'scalar','integer','positive','<=',floor(log2(numel(x)))});
assert(numel(x)*(level+1)<=2e7,'Tree too large');
tree=wpdec(double(x(:)'),level,wavelet);
n=2^level; q=uint32((0:n-1)'); positions=double(bitxor(q,bitshift(q,-1)));
coefficient=cell(n,1);
for k=1:n, coefficient{k}=wpcoef(tree,[level positions(k)]); end
edges=(0:n)'*fs/(2*n);
meta=struct('fs',fs,'level',level,'wavelet',wavelet, ...
    'node_position',positions,'nominal_edges_hz',[edges(1:end-1) edges(2:end)], ...
    'representation','decimated_wpt_coefficients');
end
