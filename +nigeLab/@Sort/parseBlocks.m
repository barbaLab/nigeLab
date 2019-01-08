function flag = parseBlocks(sortObj,blockObj)
%% PARSEBLOCKS  Add blocks to Sort object
%
%  flag = PARSEBLOCKS(sortObj,blockObj);
%
%  --------
%   INPUTS
%  --------
%   sortObj    :     nigeLab.Sort class object that is under construction.
%
%   blockObj   :     nigeLab.Block class object
%
%
% By: Max Murphy  v1.0    2019/01/08  Original version (R2017a)

%% INITIALIZE CHANNELS PROPERTY
flag = false;

sortObj.Channels.ID = parseChannelID(blockObj(1));
sortObj.Channels.Name = nigeLab.utils.parseChannelName(sortObj.Channels.ID);
sortObj.Channels.Idx = cell(numel(blockObj),1);
sortObj.Channels.N = size(sortObj.Channels.ID,1);
sortObj.Channels.Sorted = false(sortObj.Channels.N,1);

%% FIND CORRESPONDING CHANNELS FOR REST OF BLOCK ELEMENTS
for ii = 1:numel(blockObj)
   if ~blockObj(ii).updateParams('Sort')
      warning('Parameters unset for %s. Skipping...',blockObj(ii).Name);
      continue;
   end
   channelID = parseChannelID(blockObj(ii));
   idx = [];
   for iCh = 1:size(channelID,1)
      tmp = find(ismember(sortObj.Channels.ID,channelID(iCh,:),'rows'),...
         1,'first');
      idx = [idx, tmp]; %#ok<AGROW>
   end
   sortObj.Channels.Idx{ii} = idx;
   
   % If previous sorting is available:
   if getStatus(blockObj(ii),'Sorted')
      fprintf(1,'\nChecking SORTED for %s...000%%\n',...
            blockObj(ii).Name);
      for iCh = 1:blockObj(ii).NumChannels
         % Make sure the sorted data is writable
         blockObj(ii).Channels(iCh).Sorted = unlockData(...
            blockObj(ii).Channels(iCh).Sorted);

         % For backwards compatibility, make sure "tags" is not a cell
         tag = blockObj(ii).Channels(iCh).Sorted.tag(:);
         if iscell(tag)
            blockObj(ii).Channels(iCh).Sorted.tag = ...
               parseSpikeTagIdx(blockObj,tag);
         end
         fraction_done = 100 * (iCh / blockObj(ii).NumChannels);
         fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
      end
   else % If no sorted files, but clusters file exists:
      if getStatus(blockObj(ii),'Clusters')
         % Then initialize sorted file and send all spikes to one cluster
         % with the same tag:
         class = blockObj(ii).Channels(iCh).Clusters.class;
         sorted = struct('class',ones(size(class))*2,...
            'tag',ones(size(class))*2);
         blockObj(ii).Channels(iCh).Sorted = ...
            nigeLab.libs.DiskData('MatFile',fullfile(fName),...
            sorted,'access','w');
         
      else % If no clustering or sorting has apparently been done:
         fprintf(1,'\nChecking CLUSTERS for %s...000%%\n',...
            blockObj(ii).Name);
         for iCh = 1:blockObj(ii).NumChannels
            % Double-check for "clusters" file:
            pnum  = channelID(iCh,1);
            chnum = channelID(iCh,2);
            fname = sprintf(strrep(blockObj.paths.CLUW_N,'\','/'), ...
               pnum, chnum);
            fname = fullfile(fname);
            
            if exist(fname,'file')==0 % If it doesn't exist:
               % Make a file and send all spikes to one cluster
               if exist(blockObj.paths.CLUW,'dir')==0
                  mkdir(blockObj.paths.CLUW);
               end
               class = ones(size(getSpikeTimes),iCh);
               blockObj(ii).Channels(iCh).Clusters = ...
                  nigeLab.libs.DiskData('MatFile',fullfile(fName),...
                  class,'access','w');
               blockObj(ii).Channels(iCh).Clusters = lockData(...
                  blockObj(ii).Channels(iCh).Clusters);
               
            else % If it does exist, link the files:
               blockObj(ii).Channels(iCh).Clusters = ...
                  nigeLab.libs.DiskData('MatFile',fullfile(fName));
            end
            
            % Also, initialize "sorted" files with a single class and tag
            if exist(blockObj.paths.SORTW,'dir')==0
               mkdir(blockObj.paths.SORTW);
            end
            sorted = struct('class',ones(size(class))*2,...
               'tag',ones(size(class))*2);
            blockObj(ii).Channels(iCh).Sorted = ...
               nigeLab.libs.DiskData('MatFile',fullfile(fName),...
               sorted,'access','w');
            
            fraction_done = 100 * (iCh / blockObj(ii).NumChannels);
            fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
         end
      end
      % Update the status of this blockObj:
      save(blockObj(ii));
   end
   
end
sortObj.Blocks = blockObj;
flag = true;

end