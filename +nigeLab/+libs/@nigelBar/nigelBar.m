classdef nigelBar < handle
   %DASHBOARD Summary of this class goes here
   %   Detailed explanation goes here
   
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
      panel;
      axes
      titleBox
   end
   
   methods
      function obj = nigelBar(parent,varargin)
         %% Constructor. Creates a uiPanel obj with a nice title and titlebox.
         % 
         
         addlistener(obj,'Units','PostSet',@obj.UnitsChanged);
         
         set(parent,'Units','pixels');
         ParentH =parent.Position(4);
         
         
         TitleH = 0.055;
         Pars.TitleBarColor = [67 129 193]./255;   % to be loaded from colorscheme in the future
         Pars.StringColor = [255 186 73]./255;
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
%          set(parent,'Units','normalized');
         
        p = uipanel(parent,...
           'BackgroundColor',parent.Color,...
           'Units',Pars.Units,...
           'Position',Pars.Position,...
           'BorderType','none');
%         set(p,'Units','pixels');
%         set(p,'Units','normalized');

        a = axes(p,...
           'Color','none',...
           'Units','normalized',...
           'Position',[0 0 1 1]);
        a.XAxis.Visible=false;a.YAxis.Visible=false;
        
        titleBox.r1 = rectangle(a,...
           'Position',[0 0.5 1 0.5],...
           'Curvature',[0 0],...
           'FaceColor', parent.Color,...
           'EdgeColor', parent.Color);
        
        titleBox.r2 = rectangle(a,...
           'Position',[0 0 1 1],...
           'Curvature',[0.02 0.55],...
           'FaceColor', Pars.TitleBarColor,...
           'EdgeColor', Pars.TitleBarColor);
        
        for bb = 1:numel(Pars.Buttons)
           titleBox.btn(bb) = text(a,0.1,0.5,...
              Pars.Buttons(bb).String,...
              'Units','normalized',...
              'VerticalAlignment','middle',...
              'Color',Pars.StringColor,...
              'FontSize',13,...
              'FontWeight','bold',...
              'FontName','DroidSans',...
              'ButtonDownFcn',Pars.Buttons(bb).Callback);
           titleBox.btn(bb).Units = 'pixels';
           if not(bb-1)
              titleBox.btn(bb).Position(1) = 40;
           else
              titleBox.btn(bb).Position(1) = titleBox.btn(bb-1).Position(1) + titleBox.btn(bb-1).Extent(3) + 40;
              titleBox.btn(bb-1).Units = 'normalized';
           end
        end
        titleBox.btn(bb).Units = 'normalized';
        titleBox.btn(1).Units = 'normalized';
        
        obj.Parent = parent;
        obj.Tag = Pars.Tag;
        obj.InnerPosition = [.05 .05 .90 (.90 - a.Position(4))];
        obj.titleBox = titleBox;
        obj.panel = p;
        obj.axes = a;
        obj.Units = Pars.Units;
      end
      
      function cl = class(obj)
         cl = sprintf('nigelPanel (%s)', obj.Tag);
      end
      
      function UnitsChanged(obj, src, Event)
         switch Event.AffectedObject.Units
            case 'normalized'
               obj.InnerPosition =[.05 .05 .90 (.90-obj.axes.Position(4))];
               obj.Position = obj.panel.Position;
            case 'pixels'
               set(obj.axes,'Units','pixels');
               set(obj.panel,'Units','pixels');
               obj.InnerPosition = [obj.panel.Position([3 4]).*[.05 .05] obj.panel.Position(3) obj.panel.Position( 4)-obj.axes.Position(4)];
               obj.InnerPosition = round(obj.InnerPosition);
               obj.InnerPosition(3:4)= obj.InnerPosition(3:4)-obj.InnerPosition(1:2)*2;
               obj.Position = obj.panel.Position;
               set(obj.axes,'Units','normalized');
               set(obj.panel,'Units','normalized');
         end
         

      end
      
   end
end
