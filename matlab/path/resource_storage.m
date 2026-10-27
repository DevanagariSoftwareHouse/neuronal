function r = resource_storage(path,varargin)
%RESOURCE_STORAGE Inspect filesystem capacity and Linux I/O pressure.
%   R = RESOURCE_STORAGE(PATH) returns filesystem space available for PATH.
%   R = RESOURCE_STORAGE(PATH,'expected_write_bytes',N,'min_free_bytes',M)
%   checks whether an N-byte write can preserve M bytes of headroom.
%
%   Options:
%     expected_write_bytes  Planned write size, in bytes (default 0).
%     min_free_bytes        Additional free-space floor (default 0).
%     safety_fraction       Keep this fraction of total space (default 0.05).
%     fail_if_insufficient  Throw if R.ready is false (default false).
%
%   Works in MATLAB R2019a on Linux (and other systems with Java).
%   This is a snapshot, NOT a reservation or cross-process lock.
%   Multiple workers must use a separate coordinated resource_acquire.
%
%   Example:
%     r = resource_storage('data/derived', ...
%         'expected_write_bytes',8*2^30,'min_free_bytes',2*2^30);
%
if nargin < 1 || isempty(path)
    path = pwd;
end
if isstring(path)
    if ~isscalar(path), error('resource:StoragePath','Path must be scalar.'); end
    path = char(path);
end
validateattributes(path,{'char'},{'row'},mfilename,'path');

p = inputParser;
p.FunctionName = mfilename;
p.PartialMatching = false;
addParameter(p,'expected_write_bytes',0,@validBytes);
addParameter(p,'min_free_bytes',0,@validBytes);
addParameter(p,'safety_fraction',0.05,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=0&&x<1);
addParameter(p,'fail_if_insufficient',false,@(x)islogical(x)&&isscalar(x));
parse(p,varargin{:});
o = p.Results;

% Check the closest existing ancestor, without creating any directories.
jpath = java.io.File(path).getAbsoluteFile();
requested = char(jpath.getCanonicalPath());
while ~jpath.exists()
    parent = jpath.getParentFile();
    if isempty(parent)
        error('resource:StoragePath','No existing ancestor for %s.',requested);
    end
    jpath = parent;
end
if ~jpath.isDirectory()
    jpath = jpath.getParentFile();
end
if isempty(jpath) || ~jpath.isDirectory()
    error('resource:StoragePath','No accessible directory for %s.',requested);
end
existing = char(jpath.getCanonicalPath());

total = double(jpath.getTotalSpace());
usable = double(jpath.getUsableSpace());
free = double(jpath.getFreeSpace());
if total <= 0
    error('resource:StorageUnavailable','Cannot determine filesystem capacity at %s.',existing);
end
headroom = max(o.min_free_bytes,o.safety_fraction*total);
remaining = usable - headroom - o.expected_write_bytes;

r = struct();
r.path = requested;
r.existing_path = existing;
r.total_bytes = total;
r.free_bytes = free;             % Includes space not available to this user.
r.usable_bytes = usable;         % Space available to this process/user.
r.used_fraction = max(0,min(1,(total-free)/total));
r.expected_write_bytes = double(o.expected_write_bytes);
r.headroom_bytes = headroom;
r.remaining_bytes = remaining;
r.ready = remaining >= 0;
r.io_pressure = readIoPressure();

% df -P reports the filesystem backing the existing parent, not each NVMe.
% Use a safely quoted absolute path: single quotes become shell-safe '\''.
r.filesystem = '';
r.mount_point = '';
if isunix
    quoted = ['''' strrep(existing,'''','''\''''') ''''];
    [status,out] = system(['LC_ALL=C df -P ' quoted ' 2>/dev/null']);
    if status == 0
        lines = regexp(strtrim(out),'\r?\n','split');
        if numel(lines) >= 2
            parts = regexp(strtrim(lines{end}),'\s+','split');
            if numel(parts) >= 6
                r.filesystem = parts{1};
                r.mount_point = strjoin(parts(6:end),' ');
            end
        end
    end
end
if o.fail_if_insufficient && ~r.ready
    error('resource:StorageInsufficient', ...
        'Insufficient usable space at %s: need %.0f B more.', ...
        existing,-remaining);
end
end

function tf = validBytes(x)
tf = isnumeric(x) && isscalar(x) && isfinite(x) && x>=0;
end

function pressure = readIoPressure()
% Kernel PSI: averages are percentages of time stalled, not disk bandwidth.
pressure = struct('some_avg10',NaN,'some_avg60',NaN, ...
    'some_avg300',NaN,'full_avg10',NaN,'full_avg60',NaN, ...
    'full_avg300',NaN);
file = '/proc/pressure/io';
if exist(file,'file')~=2, return; end
try
    contents = fileread(file);
    kinds = {'some','full'};
    windows = {'avg10','avg60','avg300'};
    for k = 1:numel(kinds)
        line = regexp(contents,['(?m)^' kinds{k} ' [^\n]*'],'match','once');
        if isempty(line), continue; end
        for w = 1:numel(windows)
            tok = regexp(line,[windows{w} '=([0-9.]+)'],'tokens','once');
            if ~isempty(tok)
                pressure.([kinds{k} '_' windows{w}]) = str2double(tok{1});
            end
        end
    end
catch
    % PSI is optional. Capacity measurements remain useful.
end
end
