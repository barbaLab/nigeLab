function gObj = uiMakeEditArray(container,nRow,nCol,varargin)
%UIMAKEEDITARRAY  Make array of edit boxes that corresponds to set of labels
%
%  editArray = nigeLab.utils.uiMakeEditArray(container,nRow,nCol);
%
%  editArray = nigeLab.utils.uiMakeEditArray(__,labels,_);
%  --> Specify `labels` instead of `(nRow,nCol)` to parse from label grid
%
%  editArray = nigeLab.utils.uiMakeEditArray(___,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  container   :     Graphics container object (uipanel) to hold the array.
%
%    nRow      :     Number of rows of uiEdit boxes in array
%
%    nCol      :     Number of columns of uiEdit boxes in array
%
%   varargin   :     (Optional) 'NAME', value input argument pairs that
%                             modify the uicontrol.
%
%                    -> 'X' [def: 0.500] // Normalized X (Position(1))
%
%                    -> 'W' [def: 0.475] // Normalized width (Position(3))
%
%                    -> 'H' [def: 0.150] // Normalized height (Position(4))
%
%                    -> 'TAG' [def: ''] // 'Tag' char array for each object
%
%                    -> 'MASK' [def: []] // Specify as matrix same size of
%                          `y`; any elements that are false get skipped and
%                          remain as "empty" gobjects in the array
%
%  --------
%   OUTPUT
%  --------
%    gObj      :     Array of graphics uicontrol objects (style: 'edit')
%
%  [X,Y,W,H]   :     Position elements for each `lab` member. 
%                    --> X,Y given as "Meshgrid" style coordinates of
%                       lower-left corner of object
%                    --> W,H given as scalars (width & height)

% DEFAULTS
pars = struct;
pars.Top = 0.125; % Offset from TOP border ([0 1])
pars.Bot = 0.125; % Offset from BOTTOM border ([0 1])
pars.Y = []; % (Meshgrid Matrix) y-coordinate (lower left corner) [overrides estimated positions]
pars.H = []; % (Scalar) width [overrides estimated height]
pars.Left = 0.5125; % Offset from LEFT border ([0 1])
pars.Right = 0.0250; % Offset from RIGHT border ([0 1])
pars.X = [];   % (Meshgrid Matrix) x-coordinate (lower left corner) [overrides estimated positions]
pars.W = [];   % (Scalar) width [overrides estimated width]
pars.BackgroundColor = nigeLab.defaults.nigelColors('onsurface'); % White
pars.ForegroundColor = nigeLab.defaults.nigelColors('enabletext'); % Black
pars.FontSize = 0.15; % Normalized font size ([0 1])
pars.FontName = 'Droid Sans';
pars.FontWeight = 'bold';
pars.FontAngle = 'normal';
pars.Enable = 'off';
pars.HorizontalAlignment = 'left';
pars.Tag = '';
pars.Mask = [];
pars.XLim = []; % Parsed from parent container object usually
pars.YLim = []; % Parsed from parent container object usually

% PARSE INPUT
if iscell(nRow)
   if nargin > 2
      varargin = [nCol, varargin];
   end
   % Assign to `'TAG'` parameter
   pars.Tag = nRow;
   % Parse # rows, columns from `Labels` matrix
   [nRow,nCol] = size(nRow);
end

% PARSE VARARGIN
if (numel(varargin) == 1)
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin = {};
   else
      error(['nigeLab:' mfilename ':BadNumInputs'],...
         ['\n\t\t->\t<strong>[UIMAKEEDITARRAY]:</strong> ' ...
         'Optional inputs should be <''NAME'',value> pairs or '...
         'a scalar `pars` struct.\n']);
   end
else
   pars = nigeLab.utils.getopt(pars,1,varargin{:});
end

% PARSE MASK AND TAG
if isempty(pars.Mask)
   if isempty(pars.Tag)
      pars.Mask = true(nRow,nCol);
   else
      pars.Mask = ~cellfun(@isempty,pars.Tag);
   end
end

if isempty(pars.Tag)
   pars.Tag = repmat({''},nRow,nCol);
end

% Parse "XLim" and "YLim" based on parent position
if isempty(pars.XLim)
   pars.XLim = [0 1];
end
if isempty(pars.YLim)
   pars.YLim = [0 1];
end
% Parse positions
[X,Y,W,H] = nigeLab.utils.uiGetGrid(nRow,nCol,pars);
if ~isempty(pars.X)
   X = pars.X;
end
if ~isempty(pars.Y) 
   Y = pars.Y;
end
if ~isempty(pars.W)
   W = pars.W;
end
if ~isempty(pars.H)
   H = pars.H;
end

% CONSTRUCT GRAPHICS ARRAY
gObj = gobjects(nRow,nCol);

for iRow = 1:nRow
   for iCol = 1:nCol
      if ~pars.Mask
         continue; % Then skip this element
      end
      gObj(iRow,iCol) = uicontrol(container,...
         'Style','edit',...
         'Units','Normalized',...
         'Position',[X(iRow,iCol),Y(iRow,iCol),W,H],...
         'FontUnits','Normalized',...
         'FontSize',pars.FontSize,...
         'FontName',pars.FontName,...
         'FontWeight',pars.FontWeight,...
         'FontAngle',pars.FontAngle,...
         'BackgroundColor',pars.BackgroundColor,...
         'ForegroundColor',pars.ForegroundColor,...
         'HorizontalAlignment',pars.HorizontalAlignment,...
         'Enable',pars.Enable,...
         'String','???',...
         'Tag',pars.Tag{iRow,iCol},...
         'UserData',struct('Row',iRow,'Column',iCol));
   end
end

end