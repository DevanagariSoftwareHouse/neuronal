function test_session_window_filter_disk()
% Integration regression: requires MATLAB, Signal Processing Toolbox.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'matlab','path'));
script = fullfile(root,'analysis','+con2phys','t03_session_window_filter.m');
folder = tempname; mkdir(folder);
cleanup = onCleanup(@() rmdir(folder,'s')); %#ok<NASGU>
N = 512; Fs = 500; t = (0:N-1)'/Fs;
x = [sin(2*pi*23*t)+0.3*cos(2*pi*61*t), cos(2*pi*17*t)];
p1 = fullfile(folder,'columns.bin'); p2 = fullfile(folder,'rows.bin');
fid = fopen(p1,'wb'); fwrite(fid,x,'double'); fclose(fid);
fid = fopen(p2,'wb'); fwrite(fid,x.','double'); fclose(fid);
data = struct('id','test','n_lfp_samples',N,'srate',Fs, ...
    'lfp_1',memmapfile(p1,'Format',{'double',[N 2],'x'}), ...
    'lfp_2',memmapfile(p2,'Format',{'double',[2 N],'x'}));
cfg = struct('sessions',1,'areas',{{'lfp_1','lfp_2'}},'channels',1, ...
    'time_levels',0:2,'frequency_levels',0:1, ...
    'output_dir',fullfile(folder,'out'));
run(script);
outdir = fullfile(cfg.output_dir,'session_test');
a = load(fullfile(outdir,'lfp_1_ch001.mat'));
b = load(fullfile(outdir,'lfp_2_ch001.mat'));
assert(all(a.completed) && isequal(size(a.mean_amplitude),[11 4]));
names = {'mean_amplitude','median_amplitude','mean_angular_speed', ...
    'median_negative_acceleration','n_negative_acceleration', ...
    'median_positive_acceleration','n_positive_acceleration'};
for k = 1:numel(names)
    assert(isequaln(a.(names{k}),b.(names{k})), 'Layout mismatch.');
end
% Full-session identity column independently checked against direct formulas.
z = hilbert(x(:,1)); v = diff(unwrap(angle(z)))*Fs; acc = diff(v)*Fs;
expected = [mean(abs(z)),median(abs(z)),mean(v), ...
    median(acc(acc<0)),sum(acc<0),median(acc(acc>0)),sum(acc>0)];
for k = 1:numel(names)
    actual = a.(names{k})(1,1);
    assert(abs(actual-expected(k)) <= 1e-10*max(1,abs(expected(k))));
end
% Incomplete columns are recomputed; completed columns remain untouched.
m = matfile(fullfile(outdir,'lfp_1_ch001.mat'),'Writable',true);
m.mean_amplitude(:,2) = zeros(11,1);
m.completed(1,2) = false;
m.mean_amplitude(1,1) = -123;
run(script);
assert(m.mean_amplitude(1,1)==-123);
assert(isequal(m.mean_amplitude(:,2),a.mean_amplitude(:,2)));
assert(m.completed(1,2));
% Resume with changed settings must fail instead of mixing incompatible data.
cfg.phase = 'zero'; rejected = false;
try
    run(script);
catch ME
    rejected = ~isempty(strfind(ME.message,'metadata differs')); %#ok<STREMP>
end
assert(rejected, 'Incompatible settings were not rejected.');
clear data m
fprintf('Disk-backed window-filter tests passed.\n');
end
