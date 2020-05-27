function clusterIndex = getClus(blockObj,ch,suppressText)
%GETCLUS     Retrieve list of spike Clusters class indices for each spike
%
%  clusterIndex = GETCLUS(blockObj,ch);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     nigeLab.Block class object.
%
%    ch        :     Channel index for retrieving spikes.
%                    -> If not specified, returns a cell array with spike
%                          indices for each channel.
%                    -> Can be given as a vector.
%
%  suppressText:     Default: false; set to true to turn off print to
%                       command window when a channel is initialized.
%
%  --------
%   OUTPUT
%  --------
% clusterIndex :     Vector of spike classes (integers)
%                    -> If ch is a vector, returns a cell array of
%                       corresponding spike classes.

% PARSE INPUT
if nargin < 2
   ch = 1:blockObj(1).NumChannels;
end

if nargin < 3
   suppressText = ~blockObj.Verbose;
end

% ITERATE ON MULTIPLE CHANNELS
if (numel(ch) > 1)
   clusterIndex = cell(size(ch));
   for ii = 1:numel(ch)
      clusterIndex{ii} = getClus(blockObj,ch(ii));
   end
   return;
end

% ITERATE ON MULTIPLE BLOCKS
if (numel(blockObj) > 1)
   clusterIndex = [];
   for ii = 1:numel(blockObj)
      clusterIndex = [clusterIndex; getClus(blockObj(ii),ch)]; %#ok<AGROW>
   end 
   return;
end

% CHECK TO BE SURE THAT THIS BLOCK/CHANNEL HAS BEEN SORTED
fName = fullfile(sprintf(strrep(blockObj.Paths.Clusters.file,'\','/'),...
            num2str(blockObj.Channels(ch).probe),...
            blockObj.Channels(ch).chStr));
        
if getStatus(blockObj,'Clusters',ch)
   clusterIndex = getCIFromExistingFile(blockObj,ch);
   ts = getSpikeTimes(blockObj,ch);
   n = numel(ts);
   if numel(clusterIndex)~=n
      warning(['[GETCLUS]::[%s] Mismatch between number of Cluster '...
         'assignments (%g) and number of spikes (%g) for ' ...
         '%s::P%g-%s\n\t->\tAssigning all spikes to cluster zero.\n'],...
         blockObj.Name,numel(clusterIndex),n,...
         blockObj.Channels(ch).probe,blockObj.Channels(ch).chStr);
      clusterIndex = zeros(n,1);
      return;
   end
elseif exist(fName,'file')~=0   
    clusterIndex = getCIFromExistingFile(blockObj,ch);
    ts = getSpikeTimes(blockObj,ch);
    n = numel(ts);
    if numel(clusterIndex)~=n
        warning(['[GETCLUS]::[%s] Mismatch between number of Cluster '...
            'assignments (%g) and number of spikes (%g) for ' ...
            '%s::P%g-%s\n\t->\tAssigning all spikes to cluster zero.\n'],...
            blockObj.Name,numel(clusterIndex),n,...
            blockObj.Channels(ch).probe,blockObj.Channels(ch).chStr);
        clusterIndex = zeros(n,1);
        return;
    end
    updateStatus(blockObj,'Clusters',true,ch);
else % If it doesn't exist
   nigeLab.utils.cprintf('*SystemCommands',true,'[%s Channel %d] *Cluster* data not found.Initializing empty Clusters file.\n',blockObj.Name,ch);
   if getStatus(blockObj,'Spikes',ch) % but spikes do
      initClusters(blockObj,ch,suppressText);
      clusterIndex = getCIFromExistingFile(blockObj,ch);
%       updateStatus(blockObj,'Clusters',true,ch);
      return;
   else
       error(['[GETCLUS]::[%s Channel %d] Trying to access *Clusters* without *Spikes*.\n'...
           'To access spike sorting funcionalities run doSD first.'],...
           blockObj.Name,ch);
   end
end
if ~any(clusterIndex) % if all indexes are zero
    nigeLab.utils.cprintf('*SystemCommands',true,'[%s Channel %d] *Cluster* data contains only zeros.\n',blockObj.Name,ch);
end
end

function clusterIndex = getCIFromExistingFile(blockObj,ch)
%%GETCIFROMEXISTINGFILE    Get cluster index from existing file
% For backwards compatibility, make sure "tags" is not a cell

ftype = getFileType(blockObj,'Clusters');
info = getInfo(blockObj.Channels(ch).Clusters);
names = {info.Name};
tagIdx = find(strcmpi(names,'tag'),1,'first');

if isempty(tagIdx) % Everything is fine, return it the normal way
    clusterIndex = blockObj.Channels(ch).Clusters.value;
elseif strcmp(info(tagIdx).class,'cell')
    tag = blockObj.Channels(ch).Clusters.tag(:);
    tag = parseSpikeTagIdx(blockObj,tag);
    fname = getPath(blockObj.Channels(ch).Clusters);
    
    clusters = zeros(numel(tag),5);
    clusters(:,2) = blockObj.Channels(ch).Clusters.class(:);
    clusters(:,3) = tag;
    clusters(:,4) = getSpikeTimes(blockObj,ch);
    
    blockObj.Channels(ch).Clusters = ...
        nigeLab.libs.DiskData(ftype,fullfile(fname),...
        clusters,'access','w');
    clusterIndex = clusters(:,2);
    
elseif numel(info) > 1
    fname = getPath(blockObj.Channels(ch).Clusters);
    
    clusters = zeros(numel(info(1).size(1)),5);
    clusters(:,2) = blockObj.Channels(ch).Clusters.class(:);
    clusters(:,3) = blockObj.Channels(ch).Clusters.tag(:);
    clusters(:,4) = getSpikeTimes(blockObj,ch);
    
    blockObj.Channels(ch).Clusters = ...
        nigeLab.libs.DiskData(ftype,fullfile(fname),...
        clusters,'access','w');
    clusterIndex = clusters(:,2);
    
else % Everything is fine, return it the normal way
    clusterIndex = blockObj.Channels(ch).Sorted.value;
end
end

function initClusters(blockObj,ch,suppressText)
    if getStatus(blockObj,'Spikes',ch) % if spikes are present
        ts = getSpikeTimes(blockObj,ch);
        n = numel(ts);
        clusterIndex = zeros(n,1); % Assignment for output
        data = [zeros(n,3) clusterIndex zeros(n,1)];

        % initialize the 'Sorted' DiskData file
        fType = blockObj.getFileType('Clusters');
        fName = fullfile(sprintf(strrep(blockObj.Paths.Clusters.file,'\','/'),...
            num2str(blockObj.Channels(ch).probe),...
            blockObj.Channels(ch).chStr));
        if exist(blockObj.Paths.Clusters.dir,'dir')==0
            mkdir(blockObj.Paths.Clusters.dir);
        end
        blockObj.Channels(ch).Clusters = nigeLab.libs.DiskData(fType,...
            fName,data,'access','w');
        if ~suppressText
            fprintf(1,'Initialized Clusters file for P%d: Ch-%s\n',...
                blockObj.Channels(ch).probe,blockObj.Channels(ch).chStr);
        end
    end
end
