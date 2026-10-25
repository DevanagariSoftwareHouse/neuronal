function y = filter_forward_backward(x,d)
%FILTER_FORWARD_BACKWARD Offline zero-phase filtering of a complete record.
% Y = filter_forward_backward(X,D). X is samples-by-channels or a vector.
% Uses FILTFILT default boundary handling; effective interior magnitude is
% |H|^2. Independent chunks are NOT equivalent to a whole-record call.
% Example: y=filter_forward_backward(x,filter_butterworth(500,[4 12],4));
[y,row]=filter_input(x);
if ~strcmp(d.kind,'identity')
    if strcmp(d.form,'sos'), y=filtfilt(d.sos,d.gain,y);
    else, y=filtfilt(d.b,d.a,y); end
end
if row, y=y.'; end
end
