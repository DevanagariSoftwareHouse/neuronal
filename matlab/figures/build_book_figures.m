function manifest = build_book_figures(output_dir)
%BUILD_BOOK_FIGURES Reproduce pilot scientific figures and their manifest.
%   Run from any current directory after adding matlab/figures to path.
%   Output: matlab/build/figures/{*.eps,*.pdf,manifest.json,manifest.tsv}.
%   Requires base MATLAB; no input recordings or toolboxes.

this_dir = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(output_dir)
    output_dir = fullfile(fileparts(this_dir), 'build', 'figures');
end
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

original_path = path;
path_cleanup = onCleanup(@() path(original_path)); %#ok<NASGU>
addpath(fullfile(this_dir, 'generators'), fullfile(this_dir, 'helpers'));

manifest = [figure_lfp_forward_geometry(output_dir); ...
            figure_cable_attenuation_vs_frequency(output_dir)];

json_path = fullfile(output_dir, 'manifest.json');
fid = fopen(json_path, 'w');
assert(fid ~= -1, 'Could not open JSON manifest for writing.');
file_cleanup = onCleanup(@() fclose(fid));
fwrite(fid, jsonencode(manifest), 'char');
clear file_cleanup;

tsv_path = fullfile(output_dir, 'manifest.tsv');
fid = fopen(tsv_path, 'w');
assert(fid ~= -1, 'Could not open TSV manifest for writing.');
file_cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, 'figure_id\tchapter\tsource_matlab_function\toutput_eps\toutput_pdf\tcaption_short\tlatex_label\tstatus\treference_doi\n');
for k = 1:numel(manifest)
    item = manifest(k);
    fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
        item.figure_id, item.chapter, item.source_matlab_function, ...
        item.eps_path, item.pdf_path, item.caption, ...
        item.latex_label, item.status, item.reference_doi);
end
end
