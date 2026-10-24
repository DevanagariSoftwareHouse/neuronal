function manifest = filter_write(folder,value,metadata,precision)
%FILTER_WRITE Persist an immutable typed array as binary plus manifest.
% M = filter_write(FOLDER,VALUE,METADATA,PRECISION); precision single/double.
% Required METADATA fields: representation, units, source, configuration.
% Add fs, frequency axes, channel IDs, edge masks, software versions etc.
% Allowed representations: voltage, complex_coefficients, power, phase,
% source_density. Complex data use real then imaginary planes in data.bin.
% Uses little-endian column-major order, temporary directory and final rename.
% FOLDER must not exist. Use one writer per destination. This serializes an
% existing array; it does not make its computation out-of-core or resumable.
% Example: m=struct('representation','voltage','units','uV', ...
%   'source','session/channel','configuration',d,'fs',500);
%   filter_write('derived/example',y,m,'single');
if nargin<4, precision='single'; end
precision=validatestring(precision,{'single','double'});
validateattributes(value,{'numeric'},{'nonempty','nonsparse'});
assert(isstruct(metadata) && isscalar(metadata),'Metadata must be a scalar struct');
required={'representation','units','source','configuration'};
assert(all(isfield(metadata,required)),'Metadata needs representation, units, source, configuration');
metadata.representation=validatestring(metadata.representation, ...
    {'voltage','complex_coefficients','power','phase','source_density'});
assert(isreal(value) || strcmp(metadata.representation,'complex_coefficients'), ...
    'Complex arrays require complex_coefficients representation');
folder=char(folder); assert(~isempty(folder),'Folder must be nonempty');
assert(exist(folder,'file')==0,'Destination already exists; choose a new artifact folder');
parent=fileparts(folder); if isempty(parent), parent=pwd; end
if ~exist(parent,'dir'), [ok,msg]=mkdir(parent); assert(ok,msg); end
stage=tempname(parent); [ok,msg]=mkdir(stage); assert(ok,msg);
cleanup=onCleanup(@() cleanup_stage(stage));
fid=fopen(fullfile(stage,'data.bin'),'w','ieee-le');
assert(fid>=0,'Cannot open binary output');
try
    count=fwrite(fid,real(value),precision);
    assert(count==numel(value),'Incomplete real plane');
    is_complex=~isreal(value);
    if is_complex
        count=fwrite(fid,imag(value),precision);
        assert(count==numel(value),'Incomplete imaginary plane');
    end
    status=fclose(fid); fid=-1; assert(status==0,'Binary close failed');
catch err
    if fid>=0, fclose(fid); end
    rethrow(err)
end
bytes=4; if strcmp(precision,'double'), bytes=8; end
manifest=struct('version',1,'shape',size(value),'precision',precision, ...
    'byte_order','ieee-le','is_complex',is_complex, ...
    'bytes',numel(value)*bytes*(1+is_complex),'metadata',metadata);
save(fullfile(stage,'manifest.mat'),'manifest','-v7');
assert(exist(folder,'file')==0,'Destination appeared while writing');
[ok,msg]=movefile(stage,folder); assert(ok,msg);
clear cleanup
end

function cleanup_stage(stage)
if exist(stage,'dir'), rmdir(stage,'s'); end
end
