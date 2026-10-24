function [y,trend,weights] = filter_robust_detrend(x,degree,iterations)
%FILTER_ROBUST_DETREND Polynomial trend fitted by Huber IRLS per channel.
% [Y,TREND,W] = filter_robust_detrend(X,DEGREE,ITERATIONS)
% X: samples-by-channels/vector; degree 0..10; default iterations=30.
% Huber cutoff 1.345; residual scale estimated by MAD. This is an explicit
% robust-regression variant, not a copy of the NoiseTools detrending method.
% Example: [y,tr,w]=filter_robust_detrend(x,2,30);
if nargin<3, iterations=30; end
[x,row]=filter_input(x); n=size(x,1);
validateattributes(degree,{'numeric'},{'scalar','integer','>=',0,'<=',10,'<',n});
validateattributes(iterations,{'numeric'},{'scalar','integer','positive'});
t=linspace(-1,1,n)'; a=ones(n,degree+1);
for k=1:degree, a(:,k+1)=t.^k; end
trend=zeros(size(x)); weights=ones(size(x));
for c=1:size(x,2)
    b=a\x(:,c);
    for j=1:iterations
        r=x(:,c)-a*b;
        scale=1.4826*median(abs(r-median(r)));
        scale=max(scale,eps(max(1,max(abs(x(:,c))))));
        w=min(1,1.345*scale./max(abs(r),realmin));
        root=sqrt(w); bnew=bsxfun(@times,a,root)\(root.*x(:,c));
        if norm(bnew-b)<=1e-10*(1+norm(b)), b=bnew; break; end
        b=bnew;
    end
    trend(:,c)=a*b; weights(:,c)=w;
end
y=x-trend;
if row, y=y.'; trend=trend.'; weights=weights.'; end
end
