function flag = qRawExtraction(blockObj)
%% QRAWEXTRACTION  Extract raw data files to BLOCK format using Isilon
%
%  b = orgExp.Block;
%  flag = qRawExtraction(b);
%
%  --------
%   OUTPUT
%  --------
%   flag       :     Returns true if conversion was successful.
%
%  By: Max Murphy v1.0  06/15/2018 Original version (R2017b)

%% SET QUEUE PARAMETERS FROM TEMPLATE FILE
blockObj.QueuePars = orgExp.defaults.Queue();

%% PREPARE THE PROPER PATH NAMES TO GIVE TO ISILON
% Replace the leading string for the recording file on R:/Recorded_Data
concatIdx = find((blockObj.RecFile == '/' ) | (blockObj.RecFile == '\'),1,'first')+1;
recFile = [blockObj.QueuePars.UNCPath{1}, blockObj.RecFile(concatIdx:end)];

% Replace the leading string for the processed data (P:/Processed_Data)
paths = blockObj.paths;
f = reshape(fieldnames(paths),1,numel(fieldnames(paths)));
for varName = f
   v = varName{1};
   concatIdx = find((paths.(v)== '/' ) | (paths.(v) == '\'),1,'first')+1;
   paths.(v) = [blockObj.QueuePars.UNCPath{2},paths.(v)(concatIdx:end)];
end

%% GET CURRENT VERSION INFORMATION WIP
load('qRawExtraction_files.mat','attachedFiles');
pkgPath = fileparts(mfilename('fullpath'));
pkgPath = strsplit(pkgPath,filesep);
pkgIdx = find(ismember(pkgPath,'+orgExp'),1,'first')-1;
for ii = 1:numel(attachedFiles) %#ok<NODEF>
   attachedFiles{ii} = fullfile(strjoin(pkgPath(1:pkgIdx),filesep),...
      attachedFiles{ii}); %#ok<AGROW>
end

if isempty(blockObj.QueuePars.Cluster)
   useCluster = orgExp.libs.findGoodCluster('CLUSTER_LIST',...
      blockObj.QueuePars.ClusterList);
else
   useCluster = blockObj.QueuePars.Cluster;
end
myCluster = parcluster(useCluster);
myJob     = createCommunicatingJob(myCluster, ...
       'AttachedFiles', attachedFiles, ...
       'Name', ['Raw Extraction: ' blockObj.Name], ...
       'NumWorkersRange', [1 2], ...
       'FinishedFcn', @orgExp.libs.JobFinishedAlert, ...
       'Type','pool', ...
       'Tag', ['Queued: Raw Extraction for ' blockObj.Name]);

%% PARSE EXTRACTION DEPENDING ON RECORDING TYPE AND FILE EXTENSION
% If returns before completion, indicate failure to complete with flag
flag = false;

switch blockObj.RecType
   case 'Intan'
      % Two types of Intan binary files: rhd and rhs
      switch blockObj.FileExt
         case '.rhs'
            createTask(myJob,@RHS2Block,0,{blockObj,recFile,paths});
            flag = true;
         case '.rhd'
            createTask(myJob,@RHD2Block,0,{blockObj,recFile,paths});
            flag = true;
         otherwise
            warning('Invalid file type (%s).',blockObj.File_extension);
            return;
      end
      
   case 'TDT'
      % TDT raw data already has a sort of "BLOCK" structure that should be
      % parsed to get this information.
      warning('%s is not yet supported, but will be added.',...
         blockObj.RecType);
      return;
      
   case 'mat'
      % Federico did you add this? I don't think there are plans to add
      % support for acquisition that streams to Matlab files...? -MM
      warning('%s is not yet supported, but will be added.',...
         blockObj.RecType);
      return;
      
   otherwise
      % Currently only working with TDT and Intan, the two types of
      % acquisition hardware that are in place at Nudo Lab at KUMC, and at
      % Chiappalone Lab at IIT.
      warning('%s is not a supported (case-sensitive).',...
         blockObj.RecType);
      return;
end

fprintf(1,'Submitting raw extraction for %s to %s...\n',...
   blockObj.Name,useCluster);
submit(myJob);
fprintf(1,'\n\n\n----------------------------------------------\n\n');
wait(myJob, 'queued');
fprintf(1,'Queued job:  %s\n',blockObj.Name);
fprintf(1,'\n');
wait(myJob, 'running');
fprintf(1,'\n');
fprintf(1,'->\tJob running.\n');

end