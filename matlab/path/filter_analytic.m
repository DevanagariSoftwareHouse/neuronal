function z = filter_analytic(x)
%FILTER_ANALYTIC Hilbert analytic signal of already filtered real voltage.
% Z = filter_analytic(X); X samples-by-channels or vector; shape preserved.
% Complex Z has the same voltage units. No band selection is performed.
% Phase interpretation needs a meaningful narrowband signal and edge mask.
% Example: z=filter_analytic(filter_forward_backward(x,d));
[x,row]=filter_input(x); z=hilbert(x);
if row, z=z.'; end
end
