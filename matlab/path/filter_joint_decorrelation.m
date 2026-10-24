function [w,score] = filter_joint_decorrelation(target,reference,ridge)
%FILTER_JOINT_DECORRELATION Whiten reference covariance and diagonalize target.
% [W,SCORE] = filter_joint_decorrelation(C1,C0,RIDGE); C1,C0: channel covariances.
% RIDGE (default 1e-6) adds RIDGE*trace(C0)/channels to C0's diagonal.
% W columns are spatial filters; X*W gives components sorted by descending
% target/reference variance. W'*C0regularized*W=I. Sign is arbitrary.
% Example: [w,s]=filter_joint_decorrelation(cov(xband),cov(xbroad),1e-6);
if nargin<3, ridge=1e-6; end
validateattributes(target,{'numeric'},{'2d','square','real','finite','nonempty'});
validateattributes(reference,{'numeric'},{'size',size(target),'real','finite'});
validateattributes(ridge,{'numeric'},{'scalar','real','finite','nonnegative'});
assert(norm(target-target','fro')<=1e-10*max(1,norm(target,'fro')) && ...
    norm(reference-reference','fro')<=1e-10*max(1,norm(reference,'fro')),'Covariances must be symmetric');
a=(double(target)+double(target)')/2; b=(double(reference)+double(reference)')/2;
assert(min(eig(a))>=-1e-10*max(1,norm(a,2)) && ...
    min(eig(b))>=-1e-10*max(1,norm(b,2)),'Covariances must be positive semidefinite');
scale=trace(b)/size(b,1); assert(scale>0,'Reference covariance is zero');
b=b+ridge*scale*eye(size(b));
[v,d]=eig(b); values=diag(d);
assert(all(values>eps(max(values))*size(b,1)),'Reference rank deficient: increase ridge');
q=v*diag(1./sqrt(values));
c=q'*a*q; [u,d]=eig((c+c')/2);
[score,order]=sort(real(diag(d)),'descend'); w=q*u(:,order);
end
