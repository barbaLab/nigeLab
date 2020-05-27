classdef nigelPanel < handle
% NIGELPANEL  Helper object for nigeLab GUI. Container for other graphics.
%
% By default, nigeLab.libs.nigelPanel builds a panel with a title box and
% subtitle. Conveniently, the panel can be made "scrollable" through some
% interfacing with "jscrollpane," which is made accessible through the
% "attachScrollPanelTo" function contributed by Yair Altman to the Matlab
% File Exchange.
%
%    obj = nigeLab.libs.nigelPanel(parent);
%    obj = nigeLab.libs.nigelPanel(parent,'Name1',value1,...);
%  
%    inputs:
%    parent  --  Container for nigelPanel object. Any class that is
%                a valid parent for matlab.ui.container.Panel is
%                acceptable here.
%    varargin  --  'Name', value input argument pairs that
%                   correspond mostly to properties of
%                   matlab.ui.container.Panel. Valid 'Name' values
%                   include:
%                   --> 'TitleBarColor' (see: 
%                        nigeLab.defaults.nigelColors)
%                   --> 'PanelColor' (see: 
%                        nigeLab.defaults.nigelColors)
%                   --> 'TitleColor' (see: 
%                        nigeLab.defaults.nigelColors)
%                   --> 'Position'
%                   --> 'String'
%                   --> 'Substr' 
%                   --> 'Tag' (default is 'nigelPanel')
%                   --> 'Units' ('normalized' or 'pixels')
%                   --> 'Scrollable' ('off' (default) or 'on')
%
% Typical use:
% 
% F = figure;
% p = nigeLab.libs.nigelPanel(F,...
%             'String','ThisIsATitle',...
%             'Tag','MyFisrtNigelPanel',...
%             'Units','normalized',...
%             'Position',[0 0 1 1],...
%             'Scrollable','off',...
%             'PanelColor',nigeLab.defaults.nigelColors('surface'),...
%             'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
%             'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
% ax = axes(); % some graphical object
% p.nestObj(ax);  % use function nestobj to correctly nest something inside
%                 % a nigelpanel
   
   % % % PROPERTIES % % % % % % % % % %
   % PUBLIC
   properties(Access=public)
      Parent                              % Handle to Parent container. Must be a class that is a valid parent for matlab.ui.container.Panel
      Tag               char              % Short identifier that can be used to get this object from an array of nigelPanels
      Visible     (1,1) logical = true    % Is the panel visible?
      BorderType        char = 'None'     % default: 'None'
      Position                            % Position of "outer" panel (4-element numeric vector: [x,y,width,height])
      InnerPosition                       % Position for inner "non-scroll" region
      Substr            char = ''         % Char array that is a sub-string. currently unused ...?
      Scrollable        char = 'off'      % ('on' or 'off' (default))
      DeleteFcn                           % Function handle to execute on object deletion
      UserData                            % user defined data
   end
   
   % SETOBSERVABLE,PUBLIC
   properties(SetObservable,Access=public)
      Children                                     % Cell Array of nigeLab.libs.nigelPanel objects
      Color                                        % Struct with parameters for 'Panel','TitleText','TitleBar',and 'Parent'
      String                                       % Char array for string in obj.textBox.ann
      Units                    char = 'Normalized' % 'Normalized' or 'Pixels'
      FontName                 char = 'Droid Sans' % Default: 'Droid Sans'
      MinTitleBarHeightPixels  double = 20         % Default: 20
      TitleFontSize            double = 13         % Default: 13
      TitleFontWeight          char = 'bold'       % Default: 'bold'
      TitleVerticalAlignment   char = 'middle'     % Default: 'middle'
      TitleAlignment           char = 'left'       % Default: 'left'
      TitleBarLocation         char = 'top'        % Location of title bar (can be 'top' or 'bot')
      TitleBarPosition                             % Coordinate [px py width height] vector for titleBox position
      TitleStringX                                 % X-coordinate of Title String ([0 -- far left; 1 -- far right])
      TitleStringY             double = 0.5        % Y-coordinate of middle of Title String (default: 0.5)
   end
   
   % PUBLIC/RESTRICTED:nigeLab.libs.nigelBar
   properties (GetAccess=public,SetAccess={?nigeLab.libs.nigelBar})
      ChildName   % Cell array of names corresponding to elements of Children
      OutPanel    % Handle to the uipanel that is an "outer" container
      Panel       % Handle to the uipanel that is the nigelPanel basically ("inner scroll region")
      TitleBar    % Struct for titleBox with fields: 'axes', 'r1', 'r2', and 'ann'
      lh          % Array of listener handles
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % PUBLIC (constructor)
   methods (Access=public)
      % Class constructor for nigeLab.libs.nigelPanel object
      function obj = nigelPanel(parent,varargin)
         % NIGELPANEL  Class constructor for nigelPanel, a standardized
         %             custom graphics container for nigeLab.
         %
         %  obj = nigelPanel(parent);
         %  obj = nigelPanel(parent,'Name1',value1,...,'NameK',valueK);
         %
         %  inputs:
         %  parent  --  Container for nigelPanel object. Any class that is
         %              a valid parent for matlab.ui.container.Panel is
         %              acceptable here. If no arguments are specified, or
         %              if the first argument is a char array, then this
         %              defaults to the current figure.
         %  varargin  --  'Name', value input argument pairs that
         %                 correspond mostly to properties of
         %                 matlab.ui.container.Panel. Valid 'Name' values
         %                 include:
         %                 --> 'TitleBarColor' (see:
         %                      nigeLab.defaults.nigelColors)
         %                 --> 'PanelColor' (see:
         %                      nigeLab.defaults.nigelColors)
         %                 --> 'TitleColor' (see:
         %                      nigeLab.defaults.nigelColors)
         %                 --> 'Position'
         %                 --> 'String'
         %                 --> 'Substr'
         %                 --> 'Tag' (default is 'nigelPanel')
         %                 --> 'Units' ('normalized' or 'pixels')
         %                 --> 'Scrollable' ('off' (default) or 'on')
         
         % Configure Parent property
         if nargin < 1
            parent = gcf;
         elseif ischar(parent)
            varargin = [parent, varargin];
            parent = gcf;
         end
         
         % If this is a nested nigeLab.libs.nigelPanel panel, then make the
         % parent the .Panel from the "parent" nigelPanel.
         if isa(parent,'nigeLab.libs.nigelPanel')
            parent = parent.Panel;
         end
         obj.Parent = parent;
         
         initProps(obj,varargin{:});
         
         buildOuterPanel(obj);  % Make "outer frame" for if there is scroll bar
         buildTitleBar(obj);    % Makes "nice header box"
         buildInnerPanel(obj);  % Make scrollbar and "inner frame" container
         buildListeners(obj);   % Make event listeners
      end
      
   end
   
   % NO ATTRIBUTES (overloads)
   methods
      % Returns the class, which is just obj.Tag
      function cl = class(obj)
         % CLASS  Returns the Tag property as formatted char array
         %
         %  cl = obj.class;
         %
         %  cl: Char array formatted as 'nigelPanel (obj.Tag)'
         
         cl = sprintf('nigelPanel (%s)', obj.Tag);
      end
      
      % Destroy cumbersome objects on nigelPanel deletion
      function delete(obj)
         % DELETE  Ensure that listener handles are properly deleted
         
         for i = 1:numel(obj.lh)
            if isvalid(obj.lh)
               delete(obj.lh);
            end
         end
      end
      
      % Set a specific property (case-insensitive)
      function set(obj,propName,value)
         % SET  Sets a specific property, specified by "propName", to the
         %      value specified by "value"
         %
         %  obj.set('parent',value); Matches 'Parent' property (case
         %                           insensitive).
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               set(obj(i),propName,value);
            end
            return;
         end
         
         % Parse whether property exists. If not, check if there is a
         % case-insensitive match and use that.
         if ~isprop(obj,propName)
            pname = properties(obj);
            idx = find(ismember(lower(pname),lower(propName)),1,'first');
            if isempty(idx)
               error(['nigeLab:' mfilename ':BadPropName'],...
                  'Not a valid property of nigelPanel: %s',propName);
            end
            propName = pname{idx};
            obj.(propName) = value;
         else
            obj.(propName) = value;
         end
         
      end
   end
   
   % SEALED,PUBLIC
   methods (Sealed,Access=public)
      % Function to execute when panel is deleted
      function deleteFcn(obj)
         delete(obj);
      end
      
      % Return handle to child object corresponding to 'name'
      function varargout = getChild(obj,name,suppressWarnings)
         % GETCHILD  Return handle to child object corresponding to 'name'
         %
         %  c = obj.getChild('ChildName');
         %
         %  c  --  element of obj.Children that corresponds to the matching
         %         element of obj.ChildName. If no matching element is
         %         found, then a warning is issued and c is returned as an
         %         empty array.
         %
         %  See Also:
         %  nigeLab.libs.nigelPanel/NESTOBJ
         
         if nargin < 3
            suppressWarnings = false;
         end
         
         idx = ismember(obj.ChildName,name);
         if sum(idx)==0
            if ~suppressWarnings
               warning('No member of %s property ChildName: %s',...
                  obj.class,name);
            end
            varargout = {[]};
         elseif sum(idx)>1
            warning('Ambiguous ChildName: %s',name);
            varargout = obj.ChildName{idx};
         else
            varargout = obj.Children(idx);
         end
      end
      
      % Returns the pixel position for "panel"
      function pos = getPixelPosition(obj)
         % GETPIXELPOSITION  Returns the pixel position of "panel" object
         
         pos = getpixelposition(obj.Panel);
      end
      
      % Method to "nest" child objects into this panel
      function nestObj(obj,c,name)
         % NESTOBJ  Sets this nigelPanel as the parent of Obj and adds Obj
         %           to cell array of nigelPanel.Children, along with an
         %           associated name char array into cell array property
         %           nigelPanel.ChildName.
         %
         %  obj = nigeLab.libs.nigelPanel;
         %  obj.nestObj(graphicsObj,'nameOfGraphicsObj');
         %
         %  e.g.
         %  ax = axes();
         %  obj.nestObj(ax,'Information Axes');
         
         if nargin < 3
            name = '';
         end
         if numel(c) > 1
            if ~iscell(name)
               name = repmat({name},size(c));
            elseif numel(name) == 1
               name = repmat(name,size(c));
            end
            
            for i = 1:numel(c)
               nestObj(obj,c(i),name{i});
            end
            return;
         end
         if isempty(c.Parent)
            c.Parent = obj.Panel;
         elseif isa(c.Parent,'matlab.graphics.axis.Axes')
            c.Parent.Parent = obj.Panel;
         else
            c.Parent = obj.Panel;
         end
         obj.Children{end+1} = c;
         obj.ChildName{end+1} = name;
         obj.fixProperties(c,'FontName');
      end
      
      % Remove the child object corresponding to 'name'
      function removeChild(obj,name)
         % REMOVECHILD  Remove the child object corresponding to
         %              name ('ChildName').
         %
         %  obj.removeChild('ChildName');
         %
         %  If it is a valid element of Children (determined by matching
         %  ChildName to ChildName property), then remove it from both
         %  Children and ChildName property arrays and delete the object
         %  corresponding to Children.
         %
         %  See Also:
         %  nigeLab.libs.nigelPanel/NESTOBJ
         
         idx = ismember(obj.ChildName,name);
         if ~isempty(idx)
            if isvalid(obj.Children{idx})
               delete(obj.Children{idx});
            end
            obj.ChildName(idx) = [];
            obj.Children(idx) = [];
         end
      end
      
      % Callback that is executed whenever a Child object is added or
      % removed to ensure that the inner panel is the correct size.
      function resizeInnerPanel(obj,~,~)
         % RESIZEINNERPANEL  Callback executed whenever Children are added
         %                   or removed from the Children cell array. It
         %                   makes sure that the inner panel is the correct
         %                   size.
         
         % This should be fixed to revert to some "initial" defaults that
         % is agnostic to whether there are Children objects
         
         if isempty(obj.Children)
            return;
         end
         
         if obj.Children{end}.Position(2)<0
            panPos = getpixelposition(obj.Panel);
            chPos = getpixelposition(obj.Children{end});
            panPos(4) = panPos(4) - chPos(2)+5;
            setpixelposition(obj.Panel,panPos);
            for ii=1:(numel(obj.Children)-1)
               objPos = getpixelposition(obj.Children{ii});
               objPos(2) = objPos(2) - chPos(2);
               setpixelposition(obj.Children{ii},objPos);
            end
            chPos(2) = 5;
            setpixelposition(obj.Children{end},chPos);
            
         end
         
      end
      
   end
   
   % PROTECTED
   methods (Access=protected)
      % Method for accessing Java-based Scrollbar, provided by Yair Altman
      [hScrollPanel, hPanel] = attachScrollPanelTo(~,hObject)
      
      % Build "inner panel" container
      function buildInnerPanel(obj)
         % BUILDINNERPANEL  Builds the "inner panel" container that is
         %                  useful for border reference when there is a
         %                  scroll bar in the nigelPanel.
         %
         %  obj.buildInnerPanel;
         
         pos = obj.getInnerPanelPosition;
         obj.Panel =  uipanel(obj.OutPanel,...
                'BackgroundColor', obj.Color.Panel,...
                'Units',obj.Units,...
                'Position',pos,...
                'BorderType',obj.BorderType);
             
         if strcmp(obj.Scrollable,'on')
            jscrollpane=obj.attachScrollPanelTo(obj.Panel);
            % Create a new listener so that the scrollbar resizes any time
            % that 'Children' property changes
            obj.lh = [obj.lh; ...
               addlistener(obj,'Children','PostSet',@obj.resizeInnerPanel)];
            
            % Scrollbar is always VERTICAL; never HORIZONTAL (allows
            % scrolling "UP" and "DOWN" as new tasks are added to a given
            % panel)
            jscrollpane.JavaPeer.setVerticalScrollBarPolicy(...
               javax.swing.ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS); 
            jscrollpane.JavaPeer.setHorizontalScrollBarPolicy(...
               javax.swing.ScrollPaneConstants.HORIZONTAL_SCROLLBAR_NEVER);
            
            % Create scrollbar border
            jscrollpane.JavaPeer.setBorder(...
               javax.swing.BorderFactory.createEmptyBorder)
         end
      end
      
      % Build event listeners
      function buildListeners(obj)
         % BUILDLISTENERS  Build event listeners for nigelPanel property
         %                 changes
         %
         %  Current listener handles (3):
         %  * 'Units' property (PostSet)
         %  * 'Color' property (PostSet)
         %  * 'String' property (PostSet)
         
         % Get a list of all "SetObservable == true" properties
         setObservablePropList = obj.findAttrValue('SetObservable');

         for i = 1:numel(setObservablePropList)
            obj.lh = [obj.lh; addlistener(obj,setObservablePropList{i},...
               'PostSet',@obj.handlePropEvents)];
         end
      end
      
      % Build "outer panel" container
      function buildOuterPanel(obj)
         % BUILDOUTERPANEL  Build "outer panel" that houses an "inner
         %                  panel" as well as a potential scroll bar that
         %                  changes the contents "viewed" in "inner panel"
         %
         %  obj.buildOuterPanel;
         
         obj.OutPanel = uipanel(obj.Parent,...
             'BackgroundColor', obj.Color.Panel,...
             'Units',obj.Units,...
             'Position',obj.Position,...
             'BorderType',obj.BorderType,...
             'DeleteFcn',@(~,~)obj.DeleteFcn);
      end
      
      % Build graphics for "nice header box"
      function buildTitleBar(obj)
         % BUILDTITLEBAR  Build graphics for "nice header box"
         %
         %  obj.buildTitleBar; 
         if isempty(obj.TitleBar)
           obj.TitleBar = struct;
           obj.TitleBar.axes = axes(obj.OutPanel,... % formerly "a"
              'Color','none',...
              'Units','normalized',... 
              'Clipping','off',...
              'Position',obj.TitleBarPosition,...
              'XColor','none',...
              'YColor','none');

           % Produces the "flat right-half"
           obj.TitleBar.r1 = rectangle(obj.TitleBar.axes,...
              'Position',[0 0.5 1 0.5],...
              'Curvature',[0 0],...
              'FaceColor', obj.Color.Parent,...
              'EdgeColor', obj.Color.Parent);

           % Produces the "rounded left-half"
           obj.TitleBar.r2 = rectangle(obj.TitleBar.axes,...
              'Position',[0 0 1 1],...
              'Curvature',[0.05 0.55],...
              'FaceColor', obj.Color.TitleBar,...
              'EdgeColor', obj.Color.TitleBar);

           % Annotation text
           obj.TitleBar.ann = text(obj.TitleBar.axes,...
              obj.TitleStringX,obj.TitleStringY,...
              obj.String,...
              'Units','normalized',...
              'VerticalAlignment',obj.TitleVerticalAlignment,...
              'HorizontalAlignment',obj.TitleAlignment,...
              'Clipping','off',...
              'Color',obj.Color.TitleText,...
              'FontSize',obj.TitleFontSize,...
              'FontWeight',obj.TitleFontWeight,...
              'FontName',obj.FontName);
         end
         fixTitleHeight(obj);
      end
      
      % "Fix" child properties so they are the same as nigelPanel (e.g.
      % 'FontName' etc.)
      function fixProperties(obj,c,propName)
         % FIXCHILDPROPERTIES  "Fix" child properties
         %
         %  obj.fixProperties(c);  Match all child properties to nigelPanel
         %                         properties (from list)
         %
         %  obj.fixProperties(c,propName);  Match child property for object 
         %                                  or array of objects.
         
         if nargin < 2
            c = obj.Children;
         end
         
         if nargin < 3
            propName = {'FontName','FontSize','Tag'};
         end
         
         if numel(c) > 1
            for i = 1:numel(c)
               obj.fixProperties(c(i),propName);
            end
            return;
         end
         
         if iscell(propName) && (numel(propName) > 1)
            for i = 1:numel(propName)
               obj.fixProperties(c,propName{i});
            end
            return;
         end
         
         if isprop(c,propName)
            switch propName
               case 'FontSize'
                  c.FontSize = obj.FontSize - 2;  % Make it smaller
               otherwise
                  c.(propName) = obj.(propName);
            end
         end
         
      end
      
      % "Fix" title bar height so that it cannot be "shorter" than a
      % minimum pixel height
      function fixTitleHeight(obj)
         % FIXTITLEHEIGHT  "Fix" title bar height based on
         %                 obj.MinTitleBarHeightPixels
         %
         %  obj.fixTitleHeight;
         
         % Parse TitleBarPosition Height from MinTitleBarHeight
         pos = obj.getPixelPosition;
         minNormHeight = obj.MinTitleBarHeightPixels / pos(4);
         obj.TitleBarPosition(4) = max(minNormHeight,...
                                       obj.TitleBarPosition(4));
      end
      
      % Returns position of "inner panel" based on "titleBox" location
      function innerPosition = getInnerPanelPosition(obj)
         % GETINNERPANELPOSITION    Returns position of "inner panel"
         %                          depending on where "titleBox" is
         %                          located.
         %
         %  innerPosition = getInnerPanelPosition(obj);
         
         switch lower(obj.TitleBarLocation)
            case 'top'
               innerPosition = obj.InnerPosition + ...
                  [0.01,...  % x offset
                   0.01,...  % y offset
                  -0.02,... % width offset
                  -(0.02 + obj.TitleBar.axes.Position(4))]; % height offset
            case {'bot','bottom'}
               innerPosition = obj.InnerPosition + ...
                  [0.01,...  % x offset
                   0.02 + obj.TitleBar.axes.Position(4),...  % y offset
                  -0.02,... % width offset
                  -(0.03 + obj.TitleBar.axes.Position(4))]; % height offset
            otherwise
               innerPosition = obj.InnerPosition + ...
                  [0.01,...  % x offset
                   0.01,...  % y offset
                  -0.02,... % width offset
                  -(0.02 + obj.TitleBar.axes.Position(4))]; % height offset
         end

      end
      
      % Set all properties in the constructor based on 'Name', value pairs
      function initProps(obj,varargin)
         % SETPROPS  Set all properties in constructor based on 'Name',
         %           value input argument pairs.
         
         p.TitleBar = [];
         p.TitleBarColor = nigeLab.defaults.nigelColors('primary'); 
         p.PanelColor = nigeLab.defaults.nigelColors('surface');
         p.TitleColor = nigeLab.defaults.nigelColors('onprimary');
         p.Position  = [0.1 0.1 0.3 0.91];
         p.InnerPosition =  [0 0 1 1];
         p.String = '';
         p.Substr = '';
         p.BorderType = 'none';
         p.Tag = 'nigelPanel';
         p.Units = 'normalized';
         p.Scrollable = 'off';
         p.FontName = 'Droid Sans';
         p.MinTitleBarHeightPixels = 20;
         p.TitleFontSize = 13;
         p.TitleFontWeight = 'bold';
         p.TitleAlignment = 'left';
         p.TitleBarLocation = 'top';
         p.TitleBarPosition = [0.000 0.945 1.000 0.055; ... % top
                               0.000 0.055 1.000 0.055];    % bottom
         p.TitleStringX = 0.1;
         p.TitleStringY = 0.5;
         p.DeleteFcn = @obj.deleteFcn;
         p.UserData = [];
         Pars = nigeLab.utils.getopt(p,varargin{:});
         
         % Parse Color struct property
         obj.Color = struct;
         obj.Color.Panel = Pars.PanelColor;
         obj.Color.TitleText = Pars.TitleColor;
         obj.Color.TitleBar = Pars.TitleBarColor;
         if isa(obj.Parent,'nigeLab.libs.nigelPanel')
            obj.Color.Parent = obj.Parent.Color.Panel;
         elseif isprop(obj.Parent,'Color')
            obj.Color.Parent = obj.Parent.Color;
         elseif isprop(obj.Parent,'BackgroundColor')
            obj.Color.Parent = obj.Parent.BackgroundColor;
         else
            error('Cannot parse parent background color for parent class (%s)',...
               class(obj.Parent));
         end
         
         % Assign other parameters
         obj.Position = Pars.Position;
         obj.InnerPosition = Pars.InnerPosition;
         obj.String = Pars.String;
         obj.Substr = Pars.Substr;
         obj.BorderType = Pars.BorderType;
         obj.Tag = Pars.Tag;
         obj.Units = Pars.Units;
         obj.Scrollable = lower(Pars.Scrollable);
         obj.FontName = Pars.FontName;
         obj.MinTitleBarHeightPixels = Pars.MinTitleBarHeightPixels;
         obj.TitleBar = Pars.TitleBar; % If want to manually set TitleBar
         obj.TitleAlignment = Pars.TitleAlignment;
         obj.TitleFontSize = Pars.TitleFontSize;
         obj.TitleFontWeight = Pars.TitleFontWeight;
         obj.TitleBarLocation = Pars.TitleBarLocation;
         switch lower(obj.TitleBarLocation)
            case 'top'
               obj.TitleVerticalAlignment = 'middle';
               obj.TitleBarPosition = Pars.TitleBarPosition(1,:);
            case {'bot','bottom'}
               obj.TitleVerticalAlignment = 'top';
               obj.TitleBarPosition = Pars.TitleBarPosition(2,:);
            otherwise 
               obj.TitleVerticalAlignment = 'middle';
               obj.TitleBarPosition = Pars.TitleBarPosition(1,:); 
         end
         obj.TitleStringX = Pars.TitleStringX;
         obj.TitleStringY = Pars.TitleStringY;
         obj.DeleteFcn = Pars.DeleteFcn;
         obj.UserData = Pars.UserData;
         
         % Create listeners for all setObservable properties
         obj.buildListeners;
      end
      
      % Set colors for all graphics objects
      function setColors(obj)
         % SETCOLORS  Set colors for all graphics objects
         %
         %  obj.setColors; Updates titleBox, OuterPanel, and panel
         %
         %  --> Uses current value of obj.Color struct property
         
         % Set colors for titleBox elements
         obj.TitleBar.r1.FaceColor = obj.Color.Parent;
         obj.TitleBar.r1.EdgeColor = obj.Color.Parent;
         obj.TitleBar.r2.FaceColor = obj.Color.TitleBar;
         obj.TitleBar.r2.EdgeColor = obj.Color.TitleBar;
         obj.TitleBar.ann.Color = obj.Color.TitleText;
         
         % Set colors for "Inner Panel"
         obj.Panel.BackgroundColor = obj.Color.Panel;
         
         % Set colors for "Outer Panel"
         obj.OutPanel.BackgroundColor = obj.Color.Panel;
      end
      
      % Set the current annotation title (in titleBox)
      function setTitle(obj)
         % SETTITLE  Set the current annotation title (in titleBox)
         %
         %  obj.setTitle;  Uses current value of obj.String
         
         obj.TitleBar.ann.String = obj.String;
      end
      
      % Callback executed when Units property is changed
      function UnitsChanged(obj)
         % UNITSCHANGED  Callback that is executed when Units property is
         %               changed. Makes sure that the panels will behave
         %               properly if the Units property is toggled even
         %               after the Constructor.
         
         switch obj.Units
            case 'normalized'
               set(obj.OutPanel,'Units','normalized');
               obj.InnerPosition = [0 0 1 1];
               obj.Position = obj.OutPanel.Position;
            case 'pixels'
               set(obj.OutPanel,'Units','pixels');
               obj.InnerPosition = getpixelposition(obj.Panel);
               obj.Position = obj.OutPanel.Position;
         end
      end
   end
   
   % STATIC,PROTECTED
   methods (Static,Access=protected)  
      % Method to find properties based on their attribute values
      function propList = findAttrValue(attrName,attrValue)
         % FINDATTRVALUE  Find properties given an attribute value
         %
         %  cl_out = nigeLab.libs.nigelPanel.findAttrValue(attrName);
         %  cl_out = nigeLab.libs.nigelPanel.findAttrValue(attrName,...
         %                                                 attrValue);
         %
         %  attrName : e.g. 'SetAccess' etc (property attributes)
         %  attrValue : (optional) e.g. 'private' or 'public' etc
         %
         %  Adapted from TheMathworks getting-information-about-properties
         
         % Get class metadata and second input arg if not specified
         if nargin < 2
            attrValue = '';
         end
         mc = meta.class.fromName('nigeLab.libs.nigelPanel');
         
         % Initialize outputs
         propListCounter = 0; 
         nProp = numel(mc.PropertyList);
         propList = cell(1,nProp);
         
         % Check each property
         for  c = 1:nProp
            mp = mc.PropertyList(c);
            if isempty (findprop(mp,attrName))
               error(['nigeLab:' mfilename ':BadPropName'],...
                  'Not a valid attribute name')
            end
            val = mp.(attrName);
            if val
               if islogical(val) || strcmp(attrValue,val)
                  propListCounter = propListCounter + 1;
                  propList(propListCounter) = {mp.Name};
               end
            end
         end
         propList = propList(1:propListCounter);
      end
      
      % Method to handle property changes in general
      function handlePropEvents(metaProp,evt)
         % HANDLEPROPEVENTS  Static function to handle property changes
         %
         %  nigeLab.libs.nigelPanel.handlePropEvents(metaProp,evt);
         
         h = evt.AffectedObject;
         switch metaProp.Name
            case 'Color'
               h.setColors;
            case 'String'
               h.setTitle;
            case 'Units'
               h.UnitsChanged;
            case 'MinTitleBarHeightPixels'
               h.fixTitleHeight;
            case 'TitleBarPosition'
               h.TitleBar.ax.Position = h.TitleBarPosition;
               h.fixTitleHeight;
            case 'TitleStringX'
               h.TitleBar.ann.Position(1) = h.TitleStringX;
            case 'TitleStringY'
               h.TitleBar.ann.Position(2) = h.TitleStringY;
            case 'FontName'
               h.TitleBar.ann.FontName = h.FontName;
               h.fixProperties(h.Children,'FontName');
            case 'TitleFontWeight'
               h.TitleBar.ann.FontWeight = h.TitleFontWeight;
            case 'TitleAlignment'
               h.TitleBar.ann.HorizontalAlignment = h.TitleAlignment;
            case 'TitleVerticalAlignment'
               h.TitleBar.ann.VerticalAlignment = h.TitleVerticalAlignment;
            otherwise
               % do nothing
         end
      end
   end
   % % % % % % % % % % END METHODS% % %
end

