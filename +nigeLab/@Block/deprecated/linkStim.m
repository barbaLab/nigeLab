function flag = linkStim(blockObj)
%% LINKSTIM   Connect the stim data saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = LINKSTIM(b);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
updateStimFlag = false(1,blockObj.NumChannels);
updateDCFlag = false(1,blockObj.NumChannels);
flag = false(1,2);
counter = 0;
fprintf(1,'\nLinking STIMULATION channels...000%%\n');
for iCh = blockObj.Mask
   pnum  = num2str(blockObj.ChannelID(iCh,1));
   chnum = num2str(blockObj.ChannelID(iCh,2),'%03g');
   
   % This needs to be fixed, probably in genPaths
   stim_data_fname = strrep(fullfile(blockObj.paths.DW,'STIM_DATA',...
      [blockObj.Name '_STIM_P%s_Ch_%s.mat']),'\','/');
   fname = sprintf(strrep(stim_data_fname,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if (~exist(fullfile(fname),'file') && ismember(blockObj.FileExt,...
         {'.rhs','tdt'}))
      flag(1) = true;
   else
      updateStimFlag(iCh) = true;
      blockObj.Channels(iCh).stimData = ...
         nigeLab.libs.DiskData(blockObj.SaveFormat,fname);
   end
   
   if ~isempty(blockObj.DCAmpDataSaved)
      if (blockObj.DCAmpDataSaved ~= 0)
         dc_amp_fname = strrep(fullfile(blockObj.paths.DW,'DC_AMP',...
            [blockObj.Name '_DCAMP_P%s_Ch_%s.mat']),'\','/');
         fname = sprintf(strrep(dc_amp_fname,'\','/'), pnum, chnum);
         fname = fullfile(fname);
         
         if ~exist(fullfile(fname),'file')
            flag(2) = true;
         else
            updateDCFlag(iCh) = true;
            blockObj.Channels(iCh).dcAmpData = ...
               nigeLab.libs.DiskData(blockObj.SaveFormat,fname);
         end
      end
   end
   counter = counter + 1;
   fraction_done = 100 * (counter / numel(blockObj.Mask));
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end
blockObj.updateStatus('Stim',updateStimFlag);
blockObj.updateStatus('DC',updateDCFlag);

end