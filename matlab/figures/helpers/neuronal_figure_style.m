function neuronal_figure_style(fig)
%NEURONAL_FIGURE_STYLE Apply a consistent, publication-oriented figure style.
%   This function changes only the supplied figure and its descendants.

validateattributes(fig, {'matlab.ui.Figure'}, {'scalar'}, mfilename, 'fig');
set(fig, 'Color', 'w', 'Units', 'inches', ...
    'Position', [1 1 7.2 3.5], 'PaperPositionMode', 'auto');
axes_handles = findall(fig, 'Type', 'axes');
for k = 1:numel(axes_handles)
    set(axes_handles(k), 'Box', 'off', 'TickDir', 'out', ...
        'LineWidth', 0.8, 'FontSize', 10, 'FontName', 'Helvetica');
end
end
