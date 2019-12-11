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
par = nigeLab.defaults.AutoClustering;


%% runs automatic clustering algorithms
switch nargin
   case 1
      chan = blockObj.Mask;
      unit = 'all';
   case 2
      unit = 'all';
end

if strcmpi(unit,'all')
    unit = 0:par.NCLUS_MAX;
end
blockObj.reportProgress('AutoClustering',0);

SuppressText = true;

switch par.MethodName
    
    case 'KMEANS'
        runKMEANSclustering(blockObj,chan,par)
    case 'SPC'
       runSPCclustering(blockObj,chan,par)
    otherwise
end

flag = true;
end

function runSPCclustering(blockObj,chan,par)
%TODO inspk = getspikes(chan,block)
for iCh = chan
    [classes,temp] = nigeLab.utils.SPC.DoSPC(par.SPC,inspk);
    saveClusters(blockObj,classes,iCh,temp);
    
    pct = numel(iCh > chan)./numel(chan) * 100;
    blockObj.reportProgress('AutoClustering',pct);
end
end

function runKMEANSclustering(blockObj,chan,par)
%TODO inspk = getspikes(chan,block)
% TODO parallel

for iCh = chan
    inspk = blockObj.getSpikes(iCh);
    GPUavailable = false;
    if par.KMEANS.UseGPU
        try
            inspk = gpuArray(inspk(:));     % we need inspk as column for KMENAS
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
        case 'max'
            Klist = pars.MaxNClus;
    end
    
    if GPUavailable
        % sadly evalcluster is broken with gpuArrays, at least on 2017a
        % workarouund, compute the cluster solution outside evalclust and
        % use it only to evaluate the solution.
        
        ClustSolutions = zeros(numel(inspk),numel(Klist));
        for ii=Klist
          ClustSolutions(:,ii) = gather(kmeans(inspk,Klist(ii)));
          evals = evalclusters(inspk,ClustSolutions,'Silhouette');
          classes = evals.OptimalY;
        end
    else
       evals = evalclusters(inspk,'kmeans','Silhouette','Klist',Klist);
       classes = evals.OptimalY;
    end
    
   
    
    temp = 0;
    saveClusters(blockObj,classes,iCh,temp);
    
    pct = numel(iCh > chan)./numel(chan) * 100;
    blockObj.reportProgress('AutoClustering',pct);
end
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