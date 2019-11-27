classdef DashBoard < handle
   %DASHBOARD
   
   properties
      nigelGui
      Children
      Tank
      remoteMonitor
   end
   
   properties(Access=private)
      job
      jobIsRunning = false;
      
   end
   
   methods
          function obj = DashBoard(tankObj)
        
         %% Defaults Values
         bCol = nigeLab.defaults.nigelColors('background');
         PBCol = nigeLab.defaults.nigelColors('surface'); % Panel background colors
         onPBcol = nigeLab.defaults.nigelColors('onsurface');
         %% Init
         obj.Tank = tankObj;
         
         %% Load Graphics
         obj.nigelGui = figure('Units','Normalized',...
            'Position',[0.1 0.1 0.8 0.8],...
            'Color',bCol,...
            'ToolBar','none',...
            'MenuBar','none');
         loadPanels(obj)
         obj.remoteMonitor=nigeLab.libs.remoteMonitor(obj.getChildPanel('Queue'));
         addlistener(obj.remoteMonitor,'jobCompleted',@obj.refreshStats);
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
            mitem.Callback = {@obj.uiCMenuClick,Tree};
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
      end
      
   end
   
   methods(Access = private)
      
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
      function Tree = getTankTree(obj,Tree)
         tankObj = obj.Tank;
         Tree.Root.Name = tankObj.Name;
         AnNames = {tankObj.Animals.Name};
         for ii =1:numel(AnNames)
            AnNode = uiw.widget.CheckboxTreeNode('Name',AnNames{ii},'Parent',Tree.Root);
            set(AnNode,'UserData',[ii]);
            Metas = [tankObj.Animals(ii).Blocks.Meta];
            if isfield(Metas(1),'AnimalID') && isfield(Metas(1),'RecID')
                BlNames = {Metas.RecID};
            else
                warning('Missing AnimalID or RecID Meta fields. Using Block.Name instead.');
                BlNames = {tankObj.Animals(ii).Blocks.Name};
            end
            
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
      
      function setAnimalTablePars(obj,SelectedItems)
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
      
      function setBlockTablePars(obj,SelectedItems)
         
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
      
      function plotRecapCircle(obj,Status)
        %% plots the overview of the performed operations inside the Stats panel 
         
         ax = obj.Children{2}.Children{2};  % what is this axes?
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
      
      function refreshStats(obj,src,evt)
          bar = evt.bar;
          idx = bar.UserData;
          obj.Tank.Animals(idx(1)).Blocks(idx(2)).reload;
          pan = obj.getChildPanel('Overview');
          Tr = pan.Children{1};
          Nodes.Nodes = Tr.SelectedNodes;
          Nodes.AddedNodes = Tr.SelectedNodes;
          obj.treeSelectionFcn(Tr, Nodes)
      end
      
      
      function uiCMenuClick(obj,m,~,Tree)
         SelectedItems = cat(1,Tree.SelectedNodes.UserData);
         switch  unique(cellfun(@(x) numel(x), {Tree.SelectedNodes.UserData}))
            case 0  % tank
               obj.qOperations(m.Label,obj.Tank)
            case 1  % animal
               for ii=1:size(SelectedItems,1)
                  A = obj.Tank.Animals(SelectedItems(ii));
                  obj.qOperations(m.Label,A,SelectedItems(ii))
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
      
      % Return the panel corresponding to a given tag
      % (so we don't memorize panel indices)
      function panelHandle = getChildPanel(obj,tagString)
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
%                if ~obj.initJobs(target)
%                   return;
%                end
               
               for ii = 1:numel(target.Animals)
                  for ik = 1:target.Animals(ii).getNumBlocks
                     qOperations(obj,operation,...
                        target.Animals(ii).Blocks(ik),[ii ik]);
                     
                  end
               end
               
            case 'nigeLab.Animal'
%                if ~obj.initJobs(target)
%                   return;
%                end
%                
               for ii = 1:numel(target.Blocks)
                  qOperations(obj,operation,target.Blocks(ii),[idx ii]);
               end
               
            case 'nigeLab.Block'
%                if obj.jobIsRunning(idx)
%                   fprintf(1,'Jobs are still running. Aborted.\n');
%                   return;
%                end
               
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
%                   obj.remoteMonitor(sprintf('%s - %s',name,operation),idx);
%                   obj.jobIsRunning(idx) = true;
                obj.remoteMonitor.updateStatus(bar,'Pending...')

                  job.FinishedFcn = {@(~,~,b)obj.remoteMonitor.barCompleted(b),bar};
                  
%                 updating ststus labels
                  job.QueuedFcn =  {@(~,~,b)obj.remoteMonitor.updateStatus(b,'Queuing...'),bar};
                  job.RunningFcn = {@(~,~,b)obj.remoteMonitor.updateStatus(bar,'Running...'),bar};

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
               error('Invalid target class: %s',class(target));
         end
         drawnow;
         
      end
   end
end

