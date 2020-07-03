function [H,R] = spm_ness(J,G)
% Evaluation of hessian and solenoidal operators at NESS
% FORMAT [H,R] = spm_ness(J,G)
% J  - Jacobian (dfdx)
% G  - diffusion tensor (amplitude of random fluctuations)
%
% H  - Hessian matrix (i.e., precision of a Gaussian density)
% R  - Skew symmetric solenoidal operator
%__________________________________________________________________________
% This routine evaluates the hessian (i.e., precision) of a nonequilibrium
% steady-state density (using a local linear approximation, under Gaussian
% assumptions). This is evaluated  under linear constraints on the
% solenoidal term of a Helmholtz decomposition. In short, given the flow
% (encoded by the systems Jacobian) and amplitude of random fluctuations,
% one can evaluate the steady-state density under nonequilibrium dynamics
% implied by solenoidal flow.
%
% flow constraints (Jacobian J)(R = -Q')
%--------------------------------------------------------------------------
% where flow   f = (R + G)*d log(p(x))/dx and
% log(p(x))      = -(1/2)*x'*H*x =>
% d log(p(x))/dx = -H*x =>
% df/dx = J      = -(R + G)*H =>
% H              = -(R + G)\J =>
% J*R + R*J'     = J*G - G*J'
%__________________________________________________________________________
% Copyright (C) 2008-2014 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_ness.m 7808 2020-03-31 11:18:26Z karl $


% solve for solenoidal (R) operator J*R + R*J' = J*G - G*J'
%==========================================================================
n = size(J,1);
I = eye(n,n);
X = kron(I,J) + kron(conj(J),I);
Y = spm_vec(J*G - G*J');
R = reshape(X\Y,n,n);

% precision (inverse covariance) of steady-state density
%--------------------------------------------------------------------------
H = -(R + G)\J;

return


% complex analysis
%==========================================================================
[eJ,vJ] = eig(J,'nobalance','vector');
J       = pinv(eJ)*J*eJ;
G       = pinv(eJ)*G*eJ;

% complex form
%--------------------------------------------------------------------------
R      = 1j*real(G)*imag(J)/real(J);
H      = - real(J)/G;


% NOTES: stochastic coupling (numerical analysis)
%==========================================================================
n     = 8;
m     = 32;
for i = 1:512
    
    % (random) Jacobian with separation of internal and external states
    %----------------------------------------------------------------------
    J = [1 1 0;
        1 1 1;
        0 1 1];
    J = kron(J,ones(n,n));
    J = J.*randn(size(J));
    J = J - diag(kron([0 0 m],ones(1,n)));
    
    % amplitude of random fluctuations and Hessian
    %----------------------------------------------------------------------
    G     = diag(kron([1 1 1],ones(1,n)));
    [H,R] = spm_ness(J,G);
    A     = -inv(G + R);
    
    % accumulate operators
    %----------------------------------------------------------------------
    RR(:,:,i) = R;
    HH(:,:,i) = H;
    JJ(:,:,i) = J;
    GG(:,:,i) = G;
    AA(:,:,i) = A;
    
end

% plot variance
%--------------------------------------------------------------------------
subplot(2,3,4),imagesc(std(RR,0,3)), axis image, title('Solenoidal','Fontsize',16)
subplot(2,3,5),imagesc(std(JJ,0,3)), axis image, title('Jacobian',  'Fontsize',16)
subplot(2,3,6),imagesc(std(HH,0,3)), axis image, title('Hessian',   'Fontsize',16)

% subplot(2,2,1),imagesc(mean(HH,3)), axis image, title('Hessian',   'Fontsize',16)
% subplot(2,2,2),imagesc(mean(RR,3)), axis image, title('Solenoidal','Fontsize',16)
% subplot(2,2,4),imagesc(mean(JJ,3)), axis image, title('Jacobian',  'Fontsize',16)
% subplot(2,2,3),imagesc(mean(AA,3)), axis image, title('Diffusion', 'Fontsize',16)


%  symbolic maths analysis (four dimensional system)
%==========================================================================
syms Jhh jhb K  jbh Jbb jbi    jib Jii;
J = [Jhh jhb 0; jbh Jbb jbi; 0 jib Jii];
J = J - diag([K K K])

n = size(J,1);
I = eye(n,n);
X = kron(I,J) + kron(J,I);
Y = J - transpose(J);
Y = Y(:);
R = inv(X);
R = R*Y;
R = reshape(R,n,n);
R = simplify(R);
H = -inv(R + I)*J;

% Rational function form of Hessian
%--------------------------------------------------------------------------
N      = cell(n,n);
D      = cell(n,n);
for ii = 1:n
    for jj = 1:n
        
        
        % get the expression for this element of the Hessian
        %------------------------------------------------------------------
        str   = char(simplify(H(ii,jj)));
        i     = findstr(str,'/');
        Nstr  = str(1:(i - 1));
        Dstr  = str((i + 1):end);
        
        % Ensure one division (i.e., a rational function)
        %------------------------------------------------------------------
        if numel(i) > 1, error('more then one /'), end
        
        % find individual terms of numerator (N), with leading powers of K
        %------------------------------------------------------------------
        for i = 1:8
            dH = diff(Nstr,K,i);
            try
                if ~eval(dH)
                    dH = diff(Nstr,K,i - 1);
                    for j = 1:(i - 1)
                        dH   = int(dH,K);
                    end
                    N{ii,jj} = char(simplify(dH))
                    break
                end
            end
        end
        
        % find individual terms of denominator (D), with leading powers of K
        %------------------------------------------------------------------
        for i = 1:8
            dH = diff(Dstr,K,i);
            try
                if ~eval(dH)
                    dH = diff(Dstr,K,i - 1);
                    for j = 1:(i - 1)
                        dH   = int(dH,K);
                    end
                    D{ii,jj} = char(simplify(dH))
                    break
                end
            end
        end
    end
end

% show results
%--------------------------------------------------------------------------
clc
disp(N)
disp(D)


% Numerical  analysis of the Hessian (between internal and external states)
%==========================================================================
str   = vectorize(char(simplify(H(3,1))));
nn    = 10000;
m     = (4:32)';
V     = m;
for i = 1:numel(m)
    
    %  sample a random Jacobian with noncentral leading diagonal
    %----------------------------------------------------------------------
    Jhh  = randn(nn,1);
    jhb  = randn(nn,1);
    jbh  = randn(nn,1);
    Jbb  = randn(nn,1);
    jbi  = randn(nn,1);
    jib  = randn(nn,1);
    Jii  = randn(nn,1);
    
    K    = m(i);
    
    %  evaluate the variance of the Hessian
    %----------------------------------------------------------------------
    V(i) = eval(['var(' str ')']);
end

% assume power law for m > 1
%--------------------------------------------------------------------------
X           = [m.^0 log(m)];
[F,df,beta] = spm_ancova(X,[],log(V));

beta(2) = -2;
disp(exp(beta(1)))

% show results
%--------------------------------------------------------------------------
subplot(2,2,1), plot(m,V,'.',m,exp(X*beta),'b')
axis square, title('Conditional independence','Fontsize',16)
xlabel('mean dissipation'),ylabel('variance of precision')

subplot(2,2,2), plot(log(m),log(V),'.',log(m),X*beta,'b')
axis square, title('Log scaling','Fontsize',16)
xlabel('log mean'),ylabel('log variance')