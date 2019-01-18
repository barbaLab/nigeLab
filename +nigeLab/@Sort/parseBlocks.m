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
sortObj.Channels.Mask = blockObj(1).Mask;
sortObj.Channels.Name = parseChannelName(sortObj);
sortObj.Channels.N = size(sortObj.Channels.ID,1);
sortObj.Channels.Idx = matchChannelID(blockObj,sortObj.Channels.ID);
sortObj.Channels.Sorted = false(sortObj.Channels.N,1);

%% FIND CORRESPONDING CHANNELS FOR REST OF BLOCK ELEMENTS
for ii = 1:numel(blockObj)
   if ~blockObj(ii).updateParams('Sort')
      warning('Parameters unset for %s. Skipping...',blockObj(ii).Name);
      continue;
   end
   
   % If previous sorting is available:
   if getStatus(blockObj(ii),'Sorted')
      fprintf(1,'\nChecking SORTED for %s...000%%\n',...
         blockObj(ii).Name);
      fType = getFileType(blockObj(ii),'Sorted');
      for iCh = blockObj(ii).Mask
         
         
         blockObj(ii).Channels(iCh).Sorted = unlockData(...
            blockObj(ii).Channels(iCh).Sorted);
         pct = 100 * (iCh / blockObj(ii).NumChannels);
         fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct))
      end
   else % If no sorted files, but clusters file exists:
      if getStatus(blockObj(ii),'Clusters',blockObj(ii).Mask)
         fprintf(1,'\nInitializing SORTED for %s...000%%\n',...
            blockObj(ii).Name);
         % Then initialize sorted file and send all spikes to one cluster
         % with the same tag:
         if exist(blockObj(ii).paths.SORTW,'dir')==0
            mkdir(blockObj(ii).paths.SORTW);
         end
         for iCh = blockObj(ii).Mask
            pnum  = num2str(channelID(iCh,1));
            chnum = num2str(channelID(iCh,2),'%03g');
            fname = sprintf(strrep(blockObj(ii).paths.CLUW_N,'\','/'), ...
               pnum, chnum);
            fName = fullfile(fname);
            
            value = blockObj(ii).Channels(iCh).Clusters.class;
            tag = ones(size(class)) * sortObj.pars.TagInit(1);
            sorted = struct('class',class,'tag',tag);
            
            blockObj(ii).Channels(iCh).Sorted = ...
               nigeLab.libs.DiskData('MatFile',fullfile(fName),...
               sorted,'access','w');
            
            pct = 100 * (iCh / blockObj(ii).NumChannels);
            fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct));
         end
      else % If no clustering or sorting has apparently been done:
         fprintf(1,'\nChecking CLUSTERS for %s...000%%\n',...
            blockObj(ii).Name);
         for iCh = blockObj(ii).Mask
            % Double-check for "clusters" file:
            pnum  = num2str(channelID(iCh,1));
            chnum = num2str(channelID(iCh,2),'%03g');
            fname = sprintf(strrep(blockObj(ii).paths.CLUW_N,'\','/'), ...
               pnum, chnum);
            fName = fullfile(fname);
            
            class = ones(size(getSpikeTimes),iCh);
            tag = ones(size(class)) * sortObj.pars.TagInit(1);
            
            if exist(fName,'file')==0 % If it doesn't exist:
               % Make a file and send all spikes to one cluster
               if exist(blockObj(ii).paths.CLUW,'dir')==0
                  mkdir(blockObj(ii).paths.CLUW);
               end
               
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
            if exist(blockObj(ii).paths.SORTW,'dir')==0
               mkdir(blockObj(ii).paths.SORTW);
            end
            sorted = struct('class',class,'tag',tag);
            blockObj(ii).Channels(iCh).Sorted = ...
               nigeLab.libs.DiskData('MatFile',fullfile(fName),...
               sorted,'access','w');
            
            pct = 100 * (iCh / blockObj(ii).NumChannels);
            fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct))
         end
      end
      % Update the status of this blockObj:
      blockObj(ii).updateStatus('Clusters',...
         true(size(blockObj(ii).Mask)),...
         blockObj(ii).Mask);
      save(blockObj(ii));
   end
   
end
sortObj.Blocks = blockObj;
flag = true;

end