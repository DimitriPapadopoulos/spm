function [Q] = spm_gen_Q(P,X)
% Helper routine for spm_gen routines
% FORMAT [Q] = spm_gen_Q(P,X)
%
% P - parameters
% X - vector of between trial effects
% c - trial in question
%
% Q - trial or condition-specific parameters
%
% This routine computes the parameters of a DCM for a given trial, where
% trial-specific effects are deployed according to a design vector X. The
% parameterisation follows a standard naming protocol where, for example,
% X(1)*P.B{1} + X(2)*P.B{2}... adjusts P.A for all (input) effects encoded
% in P.B.
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_gen_Q.m 5724 2013-10-31 14:56:12Z rosalyn $


% condition or trial specific parameters
%==========================================================================
Q  = P;


% trial-specific effects on C (first effect only)
%----------------------------------------------------------------------
try
    Q.C = Q.C(:,:,1) + X(1)*P.C(:,:,2);
end

% trial-specific effects on A (connections)
%----------------------------------------------------------------------
for i = 1:size(X,2)
    
    % extrinsic (driving) connections
    %------------------------------------------------------------------
    for j = 1:length(Q.A)
        Q.A{j} = Q.A{j} + X(i)*P.B{i};
        
        % -- for CMM-NMDA specific modulation on Extrinsic NMDA connections
        try
            Q.AN{j}   = Q.AN{j}   + X(i)*P.BN{i};
        end
        
    end
    
    % modulatory connections
    %------------------------------------------------------------------
    try
        Q.M  = Q.M + X(i)*P.N{i};
    end
    
    % intrinsic connections
    %------------------------------------------------------------------
    try
        Q.G(:,1) = Q.G(:,1) + X(i)*diag(P.B{i});
    end
    
end
