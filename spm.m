function [R1,R2]=spm(Action,P2)
% SPM: Statistical Parametric Mapping (startup function)
%
% SPM (Statistical Parametric Mapping) is a package for the analysis
% functional brain mapping experiments. It is the in-house package of
% the Wellcome Department of Cognitive Neurology, and is freely
% availabe to the scientific community.
% 
% Theoretical, computational and other details of the package are
% available in SPM's "Help" facility. Details of this release are
% availiable via the "About SPM" button on the splash screen.
% (Or type help spm.man in MatLab)
% 
% This spm function initialises the default parameters, and displays a
% splash screen with buttons leading to the PET(SPECT) & fMRI
% modalities.
%
% Other arguments lead to various setup facilities, mainly of use to
% SPM power users and programmers. See the programmers FORMAT & help
% below.
%
%_______________________________________________________________________
% %W% Karl Friston, Andrew Holmes %E%
%
%=======================================================================
% - FORMAT specifications for embedded CallBack functions
%=======================================================================
%( This is a multi function function, the first argument is an action  )
%( string, specifying the particular action function to take. Recall   )
%( MatLab's command-function duality: `spm Welcome` is equivalent to   )
%( `spm('Welcome')`.                                                   )
%
% FORMAT spm
% Defaults to spm('Welcome')
%
% FORMAT spm('Welcome')
% Clears command window, deletes all figures, prints welcome banner and
% splash screen, sets window defaults.
%
% FORMAT spm('PET') spm('FMRI')
% Closes all windows and draws new Menu, Interactive, and Graphics
% windows for an SPM session. The buttons in the Menu window launch the
% main analysis routines.
%
% FORMAT spm('CreateIntWin')
% Creates an SPM Interactive window.
%
% FORMAT spm('ChMod',Modality)
% Changes modality of SPM: Currently SPM supports PET & MRI modalities,
% each of which have a slightly different Menu window and different
% defaults. This function switches to the specified modality, setting
% defaults and displaying the relevant buttons.
%
% FORMAT spm('SetWinDefaults')
% Sets defaults for figures, such as white backgrounds, a4 paper, gray
% colormaps etc...
%
% FORMAT spm('defaults',Modality)
% Sets default global variables for the specified modality.
%
% FORMAT [Modality,ModNum]=spm('CheckModality',Modality)
% Checks the specified modality against those supported, returns
% upper(Modality) and the Modality number, it's position in the list of
% supported Modalities.
%
% FORMAT A=spm('GetWinScale')
% Returns ratios of current display dimensions to that of a 1152 x 900
% Sun display. A=[Xratio,Yratio,Xratio,Yratio]. Used for scaling other
% GUI elements.
%
% FORMAT SPMdir=spm('Dir',Fname)
% Returns the directory containing the version of spm in use,
% identified as the first in MATLABPATH containing the Mfile spm (this
% file) (or Fname if specified).
%
% FORMAT SPMver=spm('Ver')
% Returns the current version of SPM, identified by the top line of the
% Contents.m file in the directory containing the currently used spm.m
%
% FORMAT [c,cName]=spm('Colour')
% Returns the rgb tripls and a description for the current en-vogue SPm
% colour, the background colour for the Menu and Help windows.
%
% FORMAT spm('SetCmdWinLabel',WinStripe,IconLabel)
% Sets the names on the headers and icons of Sun command tools.
% WinStripe defaults to a summary line identifying the user, host and
% MatLab version; IconLabel to 'MatLab'.
%
%_______________________________________________________________________

%-Parameters
Modalities=str2mat('PET','FMRI');

%-Format arguments
if nargin==0, Action='Welcome'; end


if strcmp(lower(Action),lower('Welcome'))
%=======================================================================

%-Clear the Command window & delete all figures
%-----------------------------------------------------------------------
clc
close all
SPMver = spm('Ver');

%-Print welcome banner
%-----------------------------------------------------------------------
disp( ' ___  ____  __  __                                                  ')
disp( '/ __)(  _ \(  \/  )  Statistical Parametric Mapping                 ')
disp( '\__ \ )___/ )    (   The Wellcome Department of Cognitive Neurology ')
disp(['(___/(__)  (_/\/\_)  Version: ',SPMver])
disp(' ')
% disp('  John Ashburner, Karl Friston, Andrew Holmes, Jean-Baptiste Poline')
fprintf('\n')

%-Open startup window, set window defaults
%-----------------------------------------------------------------------
S = get(0,'ScreenSize');
F = figure('Color',[1 1 1]*.8,...
	'Name','',...
	'NumberTitle','off',...
	'Position',[S(3)/2-300,S(4)/2-140,500,280],...
	'Resize','off');
spm('SetWinDefaults')
spm('SetCmdWinLabel')

%-Frames and text
%-----------------------------------------------------------------------
axes('Position',[0 0 80/500 280/280],'Visible','Off')
text(0.5,0.5,'SPM',...
	'FontName','Times','FontSize',96,...
	'Rotation',90,...
	'VerticalAlignment','middle','HorizontalAlignment','center',...
	'Color',[1 1 1]*.6);

uicontrol(F,'Style','Frame','Position',[110 120 380 140]);
uicontrol(F,'Style','Frame','Position',[110 020 380 090]);

c = ['STATISTICAL PARAMETRIC MAPPING  - {',SPMver,'}'];
uicontrol(F,'Style','Text', 'Position',[112 220 376 30],...
'String',c,'ForegroundColor',[1 0 0])

c = 'The Wellcome Department of Cognitive Neurology,';
uicontrol(F,'Style','Text', 'Position',[112 200 376 16],'String',c)
c = 'The Institute of Neurology';
uicontrol(F,'Style','Text', 'Position',[112 180 376 16],'String',c)
c = 'University College London';
uicontrol(F,'Style','Text', 'Position',[112 160 376 16],'String',c)

%-Objects with Callbacks - PET, fMRI or About SPM
%-----------------------------------------------------------------------
uicontrol(F,'String','PET and SPECT',...
	'Position',[140 066 150 30],...
	'CallBack','close(gcf), clear all, spm(''PET'')',...
	'Interruptible','yes',...
	'ForegroundColor',[0 1 1]);
uicontrol(F,'String','fMRI time-series',...
	'Position',[310 066 150 30],...
'CallBack','close(gcf), clear all, spm(''FMRI'')',...
	'Interruptible','yes',...
	'ForegroundColor',[0 1 1]);
uicontrol(F,'String','About SPM',...
	'Position',[140 030 320 30],...
	'CallBack','spm_help(''Disp'',''spm.man'')',...
	'Interruptible','yes',...
	'ForegroundColor',[0 1 1]);
return


elseif strcmp(lower(Action),lower('PET')) | ...
	strcmp(lower(Action),lower('FMRI'))
%=======================================================================
% spm(Modality)
Modality = upper(Action);

close all

%-Draw SPM windows
%-----------------------------------------------------------------------
%-Work out figure positions and sizes
A  = spm('GetWinScale');
S1 = [108 429 400 445].*A;
S2 = [108 008 400 395].*A;
S3 = [515 008 600 865].*A;

%-Menu window
Fmenu = figure('Tag','Menu',...
	'Name',spm('Ver'),...
	'Color',[1 1 1]*.8,...
	'Position',S1,...
	'NumberTitle','off',...
	'Resize','off',...
	'Visible','off');

spm('SetWinDefaults')
Finter = figure('Tag','Interactive',...
	'Name','',...
	'Color',[1 1 1]*.7,...
	'Position',S2,...
	'NumberTitle','off',...
	'Resize','off',...
	'Visible','off');

Fgraph = figure('Tag','Graphics',...
	'Name','Results',...
	'Position',S3,...
	'NumberTitle','off',...
	'Resize','off',...
	'Visible','off',...
	'PaperPosition',[.75 1.5 7 9.5]);
spm_figure('CreateBar','Graphics');

%-Main menu & Help window
%=======================================================================

%-Frames and text
%-----------------------------------------------------------------------
uicontrol(Fmenu,'Style','Frame','BackgroundColor',spm('Colour'),...
	'Position',[010 145 380 295].*A,'Tag','Empty');

uicontrol(Fmenu,'Style','Frame',...
	'Position',[020 355 360 075].*A,'Tag','Empty');	
uicontrol(Fmenu,'Style','Text','String','Spatial',...
	'Position',[100 405 200 20].*A,'Tag','Empty',...
	'ForegroundColor','w')

uicontrol(Fmenu,'Style','Frame',...
	'Position',[020 235 360 110].*A,'Tag','Empty');
	uicontrol(Fmenu,'Style','Text','String','Analysis',...
	'Position',[100 320 200 20].*A,'Tag','Empty',...
	'ForegroundColor','w')

uicontrol(Fmenu,'Style','Frame',...
	'Position',[020 155 360 070].*A,'Tag','Empty');
uicontrol(Fmenu,'Style','Text','String','Results',...
	'Position',[100 200 200 20].*A,'Tag','Empty',...
	'ForegroundColor','w' )

uicontrol(Fmenu,'Style','Text',...
	'String','SPM for PET/SPECT',...
	'ForegroundColor',[1 1 1]*.6,...
	'BackgroundColor',[1 1 1]*.8,...
	'HorizontalAlignment','center',...
	'Position',[020 125 360 020].*A,...
	'Tag','PET','Visible','off')
uicontrol(Fmenu,'Style','Text',...
	'String','SPM for functional MRI',...
	'ForegroundColor',[1 1 1]*.6,...
	'BackgroundColor',[1 1 1]*.8,...
	'HorizontalAlignment','center',...
	'Position',[020 125 360 020].*A,...
	'Tag','FMRI','visible','off')

uicontrol(Fmenu,'Style','Frame','BackgroundColor',spm('Colour'),...
	'Position',[010 010 380 112].*A,'Tag','Empty');

%-Objects with Callbacks - main spm_*_ui.m routines
%-----------------------------------------------------------------------
uicontrol(Fmenu,'String','Realign',	'Position',[040 370 080 30].*A,...
	'CallBack','spm_realign',	'Interruptible','yes');

uicontrol(Fmenu,'String','Normalize',	'Position',[150 370 100 30].*A,...
	'CallBack','spm_sn3d',	'Interruptible','yes');

uicontrol(Fmenu,'String','Smooth',	'Position',[280 370 080 30].*A,...
	'CallBack','spm_smooth_ui',	'Interruptible','yes');

uicontrol(Fmenu,'String','Statistics',	'Position',[130 285 140 30].*A,...
	'CallBack','spm_spm_ui',	'Interruptible','yes',...
	'Visible','off',		'Tag','PET');

uicontrol(Fmenu,'String','Statistics',	'Position',[130 285 140 30].*A,...
	'CallBack','spm_fmri_spm_ui',   'Interruptible','yes',...
	'Visible','off',		'Tag','FMRI');

uicontrol(Fmenu,'String','Eigenimages',	'Position',[130 245 140 30].*A,...
	'CallBack','spm_svd_ui',	'Interruptible','yes');

uicontrol(Fmenu,'String','SPM{F}',	'Position',[045 165 070 30].*A,...
	'CallBack','spm_spmF',		'Interruptible','yes');

uicontrol(Fmenu,'String','SPM{Z}',	'Position',[165 165 070 30].*A,...
	'CallBack','spm_projections_ui','Interruptible','yes');

uicontrol(Fmenu,'String','Results',	'Position',[285 165 070 30].*A,...
	'CallBack','spm_sections_ui',	'Interruptible','yes');

%uicontrol(Fmenu,'String','Render',	'Position',[290 130 070 30].*A,...
%	'CallBack','spm_surface_ui',	'Interruptible','yes',...
%	'Visible','off',		'Tag','PET');

uicontrol(Fmenu,'String','Analyze',	'Position',[020 088 082 024].*A,...
	'CallBack','!analyze',		'Interruptible','yes');

uicontrol(Fmenu,'String','Display',	'Position',[112 088 083 024].*A,...
	'CallBack','spm_image',		'Interruptible','yes');

uicontrol(Fmenu,'String','<empty>',	'Position',[205 088 083 024].*A,...
	'CallBack','','Visible','off',	'Interruptible','yes');

uicontrol(Fmenu,'Style','PopUp','String',Modalities,...
	'Tag','Modality',		'Position',[298 088 082 024].*A,...
	'CallBack',...
	[	'if get(gco,''Value'')~=get(gco,''UserData''),',...
			'spm(''ChMod'',get(gco,''Value'')),',...
		'end'],...
					'Interruptible','yes');

uicontrol(Fmenu,'String','Mean',	'Position',[020 054 082 024].*A,...
	'CallBack','spm_average',	'Interruptible','yes');

uicontrol(Fmenu,'String','ImCalc',	'Position',[112 054 083 024].*A,...
	'CallBack','spm_image_funks',	'Interruptible','yes');

uicontrol(Fmenu,'String','MRI to PET',	'Position',[205 054 083 024].*A,...
	'CallBack','spm_mri2pet',	'Interruptible','yes');

uicontrol(Fmenu,'String','MRsegment',	'Position',[298 054 082 024].*A,...
	'CallBack','spm_segment',	'Interruptible','yes');

uicontrol(Fmenu,'String','Help',	'Position',[020 020 082 024].*A,...
	'CallBack','spm_help',		'Interruptible','yes');

uicontrol(Fmenu,'String','Defaults',	'Position',[112 020 083 024].*A,...
	'CallBack','spm_defaults',	'Interruptible','yes');

User = getenv('USER');
uicontrol(1,'String',['<',User,'>'],	'Position',[205 020 083 024].*A,...
					'Interruptible','yes',...
	'CallBack',...
		['if exist(''' User ''');',...
		 User,';else;spm_help(''Disp'',''spm_BUTTON.m''); end']);

uicontrol(Fmenu,'String','Quit',	'Position',[298 020 082 024].*A,...
	'ForeGroundColor','r',...
	'CallBack','close all,clear all,clc,fprintf(''Bye...\n\n>> '')');

%=======================================================================
%-Setup for current modality
spm('ChMod',Modality)

%-Reveal windows
set([Fmenu,Finter,Fgraph],'Visible','on')

return


elseif strcmp(lower(Action),lower('CreateIntWin'))
%=======================================================================
% spm('CreateWin',Windows)
Finter = figure('Tag','Interactive',...
	'Name','',...
	'Color',[1 1 1]*.7,...
	'Position',[108 008 400 395].*spm('GetWinScale'),...
	'NumberTitle','off',...
	'Resize','off',...
	'Visible','on');
R1 = Finter;
return


elseif strcmp(lower(Action),lower('ChMod'))
%=======================================================================
% spm('ChMod',Modality)

%-Sort out arguments
%-----------------------------------------------------------------------
if nargin<2, Modality=''; else, Modality=P2; end
[Modality,ModNum]=spm('CheckModality',Modality);

if strcmp(Modality,'PET'), OModality='FMRI'; else, OModality='PET'; end

%-Sort out global defaults
%-----------------------------------------------------------------------
spm('defaults',Modality)

%-Sort out visability of appropriate controls on Menu window
%-----------------------------------------------------------------------
Fmenu = spm_figure('FindWin','Menu');
if isempty(Fmenu), error('SPM Menu window not found'), end

set(findobj(Fmenu,'Tag',OModality),'Visible','off')
set(findobj(Fmenu,'Tag', Modality),'Visible','on')
set(findobj(Fmenu,'Tag','Modality'),'Value',ModNum,'UserData',ModNum)

%-For fMRI, check descriptors limit
%-----------------------------------------------------------------------
if strcmp(Modality,'FMRI')
	[s,w] = unix('limit');
	d     = findstr(w,'descriptors');
	w     = eval(w((d + 11):length(w)));
	if (w < 256) warndlg(['To increase; quit SPM & MatLab and type ',...
		'''unlimit'' and restart'],...
		sprintf('WARNING: file descriptors = %d',w))
	end
end
return




elseif strcmp(lower(Action),lower('SetWinDefaults'))
%=======================================================================
whitebg(0,'w')
set(0,'DefaultFigureColormap',gray);
set(0,'DefaultFigurePaperType','a4letter')

return

elseif strcmp(lower(Action),lower('defaults'))
%=======================================================================
% spm('defaults',Modality)

%-Sort out arguments
%-----------------------------------------------------------------------
if nargin<2, Modality=''; else, Modality=P2; end
Modality=spm('CheckModality',Modality);

%-Set MODALITY
%-----------------------------------------------------------------------
global MODALITY
MODALITY = Modality;

%-Set global defaults (global variables)
%-----------------------------------------------------------------------
global SWD CWD TWD PRINTSTR LOGFILE CMDLINE GRID DESCRIP UFp

SWD	 = spm('Dir');					% SPM directory
CWD	 = pwd;						% Working directory
TWD	 = getenv('SPMTMP');				% Temporary directory
if isempty(TWD)
	TWD = '/tmp';
end
PRINTSTR = 'print -dpsc -append spm.ps';		% Print string
LOGFILE	 = '';						% SPM log file
if isempty(CMDLINE), CMDLINE  = 0; end			% Command line flag
GRID	 = 0.6;						% Grid value
DESCRIP  = 'spm compatible';				% Description string
UFp	 = 0.05;					% Upper tail F-prob

%-Set Modality specific default (global variables)
%-----------------------------------------------------------------------
global DIM VOX SCALE TYPE OFFSET ORIGIN
if strcmp(Modality,'PET')
	DIM	= [128 128 43];				% Dimensions [x y z]
	VOX	= [2.1 2.1 2.45];			% Voxel size [x y z]
	SCALE	= 1;					% Scaling coeficient
	TYPE	= 2;					% Data type
	OFFSET	= 0;		    			% Offset in bytes
	ORIGIN	= [0 0 0];				% Origin in voxels
elseif strcmp(Modality,'FMRI')
	DIM	= [128 128 43];				% Dimensions {x y z]
	VOX	= [2.1 2.1 2.45];			% Voxel size {x y z]
	SCALE	= 1;					% Scaling coeficient
	TYPE	= 2;					% Data type
	OFFSET	= 0;		   			% Offset in bytes
	ORIGIN	= [0 0 0];				% Origin in voxels
elseif strcmp(Modality,'UNKNOWN')
else
	error('Illegal Modality')
end

return

elseif strcmp(lower(Action),lower('CheckModality'))
%=======================================================================
% [Modality,ModNum]=spm('CheckModality',Modality)
if nargin<2, Modality=''; else, Modality=upper(P2); end
if isempty(Modality)
	global MODALITY
	if ~isempty(MODALITY); Modality=MODALITY;
	else, Modality='UNKNOWN'; end
end
if isstr(Modality)
	ModNum = find(all(Modalities(:,1:length(Modality))'==...
			Modality'*ones(1,size(Modalities,1))));
else
	if ~any(Modality==[1:size(Modalities,1)])
		Modality = 'ERROR';
		ModNum   = [];
	else
		ModNum   = Modality;
		Modality = deblank(Modalities(ModNum,:));
	end
end

if isempty(ModNum), error('Unknown Modality'), end
R1 = upper(Modality);
R2 = ModNum;
return


elseif strcmp(lower(Action),lower('GetWinScale'))
%=======================================================================
% spm('GetWinScale')
S   = get(0,'ScreenSize');
R1  = [S(3)/1152 S(4)/900 S(3)/1152 S(4)/900];

return


elseif strcmp(lower(Action),lower('Dir'))
%=======================================================================
% spm('Ver',Mfile)
if nargin<2, Mfile='spm'; else, Mfile=P2; end
tmp    = which(Mfile);
if ~isstr(tmp)
	error(['Can''t find ',Mfile,' on MATLABPATH']); end
SPMdir = strrep(tmp,['/',Mfile,'.m'],'');
R1     = SPMdir;
return

elseif strcmp(lower(Action),lower('Ver'))
%=======================================================================
% spm('Ver',Mfile)
if nargin<2, Mfile='spm'; else, Mfile=P2; end
SPMdir = spm('Dir',Mfile);
CFile  = [SPMdir,'/Contents.m'];
if exist(CFile)
	fid  = fopen(CFile,'r');
	SPMver = setstr([fread(fid,80,'char')',setstr(10)]);
	fclose(fid);
	SPMver(1:max(1,min(find(SPMver~='%' & SPMver~=' '))-1))=[];
	SPMver = SPMver(1:min(find(SPMver==10))-1);
else
	SPMver = 'SPM';
end
R1 = SPMver;
return

elseif strcmp(lower(Action),lower('Colour'))
%=======================================================================
% spm('Colour')
R1 = [0.7,1.0,0.7];
R2 = 'Lime Green';
return

elseif strcmp(lower(Action),lower('SetCmdWinLabel'))
%=======================================================================
% spm('SetCmdWinLabel',WinStripe,IconLabel)

%-Only label Sun command tools
Term        = getenv('TERM');
if ~strcmp(Term,'sun-cmd'), return, end

%-Work out label text
User        = getenv('USER');
[null,Host] = unix('echo `hostname` | sed -e ''s/\..*$//''');
Host        = Host(1:length(Host)-1);

if nargin<3, IconLabel='MatLab'; end
if nargin<2, WinStripe=[User,' - ',Host,' : MatLab ',version]; end

%-Set window stripe
disp([']l' WinStripe '\]L' IconLabel '\'])
return

else
%=======================================================================
error('Unknown action string')

%=======================================================================
end
