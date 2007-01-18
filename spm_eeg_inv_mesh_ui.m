function D = spm_eeg_inv_mesh_ui(varargin)

%=======================================================================
% Cortical Mesh user-interface routine
% Invokes spatial normalization (if required) and the computation of
% the proper size individual size
%
% FORMAT D = spm_eeg_inv_mesh_ui(D,val)
% Input:
% D		   - input data struct (optional)
% Output:
% D	       - same data struct including the meshing files and variables
%==========================================================================
% Copyright (C) 2005 Wellcome Department of Imaging Neuroscience

% Jeremie Mattout & Christophe Phillips
% $Id: spm_eeg_inv_mesh_ui.m 720 2007-01-18 19:47:42Z karl $


% initialise
%--------------------------------------------------------------------------
[D,val] = spm_eeg_inv_check(varargin{:});

% get sMRI and mesh size
%--------------------------------------------------------------------------
D.inv{val}.mesh.Msize = spm_input('Mesh size (vertices)','+1','3000|4000|5000|7200',[1 2 3 4]);
D.inv{val}.mesh.sMRI  = spm_select(1,'image','Select subject''s structural MRI');

% sMRI spatial normalization into MNI T1 template
%--------------------------------------------------------------------------
D       = spm_eeg_inv_spatnorm(D);

% get cortical mesh size and compute meshes
%--------------------------------------------------------------------------
D       = spm_eeg_inv_meshing(D);

% check meshes and display
%--------------------------------------------------------------------------
spm_eeg_inv_checkmeshes(D);
