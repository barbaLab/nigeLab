function flag = doAutoClustering(animalObj,chan,unit)
flag = false;
nigeLab.utils.checkForWorker('config');
par = nigeLab.defaults.AutoClustering;
%% runs automatic clustering algorithms
switch nargin
    case 1
        chan = animalObj.Blocks(1).Mask;
        for ii=2:numel(animalObj.Blocks)
            [chan,~,iB] = intersect(chan,animalObj.Blocks(ii).Mask);
            if numel(iB)<numel(animalObj.Blocks(ii).Mask)
                warningFlag{ii-1} = {ii,setdiff(animalObj.Blocks(ii).Mask,animalObj.Blocks(ii).Mask(iB))};
            end
        end
        if ~isempty(warningFlag)
            nigeLab.utils.cprintf('Masks between blocks are not uniform.\n');
            nigeLab.utils.cprintf('The following channels in the following blocks will not be scored:\n');
            cellfun(@(x) nigeLab.utils.cprintf('UnterminatedStrings','\tBlock %s,\n\t\tChannels %s\b\n',animalObj.Blocks(x{1}).Name,num2str(x{2}(:)','%d,')),warningFlag)
        end
        unit = 'all';
    case 2
        unit = 'all';
end

if strcmpi(unit,'all')
    unit = 0:par.NMaxClus;
end

fprintf(1,'%.3d%%',0)
for iCh = chan
    
    [inspk,classes,BlInd,subsetIndex]= gatherSpikesFromAllBlocks(animalObj,iCh,unit);
    
    if size(inspk,1) < 15
        nigeLab.utils.cprintf('err','Channel %.3d: Not enough Spikes!\nLess than 15 spikes detected.',1);
        return;
    end
    %% TODO, permuting spikes
    %     if par.permut == 'y'
    %        if par.match == 'y'
    %           naux = min(par.max_spk,size(inspk,1));
    %           ipermut = randperm(length(inspk));
    %           ipermut(naux+1:end) = [];
    %        else
    %           ipermut = randperm(length(inspk));
    %        end
    %        inspk_aux = inspk(ipermut,:);
    %     else
    %        if par.match == 'y'
    %           naux = min(par.max_spk,size(inspk,1));
    %           inspk_aux = inspk(1:naux,:);
    %        else
    %           inspk_aux = inspk;
    %        end
    %     end
    
    %% assigning usable labels
    
    allLabels = 1:par.NMaxClus;
    usedLabels = unique(classes(~subsetIndex));
    freeLabels = allLabels(~ismember(allLabels, usedLabels));
    
    %% do clustering here
    switch par.MethodName
        
        case 'KMEANS'
            classes_ = runKMEANSclustering(inspk,par);
            temp = 0;
        case 'SPC'
            [classes_,temp] = nigeLab.utils.SPC.DoSPC(par.SPC,inspk);
        otherwise
    end
    
    %% Matching claseter results with free labels
    newLabels = unique(classes_);
    for ii = 1:numel(newLabels)
        classes_(classes_== newLabels(ii))= freeLabels(ii);
    end
    
    classes(subsetIndex) = classes_;
    
    %% saving clustering results to the appropriate block
    for bb=1:numel(animalObj.Blocks)
        blockObj = animalObj.Blocks(bb);
        saveClusters(blockObj,classes(BlInd == bb),iCh,temp);
        blockObj.updateStatus('Clusters',true,iCh);
    end
    
    %% report progress to user
    pc = 100 * (iCh / blockObj.NumChannels);
    if ~floor(mod(pc,5)) % only increment counter by 5%
        fprintf(1,'\b\b\b\b%.3d%%',floor(pc))
    end
    
end

fprintf(1,'\b\b\b\bDone.\n');
flag = true;
end

function [inspk,classes,BlInd,subsetIndex]= gatherSpikesFromAllBlocks(animalObj,iCh,unit)
%% Gathers spikes and classes information across all the blocks
% Output:
%           - All the spikes (not restricted by unit)
%           - All the classes (not restricted by unit)
%           - A vectro the same size as classes with the block index (1 if belonging to block # 1 etc)
%           - A logical vector same size as classes and spikes set to true
%               if the entry corresponds to the given unit.
inspk = [];
classes = [];
BlInd = [];
subsetIndex = false(0);

for bb=1:numel(animalObj.Blocks)
    blockObj = animalObj.Blocks(bb);
    if not(ismember(iCh,blockObj.Mask)),continue;end
    [inspk_] = blockObj.getSpikes(iCh,nan,'feat');                    %Extract spike features.
    
    SuppressText = true;
    classes_ = blockObj.getClus(iCh,SuppressText);
    subsetIndex_ = (ismember(classes_,unit));
    
    subsetIndex = [subsetIndex; subsetIndex_];
    inspk = [inspk; inspk_];
    classes = [classes; classes_];
    BlInd = [BlInd; ones(size(classes_))*bb];
end

end

function classes = runKMEANSclustering(inspk,pars)
warning off
GPUavailable = false;
classes = zeros(1,length(inspk));
if pars.KMEANS.UseGPU
    try
        inspk = gpuArray(inspk);     % we need inspk as column for KMENAS
        GPUavailable = true;
    catch
        warning('gpuArray non available. Computing on CPU;');
    end
else
    inspk = inspk;     % we need inspk as column for KMENAS
end

switch pars.KMEANS.NClus
    % set Klist, list of K to try with KMEANS
    case 'best'
        Klist = 1:pars.NMaxClus;
        
        if GPUavailable
            % sadly evalcluster is broken with gpuArrays, at least on 2017a
            % workarouund, compute the cluster solution outside evalclust and
            % use it only to evaluate the solution.
            
            ClustSolutions = zeros(size(inspk,1),numel(Klist));
            for ii=Klist
                ClustSolutions(:,ii) = gather(kmeans(inspk,Klist(ii)));
            end
            evals = evalclusters(gather(inspk),ClustSolutions,'Silhouette');
            classes = evals.OptimalY;
        else
            evals = evalclusters(inspk,'kmeans','Silhouette','Klist',Klist);
            classes = evals.OptimalY;
        end
        
    case 'max'
        Klist = pars.NMaxClus;
        
        if GPUavailable
            % sadly evalcluster is broken with gpuArrays, at least on 2017a
            % workarouund, compute the cluster solution outside evalclust and
            % use it only to evaluate the solution.
            classes = gather(kmeans(inspk,Klist));
            
        else
            classes = kmeans(inspk,Klist);
        end
end

warning on
end

function saveClusters(blockObj,classes,iCh,temp)
if not(iscolumn(classes)),classes=classes';end
ts = getSpikeTimes(blockObj,iCh);
n = numel(ts);
data = [zeros(n,1) classes temp*ones(n,1) ts zeros(n,1)];

% initialize the 'Clusters' DiskData file
fType = blockObj.getFileType('Clusters');
fName = fullfile(sprintf(strrep(blockObj.Paths.Clusters.file,'\','/'),...
    num2str(blockObj.Channels(iCh).probe),...
    blockObj.Channels(iCh).chStr));
if exist(blockObj.Paths.Clusters.dir,'dir')==0
    mkdir(blockObj.Paths.Clusters.dir);
end
blockObj.Channels(iCh).Clusters = nigeLab.libs.DiskData(fType,...
    fName,data,'access','w');
end
