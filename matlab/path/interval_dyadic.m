function node = interval_dyadic(N, fs, level, overlap, k)
%INTERVAL_DYADIC Count dyadic windows or lazily retrieve one interval.
% n_windows = interval_dyadic(N, fs, level, overlap)
% node = interval_dyadic(N, fs, level, overlap, k)
% Omitting k returns the scalar number of complete windows.
% Supplying k returns the corresponding interval record (1-based).
% Width=T/2^level. Use overlap=0 for a partition.
% Both forms use the same validation and complete-window counting rule.
% Examples:
%   n = interval_dyadic(1000,500,3,.5);    % 15
%   w = interval_dyadic(1000,500,3,.5,n);  % last window
%   for k = 1:interval_dyadic(1000,500,3,.5)
%       w = interval_dyadic(1000,500,3,.5,k);
%   end

if nargin < 5
    first_node = interval_madic(N,fs,2,level,overlap,1);
    node = first_node.n_windows;
else
    node = interval_madic(N,fs,2,level,overlap,k);
end
end
