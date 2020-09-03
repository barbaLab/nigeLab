function bar = qOperations(obj,operation,target,sel)
%QOPERATIONS  Wrapper for "do" methods of Block, for adding to
%             jobs to a queue for parallel and/or remote
%             processing.
%
%  Example use:
%  tankObj = nigeLab.Tank();
%  nigelDash = nigeLab.libs.DashBoard(tankObj);
%  <strong>>> nigelDash.qOperations(operation,target); </strong>
%  or
%  <strong>>> nigelDash.qOperations(operation,target,sel); </strong>
%
%  inputs:
%  operation  --  "do" method function handle
%  target  --  ULTIMATELY, A BLOCK OR ARRAY OF BLOCKS. Can be
%                 passed as: Tank, Animal, Block or Block array.
%  sel  --  Indexing into subset of tanks or blocks to
%              use. Should be set as a two-element column vector,
%              where the first index references animal and second
%              references block
%
%  See Also:
%  NIGELAB.BLOCK/DORAWEXTRACTION, NIGELAB.BLOCK/DOUNITFILTER,
%  NIGELAB.BLOCK/DOREREFERENCE, NIGELAB.BLOCK/DOSD,
%  NIGELAB.BLOCK/DOAUTOCLUSTERING, NIGELAB.BLOCK/DOLFPEXTRACTION,
%  NIGELAB.DEFAULTS.QUEUE

% Set indexing to assign to UserData property of Jobs
if nargin < 4
    key = target.getKey;
    an = obj.Tank{:};
    indx = cellfun(@(bs) ~isempty(findByKey(bs,key)),...
        arrayfun(@(a) a.Children, an,'UniformOutput',false));
   sel = {an(indx).getKey,key};
end

% Want to split this up based on target type so that we can
% manage Job/Task creation depending on the input target class
switch class(target)
   case 'nigeLab.Tank'
      for ii = 1:numel(target.Children)
         for ik = 1:target.Children(ii).getNumBlocks
             keys = {target.Children(ii).getKey,...
                  target.Children(ii).Children(ik).getKey};
            qOperations(obj,operation,...
               target.Children(ii).Children(ik),keys);
            drawnow;
         end
      end
      return;
   case 'nigeLab.Animal'
      for ii = 1:numel(target.Children)
         qOperations(obj,operation,target.Children(ii),[sel {target.Children(ii).getKey}]);
         drawnow;
      end
      return;
   case 'nigeLab.Block'
      % Define imports within scope of qOperations
      import nigeLab.utils.buildWorkerConfigScript
      import nigeLab.utils.getNigeLink nigeLab.utils.getUNCPath
      import nigeLab.utils.findGoodCluster
      
      % checking licenses and parallel flags to determine where to execute the
      % computation. Three possible outcomes:
      % local - Serialized
      % local - Distributed
      % remote - Distributed
      [fmt,idt,type] = target.getDescriptiveFormatting();
      if ~target.checkParsInit({'Queue','Notifications','doActions'})
         nigeLab.utils.cprintf('Errors*',...
            '%s[QOPERATIONS]: ',idt);
         nigeLab.utils.cprintf(fmt(1:(end-1)),...
            'Failed to initialize parameters for %s (%s)\n',...
            target.Name,type);
         return;
      else
         qPars = target.Pars.Queue;
         nPars = target.Pars.Notifications;
      end
      opLink = getNigeLink('nigeLab.Block',operation);
                 
      if obj.Tank.Pars.Queue.UseParallel
         %% Configure remote or local cluster for correct parallel computation
         lineLink = getNigeLink('nigeLab.libs.DashBoard','qOperations',...
                                'Parallel');
         nigeLab.utils.cprintf(fmt,'%s[QOPERATIONS]: ',idt);
         fprintf(1,'Initializing (%s) job: %s - %s\n',...
            lineLink,opLink,target.Name);
         if qPars.UseRemote
            if isfield(qPars,'Cluster')
               myCluster = parcluster(qPars.Cluster);
            else
               myCluster = findGoodCluster();
            end
         else
            myCluster = parcluster();
         end
         
         % if we are in a local cluster deactivate the UseRemote flag
         qPars.UseRemote = ~isa(myCluster,'parallel.cluster.Local');
         
         if isempty(qPars.RemoteRepoPath)
            attachedFiles = ...
               matlab.codetools.requiredFilesAndProducts(...
               sprintf('%s.m',operation));
            % programmatically creates a worker config file:
            c = buildWorkerConfigScript('fromRemote');
            attachedFiles = [attachedFiles, {c}];

            for jj=1:numel(attachedFiles)
               attachedFiles{jj}=getUNCPath(attachedFiles{jj});
            end
         else
            p = nigeLab.utils.getUNCPath(qPars.RemoteRepoPath);
            db_p = nPars.DBLoc;
            % Create a worker config file that adds the remote repository,
            % then loads the corresponding block matfile and runs the
            % desired operation.
            add_debug_outputs = nPars.DebugOn;
            [c,w] = buildWorkerConfigScript('fromLocal',p,operation,db_p,...
               add_debug_outputs);
            attachedFiles = {c, w};
         end
         
         n = min(nPars.NMaxNameChars,numel(target.Name));
         name = target.Name(1:n);
         name = strrep(name,'_','-');         
         metas = cell(1, numel(nPars.TagString.Vars));
         for ii=1:numel(nPars.TagString.Vars)
            metas{ii} = target.Meta.(nPars.TagString.Vars{ii});
         end
         tagStr = sprintf(nPars.TagString.String,metas{:},...         % constant part of the message
                           'Pending',0);  
         blockName = sprintf('%s.%s',target.Meta.AnimalID,...
            target.Meta.RecID);
         % target is nigelab.Block
%          blockName = blockName(1:min(end,nPars.NMaxNameChars));
         barName = sprintf('%s.%s',blockName,operation);
         
         job = createCommunicatingJob(myCluster, ...
            'AutoAttachFiles',false,...
            'AttachedFiles', attachedFiles, ...
            'AdditionalPaths', p,...
            'Name', barName, ...
            'NumWorkersRange', qPars.NWorkerMinMax, ...
            'Type','pool', ...
            'UserData',sel,...
            'Tag',tagStr); %#ok<*PROPLC>
         
         bar = obj.RemoteMonitor.startBar(barName,sel,job);
         if isempty(bar)
            return;
         end

%          if qPars.UseRemote
%          % Assign callbacks to update labels and timers etc.
%          job.FinishedFcn=@(~,~)bar.indicateCompletion();
%          end
         if isempty(qPars.RemoteRepoPath)
            createTask(job,operation,0,{target});
         else
            % Will always run on _Block
            nigeLab.utils.cprintf(fmt,'\t%s[QOPERATIONS]: ',idt);
            fprintf(1,'Target: %s\n',target.File);
            
            oldDir = pwd;
            cd(fullfile(nigeLab.utils.getNigelPath,'+nigeLab','temp'));            
            createTask(job,@qWrapper,0,{target.File});
            cd(oldDir);
         end
         submit(job);
         nigeLab.utils.cprintf(fmt,'%s[QOPERATIONS]: ',idt);
         fprintf(1,'(%s) Job running: %s - %s\n',lineLink,opLink,target.Name);
         
      else
         %% otherwise run single operation serially
         lineLink = getNigeLink('nigeLab.libs.DashBoard','qOperations',...
                                'Non-Parallel');
         nigeLab.utils.cprintf(fmt,'%s[QOPERATIONS]: ',idt);
         fprintf(1,'%s Job running: (%s) - %s\n',...
            lineLink,opLink,target.Name);
         % (target is scalar nigeLab.Block)
         blockName = sprintf('%s.%s',target.Meta.AnimalID,...
            target.Meta.RecID);
%          blockName = blockName(1:min(end,nPars.NMaxNameChars));
         barName = sprintf('%s.%s',blockName,operation);
         starttime = clock();
         bar = obj.RemoteMonitor.startBar(barName,sel);
         if isempty(bar)
            return;
         end
         bar.setState(0,'Pending...');
         bar.IsRemote = false;
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
            cancelBar(bar);
            s = struct;
            s.message = me.message;
            s.identifier = me.identifier;
            s.stack = me.stack;
            lasterror(s); %#ok<LERR> % Set the last error struct
         end
         if flag
            bar.IsRunning = false;
            field = target.getOperationField(operation);
            if ~iscell(field)
               field = {field};
            end
            if ~isempty(field) && ~any(target.Status.(field{1}))
               linkToData(target,field);
            end
         end
      end
      
   otherwise
      error(['nigeLab:' mfilename ':badInputType2'],...
         '[QOPERATIONS]: Invalid target class: %s',class(target));
end
drawnow;

end
