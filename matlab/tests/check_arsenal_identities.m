%% Numerical checks of ARS-* theorems against the matlab/path implementations.
% Run from repository root: run('matlab/tests/check_arsenal_identities.m')
% Each block names the theorem it exercises (books/shared/theorems.yml).
% A passing check is numerical evidence that the code computes the object
% the theorem is about; it is not a proof. Uses only base MATLAB/Octave
% functions (no Signal Processing or Statistics Toolbox).
here=fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','path'))
randn('state',7); rand('state',7); %#ok<RAND>

%% ARS-COUNT-001: half-open bins, nothing lost or duplicated
t=[0 .1 .25 .5 .5 .999 1];
c=spike_counts_edges(t,[0 .25 .5 .75 1]);
assert(isequal(c(:)',[2 1 2 1]) && sum(c)==6);

%% ARS-COUNT-007: greedy matching equals brute-force maximum matching
for trial=1:300
    a=sort(rand(1,randi(5))); b=sort(rand(1,randi(5))); tau=.15;
    out=spike_sorting_agreement(a,b,tau);
    n=max(numel(a),numel(b));
    ap=[a nan(1,n-numel(a))]; bp=[b nan(1,n-numel(b))];
    P=perms(1:n); best=0;
    for k=1:size(P,1)
        best=max(best,sum(abs(ap-bp(P(k,:)))<=tau));
    end
    assert(out.true_positives==best,'Greedy matching not maximum');
end

%% ARS-COUNT-008: Victor-Purpura metric axioms on random trains
for trial=1:200
    A=rand(1,randi(4)); B=rand(1,randi(4)); C=rand(1,randi(4)); q=10*rand;
    dab=victor_purpura_distance(A,B,q); dba=victor_purpura_distance(B,A,q);
    dbc=victor_purpura_distance(B,C,q); dac=victor_purpura_distance(A,C,q);
    assert(abs(dab-dba)<1e-12 && dac<=dab+dbc+1e-12);
    assert(victor_purpura_distance(A,A,q)==0);
end
assert(victor_purpura_distance([.1 .2 .3],[.5],0)==2);

%% ARS-COUNT-009: jitter preserves window counts
t=sort(10*rand(200,1)); w=.05;
s=jitter_spike_surrogate(t,w,0);
assert(isequal(histc(floor(t/w),0:200),histc(floor(s/w),0:200)));

%% ARS-ROB-002 / ARS-FD-001: CMR cancels a common mode; CSD exact on quadratics
x=randn(5,300); common=randn(1,300);
assert(norm(common_median_reference(x+repmat(common,5,1))-common_median_reference(x),'fro')<1e-10);
z=(0:7)'*1e-4; phi=3+2*z+5*z.^2;          % phi''=10
csd=current_source_density(repmat(phi,1,3),1e-4,.3);
inner=csd(2:end-1,:); assert(max(abs(inner(:)+.3*10))<1e-6);

%% ARS-SPEC-003 (K=1 triviality is structural); ARS-SPEC-005: phase surrogate
for n=[64 65]
    x=randn(n,1); y=phase_randomized_surrogate(x);
    assert(isreal(y) && abs(mean(y)-mean(x))<1e-12);
    assert(norm(abs(fft(y))-abs(fft(x)))<1e-9*norm(x));
end
%% ARS-SPEC-006: circular shift preserves sorted values
x=randn(50,1); assert(isequal(sort(circular_shift_surrogate(x,7)),sort(x)));

%% ARS-SPEC-007: exact power law recovered in log-log space
f=(1:100)'; fit=aperiodic_slope(f,4*f.^-1.7,[1 100]);
assert(abs(fit.exponent-1.7)<1e-10);

%% ARS-CIRC-001/002: bounds and the PPC identity
for trial=1:50
    th=2*pi*rand(randi([2 40]),1); n=numel(th);
    pairs=0; for j=1:n, for l=j+1:n, pairs=pairs+cos(th(j)-th(l)); end, end
    assert(abs(pairwise_phase_consistency(th)-2*pairs/(n*(n-1)))<1e-12);
    [~,R]=circular_mean(th); assert(R>=0 && R<=1+1e-15);
end
% unbiasedness: E[PPC] = rho^2 independent of n (Monte Carlo)
kappa_phase=@(m) mod(.9*randn(m,1),2*pi);  % wrapped normal, rho=exp(-.81/2)
rho2=exp(-.81); est=zeros(4000,1);
for k=1:4000, est(k)=pairwise_phase_consistency(kappa_phase(5)); end
assert(abs(mean(est)-rho2)<.02);

%% ARS-CIRC-004: lag indices ignore real cross-spectra
S=complex(randn(30,1),.3*randn(30,1));
assert(abs(weighted_phase_lag_index(S)-weighted_phase_lag_index(S+5))<1e-12);
assert(phase_lag_index(zeros(20,1))==0);
% Floating point: sin(pi)=1.2e-16>0, so exact +/-pi differences count as lagged.
assert(phase_lag_index(pi*ones(20,1))==1);

%% ARS-INFO-001: normalised entropies in [0,1]; extreme cases
assert(abs(spectral_entropy(ones(16,1))-1)<1e-12);
assert(abs(spectral_entropy([1;0;0;0]))<1e-12);

%% ARS-INFO-002: plug-in MI >= 0, zero under exact empirical independence
assert(abs(mutual_information([1 1 2 2],[1 2 1 2]))<1e-12);
assert(transfer_entropy(randi(3,500,1),randi(3,500,1))>=0);

%% ARS-LIN-001: Tikhonov equals the SVD filter formula
G=randn(6,9); y=randn(6,2); lam=.3;
r=field_potential_inverse_tikhonov(G,y,lam);
[U,Sg,V]=svd(G,'econ'); s=diag(Sg);
assert(norm(r.sources-V*diag(s./(s.^2+lam))*U'*y,'fro')<1e-10);

%% ARS-LIN-004: corrected linear_discriminability equals Delta' Sigma^-1 Delta
a=randn(20,3); b=randn(25,3)+1;
d=linear_discriminability(a,b,0);
ca=a-repmat(mean(a),20,1); cb=b-repmat(mean(b),25,1);
Sigma=(ca'*ca+cb'*cb)/43; delta=mean(b)-mean(a);
assert(abs(d.dprime_squared-delta/Sigma*delta')<1e-10);

%% ARS-PCA-002/003: participation ratio bounds; assembly identity
x=randn(100,8); pr=participation_ratio(x); assert(pr>=1 && pr<=8);
assert(abs(participation_ratio(x*orth(randn(8)))-pr)<1e-9);
z=randn(40,6); w=randn(6,1); e=assembly_expression(z,w);
brute=zeros(40,1); for i=1:6, for j=1:6, if i~=j, brute=brute+z(:,i).*z(:,j)*w(i)*w(j); end, end, end
assert(norm(e-brute)<1e-10);

%% ARS-RRR-001: at zero ridge, RRR beats random rank-r alternatives
X=randn(200,6); Y=X*randn(6,4)+.1*randn(200,4);
m=reduced_rank_regression(X,Y,2,0);
Xc=X-repmat(mean(X),200,1); Yc=Y-repmat(mean(Y),200,1);
err=norm(Yc-Xc*m.coefficients,'fro');
for k=1:200
    Bt=randn(6,2); Ct=(Xc*Bt)\Yc; assert(norm(Yc-Xc*Bt*Ct,'fro')>=err-1e-9);
end

%% ARS-JPCA-001: fitted generator is skew with imaginary eigenvalues
t=(0:.01:2)'; traj=[cos(3*t) sin(3*t) .1*cos(5*t)];
mj=jpca_dynamics(traj,.01);
assert(norm(mj.generator+mj.generator','fro')<1e-12 && max(abs(real(mj.eigenvalues)))<1e-12);

%% ARS-VAR-001: Granger ratio nonnegative even for independent series
g=granger_causality(randn(400,3),1,2,3); assert(g.log_variance_ratio>=0);

%% ARS-EMD-001: completeness of sifting
x=sin(2*pi*(1:512)'/40)+.5*sin(2*pi*(1:512)'/7)+.1*randn(512,1);
[imfs,res]=empirical_mode_decomposition(x,4);
assert(norm(sum(imfs,2)+res-x)<1e-10);

disp('check_arsenal_identities: all ARS checks passed');
