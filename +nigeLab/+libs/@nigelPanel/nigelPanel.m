classdef nigelPanel < handle
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
      pCols
      tCols
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
      function obj = nigelPanel(parent,varargin)
         %% Constructor. Creates a uiPanel obj with a nice title and titlebox.
         % 
         
         addlistener(obj,'Units','PostSet',@obj.UnitsChanged);
         
         set(parent,'Units','pixels');
         ParentH =parent.Position(4);
         
         
         TitleH = 0.055;
         Pars.Tcol = [67 129 193]./255;   % to be loaded from colorscheme in the future
         Pars.Bcol = [218 219 219]./255;   % to be loaded from colorscheme in the future
         Pars.TcolT = [255 186 73]./255;
         Pars.Position  = [0.1 0.1 0.3 0.91];
         Pars.String = '';
         Pars.Substr = '';
         Pars.Tag = 'nigelPanel';
         Pars.Units = 'normalized';
         Pars = nigeLab.utils.getopt(Pars,varargin{:});
         
         obj.pCols = Pars.Bcol;
         obj.tCols = Pars.Tcol;
         obj.String = Pars.String;
         obj.Substr = Pars.Substr;
         obj.Tag = Pars.Tag;
%          set(parent,'Units','normalized');
         
        p = uipanel(parent,...
           'BackgroundColor', Pars.Bcol,...
           'Units',Pars.Units,...
           'Position',Pars.Position,...
           'BorderType','none');
%         set(p,'Units','pixels');
%         set(p,'Units','normalized');

        a = axes(p,...
           'Color','none',...
           'Units','pixels',...
           'Position',[0 5 5 ParentH*TitleH]);
        set(a,'Units','normalized');
        a.Position([1 3])=[0 1];
        a.Position(2)=1-a.Position(4);
        Apos = a.Position;
        a.XAxis.Visible=false;a.YAxis.Visible=false;
        
        titleBox.r1 = rectangle(a,...
           'Position',[0 0.5 1 0.5],...
           'Curvature',[0 0],...
           'FaceColor', parent.Color,...
           'EdgeColor', parent.Color);
        
        titleBox.r2 = rectangle(a,...
           'Position',[0 0 1 1],...
           'Curvature',[0.05 0.55],...
           'FaceColor', Pars.Tcol,...
           'EdgeColor', Pars.Tcol);
        
        titleBox.ann = text(a,0.1,0.5,...
           Pars.String,...
           'Units','normalized',...
           'VerticalAlignment','middle',...
           'Color',Pars.TcolT,...
           'FontSize',13,...
           'FontWeight','bold',...
           'FontName','DroidSans');
        
        obj.Parent = parent;
        obj.Tag = Pars.Tag;
        obj.InnerPosition = [.02 .02 .96 (.96 - a.Position(4))];
        obj.titleBox = titleBox;
        obj.panel = p;
        obj.axes = a;
        obj.Units = Pars.Units;
      end
      
      function cl = class(obj)
         cl = sprintf('nigelPanel (%s)', obj.Tag);
      end
      
      function nestObj(this,Obj)
         set(Obj, 'Parent', this.panel);
         this.Children{end+1} = Obj;
      end
      
      function UnitsChanged(obj, src, Event)
         switch Event.AffectedObject.Units
            case 'normalized'
               obj.InnerPosition =[.02 .02 .96 (.96-obj.axes.Position(4))];
               obj.Position = obj.panel.Position;
            case 'pixels'
               set(obj.axes,'Units','pixels');
               set(obj.panel,'Units','pixels');
               obj.InnerPosition = [obj.panel.Position([3 4]).*[.02 .02] obj.panel.Position(3) obj.panel.Position( 4)-obj.axes.Position(4)];
               obj.InnerPosition = round(obj.InnerPosition);
               obj.InnerPosition(3:4)= obj.InnerPosition(3:4)-obj.InnerPosition(1:2)*2;
               obj.Position = obj.panel.Position;
               set(obj.axes,'Units','normalized');
               set(obj.panel,'Units','normalized');
         end
         

      end
      
   end
end
