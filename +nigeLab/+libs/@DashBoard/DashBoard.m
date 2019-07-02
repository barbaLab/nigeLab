classdef DashBoard < handle
   %DASHBOARD 
   
   properties
      nigelGui
      Children
      Tank
   end
   
   properties(Access=private)
      remoteMonitorData = [];
      qJobs = {};
   end
   
   methods
      function obj = DashBoard(tankObj)
         
         %% Defaults Values
         bCol = nigeLab.defaults.nigelColors('background');
         PBCol = nigeLab.defaults.nigelColors('surface'); % Pabnel background colors
         onPBcol = nigeLab.defaults.nigelColors('onsurface');
         %% Init
         obj.Tank = tankObj;
         
         %% Load Graphics
         obj.nigelGui = figure('Units','pixels','Position',[500 50 1200 800],...
          'Color',bCol,'ToolBar','none','MenuBar','none');
       loadPannels(obj)
       
       %% Create Tank Tree
       Tree = uiw.widget.Tree(...
          'SelectionChangeFcn',@obj.treeSelectionFcn,...
          'Units', 'normalized', ...
          'Position',obj.Children{1}.InnerPosition,...
          'FontName','Droid Sans',...
          'FontSize',15,...
          'ForegroundColor',onPBcol);
       Tree = obj.getTankTree(Tree);
       Tree.Position(3) = Tree.Position(3)./2;
       obj.Children{1}.nestObj(Tree);
       treeContextMenu = uicontextmenu('Parent',obj.nigelGui,'Callback',@obj.prova1);
       m = methods(obj.Tank);
       m = m(startsWith(m,'do'));
       for ii=1:numel(m)
          mitem = uimenu(treeContextMenu,'Label',m{ii});
          mitem.MenuSelectedFcn = {@obj.uiCMenuClick,Tree};
       end
       set(Tree,'UIContextMenu',treeContextMenu);
       
       % Cosmetic adjustments
       Jobjs = Tree.getJavaObjects;
       Jobjs.JScrollPane.setBorder(javax.swing.BorderFactory.createEmptyBorder)
       Jobjs.JScrollPane.setComponentOrientation(java.awt.ComponentOrientation.RIGHT_TO_LEFT);
       set(Tree,'TreePaneBackgroundColor',PBCol,'BackgroundColor',PBCol,...
          'TreeBackgroundColor',PBCol,'Units','normalized','SelectionType','discontiguous');
     
       %% Save, New buttons
       ax = axes('Units','normalized', ...
         'Position', obj.Children{1}.InnerPosition,...
         'Color',PBCol,'XColor','none','YColor','none','FontName','Droid Sans');
      ax.Position(3) = ax.Position(3)./2;
      ax.Position(4) = ax.Position(4) .* 0.15;
      ax.Position(1) = ax.Position(1) + ax.Position(3);
      b1 = rectangle(ax,'Position',[1 1 2 1],'Curvature',[.1 .4],...
                     'FaceColor',nigeLab.defaults.nigelColors(2),'EdgeColor','none');
      b2 = rectangle(ax,'Position',[1 2.3 2 1],'Curvature',[.1 .4],...
         'FaceColor',nigeLab.defaults.nigelColors(2),'EdgeColor','none');
      t1 = text(ax,2,1.5,'Add','Color',nigeLab.defaults.nigelColors(2.1),'FontName','Droid Sans','HorizontalAlignment','center');
      t2 = text(ax,2,2.8,'Save','Color',nigeLab.defaults.nigelColors(2.1),'FontName','Droid Sans','HorizontalAlignment','center');
      pbaspect([1,1,1]);
      obj.Children{1}.nestObj(ax);
      %% Create recap Table

      RecapTable = uiw.widget.Table(...
         'CellEditCallback',[],...
         'CellSelectionCallback',[],...
         'Units','normalized', ...
         'Position',[obj.Children{2}.InnerPosition(1) obj.Children{2}.InnerPosition(4)./2+0.05 obj.Children{2}.InnerPosition(3) obj.Children{2}.InnerPosition(4)./2-0.1],...
         'BackgroundColor',PBCol,...
         'FontName','Droid Sans');
      obj.Children{2}.nestObj(RecapTable);
      RecapTableMJScrollPane = RecapTable.JControl.getParent.getParent;
      RecapTableMJScrollPane.setBorder(javax.swing.BorderFactory.createEmptyBorder);
      
      ax = axes('Units','normalized', ...
         'Position', [obj.Children{2}.InnerPosition(1:2) obj.Children{2}.InnerPosition(3) obj.Children{2}.InnerPosition(4)./2-.1],...
         'Color',PBCol,'XColor',onPBcol,'YColor',onPBcol,'FontName','Droid Sans');

     % axes cosmetic adjustment
      obj.Children{2}.nestObj(ax);
      ax.XAxisLocation = 'top';
      set(ax,'TickLength',[0 0]);
      pause(0.1) % gives graphics time to catch up.
      ax.YRuler.Axle.Visible = false; % removes axes line
      ax.XRuler.Axle.Visible = false;
      
      
      Tree.SelectedNodes = Tree.Root;
      Nodes.Nodes = Tree.Root;
      Nodes.AddedNodes = Tree.Root;
      treeSelectionFcn(obj,Tree,Nodes)
      
      %% Create title bar
      Position = [.01,.93,.98,.06];
      Btns = struct('String',  {'Home','Visualization Tools'},...
                    'Callback',{''    ,''});
       obj.Children{end+1} = nigeLab.libs.nigelBar(obj.nigelGui,'Position',Position,...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'StringColor',nigeLab.defaults.nigelColors('onprimary'),...
            'Buttons',Btns);
        
        %% Parameters UItabGroup
        h=uitabgroup();
        tab1 = uitab(h,'Title','settings');
        uit = uitable(tab1,'Units','normalized',...
            'Position',[0 0 1 1]);
        obj.Children{end-1}.nestObj(h);
      end
      
   end
   
   methods(Access = private)
      
      function loadPannels(obj)
         %% Create Pannels
         
         %% Overview Panel
         % Panel where animals, blocks and the tank are visualized
         str    = {'Overview'};
         strSub = {''};
         Tag      = 'PannelOvw';
         Position = [.01,.01,.33,.91];
         %[left bottom width height]
         obj.Children{end+1} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));

         
         
         %% Stats Pannel
         str    = {'Stats'};
         strSub = {''};
         Tag      = 'PannelStts';
         Position = [.35, .45, .43 ,.47];
         obj.Children{end+1} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position,...
             'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
         

         
         %% Queued works
         str    = {'Queue'};
         strSub = {''};
         Tag      = 'PannelQee';
         Position = [.35, .01, .43 , .43];
         obj.Children{end+1} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position,...
             'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'),...
            'Scrollable','on');

         
         %% Options pannel
         str    = {'Parameters'};
         strSub = {''};
         Tag      = 'PannelStff';
         Position = [.79 , .01, .2, 0.91]; 
         obj.Children{end+1} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position,...
             'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
         
         

         
      end
      
      function Tree = getTankTree(obj,Tree)
         tankObj = obj.Tank;
         Tree.Root.Name = tankObj.Name;
         AnNames = {tankObj.Animals.Name};
         for ii =1:numel(AnNames)
            AnNode = uiw.widget.CheckboxTreeNode('Name',AnNames{ii},'Parent',Tree.Root);
            set(AnNode,'UserData',[ii]);
            Metas = [tankObj.Animals(ii).Blocks.Meta];
            BlNames = {Metas.RecID};
            for jj=1:numel(BlNames)
               BlNode = uiw.widget.CheckboxTreeNode('Name',BlNames{jj},'Parent',AnNode);
               set(BlNode,'UserData',[ii,jj])
            end
         end
      end
      
      function setTankTable(obj,~)
         tankObj = obj.Tank;
         tt = tankObj.list;
         tCell = table2cell(tt);
         Status = obj.Tank.getStatus(obj.Tank.Animals(1).Blocks(1).Fields);
         StatusIndx = strcmp(tt.Properties.VariableNames,'Status');
         tCell = tCell(:,not(StatusIndx));
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
        [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell);
         

         w = obj.Children{2}.Children{1};
         w.ColumnName = tt.Properties.VariableNames(not(StatusIndx)); %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;
         plotRecapCircle(obj,Status);
      end
      
      function setAnimalTable(obj,SelectedItems)
         A = obj.Tank.Animals(SelectedItems);
         
         tCell = [];
         Status = [];
         for ii=1:numel(A)
            tt = A(ii).list;
            tCell = [tCell; table2cell(tt)];
            Status = [Status; A(ii).getStatus(A(1).Blocks(1).Fields)];
         end
         StatusIndx = strcmp(tt.Properties.VariableNames,'Status');
         tCell = tCell(:,not(StatusIndx));
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
        [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell);
         

         w = obj.Children{2}.Children{1};
         w.ColumnName = tt.Properties.VariableNames(not(StatusIndx)); %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;
         plotRecapCircle(obj,Status);
      end
      
      function setBlockTable(obj,SelectedItems)
         tCell = [];
         Status = [];
         for ii = 1:size(SelectedItems,1)
            B = obj.Tank.Animals(SelectedItems(ii,1)).Blocks(SelectedItems(ii,2));
            tt = B.list;
            tCell = [tCell; table2cell(tt)];
            Status = [Status; B.getStatus(B.Fields)'];
         end
         StatusIndx = strcmp(tt.Properties.VariableNames,'Status');
         tCell = tCell(:,not(StatusIndx));
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
        [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell);
         

         w = obj.Children{2}.Children{1};
         w.ColumnName = tt.Properties.VariableNames(not(StatusIndx)); %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;
         plotRecapCircle(obj,Status);
      end
      
      function treeSelectionFcn(obj,Tree,Nodes)
         NumNewNodes = numel(Nodes.AddedNodes);
         OldNodeType = unique(cellfun(@(x) numel(x), {Nodes.Nodes(1:end-NumNewNodes).UserData}));
         AllNodeType =  cellfun(@(x) numel(x), {Nodes.Nodes.UserData});
         NodesToRemove = not(AllNodeType==OldNodeType);
         Tree.SelectedNodes(NodesToRemove) = [];
         
         SelectedItems = cat(1,Tree.SelectedNodes.UserData);
         switch  unique(cellfun(@(x) numel(x), {Tree.SelectedNodes.UserData}))
            case 0  % tank
               setTankTable(obj);
            case 1  % animal
               setAnimalTable(obj,SelectedItems);
            case 2  % block
               setBlockTable(obj,SelectedItems);
         end
         
      end
      
      function plotRecapCircle(obj,Status)
         
         
         ax = obj.Children{2}.Children{2};
         cla(ax);
         [NAn,~] = size(Status);
         St = obj.Tank.Animals(1).Blocks(1).Fields;
         Nst = length(St);
         xlim(ax,[1 Nst+1]);ylim(ax,[1 NAn+1]);
%          image(ax,'XData',1:Nst,'YData',1:NAn,'CData',C);
         for jj=1:NAn
            for ii=1:Nst
               if Status(jj,ii)
                  rectangle(ax,'Position',[ii NAn+1-jj .97 .97],'Curvature',[0.3 0.6],...
                     'FaceColor',nigeLab.defaults.nigelColors(1),'LineWidth',1.5,'EdgeColor',[.2 .2 .2]);
               else
                  rectangle(ax,'Position',[ii NAn+1-jj 1 1],'Curvature',[0.3 0.6],...
                     'FaceColor',[nigeLab.defaults.nigelColors(2) 0.4],'EdgeColor','none');
               end
            end
         end
         ax.XAxis.TickLabel = St;
         ax.YAxis.TickLabel = cellstr( num2str((1:NAn)'));
         ax.XAxis.TickValues = 1.5:Nst+0.5;
         ax.YAxis.TickValues = 1.5:NAn+0.5;
         ax.XAxis.TickLabelRotation = 30;         
      end
      
      function uiCMenuClick(obj,m,evt,Tree)
         SelectedItems = cat(1,Tree.SelectedNodes.UserData);
         switch  unique(cellfun(@(x) numel(x), {Tree.SelectedNodes.UserData}))
            case 0  % tank
               obj.qOperations(m.Text,obj.Tank)
            case 1  % animal
               for ii=1:size(SelectedItems,1)
                  A = obj.Tank.Animals(SelectedItems(ii));
                  obj.qOperations(m.Text,A)
               end
            case 2  % block
               for ii=1:size(SelectedItems,1)
                  B = obj.Tank.Animals(SelectedItems(ii,1)).Blocks(SelectedItems(ii,2));
                  obj.qOperations(m.Text,B)
               end
         end
      end
      
      function qOperations(obj,operation,target)
         Pan = obj.Children{3};
         fileName = fullfile(nigeLab.defaults.Tempdir,[operation,target.Name]);
         obj.remoteMonitor(operation,fileName,obj.nigelGui,Pan);
         obj.qJobs{end+1} = batch(operation,0,{target});
         drawnow;

      end
      
      function deleteJob(obj,ind) %%%%%%%%%%%%%%%%%%%%% ToDO
         cancel(obj.qJobs{ind});
         pause(0.1)
         delete(obj.qJobs{ind});
         obj.qJobs(ind)=[];
      end
      remoteMonitor(obj,Labels,Files,Fig,parent);
   end
end

