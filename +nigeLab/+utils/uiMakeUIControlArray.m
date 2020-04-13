function [gObj,X,Y,W,H] = uiMakeUIControlArray(n,varargin)
%UIMAKEUICONTROLARRAY  Makes equally-spaced uiControl grid array
%
%  gObj = nigeLab.utils.uiMakeUIControlArray(n);
%  --> Creates n evenly-spaced uiControl elements in a column of gcf
%  --> Can specify n as 2-element array to set # rows and # columns.
%
%  gObj = nigeLab.utils.uiMakeUIControlArray(n,'NAME',value,...);
%  --> Creates n evenly-spaced uiControl elements with 'NAME',value props
%
%  gObj = nigeLab.utils.uiMakeUIControlArray(nRow,nCol);
%  --> Creates array grid with (nRow,nCol) elements in current figure
%
%  gObj = nigeLab.utils.uiMakeUIControlArray(parent,nRow,nCol);
%  --> Specify parent object
%
%  gObj = nigeLab.utils.uiMakeUIControlArray(__,'Name',value,...);
%  --> Specify sets of optional parameters using <'Name',value> syntax.
%     * See `pars` struct under `Defaults` comment
%     * Can also specify as `pars` struct using one argument instead of
%        argument pairs.
%
%  Example:
%  gObj = nigeLab.utils.uiMakeUIControlArray(...
%     gcf,3,2,...
%     'Callback',@(s,~)disp(s.UserData),...
%     'Mask',[true,true;true,false;true,true]);
%
%     * Create a pushbutton array where clicking on the bottom-left button
%        prints the following to the Command Window:
%     >>    
%           Row:  1
%        Column:  1
%     
%     * gObj is returned as a 3x2 UIControl array
%
%     * The element corresponding to gObj(2,2) is not created due to the
%        Mask being set to `false` for that element. (This is the right
%        button of the middle row).
%
%  --------
%   INPUTS
%  --------
%     n        :     # Elements in single column version of layout
%
%     nRow     :     # Rows in array layout.
%
%     nCol     :     # Columsn in array layout
%
%    parent    :     Figure or uipanel object to set as parent object.
%
%   varargin   :     (Optional) 'NAME', value input argument pairs.
%                    --> See options in pars struct of `DEFAULTS`
%                    --> Can be passed directly as single "pars" struct
%
%                    -- Key Parameters --
%                    * 'Style' : Default 'pushbutton' (uicontrol style)
%                    --> If 'pushbutton', 'Mask' skips any elements that do
%                    not have a 'Callback' specified (by default, none have
%                    callback)
%
%                    --> If 'text', 'Mask' skips any elements that do not
%                    have a 'String' specified
%
%                    --> Otherwise, 'Mask' doesn't automatically skip any;
%                    to override default 'Mask' behavior, specify 'Mask'
%                    manually
%
%  --------
%   OUTPUT
%  --------
%   gObj       :     uicontrol object array (style: pars.STYLE)
%
%  [X,Y,W,H]   :     Position elements for each `lab` member.
%                    --> X,Y given as "Meshgrid" style coordinates of
%                       lower-left corner of object
%                    --> W,H given as scalars (width & height)

% DEFAULTS
pars = struct;
pars.Style = 'pushbutton'; % Can be any of the `uicontrol` 'Style' options
pars.String = '';          % Use cell array to address string of
                           %  pars.STRING{i,j} to the <i,j> element of gObj
pars.Callback = [];        % Use cell array to address function handle to
                           %  gObj(i,j) == pars.CALLBACK{i,j}
pars.Top = 0.025; % Offset from TOP border ([0 1])
pars.Bot = 0.025; % Offset from BOTTOM border ([0 1])
pars.Y = []; % (Meshgrid Matrix) y-coordinate (lower left corner) [overrides estimated positions]
pars.H = []; % (Scalar) width [overrides estimated height]
pars.Left = 0.125;   % Offset from LEFT border ([0 1])
pars.Right = 0.525;  % Offset from RIGHT border ([0 1])
pars.X = [];   % (Meshgrid Matrix) x-coordinate (lower left corner) [overrides estimated positions]
pars.W = [];   % (Scalar) width [overrides estimated width]
pars.BackgroundColor = nigeLab.defaults.nigelColors('surface'); % "Panel"
pars.ForegroundColor = nigeLab.defaults.nigelColors('onsurface'); % White
pars.FontSize = 0.825; % Normalized font size ([0 1])
pars.FontName = 'Droid Sans';
pars.FontAngle = 'normal';
pars.FontWeight = 'normal';
pars.HorizontalAlignment = 'center';
pars.TooltipString = '';
pars.Value = [];
pars.BusyAction = 'queue';
pars.HandleVisibility = 'on';
pars.HitTest = 'on';
pars.Visible = 'on';
pars.Interruptible = 'on';
pars.Enable = 'on';
pars.Tag = '';  % From 'String' usually
pars.CData = [];
pars.Mask = []; % Depends on 'Style' for parsing
pars.UserData = []; % If left empty, assigns struct with 'Row', 'Column' fields
pars.XLim = []; % Parsed from parent container object usually
pars.YLim = []; % Parsed from parent container object usually

% Parse inputs
if nargin > 1
   [parent,dims,varargin] = parseParent(n,varargin{:});
   nRow = dims(1);
   nCol = dims(2);
   if nargin > 2
      if isnumeric(varargin{1})
         nCol = varargin{1};
         varargin(1) = [];
      end
   end
else
   [parent,dims] = parseParent(n,{'N/A'});
   nRow = dims(1);
   nCol = dims(2);
end

% Parse varargin
if numel(varargin) == 1
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin = {};
   else
      error(['nigeLab:' mfilename ':BadSyntax'],...
         ['\n\t\t->\t<strong>[UIMAKEUICONTROLARRAY]:</strong> ' ...
         'Optional inputs should be <''NAME'',value> pairs or '...
         'a scalar `pars` struct.\n']);
   end
else
   pars = nigeLab.utils.getopt(pars,1,varargin{:});
end

pars = parseFieldsForNonCell(pars,{'Callback','String'},nRow,nCol);

fieldsToCheck = {'Style','FontName','FontSize','FontWeight','FontAngle',...
   'HorizontalAlignment','BackgroundColor','ForegroundColor',...
   'Tag','UserData','Callback','HandleVisibility',...
   'BusyAction','Interruptible','HitTest','TooltipString',...
   'Enable','Visible','CData','Value'};
pars = parseFieldsForNonCell(pars,fieldsToCheck,nRow,nCol);

if isempty(pars.Mask)
   pars.Mask = false(nRow,nCol);
   for iRow = 1:nRow
      for iCol = 1:nCol
         switch pars.Style{iRow,iCol}
            case 'pushbutton'
               pars.Mask(iRow,iCol) = ~isempty(pars.Callback{iRow,iCol});
            case 'text'
               pars.Mask(iRow,iCol) = ~isempty(pars.String{iRow,iCol});
            otherwise
               pars.Mask(iRow,iCol) = true;
         end
      end
   end
end


% Parse "XLim" and "YLim" based on parent position
if isempty(pars.XLim)
   pars.XLim = [0 1];
end
if isempty(pars.YLim)
   pars.YLim = [0 1];
end

% GET POSITIONS
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

% CREATE UICONTROL OBJECTS
gObj = gobjects(nRow,nCol);
for iRow = 1:nRow
   for iCol = 1:nCol
      if ~pars.Mask(iRow,iCol)
         continue;
      end
      if isempty(pars.UserData{iRow,iCol})
         u = struct('Row',iRow,'Column',iCol);
      end
      gObj(iRow,iCol) = uicontrol(parent,...
         'Style',pars.Style{iRow,iCol},...
         'Units','Normalized',...
         'Position',[X(iRow,iCol),Y(iRow,iCol),W,H],...
         'FontName',pars.FontName{iRow,iCol},...
         'FontUnits','Normalized',...
         'FontSize',pars.FontSize{iRow,iCol},...
         'FontWeight',pars.FontWeight{iRow,iCol},...
         'FontAngle',pars.FontAngle{iRow,iCol},...
         'Enable',pars.Enable{iRow,iCol},...
         'HitTest',pars.HitTest{iRow,iCol},...
         'BusyAction',pars.BusyAction{iRow,iCol},...
         'Interruptible',pars.Interruptible{iRow,iCol},...
         'HandleVisibility',pars.HandleVisibility{iRow,iCol},...
         'TooltipString',pars.TooltipString{iRow,iCol},...
         'Visible',pars.Visible{iRow,iCol},...
         'HorizontalAlignment',pars.HorizontalAlignment{iRow,iCol},...
         'BackgroundColor',pars.BackgroundColor{iRow,iCol},...
         'ForegroundColor',pars.ForegroundColor{iRow,iCol},...
         'String',pars.String{iRow,iCol},...
         'Tag',pars.Tag{iRow,iCol},...
         'UserData',u,...
         'Callback',pars.Callback{iRow,iCol});

      if ~isempty(pars.CData{iRow,iCol})
         gObj(iRow,iCol).CData = pars.CData{iRow,iCol};
      end
      if ~isempty(pars.Value{iRow,iCol})
         gObj(iRow,iCol).Value = pars.Value{iRow,iCol};
      end

   end
end

   function [parent,dims,varargin] = parseParent(n,varargin)
      %PARSEPARENT  Parses parent & # rows based on first input arg (`n`)
      %
      %  [parent,dims,varargin] = parseParent(n,varargin);
      %
      %  --> Returns 'parent' graphics object
      %  --> Returns # rows in grid layout
      %  --> Updates `varargin`, dropping its first element if varargin is
      %      used to figure out # rows.
      
      switch class(n)
         case 'matlab.ui.Figure'
            parent = n;
            if isnumeric(varargin{1})
               dims = varargin{1};
               varargin(1)=[];
            end
         case 'matlab.ui.container.Panel'
            parent = n;
            if isnumeric(varargin{1})
               dims = varargin{1};
               varargin(1)=[];
            end
         case 'nigeLab.libs.nigelPanel'
            parent = n.Panel;
            if isnumeric(varargin{1})
               dims = varargin{1};
               varargin(1)=[];               
            end
         otherwise
            if ~isnumeric(n)
               error(['nigeLab:' mfilename ':BadClass'],...
                  ['\n\t\t->\t<strong>[UIMAKECONTROLARRAY]:</strong> ' ...
                  'Unexpected class: >2 inputs and first is %s\n'],...
                  class(n));
            end
            parent = gcf;
            dims = n;
            if isscalar(dims) && isnumeric(varargin{1})
               dims = [dims, varargin{1}];
               varargin(1) = [];
            elseif isnumeric(varargin{1})
               varargin(1) = [];
            end
      end
      if isscalar(dims)
         dims = [dims, 1];
      end
   end

   % [HELPER]: Parse fields that may be non-cell and convert them
   function pars = parseFieldsForNonCell(pars,fieldsToCheck,nRow,nCol)
      %PARSEFIELDSFORNONCELL  Converts any non-cell of `fieldToCheck` 
      %
      %  pars = parseFieldsForNonCell(pars,fieldsToCheck);
      
      for iF = 1:numel(fieldsToCheck)
         f = fieldsToCheck{iF};
         if ~iscell(pars.(f))
            pars.(f) = repmat({pars.(f)},nRow,nCol);
         end
      end
   end

end