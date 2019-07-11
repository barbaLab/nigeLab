classdef DashBoard < handle
   %DASHBOARD
   
   properties
      nigelGui
      Children
      Tank
   end
   
   properties(Access=private)
      %       jobCompleteListener
      %       jobUpdateListener
      jobIsRunning = false;
      jobProgressBar
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
         obj.nigelGui = figure('Units','pixels','Position',[500 50 1200 800],...
            'Color',bCol,'ToolBar','none','MenuBar','none');
         loadPanels(obj)
         
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
      
      function loadPanels(obj)
         %% Create Panels
         
         %% Overview Panel
         % Panel where animals, blocks and the tank are visualized
         str    = {'Overview'};
         strSub = {''};
         Tag      = 'Overview';
         Position = [.01,.01,.33,.91];
         %[left bottom width height]
         obj.Children{end+1} = nigeLab.libs.nigelPanel(obj.nigelGui,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
         
         %% Stats Pannel
         str    = {'Stats'};
         strSub = {''};
         Tag      = 'Stats';
         Position = [.35, .45, .43 ,.47];
         obj.Children{end+1} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
         
         
         
         %% Queued works
         str    = {'Queue'};
         strSub = {''};
         Tag      = 'Queue';
         Position = [.35, .01, .43 , .43];
         obj.Children{end+1} = nigeLab.libs.nigelPanel(obj.nigelGui,'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'),...
            'Scrollable','on');
         
         
         %% Options pannel
         str    = {'Parameters'};
         strSub = {''};
         Tag      = 'Parameters';
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
      
      function uiCMenuClick(obj,m,~,Tree)
         SelectedItems = cat(1,Tree.SelectedNodes.UserData);
         switch  unique(cellfun(@(x) numel(x), {Tree.SelectedNodes.UserData}))
            case 0  % tank
               obj.qOperations(m.Label,obj.Tank)
            case 1  % animal
               for ii=1:size(SelectedItems,1)
                  A = obj.Tank.Animals(SelectedItems(ii));
                  obj.qOperations(m.Label,A)
               end
            case 2  % block
               for ii=1:size(SelectedItems,1)
                  B = obj.Tank.Animals(SelectedItems(ii,1)).Blocks(SelectedItems(ii,2));
                  obj.qOperations(m.Label,B)
               end
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
      
      % Initialize the job listener array, as well as the isJobRunning
      % property for the method. Return false if unable to initialize (for
      % example, if job for one step is still running).
      function flag = initJobListeners(obj,target)
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
         
         % Remove any previous listener handle objects, if they exist
%          if ~isempty(obj.jobUpdateListener)
%             for ii = 1:numel(obj.jobUpdateListener)
%                delete(obj.jobUpdateListener{ii});
%             end
%          end

%          % Remove any previous listener handle objects, if they exist
%          if ~isempty(obj.jobCompleteListener)
%             for ii = 1:numel(obj.jobCompleteListener)
%                delete(obj.jobCompleteListener{ii});
%             end
%          end
         
         % Remove any previous progress bars, if they exist
         if ~isempty(obj.jobProgressBar)
            for ii = 1:numel(obj.jobProgressBar)
               delete(obj.jobProgressBar{ii});
            end
         end
         
         obj.jobIsRunning = false(1,target.getNumBlocks);
         obj.jobProgressBar = cell(1,target.getNumBlocks);
         
%          obj.jobCompleteListener = cell(1,target.getNumBlocks);
%          obj.jobUpdateListener = cell(1,target.getNumBlocks);
         
         
         flag = true; % If completed successfully
      end
      
      function qOperations(obj,operation,target,idx,D)
         % Set indexing to assign to UserData property of Jobs, so that on
         % job completion the corresponding "jobIsRunning" property array
         % element can be updated appropriately.
         if nargin < 4
            idx = 1;
         end
         
         % Create a parallel pool data queue object so we can send info
         % from the workers back to the client.
         if nargin < 5
            if (license('test','Distrib_Computing_Toolbox'))
               D = parallel.pool.DataQueue;
               afterEach(D,@obj.updateRemoteMonitor);
            else
               D = [];
            end
         end
         
         % Want to split this up based on target type so that we can
         % manage Job/Task creation depending on the input target class
         switch class(target)
            case 'nigeLab.Tank'
               if ~obj.initJobListeners(target)
                  return;
               end
               
               for ii = 1:numel(target.Animals)
                  for ik = 1:target.Animals(ii).getNumBlocks
                     qOperations(obj,operation,...
                        target.Animals(ii).Blocks(ik),idx,D);
                     idx = idx + 1;
                  end
               end
               
            case 'nigeLab.Animal'
               if ~obj.initJobListeners(target)
                  return;
               end
               
               for ii = 1:numel(target.Blocks)
                  qOperations(obj,operation,target.Blocks(ii),ii,D);
               end
               
            case 'nigeLab.Block'
               if obj.jobIsRunning(idx)
                  fprintf(1,'Jobs are still running. Aborted.\n');
                  return;
               end
               
               qParams = nigeLab.defaults.Queue;
               if (license('test','Distrib_Computing_Toolbox')) && ...
                     (qParams.UseParallel)
                  
                  
                  if isfield(qParams,'Cluster')
                     if qParams.UseRemote
                        myCluster = parcluster(qParams.Cluster);
                     else
                        myCluster = parcluster();
                     end
                  else
                     if qParams.UseRemote
                        myCluster = nigeLab.utils.findGoodCluster();
                     else
                        myCluster = parcluster();
                     end
                  end
                  attachedFiles = ...
                     matlab.codetools.requiredFilesAndProducts(...
                     sprintf('%s.m',operation));
                  
                  
                  str = target.Name(1:(min(16,numel(target.Name))));
                  str = strrep(str,'_',' ');
%                   myJob = createCommunicatingJob(myCluster, ...
%                      'AttachedFiles', attachedFiles, ...
%                      'Name', [operation target.Name], ...
%                      'NumWorkersRange', qParams.nWorkerMinMax, ...
%                      'Type','pool', ...
%                      'Tag',sprintf('%s: %s',operation,str));
                  
                  target.UserData = struct('D',D,'idx',idx);
                  obj.remoteMonitor(sprintf('%s - %s',str,operation),idx);
                  obj.jobIsRunning(idx) = true;
                  
%                   createTask(myJob,operation,0,{target});
%                   submit(myJob);
                  fprintf(1,'Job running: %s - %s\n',operation,target.Name);
%                   op = ['@nigeLab.Block.' operation];
%                   delete(gcp('nocreate'));
%                   parfeval(parpool(myCluster),operation,0,target);
                  parfeval(gcp,operation,0,target);
                  
                  
                  
                  
                  % Update the corresponding array elements now that the
                  % job/task has been created and submitted.
                  
%                   mco = metaclass(myJob);
%                   tagProp = mco.PropertyList(ismember({mco.PropertyList.Name}.','Tag'));
%                   obj.jobListener{idx} = event.proplistener(myJob,tagProp,...
%                      'PostSet',@obj.updateRemoteMonitor);
%                   obj.jobUpdateListener{idx} = addlistener(target,...
%                      'channelCompleteEvent',...
%                      @obj.updateRemoteMonitor);
%                   obj.jobCompleteListener{idx} = addlistener(target,...
%                      'processCompleteEvent',...
%                      @obj.completeRemoteMonitor);
               else
                  % otherwise run single operation
                  fprintf(1,'(Non-parallel) job running: %s - %s\n',...
                     operation,target.Name);
                  feval(operation,target);
               end
               
            otherwise
               error('Invalid target class: %s',class(target));
         end
         drawnow;
         
      end
      
%       % Function to attach to jobs, which will execute upon completion
%       function jobFinishedFcn(obj,src,~)
%          % Read out a generic completion to the command window
%          nigeLab.utils.jobFinishedAlert(src);
%
%          % Indicate that this job is no longer running in properties
%          obj.jobIsRunning(src.UserData) = false;
%
%          % Update remoteMonitor corresponding to this job
%
%       end
      
      % Function to attach to listeners that monitor job progress, which
      % will update when the 'Tag' property of the job is updated.
      function updateRemoteMonitor(obj,data)
         pct = data.pct;
         idx = data.idx;
         
         xStart = obj.jobProgressBar{idx}.XData(1);
         xStop = xStart + (1-xStart) * (pct/100);
         obj.jobProgressBar{idx}.progpatch.XData = ...
            [xStart, xStop, xStop, xStart];
         obj.jobProgressBar{idx}.progtext.String = ...
            sprintf('%.3g%%',pct);
         disp(pct);
         drawnow;
      end
      
%       function completeRemoteMonitor(obj,src,~)
%          idx = src.UserData;
%          delete(obj.jobProgressBar{idx}.progpatch);
%          delete(obj.jobProgressBar{idx}.progtext);
%          delete(obj.jobProgressBar{idx}.progaxes);
%          delete(obj.jobProgressBar{idx}.proglabel);
%          delete(obj.jobProgressBar{idx}.X);
%       end



%       function deleteJob(obj,ind) %%%%%%%%%%%%%%%%%%%%% ToDO
%          cancel(obj.qJobs{ind});
%          pause(0.1)
%          delete(obj.qJobs{ind});
%          obj.qJobs(ind)=[];
%       end
      
      remoteMonitor(obj,Labels,Files,Fig,parent);
   end
end

