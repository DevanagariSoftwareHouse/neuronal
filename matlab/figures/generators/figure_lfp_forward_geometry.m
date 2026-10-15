function out = figure_lfp_forward_geometry(output_dir)
%FIGURE_LFP_FORWARD_GEOMETRY Idealized line-source forward model.
%   Produces a geometric schematic and a depth profile computed from
%   phi = (i_line/(4*pi*sigma)) * integral(dz / distance).
%
%   Assumptions: infinite homogeneous isotropic ohmic volume conductor;
%   a finite straight line segment with uniform impressed source current.
%   Physiological return currents and recording-reference contributions
%   are intentionally omitted. The figure is an isolated-source example,
%   not a complete forward model of a current-conserving neuron.

if nargin < 1 || isempty(output_dir)
    matlab_dir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    output_dir = fullfile(matlab_dir, 'build', 'figures');
end

sigma = 0.30;         % Conductivity, S/m.
z1 = -200e-6;         % Source start, m.
z2 =  200e-6;         % Source end, m.
I_total = 1.0e-9;     % Total impressed outward current, A.
i_line = I_total / (z2-z1); % Current per unit length, A/m.
rho_um = [40 80 160];
z_um = linspace(-400, 400, 501);

fig = figure('Visible', 'off');
fig_cleanup = onCleanup(@() close(fig)); %#ok<NASGU>

% Left: planar projection of the 3-D line-source configuration.
subplot(1, 2, 1);
plot([0 0], [z1 z2]*1e6, 'k-', 'LineWidth', 4); hold on;
rho = 80; z_e = 100;
plot(rho, z_e, 'o', 'MarkerFaceColor', [0.13 0.42 0.72], ...
    'MarkerEdgeColor', [0.13 0.42 0.72], 'MarkerSize', 7);
plot([0 rho], [z_e z_e], '--', 'Color', [0.4 0.4 0.4]);
plot([0 rho], [0 z_e], ':', 'Color', [0.4 0.4 0.4]);
plot(0, 0, 'k.', 'MarkerSize', 13);
text(5, 165, 'uniform line source', 'FontSize', 9);
text(10, 117, '\rho', 'Interpreter', 'tex', 'FontSize', 11);
text(84, 110, 'electrode', 'FontSize', 9);
text(6, -220, 'z_1', 'Interpreter', 'tex');
text(6, 212, 'z_2', 'Interpreter', 'tex');
xlabel('Radial position (\mum)', 'Interpreter', 'tex');
ylabel('Axial position z (\mum)', 'Interpreter', 'tex');
title('Source-electrode geometry');
axis([-25 170 -300 300]); axis equal; grid on;

% Right: exact Green-function line integral, not a numerical quadrature.
subplot(1, 2, 2);
colors = lines(numel(rho_um));
for k = 1:numel(rho_um)
    r = rho_um(k)*1e-6;
    z = z_um*1e-6;
    potential = i_line/(4*pi*sigma) * ...
        (asinh((z2-z)/r) - asinh((z1-z)/r));
    plot(z_um, 1e6*potential, 'LineWidth', 1.5, ...
        'Color', colors(k,:)); hold on;
end
xlabel('Electrode depth z (\mum)', 'Interpreter', 'tex');
ylabel('Potential (\muV)', 'Interpreter', 'tex');
title('Idealized extracellular potential');
legend({'\rho = 40 \mum','\rho = 80 \mum','\rho = 160 \mum'}, ...
    'Interpreter', 'tex', 'Location', 'northeast', 'Box', 'off');
grid on;
neuronal_figure_style(fig);

figure_id = 'fig_lfp_forward_geometry';
paths = export_figure_eps_pdf(fig, fullfile(output_dir, figure_id));
out = struct('figure_id', figure_id, ...
    'chapter', '05b_biophysics_inverse', ...
    'source_matlab_function', mfilename, ...
    'eps_path', paths.eps_path, 'pdf_path', paths.pdf_path, ...
    'caption', ['Idealized extracellular field of a finite uniform line source ' ...
       'in an infinite isotropic conductor. Return currents are omitted.'], ...
    'latex_label', 'fig:lfp-forward-geometry', ...
    'status', 'draft', ...
    'reference_doi', '10.1038/nrn3599');
end
