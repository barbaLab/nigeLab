function flag = doAutoClustering(animalObj,chan,unit)
flag = false;
par = nigeLab.defaults.SPC;
%% runs automatic clustering algorithms
switch nargin
   case 1
      chan = unique([animalObj.Blocks.Mask]);
      unit = 'all';
   case 2
      unit = 'all';
end

if strcmpi(unit,'all'),unit = 0:par.NCLUS_MAX;end
fprintf(1,'Performing auto clustering... %.3d%%',0);

for iCh = chan
   inspk = [];
   classes = [];
   BlInd = [];
   subsetIndex = [];
   
   for bb=1:numel(animalObj.Blocks)
      blockObj = animalObj.Blocks(bb);
      if not(ismember(iCh,blockObj.Mask)),continue;end
      [inspk_] = blockObj.getSpikes(iCh,nan,'feat');                    %Extract spike features.
      
      SuppressText = true;
      classes_ = blockObj.getClus(iCh,SuppressText);
      subsetIndex_ = (ismember(classes_,unit));

      subsetIndex = [subsetIndex; subsetIndex_];
      inspk = [inspk; inspk_(subsetIndex_,:) ];
      classes = [classes; classes_];
      BlInd = [BlInd; ones(size(classes_))*bb];
   end
   
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
    
%% Perfomring clustering
    
    allLabels = 1:par.NCLUS_MAX;
    usedClasses = unique(classes(~subsetIndex));
    usedClasses(usedClasses < 1) = 1;
    if isempty(usedClasses),freeLabels = allLabels;else
    freeLabels = allLabels(ismember(allLabels, usedClasses));
    freeLabels = [freeLabels(:);...
        ones(numel(unique(classes_))-numel(freeLabels),1)*par.NCLUS_MAX];
    end
    
    par.NCLUS_MAX = numel(freeLabels);
    [classes_,temp] = nigeLab.utils.SPC.DoSPC(par,inspk);
    classes_(classes_>par.NCLUS_MAX) = par.NCLUS_MAX;
    
    jj=1;
    for ii=unique(classes_(:))'
       classes_(classes_==ii)= freeLabels(jj);
       jj=jj+1;
    end
    classes(subsetIndex) = classes_;
      
      for bb=1:numel(animalObj.Blocks)
         blockObj = animalObj.Blocks(bb);
         saveClusters(blockObj,classes(BlInd == bb),iCh,temp);         
         blockObj.updateStatus('Clusters',true,iCh);
      end
      
      pc = 100 * (iCh / blockObj.NumChannels);
      if ~floor(mod(pc,5)) % only increment counter by 5%
         fprintf(1,'\b\b\b\b%.3d%%',floor(pc))
      end
   
end

fprintf(1,'\b\b\b\bDone.\n');
    flag = true;
end

function saveClusters(blockObj,classes,iCh,temp)
if not(iscolumn(classes)),classes=classes';end
ts = getSpikeTimes(blockObj,iCh);
n = numel(ts);
data = [zeros(n,1) classes temp*ones(n,1) ts zeros(n,1)];

% initialize the 'Sorted' DiskData file
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

function [Temp,classes] = SPCrun(par,inspk_aux)
       %Interaction with SPC
    workdir = fullfile(fullfile(fileparts(fileparts(mfilename('fullpath')))),'+utils','+SPC');

    par.fname_in = fullfile(par.fname_in);
    save(fullfile(workdir,par.fname_in),'inspk_aux','-ascii');                      %Input file for SPC

    [clu,tree] = nigeLab.utils.SPC.run_cluster(par);
        
    [clust_num,temp,auto_sort] = nigeLab.utils.SPC.find_temp(tree,clu, par);
    current_temp = max(temp);
    classes = zeros(1,size(clu,2)-2);
%     for c =1: length(clust_num)
%        aux = clu(temp(c),3:end) +1 == clust_num(c);
%        classes(aux) = c;
%     end
% Same but vectorized
 classes = sum( (clu(temp,3:end) +1 == clust_num) .* (1:numel(clust_num))',1);

    
    if par.permut == 'n'
       classes = [classes zeros(1,max(size(spikes,1)-size(clu,2)-2,0))];
    end
    
    [Temp,classes]=checkclasses(current_temp,classes);
    
%     clustering_results = [];
%     clustering_results(:,1) = repmat(current_temp,length(classes),1); % temperatures
%     clustering_results(:,2) = classes'; % classes
%     
%     for i=1:max(classes)
%        clustering_results(classes==i,3) = Temp(i);
%        clustering_results(classes==i,4) = clust_num(i); % original classes
%     end
%     
%     clustering_results(:,5) = repmat(par.min_clus,length(classes),1);
%     

    
end

function [Temp,classes]=checkclasses(temp,classes)

    Temp = temp;
    % Classes should be consecutive numbers
    classes_names = nonzeros(sort(unique(classes)));
    if isempty(classes_names),return;end
    if sum(classes_names) ~= classes_names(end)*(classes_names(end)+1)/2
       for i= 1:length(classes_names)
          c = classes_names(i);
          if c~= i
             classes(classes == c) = i;
          end
          Temp(i) = temp(i);
       end
    end
    
end