function [dx] = spm_dx(dfdx,f,t)
% returns dx(t) = (expm(dfdx*t) - I)*inv(dfdx)*f
% FORMAT [dx] = spm_dx(dfdx,f,[t])
% dfdx   = df/dx
% f      = dx/dt
% t      = integration time: (default t = Inf);
%          if t is a cell (i.e., {t}) then t is set ti:
%          exp(t - log(diag(-dfdx))
%
% dx     = x(t) - x(0)
%--------------------------------------------------------------------------
% Integration of a dynamic system using local linearization.  This scheme
% accommodates nonlinearities in the state equation by using a functional of
% f(x) = dx/dt.  This uses the equality
%
%             expm([0   0     ]) = expm(t*dfdx) - I)*inv(dfdx)*f
%                  [t*f t*dfdx]
%
% When t -> Inf this reduces to
%
%              dx(t) = -inv(dfdx)*f
%
% These are the solutions to the gradient ascent ODE
%
%            dx/dt   = k*f = k*dfdx*x =>
%
%            dx(t)   = expm(t*k*dfdx)*x(0)
%                    = expm(t*k*dfdx)*inv(dfdx)*f(0) -
%                      expm(0*k*dfdx)*inv(dfdx)*f(0)
%
% When f = dF/dx (and dfdx = dF/dxdx), dx represents the update from a
% Gauss-Newton ascent on F.  This can be regularised by specifying a finite
% t, A heavy regularization corresponds to t = 1/norm(dfdx) and a light
% regularization would be t = 32/norm(dfdx).  norm(dfdx) represents an upper
% bound on the rate of convergence (c.f., a Lyapunov exponent of the
% ascent)
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_dx.m 1163 2008-02-22 12:24:06Z karl $

% defaults
%--------------------------------------------------------------------------
if nargin < 3, t = Inf;                        ; end

% t is a regulariser
%--------------------------------------------------------------------------
if iscell(t)
   t  = min(max(t{:},-6),6);
   t  = exp(t - log(diag(-dfdx)));
end


% use a [pseudo]inverse if all t > TOL
%==========================================================================
if min(t) > exp(16)
    try
        dx = -inv(dfdx)*f;
    catch
        dx = -pinv(full(dfdx))*f;
    end
    return
end

% ensure t is a scalar or matrix
%--------------------------------------------------------------------------
if isvector(t), t = diag(t); end

% augment Jacobian and take matrix exponential
%==========================================================================
dx    = spm_expm(spm_cat({0 []; t*spm_vec(f) t*dfdx}));
dx    = spm_unvec(dx(2:end,1),f);
