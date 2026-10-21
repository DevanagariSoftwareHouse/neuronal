function response = filter_response(b, a, srate, nfft, zero_phase)
%FILTER_RESPONSE Inspect coefficients, effective response and transients.
%   R = filter_response(B, A, FS, NFFT, ZERO_PHASE)
%   B,A are causal transfer coefficients, with A=1 for an FIR.
%   FS sampling frequency Hz, NFFT default 4096, ZERO_PHASE default false.
%   R.frequency, magnitude, attenuation_db, phase_rad, group_delay_samples,
%   impulse, step, impulse_time, transfer are returned.
%   ZERO_PHASE=true describes the *interior idealized* forward/backward
%   response |H(f)|^2, zero phase and zero group delay; finite-record
%   FILTFILT edge padding is NOT represented by this idealization.
%   Impulse is a centered approximation of the effective acausal kernel.
%
%   Example:
%       b = fir1(100,[4 12]/250);
%       r = filter_response(b,1,500,4096,true);
%       plot(r.frequency,r.attenuation_db); xlim([0 50]);
%
%   See also FILTER_EDGE_MASK, FREQZ, GRPDELAY.
    if nargin < 4 || isempty(nfft), nfft = 4096; end
    if nargin < 5 || isempty(zero_phase), zero_phase = false; end
    validateattributes(b,{'numeric'},{'vector','finite','nonempty'});
    validateattributes(a,{'numeric'},{'vector','finite','nonempty'});
    validateattributes(srate,{'numeric'},{'scalar','positive','finite'});
    validateattributes(nfft,{'numeric'},{'scalar','integer','>=',16});
    assert(islogical(zero_phase) && isscalar(zero_phase));
    b = double(b(:)'); a = double(a(:)');
    assert(a(1)~=0, 'Leading denominator coefficient must be nonzero');
    [h, f] = freqz(b,a,nfft,srate);
    if zero_phase
        transfer = abs(h).^2;
        phase = zeros(size(h));
        delay = zeros(size(h));
        % Centered impulse from a finite sampled approximation of |H|^2.
        n = 2*nfft;
        [hw, ~] = freqz(b,a,n,'whole');
        spectrum = abs(hw).^2;
        impulse = real(fftshift(ifft(spectrum)));
        impulse_time = ((0:n-1)'-floor(n/2))/srate;
    else
        transfer = h;
        phase = unwrap(angle(h));
        [delay,~] = grpdelay(b,a,nfft,srate);
        impulse = impz(b,a,min(8192,max(512,8*max(numel(a),numel(b)))));
        impulse_time = (0:numel(impulse)-1)'/srate;
    end
    response.frequency = f(:);
    response.transfer = transfer(:);
    response.magnitude = abs(transfer(:));
    response.attenuation_db = 20*log10(max(response.magnitude,realmin));
    response.phase_rad = phase(:);
    response.group_delay_samples = delay(:);
    response.impulse = impulse(:);
    response.impulse_time = impulse_time(:);
    response.step = cumsum(impulse(:));
    response.zero_phase = zero_phase;
    response.note = ['Finite-record filter padding and boundary transients ' ...
                     'must be evaluated on the actual record'];
end
