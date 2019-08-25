function [MB] = spm_mb_ui(action,varargin)
% VOI extraction of adjusted data and Markov Blanket decomposition
% FORMAT [MB] = spm_mb_ui('specify',SPM)
%
% SPM    - structure containing generic analysis details
%
% MB.contrast -  contrast name
% MB.name     -  MB name
% MB.c        -  contrast weights
% MB.X        -  contrast subspace
% MB.Y        -  whitened and adjusted data
% MB.X0       -  null space of contrast
%
% MB.XYZ      -  locations of voxels (mm)
% MB.xyz      -  seed voxel location (mm)
% MB.VOX      -  dimension of voxels (mm)
%
% MB.V        -  canonical vectors  (data)
% MB.v        -  canonical variates (data)
% MB.W        -  canonical vectors  (design)
% MB.w        -  canonical variates (design)
% MB.C        -  canonical contrast (design)
%
% MB.chi      -  Chi-squared statistics testing D >= i
% MB.df       -  d.f.
% MB.p        -  p-values
%
% also saved in MB_*.mat in the SPM working directory
%
% FORMAT [MB] = spm_cva_ui('results',MB)
% Display the results of a MB analysis
%__________________________________________________________________________
%
% This routine uses the notion of Markov blankets and the renormalisation
% group to evaluate the coupling among neuronal systems at increasing
% spatial scales. The underlying generative model is based upon the
% renormalisation group: a working definition of renormalization involves
% three elements: vectors of random variables, a course-graining operation
% and a requirement that the operation does not change the functional form
% of the Lagrangian. In our case, the random variables are neuronal states;
% the course graining operation corresponds to the grouping (G) into a
% particular partition and adiabatic reduction (R) � that leaves the
% functional form of the dynamics unchanged.
%
% Here, the grouping operator (G) is based upon coupling among states as
% measured by the Jacobian. In brief, the sparsity structure of the
% Jacobian is used to recursively identify Markov blankets around internal
% states to create a partition of states � at any level � into particles;
% where each particle comprises external and blanket states. The ensuing
% reduction operator (R) eliminates the internal states and retains the slow
% eigenmodes of the blanket states. These then constitute the (vector)
% states at the next level and the process begins again.
%
% This routine starts using a simple form of dynamic causal modelling
% applied to the principal eigenvariate of local parcels (i.e., particles)
% of voxels with compact support. The Jacobian is estimated using a
% linearised dynamic causal (state space) model, where observations are
% generated by applying a (e.g., haemodynamic) convolution operator to
% hidden (e.g., neuronal) states. This estimation uses parametric empirical
% Bayes (PEB: spm_PEB). The ensuing estimates of the Jacobian (i.e.,
% effective connectivity) are reduced using Bayesian model reduction (BMR:
% spm_dcm_BMR_all) within a bespoke routine (spm_dcm_J).
%
% The Jacobian is then partitioned using the course graining operator into
% particles or parcels (using spm_markov blanket). The resulting partition
% is then reduced by eliminating internal states and retaining slow
% eigenmodes with the largest (real) eigenvalues (spm_A_reduce). The
% Jacobian of the reduced states is then used to repeat the process -
% recording the locations of recursively coarse-grained particles � until
% there is a single particle.
%
% The result of this recursive decomposition (i.e., renormalisation)
% affords a characterisation of directed coupling, as characterised by a
% complex Jacobian; namely, a multivariate coupling matrix, describing the
% coupling between eigenmodes of Markov blankets at successive scales. This
% can be regarded as a recursive parcellation scheme based upon effective
% connectivity and a generative (dynamic causal) model of multivariate
% (neuronal) timeseries.
%
%__________________________________________________________________________
% Copyright (C) 2008-2014 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_mb_ui.m 7655 2019-08-25 20:10:20Z karl $

OPT.d    = 48;                         % maximum connection length (mm)
OPT.np   = 512;                        % number of parcels (particles)
OPT.xyz  = [0;0;0];                    % centre of (spherical) VOI (mm)
OPT.spec = 128;                        % radius of (spherical) VOI (mm)
OPT.Ic   = 1;                          % contrast (for adjusted data)
OPT.T    = 1;                          % threshold for adiabatic reduction
OPT.N    = 8;                          % max modes for adiabatic reduction

switch lower(action)
    
    case 'specify'
        %==================================================================
        %                      M B  :  S P E C I F Y
        %==================================================================
        if isempty(varargin)
            [SPM,sts] = spm_select(1,'mat','Select SPM',[],[],'^SPM.*\.mat$');
            if ~sts, return; end
        else
            SPM = varargin{1};
        end
        if ischar(SPM)
            SPM  = load(SPM);
            SPM  = SPM.SPM;
        end
        
        %-Contrast specification
        %------------------------------------------------------------------
        con     = SPM.xCon(OPT.Ic).name;
        c       = SPM.xCon(OPT.Ic).c;
        c       = full(c);
        
        %-Specify search volume
        %------------------------------------------------------------------
        xY.def     = 'sphere';
        xY.xyz     = OPT.xyz;
        xY.spec    = OPT.spec;
        Q          = ones(1,size(SPM.xVol.XYZ,2));
        XYZmm      = SPM.xVol.M(1:3,:)*[SPM.xVol.XYZ; Q];
        [xY,XYZ,j] = spm_ROI(xY,XYZmm);
        
        %-Extract required data from results files
        %==================================================================
        spm('Pointer','Watch')
        
        %-Get explanatory variables (data)
        %------------------------------------------------------------------
        Y    = spm_get_data(SPM.xY.VY,SPM.xVol.XYZ(:,j));
        
        if isempty(Y)
            spm('alert*',{'No voxels in this VOI';'Please use a larger volume'},...
                'Markov Blanket analysis');
            return
        end
        
        %-Remove serial correlations and get design (note X := W*X)
        %------------------------------------------------------------------
        Y   = SPM.xX.W*Y;
        X   = SPM.xX.xKXs.X;
        M   = SPM.xVol.M(1:3,1:3);               %-voxels to mm matrix
        VOX = diag(sqrt(diag(M'*M))');           %-voxel size
        
        %-Null-space
        %------------------------------------------------------------------
        X0      = [];
        try  X0 = [X0 blkdiag(SPM.xX.K.X0)];     end  %-drift terms
        try  X0 = [X0 spm_detrend(SPM.xGX.gSF)]; end  %-global estimate
        
        % exogenous inputs (decimated)
        %------------------------------------------------------------------
        for i = 1:numel(SPM.Sess.U)
            U(:,i) = SPM.Sess.U(i).u(33:end,:);
        end
        Dy      = spm_dctmtx(size(Y,1),size(Y,1));
        Du      = spm_dctmtx(size(U,1),size(Y,1));
        Dy      = Dy*sqrt(size(Y,1)/size(U,1));
        U       = Dy*(Du'*U);
        
        %-First level partition: compact support
        %==================================================================
        X0      = [X0, (X - X*c*pinv(c))];
        V       = spm_mvb_U(Y,'compact',spm_svd(X0),XYZ,[],OPT.np);
        Y       = Y*V;
        [nt,nv] = size(Y);
        
        % distance priors (plausible connections: R(i,j) = 1)
        %------------------------------------------------------------------
        R     = zeros(nv,nv);
        D     = abs(V);
        D     = bsxfun(@rdivide,D,sum(D));
        xyz   = XYZ*D;
        for i = 1:nv
            for j = i:nv
                d = xyz(:,i) - xyz(:,j);
                if sqrt(d'*d) < OPT.d
                    R(i,j) = 1;
                    R(j,i) = 1;
                end
            end
        end
        
        % first order Jacobian
        %==================================================================
        J       = spm_dcm_J(Y,U,X0,SPM.xY.RT,R);
        
        % hierarchal decomposition
        %==================================================================
        clear MB
        
        %-Assemble results
        %------------------------------------------------------------------
        MB{1}.con  = con;                        %-contrast name
        MB{1}.XYZ  = XYZ;                        %-locations of voxels (mm)
        MB{1}.VOX  = VOX;                        %-dimension of voxels (mm)
        
        N        = 4;                            % maximum number of scales
        m        = [1 1 1 1];                    % # internal states
        MB{1}.J  = J;                            % Jacobian
        MB{1}.z  = num2cell(1:nv);               % indices of states
        MB{1}.s  = num2cell(diag(J));            % Lyapunov exponents
        MB{1}.U  = U;                            % exogenous inputs
        MB{1}.V  = V;                            % support in voxel space
        MB{1}.Y  = Y;                            % time-series
        
        
        %% renormalization
        %------------------------------------------------------------------
        for i = 1:N
            
            % Markov blanket (particular) partition
            %--------------------------------------------------------------
            spm_figure('getwin',sprintf('Markov level %i',i)); clf;
            MB{i}.m     = m(i);
            MB{i}.x     = spm_Markov_blanket(MB{i}.J,MB{i}.z,m(i));
            
            % dimension reduction (eliminating internal states)
            %--------------------------------------------------------------
            [J,z,v,s]   = spm_A_reduce(MB{i}.J,MB{i}.x,OPT.T,OPT.N);
            MB{i + 1}.J = J;
            MB{i + 1}.z = z;
            MB{i + 1}.s = s;
            
            % eigenmodes and variates (V and Y)
            %--------------------------------------------------------------
            for j = 1:size(MB{i}.x,2)
                u                = [MB{i}.x{1:2,j}];     % blanket states
                w                = MB{i + 1}.z{j};       % new states
                MB{i + 1}.V(:,w) = MB{i}.V(:,u)*v{j};
                MB{i + 1}.Y(:,w) = MB{i}.Y(:,u)*v{j};
            end
            
            % functional anatomy of states
            %--------------------------------------------------------------
            spm_mb_anatomy(MB{i},XYZ,VOX,7);
            
            % break if a single particle or parcel
            %--------------------------------------------------------------
            if i > N || size(MB{i}.x,2) < 2
                break
            end
            
        end
        
        
        
        %% Save results
        %==================================================================
        
        %-Save
        %------------------------------------------------------------------
        save(fullfile(SPM.swd,['MB_' con]),'MB');
        
        
        
    case 'results'
        %==================================================================
        %                      M B  :  R E S U L T S
        %==================================================================
        
        %-Get MB and ananlysis
        %------------------------------------------------------------------
        MB       = varargin{1};
        analysis = varargin{2};
        if ischar(MB)
            MB  = load(MB);
            MB  = MB.MB;
        end
        
        switch analysis
            
            case('anatomy')
                
                % functional anatomy
                %--------------------------------------------------------------
                VOX   = MB{1}.VOX;
                XYZ   = MB{1}.XYZ;
                for i = 1:(numel(MB) - 1)
                    spm_figure('getwin',sprintf('Markov level %i',i)); clf;
                    spm_mb_anatomy(MB{i},XYZ,VOX)
                end
                
            case('distance')
                
                % spatial distance and (first-level) coupling
                %--------------------------------------------------------------
                spm_figure('getwin','Distance rules'); clf;
                
                J     = MB{1}.J;
                nv    = length(J);
                D     = abs(MB{1}.V);
                D     = bsxfun(@rdivide,D,sum(D));
                xyz   = MB{1}.XYZ*D;
                D     = [];
                E     = [];
                for i = 1:nv
                    for j = 1:nv
                        d = xyz(:,i) - xyz(:,j);
                        d = sqrt(d'*d);
                        if abs(J(i,j)) > exp(-16) && d
                            D(end + 1,1) = sqrt(d'*d);
                            E(end + 1,1) = J(i,j);
                        end
                    end
                end
                
                % regression
                %----------------------------------------------------------
                [D,i] = sort(D,'ascend');
                D     = D - D(1);
                E     = E(i);
                r     = find(E < 0);
                g     = find(E > 0);
                
                [Fr,dfr,Br] = spm_ancova([ones(size(r)) D(r)],[],log(-E(r)));
                [Fg,dfg,Bg] = spm_ancova([ones(size(g)) D(g)],[],log( E(g)));
                
                subplot(2,2,1)
                hold off, plot(D(r),E(r),'.r',D(g),E(g),'.g','MarkerSize',1)
                hold on,  plot(D(r),-exp(Br(1))*exp(Br(2)*D(r)),'r','LineWidth',2)
                hold on,  plot(D(g), exp(Bg(1))*exp(Bg(2)*D(g)),'g','LineWidth',2)
                title('Eponential distance rule','FontSize',16)
                xlabel('Distance (mm)'), ylabel('coupling strength (Hz}')
                axis square, box off, set(gca,'YLim',[-.4,.4])
                
                subplot(2,2,2)
                hold off, plot(D(r),log(-E(r)),'.r',D(g),log(E(g)),'.g','MarkerSize',1)
                hold on,  plot(D(r),Br(1) + Br(2)*D(r),'r','LineWidth',2)
                hold on,  plot(D(g),Bg(1) + Bg(2)*D(g),'g','LineWidth',2)
                title('Log coupling','FontSize',16)
                xlabel('Distance (mm)'), ylabel('log coupling')
                axis square, box off, set(gca,'YLim',[-16,0])
                
                
                % assymetry
                %----------------------------------------------------------
                D     = [];
                E     = [];
                for i = 1:nv
                    for j = 1:nv
                        if abs(J(i,j)) > exp(-8) && j ~= i
                            D(end + 1,1) = J(j,i);
                            E(end + 1,1) = J(i,j);
                        end
                    end
                end
                
                subplot(2,1,2)
                hold off, plot(E,D,'.r','MarkerSize',1)
                title('reciprocal coupling','FontSize',16)
                xlabel('coupling (Hz)'), ylabel('coupling (Hz)')
                axis square, box off, axis([-1 1 -1 1]/2)             
                
                
            case('scaling')
                
                % time constants over scales
                %----------------------------------------------------------
                spm_figure('getwin','Scaling'); clf;
                
                N     = min(3,numel(MB));
                SR    = cell(N,1);
                SI    = cell(N,1);
                for i = 1:N
                    for j = 1:numel(MB{i}.s)
                        SR{i} = [SR{i}; real(MB{i}.s{j})];
                        SI{i} = [SI{i}; imag(MB{i}.s{j})];
                    end
                end
                
                subplot(2,1,1), hold off
                col   = spm_MB_col(N);
                s     = linspace(-1,1/16,16);
                for i = 1:N
                    [n,s] = hist(SR{i},s);
                    n     = n/sum(n);
                    m(i)  = mean(1./SR{i});
                    plot(s,n,'color',col{i},'LineWidth',2), hold on
                end
                legend({'scale 1','scale 2','scale 3'})
                title('Temporal scaling','FontSize',16)
                xlabel('eigenvalue (Hz)'), ylabel('Frequency')
                axis square, box off
                
                subplot(2,1,2)
                bar(-1:numel(m),[0 0 -m])
                title('Average time constants','FontSize',16)
                xlabel('scale'), ylabel('Seconds')
                axis square, box off
                
            case('kernels')
                
                % time constants over scales
                %----------------------------------------------------------
                spm_figure('getwin','Transfer functions'); clf;
                col   = spm_MB_col(128); 
                for i = 2:min(3,numel(MB))
                    
                    % first particle
                    %------------------------------------------------------
                    
                    for p = 1:numel(MB{i}.z)
                        
                        if numel(MB{i}.z{p}) > 4
                            
                            j     = MB{i}.z{p};
                            j     = j(real(MB{i}.s{p}) < 0);
                            J     = MB{i}.J(j,j);
                            n     = length(J);
                            
                            % Bilinear operator - M0
                            %----------------------------------------------
                            M0    = spm_cat({0 [];
                                [] J});
                            
                            % Bilinear operator - M1 = dM0/du
                            %----------------------------------------------
                            M1{1} = spm_cat({0,    [];
                                ones(n,1), spm_zeros(J)});

                            % kernels
                            %----------------------------------------------
                            N       = 4096;
                            dt      = 1/8;
                            [K0,K1] = spm_kernels(M0,M1,N,dt);
                            
                            % Transfer functions (FFT of kernel)
                            %----------------------------------------------
                            S1      = fft(K1)*dt;
                            w       = ((1:N) - 1)/(N*dt);
                            j       = find(w < 1/4);
                            
                            subplot(2,2,i - 1), hold on
                            plot(w(j),abs(S1(j,:,1)),'color',col{p})
                            title(sprintf('Scale %i',i),'fontsize',16)
                            xlabel('frequency (Hz)'), ylabel('transfer tunctions')
                            axis square, box off
                            
                            if any(imag(MB{i}.s{p}))
                                subplot(2,2,i + 1), hold on
                                plot(MB{i}.s{p},'.','MarkerSize',32,'color',col{p})
                                title('Eigenvalues','fontsize',16)
                                xlabel('real (Hz)'), ylabel('imaginary (Hz)')
                                axis square, box off, axis([-1 1 -1/4 1/4])
                            end
                            
                        end
                        
                    end
                end
                    
            otherwise
                error('Unknown action.');
                
        end
        
        
    otherwise
        error('Unknown action.');
        
end

%% subroutines
%==========================================================================

% functional anatomy
%==========================================================================
function spm_mb_anatomy(MB,XYZ,VOX,N)
%__________________________________________________________________________


% set-up
%--------------------------------------------------------------------------
if nargin < 4, N = 11; end

nz   = numel(MB.z);                            % number of states
nn   = min(size(MB.x,2),N);                    % number of particles
col  = spm_MB_col(nz);                         % colours

% functional anatomy of states
%--------------------------------------------------------------------------
subplot(3,4,1),cla,hold off
c  = var(real(MB.Y));
spm_mip(logical(abs(MB.V))*c',XYZ,VOX);
axis image, axis off
title(sprintf('%i (vector) states',nz),'FontSize',16)

% functional anatomy of particles
%--------------------------------------------------------------------------
for j = 1:nn
    
    Z     = any(MB.V(:,MB.x{1,j}),2)*4;        % active states
    Z     = any(MB.V(:,MB.x{2,j}),2)*4 + Z;    % sensory states
    Z     = any(MB.V(:,MB.x{3,j}),2)*1 + Z;    % internal states
    
    subplot(3,4,j + 1)
    Z(1)  = 4;
    mip   = spm_mip(Z,XYZ,VOX);
    for k = 1:3
        c = col{j}(k)/2;
        MIP(:,:,k) = (1 - mip/64)*(1 - c) + c;
    end
    image(MIP), axis image, axis off
    title(sprintf('Particle %i',j),'FontSize',16)
end

