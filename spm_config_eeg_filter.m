function S = spm_config_eeg_filter
% configuration file for EEG Filtering
%_______________________________________________________________________
% $Id$

w = spm_jobman('HelpWidth');

D = struct('type','files','name','File Name','tag','D',...
           'filter','mat','num',1,'help',spm_justify(w,...
           'Select the EEG mat file.'...
           ));

typ = struct('type','menu','name','Filter type','tag','type',...
           'labels',{{'Butterworth'}},'values',{{1}},'val',{{1}},...
           'help',spm_justify(w,...
           'Select the filter type.'...
           ));

PHz = struct('type','entry','name','Cutoff','tag','cutoff',...
           'strtype','r','num',[1 1],'help',spm_justify(w,...
           'Enter the filter cutoff'...
           ));
flt = struct('type','branch','name','Filter','tag','filter','val',{{typ,PHz}});

S   = struct('type','branch','name','EEG Filter','tag','eeg_filter',...
           'val',{{D,flt}},'prog',@eeg_filter,'modality',{{'EEG'}},'help',spm_justify(w,...
           'Low-pass filters EEG/MEG epoched data.'...
           ));

function eeg_filter(S)
S.D = strvcat(S.D{:});
spm_eeg_filter(S)
