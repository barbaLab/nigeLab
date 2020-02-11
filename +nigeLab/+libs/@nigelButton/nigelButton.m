classdef nigelButton < handle & matlab.mixin.SetGet 
   %NIGELBUTTON   Buttons in format of nigeLab interface
   %
   %  NIGELBUTTON Properties:
   %     ButtonDownFcn - Function executed by button.
   %        This can be set publically and will change the button down
   %        function for any child objects associated with the nigelButton
   %
   %     Parent - Handle to parent axes object.
   %
   %     Button - Handle to Rectangle object with curved corners.
   %
   %     Label - Handle to Text object displaying some label string.
   %
   %  NIGELBUTTON Methods:
   %     nigelButton - Class constructor.
   %           b = nigeLab.libs.nigelButton(); Add to current axes
   %           b = nigeLab.libs.nigelButton(nigelPanelObj); Add to nigelPanel
   %           b = nigeLab.libs.nigelButton(ax);  Add to axes
   %           b = nigeLab.libs.nigelButton(__,buttonPropPairs,labPropPairs);
   %           b = nigeLab.libs.nigelButton(__,pos,string,buttonDownFcn);
   %
   %           container can be:
   %           -> nigeLab.libs.nigelPanel
   %           -> axes
   %           -> uipanel
   %
   %           buttonPropPairs & labPropPairs are {'propName', value}
   %           argument pairs, each given as a [1 x 2*k] cell arrays of pairs
   %           for k properties to set.
   %
   %           Alternatively, buttonPropPairs can be given as the position of
   %           the button rectangle, and labPropPairs can be given as the
   %           string to go into the button. In this case, the fourth input
   %           (fcn) should be provided as a function handle for ButtonDownFcn
   
   % % % PROPERTIES % % % % % % % % % %
   % PUBLIC
   properties (Access=public)
      DefaultColor      % Default border color
      HoveredColor      % Color for border change on "rollover" mouse hover
      HoveredFontColor  % Color for font change on "rollover" mouse hover
      SelectedColor     % Color for border change on "selected" highlight
      UserData          % Public property to store User Data
   end
   
   % ABORTSET,DEPENDENT,PUBLIC
   properties (Hidden=false,Dependent,Access=public)
      Enable            char = 'on'             % Is the button enabled?
      Hovered           char = 'off'            % Flags Button as "hovered"
      Selected          char = 'off'            % Flags Button as "selected"
      Visible           char = 'on'             % 'Button' visibility
   end
   
   % DEPENDENT,PUBLIC
   properties (Dependent,Access=public)
      ButtonDownFcn                                % Function handle
      Curvature      (1,2) double = [0.2 0.6]      % [X- Y-] curvature
      FaceColor                                    % 'Button' face color
      EdgeColor                                    % 'Button' edge color
      FontColor                                    % 'Label' Font color
      FontName             char = 'DroidSans'      % 'Label' font name
      FontSize       (1,1) double = 0.35           % 'Label' font size
      FontUnits            char = 'normalized'     % 'Label' font units
      FontWeight           char = 'normal'         % 'Label' font weight
      HorizontalAlignment  char = 'center'         % 'Label' horizontal align
      IconDisplayStyle     char = 'off'            % If 'off' does not show in legends
      LineWidth      (1,1) double = 1.25           % 'Button' edge width
      PixelPosition  (1,4) double                  % Read-only Pixel position
      Position       (1,4) double = [0 0 1 1]      % 'Button' position
      String               char                    % String displayed on b.Label
      Tag                  char                    % Same as String
      VerticalAlignment    char = 'middle'         % 'Label' vertical align
      WindowButtonUpFcn    cell                    % Reformatted version of Fcn_ and Fcn_Args_ properties
   end
   
   % CONSTANT,PUBLIC
   properties (Constant,Access=public)
      MinimumPixelHeight   double = 35             % Minimum height (in pixels) for 'Label'
      Type                 char = 'nigelbutton'    % Type of graphics object
      Units                char = 'data'           % 'Label' position units
   end
   
   % SETOBSERVABLE,PUBLIC
   properties (SetObservable,Access=public)
      FaceColorEnable     % b.Button.FaceColor
      FaceColorDisable    % Color for face when button disabled
      FontColorEnable     % b.Label.Color
      FontColorDisable    % Color for string on button when disabled
   end
   
   % HIDDEN,SETOBSERVABLE,TRANSIENT,PUBLIC/PROTECTED
   properties (Hidden,SetObservable,Transient,GetAccess=public,SetAccess=protected)
      Border  matlab.graphics.primitive.Rectangle  % Border of "button"
      Button  matlab.graphics.primitive.Rectangle  % Curved rectangle
      Label   matlab.graphics.primitive.Text       % Text to display
   end
   
   % TRANSIENT,PUBLIC/IMMUTABLE
   properties (Transient,GetAccess=public,SetAccess=immutable)
      Figure  matlab.ui.Figure           % Figure containing the object
      Group   matlab.graphics.primitive.Group  % "Container" object
      Parent  matlab.graphics.axis.Axes  % Axes container
   end
   
   % PROTECTED
   properties (Access=protected)
      Enable_     char = 'on'     % Store for .Enable Dependent prop
      Fcn_                        % Executed on WindowButtonUpFcn
      Fcn_Args_   cell            % (Optional) args for nigelButton.Fcn
      Hovered_    char = 'off'    % Does this button have mouse over it?
      Selected_   char = 'off'    % Is this button currently clicked
      Visible_    char = 'on'     % Is it Visible?
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded methods)
   methods
      % Overloaded methods
      % Set properties for an array
      function set(b,varargin)
         if numel(b) > 1
            for i = 1:numel(b)
               set(b(i),varargin{:});
            end
            return;
         end
         propNamesAll = properties(b);
         for iV = 1:2:numel(varargin)
            idx = strcmpi(propNamesAll,varargin{iV});
            if sum(idx)==1
               b.(propNamesAll{idx}) = varargin{iV+1};
            end
         end
      end
      
      % Delete associated graphics objects
      function delete(b)
         %DELETE  Delete associated graphics objects
         %
         %  delete(b);
         %  --> Called if any of the Graphics (Button, Border, or Label)
         %      are destroyed
         
         % Handle array elements individually
         if numel(b) > 1
            for i = 1:numel(b)
               if isvalid(b(i))
                  delete(b(i));
               end
            end
            return;
         end
         
         % Delete the Group to delete the rest of the objects
         if ~isempty(b.Group)
            if isvalid(b.Group)
               delete(b.Group);
            end
         end
      end
      
      % [DEPENDENT] property get/set methods
      function value = get.ButtonDownFcn(b)
         value = [{b.Fcn_}, b.Fcn_Args_];
      end
      function set.ButtonDownFcn(b,value)
         if isempty(value)
            b.Fcn_ = @(txt)disp(txt);
            b.Fcn_Args_ = {b};
            return;
         end         
         if iscell(value)
            if numel(value) == 1
               b.Fcn_ = value{:};
               b.Fcn_Args_ = cell(1,0);
            else
               b.Fcn_ = value{1};
               value(1) = [];
               b.Fcn_Args_ = value;
            end
         else
            b.Fcn_ = value;
            b.Fcn_Args_ = cell(1,0);
         end
      end
      
      function value = get.Curvature(b)
         value = b.Button.Curvature;
      end
      function set.Curvature(b,value)
         b.Button.Curvature = value;
         b.Border.Curvature = value;
      end
      
      function set.DefaultColor(b,value)
         c = nigeLab.libs.nigelButton.parseColor(value); 
         b.DefaultColor = c;
      end      
      
      function value = get.EdgeColor(b)
         value = b.Border.EdgeColor;
      end
      function set.EdgeColor(b,value)
         c = nigeLab.libs.nigelButton.parseColor(value);    
         b.Border.EdgeColor = c;
         b.DefaultColor = c;
      end
      
      function value = get.Enable(b)
         value = b.Enable_;
      end
      function set.Enable(b,value)
         switch value
            case 'on'
               b.FaceColor = b.FaceColorEnable;
               b.FontColor = b.FontColorEnable;
            case 'off'
               b.FaceColor = b.FaceColorDisable;
               b.FontColor = b.FontColorDisable;
         end
         b.Enable_ = value;
         drawnow;
      end
      
      function value = get.FaceColor(b)
         if strcmp(b.Enable,'on')
            value = b.FaceColorEnable;
         else
            value = b.FaceColorDisable;
         end
      end
      function set.FaceColor(b,value)
         c = nigeLab.libs.nigelButton.parseColor(value);               
         b.Button.FaceColor = c;
         if strcmp(b.Enable,'on')
            b.FaceColorEnable = c;
         else
            b.FaceColorDisable = c;
         end
      end
      
      function value = get.FontColor(b)
         if strcmp(b.Enable,'on')
            value = b.FontColorEnable;
         else
            value = b.FontColorDisable;
         end
      end
      function set.FontColor(b,value)
         c = nigeLab.libs.nigelButton.parseColor(value);    
         b.Label.Color = c;
         if strcmp(b.Enable,'on')
            b.FontColorEnable = c;
         else
            b.FontColorDisable = c;
         end
      end
      
      function value = get.FontName(b)
         value = b.Label.FontName;
      end
      function set.FontName(b,value)
         b.Label.FontName = value;
      end
      
      function value = get.FontWeight(b)
         value = b.Label.FontWeight;
      end
      function set.FontWeight(b,value)
         b.Label.FontWeight = value;
      end
      
      function value = get.FontSize(b)
         if strcmp(b.FontUnits,'normalized')
            scl = b.Button.Position(4) / diff(b.Parent.XLim);
            value = b.Label.FontSize / scl;
         else
            value = b.Label.FontSize;
         end
      end
      function set.FontSize(b,value)
         if strcmp(b.FontUnits,'normalized')
            b.Label.FontSize = fixLabelSize(obj,value);
         else
            b.Label.FontSize = value;
         end
      end
      
      function value = get.FontUnits(b)
         value = b.Label.FontUnits;
      end
      function set.FontUnits(b,value)
         b.Label.FontUnits = value;
      end
      
      function value = get.HorizontalAlignment(b)
         value = b.Label.HorizontalAlignment;
      end
      function set.HorizontalAlignment(b,value)
         b.Label.HorizontalAlignment = value;
      end
      
      function value = get.Hovered(b)
         value = b.Hovered_;
      end
      function set.Hovered(b,value)
         if strcmp(b.Selected,'on') || strcmp(b.Enable,'off')
            b.Hovered_ = 'off';
            return;
         end
         
         switch value
            case 'on'
               b.Border.EdgeColor = b.HoveredColor;
               set(b.Label,...
                  'Color',b.HoveredFontColor,...
                  'FontWeight','normal');
            case 'off'
               b.Border.EdgeColor = b.DefaultColor;
               b.Label.Color = b.FontColor;
         end
         b.Hovered_ = value;
         drawnow;
      end
      
      function set.HoveredColor(b,value)
         c = nigeLab.libs.nigelButton.parseColor(value);    
         b.HoveredColor = c;
      end
      
      function set.HoveredFontColor(b,value)
         c = nigeLab.libs.nigelButton.parseColor(value);    
         b.HoveredFontColor = c;
      end
      
      function value = get.IconDisplayStyle(b)
         value = b.Group.Annotation.LegendInformation.IconDisplayStyle;
      end
      function set.IconDisplayStyle(b,value)
         b.Group.Annotation.LegendInformation.IconDisplayStyle = value;
      end
      
      function value = get.LineWidth(b)
         value = b.Border.LineWidth;
      end
      function set.LineWidth(b,value)
         b.Button.LineWidth = value;
         b.Border.LineWidth = value;
      end
      
      function value = get.PixelPosition(b)
         value = getpixelposition(b.Parent);
      end
      function set.PixelPosition(~,~)
         % Does nothing
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[NIGELBUTTON]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set READ-ONLY property: PixelPosition\n');
         fprintf(1,'\n');
      end
      
      function value = get.Position(b)
         value = b.Button.Position;
      end
      function set.Position(b,value)
         b.Button.Position = value;
         b.Border.Position = value;
         b.Label.Position = b.getCenter(value);
      end
      
      function value = get.Selected(b)
         value = b.Selected_;
      end
      function set.Selected(b,value)
         switch value
            case 'on'
               b.Border.EdgeColor = b.SelectedColor;
               b.Label.FontWeight = 'bold';
               set(b.Figure,'WindowButtonUpFcn',@(obj,~,~)ButtonUpFcn(b));
            case 'off'
               if strcmp(b.Hovered,'on')
                  b.Border.EdgeColor = b.HoveredColor;
                  b.Label.Color = b.HoveredFontColor;
               else
                  b.Border.EdgeColor = b.DefaultColor;
                  b.Label.Color = b.FontColor;
               end
               b.Label.FontWeight = 'normal';
         end
         b.Selected_ = value;
         drawnow;
      end
      
      function set.SelectedColor(b,value)
         c = nigeLab.libs.nigelButton.parseColor(value); 
         b.SelectedColor = c;
      end
      
      function value = get.String(b)
         value = b.Label.String;
      end
      function set.String(b,value)
         b.Label.String = value;
      end
      
      function value = get.Tag(b)
         value = b.String;
      end
      function set.Tag(b,value)
         b.String = value;
      end
      
      function value = get.VerticalAlignment(b)
         value = b.Label.VerticalAlignment;
      end
      function set.VerticalAlignment(b,value)
         b.Label.VerticalAlignment = value;
      end
      
      function value = get.Visible(b)
         value = b.Visible_;
      end
      function set.Visible(b,value)
         if ~ischar(value)
            return;
         else
            value = lower(value);
         end
         if ismember(value,{'on','off'})
            b.Label.Visible = value;
            b.Button.Visible = value;
            b.Border.Visible = value;
         end
      end
      
      function value = get.WindowButtonUpFcn(b)
         value = b.ButtonDownFcn;
      end
      function set.WindowButtonUpFcn(~,~)
         % Does nothing
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[NIGELBUTTON]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set READ-ONLY property: WindowButtonUpFcn\n');
         fprintf(1,'\n');
      end
   end
   
   % PUBLIC
   methods (Access = public)
      % Class constructor
      function b = nigelButton(container,pos,string,fcn,varargin)
         %NIGELBUTTON   Buttons in format of nigeLab interface
         %
         %  b = nigeLab.libs.nigelButton();
         %     -> This forces `container` to be the current `axes` (gca)
         %
         %  b = nigeLab.libs.nigelButton(container);
         %     -> container can be:
         %        * nigeLab.libs.nigelPanel
         %        * axes
         %        * uipanel
         %
         %  b = nigeLab.libs.nigelButton(__,buttonPropPairs,labPropPairs);
         %     ## Example ##
         %     ```
         %     b = nigeLab.libs.nigelButton(ax,...
         %         {'Position',[0 0 1 1]},{'String','test'});
         %        -> This is the same as calling
         %     b = nigeLab.libs.nigelButton(ax,[0 0 1 1],'test');
         %     ```
         %
         %  Note that if no `fcn` arg is provided, the default interaction
         %  when the button is clicked is to call
         %
         %     >> disp(b); % Where b is the button object
         %
         %  b = nigeLab.libs.nigelButton(__,pos,string,@ButtonUpFcn);
         %     -> Include "@ButtonUpFcn" a handle to a function that is
         %        executed when the `nigeLab.libs.nigelButton` object is
         %        released after being clicked.
         %
         %  b = nigeLab.libs.nigelButton(__,{@ButtonUpFcn,arg1,...,argk});
         %     -> Include additional arguments as cell array
         %
         %  b = nigeLab.libs.nigelButton(ax,__,[],'prop1',val1,...);
         %     -> Specify function handle as empty to skip to
         %        <'Name',value> input argument pairs.
         %
         %  b = nigeLab.libs.nigelButton(__,@ButtonUpFcn,'prop1',val1,...);
         %     -> Can still specify the function handle with this syntax.
         %
         %  b = nigeLab.libs.nigelButton(__,{@Fcn,arg1},'prop1',val1,...);
         %     -> Can still include arguments
         %
         %  Alternatively, `pos` and `string` can be given as
         %  {'propName', value} argument pairs. This syntax requires each
         %  to be given as a [1 x 2*k] cell arrays of pairs for k
         %  properties to set. In this case, `pos` pairs are for the
         %  rectangle part of the button and `string` pairs are for the
         %  text part of the button.
         %
         %  ## Example 1 ## (Syntax not recommended)
         %  ```
         %  fig = figure; % Test 1
         %  p = nigeLab.libs.nigelPanel(fig);
         %  b = nigeLab.libs.nigelButton(p,...
         %      {'FaceColor',[1 0 0],...
         %       'ButtonDownFcn',{{@(src)disp(class(src)),p}}},...
         %      {'String','test'});
         %  ```
         %  * Creates a button in an axes of panel `p`
         %  * Button has label 'test'
         %  * Button displays 'nigelPanel (nigelPanel)' in Command Window
         %
         %  ## Example 2 ## (<strong>Recommended syntax</strong>)
         %  ```
         %  fig = figure; % Test 2
         %  ax = axes(fig,'XLim',[-2 2],'YLim',[-2 2],'NextPlot','add');
         %  bPos = [-0.5 -0.5 1 1];
         %  b = nigeLab.libs.nigelButton(ax,bPos,'test2',...
         %     {@disp,'hi'},...
         %     'HoveredColor','hl','SelectedColor','blue',...
         %     'FaceColor','tertiary','EdgeColor','ontertiary',...
         %     'LineWidth',2.5,'Color','ontertiary',...
         %     'Curvature',[1 1],'FontSize',0.35);
         %  ro = nigeLab.utils.Mouse.rollover(fig,b);
         %  ```
         %  * Creates an orange button at the origin of axes `ax`
         %  * Adding the rollover object allows the green highlight to show
         %     up on mouse-over
         %  * Clicking the button displays 'hi' in the command window,
         %     causes the font to become bold while clicked, and changes
         %     the edge color to blue temporarily.
         
         if nargin < 4
            fcn = [];
         end
         
         if nargin < 3
            string = {};
         end
         
         if nargin < 2
            pos = {};
         end
         
         if nargin < 1
            b = nigeLab.libs.nigelButton.empty();
            return;
         else
            if isnumeric(container)
               n = container;
               if numel(n) < 2
                  n = [zeros(1,2-numel(n)),n];
               else
                  n = [0, max(n)];
               end
               b = repmat(b,n);
               return;
            end
         end
         
         % Set immutable properties in constructor
         b.Parent = nigeLab.libs.nigelButton.parseContainer(container);
         k = numel(b.Parent.Children);
         b.Group = hggroup(b.Parent);
         b.Figure = parseFigure(b);
         
         % Initialize rest of graphics
         initColors(b);
         [pos,string,varargin]=b.parseSpecificArgPairs(pos,string,varargin);
         buildGraphic(b,pos,'Button');
         buildGraphic(b,string,'Label');
         completeGroup(b);
         
         % Set Function handle and input arguments
         b.ButtonDownFcn = fcn;
         
         % Parse varargin
         mc = metaclass(b);
         propNameList = {mc.PropertyList.Name};
         for iV = 1:2:numel(varargin)
            idx = strcmpi(propNameList,varargin{iV});
            if sum(idx)==1
               b.(propNameList{idx}) = varargin{iV+1};
            end
         end
      end
      
      % Return the correct button from an array
      function b = getButton(bArray,name)
         % GETBUTTON  Return the correct button from an array by specifying
         %            its name, which is the char array on the text label
         %
         %  b = getButton(bArray,'labelString');  Returns the button with
         %                                        'labelString' on it, or
         %                                        else returns empty array
         
         idx = ismember(lower(get([bArray.Label],'String')),lower(name));
         b = bArray(idx);
      end
      
      % Return the correct button from an array
      function setButton(bArray,name,propName,propval)
         % GETBUTTON  Return the correct button from an array by specifying
         %            its name, which is the char array on the text label
         %
         %  setButton(bArray,'labelString','propName',propVal);
         %
         %  Set the value of the button in array with label 'labelString'
         %  for 'propName' to propVal.
         %
         %  setButton(bArray,[],...); Sets all elements of bArray
         %
         %  setButton(bArray,logical(ones(size(bArray)))); Can use logical
         %           or numeric indexing
         
         if ischar(name)
            idx = ismember(lower(get([bArray.Label],'String')),lower(name));
         elseif isnumeric(name)
            if ~isempty(name)
               idx = name;
            else
               idx = 1:numel(bArray);
            end
         elseif islogical(name)
            idx = name;
         else
            error(['nigeLab:' mfilename ':badInputType2'],...
               'Unexpected input class for "name" (%s)',class(name));
         end
         
         B = bArray(idx);
         for i = 1:numel(B)
            B.(propName) = propval;
         end
      end
   end
   
   % HIDDEN,PROTECTED
   methods (Hidden,Access=protected)
      % Button click graphic
      function ButtonClickGraphic(b)
         % BUTTONCLICKGRAPHIC  Crude method to show the highlight border of
         %                       button that was clicked.
         
         if numel(b) > 1
            for i = 1:numel(b)
               ButtonClickGraphic(b(i));
            end
            return;
         end
         
         if strcmpi(b.Enable,'off')
            return;
         end
         
         b.Selected = 'on';
         drawnow;
      end
      
      % Button click graphic
      function ButtonUpFcn(b)
         % BUTTONUPFCN  Crude method to show the highlight border of
         %                       button that was clicked on a left-click,
         %                       and then execute current button callback.
         
         if numel(b) > 1
            for i = 1:numel(b)
               ButtonUpFcn(b(i));
            end
            return;
         end
         
         if strcmpi(b.Selected,'off')
            return;
         elseif strcmpi(b.Enable,'off')
            return;
         end
         % If button is released, turn off "highlight border"
         b.Selected = 'off';
         drawnow;
         switch lower(b.Figure.SelectionType)
            case 'normal'
               if ~isempty(b.Fcn_)
                  b.Fcn_(b.Fcn_Args_{:});
               end
            otherwise
               ... % nothing
         end
      end
      
      % Initialize a given graphic property object
      function buildGraphic(b,propPairsIn,propName)
         % BUILDGRAPHIC  Builds the specified graphic
         %
         %  b.buildGraphic(propPairsIn,'propName');
         %
         %  Builds the graphic property specified by 'propName' using the
         %  optional input property pairs list.
         
         % Check input
         if ~isprop(b,propName)
            error(['nigeLab:' mfilename ':badInputType3'],...
               'Invalid property name: %s',propName);
         end
         
         switch propName
            case 'Button'
               % Do not make additional button graphics
               if ~isempty(b.Button)
                  if isvalid(b.Button)
                     return;
                  end
               end
               
               b.Button = rectangle(b.Group,...
                  'Position',[0.15 0.10 0.70 0.275],...
                  'Curvature',[.2 .6],...
                  'FaceColor',b.FaceColorEnable,...
                  'EdgeColor','none',...
                  'LineWidth',1.5,...
                  'Tag','Button',...
                  'Visible','on',...
                  'ButtonDownFcn',@(~,~)b.ButtonClickGraphic,...
                  'DeleteFcn',@(~,~)b.delete);
               b.Border = rectangle(b.Group,...
                  'Position',[0.15 0.10 0.70 0.275],...
                  'Curvature',[.2 .6],...
                  'FaceColor','none',...
                  'EdgeColor',b.DefaultColor,...
                  'LineWidth',1.5,...
                  'Visible','on',...
                  'Tag','Border',...
                  'PickableParts','none',...
                  'DeleteFcn',@(~,~)b.delete);
               
            case 'Label'
               % Do not make additional label graphics
               if ~isempty(b.Label)
                  if isvalid(b.Label)
                     return;
                  end
               end
               
               % By default put it in the middle of the button
               pos = b.getCenter(b.Button.Position);
               sz_ = fixLabelSize(b,0.35);
               b.Label = text(b.Group,pos(1),pos(2),'',...
                  'Color',b.FontColorEnable,...
                  'FontName','Droid Sans',...
                  'Units','data',...
                  'FontUnits','normalized',...
                  'FontSize',sz_,...
                  'Tag','Label',...
                  'HorizontalAlignment','center',...
                  'VerticalAlignment','middle',...
                  'PickableParts','none',...
                  'DeleteFcn',@(~,~)b.delete);
               
            otherwise
               error(['nigeLab:' mfilename ':badInputType4'],...
                  'Unexpected graphics property name: %s',propName);
         end
         
         % If no property pairs specified, skip next part
         if isempty(propPairsIn)
            return;
         end
         
         switch class(propPairsIn)
            case 'cell'
               % Cycle through all valid name-value pairs and add them
               ob = metaclass(b.(propName));
               allPropList = {ob.PropertyList.Name};
               allPropList = allPropList(~[ob.PropertyList.Hidden]);
               
               % Don't allow the following properties to be set in
               % constructor:
               allPropList = setdiff(allPropList,...
                  {'ButtonDownFcn',...
                  'DeleteFcn',...
                  'EdgeColor',...
                  'FaceColor',...
                  'HitTest',...
                  'HorizontalAlignment',...
                  'PickableParts',...
                  'UserData',...
                  'VerticalAlignment'});
               for i = 1:2:numel(propPairsIn)
                  % Do it this way to allow mismatch on case syntax
                  idx = find(...
                     ismember(lower(allPropList),lower(propPairsIn{i})),...
                     1,'first');
                  if ~isempty(idx)
                     b.(propName).(allPropList{idx}) = propPairsIn{i+1};
                  end
               end
               
            case 'double'
               % If this was associated with the wrong set of pairs, redo
               % the button.
               if strcmp(propName,'Label')
                  error(['nigeLab:' mfilename ':badInputType3'],...
                     'Check order of position and label text inputs.');
               end
               
               % Can set position directly
               b.Button.Position = propPairsIn;
            case 'char'
               % If this was associated with the wrong set of pairs, redo
               % the label
               if strcmp(propName,'Button')
                  error(['nigeLab:' mfilename ':badInputType3'],...
                     'Check order of position and label text inputs.');
               end
               
               % Can set label text directly
               b.Label.String = propPairsIn;
               
            otherwise
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Bad input type for %s propPairs: %s',...
                  propName,class(propPairsIn));
         end
         
      end
      
      % Complete the 'Group' hggroup property
      function completeGroup(b)
         % COMPLETEGROUP  Complete the 'Group' hggroup property
         %
         %  lh = b.completeGroup();
         %
         %  fcn  --  Function handle
         
         b.Group.Tag = b.Label.String;
         b.Group.DisplayName = b.Label.String;
         
         % Make it not show up in legends:
         b.Group.Annotation.LegendInformation.IconDisplayStyle = 'off';
         
         % Make sure it deletes "parent" button when destroyed
         b.Group.DeleteFcn = @(~,~)b.delete;
         
         % Make sure things are in same "spot"
         b.Position = b.Button.Position;
         b.LineWidth = b.Border.LineWidth;
         
         % Assign object to button UserData
         b.Button.UserData = b;
         
         % Match Hovered Font Color to standard Font Color
         b.HoveredFontColor = b.FontColor;
      end
      
      % "Fixes" the label size to a minimum pixel dimension
      function sz = fixLabelSize(b,normDim)
         %FIXLABELSIZE  "Fixes" label size based on minimum pixel dim
         %
         %  sz = fixLabelSize(b,normDim);
         %
         %  b:       nigeLab.libs.nigelButton object
         %  normDim: normalized (scalar) dimension (e.g. 0.5)
         
         pct = b.Button.Position(4) / diff(b.Parent.XLim);
         
         pos = b.PixelPosition; % Pixel dims of axes container
         hButton = pos(3) * pct;         
         
         sz = normDim * pct;
         if (hButton * sz) < b.MinimumPixelHeight % Then it is too small
            sz = b.MinimumPixelHeight / pos(3);   % Clip to minimum size
         end
      end
      
      % Initialize the colors for disable/enable conditions
      function initColors(b)
         %INITCOLORS  Initializes all color-related properties
         %
         %  b.initColors();
         
         b.SelectedColor = nigeLab.defaults.nigelColors('highlight');
         b.HoveredColor = nigeLab.defaults.nigelColors('rollover');
         b.DefaultColor = 'none'; % No edges by default
         b.FaceColorEnable = nigeLab.defaults.nigelColors('enable');
         b.FaceColorDisable = nigeLab.defaults.nigelColors('disable');
         b.FontColorEnable = nigeLab.defaults.nigelColors('enabletext');
         b.FontColorDisable = nigeLab.defaults.nigelColors('disabletext');
      end
      
      % Parses "parent figure" from parent
      function fig = parseFigure(b)
         % PARSEFIGURE Parses "parent figure" from parent container
         %
         %  fig = b.parseFigure();
         
         fig = b.Parent.Parent;
         while ~isa(fig,'matlab.ui.Figure')
            fig = fig.Parent;
         end
      end
   end
   
   % STATIC,PUBLIC
   methods (Static,Access=public)
      function b = empty(n)
         %EMPTY  Create empty nigeLab.libs.nigelButton object
         %
         %  obj = nigeLab.libs.nigelButton.empty();
         %  --> Empty scalar
         %
         %  obj = nigeLab.libs.nigelButton.empty(n);
         %  --> Empty array with n elements
         
         if nargin < 1
            n = [0,0];
         else
            n = [0,max(n)];
         end
         b = nigeLab.libs.nigelButton(n);
      end
   end
   
   % STATIC,PROTECTED
   methods (Static,Access=protected)
      % Return the center coordinates based on position
      function txt_pos = getCenter(pos,xoff,yoff)
         % GETTEXTPOS  Returns the coordinates for text to go in center
         %
         %  txt_pos = nigeLab.libs.nigelButton.getCenter(pos);
         %
         %  txt_pos = nigeLab.libs.nigelButton.getCenter(pos,xoff,yoff);
         %  --> add x offset and y offset (defaults for both are zero)
         %
         %  pos -- 4-element position vector for object in 2D axes
         %  txt_pos  -- 3-element position vector for text annotation
         
         if nargin < 2
            xoff = 0;
         end
         
         if nargin < 3
            yoff = 0;
         end
         
         x = pos(1) + pos(3)/2 + xoff;
         y = pos(2) + pos(4)/2 + yoff;
         txt_pos = [x,y,0];
         
      end
      
      % Parse color argument
      function c = parseColor(value)
         %PARSECOLOR  Return color using `nigelColors` defaults or 'none'
         %
         %  c = nigeLab.libs.nigelButton.parseColor(value);
         %  --> value : Can be numeric or char
         
         if ischar(value) 
            c = nigeLab.defaults.nigelColors(value);
            if strcmpi(value,'none')
               c = value;
            end
         elseif isscalar(value)
            c = nigeLab.defaults.nigelColors(value);
         else
            if ~isnumeric(value) || (numel(value)~=3) || iscolumn(value)
               dbstack();
               disp('<strong>Attempted value:</strong>');
               disp(value);
               error(['nigeLab:' mfilename ':BadColorFormat'],...
                  '[NIGELBUTTON]: Unrecognized color format (value above)');
            else
               c = value;
            end
         end
      end
      
      % Parse first input argument and provide appropriate axes object
      function ax = parseContainer(container)
         % PARSECONTAINER  Parses first input argument and returns the
         %                 correct container for the nigelButton.
         %
         %  ax = nigeLab.libs.nigelButton.parseContainer(container);
         %
         %  ax is always output as a matlab.graphics.axis.Axes class
         %  object.
         
         switch builtin('class',container)
            case 'nigeLab.libs.nigelPanel' % If containerObj is nigelPanel, then use ButtonAxes
               ax = getChild(container,'ButtonAxes',true);
               if isempty(ax)
                  pos = container.InnerPosition;
                  pos = [pos(1) + pos(3) / 2, ...
                     pos(2) + 0.05, ...
                     pos(3) / 2, ...
                     pos(4) * 0.15];
                  ax = axes('Units','normalized', ...
                     'Tag','ButtonAxes',...
                     'Position', pos,...
                     'Color','none',...
                     'NextPlot','add',...
                     'XLimMode','manual',...
                     'XLim',[0 1],...
                     'YLimMode','manual',...
                     'YLim',[0 1],...
                     'FontName',container.FontName);
                  container.nestObj(ax,'ButtonAxes');
               end
               
            case 'matlab.graphics.axis.Axes' % If axes, just use axes as provided
               ax = container;
               
            case 'matlab.ui.container.Panel' % If uiPanel, get top axes in the panel or make new axes
               ax = [];
               for i = 1:numel(container.Children)
                  ax = container.Children(i);
                  if isa(ax,'matlab.graphics.axis.Axes')
                     break;
                  end
               end
               if isempty(ax)
                  pos = container.InnerPosition;
                  pos = [pos(1) + pos(3) / 2, ...
                     pos(2) + 0.05, ...
                     pos(3) / 2, ...
                     pos(4) * 0.15];
                  ax = axes(container,...
                     'Units','normalized', ...
                     'Tag','ButtonAxes',...
                     'Position', pos,...
                     'Color','none',...
                     'NextPlot','add',...
                     'XLimMode','manual',...
                     'XLim',[0 1],...
                     'YLimMode','manual',...
                     'YLim',[0 1],...
                     'FontName',container.FontName);
               end
            otherwise % Current support only for axes, nigelPanel, panel
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Bad input type for containerObj: %s',...
                  class(container));
         end
      end
      
      % Parse 'Name',value pairs and remove extraneous args
      function [p,s,v] = parseSpecificArgPairs(p,s,v)
         %PARSESPECIFICARGPAIRS  Remove extraneous 'Name', value pairs
         %
         %  [p,s,v]=nigeLab.libs.nigelButton.parseSpecificArgPairs(p,s,v);
         %
         %  p: `pos` constructor input (can be given as cell array)
         %  s: `string` constructor input (can be given as cell array)
         %  v: `varargin` constructor input 
         
         special_args = {...
            'buttondownfcn',...
            'userdata',...
            'facecolor',...
            'edgecolor',...
            'horizontalalignment',...
            'verticalalignment'...
            };
         
         
         if iscell(p)
            if ~isrow(p)
               p = p.';
            end
            idx = find(ismember(lower(p(1:2:end)),special_args));
            idx = 2*idx-1;
            if numel(idx) > 0
               tmp = [p(idx); p(idx+1)];
               p([idx,idx+1]) = [];
               v = horzcat(tmp{:},v);
            end
         end
         
         if iscell(s)
            if ~isrow(s)
               s = s.';
            end
            idx = find(ismember(lower(s(1:2:end)),special_args));
            idx = 2*idx-1;
            if numel(idx) > 0
               tmp = [s(idx); s(idx+1)];
               s([idx,idx+1]) = [];
               v = horzcat(v,tmp{:});
            end
         end
      end
   end
   % % % % % % % % % % END METHODS% % %
end

