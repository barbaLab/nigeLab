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

sortObj.Channels.ID = nigeLab.utils.parseChannelID(blockObj(1));
sortObj.Channels.Name = nigeLab.utils.parseChannelName(sortObj.Channels.ID);
sortObj.Channels.Idx = cell(numel(blockObj),1);
sortObj.Channels.N = size(sortObj.Channels.ID,1);
sortObj.Channels.Sorted = false(sortObj.Channels.N,1);

%% FIND CORRESPONDING CHANNELS FOR REST OF BLOCK ELEMENTS
for ii = 1:numel(blockObj)
   channelID = nigeLab.utils.parseChannelID(blockObj(ii));
   idx = [];
   for iCh = 1:size(channelID,1)
      tmp = find(ismember(sortObj.Channels.ID,channelID(iCh,:),'rows'),...
         1,'first');
      idx = [idx, tmp]; %#ok<AGROW>
   end
   sortObj.Channels.Idx{ii} = idx;
   
   % Check for Sorted
   if getStatus(blockObj(ii),'Sorted')
      
   else % Otherwise, look for Clusters
      if getStatus(blockObj(ii),'Clusters')
         
      else % Otherwise, make "Clusters"
         fprintf(1,'\nCreating CLUSTERS for %s...000%%\n',...
            blockObj(ii).Name);
         for iCh = 1:blockObj(ii).NumChannels
            pnum  = channelID(iCh,1);
            chnum = channelID(iCh,2);
            fname = sprintf(strrep(blockObj.paths.CLUW_N,'\','/'), ...
               pnum, chnum);
            fname = fullfile(fname);
            if exist(fname,'file')==0
               class = ones
               blockObj(ii).Channels(iCh).Clusters = ...
                  nigeLab.libs.DiskData('MatFile',fullfile(fName),...
                  class,'access','w');
               blockObj(ii).Channels(iCh).Clusters = lockData(...
                  blockObj(ii).Channels(iCh).Clusters);
            else
               
            end
            fraction_done = 100 * (iCh / blockObj(ii).NumChannels);
            fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
         end
         save(blockObj(ii));
      end
   end
   
end
sortObj.Blocks = blockObj;
flag = true;

end