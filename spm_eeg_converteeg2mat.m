function D = spm_eeg_converteeg2mat(S)
% User interface for conversion of EEG-files to SPM's data structure
% FORMAT D = spm_eeg_converteeg2mat(S)
%
% struct S is optional and has the following (optional) fields:
%    fmt       - string that determines type of input file. Currently, this
%                string can be either 'CNT' or 'BDF'
%    Mname     - char matrix of input file name(s)
%    Fchannels - String containing name of channel template file
%_______________________________________________________________________
% 
% spm_eeg_converteeg2mat is a user interface to convert EEG-files from their
% native format to SPM's data format. This function assembles some
% necessary information before branching to the format-specific conversion
% routines.
% The user has to specify, by either using struct S or the GUI, a 'channel
% template file' that contains information about the (approximate) spatial
% positions of the channels.
% 
% Output: The converted data are written to files. The header
% structs, but not the data, are returned in D as a cell vector of structs.
%_______________________________________________________________________
%
% Additional formats can be added by (i) extending the code below in a
% straightforward fashion, (ii) providing a new channel template file and
% (iii) adding the actual conversion routine to the SPM-code.
%_______________________________________________________________________
% Stefan Kiebel $Id$ 

[Finter,Fgraph,CmdLine] = spm('FnUIsetup','EEG data conversion setup',0);

% which format?
try
    fmt = S.fmt;
catch
    spm_input('data format', 1, 'd')
    Ctype = {
        'CNT',...
            'BDF'};
    str   = 'Select format';
	Sel   = spm_input(str, 2, 'm', Ctype);
	fmt = Ctype{Sel};
end

% which files to convert?
try
    Mname = S.Mname;
catch
    switch fmt
        case {'CNT'}
            str = '.cnt';
        case {'BDF'}
            str = '.bdf';
        otherwise
            error(sprintf('Unknown format: %s', fmt));
    end
    Mname = spm_get(inf, str, sprintf('Select %s-files', str));
end

% which channel template file
try
    Fchannels = S.Fchannels;
catch
    Fchannels = spm_get(1, '.mat', 'Select channel template file', fullfile(spm('dir'), 'EEGtemplates'));
end

Nfiles = size(Mname, 1);

S2.Fchannels = Fchannels;

% reference channel
switch fmt
    case{'CNT'}
        try
            S2.reference = S.reference;
        catch
            S2.reference = spm_input('Input reference channel(s)', '+1', 's+');
        end
end


switch fmt
	case {'CNT'}
        for i = 1:Nfiles
            S2.Fdata = deblank(Mname(i, :));            
            D{i} = spm_eeg_rdata(S2);
        end
                
    case {'BDF'}
        for i = 1:Nfiles
            S2.Fdata = deblank(Mname(i, :));
            D{i} = spm_eeg_rdata_bdf(S2);
        end
       
    otherwise
        error('Unknown format');
        
end
