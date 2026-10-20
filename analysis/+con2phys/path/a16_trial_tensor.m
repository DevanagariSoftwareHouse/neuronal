%% Real fixed-duration trial population tensor; does not require labels.
r=struct('mode','real');
% Fixed-duration trial tensor avoids padding variable duration trials with zeros.
windows=c.windows; windows=windows(diff(windows,1,2)>=1,:);
assert(size(windows,1)>=3,'battle:skip','Need >=3 one-second trials for tensor example.');
windows=windows(1:min(30,size(windows,1)),:);
tensor=zeros(numel(c.selected),10,size(windows,1));
for j=1:size(windows,1)
    tensor(:,:,j)=spike_bins(c.spikes(c.selected),windows(j,1)+(0:.1:1))';
end
r.tensor=tensor_cp_als(tensor,2,30,1e-6);
