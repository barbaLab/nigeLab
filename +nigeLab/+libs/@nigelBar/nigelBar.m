classdef nigelBar < handle
   %NIGELBAR   
   %
   %  barObj = nigeLab.libs.nigelBar(parent);
   %  barObj = nigeLab.libs.nigelBar(parent,'propName1',propVal1,...);
   
   properties
      Parent
      Children
      Tag
      Visible = true;
      InnerPosition;
      Position;
      String
      Substr
      strCol
      barCol
   end
   
   properties(SetObservable)
      Units
   end
   
   properties (Access = private)
      panel
      titleBar
   end
   
   methods
      % Class constructor for nigeLab.libs.nigelBar handle class
      function obj = nigelBar(parent,varargin)
         %NIGELBAR   
         %  barObj = nigeLab.libs.nigelBar(parent);
         %  barObj = nigeLab.libs.nigelBar(parent,'propName1',val1,...);
         
         addlistener(obj,'Units','PostSet',@obj.UnitsChanged);

         Pars.TitleBarColor = nigeLab.defaults.nigelColors('blue');
         Pars.StringColor = nigeLab.defaults.nigelColors('yellow');
         Pars.Position  = [0.1 0.1 0.3 0.91];
         Pars.String = '';
         Pars.Substr = '';
         Pars.Tag = 'nigelBar';
         Pars.Units = 'normalized';
         Pars.Buttons = struct('String','Home','Callback','');
         Pars = nigeLab.utils.getopt(Pars,varargin{:});
         
         obj.barCol = Pars.TitleBarColor;
         obj.strCol = Pars.StringColor;
         obj.String = Pars.String;
         obj.Substr = Pars.Substr;
         obj.Tag = Pars.Tag;
         
        p = uipanel(parent,...
           'BackgroundColor',parent.Color,...
           'Units',Pars.Units,...
           'Position',Pars.Position,...
           'BorderType','none');

        titleBar.axes = axes(p,...
           'Color','none',...
           'Units','normalized',...
           'Position',[0 0 1 1]);
        titleBar.axes.XAxis.Visible='off';
        titleBar.axes.YAxis.Visible='off';
        
        titleBar.r1 = rectangle(titleBar.axes,...
           'Position',[0 0.5 1 0.5],...
           'Curvature',[0 0],...
           'FaceColor', parent.Color,...
           'EdgeColor', parent.Color);
        
        titleBar.r2 = rectangle(titleBar.axes,...
           'Position',[0 0 1 1],...
           'Curvature',[0.02 0.55],...
           'FaceColor', Pars.TitleBarColor,...
           'EdgeColor', Pars.TitleBarColor);
        
        for bb = 1:numel(Pars.Buttons)
           titleBar.btn(bb) = text(titleBar.axes,0.1,0.5,...
              Pars.Buttons(bb).String,...
              'Units','normalized',...
              'VerticalAlignment','middle',...
              'Color',Pars.StringColor,...
              'FontSize',13,...
              'FontWeight','bold',...
              'FontName','DroidSans',...
              'ButtonDownFcn',Pars.Buttons(bb).Callback);
           titleBar.btn(bb).Units = 'pixels';
           if not(bb-1)
              titleBar.btn(bb).Position(1) = 40;
           else
              titleBar.btn(bb).Position(1) = titleBar.btn(bb-1).Position(1) ...
                 + titleBar.btn(bb-1).Extent(3) + 40;
              titleBar.btn(bb-1).Units = 'normalized';
           end
        end
        titleBar.btn(bb).Units = 'normalized';
        titleBar.btn(1).Units = 'normalized';
        
        obj.Parent = parent;
        obj.Tag = Pars.Tag;
        obj.InnerPosition = [.05 .05 .90 (.90 - titleBar.axes.Position(4))];
        obj.titleBar = titleBar;
        obj.panel = p;
        obj.Units = Pars.Units;
      end
      
      % OVERRIDDEN "class" method
      function [cl,tag] = class(obj)
         % CLASS  Returns the "type" of nigelBar
         %
         %  [cl,tag] = obj.class;
         %
         %  cl  --  string of format sprintf('nigelBar (%s)',obj.Tag);
         %  tag  --  obj.Tag directly
         
         cl = sprintf('nigelBar (%s)', obj.Tag);
         tag = obj.Tag;
      end
      
      % Listener callback to be executed when the UNITS property changes
      % -- DEPRECATED --
      function UnitsChanged(obj, src, Event)
         % UNITSCHANGED  Listener callback to be executed when the UNITS
         %               property changes. Ensures that sizing is
         %               proportional to the UNITS.
         
         switch Event.AffectedObject.Units
            case 'normalized'
               obj.InnerPosition =...
                  [.05 .05 .90 (.90-obj.titleBar.axes.Position(4))];
               obj.Position = obj.panel.Position;
            case 'pixels'
               set(obj.axes,'Units','pixels');
               set(obj.panel,'Units','pixels');
               obj.InnerPosition = [obj.panel.Position([3 4]).*[.05 .05] ...
                  obj.panel.Position(3) ...
                  obj.panel.Position( 4)-obj.axes.Position(4)];
               obj.InnerPosition = round(obj.InnerPosition);
               obj.InnerPosition(3:4)= ...
                  obj.InnerPosition(3:4)-obj.InnerPosition(1:2)*2;
               obj.Position = obj.panel.Position;
               set(obj.titleBar.axes,'Units','normalized');
               set(obj.panel,'Units','normalized');
         end
         

      end
      
   end
end
