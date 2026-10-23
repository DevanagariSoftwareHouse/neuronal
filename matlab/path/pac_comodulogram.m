function [mi, low_centers, high_centers] = pac_comodulogram(signal, srate, phase_bands, amplitude_bands, nbins)
%PAC_COMODULOGRAM Filter-Hilbert-Tort MI across pairs of frequency bands.
%   [MI,LOW,HIGH] = PAC_COMODULOGRAM(X,FS,PBANDS,ABANDS,NBINS)
%   returns MI as [num_phase_bands x num_amplitude_bands].
%   Phase/amplitude extraction is reused across band combinations.
%
%   Inputs: X real finite LFP vector; FS sample rate in Hz;
%   PBANDS and ABANDS K-by-2 [low high] Hz; NBINS default 18.
%   Outputs: MI descriptive normalized KL divergence; band midpoints LOW,
%   HIGH (Hz). Filtering calls BANDPASS_LFP, phase calls ANALYTIC_PHASE.
%
%   Example:
%       fs = 500; t = (0:4999)'/fs;
%       x = (1+0.5*cos(2*pi*8*t)).*cos(2*pi*70*t) + cos(2*pi*8*t);
%       [mi, fphase, famp] = pac_comodulogram(x,fs,[6 10],[60 80],18);
%
%   Reference: Tort et al. (2010), tortlab/phase-amplitude-coupling.
%   Edge transients and non-sinusoidal waveform effects can cause spurious
%   PAC; trim edges and use surrogates before inferential interpretation.
%
    if nargin < 5 || isempty(nbins), nbins = 18; end
    validateattributes(signal, {'numeric'}, {'vector','real','finite','nonempty'});
    validateattributes(srate, {'numeric'}, {'scalar','finite','positive'});
    validateattributes(nbins, {'numeric'}, {'scalar','integer','>=',3});
    assert(size(phase_bands,2) == 2 && size(amplitude_bands,2) == 2, ...
        'Bands must have two columns [low high].');
    all_bands = [phase_bands; amplitude_bands];
    assert(all(isfinite(all_bands(:))) && all(all_bands(:,1) > 0) && ...
        all(all_bands(:,2) > all_bands(:,1)) && ...
        all(all_bands(:,2) < srate/2), 'Bands must be within Nyquist.');

    x = double(signal(:));
    np = size(phase_bands,1);
    na = size(amplitude_bands,1);
    phase = zeros(numel(x),np);
    envelope = zeros(numel(x),na);
    for i = 1:np
        y = bandpass_lfp(x,srate,phase_bands(i,:));
        phase(:,i) = analytic_phase(y);
    end
    for j = 1:na
        y = bandpass_lfp(x,srate,amplitude_bands(j,:));
        [~,envelope(:,j)] = analytic_phase(y);
    end

    mi = nan(np,na);
    for i = 1:np
        for j = 1:na
            mi(i,j) = modulation_index(phase(:,i),envelope(:,j),nbins);
        end
    end
    low_centers = mean(phase_bands,2);
    high_centers = mean(amplitude_bands,2);
end
