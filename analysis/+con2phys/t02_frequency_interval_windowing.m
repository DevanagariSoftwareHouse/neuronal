%% b01_bootstrap_firing_rate_area.m

run analysis/a00_startup.m

%%

windows_mat = load('session_windows.mat')

%%

[data(:).window] = windows_mat.session_windows{:}
%%

clear windows_mat
%%

frequency_band_levels = 1:7;

frequency_bands = arrayfun(@(l)interval_dyadic(250, 1, l,.5,'all'),frequency_band_levels,'UniformOutput',false);
frequency_bands = vertcat(frequency_bands{:});
%%
gpus = struct()
gpus.device = gpuDevice
%%
clc
for dd = 1 %: numel(data)
    
    lfp_area = {'lfp_1','lfp_2','lfp3'};
    
    for la = 1 : numel(lfp_area)
        gpus.data = gpuArray(data(dd).(lfp_area{la}).Data.x);
    
        for ch = 1 : size(gpus.data,2)
            signal = gpus.data(:,ch);
            srate  = 500;
            
            for ff = 1 : numel(frequency_bands)
                f = frequency_bands(ff);

                fd = filter_design('butterworth',srate,[f.t0 f.t1],4)
                
                if ff == 1 
                    filtered = filter_do(signal,srate,fd);
                    plot(filtered)
                else
                    return
                end
                return
            end
        end
    end
end