function flag = doAutoClustering(animalObj,chan,multiBlock)
%DOAUTOCLUSTERING  Cluster spikes based on extracted waveform features
%
% b = nigeLab.Block;
% To specify a single channel:
% chan = 1;
% b.doAutoClustering(chan);
%
%  --------
%   OUTPUT
%  --------
%   flag       :     Returns true if clustering completed successfully.
blockObj = animalObj.Children;
switch nargin
   case 1
      chan = {blockObj.Mask};
      multiBlock = true;
    case 2
        if isempty(chan)
            chan = {blockObj.Mask};
        elseif islogical(chan)
            multiBlock = chan;
            chan = {blockObj.Mask};
        end
end

if ~multiBlock
   flag = true;
   for i = 1:numel(blockObj)
      if ~isempty(blockObj(i))
         if isvalid(blockObj(i))
            flag = flag && doAutoClustering(blockObj(i),chan,false);
         end
      end
   end
   return;
else
    % check if all blocks are ready
    SuppressText = false(1,numel(blockObj));
    checkActionIsValid(blockObj);
    for bb = 1:numel(blockObj)
        [~,par] = blockObj(bb).updateParams('AutoClustering','KeepPars');
        SuppressText(bb) = ~blockObj(bb).Verbose;
    end
    SuppressText = any(SuppressText);
    flag = false;
end


%% retrieving data
allChan = unique([chan{:}]);
allMasks = {blockObj.Mask};
if ~any([blockObj.OnRemote])
    str = nigeLab.utils.getNigeLink('nigeLab.Animal','doAutoClustering',...
        'Retrieving data');
    str = sprintf('AutoClustering-(%s)',str);
else
    str = sprintf('AutoClustering-(%s)',par.MethodName);
end
blockObj(1).reportProgress(str,0,'toWindow');

curCh = 1;
Allinspk = cell(1,numel(allChan));
nSpk = cell(1,numel(allChan));
for iCh = allChan
    
    %First we create for each channel indexes to link spikes to their
    %respective blocks
    
    BlocksNotMasked = cellfun(@(Ach,Mch) ismember(iCh,Ach) && ismember(iCh,Mch),chan,allMasks);

    nSpk{iCh} = zeros(1,1+numel(blockObj));
    nSpk{iCh}([false BlocksNotMasked]) = arrayfun(@(b)b.Channels(iCh).Spikes.size(1),blockObj(BlocksNotMasked)); % returns the numbers of spikes present in each block, only for unmasked blocks
    nSpk{iCh} = cumsum(nSpk{iCh}); % this way it can be used as index when retrieving spikes from each block
    nFeat = arrayfun(@(b)b.Channels(iCh).SpikeFeatures.size(2),blockObj(BlocksNotMasked)) -4; % -4 is due to the reserved spots for ts and other values in the file format
    
    uFeat = unique(nFeat); % number of features present in each block 
    if length(uFeat) ~= 1 % if it's not the same number in all blocks something went wrong
        if par.Interpolate
            maxFeat = max(nFeat);
            blocks2resample = find(nFeat == maxFeat);
        else
            error(sprintf('Classification feature are dishomogeneous across blocks. Joint clustering is not possible.\nNigel can handle this: set the ''Interpolate'' parameter to true.'))
        end
    end


    %Then we retrieve spikes and put them in the right place inside inspk 

    inspk = zeros(nSpk{iCh}(end),maxFeat); % preinitialize matrix to store all features from all spikes
    for bb = find(BlocksNotMasked)  
        blockObj(bb).updateStatus('Clusters',false,blockObj(bb).Mask); % We are overwriting any previous clustering operation, thus presetting the status to false

        idx = nSpk{iCh}(bb)+1:nSpk{iCh}(bb+1);
        if isempty(idx)
            continue;
        end
        if strcmpi(par.clusteringTraget,'Features')
            inspk(idx,:)  = getSpikeFeatures(blockObj(bb),iCh,{'Clusters',nan});
        elseif strcmpi(par.clusteringTraget,'Spikes')
            theseSpikes = getSpikes(blockObj(bb),iCh);
            if ay(bb==blocks2resample)
                t0 = linspace(blocksObj(bb).Pars.SD.WPre,blocksObj(bb).Pars.SD.WPost,nFeat(bb));
                t  = linspace(blocksObj(bb).Pars.SD.WPre,blocksObj(bb).Pars.SD.WPost,maxFeat);
                theseSpikes = interp1(t0,theseSpikes,t,par.InterpolateMethod);
            end
            inspk(idx,:) = theseSpikes;
        end
    end % bb
    
    % Finally we store all the spikes in a cell array for each channel
    Allinspk{curCh} = inspk;

    % report progress to the user
   pct = round((curCh/numel(allChan)) * 50);
   blockObj(1).reportProgress(str,pct,'toWindow');
   blockObj(1).reportProgress(par.MethodName,pct,'toEvent',par.MethodName);
   curCh = curCh +1;
end

%% actually do the clustering
if ~any([blockObj.OnRemote])
    str = nigeLab.utils.getNigeLink('nigeLab.Animal','doAutoClustering',...
        'Performing clustering');
    str = sprintf('AutoClustering-(%s)',str);
else
    str = sprintf('AutoClustering-(%s)',par.MethodName);
end

curCh = 1;
maxClass = 0;
classes = cell(1,numel(allChan));
for iCh = allChan
      SortFun = ['SORT_' par.MethodName];
      SortPars = par.(SortFun);
      Artargsout = cell(1,nargout(SortFun));
      [Artargsout{:}] = feval(SortFun,Allinspk{curCh},SortPars);
      classes_ = Artargsout{1};
      temp_ = unique(Artargsout{2});
      
   
   % the clustering methods return labels on a per-channel basis. It is
   % useful to have units with unique ids though. The conversion is done
   % here by adding to each classes_ array the number of units found on
   % previous channels
   newLabels = unique(classes_);
   correctedLabels = (maxClass + 1) : (maxClass + numel(newLabels));
   maxClass = correctedLabels(end);
   for ii = 1:numel(newLabels)
      classes_(classes_== newLabels(ii)) = correctedLabels(ii);
   end

   classes{curCh} = classes_; % sotre the correct classes
   
   % report progress to the user
   pct = round((curCh/numel(allChan)) * 90);
   blockObj(1).reportProgress(str,pct,'toWindow');
   blockObj(1).reportProgress(par.MethodName,pct,'toEvent',par.MethodName);
   curCh = curCh +1;
end

%% Save the data

if ~any([blockObj.OnRemote])
    str = nigeLab.utils.getNigeLink('nigeLab.Animal','doAutoClustering',...
        'Saving Data');
    str = sprintf('AutoClustering-(%s)',str);
else
    str = sprintf('AutoClustering-(%s)',par.MethodName);
end

curCh = 0;
for iCh = allChan
    for bb = find(BlocksNotMasked)
        idx = nSpk{iCh}(bb)+1:nSpk{iCh}(bb+1);
        if isempty(idx)
            continue;
        end
        
       classes_ = classes{iCh}(idx);
       temp = temp_;
       % save classes
       saveClusters(blockObj(bb),classes_,iCh,temp);
       blockObj(bb).updateStatus('Clusters',true,iCh);
   end

   % report progress to the user
   pct = round((curCh/numel(allChan)) * 90);
   blockObj(1).reportProgress(str,pct,'toWindow');
   blockObj(1).reportProgress(par.MethodName,pct,'toEvent',par.MethodName);
   curCh = curCh +1;
end % iCh

%% Save the blocks and finalize
if any([blockObj.OnRemote])
   str = 'Saving-Block';
   blockObj(1).reportProgress(str,95,'toWindow',str);
else
   blockObj.save;
   linkStr = blockObj(1).getLink('Clusters');
   str = sprintf('<strong>Auto-Clustering</strong> complete: %s\n',linkStr);
   blockObj(1).reportProgress(str,100,'toWindow','Done');
   blockObj(1).reportProgress('Done',100,'toEvent');
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