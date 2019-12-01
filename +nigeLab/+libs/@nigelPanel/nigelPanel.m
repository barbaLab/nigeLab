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
      InnerPosition;
      Position; % 4-element numeric vector: [x,y,width,height]
      String % Char array for string. Currently unused ...?
      Substr % Char array that is a sub-string. Currently unused ...?
      pCols
      tCols
   end
   
   properties(SetObservable)
      Units     % 'Normalized' or 'Pixels'
      Children  % Cell Array of nigeLab.libs.nigelPanel objects
   end
   
   properties (Access = private)
      OutPanel;   % Handle to the uipanel that is an "outer" container
      ChildName 
      panel;      % Handle to the uipanel that is the nigelPanel basically
      axes
      titleBox
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
         %              acceptable here.
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
         
         addlistener(obj,'Units','PostSet',@obj.UnitsChanged);

         Pars.TitleBarColor = [67 129 193]./255;   % to be loaded from colorscheme in the future
         Pars.PanelColor = [218 219 219]./255;   % to be loaded from colorscheme in the future
         Pars.TitleColor = [255 186 73]./255;
         Pars.Position  = [0.1 0.1 0.3 0.91];
         Pars.String = '';
         Pars.Substr = '';
         Pars.Tag = 'nigelPanel';
         Pars.Units = 'normalized';
         Pars.Scrollable = 'off';
         Pars = nigeLab.utils.getopt(Pars,varargin{:});
         
         obj.pCols = Pars.PanelColor;
         obj.tCols = Pars.TitleBarColor;
         obj.String = Pars.String;
         obj.Substr = Pars.Substr;
         obj.Tag = Pars.Tag;
         
         p = uipanel(parent,...
             'BackgroundColor', Pars.PanelColor,...
             'Units',Pars.Units,...
             'Position',Pars.Position,...
             'BorderType','none');
          
         p.BackgroundColor = Pars.PanelColor;

        % What is "a"? Looks like a "narrow vertical axes" that is on the
        % left-side of the uipanel p, so maybe it is a scroll bar. Except
        % TitleH is hard-coded to 0.055, so TitleH * ParentH would give a
        % value that is only 5.5% of parent height. So it's a tiny box in
        % the lower-left corner? I've changed it so it starts out as
        % normalized and is less confusing. [thought process of MM for FB
        % benefit]
        %
        % "a" is an axes that lets us produce "nice curves" on the title
        % box at the top of each nigelPanel.
        a = axes(p,...
           'Color','none',...
           'Units','normalized',... 
           'Position',[0 0.945 1 0.055]);

        Apos = a.Position;
        a.XAxis.Visible='off';
        a.YAxis.Visible='off';
        
        titleBox.r1 = rectangle(a,...
           'Position',[0 0.5 1 0.5],...
           'Curvature',[0 0],...
           'FaceColor', parent.Color,...
           'EdgeColor', parent.Color);
        
        titleBox.r2 = rectangle(a,...
           'Position',[0 0 1 1],...
           'Curvature',[0.05 0.55],...
           'FaceColor', Pars.TitleBarColor,...
           'EdgeColor', Pars.TitleBarColor);
        
        titleBox.ann = text(a,0.1,0.5,...
           Pars.String,...
           'Units','normalized',...
           'VerticalAlignment','middle',...
           'Color',Pars.TitleColor,...
           'FontSize',13,...
           'FontWeight','bold',...
           'FontName','DroidSans');
        
        obj.Parent = parent;
        obj.Tag = Pars.Tag;
        obj.InnerPosition = [0 0 1 1];
        obj.titleBox = titleBox;
        obj.OutPanel = p;
        obj.axes = a;
        obj.Units = Pars.Units;
        if strcmp(Pars.Scrollable,'on')
            p2 =  uipanel(...
                'BackgroundColor', Pars.PanelColor,...
                'Units',Pars.Units,...
                'Position',[.01 .01 .98 (.98 - a.Position(4))],...
                'BorderType','none');
            p2.Parent = p;
            jscrollpane=obj.attachScrollPanelTo(p2);
            addlistener(obj,'Children','PostSet',@obj.resizeInnerPanel);
            jscrollpane.JavaPeer.setVerticalScrollBarPolicy(javax.swing.ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS);
            jscrollpane.JavaPeer.setHorizontalScrollBarPolicy(javax.swing.ScrollPaneConstants.HORIZONTAL_SCROLLBAR_NEVER);
            jscrollpane.JavaPeer.setBorder(javax.swing.BorderFactory.createEmptyBorder)

            obj.panel = p2;
            obj.InnerPosition = [0 0 1 1];
        else
            p2 =  uipanel(...
                'BackgroundColor', Pars.PanelColor,...
                'Units',Pars.Units,...
                'Position',[.01 .01 .98 (.98 - a.Position(4))],...
                'BorderType','none');
            p2.Parent = p;
%             jscrollpane=obj.attachScrollPanelTo(p2);
%             jscrollpane.JavaPeer.setVerticalScrollBarPolicy(javax.swing.ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS);
%             jscrollpane.JavaPeer.setHorizontalScrollBarPolicy(javax.swing.ScrollPaneConstants.HORIZONTAL_SCROLLBAR_NEVER);
            obj.panel = p2;
            obj.InnerPosition = [0 0 1 1];
        end
        
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
   end
end

