function eegreg = spm_cfg_eeg_regressors
% Configuration file for M/EEG time-frequency analysis
%__________________________________________________________________________
% Copyright (C) 2014 Wellcome Trust Centre for Neuroimaging

% Vladimir Litvak
% $Id: spm_cfg_eeg_regressors.m 6007 2014-05-22 11:41:12Z vladimir $


%--------------------------------------------------------------------------
% D
%--------------------------------------------------------------------------
D        = cfg_files;
D.tag    = 'D';
D.name   = 'File Name';
D.filter = 'mat';
D.num    = [1 1];
D.help   = {'Select the M/EEG mat file.'};

%--------------------------------------------------------------------------
% method
%--------------------------------------------------------------------------
methods      = cfg_repeat;
methods.tag  = 'methods';
methods.name = 'Generation method ';
methods.num  = [1 Inf];

reg_funs = spm_select('List',spm('dir'),'^spm_eeg_regressors_.*\.m$');
reg_funs = cellstr(reg_funs);
for i = 1:numel(reg_funs)
    methods.values{i} = feval(spm_file(reg_funs{i},'basename'));
end

%--------------------------------------------------------------------------
% Output file name
%--------------------------------------------------------------------------
outfile = cfg_entry;
outfile.tag = 'outfile';
outfile.name = 'Output filename';
outfile.strtype = 's';
outfile.num = [0 inf];
outfile.val = {'regressors.mat'};
outfile.help = {'Choose file name for a mat file with regressors.'};

%--------------------------------------------------------------------------
% M/EEG Time-Frequency Analysis
%--------------------------------------------------------------------------
eegreg = cfg_exbranch;
eegreg.tag = 'eegreg';
eegreg.name = 'GLM regressors';
eegreg.val = {D, methods, outfile};
eegreg.help = {'Generate regressors for GLM analysis of M/EEG data.'};
eegreg.prog = @eeg_eegreg;
eegreg.vout = @vout_eeg_eegreg;
eegreg.modality = {'EEG'};

%==========================================================================
% function out = eeg_eegreg(job)
%==========================================================================
function out = eeg_eegreg(job)
job.D = char(job.D);
out.regrfile = {spm_eeg_regressors(job)};
out.inputfile = {job.D};

%==========================================================================
% function dep = vout_eeg_tf(job)
%==========================================================================
function dep = vout_eeg_eegreg(job)
% return dependencies
dep(1)            = cfg_dep;
dep(1).sname      = 'M/EEG dataset for statistics';
dep(1).src_output = substruct('.','inputfile');
dep(1).tgt_spec   = cfg_findspec({{'filter','mat'}});
dep(2)            = cfg_dep;
dep(2).sname      = 'MEEG GLM regressors';
dep(2).src_output = substruct('.','regrfile');
dep(2).tgt_spec   = cfg_findspec({{'filter','mat'}});


