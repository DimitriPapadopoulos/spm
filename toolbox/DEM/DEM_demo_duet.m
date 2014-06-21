function DEM_demo_duet
% This demonstration uses active inference (as implemented in spm_ALAP) to
% illustrate birdsong and communication using predictive coding. In this
% example, priors on high-level sensorimotor constructs (e.g., in the
% avian higher vocal centre) are used to generate proprioceptive
% predictions (i.e., motor commands) so that the bird can sing. However, in
% the absence of sensory attenuation, the slight differences between
% descending predictions and the sensory consequences of self-made songs
% confound  singing. This means that sensory attenuation is required so
% that the bird can either sing or listen.  By introducing a second bird
% and alternating between singing and listening respectively, one can
% simulate communication through birdsong. This is illustrated with one
% cycle of singing and listening, where the high level expectations about
% hidden states become synchronised; in effect, the two birds are singing
% from the same 'hymn sheet' or narrative and can be regarded as
% communicating in the sense of pragmatics. The first bird's expectations
% are shown in red, while the second bird's are shown in cyan.
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
 
% Karl Friston
% $Id: DEM_demo_duet.m 6041 2014-06-04 20:48:41Z karl $
 

% preliminaries
%--------------------------------------------------------------------------
rng('default')

A   = 2;                                   % number of agents (birds)
T   = 2;                                   % number of trials
dt  = 1/64;                                % time bin (seconds)

% generative process and model
%==========================================================================
M(1).E.d        = 1;                       % approximation order
M(1).E.n        = 3;                       % embedding order
M(1).E.s        = 1/2;                     % smoothness
 
M(1).E.method.x = 0;                       % state-dependent noise
M(1).E.method.v = 0;                       % state-dependent noise
M(1).E.method.h = 0;                       % suppress optimisation
M(1).E.method.g = 0;                       % suppress optimisation

% initialise parameters, states and precisions
%--------------------------------------------------------------------------
P     = cell(A,1);
x     = cell(A,1);
a     = cell(A,1);
U     = cell(1,A);
V     = cell(1,A);

x0    = [1; 1];

Up    = exp([ 8  8 -8 -8]);                % sensory attenutation
Uq    = exp([-8 -8 -8 -8]);                % sensory attention
Vp    = exp([-8 -8  0  0]);                % attenutation
Vq    = exp([-8 -8  2  2]);                % attention

for i = 1:A
    if rem(i,2), U{i} = Up; else, U{i} = Uq; end
    if rem(i,2), V{i} = Vp; else, V{i} = Vq; end
end


% level 1 of generative process: tto hidden states (amplitude and
% frequency of a bird's syrinx) generate proprioceptive and auditory
% sensations. These hidden states are driven by (2-D) action.
%--------------------------------------------------------------------------
for i = 1:A
    x{i} = x0;                             % states (of syrinx)
end
G(1).f  = @(x,v,a,P) a - spm_vec(x)/4;
G(1).g  = @(x,v,a,P) Gg1(x,v,a,P);         % SOUND PRODUCTION
G(1).x  = x;                               % hidden state
G(1).V  = exp(8);                          % precision (noise)
G(1).W  = exp(8);                          % precision (states)
G(1).U  = spm_cat(U);                      % precision (action)
 
 
% level 2; causes
%--------------------------------------------------------------------------
for i = 1:A
    a{i} = [0; 0];                         % action (fequency and volume)
end
G(2).v  = 0;                               % exogenous  cause
G(2).a  = spm_vec(a);                      % endogenous cause (action)
G(2).V  = exp(8);



% level 1 of the generative model: proprioceptive and auditory signals are 
% generated by three hidden states with attractor dynamics. The Raleigh
% number (control parameters) of these dynamics constitute the hidden cause
%--------------------------------------------------------------------------
for i = 1:A
    P{i} = [10; 8/3];                      % parameters
    x{i} = [1; x0];                        % hidden states
end
M(1).f  = @(x,v,P) Mf1(x,v,P);
M(1).g  = @(x,v,P) Mg1(x,v,P);
M(1).x  = x;
M(1).pE = P;
M(1).W  = exp(2);
M(1).V  = spm_cat(V); 

% level 2: the hidden cause is the third state of another (slower) Lorentz
% attractor, with fixed control parameters.
%--------------------------------------------------------------------------
for i = 1:A
    P{i} = [10; 8/3];                      % parameters
    x{i} = [1; 1; 30];                     % hidden states
   
    if i > 1,
        x{i} = [1; 1; 1];                  % hidden states
    end
end
M(2).f  = @(x,v,P) Mf2(x,v,P);
M(2).g  = @(x,v,P) Mg2(x,v,P);
M(2).x  = x;
M(2).v  = 0;
M(2).pE = P;
M(2).V  = exp(8);
M(2).W  = exp(8);
 
 
% hidden cause and prior expectations
%--------------------------------------------------------------------------
N     = 128;                               % length of stimulus (bins)
C     = zeros(1,N);

% assemble model structure
%--------------------------------------------------------------------------
DEM.M = M;
DEM.G = G;
DEM.C = C;

% reset initial hidden states and invert
%==========================================================================
for t = 1:T
    
    DEM    = spm_ALAP(DEM);
    LAP{t} = DEM;
    spm_DEM_qU(LAP{t}.qU,LAP{t}.pU)
    
    % update percicions & switch roles (sensory attenuation vs. attention)
    %----------------------------------------------------------------------
    if rem(t,2)
        for i = 1:A
            if rem(i,2), U{i} = Uq; else, U{i} = Up; end
            if rem(i,2), V{i} = Vq; else, V{i} = Vp; end
        end
    else
        for i = 1:A
            if rem(i,2), U{i} = Up; else, U{i} = Uq; end
            if rem(i,2), V{i} = Vp; else, V{i} = Vq; end
        end
    end
    DEM.G(1).U  = spm_cat(U);
    DEM.M(1).V  = spm_cat(V);
    
    
    % update states and action
    %----------------------------------------------------------------------
    DEM   = spm_ADEM_update(DEM);
    
end


% illustrate responses with sonogram (and sound file)
%==========================================================================
spm_figure('GetWin','Figure 1'); clf


% sonogram (reducing the second birds percepts by a half)
%--------------------------------------------------------------------------
qU    = [];
for t = 1:T
    v      = LAP{t}.qU.v{1}([1 2],:);
    v(1,:) = v(1,:)/max(abs(v(1,:)));
    if rem(t - 1,2)
        v(1,:) = v(1,:)/2;
    end
    qU = [qU v];
end

% synchronisation of expectations about hidden states at the first level
%--------------------------------------------------------------------------
subplot(3,1,1)
colormap('pink')
spm_DEM_play_song(qU,T*N*dt);
title('percept','Fontsize',16)

subplot(3,1,2)
for i = 1:A
    x = [];
    for t = 1:T
        x = [x LAP{t}.qU.x{1}([1 2 3] + (i - 1)*3,:)];
    end
    if i > 1
        plot((1:size(x,2))*dt,x,'c'),hold on
    else
        plot((1:size(x,2))*dt,x,'r'),hold on
    end
end
xlabel('time (seconds)')
title('First level expectations (hidden states)','Fontsize',16)

% synchronisation of expectations about hidden states at the second level
%--------------------------------------------------------------------------
subplot(3,1,3)
for i = 1:A
    x = [];
    for t = 1:T
        x = [x LAP{t}.qU.x{2}([1 2 3] + (i - 1)*3,:)];
    end
    if i > 1
        plot((1:size(x,2))*dt,x,'c'),hold on
    else
        plot((1:size(x,2))*dt,x,'r'),hold on
    end
end
xlabel('time (seconds)')
title('Second level expectations (hidden states)','Fontsize',16)



% Equations of motion and observer functions
%==========================================================================

% first level process: mapping hidden causes to sensations (when the
% birds cannot hear each other)
%--------------------------------------------------------------------------
function g = Gg0(x,v,a,P)
for i = 1:length(x)
    g{i,1} = [x{i}; x{i}];
end

% first level process: mapping hidden causes to sensations (when the 
% birds only hear the loudest frequency)
%--------------------------------------------------------------------------
function g = Gg1(x,v,a,P)
for i = 1:length(x)
    s(i)   = abs(x{i}(1));
end
[a j] = max(s);
for i = 1:length(x)
    g{i,1} = [x{i}; x{j}];
end

% first level model: mapping hidden causes to sensations
%--------------------------------------------------------------------------
function g = Mg1(x,v,P)
for i = 1:length(x)
    g{i,1} = x{i}([2 3 2 3]);
end

% second level model: mapping hidden causes to hidden states
%--------------------------------------------------------------------------
function g = Mg2(x,v,P)
for i = 1:length(x)
    g{i,1} = x{i}(3);
end

% first level model: flow of hidden states
%--------------------------------------------------------------------------
function f = Mf1(x,v,P)
for i = 1:length(x)
    f{i,1} = [-P{i}(1) P{i}(1) 0; (v{i}(1) - 4 - x{i}(3)) -1 0; x{i}(2) 0 -P{i}(2)]*x{i}/16;
end

% second level model: flow of hidden states
%--------------------------------------------------------------------------
function f = Mf2(x,v,P)
for i = 1:length(x)
    f{i,1} = [-P{i}(1) P{i}(1) 0; (32 - x{i}(3)) -1 0; x{i}(2) 0 -P{i}(2)]*x{i}/128;
end



 