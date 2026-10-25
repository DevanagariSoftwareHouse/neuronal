%% b01_bootstrap_firing_rate_area.m

run analysis/a00_startup.m

%%


area = 'lfp_1';

levels = 0:7;

number = arrayfun(@(l)interval_dyadic(250,1,l,.5),levels);
frequency_bands = arrayfun(@(l)interval_dyadic(250,1,l,.5,'all'),levels,'UniformOutput',false);


%%

dd = 1
lfp_areas = {'lfp_1','lfp_2','lfp_3'}


for fb = 1 
eegfilt(gpuArray(data(dd).(lfp_areas{1}).Data.x(:,:))

%%
sum(number)

%%
for ll = 1 : numel(levels)
    
    frequency_interval = interval_dyadic(250,1,levels(end),.5);
    
end
%%


%%
%% CPU versus GPU scaling benchmark
% MATLAB R2019a

sizes = [ ...
    1e3, 1e4, 1e5, ...
    1e6, 5e6, 1e7 ...
];

cpu_time = zeros(size(sizes));
gpu_time = zeros(size(sizes));
speedup  = zeros(size(sizes));

g = gpuDevice;

for k = 1:numel(sizes)

    N = sizes(k);

    x = rand(N,1,'single');
    g = gpuDevice;
    x_gpu = gpuArray(x);

    f_cpu = @() sum(x.^2);
    f_gpu = @() sum(x_gpu.^2);

    % Warm up the GPU
    f_gpu();
    wait(g);

    cpu_time(k) = timeit(f_cpu);
    

    speedup(k) = cpu_time(k)/gpu_time(k);

    fprintf( ...
        'N=%d | CPU=%.6f | GPU=%.6f | %.2fx\n', ...
        N,cpu_time(k),gpu_time(k),speedup(k));

end

figure

semilogx(sizes,speedup,'-o','LineWidth',2);
hold on
yline(1,'--');

xlabel('Number of elements');
ylabel('GPU speedup over CPU');
title('RTX 3050: GPU vs CPU');
grid on
