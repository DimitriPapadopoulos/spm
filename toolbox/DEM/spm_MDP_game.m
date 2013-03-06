function [MDP] = spm_MDP_game(MDP,varargin)
% aaction selection using active inference
% FORMAT [MDP] = spm_MDP_select(MDP)
%
% MDP.T           - process depth (the horizon)
% MDP.K           - memory  depth (default 0)
% MDP.N           - number of variational iterations (default 4)
% MDP.S(N,1)      - true initial state
%
% MDP.A(N,N)      - Likelihood of outcomes given hidden states
% MDP.B{M}(N,N)   - transition probabilities among hidden states (priors)
% MDP.C(N,1)      - terminal cost probabilities (prior N over hidden states)
% MDP.D(N,1)      - initial prior probabilities (concentration parameters)
%
% MDP.V(T,P)      - allowable policies (control sequences over time)
%
% optional:
% MDP.s(1 x T)    - vector of true states  - for deterministic solutions
% MDP.o(1 x T)    - vector of observations - for deterministic solutions
% MDP.a(1 x T)    - vector of action       - for deterministic solutions
% MDP.w(1 x T)    - vector of precisions   - for deterministic solutions
%
% MDP.G{M}(N,N)   - transition probabilities used to generate outcomes
%                   (default: the prior transition probabilities)
% MDP.B{T,M}(N,N) - transition probabilities for each time point
% MDP.G{T,M}(N,N) - transition probabilities for each time point
%                   (default: MDP.B{T,M} = MDP.B{M})
%
% MDP.plot        - switch to suppress graphics: (default: [0])
% MDP.alpha       - upper bound on precision (Gamma hyperprior � shape [8])
% MDP.beta        - precision over precision (Gamma hyperprior - rate  [1])
%
% produces:
%
% MDP.P(M,T)   - probability of emitting an action 1,...,M at time 1,...,T
% MDP.Q(N,T)   - an array of conditional (posterior) expectations over
%                N hidden states and time 1,...,T
% MDP.O(O,T)   - a sparse matrix of ones encoding outcomes at time 1,...,T
% MDP.S(N,T)   - a sparse matrix of ones,  encoding states at time 1,...,T
% MDP.V(M,T)   - a sparse matrix of ones,  encoding action at time 1,...,T
% MDP.W(1,T)   - posterior expectations of precision
% MDP.d        - simulated dopamine responses
%
% This routine provides solutions of active inference (minimisation of
% variational free energy)using a generative model based upon a Markov
% decision process. This model and inference scheme is formulated
% in discrete space and time. This means that the generative model (and
% process) are  finite state  machines or hidden Markov models whose
% dynamics are given by transition probabilities among states. For
% simplicity, we assume an isomorphism between hidden states and outcomes,
% where the likelihood corresponds to a particular outcome conditioned upon
% hidden states. Similarly, for simplicity, this routine assumes that action
% and hidden controls are isomorphic. If the dynamics of transition
% probabilities of the true process are not provided, this routine will use
% the equivalent probabilities from the generative model.

% This particular scheme is designed for situations in which a particular
% action is to be selected at a particular time. The first control state
% is considered the baseline or default behaviour. Subsequent control
% states are assumed to be selected under the constraint that only one
% action can be emitted once. This provides a particular simplification for
% the generative model, allowing a fairly exhaustive model of potential
% outcomes � eschewing a mean field approximation over successive
% control states. In brief, the agent simply represents the current state
% and states in the immediate and distant future.
%
% The transition probabilities are a cell array of probability transition
% matrices corresponding to each (discrete) the level of the control state.
%
% Mote that the conditional expectations are functions of time but also
% contain expectations about fictive states over time at each time point.
% To create time dependent transition probabilities, one can specify a
% function in place of the transition probabilities under different levels
% of control.
%
% Partially observed Markov decision processes can be modelled by
% specifying a likelihood (as part of a generative model) and absorbing any
% probabilistic mapping between (isomorphic) hidden states and outcomes
% into the transition probabilities G.
%
% See also spm_MDP which uses multiple future states and a the mean
% field, approximation for control states � but allows for different actions
% at all times (as in control problems).
%__________________________________________________________________________
% Copyright (C) 2005 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_MDP_game.m 5299 2013-03-04 18:19:35Z guillaume $

% set up and preliminaries
%==========================================================================

% options and precision defaults
%--------------------------------------------------------------------------
try, PLOT  = MDP.plot;  catch, PLOT  = 0; end
try, alpha = MDP.alpha; catch, alpha = 8; end
try, beta  = MDP.beta;  catch, beta  = 1; end
try, K     = MDP.K;     catch, K     = 0; end
try, N     = MDP.N;     catch, N     = 4; end


% set up figure if necessary
%--------------------------------------------------------------------------
if PLOT
    if ishandle(PLOT)
        figure(PLOT); clf
        PLOT = 2;
    else
        spm_figure('GetWin','MDP'); clf
    end
end

% generative model and initial states
%--------------------------------------------------------------------------
T     = MDP.T;                     % process depth (the horizon)
Ns    = size(MDP.B{1},1);          % number of hidden states
Nb    = size(MDP.B,1);             % number of time-dependent probabilities
Nu    = size(MDP.B,2);             % number of hidden controls
p0    = eps;                       % smallest probability

% likelihood model (for a partially observed MDP implicit in G)
%--------------------------------------------------------------------------
try
    A  = MDP.A + p0;
    No = size(MDP.A,1);           % number of outcomes
catch
    A  = speye(Ns,Ns) + p0;
    No = Ns;
end
A     = A*diag(1./sum(A));
lnA   = log(A);


% transition probabilities (priors)
%--------------------------------------------------------------------------
for i = 1:T
    for j = 1:Nu
        if i == 1 || Nb == T
            B{i,j}   = MDP.B{i,j} + p0;
            B{i,j}   = B{i,j}*diag(1./sum(B{i,j}));
            lnB{i,j} = log(B{i,j});
        else
            B{i,j}   = B{1,j};
            lnB{i,j} = lnB{1,j};
        end
    end
end

% terminal cost probabilities (priors)
%--------------------------------------------------------------------------
C     = spm_vec(MDP.C) + p0;
C     = C/sum(C);
lnC   = log(C);

% concentration parameters of Dirichlet prior over initial state
%--------------------------------------------------------------------------
try
    D  = spm_vec(MDP.D) + 1;
catch
    D  = 2;
end

% generative process (assume the true process is the same as the model)
%--------------------------------------------------------------------------
try
    G = MDP.G;
catch
    G = MDP.B;
end
Ng    = size(G,1);
for i = 1:T
    for j = 1:Nu
        if i == 1 || Ng == T
            G{i,j} = G{i,j} + p0;
            G{i,j} = G{i,j}*diag(1./sum(G{i,j}));
        else
            G{i,j} = G{1,j};
        end
    end
end

% policies and their expectations
%--------------------------------------------------------------------------
V      = MDP.V;
u      = zeros(size(V,2),1);
Np     = size(V,2);                % number of allowable policies
w      = 1:Np;                     % indices of allowable policies


% initial states and outcomes
%--------------------------------------------------------------------------
[p q]  = max(A*MDP.S(:,1));        % initial outcome (index)
s      = find( MDP.S(:,1));        % initial state   (index)
o      = sparse(1,1,q,1,T);        % observations    (index)
S      = sparse(s,1,1,Ns,T);       % states sampled  (1 in K vector)
O      = sparse(q,1,1,No,T);       % states observed (1 in K vector)
a      = sparse(1, T - 1);         % action (index)
U      = sparse(Nu,T - 1);         % action selected (1 in K vector)
P      = sparse(Nu,T - 1);         % posterior beliefs about control
E      = sparse(T - 1,Np);         % posterior beliefs about policies
W      = sparse(1,T);              % posterior precision


% sufficient statistics of hidden states (past, current and last)
%--------------------------------------------------------------------------
gamma  = [];                       % simulated dopamine responses
x      = zeros(Ns,T);
x(:,1) = D/sum(D);


% solve
%==========================================================================
for t  = 1:T
    
    
    % allowable policies
    %----------------------------------------------------------------------
    if t > 1
        
        % record posterior expectations over policies
        %------------------------------------------------------------------
        E(t - 1,w) = u;
        
        % retain allowable policies (that are consistent with last action)
        %------------------------------------------------------------------
        j = ismember(V(t - 1,:),a(t - 1));
        V = V(:,j);
        u = u(j);
        w = w(j);
        
        
    end
    
    % conditional KL divergence (under allowable policies)
    %======================================================================
    Np    = size(V,2);                % number of allowable policies
    KL    = zeros(Np,Ns);             % value of policies x current state
    for k = 1:Np
        
        % compositon of future states
        %------------------------------------------------------------------
        p = 1;
        for j = t:T
            p = B{j,V(j,k)}*p;
        end
        
        % divergence or information gain
        %------------------------------------------------------------------
        if nargin > 1
            KL(k,:) = -lnC'*p;
        else
            KL(k,:) = sum(p.*log(p)) - lnC'*p;
        end
        
    end
    
    
    % Variational iterations (assuming precise inference about past action)
    %======================================================================
    for i  = 1:N
        
        % past states
        %------------------------------------------------------------------
        for k = (t - K):(t - 1)
            if k > 0
                v = lnA(o(k),:)' + lnB{k,a(k    )}'*x(:,k + 1);
                if k > 2
                    v = v  + lnB{(k - 1),a(k - 1)} *x(:,k - 1);
                end
                x(:,k) = spm_softmax(v);
            end
        end
        
        % intial state (with a Dirichlet prior)
        %------------------------------------------------------------------
        if t == 1
            v  = x(:,t) + D - 1;
            d  = v/sum(v);
        end
        
        % present state
        %------------------------------------------------------------------
        if t == 1
            v  = log(d);
        else
            v  = lnB{t - 1,a(t - 1)}*x(:,t - 1);
        end
        v      = v + lnA(o(t),:)' - W(t)*KL'*u;
        x(:,t) = spm_softmax(v);
        
        % precision (W)
        %------------------------------------------------------------------
        if isfield(MDP,'w')
            W(t) = MDP.w(t);
        else
            v    = beta + u'*KL*x(:,t);
            W(t) = alpha/v;
        end
        
        % policy (u)
        %------------------------------------------------------------------
        v    = - W(t)*KL*x(:,t);
        u    = spm_softmax(v);
        
        
        % re-compute precision for first iteration
        %------------------------------------------------------------------
        if t == 1
            v    = beta + u'*KL*x(:,t);
            W(t) = alpha/v;
        end
        
        
        % simulated dopamine responses (precision as each iteration)
        %------------------------------------------------------------------
        gamma(end + 1) = W(t);
        
    end
    
    % posterior expectations (control)
    %======================================================================
    for j = 1:Nu
        for k = t:(T - 1)
            P(j,k) = sum(u(ismember(V(k,:),j)));
        end
    end
    
    % sampling of next state (outcome)
    %======================================================================
    if t < T
        
        % next action (the action that minimises expected free energy)
        %------------------------------------------------------------------
        try
            a(t) = MDP.a(t);
        catch
            a(t) = find(rand < cumsum(P(:,t)),1);
        end
        
        
        % next sampled state
        %------------------------------------------------------------------
        try
            s(t + 1) = MDP.s(t + 1);
        catch
            s(t + 1) = find(rand < cumsum(G{t,a(t)}(:,s(t))),1);
        end
        
        % next obsverved state
        %------------------------------------------------------------------
        try
            o(t + 1) = MDP.o(t + 1);
        catch
            o(t + 1) = find(rand < cumsum(A(:,s(t + 1))),1);
        end
        
        % save action and state sampled
        %------------------------------------------------------------------
        W(1,t + 1)        = W(t);
        U(a(t)    ,t    ) = 1;
        O(o(t + 1),t + 1) = 1;
        S(s(t + 1),t + 1) = 1;
        
    end
    
    
    % plot
    %======================================================================
    if PLOT > 0
        
        % posterior beliefs about hidden states
        %------------------------------------------------------------------
        subplot(4,2,1)
        imagesc(1 - [x C])
        title('Inferred states','FontSize',16)
        xlabel('Time','FontSize',12)
        ylabel('Hidden state','FontSize',12)
        
        
        % posterior beliefs about control states
        %==================================================================
        subplot(4,2,2)
        
        % make previous plots dotted lines
        %------------------------------------------------------------------
        if T > 2
            h     = get(gca,'Children'); hold on
            for i = 1:length(h)
                set(h(i),'LineStyle',':');
            end
            plot(P')
            title('Inferred policy','FontSize',16)
            xlabel('Time','FontSize',12)
            ylabel('Control state','FontSize',12)
            spm_axis tight
            legend({'Stay','Shift'}), hold off
        else
            bar(P)
            title('Inferred policy','FontSize',16)
            xlabel('Contol state','FontSize',12)
            ylabel('Posterior expectation','FontSize',12)
        end
        
        
        % policies
        %------------------------------------------------------------------
        subplot(4,2,3)
        imagesc(MDP.V')
        title('Policies','FontSize',16)
        ylabel('Policy','FontSize',12)
        xlabel('Time','FontSize',12)
        
        % expectations over policies
        %------------------------------------------------------------------
        subplot(4,2,4)
        imagesc(E')
        title('Posterior probability','FontSize',16)
        ylabel('Policy','FontSize',12)
        xlabel('Time','FontSize',12)
        
        % true state (outcome)
        %------------------------------------------------------------------
        subplot(4,2,5)
        if size(S,1) > 512
            spy(S,16)
        else
            imagesc(1 - S)
        end
        title('True states','FontSize',16)
        ylabel('State','FontSize',12)
        
        % sample (observation)
        %------------------------------------------------------------------
        subplot(4,2,7)
        if size(O,1) > 512
            spy(O,16)
        else
            imagesc(1 - O)
        end
        title('Observed states','FontSize',16)
        xlabel('Time','FontSize',12)
        ylabel('State','FontSize',12)
        
        
        % action sampled (selected)
        %------------------------------------------------------------------
        subplot(4,2,6)
        if size(U,1) > 512
            spy(U,16)
        else
            imagesc(1 - U)
        end
        title('Selected action','FontSize',16)
        ylabel('Action','FontSize',12)
        
        % expected action
        %------------------------------------------------------------------
        subplot(4,2,8)
        plot((1:length(gamma))/N,gamma)
        title('Expected precision','FontSize',16)
        xlabel('Time','FontSize',12)
        ylabel('Precision','FontSize',12)
        spm_axis tight
        drawnow
        
    end
    
end

% assemble results and place in NDP structure
%--------------------------------------------------------------------------
MDP.P = P;              % probability of action at time 1,...,T - 1
MDP.Q = x;              % conditional expectations over N hidden states
MDP.O = O;              % a sparse matrix, encoding outcomes at 1,...,T
MDP.S = S;              % a sparse matrix, encoding the states
MDP.U = U;              % a sparse matrix, encoding the action
MDP.W = W;              % posterior expectations of precision
MDP.d = gamma;          % simulated dopamine responses

