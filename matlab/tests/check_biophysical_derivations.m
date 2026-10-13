%% Analytic geometry, passive cable convergence, and spectral identities.
% Synthetic exposition checks; no new lead-field or Wilson implementation.
rng(31);
sigma=.3; I=2e-9; ell=80e-6;
for z=[-ell ell/2 2*ell]
    for rho=[2e-6 40e-6 1e-3]
        closed=I/(4*pi*sigma*ell)*(asinh((ell-z)/rho)+asinh(z/rho));
        quadrature=I/(4*pi*sigma*ell)*integral(@(s) 1./sqrt(rho^2+(z-s).^2),0,ell,'RelTol',1e-11);
        reversed=I/(4*pi*sigma*ell)*(asinh(z/rho)+asinh((ell-z)/rho));
        assert(abs(closed-quadrature)<1e-9*abs(closed));
        assert(abs(closed-reversed)<1e-12*abs(closed));
        assert(closed>0);
    end
end
rho=1e-3; tiny=1e-8;
point=I/(4*pi*sigma*rho);
line=I/(4*pi*sigma*tiny)*2*asinh(tiny/(2*rho));
assert(abs(line/point-1)<1e-9);
% Infinite-cable solution sampled on [0,L] with analytic endpoint values.
% Refine a finite-difference compartment discretization and check convergence.
lambda=1e-3; tau=.02; L=4*lambda;
for frequency=[0 1 10 100]
    omega=2*pi*frequency;
    kappa=sqrt(1+1i*omega*tau)/lambda;
    attenuation=lambda*sqrt(2/(1+sqrt(1+(omega*tau)^2)));
    assert(abs(attenuation*real(kappa)-1)<1e-12);
    errors=[];
    for N=[100 200 400]
        dx=L/N; x=(0:N)'*dx; exact=exp(-kappa*x);
        e=ones(N-1,1);
        A=spdiags([e (-2-(kappa*dx)^2)*e e],-1:1,N-1,N-1);
        rhs=zeros(N-1,1); rhs(1)=-exact(1); rhs(end)=-exact(end);
        solution=[exact(1); A\rhs; exact(end)];
        errors(end+1)=max(abs(solution-exact)); %#ok<SAGROW>
    end
    assert(errors(2)<.3*errors(1) && errors(3)<.3*errors(2));
    assert(errors(3)<1e-3);
end
% Scalar AR(1): normalized discrete-time spectral integral.
f=(-8192:8191)'/16384; variance=1.7;
for a=[-.9 0 .8]
    spectrum=variance./abs(1-a*exp(-2i*pi*f)).^2;
    assert(abs(mean(log(spectrum))-log(variance))<1e-10);
end
% Stable full-rank bivariate VAR: S=H Sigma H*, determinant identity.
A=[.4 .1;0 .2]; Sigma=[1 .2;.2 2]; logdet=zeros(size(f));
for k=1:numel(f)
    H=(eye(2)-A*exp(-2i*pi*f(k)))\eye(2);
    S=H*Sigma*H';
    assert(norm(S-S','fro')<1e-12 && min(eig(S))>0);
    logdet(k)=log(real(det(S)));
end
assert(abs(mean(logdet)-log(det(Sigma)))<1e-10);
disp('check_biophysical_derivations: passed');
