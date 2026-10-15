function out = figure_cable_attenuation_vs_frequency(output_dir)
%FIGURE_CABLE_ATTENUATION_VS_FREQUENCY Frequency filtering by a passive cable.
%   An infinite uniform passive cable has propagation factor
%   H(omega, x) = exp(-(x/lambda)*sqrt(1 + 1i*omega*tau_m)).
%   Display |H(omega,x)| / |H(0,x)| for selected distances.
%
%   This illustrates INTRACELLULAR cable voltage propagation, not the
%   transfer function from membrane currents to an LFP electrode.

if nargin < 1 || isempty(output_dir)
    matlab_dir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    output_dir = fullfile(matlab_dir, 'build', 'figures');
end

tau_m = 15e-3;                   % Membrane time constant, s.
f_hz = logspace(0, 3, 400);      % Frequencies in Hz.
lengths_over_lambda = [0.5, 1, 2];
complex_wave = sqrt(1 + 1i*2*pi*f_hz*tau_m);

fig = figure('Visible', 'off');
fig_cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
colors = lines(numel(lengths_over_lambda));
for k = 1:numel(lengths_over_lambda)
    ell = lengths_over_lambda(k);
    transfer_ratio = exp(-ell*(real(complex_wave)-1));
    semilogx(f_hz, transfer_ratio, 'LineWidth', 1.8, ...
        'Color', colors(k,:)); hold on;
end
set(gca, 'XScale', 'log');
xlabel('Frequency (Hz)');
ylabel('|H(f)| / |H(0)|');
title('Passive infinite-cable frequency attenuation');
legend({'x/\lambda = 0.5', 'x/\lambda = 1', 'x/\lambda = 2'}, ...
    'Interpreter', 'tex', 'Location', 'southwest', 'Box', 'off');
xlim([1 1000]); ylim([0 1.05]); grid on;
text(3, 0.16, '\tau_m = 15 ms', 'Interpreter', 'tex', 'FontSize', 10);
neuronal_figure_style(fig);

figure_id = 'fig_cable_attenuation_vs_frequency';
paths = export_figure_eps_pdf(fig, fullfile(output_dir, figure_id));
out = struct('figure_id', figure_id, ...
    'chapter', '05b_biophysics_inverse', ...
    'source_matlab_function', mfilename, ...
    'eps_path', paths.eps_path, 'pdf_path', paths.pdf_path, ...
    'caption', ['Frequency-dependent voltage attenuation in an ideal ' ...
       'infinite passive cable, normalized by its DC attenuation.'], ...
    'latex_label', 'fig:cable-attenuation-frequency', ...
    'status', 'draft', ...
    'reference_doi', '10.1038/nrn3599');
end
