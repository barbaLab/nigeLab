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
   
   properties
      Parent % Handle to Parent container. Must be a class that is a valid parent for matlab.ui.container.Panel
      Tag    % Short identifier that can be used to get this object from an array of nigelPanels
      Visible = true;
      BorderType       % default: 'None'
      Position         % Position of "outer" panel (4-element numeric vector: [x,y,width,height])
      InnerPosition    % Position for inner "non-scroll" region
      Substr      % Char array that is a sub-string. currently unused ...?
      Scrollable  % ('on' or 'off' (default))
      FontName          % Default: 'DroidSans'
      TitleFontSize     % Default: 13
      TitleFontWeight   % Default: 'bold'
      TitleBarLocation  % Location of title bar (can be 'top' or 'bot')
      TitleBarPosition  % Coordinate [px py width height] vector for titleBox position
      TitleStringX  % X-coordinate of Title String ([0 -- far left; 1 -- far right])
      TitleStringY  % Y-coordinate of middle of Title String (default: 0.5)
      DeleteFcn  % Function handle to execute on object deletion
   end
   
   properties (SetAccess = private, GetAccess = public)
      Panel;      % Handle to the uipanel that is the nigelPanel basically ("inner scroll region")
      TitleBar    % Struct for titleBox with fields: 'axes', 'r1', 'r2', and 'ann'
   end
   
   properties(SetObservable)
      Children  % Cell Array of nigeLab.libs.nigelPanel objects
      Color       % Struct with parameters for 'Panel','TitleText','TitleBar',and 'Parent'
      String      % Char array for string in obj.textBox.ann
      Units     % 'Normalized' or 'Pixels'
   end
   
   properties (Access = private)
      ChildName   % Cell array of names corresponding to elements of Children
      OutPanel;   % Handle to the uipanel that is an "outer" container
      lh          % Array of listener handles
   end
   
   methods (Access = public)
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

         obj.setProps(varargin{:});

         obj.buildOuterPanel;  % Make "outer frame" for if there is scroll bar
         obj.buildTitleBox;    % Makes "nice header box"
         obj.buildInnerPanel;  % Make scrollbar and "inner frame" container        
         obj.buildListeners;   % Make event listeners
      end
      
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
      
      % Function to execute when panel is deleted
      function deleteFcn(obj)
         delete(obj);         
      end
      
      % Method to "nest" child objects into this panel
      function nestObj(this,Obj,name)
         % NESTOBJ  Sets this nigelPanel as the parent of Obj and adds Obj
         %           to cell array of nigelPanel.Children, along with an
         %           associated name char array into cell array property
         %           nigelPanel.ChildName.
         %
         %  this = nigeLab.libs.nigelPanel;
         %  this.nestObj(graphicsObj,nameOfGraphicsObj);
         %
         %  e.g.
         %  ax = axes();
         %  this.nestObj(ax,'Information Axes');
         
         if nargin < 3
            name = '';
         end
         set(Obj, 'Parent', this.Panel);
         this.Children{end+1} = Obj;
         this.ChildName{end+1} = name;
      end
      
      % Return handle to child object corresponding to 'name'
      function c = getChild(obj,name)
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
         
         idx = ismember(obj.ChildName,name);
         if isempty(idx)
            warning('No member of %s property ChildName: %s',...
               obj.class,name);
            c = [];
         else
            c = obj.Children{idx};
         end
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
      
      % Returns the pixel position for "panel"
      function pos = getPixelPosition(obj)
         % GETPIXELPOSITION  Returns the pixel position of "panel" object
         
         pos = getpixelposition(obj.Panel);
      end
      
      % Callback executed when Units property is changed
      function UnitsChanged(obj, ~, Event)
         % UNITSCHANGED  Callback that is executed when Units property is
         %               changed. Makes sure that the panels will behave
         %               properly if the Units property is toggled even
         %               after the Constructor.
         
         switch Event.AffectedObject.Units
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
               error('Not a valid property of nigelPanel: %s',propName);
            end
            propName = pname{idx};
            obj.(propName) = value;
         else
            obj.(propName) = value;
         end
         
      end
      
   end
   
   methods (Access=private)
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
         
         obj.lh = [];
         obj.lh = [obj.lh; ...
                  addlistener(obj,'Units','PostSet',@obj.UnitsChanged)];
         obj.lh = [obj.lh; ...
                  addlistener(obj,'Color','PostSet',@(~,~)obj.setColors)];
         obj.lh = [obj.lh; ...
                  addlistener(obj,'String','PostSet',@(~,~)obj.setTitle)];
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
      function buildTitleBox(obj)
         % BUILDTITLEBOX  Build graphics for "nice header box"
         %
         %  obj.buildTitleBox; 
         
         if isempty(obj.TitleBar)
           obj.TitleBar = struct;
           obj.TitleBar.axes = axes(obj.OutPanel,... % formerly "a"
              'Color','none',...
              'Units','normalized',... 
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
              'VerticalAlignment','middle',...
              'Color',obj.Color.TitleText,...
              'FontSize',obj.TitleFontSize,...
              'FontWeight',obj.TitleFontWeight,...
              'FontName',obj.FontName);
         end
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
                   0.01 + obj.TitleBar.axes.Position(4),...  % y offset
                  -0.02,... % width offset
                  -(0.02 + obj.TitleBar.axes.Position(4))]; % height offset
            otherwise
               innerPosition = obj.InnerPosition + ...
                  [0.01,...  % x offset
                   0.01,...  % y offset
                  -0.02,... % width offset
                  -(0.02 + obj.TitleBar.axes.Position(4))]; % height offset
         end
            
         
         
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
         obj.TitleBar.r1.FaceColor = obj.Color.TitleBar;
         obj.TitleBar.r1.EdgeColor = obj.Color.TitleBar;
         obj.TitleBar.ann.Color = obj.Color.TitleText;
         
         % Set colors for "Inner Panel"
         obj.Panel.BackgroundColor = obj.Color.Panel;
         
         % Set colors for "Outer Panel"
         obj.OutPanel.BackgroundColor = obj.Color.Panel;
      end
      
      % Set all properties in the constructor based on 'Name', value pairs
      function setProps(obj,varargin)
         % SETPROPS  Set all properties in constructor based on 'Name',
         %           value input argument pairs.
         
         Pars.TitleBar = [];
         Pars.TitleBarColor = nigeLab.defaults.nigelColors('primary'); 
         Pars.PanelColor = nigeLab.defaults.nigelColors('surface');
         Pars.TitleColor = nigeLab.defaults.nigelColors('onprimary');
         Pars.Position  = [0.1 0.1 0.3 0.91];
         Pars.InnerPosition =  [0 0 1 1];
         Pars.String = '';
         Pars.Substr = '';
         Pars.BorderType = 'none';
         Pars.Tag = 'nigelPanel';
         Pars.Units = 'normalized';
         Pars.Scrollable = 'off';
         Pars.FontName = 'DroidSans';
         Pars.TitleFontSize = 13;
         Pars.TitleFontWeight = 'bold';
         Pars.TitleBarLocation = 'top';
         Pars.TitleBarPosition = [0.000 0.945 1.000 0.055; ... % top
                                  0.000 0.000 1.000 0.055];    % bottom
         Pars.TitleStringX = 0.1;
         Pars.TitleStringY = 0.5;
         Pars.DeleteFcn = @obj.deleteFcn;
         Pars = nigeLab.utils.getopt(Pars,varargin{:});
         
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
         obj.TitleBar = Pars.TitleBar; % If want to manually set TitleBar
         obj.TitleFontSize = Pars.TitleFontSize;
         obj.TitleFontWeight = Pars.TitleFontWeight;
         obj.TitleBarLocation = Pars.TitleBarLocation;
         switch lower(obj.TitleBarLocation)
            case 'top'
               obj.TitleBarPosition = [0 0.945 1 0.055];
            case {'bot','bottom'}
               obj.TitleBarPosition = Pars.TitleBarPosition(2,:);
            otherwise 
               obj.TitleBarPosition = Pars.TitleBarPosition(1,:); 
         end
         obj.TitleStringX = Pars.TitleStringX;
         obj.TitleStringY = Pars.TitleStringY;
         obj.DeleteFcn = Pars.DeleteFcn;
         
      end
      
      % Set the current annotation title (in titleBox)
      function setTitle(obj)
         % SETTITLE  Set the current annotation title (in titleBox)
         %
         %  obj.setTitle;  Uses current value of obj.String
         
         obj.TitleBar.ann.String = obj.String;
      end
   end
end

