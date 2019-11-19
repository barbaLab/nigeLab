function flag = doAutoClustering(blockObj,chan,unit)
flag = false;

job = getCurrentJob;
if ~isempty(job) % we are on a remote worker
    configW;     % run the programmatically generated configuration script
end

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

% initialize the 'Sorted' DiskData file
fType = blockObj.getFileType('Sorted');
fName = fullfile(sprintf(strrep(blockObj.Paths.Sorted.file,'\','/'),...
    num2str(blockObj.Channels(iCh).probe),...
    blockObj.Channels(iCh).chStr));
if exist(blockObj.Paths.Sorted.dir,'dir')==0
    mkdir(blockObj.Paths.Sorted.dir);
end
blockObj.Channels(iCh).Sorted = nigeLab.libs.DiskData(fType,...
    fName,data,'access','w');

end