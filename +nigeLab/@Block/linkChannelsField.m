function flag = linkChannelsField(blockObj,field,fileType)
%% LINKCHANNELSFIELD  Connect the data saved on the disk to Channels
%
%  b = nigeLab.Block;
%  field = 'Spikes';       % field = 'Raw'
%  fileType = 'Event';   % filetype = 'Hybrid'
%  flag = LINKCHANNELSFIELD(b,field,fileType);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
flag = false;
% updateFlag is for the total number of channels
updateFlag = false(1,blockObj.NumChannels);
   str = ['Linking <a href="matlab:doc nigelab.Block\Channels">Channels</a> field: ',field];
blockObj.reportProgress(str,0);

nigeLab.utils.printLinkFieldString(blockObj.getFieldType(field),field);
counter = 0;

% Only iterate on the channels we care about (don't update status for
% others, either). 
for iCh = blockObj.Mask
   
   % Get file name
   pNum  = num2str(blockObj.Channels(iCh).port_number);
   chNum = num2str(blockObj.Channels(iCh).native_order,'%03g');
   fName = sprintf(strrep(blockObj.Paths.(field).file,'\','/'), ...
      pNum,chNum);
   fName = fullfile(fName);
   
   % If file is not detected
   if ~exist(fullfile(fName),'file')
      flag = true;
   else
      updateFlag(iCh) = true;
      switch fileType
         case 'Event' % If it's a 'spikes' file
            try % Channels can also have channel events
               blockObj.Channels(iCh).(field) = ...
                  nigeLab.libs.DiskData(fileType,fName);
            catch % If spikes exist but in "bad format", fix that
               updateFlag(iCh) = blockObj.checkSpikeFile(fName);
            end
         otherwise
            % Each element of Channels will have different kinds of data
            % (e.g. 'Raw', 'Filt', etc...)
            blockObj.Channels(iCh).(field) = ...
               nigeLab.libs.DiskData(fileType,fName);
      end
   end
   
   counter = counter + 1;
   pct = 100 * (counter / numel(blockObj.Mask));
%    fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct))
blockObj.reportProgress(str,pct);
end
% Only update status of unmasked channels. The other ones shouldn't matter
% when are looking at 'doAction dependencies' later.
blockObj.updateStatus(field,updateFlag);

end