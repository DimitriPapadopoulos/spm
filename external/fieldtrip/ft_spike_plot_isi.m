function [H] = ft_spike_plot_isi(cfg, isih)

% FT_SPIKE_PLOT_ISI makes an inter-spike-interval bar plot.
%
% Use as
%   hdl = ft_spike_plot_isi(cfg, isih)
%
% Inputs:
%   ISIH is the output from FT_SPIKE_ISIHIST
%
% Configurations:
%   cfg.spikechannel     = string or index or logical array to to select 1 spike channel.
%                          (default = 1).
%   cfg.ylim             = [min max] or 'auto' (default)
%                          If 'auto', we plot from 0 to 110% of maximum plotted value);
%   cfg.plotfit          = 'yes' (default) or 'no'. This requires that when calling
%                          FT_SPIKESTATION_ISI, cfg.gammafit = 'yes'.
%
% Outputs:
%   hdl.fit              = handle for line fit. Use SET and GET to access.
%   hdl.isih             = handle for bar isi histogram. Use SET and GET to access.

% Copyright (C) 2010, Martin Vinck
%
% $Id: ft_spike_plot_isi.m 4839 2011-11-27 17:32:37Z marvin $

revision = '$Id: ft_spike_plot_isi.m 4839 2011-11-27 17:32:37Z marvin $';

% do the general setup of the function
ft_defaults
ft_preamble help
ft_preamble callinfo
ft_preamble trackconfig

% get the default options
cfg.spikechannel = ft_getopt(cfg, 'spikechannel', 'all');
cfg.ylim         = ft_getopt(cfg,'ylim', 'auto');
cfg.plotfit      = ft_getopt(cfg,'plotfit', 'no');

% ensure that the options are valid
cfg = ft_checkopt(cfg,'spikechannel',{'cell', 'char', 'double'});
cfg = ft_checkopt(cfg,'ylim', {'char','double'});
cfg = ft_checkopt(cfg,'plotfit', 'char', {'yes', 'no'});

% get the spikechannels
cfg.channel = ft_channelselection(cfg.spikechannel, isih.label);
spikesel    = match_str(isih.label, cfg.channel);
nUnits      = length(spikesel); % number of spike channels
if nUnits~=1, error('MATLAB:ft_spike_plot_isi:cfg:spikechannel:wrongInput',...
    'One spikechannel should be selected by means of cfg.spikechannel');
end

% plot the average isih
isiHdl = bar(isih.time,isih.avg(spikesel,:),'k');
set(isiHdl,'BarWidth', 1)

if strcmp(cfg.plotfit,'yes')
  
  if ~isfield(isih,'gammaShape') || ~isfield(isih,'gammaScale')
    error('MATLAB:ft_spike_plot_isi:fitConflict',...
      'ISIH.gammaShape and .gammaScale should be present when cfg.plotfit = yes');
  end
  
  % generate the probabilities according to the gamma model
  pGamma = gampdf(isih.time, isih.gammaShape(spikesel), isih.gammaScale(spikesel));
  pGamma = pGamma./sum(pGamma);
  
  % scale the fit in the same way (total area is equal)
  sumIsih = sum(isih.avg(spikesel,:),2);
  pGamma  = pGamma*sumIsih;
  
  % plot the fit
  hold on
  fitHdl = plot(isih.time, pGamma,'r');
else
  pGamma = 0;
end

try
  if strcmp(isih.cfg.outputunit, 'proportion')
    ylabel('probability')
  elseif strcmp(isih.cfg.outputunit, 'spikecount')
    ylabel('spikecount')
  end
end

xlabel('bin edges (sec)')

% set the x axis
set(gca,'XLim', [min(isih.time) max(isih.time)])

% set the y axis
if strcmp(cfg.ylim, 'auto')
  y = [isih.avg(spikesel,:) pGamma];
  cfg.ylim = [0 max(y(:))*1.1+eps];
elseif ~isrealvec(cfg.ylim)||length(cfg.ylim)~=2 || cfg.ylim(2)<cfg.ylim(1)
  error('MATLAB:ft_spike_plot_isi:cfg:ylim',...
    'cfg.ylim should be "auto" or ascending order 1-by-2 vector in seconds');
end
set(gca,'YLim', cfg.ylim)
set(gca,'TickDir','out')

% store the handles
if strcmp(cfg.plotfit,'yes'),     H.fit    = fitHdl;    end
H.isih   = isiHdl;

% as usual, make sure that panning and zooming does not distort the y limits
set(zoom,'ActionPostCallback',{@mypostcallback,cfg.ylim,[min(isih.time) max(isih.time)]});
set(pan,'ActionPostCallback',{@mypostcallback,cfg.ylim,[min(isih.time) max(isih.time)]});

% do the general cleanup and bookkeeping at the end of the function
ft_postamble trackconfig
ft_postamble callinfo

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = mypostcallback(fig,evd,limY,limX)

% get the x limits and reset them
ax = evd.Axes;
xlim = get(ax(1), 'XLim');
ylim = get(ax(1), 'YLim');
if limX(1)>xlim(1), xlim(1) = limX(1); end
if limX(2)<xlim(2), xlim(2) = limX(2); end
if limY(1)>ylim(1), ylim(1) = limY(1); end
if limY(2)<ylim(2), ylim(2) = limY(2); end

set(ax(1), 'XLim',xlim)
set(ax(1), 'YLim',ylim);

