function varargout=spm_figure(varargin)
% Setup and callback functions for Graphics window
% FORMAT varargout=spm_figure(varargin)
%	- An embedded callback, multi-function function
%       - For detailed programmers comments, see the format specifications
%         below
%_______________________________________________________________________
%
% spm_figure creates and manages the 'Graphics' window. This window and
% these facilities may be used independently of SPM, and any number of
% Graphics windows my be used within the same MatLab session. (Though
% only one SPM 'Graphics' 'Tag'ed window is permitted.
%
% The Graphics window is provided with a menu bar at the top that
% facilitates editing and printing of the current graphic display,
% enabling interactive editing of graphic output prior to printing
% (e.g. selection of color maps, deleting, moving and editing graphics
% objects or adding text)
%
% Print: Creates a footnote (detailing the SPM version, user & date)
% and evaluates PRINTSTR (see spm_defaults.m). Graphics windows with
% multi-page axes are printed page by page.
%
% Clear: Clears the Graphics window, leaving the menu bar. If in SPM
% usage (figure 'Tag'ed as 'Graphics' then the 'Interactive' 'Tag'ed
% window is also cleared, and it's name and pointer reset.
%
% Colormap options:
% * Gray and Hot: Sets the colormap to its default values and loads
%                 either a grayscale or 'hot metal' color map.
% * Split: Loads a 'split' color map from 'Split.mat' {128 x 3
%          matrix}.  The lower half is a gray scale and the upper half
%          is 'hot metal'.  This color map is used for viewing 'rendered' 
%          SPM{Z} on a PET, MRI or other background images
%
% Colormap effects:
% * Invert: Inverts (flips) the current color map.
% * Brighten and Darken: Brighten and Darken the current colourmap
% 	   using the MatLab BRIGHTEN command, with  beta's of +0.2 and -0.2
% 	   respectively.
%
% Editing: Right button ('alt' button) cancels operations
% * Cut  : Deletes the graphics object next selected (if deletable)
% * Move : To re-position a text, uicontrol or axis object using a
%          'drag and drop' implementation (i.e. depress - move - release)
%          Using the middle 'extend' mouse button on a text object moves
%          the axes containing the text - i.e. blocks of text.
% * Size : Re-sizes the text, uicontrol or axis object next selected
%          {left button - decrease, middle button  - increase} by a factor
%          of 1.24 (or increase/decrease FontSize by 2 dpi)
% * Text : Creates an editable text widget that produces a text object as
%          its CallBack.
%          This text object can then be manipulated using the edit facilities.
% * Edit : To edit text, select a text object with the circle cursor,
%          and edit the text in the editable text widget that appears.
%
% For SPM usage, the figure should be 'Tag'ed as 'Graphics'.
%
% For SPM power users, and programmers, spm_figure provides utility
% routines for using the SPM graphics interface. Of particular use are
% the GetWin, FindWin and Clear functions See the embedded callback
% reference in the main body of spm_figure, below the help text.
%
% See also: spm_print, spm_clf
%
%_______________________________________________________________________
% %W% Andrew Holmes %E%

%=======================================================================
% - FORMAT specifications for embedded CallBack functions
%=======================================================================
%( This is a multi function function, the first argument is an action  )
%( string, specifying the particular action function to take. Recall   )
%( MatLab's command-function duality: `spm_figure Create` is           )
%( equivalent to `spm('Create')`.                                      )
%
% FORMAT F = spm_figure
% [ShortCut] Defaults to Action 'Create'
%
% FORMAT F = spm_figure(F) - numeric F
% [ShortCut] Defaults to spm_figure('CreateBar',F)
%
% FORMAT F = spm_figure('Create',Tag,Name,Visible)
% Create a full length WhiteBg figure 'Tag'ed Tag (if specified),
% with a ToolBar.
% Equivalent to spm_figure('CreateWin','Tag') and spm_figure('CreateBar')
% Tag	  - 'Tag' string for figure.
% Name    - Name for window
% Visible - 'on' or 'off'
% F	  - Figure used
%
% FORMAT F = spm_figure('FindWin',F)
% Finds window with 'Tag' or figure numnber F - returns empty F if not found
% F	- (Input)  Figure to use [Optional] - 'Tag' string or figure number.
%	- Defaults to 'Graphics'
% F	- (Output) Figure number (if found) or empty (if not).
%
% FORMAT F = spm_figure('GetWin',Tag)
% Like spm_figure('FindWin',Tag), except that if 'Tag' is 'Graphics' or
% 'Interactive' and no such 'Tag'ged figure is found, one is created.
% Tag	- Figure 'Tag' to get, defaults to 'Graphics'
% F	- Figure number (if found/created) or empty (if not).
%
% FORMAT F = spm_figure('ParentFig',h)
% Finds window containing the object whose handle is specified
% h	- Handle of object whose parent figure is required
%	- If a vector, then first object handle is used
% F	- Number or parent figure
%
% FORMAT spm_figure('Clear',F,Tags)
% Clears figure, leaving ToolBar (& other objects with invisible handles)
% Optional third argument specifies 'Tag's of objects to delete.
% If figure F is 'Tag'ged 'Interactive' (SPM usage), then the window
% name and pointer are reset.
% F	- 'Tag' string or figure number of figure to clear, defaults to gcf
% Tags  - 'Tag's (string matrix or cell array of strings) of objects to delete
%         *regardless* of 'HandleVisibility'. Only these objects are deleted.
%         '!all' denotes all objects
%
% FORMAT F = spm_figure('CreateWin',Tag,Name,Visible)
% Creates a full length WhiteBg figure 'Tag'ged Tag (if specified).
% F	  - Figure created
% Tag	  - Tag for window
% Name    - Name for window
% Visible - 'on' or 'off'
%
% FORMAT spm_figure('CreateBar',F)
% Creates toolbar in figure F (defaults to gcf). F can be a 'Tag'
% If the figure is 'Tag'ed as 'Graphics' (SPM usage), then the Print button
% callback is set to attempt to clear an 'Interactive' figure too.
%
% FORMAT spm_figure('Print',F,PFile)
% SPM print function: Appends footnote & executes PRINTSTR
% F	- [Optional] Figure to print. ('Tag' or figure number)
%	  Defaults to figure 'Tag'ed as 'Graphics'.
%	  If none found, uses CurrentFigure if avaliable.
% PFile - [Optional] File to print to.
%	  If specified then PRINTSTR is overridden.
% PRINTSTR - global variable holding print command to be evaluated
%	  Defaults to 'print -dps2 fig.ps'
% If objects 'Tag'ed 'NextPage' and 'PrevPage' are found, then the
% pages are shown and printed in order. In breif, pages are held as
% seperate axes, with ony one 'Visible' at any one time. The handles of
% the "page" axes are stored in the 'UserData' of the 'NextPage'
% object, while the 'PrevPage' object holds the current page number.
% See spm_help('!Disp') for details on setting up paging axes.
%
% FORMAT spm_figure('NewPage',hPage,MoveOn)
% SPM pagination function: Makes objects with handles hPage paginated
% Creates pagination buttons if necessary.
% hPage	 - Handles of objects to stick to this page
% MoveOn - If specified, causes hPage objects to be made invisible
%
% FORMAT spm_figure('DeletePageControls',F)
% SPM pagination function: Deletes page controls
% F	- [Optional] Figure in which to attempt to turn the page
%         Defaults to 'Graphics' 'Tag'ged window
%
% FORMAT spm_figure('WaterMark',F,str,Tag,Angle,Perm)
% Adds watermark to figure windows.
% F	- Figure for watermark. Defaults to gcf
% str   - Watermark string. Defaults (missing or empty) to SPM
% Tag   - Tag for watermark axes. Defaults to ''
% Angle - Angle for watermark. Defaults to -45
% Perm  - If specified, then watermark is permanent (HandleVisibility 'off')
%
% FORMAT spm_figure('TurnPage',move,F)
% SPM pagination function: Turn to specified page
%
% FORMAT spm_figure('ColorMap')
% Callback for "ColorMap" buttons
%
% FORMAT spm_figure('GraphicsCut')
% Callback for "Cut" button
%
% FORMAT spm_figure('GraphicsMoveStart')
% Callback for "Move" button
%
% FORMAT spm_figure('GraphicsMoveMotion')
% Callback for move function
%
% FORMAT spm_figure('GraphicsMoveEnd')
% Callback for move function
%
% FORMAT spm_figure('GraphicsSize')
% Callback for "Size" button
%
% FORMAT spm_figure('GraphicsText')
% Callback for "Text" button
%
% FORMAT spm_figure('GraphicsTextEdit')
% Callback for "Edit" button
%_______________________________________________________________________


%-Condition arguments
%-----------------------------------------------------------------------
if (nargin==0), Action = 'Create'; else, Action = varargin{1}; end

switch lower(Action), case 'create'
%=======================================================================
% F = spm_figure('Create',Tag,Name,Visible)
%-Condition arguments
if nargin<4, Visible='on'; else, Visible=varargin{4}; end
if nargin<3, Name=''; else, Name=varargin{3}; end
if nargin<2, Tag=''; else, Tag=varargin{2}; end

F = spm_figure('CreateWin',Tag,Name,Visible);
spm_figure('CreateBar',F)
varargout = {F};


case 'createwin'
%=======================================================================
% F=spm_figure('CreateWin',Tag,Name,Visible)

%-Condition arguments
%-----------------------------------------------------------------------
if nargin<4 | isempty(varargin{4}), Visible='on'; else, Visible=varargin{4}; end
if nargin<3, Name=''; else, Name = varargin{3}; end
if nargin<2, Tag='';  else, Tag  = varargin{2}; end

S0   = get(0,'ScreenSize');
WS   = [S0(3)/1152 S0(4)/900 S0(3)/1152 S0(4)/900];

F      = figure(...
	'Tag',Tag,...
	'Position',[515 008 600 865].*WS,...
	'Resize','off',...
	'MenuBar','none',...
	'DefaultTextInterpreter','none',...
	'DefaultTextFontSize',2*round(12*min(WS)/2),...
	'DefaultUicontrolFontSize',2*round(12*min(WS)/2),...
	'DefaultUicontrolInterruptible','on',...
	'Color','w',...
	'ColorMap',gray(64),...
	'DefaultTextColor','k',...
	'DefaultAxesColor','w',...
	'DefaultAxesXColor','k',...
	'DefaultAxesYColor','k',...
	'DefaultAxesZColor','k',...
	'DefaultPatchFaceColor','k',...
	'DefaultPatchEdgeColor','k',...
	'DefaultSurfaceEdgeColor','k',...
	'DefaultLineColor','k',...
	'PaperPosition',[.75 1.5 7 9.5],...
	'PaperType','a4letter',...
	'InvertHardcopy','off',...
	'Visible','off');
if ~isempty(Name)
	set(F,'Name',[spm('GetUser'),' - ',Name],'NumberTitle','off'), end
set(F,'Visible',Visible)
varargout = {F};


case 'findwin'
%=======================================================================
% F=spm_figure('FindWin',F)
% F=spm_figure('FindWin',Tag)
%-Find window: Find window with FigureNumber# / 'Tag' attribute
%-Returns empty if window cannot be found - deletes multiple tagged figs.

if nargin<2, F='Graphics'; else, F=varargin{2}; end

if isempty(F)
	% Leave F empty
elseif isstr(F)
	% Finds Graphics window with 'Tag' string - delete multiples
	Tag=F;
	F = findobj(get(0,'Children'),'Flat','Tag',Tag);
	if length(F) > 1
		% Multiple Graphics windows - close all but most recent
		close(F(2:end))
		F = F(1);
	end
else
	% F is supposed to be a figure number - check it
	if ~any(F==get(0,'Children')), F=[]; end
end
varargout = {F};

case 'getwin'
%=======================================================================
% F=spm_figure('GetWin',Tag)

if nargin<2, Tag='Graphics'; else, Tag=varargin{2}; end
F = spm_figure('FindWin',Tag);

if isempty(F) & isstr(Tag)
	switch Tag, case 'Graphics'
		F = spm_figure('Create','Graphics','Graphics');
	case 'Interactive'
		F = spm('CreateIntWin');
	end
end
varargout = {F};

case 'parentfig'
%=======================================================================
% F=spm_figure('ParentFig',h)
if nargin<2, error('No object specified'), else, h=varargin{2}; end
F = get(h(1),'Parent');
while ~strcmp(get(F,'Type'),'figure'), F=get(F,'Parent'); end
varargout = {F};


case 'clear'
%=======================================================================
% spm_figure('Clear',F,Tags)

%-Sort out arguments
%-----------------------------------------------------------------------
if nargin<3, Tags=[]; else, Tags=varargin{3}; end
if nargin<2, F=get(0,'CurrentFigure'); else, F=varargin{2}; end
F = spm_figure('FindWin',F);
if isempty(F), return, end

%-Clear figure
%-----------------------------------------------------------------------
if isempty(Tags)
	%-Clear figure of objects with 'HandleVisibility' 'on'
	delete(findobj(get(F,'Children'),'flat','HandleVisibility','on'));
	%-Reset figures callback functions
	set(F,'KeyPressFcn','',...
		'WindowButtonDownFcn','',...
		'WindowButtonMotionFcn','',...
		'WindowButtonUpFcn')
	%-If this is the 'Interactive' window, reset name & UserData
	if strcmp(get(F,'Tag'),'Interactive')
		set(F,'Name','','UserData',[]), end
else
	%-Clear specified objects from figure
	cSHH = get(0,'ShowHiddenHandles');
	set(0,'ShowHiddenHandles','on')
	if isstr(Tags); Tags=cellstr(Tags); end
	if any(strcmp(Tags(:),'!all'))
		delete(get(F,'Children'))
	else
	    for tag = Tags(:)'
		delete(findobj(get(F,'Children'),'flat','Tag',tag{:}));
	    end
	end	
	set(0,'ShowHiddenHandles',cSHH)
end
set(F,'Pointer','Arrow')


case 'print'
%=======================================================================
% spm_figure('Print',F,PFile)

%-Arguments & defaults
if nargin<3, PFile='spm.ps'; else, PFile=varargin{3}; end
if nargin<2, F='Graphics'; else, F=varargin{2}; end

%-Find window to print, default to gcf if specified figure not found
% Return if no figures
F=spm_figure('FindWin',F);
if isempty(F), if any(get(0,'Children')), F = gcf; end, end
if isempty(F), return, end

%-Switch to figure to print
cF = get(0,'CurrentFigure');
set(0,'CurrentFigure',F)

%-See if window has paging controls
hNextPage = findobj(F,'Tag','NextPage');
hPrevPage = findobj(F,'Tag','PrevPage');
hPageNo   = findobj(F,'Tag','PageNo');
iPaged    = ~isempty(hNextPage);

%-Retrieve print command
%-----------------------------------------------------------------------
global PRINTSTR
if isempty(PRINTSTR) | (nargin>3)
	PrintCmd = ['print -dpsc2 -append ',PFile];
else
	PrintCmd = PRINTSTR;
end

%-Create footnote with SPM version, username, date and time.
%-----------------------------------------------------------------------
FNote = sprintf('%s (%s): %s',spm('ver'),spm('GetUser'),spm('time'));
%-Delete old tag lines, and print new one
delete(findobj(F,'Tag','SPMprintFootnote'));
axes('Position',[0.005,0.005,0.1,0.1],...
	'Visible','off',...
	'Tag','SPMprintFootnote')
text(0,0,FNote,'FontSize',6);

%-Print
%-----------------------------------------------------------------------
if ~iPaged
	eval(PrintCmd)
else
	hAxes     = get(hNextPage,'UserData');
	Cpage     = get(hPageNo,  'UserData');
	nPages    = size(hAxes,1);

	set([hNextPage,hPrevPage,hPageNo],'Visible','off')
	if Cpage~=1
		set(hAxes(Cpage,hAxes(Cpage,:)~=0),'Visible','off'), end
	for p = 1:nPages
		set(hAxes(p,hAxes(p,:)~=0),'Visible','on')
		eval(PrintCmd)
		set(hAxes(p,hAxes(p,:)~=0),'Visible','off')
	end
	set(hAxes(Cpage,hAxes(Cpage,:)~=0),'Visible','on')
	set([hNextPage,hPrevPage,hPageNo],'Visible','on')
end
set(0,'CurrentFigure',cF)


case 'newpage'
%=======================================================================
% h = spm_figure('NewPage',hPage,MoveOn)
if nargin<3, MoveOn=0; else, MoveOn=1; end
if nargin<2 | isempty(varargin{2}), error('No handles to paginate')
	else, hPage=varargin{2}(:)'; end

%-Work out which figure we're in
Fgraph = spm_figure('ParentFig',hPage(1));

hNextPage = findobj(Fgraph,'Tag','NextPage');
hPrevPage = findobj(Fgraph,'Tag','PrevPage');
hPageNo   = findobj(Fgraph,'Tag','PageNo');

%-Create pagination widgets if required
%-----------------------------------------------------------------------
if isempty(hNextPage)
	hNextPage = uicontrol(Fgraph,'Style','Pushbutton',...
		'HandleVisibility','on',...
		'String','>','FontSize',10,...
		'Callback','spm_figure(''TurnPage'',''+1'',gcf)',...
		'Position',[580 020 015 015].*spm('GetWinScale'),...
		'ForegroundColor',[0 0 0],...
		'Tag','NextPage','UserData',[]);
	hPrevPage = uicontrol(Fgraph,'Style','Pushbutton',...
		'HandleVisibility','on',...
		'String','<','FontSize',10,...
		'Callback','spm_figure(''TurnPage'',''-1'',gcf)',...
		'Position',[565 020 015 015].*spm('GetWinScale'),...
		'Visible','on',...
		'ForegroundColor',[1 1 1]*0.5,...
		'Tag','PrevPage');
	hPageNo = uicontrol(Fgraph,'Style','Text',...
		'HandleVisibility','on',...
		'String','',...
		'FontSize',8,...
		'HorizontalAlignment','center',...
		'BackgroundColor','w',...
		'Position',[560 005 040 015].*spm('GetWinScale'),...
		'Visible','on',...
		'Tag','PageNo','UserData',1);
end

%-Add handles for this page to UserData of hNextPage
%-----------------------------------------------------------------------
hAxes     = get(hNextPage,'UserData');
tmp       = max(size(hAxes,2),length(hPage));
hAxes     = [ [hAxes, zeros(size(hAxes,1),tmp-size(hAxes,2))];...
		[hPage, zeros(1,tmp-length(hPage))] ];
set(hNextPage,'UserData',hAxes)

%-Make handles for this page invisible if requested
%-----------------------------------------------------------------------
if MoveOn
	set(get(hPage,'Children'),'Visible','off')
end

%-Return handles to pagination controls if requested
if nargout>0
	varargout = {[hNextPage, hPrevPage, hPageNo]};
end


case 'turnpage'
%=======================================================================
% spm_figure('TurnPage',move,F)
if nargin<3, F='Graphics'; else, F=varargin{3}; end
if nargin<2, move=1; else, move=varargin{2}; end
Fgraph = spm_figure('FindWin',F);
if isempty(Fgraph), error('No Graphics window'), end

hNextPage = findobj(Fgraph,'Tag','NextPage');
hPrevPage = findobj(Fgraph,'Tag','PrevPage');
hPageNo   = findobj(Fgraph,'Tag','PageNo');
if isempty(hNextPage), return, end
hAxes     = get(hNextPage,'UserData');
Cpage     = get(hPageNo,  'UserData');
nPages    = size(hAxes,1);

%-Sort out new page number
if isstr(move)
	Npage = Cpage+eval(move);
else
	Npage = move;
end
Npage = max(min(Npage,nPages),1);

%-Make current page invisible, new page visible, set page number string
set(hAxes(Cpage,hAxes(Cpage,:)~=0),'Visible','off')
set(hAxes(Npage,hAxes(Npage,:)~=0),'Visible','on')
set(hPageNo,'UserData',Npage,'String',sprintf('%d / %d',Npage,nPages))

%-Set dimness of page turning controls (just for neatness)
if Npage==1, set(hPrevPage,'ForegroundColor',[1 1 1]*0.5)
else, set(hPrevPage,'ForegroundColor',[0 0 0]), end

if Npage==nPages, set(hNextPage,'ForegroundColor',[1 1 1]*0.5)
else, set(hNextPage,'ForegroundColor',[0 0 0]), end



case 'deletepagecontrols'
%=======================================================================
% spm_figure('DeletePageControls',F)
if nargin<2, F='Graphics'; else, F=varargin{2}; end
Fgraph = spm_figure('FindWin',F);
if isempty(Fgraph), error('No Graphics window'), end

hNextPage = findobj(Fgraph,'Tag','NextPage');
hPrevPage = findobj(Fgraph,'Tag','PrevPage');
hPageNo   = findobj(Fgraph,'Tag','PageNo');

delete([hNextPage hPrevPage hPageNo])


case 'watermark'
%=======================================================================
% spm_figure('WaterMark',F,str,Tag,Angle,Perm)
if nargin<6, HVis='on'; else, HVis='off'; end
if nargin<5, Angle=-45; else, Angle=varargin{5}; end
if nargin<4 | isempty(varargin{4}), Tag = 'WaterMark'; else, Tag=varargin{4}; end
if nargin<3 | isempty(varargin{3}), str = 'SPM';       else, str=varargin{3}; end
if nargin<2, if any(get(0,'Children')), F=gcf; else, F=''; end
	else, F=varargin{2}; end
F = spm_figure('FindWin',F);
if isempty(F), return, end

%-Specify watermark color from background colour
%-----------------------------------------------------------------------
Colour = get(F,'Color');
%-Only mess with grayscale backgrounds
if ~all(Colour==Colour(1)), return, end
%-Work out colour - lighter unless grey value > 0.9
Colour = Colour+(2*(Colour(1)<0.9)-1)*0.02;

cF = get(0,'CurrentFigure');
set(0,'CurrentFigure',F)
Units=get(F,'Units');
set(F,'Units','normalized');
h = axes('Position',[0.45,0.5,0.1,0.1],...
	'Units','normalized',...
	'Visible','off',...
	'Tag',Tag);
set(F,'Units',Units)
text(0.5,0.5,str,...
	'FontSize',96,...
	'FontWeight','Bold',...
	'FontName','Times',...
	'Rotation',Angle,...
	'HorizontalAlignment','Center',...
	'VerticalAlignment','middle',...
	'EraseMode','normal',...
	'Color',Colour,...
	'ButtonDownFcn',[...
		'if strcmp(get(gcbf,''SelectionType''),''open''),',...
			'delete(get(gcbo,''Parent'')),',...
		'end'])
set(h,'HandleVisibility',HVis)
set(0,'CurrentFigure',cF)


case 'createbar'
%=======================================================================
% spm_figure('CreateBar',F)
if nargin<2, if any(get(0,'Children')), F=gcf; else, F=''; end
	else, F=varargin{2}; end
F = spm_figure('FindWin',F);
if isempty(F), return, end

%-Get position and size parameters
%-----------------------------------------------------------------------
cUnits = get(F,'Units');
set(F,'Units','Pixels');
P     = get(F,'Position'); P  = P(3:4);		% Figure dimensions {pixels}
S_Gra = P./[600, 865];				% x & y scaling coefs

nBut  = 12;
nGap  = 2;
sx    = floor(P(1)./(nBut+(nGap+2)/6));		% uicontrol object width
dx    = floor(2*sx/6);				% inter-uicontrol gap
sy    = floor(20*S_Gra(1));			% uicontrol object height
x0    = dx;					% initial x position
x     = dx/2;					% uicontrol x position
y     = P(2) - sy;				% uicontrol y position
y2    = P(2) - 2.25*sy;				% uicontrol y position

FS    = round(12*min(S_Gra));			% uicontrol font size

%-Delete any existing 'ToolBar' 'Tag'ged objects
%-----------------------------------------------------------------------
cSHH = get(0,'ShowHiddenHandles');
set(0,'ShowHiddenHandles','on')
delete(findobj(F,'Tag','ToolBar'));
set(0,'ShowHiddenHandles',cSHH)

%-Create Frame for controls
%-----------------------------------------------------------------------
uicontrol(F,'Style', 'Frame',...
	'Position',[-4 (P(2) - 1.25*sy) P(1)+8 1.25*sy+4],...
	'Tag','ToolBar','HandleVisibility','callback');

%-Create uicontrol objects
%-----------------------------------------------------------------------
uicontrol(F,'String','Print' ,'Position',[x y sx sy],...
	'CallBack','spm_figure(''Print'',gcf)',...
	'FontSize',FS,...
	'Interruptible','off','BusyAction','cancel',...
	'Tag','ToolBar','HandleVisibility','callback',...
	'ForegroundColor','b'); x = x+sx;

h = uicontrol(F,'String','Clear' ,'Position',[x y sx sy],...
	'CallBack','spm_figure(''Clear'',gcbf)',...
	'FontSize',FS,...
	'Interruptible','off','BusyAction','cancel',...
        'Tag','ToolBar','HandleVisibility','callback',...
	'ForegroundColor','b'); x = x+sx+dx;
if strcmp(get(F,'Tag'),'Graphics')	%-Do a full SPM interface clear
	set(h,'CallBack','spm(''Clear'',''Interactive'',gcbf)')
end

uicontrol(F,'Style','PopUp','String','ColorMap|gray|hot|split',...
	'Position',[x,y,2*sx,sy],...
	'CallBack',['if (get(gco,''Value'') > 1),',...
			'set(gco,''UserData'',get(gco,''Value'')),',...
			'set(gco,''Value'',1),',...
			'spm_figure(''ColorMap'',get(gco,''UserData'')),',...
			'end'],...
	'FontSize',FS,...
	'Tag','ToolBar','HandleVisibility','callback',...
	'UserData','Pop'); x = x + 2*sx;

uicontrol(F,'Style','PopUp','String','Effects|invert|brighten|darken',...
	'Position',[x,y,2*sx,sy],...
	'CallBack',['if (get(gco,''Value'') > 1),',...
			'set(gco,''UserData'',get(gco,''Value'')),',...
			'set(gco,''Value'',1),',...
			'spm_figure(''ColorMap'',get(gco,''UserData'')),',...
			'end'],...
	'FontSize',FS,...
	'Tag','ToolBar','HandleVisibility','callback',...
	'UserData','Pop'); x = x + 2*sx + dx;

uicontrol(F,'String','cut',   'Position',[x y sx sy],...
	'CallBack','spm_figure(''GraphicsCut'')','FontSize',FS,...
	'Interruptible','off','BusyAction','cancel',...
	'Tag','ToolBar','HandleVisibility','callback'); x = x+sx;
uicontrol(F,'String','move',  'Position',[x y sx sy],...
	'CallBack','spm_figure(''GraphicsMoveStart'')','FontSize',FS,...
	'Interruptible','off','BusyAction','cancel',...
	'Tag','ToolBar','HandleVisibility','callback'); x = x+sx;
uicontrol(F,'String','size',  'Position',[x y sx sy],...
	'CallBack','spm_figure(''GraphicsSize'')','FontSize',FS,...
	'Interruptible','off','BusyAction','cancel',...
	'Tag','ToolBar','HandleVisibility','callback'); x = x+sx;
uicontrol(F,'String','text',  'Position',[x y sx sy],...
	'CallBack','spm_figure(''GraphicsText'')','FontSize',FS,...
	'Interruptible','off','BusyAction','cancel',...
	'Tag','ToolBar','HandleVisibility','callback'); x = x+sx;
uicontrol(F,'String','edit',  'Position',[x y sx sy],...
	'CallBack','spm_figure(''GraphicsTextEdit'')','FontSize',FS,...
	'Interruptible','off','BusyAction','cancel',...
	'Tag','ToolBar','HandleVisibility','callback'); x = x+sx+dx;

uicontrol(F,'String','?',     'Position',[x y dx sy],...
	'CallBack','spm_help(''spm_figure.m'')','FontSize',FS,...
	'Interruptible','off','BusyAction','queue',...
	'Tag','ToolBar','HandleVisibility','callback',...
	'ForegroundColor','g'); x = x+2*dx;

set(F,'Units',cUnits)


case 'colormap'
%=======================================================================
% spm_figure('Colormap',ColAction,h)
if nargin<3, h=[]; else, h=varargin{3}; end
if nargin<2, ColAction='gray'; else, ColAction=varargin{2}; end
if ~isstr(ColAction)
	if ColAction==1, return, end
	Actions   = get(gco,'String');
	ColAction = deblank(Actions(ColAction,:));
end
if strcmp(ColAction,'gray')
	colormap(gray(64))
elseif strcmp(ColAction,'hot')
	colormap(hot(64))
elseif strcmp(ColAction,'split')
	load Split; colormap(split)
elseif strcmp(ColAction,'invert')
	colormap(flipud(colormap))
elseif strcmp(ColAction,'brighten')
	colormap(brighten(colormap, 0.2))
elseif strcmp(ColAction,'darken')
	colormap(brighten(colormap, -0.2))
else
	error('Illegal ColAction specification')
end


case 'graphicscut'
%=======================================================================
% Delete next object clicked, provided it's deletable & in this gcbf
% "normal" mouse button deletes
% "extend" mouse button deletes blocks of text (deletes parent axes)
% "alt"    mouse button cancels operation
% spm_figure('GraphicsCut')

F = gcbf;
hBut  = gcbo;
set(hBut,'ForegroundColor','r')
tmp = get(F,'Name');
set(F,'Name',...
	'Cut: Select item to delete, RightMouse=cancel...');
set(F,'Pointer','Circle')
waitforbuttonpress;
h        = gco(F);
hType    = get(h,'Type');
SelnType = get(gcf,'SelectionType');
set(F,'Pointer','Arrow')
set(F,'Name',tmp)

if strcmp(get(h,'HandleVisibility'),'on') & ...
		~strcmp(SelnType,'alt') & ...
		~strcmp(hType,{'root','figure','uimenu','uicontrol'}) & ...
		gcf==F
	tmp  = get(h,'Type');
	if any(strcmp(hType,{'image','line','patch','surface'}))
		delete(get(h,'Parent'))
	elseif strcmp(SelnType,'extend') & strcmp(hType,'text')
		delete(get(h,'Parent'))
	elseif any(strcmp(tmp,{'text','axes'}))
		delete(h)
	end
end
set(hBut,'ForegroundColor','k')


case 'graphicsmovestart'
%=======================================================================
% Move the next object clicked, provided it's movable and in this figure
% "extend" mouse button moves blocks of text
% "alt"    mouse button cancels operation
% spm_figure('GraphicsMoveStart')

F          = gcbf;
hMoveBut   = gcbo;
set(hMoveBut,'ForegroundColor','r')
tmp        = get(F,'Name');
set(F,'Name','Move: MiddleMouse moves blocks of text. RightMouse=cancel');
set(F,'Pointer','CrossHair')
waitforbuttonpress;
hPress     = gco(F);
hPressType = get(hPress,'Type');
SelnType   = get(gcf,'SelectionType');
set(F,'Pointer','Fleur','Name',tmp)

if ~strcmp(get(hPress,'HandleVisibility'),'off') & ...
		~strcmp(SelnType,'alt') & ...
		~strcmp(hPressType,{'root','figure','uimenu','uicontrol'})&...
		gcf==F
	MS.cFUnits = get(F,'Units');
	set(F,'Units','Pixels')
	MS.OPt  = get(F,'CurrentPoint');
	if any(strcmp(hPressType,{'image','line','patch','surface'}))
		hMove = get(hPress,'Parent');
	elseif strcmp(SelnType,'extend') & strcmp(hPressType,'text')
		hMove = get(hPress,'Parent');
	elseif any(strcmp(hPressType,{'text','axes'}))
		hMove = hPress;
	else
		set(hMoveBut,'ForegroundColor','k')
		set(F,'Pointer','Arrow')
		return
	end

	%-Store info in UserData of hPress
	MS.hMove    = hMove;
	MS.hMoveBut = hMoveBut;
	MS.chMUnits = get(hMove,'Units');
	set(hMove,'Units','Pixels');
	MS.OPos     = get(hMove,'Position');
	MS.UserData = get(F,'UserData');
	set(hPress,'UserData',MS)

	%-Set Motion & ButtonUp functions
	set(F,'WindowButtonMotionFcn','spm_figure(''GraphicsMoveMotion'')')
	set(F,'WindowButtonUpFcn','spm_figure(''GraphicsMoveEnd'')')
else
	set(hMoveBut,'ForegroundColor','k')
	set(F,'Pointer','Arrow')
end


case 'graphicsmovemotion'
%=======================================================================
% spm_figure('GraphicsMoveMotion')
MS = get(gco,'UserData');
set(MS.hMove,'Units','Pixels',...
	'Position',...
	MS.OPos + [get(gcf,'CurrentPoint')-MS.OPt(1:2),0*MS.OPos(3:end)])


case 'graphicsmoveend'
%=======================================================================
% spm_figure('GraphicsMoveEnd')
MS = get(gco,'UserData');
hType = get(gco,'Type');
if any(strcmp(hType,{'image','line','patch','surface'}))
	set(get(gco,'Parent'),'Units',MS.chMUnits);
	set(gco,'UserData',MS.UserData);
else
	set(gco,'Units',MS.chMUnits,...
		'UserData',MS.UserData);
end

set(gcf,'Units',MS.cFUnits,...
	'WindowButtonMotionFcn','',...
	'WindowButtonUpFcn','',...
	'Pointer','Arrow')
set(MS.hMoveBut,'ForegroundColor','k')


case 'graphicssize'
%=======================================================================
% Change size of next object clicked, provided it's editable and in figure
% "normal" mouse button decreases size
% "extend" mouse button increases size
% "alt"    mouse button cancels operation
% spm_figure('GraphicsSize')

F     = gcbf;
hBut  = gcbo;
set(hBut,'ForegroundColor','r')
tmp   = get(F,'Name');
set(F,'Name',...
	'Resize: LeftMouse=shrink, MiddleMouse=grow, RightMouse=cancel...');
set(F,'Pointer','Circle')
waitforbuttonpress;
h        = gco(F);
hType    = get(h,'Type');
SelnType = get(gcf,'SelectionType');
u = 2*strcmp(SelnType,'extend')-1;
set(F,'Pointer','Arrow')
set(F,'Name',tmp)

if ~strcmp(get(h,'HandleVisibility'),'off') & ...
		~strcmp(SelnType,'alt') & ...
		~strcmp(hType,{'root','figure','uimenu','uicontrol'}) & ...
		gcf==F
	if any(strcmp(hType,{'image','line','patch','surface'}))
		h = get(h,'Parent'); hType = get(h,'Type'); end
	if strcmp(hType,'text')
		set(h,'Fontsize',(get(h,'FontSize')+2*u))
	elseif strcmp(hType,'axes')
		if u==1; u = 1.24; else, u = 1/1.24; end
		P = get(h,'Position');
		set(h,'Position',[P(1:2)-P(3:4)*(u-1)/2, P(3:4)*u])
	end
end
set(hBut,'ForegroundColor','k')



case 'graphicstext'
%=======================================================================
% Add text annotation to a figure
% spm_figure('GraphicsText')

F     = gcbf;
hBut  = gcbo;
set(hBut,'ForegroundColor','r')
tmp = get(F,'Name');
set(F,'Name',...
	'Select starting position, edit text widget. RightMouse=cancel..');
set(F,'Pointer','BotL')
waitforbuttonpress;
set(F,'Pointer','Arrow')
set(F,'Name',tmp)

if ~strcmp(get(gcf,'SelectionType'),'alt') & gcf==F
	cUnits = get(F,'Units');
	set(F,'Units','Normalized')
	CPt = get(F,'CurrentPoint');
	
	%-Set up axes for text widget
	axes('Position',[CPt, 0.1, 0.1],'Visible','off');
	
	%-Set uicontrol object and Callback
	set(F,'Units','Pixels')
	P = get(F,'Position');
	uicontrol(F,'Style','Edit',...
		'Position',[CPt(1:2).*P(3:4), (1-CPt(1))*P(3), 22],...
		'BackGroundColor',[0.8,0.8,1.0],...
		'HorizontalAlignment','Left',...
		'Callback','text(0,0,get(gcbo,''String'')); delete(gcbo)');
	set(F,'Units',cUnits)
end
set(hBut,'ForegroundColor','k')


case 'graphicstextedit'
%=======================================================================
% Edit text annotation to a figure
% spm_figure('GraphicsTextEdit')

F        = gcbf;
hBut     = gcbo;
set(hBut,'ForegroundColor','r')
tmp      = get(F,'Name');
set(F,'Name','Select text to edit. RightMouse=cancel..');
set(F,'Pointer','Circle')
waitforbuttonpress;
h        = gco(F);
set(F,'Pointer','Arrow')
set(F,'Name',tmp)

if strcmp(get(h,'HandleVisibility'),'off') | ...
		strcmp(get(gcf,'SelectionType'),'alt') | ...
		~strcmp(get(h,'Type'),'text') | ...
		gcf ~= F
	set(hBut,'ForegroundColor','k')
	return
end

%-Save units of various objects
cFUnits     = get(F,'Units');
cAUnits     = get(gca,'Units');
chUnits     = get(h,'Units');
chFontUnits = get(h,'FontUnits');

%-Get locations
set(F,'Units','Pixels')
set(gca,'Units','Pixels')
set(h,'Units','Pixels')
set(h,'FontUnits','Points')
tExtent = get(h,'Extent');
tmp = [1,1,0,0].*get(gca,'Position') ...
	+ [1,1,0,0].*tExtent...
	+ [0,0,1.2*max([0,0,1,1].*tExtent),ceil(22*get(h,'FontSize')/12)];

%-Create editable text widget to adjust text string
uicontrol(F,'Style','Edit',...
	'String',get(h,'String'),...
	'FontAngle',get(h,'FontAngle'),...
	'FontName',get(h,'FontName'),...
	'FontSize',get(h,'FontSize'),...
	'Position',tmp,...
	'BackGroundColor',[0.8,0.8,1.0],...
	'HorizontalAlignment',get(h,'HorizontalAlignment'),...
	'UserData',h,...
	'Callback',['set(get(gcbo,''UserData''),'...
		'''String'',get(gcbo,''String'')), delete(gcbo)']);

%-Reset stuff
set(hBut,'ForegroundColor','k')
set(F,'Units',cFUnits)
set(gca,'Units',cAUnits)
set(h,'Units',chUnits)
set(h,'FontUnits',chFontUnits)

otherwise
%=======================================================================
warning('Illegal Action string')


%=======================================================================
end
