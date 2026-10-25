
%% GPU correctness and performance test

g = gpuDevice;
disp(g.Name)
disp(g.ComputeCapability)

N = 1e6;
x = rand(N,1,'single');

% CPU reference
f_cpu = @() sum(x.^2);
t_cpu = timeit(f_cpu);

% Upload once
x_gpu = gpuArray(x);

% Warm up CUDA
sum(x_gpu.^2);
wait(g);

% Measure computation, excluding transfer
f_gpu = @() sum(x_gpu.^2);
t_gpu = gputimeit(f_gpu);

% Compare results
cpu_result = f_cpu();
gpu_result = gather(f_gpu());

relative_error = abs(double(cpu_result) - ...
    double(gpu_result)) / abs(double(cpu_result));

fprintf('CPU: %.6f seconds\n',t_cpu);
fprintf('GPU: %.6f seconds\n',t_gpu);
fprintf('Speedup: %.2fx\n',t_cpu/t_gpu);
fprintf('Relative error: %.3e\n',relative_error);
