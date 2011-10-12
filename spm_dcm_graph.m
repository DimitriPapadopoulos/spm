function spm_dcm_graph(xY,A)
% Region and anatomical graph display
% FORMAT spm_dcm_graph(xY,A)
% FORMAT spm_dcm_graph(DCM)
% xY    - cell of region structures (see spm_regions)
% A     - connections of weighted directed graph
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
 
% Karl Friston
% $Id: spm_dcm_graph.m 4524 2011-10-12 17:03:55Z karl $


% defaults
%--------------------------------------------------------------------------
try
    A   = xY.Ep.A;
    xY  = xY.xY;
end

% display parameters
%--------------------------------------------------------------------------
col   = {'b','g','r','c','m','y','k','w'};
 
% get dimensions, locations and names
%--------------------------------------------------------------------------
m     = size(xY,2);
L     = [];
S     = [];
for i = 1:m
    L       = [L xY(i).xyz];
    name{i} = xY(i).name(1:min(end,3));
    S       = [S xY(i).spec];
end


% Render graph in anatomical space
%==========================================================================
subplot(2,1,1);cla
set(gca,'position',[0 .5 1 .5])
options.query = [];
options.hfig  = gcf;
options.ParentAxes = gca;
options.markersize = 32;
options.meshsurf   = fullfile(spm('Dir'),'canonical','cortex_5124.surf.gii');
h  = spm_eeg_displayECD(L,[],8,name,options);
for i = 1:m
    set(h.handles.ht(i),'FontWeight','bold')
end
set(h.handles.mesh,'FaceAlpha',1/16);
if ~exist('A','var'), return, end
 
 
% Connections
%--------------------------------------------------------------------------
W     = max(abs(A),abs(A'));
W     = W - diag(diag(W));
W     = 3*W/max(W(:));
W     = W.*(W > 1/128);
for i = 1:length(A)
    for j = (i + 1):length(A)
        if W(i,j)
            
            % associate colour with the strongest influence
            %--------------------------------------------------------------
            if abs(A(i,j)) > abs(A(j,i)), c = j; else, c = i; end
            k   = rem(c - 1,length(col)) + 1;
            line(L(1,[i j]),L(2,[i j]),L(3,[i j]),'Color',col{k},...
                'LineStyle','-',...
                'LineWidth',W(i,j));
        end
    end
end


% Render graph in functional space
%==========================================================================
 
% Multidimensional scaling (with the Weighted Graph Laplacian)
%--------------------------------------------------------------------------
D      = diag(sum(W));
G      = D - W;
[U V]  = eig(full(spm_pinv(G)));
U      = U*sqrt(V);
[V i]  = sort(-diag(V));
U      = U(:,i(1:3))';
 
% Procrustean transform to align with anatomy (not currently used)
%--------------------------------------------------------------------------
U       = spm_detrend(U')';
L       = spm_detrend(L')';
% [R V S] = spm_svd(U*L');
% R       = R*S;
% U       = R'*U;
U       = diag(sign(diag(U*L')))*U;
U       = real(U*80/max(abs(U(:))));
 
 
subplot(2,1,2);cla
set(gca,'position',[0 0 1 .5])
options.ParentAxes = gca;
if m > 8; i = 8; else, i = 16; end
g      = spm_eeg_displayECD(U,[],i,name,options);
delete(g.handles.mesh)
delete(findobj(get(gcf,'Children'),'Type','uicontrol'))
for i = 1:m
    set(g.handles.ht(i),'FontWeight','bold')
end
 
% Connections
%--------------------------------------------------------------------------
for i = 1:m
    for j = (i + 1):m
        if W(i,j)
            
            % associate colour with the strongest influence
            %--------------------------------------------------------------
            if abs(A(i,j)) > abs(A(j,i)), c = j; else, c = i; end
            k   = rem(c - 1,length(col)) + 1;
            line(U(1,[i j]),U(2,[i j]),U(3,[i j]),'Color',col{k},...
                'LineStyle','-',...
                'LineWidth',W(i,j));
        end
    end
end

