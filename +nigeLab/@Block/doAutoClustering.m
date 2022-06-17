function flag = doAutoClustering(blockObj,chan,unit,useSort)
%DOAUTOCLUSTERING  Cluster spikes based on extracted waveform features
%
% b = nigeLab.Block;
% To specify a single channel:
% chan = 1;
% b.doAutoClustering(chan);
%
% To recluster a single unit already CLUSTERED in the past:
% unit = 1;
% b.doAutoClustering(chan,unit);
%
% To recluster a single unit already SORTED in the past:
% unit = 1;
% b.doAutoClustering(chan,unit,true);
%
%  --------
%   OUTPUT
%  --------
%   flag       :     Returns true if clustering completed successfully.
switch nargin
   case 1
      chan = blockObj.Mask;
      unit = 'all';
      useSort = false;
   case 2
      unit = 'all';
      useSort = false;
   case 3
      useSort = false;
   otherwise
      % Then unit is already defined
end

if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      if ~isempty(blockObj(i))
         if isvalid(blockObj(i))
            flag = flag && doAutoClustering(blockObj(i),chan,unit);
         end
      end
   end
   return;
else
   flag = false;
end

[~,par] = blockObj.updateParams('AutoClustering','KeepPars');
blockObj.checkActionIsValid();
SuppressText = ~blockObj.Verbose;
blockObj.updateStatus('Clusters',false,blockObj.Mask);

% runs automatic clustering algorithms
if isempty(unit)
   unit = 0:par.NMaxClus;
elseif strcmpi(unit,'all') % Returns false if unit is numeric
   unit = 0:par.NMaxClus;
elseif ischar(unit)
   error(['nigeLab:' mfilename ':BadString'],...
      'Unexpected "unit" value: %s (should be ''all'' or numeric)\n',unit);
end

if ~blockObj.OnRemote
   str = nigeLab.utils.getNigeLink('nigeLab.Block','doAutoClustering',...
      par.MethodName);
   str = sprintf('AutoClustering-(%s)',str);
else
   str = sprintf('AutoClustering-(%s)',par.MethodName);
end
blockObj.reportProgress(str,0,'toWindow');
curCh = 0;
for iCh = chan
   curCh = curCh+1;
   
   % load spikes and classes.
   % NOTE: for now this is fine, since we will NEVER call this method from
   % the @Sort interface (it uses nigeLab.libs.SpikeImage/Recluster()
   % method to group "leftover" spikes using PCA on spike waveforms);
   % however, if `.doAutoClustering` is used in combination with @Sort,
   % the method should be changed to make use of `useSort`
   if useSort 
      if blockObj.getStatus('Sorted',iCh)
         inspk = getSpikeFeatures(blockObj,iCh,{'Sorted',unit});
      else
         inspk = getSpikeFeatures(blockObj,iCh,{'Sorted',nan});
      end
   else
      if blockObj.getStatus('Clusters',iCh)
         inspk = getSpikeFeatures(blockObj,iCh,{'Clusters',unit});
      else
         inspk = getSpikeFeatures(blockObj,iCh,{'Clusters',nan});
      end
   end
   classes =  getClus(blockObj,iCh,SuppressText);
   if isempty(inspk)
      saveClusters(blockObj,classes,iCh,nan);
      continue;
   end
   
   % if unit is porvided, match spikes and classes with the unit
   SubsetIndx = ismember(classes,unit);
   classesSubset = classes(SubsetIndx);
   
   % make sure not to overwrite/assign already used labels
   allLabels = 1:par.NMaxClus;
   usedLabels = setdiff(classes,unit);
   freeLabels = setdiff(allLabels, usedLabels);
   par.NMaxClus = numel(freeLabels);
   
   % actually do the clustering

 
      SortFun = ['SORT_' par.MethodName];
      SortPars = par.(SortFun);
      Artargsout = cell(1,nargout(SortFun));
      [Artargsout{:}] = feval(SortFun,inspk,SortPars);
      classes_ = Artargsout{1};
      temp = unique(Artargsout{2});
      
   
   % Attach correct/free labels to newly clustered spks
   newLabels = unique(classes_);
   for ii = 1:numel(newLabels)
      classes_(classes_== newLabels(ii))= freeLabels(ii);
   end
   
   % save classes
   classes(SubsetIndx) = classes_;
   saveClusters(blockObj,classes,iCh,temp);
   
   % report progress to the user
   pct = round((curCh/numel(chan)) * 90);
   blockObj.updateStatus('Clusters',true,iCh);
   blockObj.reportProgress(str,pct,'toWindow');
   blockObj.reportProgress(par.MethodName,pct,'toEvent',par.MethodName);
end
if blockObj.OnRemote
   str = 'Saving-Block';
   blockObj.reportProgress(str,95,'toWindow',str);
else
   blockObj.save;
   linkStr = blockObj.getLink('Clusters');
   str = sprintf('<strong>Auto-Clustering</strong> complete: %s\n',linkStr);
   blockObj.reportProgress(str,100,'toWindow','Done');
   blockObj.reportProgress('Done',100,'toEvent');
end
flag = true;
end

function saveClusters(blockObj,classes,iCh,temperature)
%SAVECLUSTERS  Save detected clusters in proper BLOCK folder hierarchical
%                 format and with the correct filename. 
%
%              clusters data files have the following format
%
%              |  Col1  |   Col2   |     Col3    |  Col4  |  Col5  |
%              |   -    |  cluster | keyParamVal |   ts   |   -    |

% Get filename for `Clusters` and `Sorted` files
fNameC = fullfile(sprintf(strrep(blockObj.Paths.Clusters.file,'\','/'),...
   num2str(blockObj.Channels(iCh).probe),...
   blockObj.Channels(iCh).chStr));
fNameS = fullfile(sprintf(strrep(blockObj.Paths.Sorted.file,'\','/'),...
    num2str(blockObj.Channels(iCh).probe),...
    blockObj.Channels(iCh).chStr));

% Create the `Clusters` and `Sorted` folders if necessary
if exist(blockObj.Paths.Clusters.dir,'dir')==0
   mkdir(blockObj.Paths.Clusters.dir);
end
if exist(blockObj.Paths.Sorted.dir,'dir')==0
    mkdir(blockObj.Paths.Sorted.dir);
end

% If `classes` is empty, then make this an "empty" file
if isempty(classes)
   data = zeros(0,5);
   blockObj.Channels(iCh).Clusters = nigeLab.libs.DiskData('Event',...
      fNameC,data,'access','w','overwrite',true,...
      'Complete',ones(1,1,'int8'));
   % only intitialize a `Sorted` file if there is no existing file
   if exist(fNameS,'file')==0
      blockObj.Channels(iCh).Sorted = nigeLab.libs.DiskData('Event',...
       fNameS,data,'access','w','overwrite',true,...
       'Complete',zeros(1,1,'int8'));
   end
   return;
end

% Otherwise, format and save as usual
classes = classes(:);   % we need classes formatted as column vector
ts = getSpikeTimes(blockObj,iCh);
n = numel(ts);
data = [zeros(n,1) classes temperature*ones(n,1) ts zeros(n,1)];

% save the 'Clusters' DiskData file and potentially initialize `Sorted`
blockObj.Channels(iCh).Clusters = nigeLab.libs.DiskData('Event',...
   fNameC,data,'access','w','overwrite',true,...
   'Complete',ones(1,1,'int8'));

% only intitialize a `Sorted` file if there is no existing file
if exist(fNameS,'file')==0
   blockObj.Channels(iCh).Sorted = nigeLab.libs.DiskData('Event',...
    fNameS,data,'access','w','overwrite',true,...
    'Complete',zeros(1,1,'int8'));
end


end