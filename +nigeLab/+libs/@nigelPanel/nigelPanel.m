classdef nigelPanel < handle
   %% NIGELPANEL Helper object for nigeLab GUI.
% It builds a panel with a titlebox and a subtitle. The inside panel can
% also be made scrollable.
% Tipacal use:
% 
% F = figure;
% p = nigeLab.libs.nigelPanel(F,...
%             'String','ThisIsATitle',...
%             'Tag','MyFisrtNigelPanel',...
%             'Units','normalized'
%             'Position',[0 0 1 1],...
%             'Scrollable','off',...
%             'PanelColor',nigeLab.defaults.nigelColors('surface'),...
%             'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
%             'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
% ax = axes(); % some graphical object
% p.nestObj(ax);  % use function nestobj to correctly nest something inside
%                 % a nigelpanel
   
   properties
      Parent
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
      Children
   end
   
   properties (Access = private)
       OutPanel;
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
         %          set(parent,'Units','normalized');
         
         p = uipanel(parent,...
             'BackgroundColor', Pars.PanelColor,...
             'Units',Pars.Units,...
             'Position',Pars.Position,...
             'BorderType','none');
         %         set(p,'Units','pixels');
         %         set(p,'Units','normalized');
         p.BackgroundColor = Pars.PanelColor;

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
                set(obj.OutPanel,'Units','normalized');
               obj.InnerPosition = [0 0 1 1];
               obj.Position = obj.OutPanel.Position;
            case 'pixels'
               set(obj.OutPanel,'Units','pixels');
               obj.InnerPosition = getpixelposition(obj.panel);
               obj.Position = obj.OutPanel.Position;

         end
         

      end
      
      function resizeInnerPanel(obj, src, Event)
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
       [hScrollPanel, hPanel] = attachScrollPanelTo(~,hObject)
   end
end

