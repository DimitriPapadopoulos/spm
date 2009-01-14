% read_eeglabdata() - import EEGLAB dataset files
%
% Usage:
%   >> dat = read_eeglabdata(filename);
%
% Inputs:
%   filename - [string] file name
%
% Optional inputs:
%   'begtrial'  - [integer] first trial to read
%   'endtrial'  - [integer] last trial to read
%   'chanindx'  - [integer] list with channel indices to read
%   'header'    - FILEIO structure header
%
% Outputs:
%   dat    - data over the specified range
%
% Author: Arnaud Delorme, SCCN, INC, UCSD, 2008-

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2008 Arnaud Delorme, SCCN, INC, UCSD, arno@salk.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% $Log: read_eeglabdata.m,v $
% Revision 1.1  2009/01/14 09:12:15  roboos
% The directory layout of fileio in cvs sofar did not include a
% private directory, but for the release of fileio all the low-level
% functions were moved to the private directory to make the distinction
% between the public API and the private low level functions. To fix
% this, I have created a private directory and moved all appropriate
% files from fileio to fileio/private.
%
% Revision 1.2  2008/04/21 18:45:23  roboos
% fixed bug due to sample/trial selection mixup
% only read the selected trials
%
% Revision 1.1  2008/04/18 14:04:48  roboos
% new implementation by Arno, shoudl be tested
%

function dat = read_eeglabdata(filename, varargin);

if nargin < 1
  help read_eeglabdata;
  return;
end;

header    = keyval('header',     varargin);
begsample = keyval('begsample',  varargin);
endsample = keyval('endsample',  varargin);
begtrial  = keyval('begtrial',   varargin);
endtrial  = keyval('endtrial',   varargin);
chanindx  = keyval('chanindx',   varargin);

if isempty(header)
  header = read_eeglabheader(filename);
end;

if isempty(begtrial), begtrial = 1; end;
if isempty(endtrial), endtrial = header.nTrials; end;

if ischar(header.orig.data)
  if strcmpi(header.orig.data(end-2:end), 'set'),
    header.ori = load('-mat', filename);
  else
    fid = fopen(header.orig.data);
    if fid == -1, error('Cannot not find data file'); end;

    nTrials = endtrial-begtrial+1;
    offset = (begtrial-1)*header.nChans*header.nSamples*4; % number of bytes to skip
    fseek(fid, offset, 'cof');

    % only read the desired trials
    dat = fread(fid,prod([header.nChans header.nSamples*nTrials]),'float');
    dat = reshape(dat, header.nChans, header.nSamples, nTrials);
    fclose(fid);
  end;
else
  dat = header.orig.data;
  dat = reshape(dat, header.nChans, header.nSamples, header.nTrials);
  dat = dat(:,:,begtrial:endtrial);
end;

if ~isempty(chanindx)
  % select the desired channels
  dat = dat(chanindx,:,:);
end

