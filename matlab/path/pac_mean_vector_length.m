function result = pac_mean_vector_length(phase,amplitude)
%PAC_MEAN_VECTOR_LENGTH Canolty et al. (2006); Huelsemann et al. (2019).
% DOI 10.1126/science.1128115; 10.3389/fnins.2019.00573.
% Low-frequency phase in radians; high-frequency envelope in original units.
%
%   SYNTAX
%     result = pac_mean_vector_length(phase,amplitude)
%
%   INPUTS
%     phase: Low-frequency phase vector in radians.
%     amplitude: Matching high-frequency envelope; only finite pairs with amplitude>=0 are
%       retained (>=2 needed).
%
%   OUTPUTS
%     result: Struct: raw_mvl (amplitude units), normalized_mvl (divided by mean amplitude; NaN
%       for zero mean), preferred_phase_rad, observations and note.
%
%   EXAMPLE
%     phase = linspace(-pi,pi,1001)'; amplitude = 1+0.5*cos(phase);
%     result = pac_mean_vector_length(phase,amplitude);
%     % Raw MVL depends on amplitude scale; normalized MVL removes that scale.
%
p=double(phase(:)); a=double(amplitude(:));
assert(numel(p)==numel(a) && ~isempty(p));
valid=isfinite(p)&isfinite(a)&a>=0;
assert(nnz(valid)>=2,'Requires >=2 valid matched observations');
p=p(valid); a=a(valid);
z=mean(a.*exp(1i*p));
result.raw_mvl=abs(z);
result.normalized_mvl=NaN;
if mean(a)>0, result.normalized_mvl=abs(z)/mean(a); end
result.preferred_phase_rad=angle(z);
result.observations=numel(a);
result.note='Descriptive estimate: use surrogates and harmonic controls';
end
