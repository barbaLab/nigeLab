function [gObj,X,Y,W,H,ax] = uiMakeLabels(parent,labels,varargin)
%UIMAKELABELS  Make labels at equally spaced increments along left of panel
%
%  gObj = UIMAKELABELS(parent,labels);
%  [gObj,X,Y,W,H] = UIMAKELABELS(parent,labels);
%  [__] = UIMAKELABELS(parent,labels,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%   parent     :     Uipanel object where the labels will go along the left
%                    side.
%
%    labels    :     Cell array of strings to use for the labels.
%
%   varargin   :     (Optional) 'NAME', value input argument pairs.
%
%                 -> 'LEFT' [def: 0.125] // Offset from left border
%                 (normalized from 0 to 1)
%
%                 -> 'RIGHT' [def: 0.525] // Offset from right border
%                 (normalized from 0 to 1)
%
%                 -> 'BOT' [def: 0.025] // Offset from bottom border
%                 (normalized from 0 to 1)
%
%                 -> 'TOP' [def: 0.025] // Offset from top border
%                 (normalized from 0 to 1)
%
%  --------
%   OUTPUT
%  --------
%   gObj       :     Label object array (uicontrol, style: 'label')
%
%  [X,Y,W,H]   :     Position elements for each `lab` member. 
%                    --> X,Y given as "Meshgrid" style coordinates of
%                       lower-left corner of object
%                    --> W,H given as scalars (width & height)
%
%   ax         :     Axes "container" of labels

% DEFAULTS
pars = struct;
pars.Top = 0.050; % Offset from TOP border ([0 1])
pars.Bot = 0.125; % Offset from BOTTOM border ([0 1])
pars.YLim = nan;
pars.Y = []; % (Meshgrid Matrix) y-coordinate (lower left corner) [overrides estimated positions]
pars.H = []; % (Scalar) width [overrides estimated height]
pars.Left = 0.0250; % Offset from LEFT border ([0 1])
pars.Right = 0.575; % Offset from RIGHT border ([0 1])
pars.XLim = nan;
pars.X = [];   % (Meshgrid Matrix) x-coordinate (lower left corner) [overrides estimated positions]
% pars.W = [];   % (Scalar) width [overrides estimated width]
pars.BackgroundColor = 'none'; % "Panel"
pars.EdgeColor = 'none';
pars.Color = nigeLab.defaults.nigelColors('onsurface'); % White
pars.FontName = 'Droid Sans';
pars.FontAngle = 'normal';
pars.FontWeight = 'bold';
pars.FontMultiplier = 0.175;  % For normalized font
pars.HorizontalAlignment = 'right';
pars.VerticalAlignment = 'middle';
pars.String = '';
pars.Tag = '';
pars.Mask = [];

% PARSE VARARGIN
if numel(varargin) == 1
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin = {};
   else
      error(['nigeLab:' mfilename ':BadSyntax'],...
         ['\n\t\t->\t<strong>[UIMAKELABELS]:</strong> ' ...
         'Optional inputs should be <''NAME'',value> pairs or '...
         'a scalar `pars` struct.\n']);
   end
else
   pars = nigeLab.utils.getopt(pars,1,varargin{:});
end

if isempty(pars.Mask)
   pars.Mask = ~cellfun(@isempty,labels);
end

% PARSE NUMBER OF ELEMENTS TO LAYOUT IN EACH DIRECTION
[nRow,nCol] = size(labels);

if isempty(pars.Tag)
   pars.Tag = labels;
elseif ~iscell(pars.Tag)
   pars.Tag = repmat({pars.Tag},nRow,nCol);
end

if isempty(pars.String)
   pars.String = labels;
elseif ~iscell(pars.String)
   pars.String = repmat({pars.String},nRow,nCol);
end

% GET POSITIONS
[X,Y,~,H] = nigeLab.utils.uiGetGrid(nRow,nCol,pars);
if ~isempty(pars.X)
   X = pars.X;
end
if ~isempty(pars.Y) 
   Y = pars.Y;
end
% if ~isempty(pars.W)
%    W = pars.W;
% end
if ~isempty(pars.H)
   H = pars.H;
end

% CONSTRUCT GRAPHICS ARRAY
gObj = gobjects(nRow,nCol);
if ~isa(parent,'matlab.graphics.axis.Axes')
   ax = axes(parent,'Color','none',...
      'XColor','none','YColor','none',...
      'XTick',[],'YTick',[],'NextPlot','add',...
      'XLim',[0 1],'YLim',[0 1],...
      'XLimMode','manual','YLimMode','manual',...
      'HitTest','off','PickableParts','none',...
      'Units','Normalized','Position',[0.025 0.025 0.95 0.95]);
   uistack(ax,'bottom');
else
   ax = parent;
end

for iRow = 1:nRow
   for iCol = 1:nCol
      if ~pars.Mask
         continue; % Then skip this element
      end
      gObj(iRow,iCol) = text(ax,X(iRow,iCol),Y(iRow,iCol),...
         pars.String{iRow,iCol},...
         'Units','data',...
         'Color',pars.Color,...
         'FontUnits','Normalized',...
         'FontSize',H * pars.FontMultiplier,...
         'FontName',pars.FontName,...
         'FontWeight',pars.FontWeight,...
         'FontAngle',pars.FontAngle,...
         'BackgroundColor',pars.BackgroundColor,...
         'EdgeColor',pars.EdgeColor,...
         'HorizontalAlignment',pars.HorizontalAlignment,...
         'VerticalAlignment',pars.VerticalAlignment,...
         'Tag',pars.Tag{iRow,iCol},...
         'UserData',struct('Row',iRow,'Column',iCol));
   end
end

e = vertcat(gObj.Extent);
W = max(e(:,3));
H = max(e(:,4));

end