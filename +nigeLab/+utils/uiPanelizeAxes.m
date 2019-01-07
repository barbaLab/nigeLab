function ax = uiPanelizeAxes(parent,nAxes,xOffset,yOffset,varargin)
%% UIPANELIZEAXES Returns axes cell array, with panelized axes objects
%
%  ax = UIPANELIZEAXES(parent,nAxes,xOffset,yOffset);
%
%  --------
%   INPUTS
%  --------
%   parent     :     Handle to container object to panelize (such as
%                    uipanel)
%
%    nAxes     :     Number of axes objects.
%
%    xOffset   :     Offset between elements within a row (and from edge).
%
%    yOffset   :     Offset between elements within a column (and from
%                    edge).
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%    ax        :     Cell array of axes object handles.
%
% By: Max Murphy  v1.0  03/22/2018  Original version (R2017b)

%% DEFAULTS
% For specified inputs
N_AXES = 9;
X_OFFSET = 0.025;
Y_OFFSET = 0.025;

% For varargin
FONTNAME = 'Arial';
FONTSIZE = 12;
NEXTPLOT = 'replacechildren';
COLOR = 'w';
XCOLOR = 'k';
YCOLOR = 'k';
XLIM = nan;
YLIM = nan;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if exist('nAxes','var')==0
   nAxes = N_AXES;
end

if exist('xOffset','var')==0
   xOffset = X_OFFSET;
end

if exist('yOffset','var')==0
   yOffset = Y_OFFSET;
end

%% GET NUMBER OF ROWS, COLUMNS, AND AXES WIDTH/HEIGHT
nRow = floor(sqrt(nAxes));
nCol = ceil(nAxes/nRow);

widthAx  = (1 - xOffset*(nCol + 1))/nCol;
heightAx = (1 - yOffset*(nRow + 1))/nRow;

widthPos = widthAx + xOffset;
heightPos = heightAx + yOffset;

%% INITIALIZE AXES ARRAY

ax = cell(nAxes,1);
for ii = 1:nAxes
   xpos = mod(ii-1,nCol)*widthPos + xOffset;
   ypos = 1 - ceil(ii/nRow)*heightPos;
   
   pos = [xpos ypos widthAx heightAx];
   ax{ii} = axes(parent,...
                 'Units','Normalized',...
                 'Position',pos,...
                 'FontName',FONTNAME,...
                 'FontSize',FONTSIZE,...
                 'NextPlot',NEXTPLOT,...
                 'Color',COLOR,...
                 'XColor',XCOLOR,...
                 'YColor',YCOLOR,...
                 'UserData',ii);
              
   if ~isnan(YLIM(1))
      ax{ii}.YLim = YLIM;
   end
   
   if ~isnan(XLIM(1))
      ax{ii}.XLim = XLIM;
   end
 
end

end