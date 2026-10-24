function [components,w,score,model] = filter_ssd(x,target_design,noise_design,ridge)
%FILTER_SSD Spatial-spectral decomposition with explicit target/noise designs.
% [Y,W,SCORE,M] = filter_ssd(X,TARGET,NOISE,RIDGE)
% X: samples-by-channels. NOISE is one design or a cell of flanking designs;
% its covariance is the average of individually filtered noise covariances.
% Fits generalized eigenvectors, then projects centered broadband X.
% Exclude transients BEFORE fitting (supply sufficiently long clean data).
% Example: d1=filter_butterworth(500,[8 12],4);
%   d0={filter_butterworth(500,[4 7],4),filter_butterworth(500,[13 16],4)};
%   [y,w,s,m]=filter_ssd(x,d1,d0,1e-6);
if nargin<4, ridge=1e-6; end
[x,~]=filter_input(x); assert(size(x,1)>size(x,2),'Need more samples than channels');
if ~iscell(noise_design), noise_design={noise_design}; end
assert(~isempty(noise_design),'At least one noise design is required');
target=filter_forward_backward(x,target_design); c0=zeros(size(x,2));
for k=1:numel(noise_design)
    assert(noise_design{k}.fs==target_design.fs,'Design sampling rates must match');
    z=filter_forward_backward(x,noise_design{k}); c0=c0+cov(z)/numel(noise_design);
end
[w,score]=filter_joint_decorrelation(cov(target),c0,ridge);
mu=mean(x,1); components=bsxfun(@minus,x,mu)*w;
model=struct('mean',mu,'weights',w,'score',score,'target',target_design, ...
    'noise',{noise_design},'ridge',ridge);
end
