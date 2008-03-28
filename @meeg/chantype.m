function res = chantype(this, varargin)
% Method for setting/getting channel types
% FORMAT chantype(this, ind, type)
%   ind - channel index
%   type - type (string: 'EEG', 'MEG', 'LFP' etc.)
%
% FORMAT chantype(this, ind), chantype(this)
% Sets channel types to default using Fieldtrip channelselection
% _______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Vladimir Litvak
% $Id: chantype.m 1279 2008-03-28 18:43:17Z vladimir $


if length(varargin)>=2
    ind = varargin{1};
    type = varargin{2};

    if isempty(ind)
        ind = 1:nchannels(this);
    end

    if isempty(type)
        if exist('channelselection') == 2
            eeg_types = {'EEG', 'EEG1020', 'EEG1010', 'EEG1005', 'EEGBHAM', 'EEGREF'};
            other_types = {'MEG', 'EMG', 'EOG'};

            for i=1:length(eeg_types)
                foundind = spm_match_str(chanlabels(this, ind), channelselection(eeg_types(i), chanlabels(this, ind)));
                if ~isempty(foundind)
                    this = chantype(this, ind(foundind), 'EEG');
                    ind = setdiff(ind, ind(foundind));
                end
            end

            for i=1:length(other_types)
                foundind = spm_match_str(chanlabels(this, ind), channelselection(other_types(i), chanlabels(this, ind)));
                if ~isempty(foundind)
                    this = chantype(this, ind(foundind), other_types{i});
                    ind = setdiff(ind, ind(foundind));
                end
            end
        else
            warning('Fieldtrip not available, setting all types to ''other''');
        end

        if ~isempty(ind)
            this = chantype(this, ind, 'Other');
        end

        res = this;       
        return
    end    
end

res = getset(this, 'channels', 'type', varargin{:});