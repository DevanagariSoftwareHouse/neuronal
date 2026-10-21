f = @(x,t,a,f,s,p) a(t)*sin(2*pi*(f(t)+s(t))+p(t));

t = 0:0.01:1;
a = ones(t)*1;
f = ones(t)*8;
