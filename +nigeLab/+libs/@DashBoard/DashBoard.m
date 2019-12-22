classdef DashBoard < handle
   % DASHBOARD  Class constructor for "DashBoard" UI that provides
   %            visual indicator of processing status for Tank,
   %            Animal, and Block objects, as well as a graphical
   %            interface to run extraction methods and visualize
   %            their current progress during remote execution.
   %
   %  tankObj = nigeLab.Tank();
   %  obj = nigeLab.libs.DashBoard(tankObj);
   
   %% PROPERTIES
   % PUBLIC
   % SetObservable properties of DashBoard: GUI and Color struct
   properties(SetAccess = private, GetAccess = public, SetObservable)
      nigelGUI       matlab.ui.Figure    % matlab.ui.Figure handle to user interface figure
      Color          struct              % Struct referencing colors
      SelectionIndex = [1 0 0]     % indexing of currently-selected items
   end
   
   % PUBLIC
   % Can only be set by methods of DashBoard
   properties(SetAccess = private, GetAccess = public)
      Children       cell                % Cell array of nigelPanels
      remoteMonitor  nigeLab.libs.remoteMonitor  % Monitor remote progress
   end
   
   properties(SetAccess = immutable, GetAccess = public)
      Tank           nigeLab.Tank        % Tank associated with this DashBoard
   end
   
   % PRIVATE
   % Object "children" of DashBoard etc
   properties(Access=private)
      Fields         cell        % Array of fields for this tank
      FieldType      cell        % Array of field type for this tank
      nigelButtons   nigeLab.libs.nigelButton  % Array of nigelButtons
      job            cell         % Cell array of Matlab job objects
      jobIsRunning = false;       % Flag indicating current job(s) state
      RecapAxes      matlab.graphics.axis.Axes  % "Recap" circles container
      RecapTable     uiw.widget.Table    % "Recap" table
      Tree           uiw.widget.Tree     % widget graphic for datasets as "nodes"
      splitMultiAnimalsUI  nigeLab.libs.splitMultiAnimalsUI % interface to split multiple animals
      treeContextMenu  matlab.ui.container.ContextMenu  % UI context menu for launching "do" actions
      Listener  event.listener    % Array of event listeners to delete on destruction
   end
   
   % RESTRICTED
   % For interaction with splitMultiAnimalsUI
   properties (Access = ?nigeLab.libs.splitMultiAnimalsUI, SetObservable)
      toSplit   % Struct array of Block and corresponding Animal to split
      toAdd     % Struct array of Block and corresponding Animal to add
   end
   
   %% EVENTS
   
   events
      TreeSelectionChanged       % Event issued when new node on Tree is clicked
   end
   
   %% METHODS
   % PUBLIC
   % Class Constructor and overloaded methods
   methods(Access = public)
      % Class constructor for nigeLab.libs.DashBoard
      function obj = DashBoard(tankObj)
         % DASHBOARD  Class constructor for "DashBoard" UI that provides
         %            visual indicator of processing status for Tank,
         %            Animal, and Block objects, as well as a graphical
         %            interface to run extraction methods and visualize
         %            their current progress during remote execution.
         %
         %  tankObj = nigeLab.Tank();
         %  obj = nigeLab.libs.DashBoard(tankObj);
         
         %% Check input
         if nargin < 1
            % Allow selection of TANK if not assigned directly
            tankObj = nigeLab.Tank();
         end
         
         %% Init
         obj.Tank = tankObj;
         obj.initRefProps();
         
         % Build all the panels and add the list of nigelObjects as a
         % uiw.widget.Tree to the "Tree" panel.
         obj.nigelGUI = obj.buildGUI();
         pTree = obj.getChild('TreePanel');
         obj.Tree = obj.buildTree(pTree);
         
         % Add the remote monitor to the "Queue" panel
         pQueue = obj.getChild('QueuePanel');
         obj.remoteMonitor=nigeLab.libs.remoteMonitor(tankObj,pQueue);
         obj.buildJavaObjs();
         
         % Nest the buttons in the "Tree" panel
         obj.buildButtons(pTree);
         
         % Create recap Table and container for "recap circles"
         pRecap = obj.getChild('StatsPanel');
         hOff = 0.025;
         vOff = 0.025;
         [obj.RecapTable,obj.RecapAxes] = obj.buildRecapObjects(pRecap,...
            hOff,vOff);
         
         %% Create title bar
         Position = [.01,.93,.98,.06];
         Btns = struct('String',  {'Home','Visualization Tools'},...
            'Callback',{''    ,''}); % ADD HOME / VISUAL CB HERE
         obj.Children{5} = nigeLab.libs.nigelBar(obj.nigelGUI,...
            'Position',Position,...
            'Tag','TitleBar',...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'StringColor',nigeLab.defaults.nigelColors('onprimary'),...
            'Buttons',Btns);
         
         %% Parameters UItabGroup
         h=uitabgroup();
         pParam = getChild(obj,'ParametersPanel');
         pParam.nestObj(h,'TabGroup');
         
         %% Set the selected node as the root node
         obj.Tree.SelectedNodes = obj.Tree.Root;
         Nodes.Nodes = obj.Tree.Root;
         Nodes.AddedNodes = obj.Tree.Root;
         treeSelectionFcn(obj,obj.Tree,Nodes)
         
         %% Add listeners
         obj.treeContextMenu = obj.initUICMenu();
         obj.Listener = obj.addAllListeners();
         
      end
      
      % Delete overload to handle child objects
      function delete(obj)
         % DELETE  Overloaded delete function to handle child objects
         %
         %  delete(obj);
         
         % Delete all listener handles
         obj.deleteListeners();
         
         % Delete anything associated with multianimals UI
         if ~isempty(obj.splitMultiAnimalsUI)
            if isvalid(obj.splitMultiAnimalsUI)
               delete(obj.splitMultiAnimalsUI);
            end
         end
         
         % Delete buttons
         if ~isempty(obj.nigelButtons)
            for b = obj.nigelButtons
               if isvalid(b)
                  delete(b);
               end
            end
         end
         
         % Delete remote monitor
         if ~isempty(obj.remoteMonitor)
            if isvalid(obj.remoteMonitor)
               delete(obj.remoteMonitor);
            end
         end
         
      end
      
      % Return the panel corresponding to a given tag
      % (e.g. getChild('TreePanel'))
      function panelHandle = getChild(obj,tagString)
         % GETCHILDPANEL  Return panel handle that corresponds to tagString
         %
         %  panelHandle = obj.getChild('nigels favorite panel');
         %  --> panelHandle returns handle to nigelPanel with Tag property
         %      of 'nigels favorite panel'
         %
         %  Options:
         %     Children{1}  <--> 'TreePanel'
         %     Children{2}  <--> 'StatsPanel'
         %     Children{3}  <--> 'QueuePanel'
         %     Children{4}  <--> 'ParametersPanel'
         %     Children{5}  <--> 'TitleBar'
         
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
            help('nigeLab.libs.DashBoard/getChild');
            error(['nigeLab:' mfilename ':badPropertyName'],...
               'Could not match nigelPanel Tag (%s).',tagString);
         end
      end
      
      % Return the current item selection
      function [block,animal] = getSelectedItems(obj,mode)
         % GETSELECTEDITEMS  Returns the currently-selected items from the
         %                   tree.
         %
         %  [block,animal] = obj.getSelectedItems(mode);
         %
         %  mode: default -- 'obj'
         %        * Can be 'index'
         %        * Can be 'name'
         %
         %  Returns Block and Animal objects corresponding to the selected
         %  Nodes (default). If a different mode is specified, such as
         %  'index' or 'name' then those corresponding properties are
         %  returned instead of the object handle arrays.
         
         if nargin < 2
            mode = 'obj';
         end
         switch lower(mode)
            case 'obj'
               block = [];
               animal = [];
               % SelectedItems will always have consistent # columns, since
               % "unlike" nodes are de-selected during treeSelectionFcn
               SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
               nCol = size(SelectedItems,2);
               switch  nCol
                  case 0  % tank
                     animal = obj.Tank{:};
                     block = obj.Tank{:,:};
                     
                  case 1  % animal
                     animal = obj.Tank{SelectedItems};
                     block = obj.Tank{SelectedItems,:};
                     
                  case 2  % block
                     animalIdx = unique(SelectedItems(:,1));
                     animal = obj.Tank{animalIdx};
                     block = obj.Tank{SelectedItems};
               end
            case 'index'
               SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
            case 'name'
               [B,A] = obj.getSelectedItems('obj');
               for i = 1:numel(B)
                  if isfield(B(i).Meta,'AnimalID') && ...
                        isfield(B(i).Meta,'RecID')
                     blockName = sprintf('%s.%s',...
                        B(i).Meta.AnimalID,...
                        B(i).Meta.RecID);
                  else
                     warning(['Missing AnimalID or RecID Meta fields. ' ...
                        'Using Block.Name instead.']);
                     blockName = strrep(B(i).Name,'_','.');
                  end
                  % target is nigelab.Block
                  blockName = blockName(1:min(end,...
                     B(i).Pars.Notifications.NMaxNameChars));
               end
               animal = {A.Name};
            otherwise
               error(['nigeLab:' mfilename ':badInputType3'],...
                  ['Unexpected "mode" value: ''%s''\n' ...
                  '(should be ''obj'', ''index'', or ''name'')'],mode);
         end % case
      end % getSelectedItems
      
   end
   
   % PRIVATE
   % Build or initialize elements of interface
   methods(Access = private)
      % Method to add all bars
      
      % Method to add all listeners
      function lh = addAllListeners(obj)
         % ADDALLLISTENERS  Add all the listeners and contain them in a
         %                  handle array that can be deleted on object
         %                  destruction.
         
         lh = [];
         lh = [lh, addlistener(obj.Tank,'StatusChanged',...
            @(~,~)obj.updateStatusTable)];
         lh = [lh, addlistener(obj.remoteMonitor,...
            'jobCompleted',@obj.refreshStats)];
         lh = [lh, addlistener(obj.splitMultiAnimalsUI,...
            'splitCompleted',@(~,e)obj.addToTree(e.nigelObj))];
         
         for a = obj.Tank.Animals
            lh = [lh, ...
               addlistener(a,'ObjectBeingDestroyed',...
               @obj.removeFromTree)];
            for b = a.Blocks
               lh = [lh, addlistener(b,'ObjectBeingDestroyed',...
                  @obj.removeFromTree)];
            end
         end
         lh = [lh, addlistener(obj.Tank,'ObjectBeingDestroyed',...
            @obj.removeFromTree)];
         
      end
      
      % Add a nigelObj to the tree
      function addToTree(obj,nigelObj)
         % ADDTOTREE  Add a nigelObj to the tree, for example after
         %            splitting multiple animals.
         %
         %  Typical syntax:
         %  lh = addlistener(obj.splitMultiAnimalsUI,...
         %                    'splitCompleted',...
         %                    @(~,e)obj.addToTree(e.nigelObj));
         
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
               
               % Add animal to the block
               addAnimal(obj.Tank.Animals,nigelObj(ii));
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
                  % actually add animals to block
                  obj.Tank.Animals(AnIndx).Blocks = [obj.Tank.Animals(AnIndx).Blocks, nigelObj];
               end
            otherwise
               error(['nigeLab:' mfilename ':unrecognizedClass'],...
                  'Unexpected class: %s',class(nigelObj));
         end
         
         nigeLab.libs.DashBoard.addToNode(animalNode,BlNames);
         obj.Tree = Tree; % Assign as property of DashBoard at end
      end
      
      % Add buttons to interface
      function buildButtons(obj,nigelPanelObj)
         % BUILDBUTTONS  Initialize/built buttons on interface panel
         
         if nargin < 2
            nigelPanelObj = obj.getChild('TreePanel');
         end
         
         % Make button axes for this nigelPanelObj (Tree panel)
         pos = nigelPanelObj.InnerPosition;
         pos = [pos(1) + pos(3) / 2, ...
            pos(2) + 0.05, ...
            pos(3) / 2, ...
            pos(4) * 0.15];
         ax = axes('Units','normalized', ...
            'Tag','ButtonAxes',...
            'Position', pos,...
            'Color',obj.Color.panel,...
            'XColor','none',...
            'YColor','none',...
            'NextPlot','add',...
            'XLimMode','manual',...
            'XLim',[0 1],...
            'YLimMode','manual',...
            'YLim',[0 1],...
            'FontName',nigelPanelObj.FontName);
         nigelPanelObj.nestObj(ax,'ButtonAxes');
         p = nigelPanelObj; % For shorter reference
         
         % Create array of nigelButtons
         obj.nigelButtons = [obj.nigelButtons, ...
            nigeLab.libs.nigelButton(p, [0.15 0.10 0.70 0.275],'Add'), ...
            ... % Add handle to 'ADD' function here               ^
            nigeLab.libs.nigelButton(p, [0.15 0.40 0.70 0.275],'Save'), ...
            ... % Add handle to 'SAVE' function here              ^
            nigeLab.libs.nigelButton(p, [0.15 0.70 0.70 0.275],'Split',...
            @obj.toggleSplitMultiAnimalsUI,'start')];
         
         setButton(obj.nigelButtons,'Add','Enable','off');  % (WIP)
         setButton(obj.nigelButtons,'Save','Enable','off'); % (WIP)
         if obj.SelectionIndex(1,2) == 0
            setButton(obj.nigelButtons,'Split','Enable','off');
         else
            setButton(obj.nigelButtons,'Split','Enable','on');
         end
         
         obj.Listener = [obj.Listener, ...
            addlistener(obj,'SelectionIndex','PostSet',...
            @(~,~)obj.toggleSplitUIMenuEnable)];
         
      end
      
      % Method to create figure for UI as well as panels that serve as
      % containers for the rest of the UI contents
      function fig = buildGUI(obj,fig)
         % LOADPANELS  Method to create all custom uipanels (nigelPanels)
         %             that populate most of the GUI interface.
         %
         %  obj = nigeLab.libs.Dashboard(tankObj);
         %  obj.buildGUI;   (From method of obj; make appropriate panels)
         %  obj.buildGUI(fig);  Optional: fig allows pre-specification of
         %                                figure handle
         %
         %  obj.Children{1} <--> 'TreePanel'
         %  obj.Children{2} <--> 'StatsPanel'
         %  obj.Children{3} <--> 'QueuePanel'
         %  obj.Children{4} <--> 'ParametersPanel'
         
         %% Check input
         if nargin < 2
            fig = figure('Units','Normalized',...
               'Position',[0.1 0.1 0.8 0.8],...
               'Color',obj.Color.fig,...
               'ToolBar','none',...
               'MenuBar','none',...
               'DeleteFcn',@(~,~)obj.delete);
         end
         
         %% Tree Panel
         % Panel where animals, blocks and the tank are visualized
         str    = {'TreePanel'};
         strSub = {''};
         Tag      = 'TreePanel';
         Position = [.01,.01,.33,.91];
         %[left bottom width height]
         obj.Children{1} = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
         
         %% Stats Pannel
         str    = {'StatsPanel'};
         strSub = {''};
         Tag      = 'StatsPanel';
         Position = [.35, .45, .43 ,.47];
         obj.Children{2} = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
         
         %% Queue Panel
         str    = {'QueuePanel'};
         strSub = {''};
         Tag      = 'QueuePanel';
         Position = [.35, .01, .43 , .43];
         obj.Children{3} = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'),...
            'Scrollable','on');
         
         %% Parameters Panel
         str    = {'ParametersPanel'};
         strSub = {''};
         Tag      = 'ParametersPanel';
         Position = [.79 , .01, .2, 0.91];
         obj.Children{4} = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
         
      end
      
      % Build Java objects associated with Tree object
      function buildJavaObjs(obj)
         % BUILDJAVAOBJS  Builds the Java objects associated with Tree
         %
         %  obj.buildJavaObjs(); Should just be called in constructor
         
         % Cosmetic adjustments
         Jobjs = obj.Tree.getJavaObjects;
         Jobjs.JScrollPane.setBorder(...
            javax.swing.BorderFactory.createEmptyBorder)
         Jobjs.JScrollPane.setComponentOrientation(...
            java.awt.ComponentOrientation.RIGHT_TO_LEFT);
      end
      
      % Construct recap table for recording
      function [recapTable,recapAx] = buildRecapObjects(obj,nigelPanelObj,hOff,vOff)
         % BUILDRECAPOBJECTS  Construct "recap table" for displaying basic
         %                    info about the recording, and "recap axes"
         %                    for containing the result of PLOTRECAPCIRCLES
         %
         %  recapTable = obj.buildRecapTable(); Return recaptable uiw
         %  recapTable = obj.buildRecapTable(hOff,vOff);
         %  Set horizontal and vertical offset respectively (distance from
         %     left side of panel to left side of table, or from bottom to
         %     bottom, in normalized units).
         
         if nargin < 4
            vOff = .025;
         end
         
         if nargin < 3
            hOff = .025;
         end
         
         if nargin < 2
            nigelPanelObj = obj.getChild('StatsPanel');
         end
         
         ppos = nigelPanelObj.InnerPosition;
         tab_pos = ppos .* [1 1 1 .5] + [hOff vOff+.7 -hOff*2 -vOff*10];
         recapTable = uiw.widget.Table(...
            'Parent',nigelPanelObj.Panel,...
            'CellEditCallback',[],...
            'CellSelectionCallback',[],...
            'Units','normalized', ...
            'Position',tab_pos,...
            'BackgroundColor',obj.Color.panel,...
            'FontName','Droid Sans');
         nigelPanelObj.nestObj(recapTable);
         RecapTableMJScrollPane = recapTable.JControl.getParent.getParent;
         RecapTableMJScrollPane.setBorder(...
            javax.swing.BorderFactory.createEmptyBorder);
         
         ax_pos = ppos .* [1 1 1 .5] + [hOff vOff -hOff*2 -vOff*4];
         recapAx = axes(nigelPanelObj.Panel,...
            'Units','normalized', ...
            'Position', ax_pos,...
            'Tag','RecapAxes',...
            'Color','none',...
            'TickLength',[0 0],...
            'XTickLabels',[],...
            'XAxisLocation','top',...
            'LineWidth',0.005,...
            'GridColor','none',...
            'XColor',obj.Color.onPanel,...
            'YColor',obj.Color.onPanel,...
            'Box','off',...
            'FontName','DroidSans',...
            'FontSize',13,...
            'FontWeight','bold');
         recapAx.XAxis.TickLabelRotation = 75;
         
         % axes cosmetic adjustment
         nigelPanelObj.nestObj(recapAx,'RecapAxes');
         drawnow;
      end
      
      % Initializes the graphics tree widget
      function Tree = buildTree(obj,nigelPanelObj)
         % BUILDTREE  Method to initialize tree
         %
         %  Tree = obj.buildTree(); Automatically puts Tree in "Tree" panel
         %  Tree = obj.buildTree(nigelPanelObj); Puts tree in assigned
         %                                       nigelPanelObj.
         
         if nargin < 2
            nigelPanelObj = obj.getChild('TreePanel');
         end
         
         pos = nigelPanelObj.InnerPosition;
         pos(3) = pos(3)/2;
         Tree = uiw.widget.Tree(...
            'SelectionChangeFcn',@obj.treeSelectionFcn,...
            'Units', 'normalized', ...
            'Position',pos,...
            'FontName','Droid Sans',...
            'FontSize',15,...
            'Tag','Tree',...
            'ForegroundColor',obj.Color.onPanel,...
            'TreePaneBackgroundColor',obj.Color.panel,...
            'BackgroundColor',obj.Color.panel,...
            'TreeBackgroundColor',obj.Color.panel,...
            'Units','normalized',...
            'SelectionType','discontiguous');
         
         Tree.Root.Name = obj.Tank.Name;
         
         % Add animals to tank Tree
         animalObj = obj.Tank.Animals;
         for ii = 1:numel(animalObj)
            animalNode = uiw.widget.CheckboxTreeNode(...
               'Name',animalObj(ii).Name,...
               'Parent',Tree.Root,...
               'UserData',ii);
            
            names = obj.getName(animalObj(ii),'Block');
            nigeLab.libs.DashBoard.addToNode(animalNode,names);
         end
         
         nigelPanelObj.nestObj(Tree,Tree.Tag);
         obj.Tree = Tree; % Assign as property of DashBoard at end
      end
      
      % CloseRequestFcn handler to ensure that extra objects are
      % destroyed when the interface is closed
      function deleteDashBoard(obj)
         % DELETEDASHBOARD  CloseRequestFcn assigned property to ensure
         %                  that things get deleted properly.
         %
         %  fig.CloseRequestFcn = @obj.deleteDashBoard;  Just deletes obj
         
         delete(obj);
      end
      
      % Delete all current listener handles
      function deleteListeners(obj)
         % DELETELISTENERS  Deletes all current listener handles
         %
         %  obj.deleteListeners();
         
         for lh = obj.Listener
            delete(lh);
         end
         obj.Listener(:) = [];
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
      
      % Initialize reference proprety values
      function initRefProps(obj)
         % INITREFPROPS  Initialize property values for referencing later
         %
         %  obj.initRefProps(tankObj);  Takes references from parameters of
         %                                tankObj, which should be
         %                                identical for all Blocks and
         %                                Animals that are under
         %                                consideration by DashBoard.
         
         obj.Color = nigeLab.libs.DashBoard.initColors();
         obj.Fields = obj.Tank.Pars.Block.Fields;
         obj.FieldType = obj.Tank.Pars.Block.FieldType;
      end
      
      % Creates the "recap circles" (rectangles with rounded edges that
      % look nice) for displaying the current status of different
      % processing stages. This should behave differently depending on if a
      % Tank, Animal, or Block node has been selected.
      function plotRecapCircle(obj,Status,N)
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
         %
         %  N   -- # Animals or # Channels (if single block)
         
         ax = obj.RecapAxes;
         cla(ax);
         
         if nargin < 3
            N = 1;
         end
         
         nField = numel(obj.Fields);
         
         
         switch class(Status)
            case 'cell'
               xlim(ax,[1 nField+1]);
               ylim(ax,[1 N+1]);
               obj.RecapAxes.YColor = 'none';
               
               for ii=1:nField
                  switch numel(Status{ii})
                     case 1
                        if Status{ii}
                           rectangle(ax,'Position',[ii 1 .97 N*0.97],...
                              'Curvature',[0.3 0.6],...
                              'FaceColor',nigeLab.defaults.nigelColors(1),...
                              'LineWidth',1.5,...
                              'EdgeColor',[.2 .2 .2]);
                        else
                           rectangle(ax,'Position',[ii 1 1 N],...
                              'Curvature',[0.3 0.6],...
                              'FaceColor',[nigeLab.defaults.nigelColors(2) 0.4],...
                              'EdgeColor','none');
                        end
                     otherwise
                        for jj = 1:numel(Status{ii})
                           if Status{ii}(jj)
                              rectangle(ax,'Position',[ii N+1-jj .97 .97],...
                                 'Curvature',[0.3 0.6],...
                                 'FaceColor',nigeLab.defaults.nigelColors(1),...
                                 'LineWidth',1.5,...
                                 'EdgeColor',[.2 .2 .2]);
                           else
                              rectangle(ax,'Position',[ii N+1-jj 1 1],...
                                 'Curvature',[0.3 0.6],...
                                 'FaceColor',[nigeLab.defaults.nigelColors(2) 0.4],...
                                 'EdgeColor','none');
                           end % if
                        end % jj
                  end % case
                  
               end % ii
               
               
               
            case 'logical'
               [N,~] = size(Status);
               xlim(ax,[1 nField+1]);
               ylim(ax,[1 N+1]);
               obj.RecapAxes.YColor = obj.Color.onPanel;
               for jj=1:N
                  for ii=1:nField
                     if Status(jj,ii)
                        rectangle(ax,'Position',[ii N+1-jj .97 .97],...
                           'Curvature',[0.3 0.6],...
                           'FaceColor',nigeLab.defaults.nigelColors(1),...
                           'LineWidth',1.5,...
                           'EdgeColor',[.2 .2 .2]);
                     else
                        rectangle(ax,'Position',[ii N+1-jj 1 1],...
                           'Curvature',[0.3 0.6],...
                           'FaceColor',[nigeLab.defaults.nigelColors(2) 0.4],...
                           'EdgeColor','none');
                     end % if
                  end % ii
               end % jj
            case 'double'
               Status = logical(Status);
               obj.plotRecapCircle(Status,N);
            otherwise
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Unexpected Status class: %s',class(Status));
         end
         
         ax.XAxis.TickLabel = obj.Fields;
         ax.YAxis.TickLabel = cellstr( num2str((1:N)'));
         ax.XAxis.TickValues = 1.5:nField+0.5;
         ax.YAxis.TickValues = 1.5:N+0.5;
      end
      
      % This function wraps any of the "do" methods of Block, allowing them
      % to be added to a job queue for parallel and/or remote processing
      function qOperations(obj,operation,target,sel)
         % QOPERATIONS  Wrapper for "do" methods of Block, for adding to
         %              jobs to a queue for parallel and/or remote
         %              processing.
         %
         %  nigeLab.DashBoard.qOperations(operation,target);
         %  nigeLab.DashBoard.qOperations(operation,target,sel);
         %
         %  inputs:
         %  operation  --  "do" method function handle
         %  target  --  ULTIMATELY, A BLOCK OR ARRAY OF BLOCKS. Can be
         %                 passed as: Tank, Animal, Block or Block array.
         %  sel  --  Indexing into subset of tanks or blocks to
         %              use. Should be set as a two-element column vector,
         %              where the first index references animal and second
         %              references block
         
         % Set indexing to assign to UserData property of Jobs, so that on
         % job completion the corresponding "jobIsRunning" property array
         % element can be updated appropriately.
         if nargin < 4
            sel = [1 1];
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
                  qOperations(obj,operation,target.Blocks(ii),[sel ii]);
               end
               
            case 'nigeLab.Block'
               
               % checking licences and parallel flags to determine where to execute the
               % computation. Three possible outcomes:
               % local - Serialized
               % local - Distributed
               % remote - Distributed
               target.updateParams('Queue');
               [~,nPars] = target.updateParams('Notifications');
               qParams = target.Pars.Queue;
               opLink = nigeLab.utils.getNigeLink('nigeLab.Block',operation);
               if qParams.UseParallel...              check user preference
                     && license('test','Distrib_Computing_Toolbox')... check if toolbox is licensed
                     && ~isempty(ver('distcomp'))...           and check if it's installed
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  %% Configure remote or local cluster for correct parallel computation
                  lineNum = dbstack();
                  lineNum = lineNum(1).line+61;
                  lineLink = nigeLab.utils.getNigeLink(...
                     'nigeLab.libs.DashBoard/qOperations',lineNum,...
                     '(Parallel)');
                  fprintf(1,'Initializing %s job: %s - %s\n',...
                     lineLink,opLink,target.Name);
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
                  
                  n = min(nPars.NMaxNameChars,numel(target.Name));
                  name = target.Name(1:n);
                  name = strrep(name,'_','-');
                  
                  tagStr = reportProgress(target,'Queuing',0);
                  job = createCommunicatingJob(myCluster, ...
                     'AttachedFiles', attachedFiles, ...
                     'Name', [operation target.Name], ...
                     'NumWorkersRange', qParams.NWorkerMinMax, ...
                     'Type','pool', ...
                     'UserData',sel,...
                     'Tag',tagStr); %#ok<*PROPLC>
                  
                  blockName = sprintf('%s.%s',target.Meta.AnimalID,...
                     target.Meta.RecID);
                  % target is nigelab.Block
                  blockName = blockName(1:min(end,nPars.NMaxNameChars));
                  barName = sprintf('%s %s',blockName,operation(3:end));
                  bar = obj.remoteMonitor.startBar(barName,sel,job);
                  bar.setState(0,'Pending...')
                  
                  % Assign callbacks to update labels and timers etc.
                  job.FinishedFcn=@(~,~)obj.remoteMonitor.barCompleted(bar);
                  job.QueuedFcn=@(~,~)bar.setState(bar,0,'Queuing...');
                  job.RunningFcn=@(~,~)bar.setState(bar,0,'Running...');
                  
                  createTask(job,operation,0,{target});
                  submit(job);
                  fprintf(1,'%s Job running: %s - %s\n',...
                     lineLink,opLink,target.Name);

               else
                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  %% otherwise run single operation serially
                  lineNum = dbstack();
                  lineNum = lineNum(1).line+18;
                  lineLink = nigeLab.utils.getNigeLink(...
                     'nigeLab.libs.DashBoard/qOperations',lineNum,...
                     '(Non-Parallel)');
                  fprintf(1,'%s Job running: %s - %s\n',...
                     lineLink,opLink,target.Name);
                  % (target is scalar nigeLab.Block)
                  blockName = sprintf('%s.%s',target.Meta.AnimalID,...
                     target.Meta.RecID);
                  blockName = blockName(1:min(end,nPars.NMaxNameChars));
                  barName = sprintf('%s %s',blockName,operation(3:end));
                  starttime = clock();
                  bar = obj.remoteMonitor.startBar(barName,sel);
                  bar.setState(0,'Pending...');
                  lh = addlistener(bar,'JobCanceled',...
                     @(~,~)target.invokeCancel);
                  try
                     feval(operation,target);
                     flag = true;
                  catch me
                     flag = false;
                     warning('Task failed with following error:');
                     disp(me);
                     for i = 1:numel(me.stack)
                        disp(me.stack(i));
                     end
                     obj.remoteMonitor.stopBar(bar);
                     s = struct;
                     s.message = me.message;
                     s.identifier = me.identifier;
                     s.stack = me.stack;
                     lasterror(s); %#ok<LERR> % Set the last error struct
                  end
                  if flag
                     delete(lh);
                     field = target.getOperationField(operation);
                     if ~iscell(field)
                        field = {field};
                     end
                     if ~isempty(field) && ~any(target.Status.(field{1}))
                        linkToData(target,field);
                     end
                  end
                  % Since it is SERIAL, bar will be updated
                  if flag
                     obj.remoteMonitor.stopBar(bar);
                  end
               end
               
            otherwise
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Invalid target class: %s',class(target));
         end
         drawnow;
         
      end
      
      % Translates "SelectedItems" (nodes UserData) to "selection index"
      function sel = selectedItems2Index(obj,items)
         % SELECTEDITEMS2INDEX  Returns the "indexing" for SelectedItems
         %                       from UserData of nodes on obj.Tree
         %
         %  sel = obj.selectedItems2Index(items);
         
         % tankObj
         if isempty(items)
            sel = [1 0 0];
            return;
         end
         
         % animalObj
         if size(items,2) == 1
            sel = ones(size(items,1),3);
            A = obj.Tank.Animals;
            k = 0;
            for i = 1:size(items,1)
               a = A(items(i));
               B = a.Blocks;
               for ii = 1:numel(B)
                  k = k + 1;
                  sel(k,[2,3]) = [items(i), ii];
               end
            end
            return;
         end
         
         % blockObj
         if size(items,2) == 2
            sel = ones(size(items,1),3);
            sel(:,[2,3]) = items;
            return;
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
         
         % Prevent bad concatenation things
         NodesToRemove = not(AllNodeType==OldNodeType);
         Tree.SelectedNodes(NodesToRemove) = [];
         
         SelectedItems = cat(1,Tree.SelectedNodes.UserData);
         obj.SelectionIndex = obj.selectedItems2Index(SelectedItems);
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
      
      % LISTENER CALLBACK: Method to remove an object from the tree
      function Tree = removeFromTree(obj,src,~)
         % REMOVEFROMTREE  Method to remove a deleted nigelObj from tree.
         %
         %  addlistener(nigelObj,...
         %     'ObjectBeingDestroyed',@obj.removeFromTree);
         
         Tree = obj.Tree;
         switch class(src)
            case 'nigeLab.Tank'
               ...
            case 'nigeLab.Animal'
            A=obj.Tank.Animals;
            indx = find(src == A);
            
            obj2del = obj.Tree.Root.Children(indx);
            if obj2del.Name == src.Name % useless check  but just to be sure
               delete(obj2del);
               UserData = cellfun(@(x) x-1,{obj.Tree.Root.Children(indx:end).UserData},'UniformOutput',false);
               [obj.Tree.Root.Children(indx:end).UserData]=deal(UserData{:});
            else
               nigeLab.utils.cprintf('SystemCommands','There is mimatch between the tank loaded in the dashboard and the one in memory.\n Try to reload it!');
            end
            
            case 'nigeLab.Block'
               A=obj.Tank.Animals;
               indx = cellfun(@(x,idx)[idx*logical(find(src==x)) find(src==x)],{A.Blocks},num2cell(1:numel(A)),'UniformOutput',false);
               indx = [indx{cellfun(@(x) ~isempty(x),indx)}];
               obj2del = obj.Tree.Root.Children(indx(1)).Children(min(indx(2),end));
               if obj2del.Name == src.Meta.RecID % useless check  but just to be sure
                  delete(obj2del);
                  UserData = cellfun(@(x) x-[0 1],{obj.Tree.Root.Children(indx(1)).Children(indx(2):end).UserData},'UniformOutput',false);
                  [obj.Tree.Root.Children(indx(1)).Children(indx(2):end).UserData]=deal(UserData{:});
               else
                  nigeLab.utils.cprintf('SystemCommands','There is mimatch between the tank loaded in the dashboard and the one in memory.\n Try to reload it!');
               end
         end
         
         
      end
      
      % Toggles the split UI menu button depending on nodes that are click
      function toggleSplitUIMenuEnable(obj)
         % TOGGLESPLITUIMENUENABLE  Toggles the split UI menu depending on
         %                          what is clicked.
         %
         %  Syntax:
         %  addlistener(obj,'SelectionIndex','PostSet',...
         %                 @(~,~)obj.toggleSplitUIMenuEnable);
         
         % If TANK is clicked, disable
         if obj.SelectionIndex(1,2) == 0
            setButton(obj.nigelButtons,'Split','Enable','off');
            return;
         end
         
         A = obj.Tank.Animals;
         if all([A(obj.SelectionIndex(:,2)).MultiAnimals])
            % Only enable the button if ALL are multi-animals
            setButton(obj.nigelButtons,'Split','Enable','on');
         else
            setButton(obj.nigelButtons,'Split','Enable','off');
         end
      end
      
      function setUIContextMenuVisibility(obj,src,evt)
         % SETUICONTEXTMENUVISIBILITY  Set UI Context menu Visibility
         
         % SelectedItems = cat(1,src.SelectedNodes.UserData);
         switch  unique(cellfun(@(x) numel(x),...
               {src.SelectedNodes.UserData}))
            case 0  % tank
               ...
            case 1  % animal
            ...
            case 2  % block
            ...
         end
      
      % Set menuItems active or inactive
      menuItems = {src.UIContextMenu.Children.Label};
      
      indx = (startsWith(menuItems,'do'));
      
      
      [src.UIContextMenu.Children(indx).Enable] = deal('on');
      [src.UIContextMenu.Children(~indx).Enable] = deal('off');
      end
      
   end
   
   % MultiAnimals methods
   methods (Access = ?nigeLab.libs.splitMultiAnimalsUI)
      % Callback that toggles the split multi animals UI on or off
      function toggleSplitMultiAnimalsUI(obj,mode)
         % TOGGLESPLITMULTIANIMALSUI  Toggle the split multi animals UI on
         %                            or off.
         %
         %  Assignment syntax:
         %  b.ButtonDownFcn = ...
         %     {@(~,~,str) obj.toggleSplitMultiAnimalsUI(str),'start'};
         %
         %  Where 'start' corresponds to a fixed instantiation of "mode"
         %  input, as desired for the application.
         
         switch mode
            case 'start'
               SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
               switch  unique(cellfun(@(x) numel(x), {obj.Tree.SelectedNodes.UserData}))
                  case 0  % tank
                     idx= find([obj.Tank.Animals.MultiAnimals],1);
                     obj.Tree.SelectedNodes = obj.Tree.Root.Children(idx).Children(1);
                  case 1  % animal
                     
                     % If this animal is a "multi-animal" Animal, then
                     % cycle through its children, finding "multi-animal"
                     % blocks.
                     if obj.Tank.Animals(SelectedItems).MultiAnimals
                        obj.Tree.SelectedNodes = obj.Tree.SelectedNodes.Children(1);
                     else
                        errordlg('This is not a multiAnimal!');
                        return;
                     end % if MultiAnimals
                     
                     
                  case 2  % block
                     if ~obj.Tank.Animals(SelectedItems(1)).Blocks(SelectedItems(2)).MultiAnimals
                        errordlg('This is not a multiAnimal!');
                        return;
                     end % if ~MultiAnimals
               end % case
               
               % Ensure that only 1 "child" object is selected at a time
               obj.getChild('TreePanel').getChild('Tree').SelectionType = 'single';
               if isvalid(obj.splitMultiAnimalsUI)
                  obj.splitMultiAnimalsUI.toggleVisibility;
                  return;
               else
                  % 'start' is only entered via button-click
                  toggleSplitMultiAnimalsUI(obj,'init');
               end % if isvalid
               
               % TODO disable nodes without multiAnimal flag!
               %                    [obj.Tree.Root.Children(find([obj.Tank.Animals.MultiAnimals])).Enable] = deal('off');
            case 'stop'
               obj.getChild('TreePanel').getChild('Tree').SelectionType = ...
                  'discontiguous';
               % TODO reenable nodes without multiAnimal flag!
               if any([obj.Tank.Animals.MultiAnimals])
                  obj.splitMultiAnimalsUI.toggleVisibility;
               else
                  delete( obj.splitMultiAnimalsUI.Fig);
                  delete(obj.splitMultiAnimalsUI);
               end
               
            case 'init'
               % First, make sure the selection is valid
               
               % The multiAnimalsUI must be opened
               SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
               % Note that SelectedItems only contains nodes of a specific
               % type, based on exclusion done in `treeSelectionFcn`.
               % Therefore the vertical concatenation above is always valid
               nCol = size(SelectedItems,2);
               switch  nCol
                  case 0  % tank
                     % Cannot be invoked at "TANK" level
                     error(['nigeLab:' mfilename ':badCase'],...
                        'Should not be able to enter split UI from TANK level.');
                  case 1  % animal
                     % Gets all blocks of selected animals
                     B = obj.Tank{SelectedItems(1),:};
                     A = repmat(obj.Tank{SelectedItems(1)},1,numel(B));
                     for i = 1:numel(SelectedItems)
                        b = obj.Tank{SelectedItems(i),:};
                        B = [B, b];
                        A = [A, ...
                           repmat(obj.Tank{SelectedItems(i)},1,numel(b))];
                     end
                     
                  case 2  % block
                     % Get specific subset of block or blocks
                     A = obj.Tank{SelectedItems(:,1)};
                     B = obj.Tank{SelectedItems};
               end % switch nCol
               
               if ~all([A.MultiAnimals])
                  return;
               end
               
               if ~all([B.MultiAnimals])
                  return;
               end
               
               obj.toSplit = struct('Animal',cell(numel(A),1),...
                  'Block',cell(numel(B),1));
               for i = 1:numel(obj.toSplit)
                  obj.toSplit(i).Animal = A(i);
                  obj.toSplit(i).Block = B(i);
               end
               obj.toAdd = struct('Animal',{},'Block',{});
               
               obj.splitMultiAnimalsUI = ...
                  nigeLab.libs.splitMultiAnimalsUI(obj);
               
         end % switch mode
      end
      
   end
   
   % PRIVATE
   % Methods associated with the "Tables"
   methods (Access = private)
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
         
         idx = evt.BlockSelectionIndex;
         obj.Tank.Animals(idx(1)).Blocks(idx(2)).reload;
         selEvt = struct('Nodes',obj.Tree.SelectedNodes,...
            'AddedNodes',obj.Tree.SelectedNodes);
         obj.treeSelectionFcn(obj.Tree, selEvt)
      end
      
      % "Reload" the tank (likely multi-animal-related)
      function reloadTank(obj)
         % RELOADTANK  "Reload" the tank object (probably for multi-animals
         %              stuff)
         %
         %  obj.reloadTank();
         
         %             [block,animal] = getSelectedItems(obj,'index');
         load([obj.Tank.Paths.SaveLoc '_tank.mat'],'tankObj');
         obj.Tank = tankObj;
         delete(obj.Tree);
         obj.Tree = obj.initTankTree();
      end
      
      % Update the status table for TANK, ANIMAL, or BLOCK
      function updateStatusTable(obj,~)
         %UPDATESTATUSTABLE  Update status table for TANK, ANIMAL, or BLOCK
         %
         %
         
         SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
         nCol = size(SelectedItems,2);
         switch  nCol
            case 0  % tank
               setTankTable(obj);
            case 1  % animal
               setAnimalTable(obj,SelectedItems);
            case 2  % block
               setBlockTable(obj,SelectedItems);
         end
         
      end
      
      % Set the "TANK" table -- the display showing processing status
      function setTankTable(obj,~)
         % SETTANKTABLE    Creates "TANK" table for currently-selected
         %                 NODE, indicating the current state of processing
         %                 for a given nigeLab.Animal object.
         %
         %  obj.setTankTable();
         
         tt = obj.Tank.list;
         tCell = table2cell(tt);
         Status = obj.Tank.getStatus(obj.Fields);
         StatusIndx = strcmp(tt.Properties.VariableNames,'Status');
         tCell = tCell(:,not(StatusIndx));
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
         dates_idx = strcmp(columnFormatsAndData,'datetime');
         recDates = tCell(:,dates_idx);
         recmonths = cellfun(@(x) month(x,'shortname'),recDates,'UniformOutput',false);
         tmp = cellfun(@(x) {strjoin(unique(x),',')},recmonths,'UniformOutput',false);
         tCell(:,strcmp(columnFormatsAndData,'datetime')) = tmp;
         columnFormatsAndData{strcmp(columnFormatsAndData,'datetime')} = 'cell';
         [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell,'Tank');
         
         w = obj.RecapTable;
         w.ColumnName = tt.Properties.VariableNames(not(StatusIndx)); %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;
         plotRecapCircle(obj,Status,1);
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
         f = A(1).Blocks(1).Fields;
         tCell = [];
         Status = [];
         for ii=1:numel(A)
            tt = A(ii).list;
            tCell = [tCell; table2cell(tt)];
            Status = [Status; A(ii).getStatus(obj.Fields)];
         end
         nonStatusCols = ~strcmp(tt.Properties.VariableNames,'Status');
         tCell = tCell(:,nonStatusCols);
         header = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
         
         % Put "non-Status" elements of list into table format for Recap
         [tCell, header] = uxTableFormat(header(nonStatusCols),tCell,'Animal');
         
         w = obj.RecapTable;
         w.ColumnName = tt.Properties.VariableNames(nonStatusCols);
         w.ColumnFormat = header(:,1);
         w.ColumnFormatData = header(:,2);
         w.Data = tCell;
         plotRecapCircle(obj,Status,numel(A));
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
         
         B = obj.Tank{SelectedItems};
         tt = list(B);
         tCell = table2cell(tt);
         s = getStatus(B,obj.Fields);
         if numel(B) == 1
            Status = cell(size(s));
            iCh = B.getFieldTypeIndex('Channels');
            for i = 1:numel(Status)
               if iCh(i)
                  Status{i} = B.getStatus(obj.Fields{i});
               else
                  Status{i} = s(i);
               end
            end
            nCh = B.NumChannels;
         else
            Status = s;
            nCh = 1;
         end
         StatusIndx = strcmp(tt.Properties.VariableNames,'Status');
         tCell = tCell(:,not(StatusIndx));
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
         [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell,'Block');
         
         w = obj.RecapTable;
         w.ColumnName = tt.Properties.VariableNames(not(StatusIndx)); %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;
         
         plotRecapCircle(obj,Status,nCh);
         
      end
      
      % Updates the 'ParametersPanel' panel with current TANK parameters
      function setTankTablePars(obj)
         % SETTANKTABLEPARS  Display the parameters for TANK
         %
         %  obj.setTankTablePars
         
         T = obj.Tank;
         parPanel = getChild(obj,'ParametersPanel');
         h =  parPanel.Children{1};
         delete(h.Children);
         ActPars = T.Pars;
         
         dd=struct2cell(ActPars);
         inx=cellfun(@(x) (isnumeric(x) && isscalar(x))||islogical(x)||ischar(x), dd);
         
         ff =fieldnames(ActPars);
         if any(inx)
            tab1 = uitab(h,'Title','Pars');
            uit = uitable(tab1,'Units','normalized',...
               'Position',[0 0 1 1],'Data',[cell(sum(inx),1),ff(inx),dd(inx),cell(sum(inx),1)],...
               'RowName',[],'ColumnWidth',{2,'auto','auto',2});
         end
         pos = getpixelposition(uit);
         width = pos(3) - 4;
         
         uit.ColumnWidth{2} = width*0.2;
         uit.ColumnWidth{3} = width*0.725;
      end
      
      % Updates the 'ParametersPanel' panel with current ANIMAL parameters
      function setAnimalTablePars(obj,SelectedItems)
         % SETANIMALTABLEPARS  Display parameters for selected ANIMAL(s)
         %
         %  obj.setAnimalTablePars(SelectedItems);
         %
         %  SelectedItems  --  Subset of nodes corresponding to
         %                     currently-selected nigeLab.Animal objects.
         %                    --> This is an indexing array
         
         A = obj.Tank.Animals(SelectedItems);
         pParam = getChild(obj,'ParametersPanel');
         h =  pParam.Children{1};
         delete(h.Children);
         ActPars = A.Pars;
         
         dd=struct2cell(ActPars);
         inx=cellfun(@(x) (isnumeric(x) && isscalar(x))||islogical(x)||ischar(x), dd);
         
         ff =fieldnames(ActPars);
         if any(inx)
            tab1 = uitab(h,'Title','Pars');
            InnerPos = getpixelposition(tab1) .*tab1.Position;
            uit = uitable(tab1,'Units','normalized',...
               'Position',[0 0 1 1],...
               'Data',[cell(sum(inx),1),ff(inx),dd(inx),cell(sum(inx),1)],...
               'RowName',[],'ColumnWidth',{2,'auto','auto',2});
         end
         pos = getpixelposition(uit);
         width = pos(3) - 4;
         
         uit.ColumnWidth{2} = width*0.2;
         uit.ColumnWidth{3} = width*0.725;
         
         % init splitmultianimals interface
         toggleSplitMultiAnimalsUI(obj,'init');
         
      end
      
      % Updates the 'ParametersPanel' panel with current BLOCK parameters
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
         Pan = getChild(obj,'ParametersPanel');
         h =  Pan.Children{1};
         delete(h.Children);
         for ii=1:numel(Fnames)
            ActPars = B.Pars.(Fnames{ii});
            
            
            dd=struct2cell(ActPars);
            inx=cellfun(@(x) (isnumeric(x) && isscalar(x))||islogical(x)||ischar(x), dd);
            
            ff =fieldnames(ActPars);
            if any(inx)
               tab1 = uitab(h,'Title',Fnames{ii});
               uit = uitable(tab1,'Units','normalized',...
                  'ColumnName',{'--','Parameter','Value','--'},...
                  'Position',[0 0 1 1],...
                  'Data',[cell(sum(inx),1),ff(inx),dd(inx),cell(sum(inx),1)],...
                  'RowName',[],'ColumnWidth',{2,'auto','auto',2});
            end
            pos = getpixelposition(uit);
            width = pos(3) - 4;
            
            uit.ColumnWidth{2} = width*0.2;
            uit.ColumnWidth{3} = width*0.725;
         end
      end
      
   end
   
   % PRIVATE
   % Methods for UI Context Interactions (mostly callbacks)
   methods(Access = private)
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
         %           'treeContextMenu' that is a child of obj.nigelGUI
         %
         %  ~  -- "EventData" is currently unused
         %
         %  Key fields of m:
         %  --> 'Label' :: Char array for the current 'do' method to run
         
         % Make a column vector of Animal Indices from any selected
         % (highlighted) animal node
         SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
         
         % Depending on what is in this array, we will run our extraction
         % methods at different levels (e.g. Tank vs Animal vs Block). We
         % can figure out what level was selected based on the number of
         % unique "counts" of UserData
         switch  unique(cellfun(@(x) numel(x), ...
               {obj.Tree.SelectedNodes.UserData}))
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
               
               for ii=1:size(SelectedItems,1)
                  A = obj.Tank.Animals(SelectedItems(ii));
                  obj.qOperations(m.Label,A,SelectedItems(ii))
               end
            case 2  % block
               for ii = 1:size(SelectedItems,1)
                  B = obj.Tank{SelectedItems(ii,1),SelectedItems(ii,2)};
                  obj.qOperations(m.Label,B(ii),SelectedItems(ii,:));
               end
         end
      end
      
      % Initialize UI context menu for tree click interactions
      function treeContextMenu = initUICMenu(obj)
         % INITUICMENU  Initialize UI Context menu. Adds all 'do' methods
         %              to the context options list.
         %
         %  obj.initUICMenu();
         
         treeContextMenu = uicontextmenu(...
            'Parent',obj.nigelGUI);
         m = methods(obj.Tank);
         m = m(startsWith(m,'do'));
         for ii=1:numel(m)
            mitem = uimenu(treeContextMenu,'Label',m{ii});
            mitem.Callback = @obj.uiCMenuClick;
         end
         set(obj.Tree,'UIContextMenu',treeContextMenu);
      end
      
      
   end
   
   % STATIC/private functions
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
      
      % Helper method to return name or array of name at a given level
      function name = getName(nigelObj,level)
         % GETNAME  Returns name of a nigelObj based on organization level
         %
         %  name = nigeLab.libs.DashBoard.getName(nigelObj);
         %  name = nigeLab.libs.DashBoard.getName(nigelObj,level);
         %
         %  nigelObj  --  Tank, Animal or Block object
         %  level  --  'Tank', 'Animal' or 'Block' level to return names
         
         if nargin < 2
            level = class(nigelObj(1));
            level = strsplit(level,'.');
            level = level{2};
         end
         
         switch class(nigelObj)
            case 'nigeLab.Block'
               switch lower(level)
                  case 'tank'
                     error(['nigeLab:' mfilename ':badInputType1'],...
                        '%s is a higher level than %s',level,class(nigelObj));
                  case 'animal'
                     error(['nigeLab:' mfilename ':badInputType1'],...
                        '%s is a higher level than %s',level,class(nigelObj));
                  case 'block'
                     Metas = [nigelObj.Meta];
                     if isfield(Metas(1),'AnimalID') && isfield(Metas(1),'RecID')
                        name = {Metas.RecID};
                     else
                        name = {nigelObj.Name};
                     end
               end
            case 'nigeLab.Animal'
               switch lower(level)
                  case 'tank'
                     error(['nigeLab:' mfilename ':badInputType1'],...
                        '%s is a higher level than %s',level,class(nigelObj));
                  case 'animal'
                     name = {nigelObj.Name};
                  case 'block'
                     name = [];
                     for i = 1:numel(nigelObj)
                        b = nigelObj(i).Blocks;
                        Metas = [b.Meta];
                        if isfield(Metas(1),'AnimalID') && isfield(Metas(1),'RecID')
                           name = [name, {Metas.RecID}];
                        else
                           name = [name, {b.Name}];
                        end
                     end
               end
               
            case 'nigeLab.Tank'
               switch lower(level)
                  case 'tank'
                     name = {nigelObj.Name};
                  case 'animal'
                     a = nigelObj.Animals;
                     name = {a.name};
                  case 'block'
                     name = [];
                     a = nigelObj.Animals;
                     for i = 1:numel(a)
                        b = a(i).Blocks;
                        Metas = [b.Meta];
                        if isfield(Metas(1),'AnimalID') && isfield(Metas(1),'RecID')
                           name = [name, {Metas.RecID}];
                        else
                           name = [name, {b.Name}];  %#ok<*AGROW>
                        end
                     end
               end
            otherwise
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Unexpected input class: %s',class(nigelObj));
         end
      end
      
      % Initialize Colors struct with default values
      function col = initColors(figCol,panelCol,onPanelCol,buttonCol,onButtonCol)
         % INITCOLORS  Initialize colors struct for panel colors
         %
         %  col has three fields: 'fig', 'panel', 'onPanel', 'button', and
         %  'onButton'. They correspond to optional inputs 'figCol',
         %  'panelCol','onPanelCol','buttonCol', and 'onButtonCol'.
         %
         %  col = nigeLab.libs.initColors();
         %  col = nigeLab.libs.initColors(bg,surf,onsurf);
         
         col = struct;
         
         if nargin < 1
            col.fig = nigeLab.defaults.nigelColors('background');
         else
            col.fig = figCol;
         end
         
         if nargin < 2
            col.panel = nigeLab.defaults.nigelColors('surface');
         else
            col.panel = panelCol;
         end
         
         if nargin < 3
            col.onPanel = nigeLab.defaults.nigelColors('onsurface');
         else
            col.onPanel = onPanelCol;
         end
         
         if nargin < 4
            col.button = nigeLab.defaults.nigelColors(2);
         else
            col.button = buttonCol;
         end
         
         if nargin < 5
            col.onButton = nigeLab.defaults.nigelColors(2.1);
         else
            col.onButton = onButtonCol;
         end
      end
      
   end
   
   % STATIC/public functions
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

