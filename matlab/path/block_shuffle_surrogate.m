function y = block_shuffle_surrogate(x,block_samples)
%BLOCK_SHUFFLE_SURROGATE Permute nonoverlapping contiguous blocks.
% Preserves within-block structure; disrupts between-block ordering.
assert(isnumeric(x)&&ismatrix(x)&&all(isfinite(x(:))));
n=size(x,1); assert(block_samples>=1&&block_samples==floor(block_samples));
assert(n>=block_samples);
nblocks=floor(n/block_samples);
head=reshape(x(1:nblocks*block_samples,:),block_samples,nblocks,size(x,2));
head=head(:,randperm(nblocks),:);
y=[reshape(head,nblocks*block_samples,size(x,2));x(nblocks*block_samples+1:end,:)];
end
