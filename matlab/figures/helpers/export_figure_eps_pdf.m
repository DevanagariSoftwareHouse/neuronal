function paths = export_figure_eps_pdf(fig, basepath)
%EXPORT_FIGURE_EPS_PDF Export figure to EPS and PDF with vector rendering.
%   PATHS = EXPORT_FIGURE_EPS_PDF(FIG, BASEPATH) creates BASEPATH.eps
%   and BASEPATH.pdf. Errors propagate to the caller.

validateattributes(fig, {'matlab.ui.Figure'}, {'scalar'}, mfilename, 'fig');
if isstring(basepath)
    basepath = char(basepath);
end
assert(ischar(basepath) && ~isempty(basepath), ...
    'basepath must be a nonempty character vector.');
[parent_dir, ~, ~] = fileparts(basepath);
if ~isempty(parent_dir) && ~exist(parent_dir, 'dir')
    mkdir(parent_dir);
end

paths = struct('eps_path', [basepath '.eps'], ...
               'pdf_path', [basepath '.pdf']);
% For plots containing only lines and text, Painters keeps the output vector.
print(fig, paths.eps_path, '-depsc2', '-painters');
print(fig, paths.pdf_path, '-dpdf', '-painters');

assert(exist(paths.eps_path, 'file') == 2, 'EPS was not created.');
assert(exist(paths.pdf_path, 'file') == 2, 'PDF was not created.');
end
