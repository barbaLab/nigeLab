function qOperations(obj,operation,target,sel)
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

%% Define imports within scope of qOperations
import nigeLab.utils.buildWorkerConfigScript
import nigeLab.utils.getNigeLink nigeLab.utils.getUNCPath
import nigeLab.utils.findGoodCluster

%%
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
      [~,qPars] = target.updateParams('Queue');
      [~,nPars] = target.updateParams('Notifications');
      opLink = getNigeLink('nigeLab.Block',operation);
                 
      if obj.Tank.UseParallel
         %% Configure remote or local cluster for correct parallel computation
         lineLink = getNigeLink('nigeLab.libs.DashBoard','qOperations',...
                                '(Parallel)');
         fprintf(1,'Initializing %s job: %s - %s\n',...
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
            p = qPars.RemoteRepoPath;
            % Create a worker config file that adds the remote repository,
            % then loads the corresponding block matfile and runs the
            % desired operation.
            [c,w] = buildWorkerConfigScript('fromLocal',p,operation);
            attachedFiles = {c, w};
         end
         
         n = min(nPars.NMaxNameChars,numel(target.Name));
         name = target.Name(1:n);
         name = strrep(name,'_','-');
         bar = obj.remoteMonitor.getBar(sel);
         bar.setState(0,'Pending...');
         bar.Visible = 'on';
         
         tagStr = reportProgress(target,'Queuing',0);
         job = createCommunicatingJob(myCluster, ...
            'AutoAttachFiles',false,...
            'AttachedFiles', attachedFiles, ...
            'AdditionalPaths', p,...
            'Name', [operation target.Name], ...
            'NumWorkersRange', qPars.NWorkerMinMax, ...
            'Type','pool', ...
            'UserData',sel,...
            'Tag',tagStr); %#ok<*PROPLC>
         
         blockName = sprintf('%s.%s',target.Meta.AnimalID,...
            target.Meta.RecID);
         % target is nigelab.Block
         blockName = blockName(1:min(end,nPars.NMaxNameChars));
         barName = sprintf('%s %s',blockName,operation(3:end));
         obj.remoteMonitor.startBar(barName,bar,job);

         % Assign callbacks to update labels and timers etc.
         job.FinishedFcn=@(~,~)obj.remoteMonitor.barCompleted(bar);
         job.QueuedFcn=@(~,~)bar.setState(0,'Queuing...');
         job.RunningFcn=@(~,~)bar.setState(0,'Running...');
         if isempty(qPars.RemoteRepoPath)
            createTask(job,operation,0,{target});
         else
            targetFile = getUNCPath(...
               [target.Paths.SaveLoc.dir '_Block.mat']);
            createTask(job,'qWrapper',0,{targetFile});
%             delete(c); % Delete configW.m (from Tempdir)
%             delete(w); % Delete qWrapper.m (from pwd)
         end
         submit(job);
         fprintf(1,'%s Job running: %s - %s\n',...
            lineLink,opLink,target.Name);
         
      else
         %% otherwise run single operation serially
         lineLink = getNigeLink('nigeLab.libs.DashBoard','qOperations',...
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
