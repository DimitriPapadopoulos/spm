function [nts] = read_neuralynx_nts(filename, begrecord, endrecord);

% READ_NEURALYNX_NTS reads spike timestamps
%
% Use as
%   [nts] = read_neuralynx_nts(filename)
%   [nts] = read_neuralynx_nts(filename, begrecord, endrecord)

% Copyright (C) 2006-2007, Robert Oostenveld
%
% $Log: read_neuralynx_nts.m,v $
% Revision 1.1  2007/03/21 17:12:04  roboos
% renamed NTE in NTS (filenames and function names)
%
% Revision 1.4  2007/03/21 17:06:57  roboos
% updated the documentation
%
% Revision 1.3  2007/03/21 12:54:37  roboos
% included the 2nd and 3rd input arguments in the function declaration
%
% Revision 1.2  2007/03/19 16:58:08  roboos
% implemented the actual reading of the data from file
%
% Revision 1.1  2006/12/13 15:52:26  roboos
% added empty function, only containing help but no usefull code yet
%

if nargin<2
  begrecord = 1;
end
if nargin<3
  endrecord = inf;
end

% the file starts with a 16*1024 bytes header in ascii, followed by a number of records
hdr = neuralynx_getheader(filename);
fid = fopen(filename, 'rb', 'ieee-le');

% determine the length of the file
fseek(fid, 0, 'eof');
headersize = 16384;
recordsize = 8;
NRecords   = floor((ftell(fid) - headersize)/recordsize);

if begrecord<1
  error('cannot read before the first record');
elseif endrecord>NRecords
  endrecord = NRecords;
end

if endrecord>=begrecord
  % rewind to the first record to be read
  fseek(fid, headersize + (begrecord-1)*recordsize, 'bof');
  numrecord = (endrecord-begrecord+1);
  TimeStamp = fread(fid, numrecord, 'uint64=>uint64');

  nts.TimeStamp = TimeStamp;
end
fclose(fid);

nts.NRecords = NRecords;
nts.hdr      = hdr;
