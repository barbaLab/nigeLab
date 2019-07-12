function flag = doAutoClustering(blockObj,chan,unit)
flag = false;
par = nigeLab.defaults.SPC;
%% runs automatic clustering algorithms
switch nargin
   case 1
      chan = blockObj.Mask;
      unit = 'all';
   case 2
      unit = 'all';
end

if strcmpi(unit,'all'),unit = 0:par.NCLUS_MAX;end
fprintf(1,'Performing auto clustering... %.3d%%',0);

SuppressText = true;


for iCh = chan
   [inspk] = blockObj.getSpikes(iCh,nan,'feat');                    %Extract spike features.
   classes = getClus(blockObj,iCh,SuppressText);
   offs = max(classes);
   %% runs automatic clustering algorithms
   
   subsetIndex = find(ismember(classes,unit));
   
   
   inspk = inspk(subsetIndex,:);
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
   
   %% Performing clustering
   
   [classes_,temp] = nigeLab.utils.SPC.DoSPC(par,inspk);
   classes_ = classes_ + offs;
   classes_(classes_>par.NCLUS_MAX) = par.NCLUS_MAX;
   classes(subsetIndex) = classes_;
   
   saveClusters(blockObj,classes,iCh,temp);
   
   blockObj.updateStatus('Clusters',true,iCh);
   blockObj.notifyUser('doAutoClustering','SPC',iCh,max(chan));
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