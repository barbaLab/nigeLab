classdef DashBoard < handle
   %DASHBOARD Summary of this class goes here
   %   Detailed explanation goes here
   
   properties
      nigelGui
      Children
      Tank
   end
   
   methods
      function obj = DashBoard(tankObj)
         
         %% Defaults Values
         bCol = [55 56 58]./255;
         
         %% Init
         obj.Tank = tankObj;
         
         %% Load Graphics
         obj.nigelGui = figure('Units','pixels','Position',[500 200 1200 800],...
          'Color',bCol,'ToolBar','none','MenuBar','none');
       loadPannels(obj)
       
       %% Create Tank Tree
       Tree = uiw.widget.Tree(...
          'SelectionChangeFcn',@obj.treeSelectionFcn,...
          'Units', 'normalized', ...
          'Position',obj.Children{1}.InnerPosition,...
          'FontName','Droid Sans',...
          'FontSize',15);
       Tree = obj.getTankTree(Tree);
       Tree.Position(3) = Tree.Position(3)./2;
%        [mtree, container] = uitree('v0', 'Root',TankNode, 'Parent',obj.Children{1}.panel); % Parent is ignored
       obj.Children{1}.nestObj(Tree);
%        mtree.Position=obj.Children{1}.InnerPosition;
%        jtree = mtree.getTree; % get the javba handle for the tree
%        jtree.expandRow(0);    % expands animals
       
       % Cosmetic adjustments
       PBCol = obj.Children{1}.pCols; % Pabnel background colors
       Jobjs = Tree.getJavaObjects;
       Jobjs.JScrollPane.setBorder(javax.swing.BorderFactory.createEmptyBorder)
       set(Tree,'TreePaneBackgroundColor',PBCol,'BackgroundColor',PBCol,...
          'TreeBackgroundColor',PBCol,'Units','normalized','SelectionType','discontiguous');
     
      %% Create recap Table

      RecapTable = uiw.widget.Table(...
         'CellEditCallback',[],...
         'CellSelectionCallback',[],...
         'Units','normalized', ...
         'Position',[obj.Children{2}.InnerPosition(1) obj.Children{2}.InnerPosition(4)./2 obj.Children{2}.InnerPosition(3) obj.Children{2}.InnerPosition(4)./2],...
         'BackgroundColor',PBCol,...
         'FontName','Droid Sans');
      obj.Children{2}.nestObj(RecapTable);
      RecapTableMJScrollPane = RecapTable.JControl.getParent.getParent;
      RecapTableMJScrollPane.setBorder(javax.swing.BorderFactory.createEmptyBorder);
      
      ax = axes('Units','normalized', ...
         'Position',[ obj.Children{2}.InnerPosition(3:4)./2 obj.Children{2}.InnerPosition(3:4)./2],...
         'Color',PBCol);
      ax.YAxis.Visible = false;ax.XAxis.Visible = false;
      obj.Children{2}.nestObj(ax);
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
         obj.Children{end+1} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position);

         
         
         %% Stats Pannel
         str    = {'Stats'};
         strSub = {''};
         Tag      = 'PannelStts';
         Position = [.35, .45, .43 ,.47];
         obj.Children{end+1} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position);
         

         
         %% Qued works
         str    = {'Queue'};
         strSub = {''};
         Tag      = 'PannelQee';
         Position = [.35, .01, .43 , .43];
         obj.Children{end+1} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position);

         
         %% Options pannel
         str    = {'Stuff'};
         strSub = {''};
         Tag      = 'PannelStff';
         Position = [.79 , .01, .2, 0.91]; 
         obj.Children{end+1} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position);
         
         

         
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
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
        [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData,tCell);
         

         w = obj.Children{2}.Children{1};
         w.ColumnName = tt.Properties.VariableNames; %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;
         
      end
      
      function setAnimalTable(obj,SelectedItems)
         A = obj.Tank.Animals(SelectedItems);
         
         tCell = [];
         for ii=1:numel(A)
            tt = A(ii).list;
            tCell = [tCell; table2cell(tt)];
         end
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
        [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData,tCell);
         

         w = obj.Children{2}.Children{1};
         w.ColumnName = tt.Properties.VariableNames; %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;

      end
      
      function setBlockTable(obj,SelectedItems)
         tCell = [];
         for ii = 1:size(SelectedItems,1)
            B = obj.Tank.Animals(SelectedItems(ii,1)).Blocks(SelectedItems(ii,2));
            tt = B.list;
            tCell = [tCell; table2cell(tt)];
         end
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
        [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData,tCell);
         

         w = obj.Children{2}.Children{1};
         w.ColumnName = tt.Properties.VariableNames; %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;

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
         xlim(ax,[0 1]);ylim(ax,[0 1]);
         x=0.5;y=0.5;r=.4;
         th = 0:pi/50:2*pi;
         xunit = r * cos(th) + x;
         yunit = r * sin(th) + y;
         h1 = plot(ax,xunit, yunit,'Color',[0 0 0],'LineWidth',3.7);
         hold(ax,'on');
      end
   end
end

