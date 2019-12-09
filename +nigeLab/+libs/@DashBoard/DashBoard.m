classdef DashBoard < handle
   % DASHBOARD  Class constructor for "DashBoard" UI that provides
   %            visual indicator of processing status for Tank,
   %            Animal, and Block objects, as well as a graphical
   %            interface to run extraction methods and visualize
   %            their current progress during remote execution.
   %
   %  tankObj = nigeLab.Tank();
   %  obj = nigeLab.libs.DashBoard(tankObj);
   
   properties(SetAccess = private, GetAccess = public, SetObservable)
      Color          struct              % Struct referencing colors
      nigelGui       matlab.ui.Figure    % matlab.ui.Figure handle to user interface figure
      Tree           uiw.widget.Tree     % widget graphic for datasets as "nodes"
   end
   
   properties(SetAccess = private, GetAccess = public)
      Children       cell                % Cell array of nigelPanels
      Tank           nigeLab.Tank        % Tank associated with this DashBoard
      remoteMonitor  nigeLab.libs.remoteMonitor  % Monitor remote progress
   end
   
   properties(Access=private)
      job            cell         % Cell array of Matlab job objects
      jobIsRunning = false;
      
   end
   
   % Only the class constructor should be public
   methods(Access = public)
         function obj = DashBoard(tankObj)
         % DASHBOARD  Class constructor for "DashBoard" UI that provides
         %            visual indicator of processing status for Tank,
         %            Animal, and Block objects, as well as a graphical
         %            interface to run extraction methods and visualize
         %            their current progress during remote execution.
         %
         %  tankObj = nigeLab.Tank();
         %  obj = nigeLab.libs.DashBoard(tankObj);
            
         %% Default Values
         obj.Color = struct;
         obj.Color.fig = nigeLab.defaults.nigelColors('background');
         obj.Color.panel = nigeLab.defaults.nigelColors('surface'); 
         obj.Color.onPanel = nigeLab.defaults.nigelColors('onsurface');
         
         %% Init
         obj.Tank = tankObj;
         
         %% Load Graphics
         buildGUI(obj)
         obj.remoteMonitor=nigeLab.libs.remoteMonitor(obj.getChildPanel('Queue'));
         addlistener(obj.remoteMonitor,'jobCompleted',@obj.refreshStats);
         
         %% Create Tank Tree
         obj.buildTree();
         obj.Tree.Position(3) = obj.Tree.Position(3)./2;
         obj.Children{1}.nestObj(obj.Tree,'MainTree');
         treeContextMenu = uicontextmenu(...
            'Parent',obj.nigelGui,...
            'Callback',@obj.prova1);
         m = methods(obj.Tank);
         m = m(startsWith(m,'do'));
         for ii=1:numel(m)
            mitem = uimenu(treeContextMenu,'Label',m{ii});
            mitem.Callback = @obj.uiCMenuClick;
         end
         set(obj.Tree,'UIContextMenu',treeContextMenu);
         
         % Cosmetic adjustments
         Jobjs = obj.Tree.getJavaObjects;
         Jobjs.JScrollPane.setBorder(javax.swing.BorderFactory.createEmptyBorder)
         Jobjs.JScrollPane.setComponentOrientation(java.awt.ComponentOrientation.RIGHT_TO_LEFT);
         set(obj.Tree,...
            'TreePaneBackgroundColor',obj.Color.panel,...
            'BackgroundColor',obj.Color.panel,...
            'TreeBackgroundColor',obj.Color.panel,...
            'Units','normalized',...
            'SelectionType','discontiguous');
         
         %% Save, New buttons
         ax = axes('Units','normalized', ...
            'Tag','SaveNewButtonAxes',...
            'Position', obj.Children{1}.InnerPosition,...
            'Color',obj.Color.panel,...
            'XColor','none','YColor','none',...
            'FontName',obj.Children{1}.FontName);
         ax.Position(3) = ax.Position(3)./2;
         ax.Position(4) = ax.Position(4) .* 0.15;
         ax.Position(1) = ax.Position(1) + ax.Position(3);
         b1 = rectangle(ax,...
            'Position',[1 1 2 1],...
            'Curvature',[.1 .4],...
            'FaceColor',nigeLab.defaults.nigelColors(2),...
            'EdgeColor','none');
         b2 = rectangle(ax,...
            'Position',[1 2.3 2 1],...
            'Curvature',[.1 .4],...
            'FaceColor',nigeLab.defaults.nigelColors(2),...
            'EdgeColor','none');
         t1 = text(ax,2,1.5,'Add',...
            'Color',nigeLab.defaults.nigelColors(2.1),...
            'FontName','Droid Sans',...
            'HorizontalAlignment','center');
         t2 = text(ax,2,2.8,'Save',...
            'Color',nigeLab.defaults.nigelColors(2.1),...
            'FontName','Droid Sans',...
            'HorizontalAlignment','center');
         pbaspect([1,1,1]);
         obj.Children{1}.nestObj(ax);
         %% Create recap Table
         pRecap = obj.getChildPanel('Stats');
         RecapTable = uiw.widget.Table(...
            'CellEditCallback',[],...
            'CellSelectionCallback',[],...
            'Units','normalized', ...
            'Tag','RecapTable',...
            'Position',[pRecap.InnerPosition(1)...
                        pRecap.InnerPosition(4)./2+0.05 ...
                        pRecap.InnerPosition(3) ...
                        pRecap.InnerPosition(4)./2-0.1],...
            'BackgroundColor',obj.Color.panel,...
            'FontName','Droid Sans');
         obj.Children{2}.nestObj(RecapTable,'RecapTable');
         RecapTableMJScrollPane = RecapTable.JControl.getParent.getParent;
         RecapTableMJScrollPane.setBorder(javax.swing.BorderFactory.createEmptyBorder);
         
         ax = axes('Units','normalized', ...
            'Position', [pRecap.InnerPosition(1)+.025,...
                         pRecap.InnerPosition(2), ... 
                         pRecap.InnerPosition(3)-.05 ...
                         pRecap.InnerPosition(4)./2-.1],...
            'Tag','RecapAxes',...
            'Color',obj.Color.panel,...
            'XTickLabels',[],...
            'XColor',obj.Color.onPanel,...
            'YColor',obj.Color.onPanel,...
            'Box','off',...
            'FontName','Droid Sans');
         
         % axes cosmetic adjustment
         pRecap.nestObj(ax,'RecapAxes');
         ax.XAxisLocation = 'top';
         set(ax,'TickLength',[0 0]);
         pause(0.1) % gives graphics time to catch up.
         ax.YRuler.Axle.Visible = 'off'; % removes axes line
         ax.XRuler.Axle.Visible = 'off';
         
         %% Create title bar
         Position = [.01,.93,.98,.06];
         Btns = struct('String',  {'Home','Visualization Tools'},...
            'Callback',{''    ,''});
         obj.Children{end+1} = nigeLab.libs.nigelBar(obj.nigelGui,...
            'Position',Position,...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'StringColor',nigeLab.defaults.nigelColors('onprimary'),...
            'Buttons',Btns);
         
         %% Parameters UItabGroup
         h=uitabgroup();
         Pan = getChildPanel(obj,'Parameters');
         Pan.nestObj(h);
         
         %% Set the selected node as the root node
         obj.Tree.SelectedNodes = obj.Tree.Root;
         Nodes.Nodes = obj.Tree.Root;
         Nodes.AddedNodes = obj.Tree.Root;
         treeSelectionFcn(obj,obj.Tree,Nodes)
      end
      
   end
   
   % All other methods should be accessed via interaction with graphical
   % interface.
   methods(Access = private)
      % Method to create figure for UI as well as panels that serve as
      % containers for the rest of the UI contents
      function buildGUI(obj,fig)
         % LOADPANELS  Method to create all custom uipanels (nigelPanels)
         %             that populate most of the GUI interface.
         %
         %  obj = nigeLab.libs.Dashboard(tankObj);
         %  obj.buildGUI;   (From method of obj; make appropriate panels)
         %  obj.buildGUI(fig);  Optional: fig allows pre-specification of
         %                                figure handle
         
         %% Check input
         if nargin < 2
            fig = figure('Units','Normalized',...
               'Position',[0.1 0.1 0.8 0.8],...
               'Color',obj.Color.fig,...
               'ToolBar','none',...
               'MenuBar','none');
         end
         
         %% Overview Panel
         % Panel where animals, blocks and the tank are visualized
         str    = {'Overview'};
         strSub = {''};
         Tag      = 'Overview';
         Position = [.01,.01,.33,.91];
         %[left bottom width height]
         obj.Children{1} = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
         
         %% Stats Pannel
         str    = {'Stats'};
         strSub = {''};
         Tag      = 'Stats';
         Position = [.35, .45, .43 ,.47];
         obj.Children{2} = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
         
         
         %% Queued works
         str    = {'Queue'};
         strSub = {''};
         Tag      = 'Queue';
         Position = [.35, .01, .43 , .43];
         obj.Children{3} = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'),...
            'Scrollable','on');
         
         %% Options pannel
         str    = {'Parameters'};
         strSub = {''};
         Tag      = 'Parameters';
         Position = [.79 , .01, .2, 0.91];
         obj.Children{4} = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
         
         %% Assign
         obj.nigelGui = fig;

            % Cosmetic adjustments
            Jobjs = Tree.getJavaObjects;
            Jobjs.JScrollPane.setBorder(javax.swing.BorderFactory.createEmptyBorder)
            Jobjs.JScrollPane.setComponentOrientation(java.awt.ComponentOrientation.RIGHT_TO_LEFT);
            set(Tree,'TreePaneBackgroundColor',PBCol,'BackgroundColor',PBCol,...
                'TreeBackgroundColor',PBCol,'Units','normalized','SelectionType','discontiguous');
            
            obj.Tree = Tree;
            %% Save, New buttons
            % TODO insert axes in a panels in order to have floating buttns
            ax = axes('Units','normalized', ...
                'Position', obj.Children{1}.InnerPosition,...
                'Color','none','XColor','none','YColor','none','FontName','Droid Sans');
            ax.Position(3) = ax.Position(3)./2;
            ax.Position(4) = ax.Position(4) .* 0.25;
            ax.Position(1) = ax.Position(1) + ax.Position(3);
            b1 = rectangle(ax,'Position',[1 1 2 1],'Curvature',[.1 .4],...
                'FaceColor',nigeLab.defaults.nigelColors(2),'EdgeColor','none');
            b2 = rectangle(ax,'Position',[1 2.3 2 1],'Curvature',[.1 .4],...
                'FaceColor',nigeLab.defaults.nigelColors(2),'EdgeColor','none');
            b3 = rectangle(ax,'Position',[1 3.6 2 1],'Curvature',[.1 .4],...
                'FaceColor',nigeLab.defaults.nigelColors(2),'EdgeColor','none',...
                'ButtonDownFcn',{@(~,~,str) obj.toggleSplitMultiAnimalsUI(str),'start'});
            t1 = text(ax,2,1.5,'Add','Color',nigeLab.defaults.nigelColors(2.1),'FontName','Droid Sans','HorizontalAlignment','center');
            t2 = text(ax,2,2.8,'Save','Color',nigeLab.defaults.nigelColors(2.1),'FontName','Droid Sans','HorizontalAlignment','center');
            t3 = text(ax,2,4.1,'Split','Color',nigeLab.defaults.nigelColors(2.1),'FontName','Droid Sans','HorizontalAlignment','center');
            
            pbaspect([1,1,1]);
            obj.Children{1}.nestObj(ax);
            
            %% splitMultiAnimals Button
            
            
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
            ax.YRuler.Axle.Visible = 'off'; % removes axes line
            ax.XRuler.Axle.Visible = 'off';
            
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
            Pan = getChildPanel(obj,'Parameters');
            Pan.nestObj(h);
            
            
            
            %% Set the selected node as the root node
            Tree.SelectedNodes = Tree.Root;
            Nodes.Nodes = Tree.Root;
            Nodes.AddedNodes = Tree.Root;
            treeSelectionFcn(obj,Tree,Nodes)
            
            %% init splitmultianimals interface
            toggleSplitMultiAnimalsUI(obj,'init');
            
            %% Add all the listeners
            addlistener(obj.remoteMonitor,'jobCompleted',@obj.refreshStats);
            addlistener(obj.splitMultiAnimalsUI,'splitCompleted',@(~,e)obj.addToTree(e.nigelObj));
            
            addlistener([obj.Tank.Animals.Blocks],'ObjectBeingDestroyed',@obj.removeFromTree);
            addlistener([obj.Tank.Animals],'ObjectBeingDestroyed',@obj.removeFromTree);
            addlistener([obj.Tank],'ObjectBeingDestroyed',@obj.removeFromTree);
        end
        
        function [block,animal] = getSelectedItems(obj,mode)
            if nargin < 2
               mode = 'obj'; 
            end
            switch mode
                case 'obj'
                    block = [];
                    animal = [];
                    SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
                    switch  unique(cellfun(@(x) numel(x), {obj.Tree.SelectedNodes.UserData}))
                        case 0  % tank
                            
                        case 1  % animal
                            for ii=1:size(SelectedItems,1)
                                animal =[animal, obj.Tank.Animals(SelectedItems(ii,1))];                               %#ok<AGROW>
                                block = [block, obj.Tank.Animals(SelectedItems(ii,1)).Blocks];                         %#ok<AGROW>
                            end
                        case 2  % block
                            for ii = 1:size(SelectedItems,1)
                                animal =[animal, obj.Tank.Animals(SelectedItems(ii,1))];                               %#ok<AGROW>
                                block = [block, obj.Tank.Animals(SelectedItems(ii,1)).Blocks(SelectedItems(ii,2))];    %#ok<AGROW>
                            end
                    end
                case 'index'
                    SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
                case 'name'
                    SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
                otherwise
            end
        end
    end

    
    methods(Access = private)
        
        % CloseRequestFcn handler
        % takes car of deleting various objects
        function deleteDashBoard(obj)
            if ~isempty(obj.splitMultiAnimalsUI)
                delete(obj.splitMultiAnimalsUI.Fig);
                delete(obj.splitMultiAnimalsUI);
            end
           delete(obj.nigelGui);
        end
        
        %% Context Menu functions
        
        function treeContextMenu = initUiContextMenu(obj,Tree,treeContextMenu)
            %% intialize all the menu item here
            % doMethods and whatever else needs to be there.
            % doRawExtraction
            % doUnitFilter
            % doReReference
            % doSD
            % doLFPExtraction
            % splitMultiAnimals
            
            m = methods(obj.Tank);
            m = m(startsWith(m,'do'));
            for ii=1:numel(m)
                mitem = uimenu(treeContextMenu,'Label',m{ii});
                mitem.Callback = {@obj.uiCMenuClick,Tree};
                mitem.Enable = 'on';
            end
            mitem = uimenu(treeContextMenu,'Label','splitMultiAnimals');
            mitem.Callback = {@obj.uiCMenuClick,Tree};
            mitem.Enable = 'off';
            
        end
        
        function uiCMenuClick(obj,m,~,Tree)
            SelectedItems = cat(1,Tree.SelectedNodes.UserData);
            switch  unique(cellfun(@(x) numel(x), {Tree.SelectedNodes.UserData}))
                case 0  % tank
                    obj.qOperations(m.Label,obj.Tank)
                case 1  % animal
                    for ii=1:size(SelectedItems,1)
                        A = obj.Tank.Animals(SelectedItems(ii));
                        if startsWith(m.Label,'do')
                            obj.qOperations(m.Label,A,SelectedItems(ii));
                        else
                           A.(m.Label)(obj);
                        end
                    end
                case 2  % block
                    for ii = 1:size(SelectedItems,1)
                        B = obj.Tank.Animals(SelectedItems(ii,1)).Blocks(SelectedItems(ii,2)); %#ok<AGROW>
                        obj.qOperations(m.Label,B(ii),SelectedItems(ii,:));
                    end
                    %                if ~obj.initJobs(B)
                    %                   fprintf(1,'Jobs are still running. Aborted.\n');
                    %                   return;
                    %                end
                    %                for ii=1:numel(B)
                    %                   obj.qOperations(m.Label,B(ii),ii)
                    %                end
            end
        end
        
        function setUIContextMenuVisibility(obj,src,evt)
            
%             SelectedItems = cat(1,src.SelectedNodes.UserData);
            switch  unique(cellfun(@(x) numel(x), {src.SelectedNodes.UserData}))
                case 0  % tank
                    ...
                case 1  % animal
                    ...
                case 2  % block
                    ...
            end
            
            %% Set menuItems active or inactive
            menuItems = {src.UIContextMenu.Children.Label};
            
            indx = (startsWith(menuItems,'do'));
            
            
            [src.UIContextMenu.Children(indx).Enable] = deal('on');
            [src.UIContextMenu.Children(~indx).Enable] = deal('off');
        end
        
        % Method to create all the custom uipanels (nigelPanels) that
        % populate most of the GUI interface.
        function loadPanels(obj)
            %% Create Panels
            
            %% Overview Panel
            % Panel where animals, blocks and the tank are visualized
            str    = {'Overview'};
            strSub = {''};
            Tag      = 'Overview';
            Position = [.01,.01,.33,.91];
            %[left bottom width height]
            obj.Children{1} = nigeLab.libs.nigelPanel(obj.nigelGui,...
                'String',str,'Tag',Tag,'Position',Position,...
                'PanelColor',nigeLab.defaults.nigelColors('surface'),...
                'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
                'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
            
            %% Stats Pannel
            str    = {'Stats'};
            strSub = {''};
            Tag      = 'Stats';
            Position = [.35, .45, .43 ,.47];
            obj.Children{2} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position,...
                'PanelColor',nigeLab.defaults.nigelColors('surface'),...
                'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
                'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
            
            
            %% Queued works
            str    = {'Queue'};
            strSub = {''};
            Tag      = 'Queue';
            Position = [.35, .01, .43 , .43];
            obj.Children{3} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position,...
                'PanelColor',nigeLab.defaults.nigelColors('surface'),...
                'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
                'TitleColor',nigeLab.defaults.nigelColors('onprimary'),...
                'Scrollable','on');
            
            %% Options pannel
            str    = {'Parameters'};
            strSub = {''};
            Tag      = 'Parameters';
            Position = [.79 , .01, .2, 0.91];
            obj.Children{4} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position,...
                'PanelColor',nigeLab.defaults.nigelColors('surface'),...
                'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
                'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
            
        end
        
        % Method to create each Tank node on the tree.
        function Tree = initTankTree(obj)
            onPBcol = nigeLab.defaults.nigelColors('onsurface');
            Tree = uiw.widget.Tree(...
                'SelectionChangeFcn',@obj.treeSelectionFcn,...
                'Units', 'normalized', ...
                'Position',obj.Children{1}.InnerPosition,...
                'FontName','Droid Sans',...
                'FontSize',15,...
                'ForegroundColor',onPBcol);
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
        
        function Tree = addToTree(obj,nigelObj)
            Tree = obj.Tree;
            switch class(nigelObj)
                case 'nigeLab.Tank'
                    ...
                case 'nigeLab.Animal'
                numAnimals = numel(obj.Tank.Animals);
                AnNames = {nigelObj.Name};
                for ii =1:numel(AnNames)
                    indx = strcmp({obj.Tree.Root.Children.Name},AnNames{ii});
                    if any(indx)
                        AnNode = obj.Tree.Root.Children(indx);
                    else
                    AnNode = uiw.widget.CheckboxTreeNode('Name',AnNames{ii},'Parent',Tree.Root);
                    set(AnNode,'UserData',[numAnimals+ii]);
                    end
                   
                    Metas = [nigelObj(ii).Blocks.Meta];
                    BlNames = {Metas.RecID};
                    for jj=1:numel(BlNames)
                        BlNode = uiw.widget.CheckboxTreeNode('Name',BlNames{jj},'Parent',AnNode);
                        
                        set(BlNode,'UserData',[numAnimals + ii,jj]);
                    end
                    
                    %% actually add animals to block
                    obj.Tank.Animals = [obj.Tank.Animals, nigelObj(ii)];
                end
                case 'nigeLab.Block'
                    Metas = [nigelObj.Meta];
                    AnNames = {Meta.AnimalID};
                    for ii =1:numel(AnNames)
                        AnIndx = strcmp({Tree.Root.Children.Name},AnNames(ii));
                        AnNode = Tree.Root.Children(AnIndx); 
                        BlNames = {Metas.RecID};
                        for jj=1:numel(BlNames)
                            BlNode = uiw.widget.CheckboxTreeNode('Name',BlNames{jj},'Parent',AnNode);
                            
                            set(BlNode,'UserData',[numAnimal + ii,jj]);
                        end
                        %% actually add animals to block
                        obj.Tank.Animals(AnIndx).Blocks = [obj.Tank.Animals(AnIndx).Blocks, nigelObj];
                    end
            end
            
            nigeLab.libs.DashBoard.addToNode(animalNode,BlNames);
         end
         obj.Tree = Tree; % Assign as property of DashBoard at end
      end
      
      % Initialize the job array, as well as the isJobRunning
      % property for the method. Return false if unable to initialize (for
      % example, if job for one step is still running).
      function flag = initJobs(obj,target)
         flag = false;
         % For example, if doRawExtraction was run, don't want to run
         % doUnitFilter yet. NOTE: Start here with 'any' but could later be
         % updated to only re-initialize the jobIsRunning array if it
         % should change size. Then, you could have asymmetric job
         % advancement by only checking on BLOCK case for job creation.
         if any(obj.jobIsRunning)
            fprintf(1,'Jobs are still running. Aborted.\n');
            return;
         end
         
         % Remove any previous job handle objects, if they exist
         if ~isempty(obj.job)
            for ii = 1:numel(obj.job)
               delete(obj.job{ii});
            end
         end
         
         % Remove any previous progress bars, if they exist
         if ~isempty(obj.jobProgressBar)
            for ii = 1:numel(obj.jobProgressBar)
               f = fieldnames(obj.jobProgressBar{ii});
               for ik = 1:numel(f)
                  if isvalid(obj.jobProgressBar{ii}.(f{ik}))
                     delete(obj.jobProgressBar{ii}.(f{ik}));
                  end
               end   
            end
         end
         
         obj.jobIsRunning = false(1,getNumBlocks(target));
         obj.jobProgressBar = cell(1,getNumBlocks(target));
         obj.job = cell(1,getNumBlocks(target));         
         
         flag = true; % If completed successfully
      end
      
      % Return the panel corresponding to a given tag
      % (so we don't memorize panel indices)
      function panelHandle = getChildPanel(obj,tagString)
         % GETCHILDPANEL  Return panel handle that corresponds to tagString
         %
         %  panelHandle = obj.getChildPanel('nigels favorite panel');
         %  --> panelHandle returns handle to nigelPanel with Tag property
         %      of 'nigels favorite panel'
         
         idx = 0;
         panelHandle = [];
         while idx < numel(obj.Children)
            idx = idx + 1;
            if isprop(obj.Children{idx},'Tag')
               if strcmpi(obj.Children{idx}.Tag,tagString)
                  panelHandle = obj.Children{idx};
                  break;
               end
            end
         end
         if isempty(panelHandle)
            error('Could not match nigelPanel Tag (%s).',tagString);
         end
      end

      % Creates the "recap circles" (rectangles with rounded edges that
      % look nice) for displaying the current status of different
      % processing stages. This should behave differently depending on if a
      % Tank, Animal, or Block node has been selected.
      function plotRecapCircle(obj,SelectedItems)
        % PLOTRECAPCIRCLE  Plot overview of operations performed within the
        %                  "Stats" panel.
        %
        %   obj.plotRecapCircle(Status);
        %
        %   obj --  nigeLab.libs.DashBoard object
        %   SelectedItems -- indexing matrix from tree/node structure where
        %                    first column is animal index and second is
        %                    block index.
        %      --> If only a single "row" of SelectedItems (e.g. one block)
        %          is given, then the behavior of the table changes such
        %          that it shows individual channel statuses for that
        %          block. Otherwise it looks at the "aggregate" stage
        %          processing status based on combination of all channels'
        %          progress on that stage and the channel mask (Block.Mask)
        
         p = obj.getChildPanel('Stats');
         ax = p.getChild('RecapAxes');
         cla(ax);
         [NAn,~] = size(Status);
         St = obj.Tank.Animals(1).Blocks(1).Fields;
         Nst = length(St);
         xlim(ax,[1 Nst+1]);
         ylim(ax,[1 NAn+1]);
         
         switch size(SelectedItems,1)
            case 1
               
            otherwise
               for jj=1:NAn
                  for ii=1:Nst
                     if Status(jj,ii)
                        rectangle(ax,'Position',[ii NAn+1-jj .97 .97],...
                           'Curvature',[0.3 0.6],...
                           'FaceColor',nigeLab.defaults.nigelColors(1),...
                           'LineWidth',1.5,...
                           'EdgeColor',[.2 .2 .2]);
                     else
                        rectangle(ax,'Position',[ii NAn+1-jj 1 1],...
                           'Curvature',[0.3 0.6],...
                           'FaceColor',[nigeLab.defaults.nigelColors(2) 0.4],...
                           'EdgeColor','none');
                     end
                  end
               end
         end
         
         ax.XAxis.TickLabel = St;
         ax.YAxis.TickLabel = cellstr( num2str((1:NAn)'));
         ax.XAxis.TickValues = 1.5:Nst+0.5;
         ax.YAxis.TickValues = 1.5:NAn+0.5;
         ax.XAxis.TickLabelRotation = 30;
      end
      
      % This function wraps any of the "do" methods of Block, allowing them
      % to be added to a job queue for parallel and/or remote processing
      function qOperations(obj,operation,target,idx)
         % QOPERATIONS  Wrapper for "do" methods of Block, for adding to
         %              jobs to a queue for parallel and/or remote
         %              processing.
         %
         %  nigeLab.DashBoard.qOperations(operation,target);
         %  nigeLab.DashBoard.qOperations(operation,target,idx);
         %
         %  inputs:
         %  operation  --  "do" method function handle
         %  target  --  ULTIMATELY, A BLOCK OR ARRAY OF BLOCKS. Can be
         %                 passed as: Tank, Animal, Block or Block array.
         %  idx  --  (Optional) Indexing into subset of tanks or blocks to
         %              use. Should be set as a two-element column vector,
         %              where the first index references ??? and second
         %              index references ??? 
         
         % Set indexing to assign to UserData property of Jobs, so that on
         % job completion the corresponding "jobIsRunning" property array
         % element can be updated appropriately.
         if nargin < 4
            idx = [1 1];
         end 
         
         % Want to split this up based on target type so that we can
         % manage Job/Task creation depending on the input target class
         switch class(target)
            case 'nigeLab.Tank'               
               for ii = 1:numel(target.Animals)
                  for ik = 1:target.Animals(ii).getNumBlocks
                     qOperations(obj,operation,...
                        target.Animals(ii).Blocks(ik),[ii ik]);
                     
                  end
               end
               
            case 'nigeLab.Animal'              
               for ii = 1:numel(target.Blocks)
                  qOperations(obj,operation,target.Blocks(ii),[idx ii]);
               end
               
            case 'nigeLab.Block'
               
% checking licences and parallel flags to determine where to execute the
% computation. Three possible outcomes:
% local - Serialized
% local - Distributed
% remote - Distributed
               qParams = nigeLab.defaults.Queue;
               
               
               if qParams.UseParallel...              check user preference
                       && license('test','Distrib_Computing_Toolbox')... check if toolbox is licensed
                       && ~isempty(ver('distcomp'))...           and check if it's installed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Configure remote or local cluster for correct parallel computation
                  fprintf(1,'Initializing job: %s - %s\n',operation,target.Name);
                  if qParams.UseRemote
                      if isfield(qParams,'Cluster')                          
                          myCluster = parcluster(qParams.Cluster);
                      else
                          myCluster = nigeLab.utils.findGoodCluster();
                      end
                  else
                      myCluster = parcluster();
                  end
                  
                  
                  attachedFiles = ...
                     matlab.codetools.requiredFilesAndProducts(...
                     sprintf('%s.m',operation));
                 
                  p = nigeLab.utils.getNigelPath('UNC');
                  
                  % programmatically create a worker config file.
                  % TODO, maybe using a template? for the time being we
                  % only need a addpath function
                  configFilePath = fullfile(nigeLab.defaults.Tempdir,'configW.m');
                  fid = fopen(configFilePath,'w');
                  fprintf(fid,'addpath(''%s'');',p);
                  fclose(fid);
                  attachedFiles = [attachedFiles, {configFilePath}];
                  
                 
                  for jj=1:numel(attachedFiles)
                      attachedFiles{jj}=nigeLab.utils.getUNCPath(attachedFiles{jj});
                  end
                  nPars = nigeLab.defaults.Notifications();
                  n = min(nPars.NMaxNameChars,numel(target.Name));
                  name = target.Name(1:n);
                  name = strrep(name,'_','-');
                  
                  tagStr = reportProgress(target,'Queuing',0);
                  job = createCommunicatingJob(myCluster, ...
                     'AttachedFiles', attachedFiles, ...
                     'Name', [operation target.Name], ...
                     'NumWorkersRange', qParams.NWorkerMinMax, ...
                     'Type','pool', ...
                     'UserData',idx,...
                     'Tag',tagStr); %#ok<*PROPLC>
                 
                 if isfield(target.Meta,'AnimalID') && isfield(target.Meta,'RecID')
                     BlName = sprintf('%s.%s',target.Meta.AnimalID,target.Meta.RecID);
                 else
                     warning('Missing AnimalID or RecID Meta fields. Using Block.Name instead.');
                     BlName = strrep(target.Name,'_','.');
                 end
                 BlName = BlName(1:min(end,25));
                 barName = sprintf('%s %s',BlName,operation(3:end));
                 bar = obj.remoteMonitor.addBar(barName,job,idx);
                 obj.remoteMonitor.updateStatus(bar,'Pending...')

                  job.FinishedFcn = {@(~,~,b)obj.remoteMonitor.barCompleted(b),bar};
                  
                  % updating status labels
                  job.QueuedFcn =  {@(~,~,b)obj.remoteMonitor.updateStatus(b,'Queuing...'),bar};
                  job.RunningFcn = {@(~,~,b)obj.remoteMonitor.updateStatus(b,'Running...'),bar};

                  createTask(job,operation,0,{target});
                  submit(job);
                  fprintf(1,'Job running: %s - %s\n',operation,target.Name);
                  
                  
               else
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                   
                  %% otherwise run single operation serially
                  fprintf(1,'(Non-parallel) job running: %s - %s\n',...
                     operation,target.Name);
                 
                 if isfield(target.Meta,'AnimalID') && isfield(target.Meta,'RecID')
                     BlName = sprintf('%s.%s',target.Meta.AnimalID,target.Meta.RecID);
                 else
                     warning('Missing AnimalID or RecID Meta fields. Using Block.Name instead.');
                     BlName = strrep(target.Name,'_','.');
                 end
                 BlName = BlName(1:min(end,25));
                 barName = sprintf('%s %s',BlName,operation(3:end));
                 bar = obj.remoteMonitor.addBar(barName,[],idx);
                 obj.remoteMonitor.updateStatus(bar,'Serial. Check command window.')
                 pause(0.1);
                 feval(operation,target);
                 obj.remoteMonitor.barCompleted(bar);
                 obj.remoteMonitor.updateStatus(bar,'Done.')
               end
               
            otherwise
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Invalid target class: %s',class(target));
         end
         drawnow;
         
      end
      
      % Refresh the "Stats" table when a stage is updated
      function refreshStats(obj,~,evt)
         % REFRESHSTATS  Callback to refresh the "stats" table when a stage
         %               is updated.
         %
         %  Example usage:
         %  rm = nigeLab.libs.remoteMonitor;
         %  lh = addlistener(rm,'jobCompleted',@obj.refreshStats);
         %
         %  obj  --  nigeLab.libs.DashBoard object
         %  ~  --  "Source"  (unused; nigeLab.libs.remoteMonitor object)
         %  evt  --  "EventData" associated with the remoteMonitor
         %           'jobCompleted' event, which is a
         %           nigeLab.evt.jobCompletedEventData custom event
         
         % class(bar) = 'nigeLab.libs.nigelProgress'  
         % evt.UserData is from evt.bar
         idx = evt.UserData;
         obj.Tank.Animals(idx(1)).Blocks(idx(2)).reload;
         selEvt = struct('Nodes',obj.Tree.SelectedNodes,...
                         'AddedNodes',obj.Tree.SelectedNodes);
         obj.treeSelectionFcn(obj.Tree, selEvt)
      end
      
      % Set the "TANK" table -- the display showing processing status
      function setTankTable(obj,~)
         % SETTANKTABLE  Creates "TANK" table, a high-level overview of
         %               processing stats for all the contents of a given
         %               nigeLab.Tank object.
         %
         %  obj.setTankTable();
         
         tankObj = obj.Tank;
         tt = tankObj.list;
         tCell = table2cell(tt);
         Status = obj.Tank.getStatus(obj.Tank.Animals(1).Blocks(1).Fields);
         StatusIndx = strcmp(tt.Properties.VariableNames,'Status');
         tCell = tCell(:,not(StatusIndx));
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
         tmp = unique(month( tCell{strcmp(columnFormatsAndData,'datetime')},'shortname'));
         for ii=1:(numel(tmp)-1),tmp{ii} = [tmp{ii} ', '];end
         tCell(strcmp(columnFormatsAndData,'datetime')) = {tmp};
         columnFormatsAndData{strcmp(columnFormatsAndData,'datetime')} = 'cell';
         [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell,'Tank');
         
         w = obj.Children{2}.Children{1};
         w.ColumnName = tt.Properties.VariableNames(not(StatusIndx)); %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;
         plotRecapCircle(obj,Status);
      end
      
      % Set the "ANIMAL" table -- the display showing processing status
      function setAnimalTable(obj,SelectedItems)
         % SETANIMALTABLE  Creates "ANIMAL" table for currently-selected
         %                 NODE, indicating the current state of processing
         %                 for a given nigeLab.Animal object.
         %
         %  obj.setAnimalTable(SelectedItems);
         %
         %  SelectedItems  --  Subset of nodes corresponding to
         %                     currently-selected nigeLab.Animal objects.
         %                    --> This is an indexing array
         
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
         [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell,'Animal');
         
         
         w = obj.Children{2}.Children{1};
         w.ColumnName = tt.Properties.VariableNames(not(StatusIndx)); %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;
         plotRecapCircle(obj,SelectedItems);
      end
      
      % Set the "BLOCK" table -- the display showing processing status
      function setBlockTable(obj,SelectedItems)
         % SETBLOCKTABLE  Creates the "BLOCK" table for currently-selected
         %                NODE, indicating the current state of processing
         %                for a given nigeLab.Block object.
         %
         %  obj.setBlockTable(SelectedItems);
         %
         %  SelectedItems  --  Subset of nodes corresponding to
         %                     currently-selected nigeLab.Block objects.
         %                    --> This is an indexing matrix, where the
         %                        first column indexes Animals and the
         %                        second column indexes Block.
         
         tCell = [];
         Status = [];
         B = obj.Tank{SelectedItems};
         for b = B
            tt = b.list;
            tCell = [tCell; table2cell(tt)];
            Status = [Status; b.getStatus(b.Fields)'];
         end
         StatusIndx = strcmp(tt.Properties.VariableNames,'Status');
         tCell = tCell(:,not(StatusIndx));
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
         [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell,'Block');
         
         pRecap = obj.getChildPanel('Stats');
         w = pRecap.getChild('RecapTable');
         w.ColumnName = tt.Properties.VariableNames(not(StatusIndx)); %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;

         plotRecapCircle(obj,SelectedItems);

      end
      
      % Updates the 'Parameters' panel with current TANK parameters
      function setTankTablePars(obj)
         % SETTANKTABLEPARS  Display the parameters for TANK
         %
         %  obj.setTankTablePars
         
         T = obj.Tank;
         Pan = getChildPanel(obj,'Parameters');
         h =  Pan.Children{1};
         delete(h.Children);
         ActPars = T.Pars;
         
         dd=struct2cell(ActPars);
         inx=cellfun(@(x) (isnumeric(x) && isscalar(x))||islogical(x)||ischar(x), dd);
         
         ff =fieldnames(ActPars);
         if any(inx)
            tab1 = uitab(h,'Title','Pars');
            InnerPos = getpixelposition(tab1) .*tab1.Position;
            InneWidth = InnerPos(3);
            uit = uitable(tab1,'Units','normalized',...
               'Position',[0 0 1 1],'Data',[ff(inx),dd(inx)],...
               'RowName',[],'ColumnWidth',{round(InneWidth*0.3),round(InneWidth*0.65)});
         end
         
      end
      
      % Updates the 'Parameters' panel with current ANIMAL parameters
      function setAnimalTablePars(obj,SelectedItems)
         % SETANIMALTABLEPARS  Display parameters for selected ANIMAL(s)
         %
         %  obj.setAnimalTablePars(SelectedItems);
         %
         %  SelectedItems  --  Subset of nodes corresponding to
         %                     currently-selected nigeLab.Animal objects.
         %                    --> This is an indexing array
         
         A = obj.Tank.Animals(SelectedItems);
         Pan = getChildPanel(obj,'Parameters');
         h =  Pan.Children{1};
         delete(h.Children);
         ActPars = A.Pars;
         
         dd=struct2cell(ActPars);
         inx=cellfun(@(x) (isnumeric(x) && isscalar(x))||islogical(x)||ischar(x), dd);
         
         ff =fieldnames(ActPars);
         if any(inx)
            tab1 = uitab(h,'Title','Pars');
            InnerPos = getpixelposition(tab1) .*tab1.Position;
            InneWidth = InnerPos(3);
            uit = uitable(tab1,'Units','normalized',...
               'Position',[0 0 1 1],'Data',[ff(inx),dd(inx)],...
               'RowName',[],'ColumnWidth',{round(InneWidth*0.3),round(InneWidth*0.65)});
         end
         
      end
      
      % Updates the 'Parameters' panel with current BLOCK parameters
      function setBlockTablePars(obj,SelectedItems)
         % SETBLOCKTABLEPARS  Display the parameters for selected BLOCK(s)
         %
         %  obj.setBlockTablePars(SelectedItems);
         %
         %  SelectedItems  --  Subset of nodes corresponding to
         %                     currently-selected nigeLab.Block objects.
         %                    --> This is an indexing matrix
         
         B = obj.Tank.Animals(SelectedItems(1,1)).Blocks(SelectedItems(1,2));
         Fnames = fieldnames(B.Pars);
         Pan = getChildPanel(obj,'Parameters');
         h =  Pan.Children{1};
         delete(h.Children);
         for ii=1:numel(Fnames)
            ActPars = B.Pars.(Fnames{ii});
            

        end
        
        function setTankTable(obj,~)
            tankObj = obj.Tank;
            tt = tankObj.list;
            tCell = table2cell(tt);
            Status = obj.Tank.getStatus(obj.Tank.Animals(1).Blocks(1).Fields);
            StatusIndx = strcmp(tt.Properties.VariableNames,'Status');
            tCell = tCell(:,not(StatusIndx));
            columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
            recDates = tCell(:,strcmp(columnFormatsAndData,'datetime'));
            recmonths = cellfun(@(x) month(x,'shortname'),recDates,'UniformOutput',false);
            tmp = cellfun(@(x) {strjoin(unique(x),',')},recmonths,'UniformOutput',false);
            tCell(:,strcmp(columnFormatsAndData,'datetime')) = tmp;
            columnFormatsAndData{strcmp(columnFormatsAndData,'datetime')} = 'cell';
            [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell,'Tank');
            
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
            [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell,'Animal');
            
            
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
            [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell,'Block');
            
            
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
            notify(obj,'TreeSelectionChanged');
            
            SelectedItems = cat(1,Tree.SelectedNodes.UserData);
            switch  unique(cellfun(@(x) numel(x), {Tree.SelectedNodes.UserData}))
                case 0  % tank
                    setTankTable(obj);
                    setTankTablePars(obj);
                case 1  % animal
                    setAnimalTable(obj,SelectedItems);
                    setAnimalTablePars(obj,SelectedItems);
                case 2  % block
                    setBlockTable(obj,SelectedItems);
                    setBlockTablePars(obj,SelectedItems);
            end
            
            setUIContextMenuVisibility(obj,Tree,[]);
            
        end
        
        function setTankTablePars(obj)
            T = obj.Tank;
            Pan = getChildPanel(obj,'Parameters');
            h =  Pan.Children{1};
            delete(h.Children);
            ActPars = T.Pars;
            
            dd=struct2cell(ActPars);
            inx=cellfun(@(x) (isnumeric(x) && isscalar(x))||islogical(x)||ischar(x), dd);
            
            ff =fieldnames(ActPars);
            if any(inx)
                tab1 = uitab(h,'Title','Pars');
                InnerPos = getpixelposition(tab1) .*tab1.Position;
                InneWidth = InnerPos(3);
                uit = uitable(tab1,'Units','normalized',...
                    'Position',[0 0 1 1],'Data',[ff(inx),dd(inx)],...
                    'RowName',[],'ColumnWidth',{round(InneWidth*0.3),round(InneWidth*0.65)});
            end
         end
      end
      
      % Function for interfacing with the tree based on current selection
      function treeSelectionFcn(obj,Tree,Nodes)
         % TREESELECTIONFCN  Interfaces with the Tree based on the current
         %                   selection. Used as SELECTIONCHANGEDFCN for
         %                   uiw.widget.Tree 'SelectionChanged' event
         %
         %  node = uiw.widget.Tree('Parent',obj.Tree);
         %  node.SelectionChangedFcn = @obj.treeSelectionFcn;
         %
         %  obj  --  nigeLab.libs.DashBoard class object
         %  Tree  --  "Source" object
         %  Nodes  --  "EventData" that has field .AddedNodes, which can be
         %             used in combination with .UserData to figure out
         %             which Animal and Block combinations were selected.
         
         
         NumNewNodes = numel(Nodes.AddedNodes);
         % Get UserData indexing all OLD nodes (from previous selection)
         OldNodeType = unique(...
                        cellfun(@(x) numel(x), ...
                           {Nodes.Nodes(1:(end-NumNewNodes)).UserData}));
         % Get UserData indexing ALL nodes
         AllNodeType =  cellfun(@(x) numel(x), {Nodes.Nodes.UserData});
         
         NodesToRemove = not(AllNodeType==OldNodeType);
         Tree.SelectedNodes(NodesToRemove) = [];
         
         SelectedItems = cat(1,Tree.SelectedNodes.UserData);
         switch  unique(cellfun(@(x) numel(x), {Tree.SelectedNodes.UserData}))
            case 0  % tank
               setTankTable(obj);
               setTankTablePars(obj);
            case 1  % animal
               setAnimalTable(obj,SelectedItems);
               setAnimalTablePars(obj,SelectedItems);
            case 2  % block
               setBlockTable(obj,SelectedItems);
               setBlockTablePars(obj,SelectedItems);
         end
         
      end
      
      % Callback for when user clicks on tree interface
      function uiCMenuClick(obj,m,~)
         % UICMENUCLICK  Callback for when user clicks on tree interface
         %               context menu.
         %  
         %  m.Callback = @obj.uiCMenuClick;
         %
         %  obj  --  nigeLab.libs.DashBoard handle 
         %
         %  m  --  "Source" is matlab.ui.container.Menu object handle from
         %           parent matlab.ui.container.ContextMenu
         %           'treeContextMenu' that is a child of obj.nigelGui
         %
         %  ~  -- "EventData" is currently unused
         %
         %  Key fields of m:
         %  --> 'Label' :: Char array for the current 'do' method to run
         
         % Make a column vector of Animal Indices from any selected
         % (highlighted) animal node
         SelectedItems = cat(1,Tree.SelectedNodes.UserData);
         
         % Depending on what is in this array, we will run our extraction
         % methods at different levels (e.g. Tank vs Animal vs Block). We
         % can figure out what level was selected based on the number of
         % unique "counts" of UserData
         switch  unique(cellfun(@(x) numel(x), ...
               {Tree.SelectedNodes.UserData}))
            case 0  % tank
               obj.qOperations(m.Label,obj.Tank)
            case 1  % animal
               for ii=1:size(SelectedItems,1)
                  A = obj.Tank.Animals(SelectedItems(ii));
                  obj.qOperations(m.Label,A,SelectedItems(ii))
               end
            case 2  % block
               for ii = 1:size(SelectedItems,1)
                  B = obj.Tank.Animals( ...
                     SelectedItems(ii,1)).Blocks(SelectedItems(ii,2)); 
                  obj.qOperations(m.Label,B(ii),SelectedItems(ii,:));
               end
         end
      end

   end
   
   methods (Access = private, Static = true)
      % Method to add nodes to a given node
      function addToNode(nodeObj,name)
         % ADDTONODE  Adds nodes based on provided names to another node
         %
         %  nigeLab.libs.DashBoard.addToNode(nodeObj,name);
         %
         %  nodeObj  --  uiw.widget.CheckboxTreeNode handle object (an
         %                 existing node on a graphical tree)
         %
         %  name  --  char array or cell array of char arrays, defining the
         %              names of children nodes to add to nodeObj.
         
         % Check input
         switch class(nodeObj)
            case {'uiw.widget.Tree',...
                  'uiw.widget.CheckboxTree'}
               nodeObj = nodeObj.Root;
            
            case {'uiw.widget.TreeNode',...
                  'uiw.widget.CheckboxTreeNode'}
               % do nothing
            
            otherwise 
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Unexpected nodeObj input type: %s',class(nodeObj));
         end
 
         if ~iscell(name)
            name = {name};
         end
         
         % Add each block of a given animal. UserData can be used to index
         % nodes according to some larger hierarchy.
         if isnumeric(nodeObj.UserData)
            parentIndex = nodeObj.UserData;
         else
            parentIndex = [];
         end
         
         for jj=1:numel(name)
            uiw.widget.CheckboxTreeNode(...
               'Name',name{jj},...
               'Parent',nodeObj,...
               'UserData',[parentIndex, jj]);
         end
      end
   end
   
   methods (Access = public, Static = true)
      % Update status
      function updateStatus(bar,str)
         % UPDATESTATUS  Update status string
         %
         %  bar.updateStatus('statusText');
         
         bar.updateStatus(str);
      end
   end
end

