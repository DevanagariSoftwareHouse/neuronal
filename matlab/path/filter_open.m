function [map,manifest] = filter_open(folder)
%FILTER_OPEN Validate and memory-map a FILTER_WRITE artifact, read-only.
% [MAP,M] = filter_open(FOLDER). MAP.Data.real contains the real plane;
% complex artifacts also have MAP.Data.imag. No full signal copy is made.
% Stored dimensions and metadata are retained; byte count must match.
% Example: [m,info]=filter_open('derived/example'); x=m.Data.real(1:500,1);
s=load(fullfile(folder,'manifest.mat'),'manifest'); manifest=s.manifest;
assert(manifest.version==1 && strcmp(manifest.byte_order,'ieee-le'),'Unsupported format');
[~,~,endian]=computer;
assert(endian=='L','memmapfile requires a little-endian host for this format');
precision=validatestring(manifest.precision,{'single','double'});
validateattributes(manifest.shape,{'numeric'},{'vector','integer','positive'});
assert(islogical(manifest.is_complex) && isscalar(manifest.is_complex),'Invalid complex flag');
bytes=4; if strcmp(precision,'double'), bytes=8; end
expected=prod(double(manifest.shape))*bytes*(1+manifest.is_complex);
assert(expected==manifest.bytes,'Inconsistent manifest');
filename=fullfile(folder,'data.bin'); info=dir(filename);
assert(numel(info)==1 && info.bytes==expected,'Missing or truncated binary artifact');
format={precision,manifest.shape,'real'};
if manifest.is_complex, format(2,:)={precision,manifest.shape,'imag'}; end
map=memmapfile(filename,'Format',format,'Repeat',1,'Writable',false);
end
