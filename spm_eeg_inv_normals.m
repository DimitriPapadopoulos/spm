function normal = spm_eeg_inv_normals(vert,face)
% FORMAT normal = spm_eeg_inv_normals(vert,face)
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Jeremie Mattout
% $Id: spm_eeg_inv_normals.m 1131 2008-02-06 11:17:09Z spm $


m = struct('Vertices',vert,'Faces',face);
h = figure('Visible','off');
n = get(patch(m),'VertexNormals');
close(h);

f = sqrt(sum(n.^2,2));
I = find(f == 0);
for i = 1:length(I)
    n(I(i)) = n(I(i) - 1);
end
f           = sqrt(sum(n.^2,2));
normal(:,1) = n(:,1)./f;
normal(:,2) = n(:,2)./f;
normal(:,3) = n(:,3)./f;

return
%==========================================================================
