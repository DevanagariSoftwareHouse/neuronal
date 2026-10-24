function [x, was_row] = filter_input(x)
% Internal common samples-by-channels validation (CPU double).
validateattributes(x, {'numeric'}, {'2d','real','finite','nonempty'});
was_row = isrow(x);
if isvector(x), x = x(:); end
x = double(x);
end
