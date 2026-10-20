function result = cluster_permutation_test(a,b,threshold,B)
%CLUSTER_PERMUTATION_TEST 1D cluster-mass permutation over ordered features.
% Independent units in rows, ordered samples/frequencies in columns.
% Uses absolute Welch-like t statistic and max cluster mass.
% A significant cluster does NOT localize the effect to every sample.
%
%   SIGNATURE DESCRIPTION
%     a — the a value; expected shape, units, and constraints are stated in the notes above.
%     b — the b value; expected shape, units, and constraints are stated in the notes above.
%     threshold — the threshold value; expected shape, units, and constraints are stated in the notes above.
%     B — number of bootstrap/permutation/surrogate draws.
%   RETURNS
%     result — result structure containing the estimates and diagnostics described above.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     result = cluster_permutation_test(a, b, threshold, B);
%
if nargin<3||isempty(threshold), threshold=2; end
if nargin<4||isempty(B), B=999; end
assert(isnumeric(a)&&isnumeric(b)&&size(a,2)==size(b,2));
assert(size(a,1)>=2&&size(b,1)>=2&&B>=19);
assert(all(isfinite(a(:)))&&all(isfinite(b(:)))&&threshold>0);
na=size(a,1); pool=[a;b]; n=size(pool,1);
obs=local_t(a,b); [masses,labels]=local_clusters(obs,threshold);
maxnull=zeros(B,1);
for k=1:B
    p=randperm(n); t=local_t(pool(p(1:na),:),pool(p(na+1:end),:));
    v=local_clusters(t,threshold);
    if ~isempty(v), maxnull(k)=max(v); end
end
p=(1+sum(bsxfun(@ge,maxnull,masses),1))/(B+1);
result=struct('statistic',obs,'cluster_labels',labels, ...
    'cluster_masses',masses,'cluster_p',p,'max_null',maxnull);
end
function t=local_t(a,b)
va=var(a,0,1)/size(a,1); vb=var(b,0,1)/size(b,1);
den=sqrt(va+vb);
t=zeros(1,size(a,2)); good=den>0;
t(good)=(mean(a(:,good),1)-mean(b(:,good),1))./den(good);
end
function [mass,labels]=local_clusters(t,threshold)
active=abs(t)>threshold; starts=find(diff([false active false])==1);
ends=find(diff([false active false])==-1)-1;
mass=zeros(1,numel(starts)); labels=zeros(size(t));
for j=1:numel(starts)
    ix=starts(j):ends(j); mass(j)=sum(abs(t(ix))); labels(ix)=j;
end
end
