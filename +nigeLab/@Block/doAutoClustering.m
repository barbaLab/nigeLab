function flag = doAutoClustering(blockObj,chan,unit)
%% DOAUTOCLUSTERING Attempts to perform automatic single unit clustering on the selcted block
% 
% b = nigeLab.Block;
% chan = 1;
% b.doAutoClustering(chan);
%
% To recluster a single unit already sorted in the past:
% unit = 1;
% b.doAutoClustering(chan,unit);
% 
%  --------
%   OUTPUT
%  --------
%   flag       :     Returns true if conversion was successful.


flag = false;
nigeLab.utils.checkForWorker('config');
[~,par] = blockObj.updateParams('AutoClustering');

blockObj.checkActionIsValid();

%% runs automatic clustering algorithms
switch nargin
   case 1
      chan = blockObj.Mask;
      unit = 'all';
   case 2
      unit = 'all';
end

if strcmpi(unit,'all')
    unit = 0:par.NMaxClus;
end
str = nigeLab.utils.getNigeLink('nigeLab.Block','doAutoClustering',...
   par.MethodName);
str = sprintf('AutoClustering (%s)',str);
blockObj.reportProgress(str,0,'toWindow');
for iCh = chan
    % load spikes and classes
    inspk = blockObj.getSpikes(iCh,unit,'feat');
    SuppressText = true;
    classes =  blockObj.getClus(iCh,SuppressText);
    
    % if unit is porvided, match sikes and classes with the unit
    SubsetIndx = ismember(classes,unit);
    classesSubset = classes(SubsetIndx);
    
    % make sure not to overwrite/assign already used labels
    allLabels = 1:par.NMaxClus;
    usedLabels = setdiff(classes,unit);
    freeLabels = setdiff(allLabels, usedLabels);
    par.NMaxClus = numel(freeLabels);
    
    % actually do the clustering
    switch par.MethodName
        case 'KMEANS'
           [classes_,temp] = runKMEANSclustering(inspk,par);
        case 'SPC'
            [classes_,temp] = runSPCclustering(inspk,par);
        otherwise
    end
    
    % Attach correct/free labels to newly clusterd spks
    newLabels = unique(classes_);
    for ii = 1:numel(newLabels)
        classes_(classes_== newLabels(ii))= freeLabels(ii);
    end
    
    % save classes
    classes(SubsetIndx) = classes_;
    saveClusters(blockObj,classes,iCh,temp);
    
    % report progress to the user
    pct = round((iCh/numel(chan)) * 100);
    blockObj.reportProgress(str,pct,'toWindow');
    blockObj.reportProgress(sprintf('%s',par.MethodName),pct,'toEvent');
end
blockObj.save;
flag = true;
end

function [classes,temp] = runSPCclustering(inspk,par)
    [classes,temp] = nigeLab.utils.SPC.DoSPC(par.SPC,inspk);
end

function [classes,temp] = runKMEANSclustering(inspk,par)
warning off
GPUavailable = false;
if par.KMEANS.UseGPU
    try
        inspk = gpuArray(inspk(:,:));     % we need inspk as column for KMENAS
        GPUavailable = true;
    catch
        warning('gpuArray non available. Computing on CPU;');
    end
else
    inspk = inspk(:);     % we need inspk as column for KMENAS
end

switch par.KMEANS.NClus
    % set Klist, list of K to try with KMEANS
    case 'best'
        Klist = 1:pars.MaxNClus;
        if GPUavailable
            % sadly evalcluster is broken with gpuArrays, at least on 2017a
            % workarouund, compute the cluster solution outside evalclust and
            % use it only to evaluate the solution.
            
            ClustSolutions = zeros(numel(inspk),numel(Klist));
            for ii=Klist
                ClustSolutions(:,ii) = gather(kmeans(inspk,Klist(ii)));
            end
            evals = evalclusters(inspk,ClustSolutions,'Silhouette');
            classes = evals.OptimalY;
        else
            evals = evalclusters(inspk,'kmeans','Silhouette','Klist',Klist);
            classes = evals.OptimalY;
        end
        
    case 'max'
        Klist = min(size(inspk,1),par.NMaxClus);
        if GPUavailable
            % sadly evalcluster is broken with gpuArrays, at least on 2017a
            % workarouund, compute the cluster solution outside evalclust and
            % use it only to evaluate the solution.
            
            classes = gather(kmeans(inspk,Klist));
        else
            classes = kmeans(inspk,Klist);
        end
        
end

temp = 0;
end

function saveClusters(blockObj,classes,iCh,temperature)
classes = classes(:);   % we need classes formatted as column vector
ts = getSpikeTimes(blockObj,iCh);
n = numel(ts);
data = [zeros(n,1) classes temperature*ones(n,1) ts zeros(n,1)];

%% initialize the 'Clusters' DiskData file
fType = blockObj.getFileType('Clusters');
fName = fullfile(sprintf(strrep(blockObj.Paths.Clusters.file,'\','/'),...
   num2str(blockObj.Channels(iCh).probe),...
   blockObj.Channels(iCh).chStr));
if exist(blockObj.Paths.Clusters.dir,'dir')==0
   mkdir(blockObj.Paths.Clusters.dir);
end
blockObj.Channels(iCh).Clusters = nigeLab.libs.DiskData(fType,...
    fName,data,'access','w');

%% probably we don't need to reinitialize the Sorted files
% % initialize the 'Sorted' DiskData file
% fType = blockObj.getFileType('Sorted');
% fName = fullfile(sprintf(strrep(blockObj.Paths.Sorted.file,'\','/'),...
%     num2str(blockObj.Channels(iCh).probe),...
%     blockObj.Channels(iCh).chStr));
% if exist(blockObj.Paths.Sorted.dir,'dir')==0
%     mkdir(blockObj.Paths.Sorted.dir);
% end
% blockObj.Channels(iCh).Sorted = nigeLab.libs.DiskData(fType,...
%     fName,data,'access','w');

end