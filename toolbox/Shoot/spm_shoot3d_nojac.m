function varargout = spm_shoot3d_nojac(v0,prm,args)
% Geodesic shooting
% FORMAT [phi,v1,theta] = spm_shoot3d_nojac(v0,prm,args)
% v0   - Initial velocity field n1*n2*n3*3 (single prec. float)
% prm  - Differential operator parameters
% prm  - 7 parameters (settings)
%        - [1] Regularisation type (ie the form of the differential
%          operator), can take values of
%           - 0 Linear elasticity
%           - 1 Membrane energy
%           - 2 Bending energy
%        - [2][3][4] Voxel sizes
%        - [5][6][7] Regularisation parameters
%           - For "membrane energy", the parameters are
%             lambda, unused and id.
%           - For "linear elasticity", the parameters are
%             mu, lambda, and id
%           - For "bending energy", the parameters are
%             lambda, id1 and id2.
% args - Integration parameters
%        - [1] Num time steps
%        - [2][3] Multigrid parameters (cycles and iterations)
%          for generating velocities from momentum
%
% phi  - Forward deformation field n1*n2*n3*3 (single prec. float)
% v1   - Final velocity field n1*n2*n3*3 (single prec. float)
% theta - Inverse deformation field n1*n2*n3*3 (single prec. float)
%
% This code generates deformations and their Jacobian determinans from
% initial velocity fields by gedesic shooting.  See the work of Miller,
% Younes and others.
%
% LDDMM (Beg et al) uses the following evolution equation:
%     d\phi/dt = v_t(\phi_t)
% where a variational procedure is used to find the stationary solution
% for the time varying velocity field.
% In principle though, once the initial velocity is known, then the
% velocity at subsequent time points can be computed.  This requires
% initial momentum (m_0), computed (using differential operator L) by:
%     m_0 = L v_0
% Then (Ad_{\phi_t})^* m_0 is computed:
%     m_t = |d \phi_t| (d\phi_t)^T m_0(\phi_t)
% The velocity field at this time point is then obtained by using
% multigrid to solve:
%     v_t = L^{-1} m_t
%
% These equations can be found in:
% Younes (2007). "Jacobi fields in groups of diffeomorphisms and
% applications". Quarterly of Applied Mathematics, vol LXV,
% number 1, pages 113-134 (2007).
%
% Note that in practice, (Ad_{\phi_t})^* m_0 is computed differently,
% by multiplying the initial momentum by the inverse of the Jacobian
% matrices of the inverse warp, and pushing the values to their new
% location by the inverse warp (see the "pushg" code of shoot3).
% Multigrid is currently used to obtain v_t = L^{-1} m_t, but
% this could also be done by convolution with the Greens function
% K = L^{-1} (see e.g. Bro-Nielson).
%
%________________________________________________________
% (c) Wellcome Trust Centre for NeuroImaging (2009)

% John Ashburner
% $Id$

args0 = [8 1 1];
if nargin<3,
    args = args0;
else
    if numel(args)<numel(args0),
        args = [args args0((numel(args)+1):end)];
    end
end
verb     = false;
N        = args(1);   % # Time steps
fmg_args = args(2:3); % Multigrid params
d        = size(v0);
d        = d(1:3);
vt       = v0;

m0       = shoot3('vel2mom',v0,prm); % Initial momentum (m_0 = L v_0)
phi      = shoot3('smalldef', vt,1/N);

if nargout>=3, theta = shoot3('smalldef', vt,-1/N); end

for t=2:abs(N),
    vt  = shoot3('mom2vel',shoot3('pushg',m0,phi),[prm,fmg_args],vt);
    phi = shoot3('comp', shoot3('smalldef',vt,1/N), phi);
    if nargout>=3, theta = shoot3('comp', theta, shoot3('smalldef',vt,-1/N)); end
    drawnow
end

varargout{1} = phi;
if nargout>=2, varargout{2} = shoot3('mom2vel',shoot3('pushg',m0,phi),[prm,fmg_args],vt); end
if nargout>=3, varargout{3} = theta; end
%__________________________________________________________________________________

%__________________________________________________________________________________

