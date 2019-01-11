function flag = linkSpikes(blockObj)
%% LINKSPIKES   Connect the Spikes data saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = LINKSPIKES(b);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% CHECK SPIKES DATA
updateFlag = false(1,blockObj.NumChannels);
flag = false;
counter = 0;
fprintf(1,'\nLinking SPIKES channels...000%%\n');
for iCh = blockObj.Mask
   pnum  = num2str(blockObj.ChannelID(iCh,1));
   chnum = num2str(blockObj.ChannelID(iCh,2),'%03g');
   fname = sprintf(strrep(blockObj.paths.SDW_N,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   if ~exist(fullfile(fname),'file')
      flag = true;
   else
      updateFlag(iCh) = true;
      blockObj.Channels(iCh).Spikes=nigeLab.libs.DiskData('MatFile',fname);
   end
   counter = counter + 1;
   fraction_done = 100 * (counter / numel(blockObj.Mask));
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end
blockObj.updateStatus('Spikes',updateFlag);

end