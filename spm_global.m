function GX = spm_global(V)
% returns the global mean for a memory mapped volume image - a compiled routine
% FORMAT GX = spm_global(V)
% V   - memory mapped volume
% GX  - mean global activity
%_______________________________________________________________________
%
% spm_global returns the mean counts integrated over all the  
% slices from the volume
%
% The mean is estimated after discounting voxels outside the object
% using a criteria of greater than > (global mean)/8
%
%_______________________________________________________________________
% Copyright (C) 2005 Wellcome Department of Imaging Neuroscience

% Anonymous
% $Id: spm_global.m 1131 2008-02-06 11:17:09Z spm $


%-This is merely the help file for the compiled routine
error('spm_global.c not compiled - see Makefile')
