function en = end(a,k,n)
% Overloaded end function for file_array objects.
% _______________________________________________________________________
% Copyright (C) 2005 Wellcome Department of Imaging Neuroscience

%
% $Id: end.m 174 2005-05-24 11:03:32Z john $

dim = size(a);
if k>length(dim)
    en = 1;
else
    if n<length(dim),
	dim = [dim(1:(n-1)) prod(dim(n:end))];
    end;
    en = dim(k);
end;
