function clusterIndex = getSort(blockObj,ch,suppressText)
%% GETSORT     Retrieve list of spike class indices for each spike
%
%  clusterIndex = GETSORT(blockObj,ch);
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
      clusterIndex{ii} = getSort(blockObj,ch(ii));
   end
   return;
end

%% USE RECURSION TO ITERATE ON MULTIPLE BLOCKS
if (numel(blockObj) > 1)
   clusterIndex = [];
   for ii = 1:numel(blockObj)
      clusterIndex = [clusterIndex; getSort(blockObj(ii),ch)]; %#ok<AGROW>
   end 
   return;
end

%% CHECK TO BE SURE THAT THIS BLOCK/CHANNEL HAS BEEN SORTED
if getStatus(blockObj,'Sorted',ch)
   clusterIndex = blockObj.Channels(ch).Sorted.value;
else % If it doesn't exist
   if isfield(blockObj.Channels,'Spikes') % but spikes do
      ts = getSpikeTimes(blockObj,ch);
      n = numel(ts);
      clusterIndex = [zeros(n,3) ts zeros(n,1)];
      
      % initialize the 'Sorted' DiskData file
      fType = blockObj.FileType{ismember(blockObj.Fields,'Spikes')};
      fName = fullfile(sprintf(strrep(blockObj.Paths.Sorted.file,'\','/'),...
         num2str(blockObj.Channels(ch).probe),...
         blockObj.Channels(ch).chStr));
      blockObj.Channels(ch).Sorted = nigeLab.libs.DiskData(fType,...
         fName,'access','w');
      if ~suppressText
         fprintf(1,'Initialized Sorted file for P%d: Ch-%s\n',...
            blockObj.Channels(ch).probe,blockObj.Channels(ch).chStr);
      end
   else
      clusterIndex = [];
   end
end

end