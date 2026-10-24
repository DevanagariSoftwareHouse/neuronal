%% Test lazy multiscale overlapping interval indexing.
% No Signal Processing Toolbox or real recording is needed.
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','path'));

fs = 500;
N = 1000;
root = interval_at(N,fs,0,0,1);
assert(root.first==1 && root.last==N && root.n_windows==1);
assert(root.t0==0 && root.t1==N/fs);

w1 = interval_at(N,fs,1,0.5,1);
w2 = interval_at(N,fs,1,0.5,2);
w3 = interval_at(N,fs,1,0.5,3);
assert(w1.n_windows==3 && w1.first==1 && w1.last==500);
assert(w2.first==251 && w2.last==750);
assert(w3.first==501 && w3.last==1000);
assert(numel(intersect(w1.first:w1.last,w2.first:w2.last))==250);
assert(abs(w1.phase_step_rad-pi/2)<1e-12);
assert(abs(w2.frequency_hz-0.5)<1e-12);
assert(abs(w2.phase_rad-3*pi/2)<1e-12);

% Five phases need not mean five windows: at level 2, 50% overlap has 7.
w = interval_at(N,fs,2,0.5,7);
assert(w.n_windows==7 && w.last==N);
assert(abs(w.duration_s-0.5)<1e-12);
assert(abs(w.hop_s-0.25)<1e-12);

% Odd sample counts: no overrun and half-open boundaries.
Nodd = 1001;
for level=0:5
    for o=[0 .25 .5 .75]
        a = interval_at(Nodd,fs,level,o,1);
        for k=1:a.n_windows
            b=interval_at(Nodd,fs,level,o,k);
            assert(b.first>=1 && b.last<=Nodd && b.first<=b.last);
            clock = ((b.first:b.last)-1)/fs;
            assert(all(clock>=b.t0-1e-12 & clock<b.t1+1e-12));
        end
    end
end
disp('interval_at lazy interval checks completed')
