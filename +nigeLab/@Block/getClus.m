function clusterIndex = getClus(blockObj,ch,suppressText)
%% GETCLUS     Retrieve list of spike Clusters class indices for each spike
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
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE INPUT
if nargin < 2
   ch = 1:blockObj(1).NumChannels;
end

if nargin < 3
   suppressText = false;
end

%% USE RECURSION TO ITERATE ON MULTIPLE CHANNELS
if (numel(ch) > 1)
   clusterIndex = cell(size(ch));
   for ii = 1:numel(ch)
      clusterIndex{ii} = getClus(blockObj,ch(ii));
   end
   return;
end

%% USE RECURSION TO ITERATE ON MULTIPLE BLOCKS
if (numel(blockObj) > 1)
   clusterIndex = [];
   for ii = 1:numel(blockObj)
      clusterIndex = [clusterIndex; getClus(blockObj(ii),ch)]; %#ok<AGROW>
   end 
   return;
end

%% CHECK TO BE SURE THAT THIS BLOCK/CHANNEL HAS BEEN SORTED
if getStatus(blockObj,'Clusters',ch)
   clusterIndex = blockObj.Channels(ch).Clusters.value;
else % If it doesn't exist
   if getStatus(blockObj,'Spikes',ch) % but spikes do
      ts = getSpikeTimes(blockObj,ch);
      n = numel(ts);
      clusterIdx = zeros(n,1);
      data = [zeros(n,2) clusterIdx ts zeros(n,1)];
      
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
   else
      clusterIndex = [];
   end
end

end