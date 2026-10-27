function elapsed = resource_gpu_sync()
%RESOURCE_GPU_SYNC Synchronize outstanding operations on selected GPU.
% This does not wait for another process to release GPU memory.
t=tic;
g=gpuDevice();
wait(g);
elapsed=toc(t);
end
