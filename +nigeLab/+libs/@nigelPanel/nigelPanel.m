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
      String      % Char array for string in obj.textBox.ann
      Substr      % Char array that is a sub-string. currently unused ...?
      Color       % Struct with parameters for 'Panel','TitleText','TitleBar',and 'Parent'
      Scrollable  % ('on' or 'off' (default))
      FontName          % Default: 'DroidSans'
      TitleFontSize     % Default: 13
      TitleFontWeight   % Default: 'bold'
      TitleBarPosition  % Location of title bar (can be 'top' or 'bot' or a [px py width height] vector)
      TitleStringX  % X-coordinate of Title String ([0 -- far left; 1 -- far right])
      TitleStringY  % Y-coordinate of middle of Title String (default: 0.5)
   end
   
   properties (SetAccess = private, GetAccess = public)
      panel;      % Handle to the uipanel that is the nigelPanel basically ("inner scroll region")
      titleBox    % Struct for titleBox with fields: 'axes', 'r1', 'r2', and 'ann'
   end
   
   properties(SetObservable)
      Units     % 'Normalized' or 'Pixels'
      Children  % Cell Array of nigeLab.libs.nigelPanel objects
   end
   
   properties (Access = private)
      OutPanel;   % Handle to the uipanel that is an "outer" container
      ChildName   % Cell array of names corresponding to elements of Children
   end
   
   methods
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
         
        if isa(parent,'nigeLab.libs.nigelPanel')
           parent = parent.panel;
        end
        obj.Parent = parent;
         
        
        obj.setProps(varargin{:});
        
        obj.buildOuterPanel;  % Make "outer frame" for if there is scroll bar
        obj.buildTitleBox;    % Makes "nice header box"
        obj.buildInnerPanel;  % Make scrollbar and "inner frame" container        
        addlistener(obj,'Units','PostSet',@obj.UnitsChanged);
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
         set(Obj, 'Parent', this.panel);
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
         
         pos = getpixelposition(obj.panel);
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
               obj.InnerPosition = getpixelposition(obj.panel);
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
            panPos = getpixelposition(obj.panel);
            chPos = getpixelposition(obj.Children{end});
            panPos(4) = panPos(4) - chPos(2)+5;
            setpixelposition(obj.panel,panPos);
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
         
         pos = obj.InnerPosition + ...
              [0.01,...  % x offset
               0.01,...  % y offset
               -0.02,... % width offset
               -(0.02 + obj.titleBox.axes.Position(4))]; % height offset
        obj.panel =  uipanel(obj.OutPanel,...
                'BackgroundColor', obj.Color.Panel,...
                'Units',obj.Units,...
                'Position',pos,...
                'BorderType',obj.BorderType);
        if strcmp(obj.Scrollable,'on')
           jscrollpane=obj.attachScrollPanelTo(obj.panel);
           addlistener(obj,'Children','PostSet',@obj.resizeInnerPanel);
           jscrollpane.JavaPeer.setVerticalScrollBarPolicy(javax.swing.ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS);
           jscrollpane.JavaPeer.setHorizontalScrollBarPolicy(javax.swing.ScrollPaneConstants.HORIZONTAL_SCROLLBAR_NEVER);
           jscrollpane.JavaPeer.setBorder(javax.swing.BorderFactory.createEmptyBorder)
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
             'BorderType',obj.BorderType);
      end
      
      % Build graphics for "nice header box"
      function buildTitleBox(obj)
         if isempty(obj.titleBox)
           obj.titleBox = struct;
           obj.titleBox.axes = axes(obj.OutPanel,... % formerly "a"
              'Color','none',...
              'Units','normalized',... 
              'Position',obj.TitleBarPosition);
           obj.titleBox.axes.XAxis.Visible='off';
           obj.titleBox.axes.YAxis.Visible='off';

           % Produces the "flat right-half"
           obj.titleBox.r1 = rectangle(obj.titleBox.axes,...
              'Position',[0 0.5 1 0.5],...
              'Curvature',[0 0],...
              'FaceColor', obj.Color.Parent,...
              'EdgeColor', obj.Color.Parent);

           % Produces the "rounded left-half"
           obj.titleBox.r2 = rectangle(obj.titleBox.axes,...
              'Position',[0 0 1 1],...
              'Curvature',[0.05 0.55],...
              'FaceColor', obj.Color.TitleBar,...
              'EdgeColor', obj.Color.TitleBar);

           % Annotation text
           obj.titleBox.ann = text(obj.titleBox.axes,...
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
      
      % Set all properties in the constructor based on 'Name', value pairs
      function setProps(obj,varargin)
         % SETPROPS  Set all properties in constructor based on 'Name',
         %           value input argument pairs.
         
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
         Pars.TitleBarPosition = [0 0.945 1 0.055];
         Pars.TitleStringX = 0.1;
         Pars.TitleStringY = 0.5;
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
         obj.TitleFontSize = Pars.TitleFontSize;
         obj.TitleFontWeight = Pars.TitleFontWeight;
         if ischar(Pars.TitleBarPosition)
            switch lower(Pars.TitleBarPosition)
               case 'top'
                  obj.TitleBarPosition = [0 0.945 1 0.055];
               case {'bot','bottom'}
                  obj.TitleBarPosition = [0 0 1 0.055];
               otherwise 
                  error('Invalid position: %s. (should be ''top'' or ''bot'')',...
                     Pars.TitleBarPosition);
            end
         else
            obj.TitleBarPosition = Pars.TitleBarPosition;
         end
         obj.TitleStringX = Pars.TitleStringX;
         obj.TitleStringY = Pars.TitleStringY;
         
         
      end
   end
end

