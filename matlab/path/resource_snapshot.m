function s = resource_snapshot(varargin)
%RESOURCE_SNAPSHOT Inspect Linux RAM, CPU pressure, disk and optional GPU.
% s = resource_snapshot('gpu',false,'disk_path',tempdir)
% Linux / MATLAB R2019a. GPU queries run only on the MATLAB client.
% Available values can change immediately; this is NOT a reservation.
p = inputParser;
p.addParameter('gpu',false,@(x)islogical(x)&&isscalar(x));
p.addParameter('disk_path','',@(x)ischar(x)||isstring(x));
p.parse(varargin{:});
opt = p.Results;
s = struct('timestamp',now,'ram_total',NaN,'ram_available',NaN, ...
    'ram_free',NaN,'swap_free',NaN,'cpu_load1',NaN,'cpu_count',NaN, ...
    'disk_available',NaN,'gpu_available',NaN,'gpu_total',NaN, ...
    'gpu_supported',false,'gpu_error','');
if isunix && exist('/proc/meminfo','file') == 2
    fid=fopen('/proc/meminfo','r');
    if fid>=0
        c=onCleanup(@()fclose(fid));
        while ~feof(fid)
            line=fgetl(fid);
            if ~ischar(line), break; end
            t=regexp(line,'^(MemTotal|MemAvailable|MemFree|SwapFree):\s*(\d+)\s*kB','tokens','once');
            if isempty(t), continue; end
            switch t{1}
                case 'MemTotal', s.ram_total=str2double(t{2})*1024;
                case 'MemAvailable', s.ram_available=str2double(t{2})*1024;
                case 'MemFree', s.ram_free=str2double(t{2})*1024;
                case 'SwapFree', s.swap_free=str2double(t{2})*1024;
            end
        end
        clear c;
    end
end
if isunix && exist('/proc/loadavg','file')==2
    fid=fopen('/proc/loadavg','r');
    if fid>=0
        c=onCleanup(@()fclose(fid));
        line=fgetl(fid);
        if ischar(line)
            t=sscanf(line,'%f',1);
            if ~isempty(t), s.cpu_load1=t; end
        end
        clear c;
    end
end
try
    s.cpu_count=feature('numcores');
catch
    % Unknown CPU count is represented by NaN.
end
path=char(opt.disk_path);
if ~isempty(path)
    assert(isfolder(path),'resource_snapshot:DiskPath','Disk path must exist.');
    try
        f=java.io.File(path);
        s.disk_available=double(f.getUsableSpace());
    catch
        % MATLAB running without Java, or inaccessible mount.
    end
end
if opt.gpu
    try
        g=gpuDevice();
        s.gpu_total=double(g.TotalMemory);
        s.gpu_available=double(g.AvailableMemory);
        s.gpu_supported=true;
    catch ME
        s.gpu_error=ME.message;
    end
end
end
