function type = chantype(input, desired)

% CHANTYPE determines for each channel what type it is, e.g. planar/axial gradiometer or magnetometer
%
% Use as
%   type = chantype(hdr)
%   type = chantype(sens)
%   type = chantype(label)
% or as
%   type = chantype(hdr, desired)
%   type = chantype(sens, desired)
%   type = chantype(label, desired)

% Copyright (C) 2008, Robert Oostenveld
%
% $Log: chantype.m,v $
% Revision 1.5  2008/10/22 07:22:46  roboos
% also detect refmag and refgrad from ctf labels, use regexp and local subfunction
%
% Revision 1.4  2008/10/21 20:32:47  roboos
% added second input argument (desired type)
% besides hdr, also allow grad and label input (ctf only sofar)
%
% Revision 1.3  2008/10/20 15:14:06  roboos
% added missing semicolon
%
% Revision 1.2  2008/09/10 10:06:07  roboos
% added ctf headloc
%
% Revision 1.1  2008/09/10 10:04:22  roboos
% new function
%

% determine the type of input

isheader = isa(input, 'struct') && isfield(input, 'label') && isfield(input, 'Fs');
isgrad   = isa(input, 'struct') && isfield(input, 'pnt') && isfield(input, 'ori');
islabel  = isa(input, 'cell')   && isa(input{1}, 'char');

hdr   = input;
grad  = input;
label = input;

if isheader
  numchan = length(hdr.label);
elseif isgrad
  numchan = length(grad.label);
elseif islabel
  numchan = length(label);
end

% start with unknown type
type = cell(numchan,1);
for i=1:length(type)
  type{i} = 'unknown';
end

if senstype(input, 'neuromag')
  % channames-KI is the channel kind, 1=meg, 202=eog, 2=eeg, 3=trigger (I am nut sure, but have inferred this from a single test file)
  % chaninfo-TY is the Coil type (0=magnetometer, 1=planar gradiometer)
  if isfield(hdr, 'orig') && isfield(hdr.orig, 'channames')
    for sel=find(hdr.orig.channames.KI(:)==202)'
      type{sel} = 'eog';
    end
    for sel=find(hdr.orig.channames.KI(:)==2)'
      type{sel} = 'eeg';
    end
    for sel=find(hdr.orig.channames.KI(:)==3)'
      type{sel} = 'trigger';
    end
    % determinge the MEG channel subtype
    selmeg=find(hdr.orig.channames.KI(:)==1)';
    for i=1:length(selmeg)
      if hdr.orig.chaninfo.TY(i)==0
        type{selmeg(i)} = 'magnetometer';
      elseif hdr.orig.chaninfo.TY(i)==1
        type{selmeg(i)} = 'planar';
      end
    end
  end

elseif senstype(input, 'ctf') && islabel
  % the channels have to be identified based on their name alone
  sel = myregexp('^M[ZLR][A-Z][0-9][0-9]$', label);
  type(sel) = {'meg'};                % normal gradiometer channels
  sel = myregexp('^B[GPR][0-9]$', label);
  type(sel) = {'refmag'};             % reference magnetometers
  sel = myregexp('^[GPQR][0-9][0-9]$', label);
  type(sel) = {'refgrad'};            % reference gradiometers

elseif senstype(input, 'ctf') && isgrad
  % in principle it is possible to look at the number of coils, but here the channels are identified based on their name
  sel = myregexp('^M[ZLR][A-Z][0-9][0-9]$', grad.label);
  type(sel) = {'meg'};                % normal gradiometer channels
  sel = myregexp('^B[GPR][0-9]$', grad.label);
  type(sel) = {'refmag'};             % reference magnetometers
  sel = myregexp('^[GPQR][0-9][0-9]$', grad.label);
  type(sel) = {'refgrad'};            % reference gradiometers
 
elseif senstype(input, 'ctf') && isheader
  % meg channels are 5, refmag 0, refgrad 1, adcs 18, trigger 11, eeg 9
  if isfield(hdr, 'orig') && isfield(hdr.orig, 'sensType')
    origSensType = hdr.orig.sensType;
  elseif isfield(hdr, 'orig') && isfield(hdr.orig, 'res4')
    origSensType =  [hdr.orig.res4.senres.sensorTypeIndex];
  end

  for sel=find(origSensType(:)==5)'
    type{sel} = 'meg';
  end
  for sel=find(origSensType(:)==0)'
    type{sel} = 'refmag';
  end
  for sel=find(origSensType(:)==1)'
    type{sel} = 'refgrad';
  end
  for sel=find(origSensType(:)==18)'
    type{sel} = 'adc';
  end
  for sel=find(origSensType(:)==11)'
    type{sel} = 'trigger';
  end
  for sel=find(origSensType(:)==9)'
    type{sel} = 'eeg';
  end
  for sel=find(origSensType(:)==29)'
    type{sel} = 'headloc';
  end

end % senstype

if nargin>1
  % return a boolean vector
  type = strcmp(desired, type);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function match = myregexp(pat, list)
match = false(size(list));
for i=1:numel(list)
  match(i) = ~isempty(regexp(list{i}, pat, 'once'));
end
  

