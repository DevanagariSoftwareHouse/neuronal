function y = block_shuffle_surrogate(x,block_samples)
%BLOCK_SHUFFLE_SURROGATE Permute nonoverlapping contiguous blocks.
% Preserves within-block structure; disrupts between-block ordering.
%
%   SIGNATURE DESCRIPTION
%     x — input observations or signal (see the function summary for its expected shape).
%     block_samples — the block samples value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     y — the returned y; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     y = block_shuffle_surrogate(x, block_samples);
%
assert(isnumeric(x)&&ismatrix(x)&&all(isfinite(x(:))));
n=size(x,1); assert(block_samples>=1&&block_samples==floor(block_samples));
assert(n>=block_samples);
nblocks=floor(n/block_samples);
head=reshape(x(1:nblocks*block_samples,:),block_samples,nblocks,size(x,2));
head=head(:,randperm(nblocks),:);
y=[reshape(head,nblocks*block_samples,size(x,2));x(nblocks*block_samples+1:end,:)];
end
