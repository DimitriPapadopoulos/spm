function [s, cfg] = ft_statfun_depsamplesFunivariate(cfg, dat, design)

% FT_STATFUN_DEPSAMPLESFUNIIVARIATE calculates the univariate repeated-mesures ANOVA
% on the biological data (the dependent variable), using the information on the
% independent variable (ivar) in design.
%
% Use this function by calling one of the high-level statistics functions as
%   [stat] = ft_timelockstatistics(cfg, timelock1, timelock2, ...)
%   [stat] = ft_freqstatistics(cfg, freq1, freq2, ...)
%   [stat] = ft_sourcestatistics(cfg, source1, source2, ...)
% with the following configuration option:
%   cfg.statistic = 'ft_statfun_depsamplesFunivariate'
%
% You can specify the following configuration options:
%   cfg.computestat    = 'yes' or 'no', calculate the statistic (default='yes')
%   cfg.computecritval = 'yes' or 'no', calculate the critical values of the test statistics (default='no')
%   cfg.computeprob    = 'yes' or 'no', calculate the p-values (default='no')
%
% The following options are relevant if cfg.computecritval='yes' and/or cfg.computeprob='yes':
%   cfg.alpha = critical alpha-level of the statistical test (default=0.05)
%   cfg.tail  = -1, 0, or 1, left, two-sided, or right (default=1)
%               cfg.tail in combination with cfg.computecritval='yes'
%               determines whether the critical value is computed at
%               quantile cfg.alpha (with cfg.tail=-1), at quantiles
%               cfg.alpha/2 and (1-cfg.alpha/2) (with cfg.tail=0), or at
%               quantile (1-cfg.alpha) (with cfg.tail=1). For the
%               Fstatistic only cfg.tail = 1 makes sense.
%
% The experimental design is specified as:
%   cfg.ivar  = independent variable, row number of the design that contains the labels of the conditions to be compared (default=1)
%   cfg.uvar  = unit variable, row number of design that contains the labels of the units-of-observation, i.e. subjects or trials (default=2)
%
% The labels for the independent variable should be specified as numbers ranging
% from 1 to the number of conditions. The labels for the unit of observation should
% be integers ranging from 1 to the total number of observations (subjects or trials).
%
% See also FT_TIMELOCKSTATISTICS, FT_FREQSTATISTICS or FT_SOURCESTATISTICS

% Copyright (C) 2014, Diego Lozano-Soldevilla
%
% This file is part of FieldTrip, see http://www.fieldtriptoolbox.org
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

% set the defaults
cfg.computestat    = ft_getopt(cfg, 'computestat', 'yes');
cfg.computecritval = ft_getopt(cfg, 'computecritval', 'no');
cfg.computeprob    = ft_getopt(cfg, 'computeprob', 'no');
cfg.alpha          = ft_getopt(cfg, 'alpha', 0.05);
cfg.tail           = ft_getopt(cfg, 'tail', 1);
cfg.ivar           = ft_getopt(cfg, 'ivar', 1);
cfg.uvar           = ft_getopt(cfg, 'uvar', 2);

nconds = length(unique(design(cfg.ivar,:)));
ncontrasts = nconds-1;

% perform some checks on the configuration
if strcmp(cfg.computeprob,'yes') && strcmp(cfg.computestat,'no')
  ft_error('P-values can only be calculated if the test statistics are calculated.');
end
if ~isfield(cfg,'uvar') || isempty(cfg.uvar)
  ft_error('uvar must be specified for dependent samples statistics');
end

% perform some checks on the design
nuospercond=zeros(nconds,1);
for condindx=1:nconds
  nuospercond(condindx)=sum(design(cfg.ivar,:)==condindx);
end
if sum(nuospercond)<size(design,2) || any(nuospercond~=nuospercond(1))
  ft_error('Invalid specification of the design array.');
end
nunits = max(design(cfg.uvar,:));
dfdenom = nunits - ncontrasts;
if dfdenom<1
  ft_error('The data must contain more units-of-observation (subjects or trials) than the number of contrasts.')
end
nrepl=nunits*nconds;
if (nrepl~=sum(nuospercond)) || (nrepl~=size(dat,2))
  ft_error('Invalid specification of the design array.');
end
nsmpls = size(dat,1);

if strcmp(cfg.computestat,'yes')
  % compute the statistic
  % store the positions of the condition labels nunits-by-nconds array
  poslabelsperunit=zeros(nunits,nconds);
  for condindx=1:nconds
    poslabel=find(design(cfg.ivar,:)==condindx);
    [dum,i]=sort(design(cfg.uvar,poslabel),'ascend');
    poslabelsperunit(:,condindx)=poslabel(i);
  end
  % reshape poslabelsperunit into a row vector that contains the
  % replications of the first condition on the first nunits positions,
  % the replications of the second condition on the second nunits
  % positions, etc.
  poslabelsperunit=reshape(poslabelsperunit,1,nrepl);
  %s.stat=zeros(nsmpls,1);
  %for smplindx=1:nsmpls
  %  datonesmpl=reshape(dat(smplindx,poslabelsperunit),nunits,nconds);
  %
  %  Ysub = mean(datonesmpl,2);
  %  Yfac = mean(datonesmpl,1);
  %
  %  % computing sums of squares
  %  meanYsub = mean(Ysub);
  %  SStot = sum((datonesmpl(:)-meanYsub).^2);
  %  SSsub = nconds * sum(sum((Ysub-meanYsub).^2));
  %  SSfac = nunits * sum(sum((Yfac-meanYsub).^2));
  %  SSerr = SStot - SSsub - SSfac;
  %
  %  % mean sum of squares for factor levels
  %  df  = nconds - 1;
  %  dfe = size(datonesmpl(:),1)  - nunits - df;
  %
  %  MSfac = SSfac/df;
  %  MSerr = SSerr/dfe;
  %
  %  s.stat(smplindx) = MSfac/MSerr; % F-statistic
  %end
  dat  = reshape(dat(:,poslabelsperunit),[nsmpls nunits nconds]);
  Ysub = nanmean(dat,3);
  Yfac = nanmean(dat,2);

  meanYsub = nanmean(Ysub,2);
  SStot    = nansum(nansum((dat-meanYsub(:,ones(1,nunits),ones(1,nconds))).^2,3),2);
  SSsub    = nconds * nansum((Ysub-meanYsub(:,ones(1,nunits))).^2,2);
  SSfac    = nunits * nansum((Yfac-meanYsub(:,1,ones(1,nconds))).^2,3);
  SSerr    = SStot - SSsub - SSfac;

  % mean sum of squares for factor levels
  df  = nconds - 1;
  dfe = sum(isfinite(dat(:,:)),2) - nunits - df;

  MSfac = SSfac./df;
  MSerr = SSerr./dfe;

  s.stat = MSfac./MSerr; % F-statistic;
end

if strcmp(cfg.computecritval,'yes')
  % also compute the critical values
  s.dfnum = nconds - 1;
  s.dfdenom = nrepl - nunits - s.dfnum;
  if cfg.tail==-1
    ft_error('For a dependent samples F-statistic, it does not make sense to calculate a left tail critical value.');
  end
  if cfg.tail==0
    ft_error('For a dependent samples F-statistic, it does not make sense to calculate a two-sided critical value.');
  end
  if cfg.tail==1
    s.critval = finv(1-cfg.alpha,s.dfnum,s.dfdenom);
  end
end

if strcmp(cfg.computeprob,'yes')
  % also compute the p-values
  s.dfnum = nconds - 1;
  s.dfdenom = nrepl - nunits - s.dfnum;
  if cfg.tail==-1
    ft_error('For a dependent samples F-statistic, it does not make sense to calculate a left tail p-value.');
  end
  if cfg.tail==0
    ft_error('For a dependent samples F-statistic, it does not make sense to calculate a two-sided p-value.');
  end
  if cfg.tail==1
    s.prob = 1-fcdf(s.stat,s.dfnum,s.dfdenom);
  end
end
