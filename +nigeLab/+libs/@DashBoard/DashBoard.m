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
   end
   
   % PUBLIC
   % Can only be set by methods of DashBoard
   properties(SetAccess = private, GetAccess = public)
      Children       cell                % Cell array of nigelPanels
      Tank           nigeLab.Tank        % Tank associated with this DashBoard
      remoteMonitor  nigeLab.libs.remoteMonitor  % Monitor remote progress
   end
   
   % PRIVATE
   % Object "children" of DashBoard etc
   properties(Access=private)
      job            cell         % Cell array of Matlab job objects
      jobIsRunning = false;       % Flag indicating current job(s) state
      Tree           uiw.widget.Tree     % widget graphic for datasets as "nodes"
      splitMultiAnimalsUI = ?nigeLab.libs.splitMultiAnimalsUI
      Listener  event.listener    % Array of event listeners to delete on destruction
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
        
         %% Init
         obj.Tank = tankObj;
         obj.Color = obj.initColors();
         obj.nigelGUI = obj.buildGUI();
         obj.Tree = obj.buildTree();
         
         pQueue = obj.getChildPanel('Queue');
         obj.remoteMonitor=nigeLab.libs.remoteMonitor(pQueue);
         obj.buildJavaObjs();

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
         pRecap.nestObj(RecapTable,'RecapTable');
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
         obj.Children{end+1} = nigeLab.libs.nigelBar(obj.nigelGUI,...
            'Position',Position,...
            'Tag','TitleBar',...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'StringColor',nigeLab.defaults.nigelColors('onprimary'),...
            'Buttons',Btns);
         
         %% Parameters UItabGroup
         h=uitabgroup();
         pParam = getChildPanel(obj,'Parameters');
         pParam.nestObj(h,'TabGroup');
         
         %% Set the selected node as the root node
         obj.Tree.SelectedNodes = obj.Tree.Root;
         Nodes.Nodes = obj.Tree.Root;
         Nodes.AddedNodes = obj.Tree.Root;
         treeSelectionFcn(obj,obj.Tree,Nodes)
         
         %% Add listeners
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
            if isvalid(obj.splitMultiAnimalsUI.Fig)
               delete(obj.splitMultiAnimalsUI.Fig);
            end
            delete(obj.splitMultiAnimalsUI);
         end
         
         % Delete this interface
         if isvalid(obj.nigelGUI)
            delete(obj.nigelGUI);
         end
      end
      
      % Return the panel corresponding to a given tag 
      % (e.g. getChildPanel('Tree'))
      function panelHandle = getChildPanel(obj,tagString)
         % GETCHILDPANEL  Return panel handle that corresponds to tagString
         %
         %  panelHandle = obj.getChildPanel('nigels favorite panel');
         %  --> panelHandle returns handle to nigelPanel with Tag property
         %      of 'nigels favorite panel'
         %
         %  Options:  
         %     Children{1}  <--> 'Tree'
         %     Children{2}  <--> 'Stats'
         %     Children{3}  <--> 'Queue'
         %     Children{4}  <--> 'Parameters'
         
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

   end
   
   % PRIVATE
   % Build or initialize elements of interface
   methods(Access = private)   
      % Method to add all listeners
      function lh = addAllListeners(obj)
         %% Add all the listeners
         
         lh = [];
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
                  %% actually add animals to block
                  obj.Tank.Animals(AnIndx).Blocks = [obj.Tank.Animals(AnIndx).Blocks, nigelObj];
               end
            otherwise
               error(['nigeLab:' mfilename ':unrecognizedClass'],...
                  'Unexpected class: %s',class(nigelObj));
         end
         
         nigeLab.libs.DashBoard.addToNode(animalNode,BlNames);
         obj.Tree = Tree; % Assign as property of DashBoard at end
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
         
         %% Check input
         if nargin < 2
            fig = figure('Units','Normalized',...
               'Position',[0.1 0.1 0.8 0.8],...
               'Color',obj.Color.fig,...
               'ToolBar','none',...
               'MenuBar','none');
         end
         
         %% Tree Panel
         % Panel where animals, blocks and the tank are visualized
         str    = {'Tree'};
         strSub = {''};
         Tag      = 'Tree';
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
         
         %% Queue Panel 
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
         
         %% Parameters Panel
         str    = {'Parameters'};
         strSub = {''};
         Tag      = 'Parameters';
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
      
      % Initializes the graphics tree widget
      function Tree = buildTree(obj)
         % BUILDTREE  Method to initialize tree
         
         pTree = obj.getChildPanel('Tree');
         pos = pTree.InnerPosition;
         pos(3) = pos(3)/2;
         Tree = uiw.widget.Tree(...
            'SelectionChangeFcn',@obj.treeSelectionFcn,...
            'Units', 'normalized', ...
            'Position',pos,...
            'FontName','Droid Sans',...
            'FontSize',15,...
            'Tag','MainTree',...
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
         
         pTree.nestObj(Tree,Tree.Tag);
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
      
      % Initialize Colors struct with default values
      function col = initColors(obj)
         
         col = struct;
         col.fig = nigeLab.defaults.nigelColors('background');
         col.panel = nigeLab.defaults.nigelColors('surface');
         col.onPanel = nigeLab.defaults.nigelColors('onsurface');
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
      
      % Creates the "recap circles" (rectangles with rounded edges that
      % look nice) for displaying the current status of different
      % processing stages. This should behave differently depending on if a
      % Tank, Animal, or Block node has been selected.
      function plotRecapCircle(obj,Status)
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
        
         pRecap = obj.getChildPanel('Stats');
         ax = pRecap.getChild('RecapAxes');
         cla(ax);
         [NAn,~] = size(Status);
         St = obj.Tank.Animals(1).Blocks(1).Fields;
         Nst = length(St);
         xlim(ax,[1 Nst+1]);
         ylim(ax,[1 NAn+1]);
         
         switch size(Status,1)
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
      
      %% Set menuItems active or inactive
      menuItems = {src.UIContextMenu.Children.Label};
      
      indx = (startsWith(menuItems,'do'));
      
      
      [src.UIContextMenu.Children(indx).Enable] = deal('on');
      [src.UIContextMenu.Children(~indx).Enable] = deal('off');
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
         
%          pbaspect([1,1,1]);
%          obj.Children{1}.nestObj(ax);
         
         %% splitMultiAnimals Button
         tankObj = obj.Tank;
         tt = tankObj.list;
         tCell = table2cell(tt);
         Status = obj.Tank.getStatus(obj.Tank.Animals(1).Blocks(1).Fields);
         StatusIndx = strcmp(tt.Properties.VariableNames,'Status');
         tCell = tCell(:,not(StatusIndx));
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
         
         % Do some reformatting on dates
         dateTimeCol = strcmp(columnFormatsAndData,'datetime');
         dateData = tCell(:,dateTimeCol);
         monthAbbrev = cell(size(dateData));
         for i = 1:numel(dateData)
            monthAbbrev{i} = month(dateData{i},'shortname');
            monthAbbrev{i} = monthAbbrev{i}{1};
         end
         tmp = unique(monthAbbrev);
         for ii=1:(numel(tmp)-1)
            tmp{ii} = [tmp{ii} ', '];
         end
         tCell(:,dateTimeCol) = {tmp};
         
         columnFormatsAndData{dateTimeCol} = 'cell';
         [tCell, columnFormatsAndData] = uxTableFormat(...
            columnFormatsAndData(not(StatusIndx)),tCell,'Tank');
         
         %% Create recap Table
         pRecap = obj.getChildPanel('Stats');
         RecapTable = uiw.widget.Table(...
            'CellEditCallback',[],...
            'CellSelectionCallback',[],...
            'Units','normalized', ...
            'Position',[pRecap.InnerPosition(1) ...
                        pRecap.InnerPosition(4)./2+0.05 ...
                        pRecap.InnerPosition(3) ...
                        pRecap.InnerPosition(4)./2-0.1],...
            'BackgroundColor',obj.Color.panel,...
            'FontName','Droid Sans');
         pRecap.nestObj(RecapTable);
         RecapTableMJScrollPane = RecapTable.JControl.getParent.getParent;
         RecapTableMJScrollPane.setBorder(...
            javax.swing.BorderFactory.createEmptyBorder);
         
         w = getChild(pRecap,'RecapTable');
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
         
         pRecap = obj.getChildPanel('Stats');
         w = pRecap.getChild('RecapTable');
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
         parPanel = getChildPanel(obj,'Parameters');
         h =  parPanel.Children{1};
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
         
         %% init splitmultianimals interface
%          toggleSplitMultiAnimalsUI(obj,'init');
         
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
            
            
            dd=struct2cell(ActPars);
            inx=cellfun(@(x) (isnumeric(x) && isscalar(x))||islogical(x)||ischar(x), dd);
            
            ff =fieldnames(ActPars);
            if any(inx)
               tab1 = uitab(h,'Title',Fnames{ii});
               InnerPos = getpixelposition(tab1) .*tab1.Position;
               InneWidth = InnerPos(3);
               uit = uitable(tab1,'Units','normalized',...
                  'Position',[0 0 1 1],'Data',[ff(inx),dd(inx)],...
                  'RowName',[],'ColumnWidth',{round(InneWidth*0.3),round(InneWidth*0.65)});
            end
         end
      end
      
   end
   
   % PRIVATE
   % Methods for UI Context Interactions
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
               {Tree.SelectedNodes.UserData}))
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
      
      function treeContextMenu = initUICMenu(obj)
         % INITUICMENU  Initialize UI Context menu. Adds all 'do' methods
         %              to the context options list.
         %
         %  obj.initUICMenu();
         
         treeContextMenu = uicontextmenu(...
            'Parent',obj.nigelGUI,...
            'Callback',@obj.prova1);
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

