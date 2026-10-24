function node = interval_dyadic(N, fs, level, overlap, k)
%INTERVAL_DYADIC Lazily generate a dyadic interval with explicit overlap.
% node = interval_dyadic(N, fs, level, overlap, k)
% Width=T/2^level. Use overlap=0 for a partition.
% Example: w = interval_dyadic(1000,500,2,.5,3);

node = interval_madic(N,fs,2,level,overlap,k);
end
