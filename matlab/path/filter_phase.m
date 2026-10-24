function phase = filter_phase(coefficient)
%FILTER_PHASE Wrapped phase in radians of explicit analytic coefficients.
% PHI = filter_phase(C); does not run Hilbert or bandpass implicitly.
% Zero-amplitude coefficients yield NaN because their phase is undefined.
% Example: phi=filter_phase(filter_analytic(y));
validateattributes(coefficient,{'numeric'},{'nonempty'});
phase=angle(coefficient); phase(abs(coefficient)==0)=NaN;
end
