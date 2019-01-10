function CRC_SubmitPushCallback(~,~,obj)
%% CRC_SUBMITPUSHCALLBACK  Callback function for SUBMIT pushbutton

% Make sure you've looked at all channels
if any(~obj.Data.files.submitted)
   ch_ind = find(~obj.Data.files.submitted,1,'first');
   beep;
   msg = questdlg(sprintf('%s not yet combined. Submit anyways?',...
      obj.Data.UI.channels{ch_ind}),...
      'Unsorted Channel','Yes','No','No');
   if ~strcmp(msg,'Yes')
      chanpop.Value = ch_ind;
      CRC_ChannelPopCallback(chanpop);
      return;
   end
end

% Make sure you want to save to the default directory
if exist(obj.Data.files.sort.folder,'DIR')==0
   mkdir(obj.Data.files.sort.folder);
else
   str = questdlg(sprintf(['Existing directory:\n%s\n\n' ...
      'Make new directory?'],obj.Data.files.sort.folder), ...
      'Sorted spikes detected', ...
      'New','Overwrite','Cancel','New');
   switch str
      case 'New'  % Allow user to specify a new directory name
         folder_out = inputdlg(...
            'New tag to append to _Sorted directory:', ...
            'Create new folder', 1, ...
            {'[tag]'});
         if isempty(folder_out)
            disp('No sort created.');
            return;
         end
         folder_out = folder_out{1};
         folder_out = strrep(folder_out,'[','');
         folder_out = strrep(folder_out,']','');
         folder_out = strrep(folder_out,'-','');
         folder_out = strrep(folder_out,'_','');
         if isempty(folder_out)
            error(['No valid characters in tag name. Do not use ' ...
               '"-" or "_" or "[" or "]".']);
         end
         folder_out = strrep(obj.Data.files.sort.folder,...
                    obj.Data.OUT_ID,...
                    [obj.Data.OUT_ID folder_out]);
         
         if exist(folder_out,'DIR')==0
            obj.Data.files.sort.folder = folder_out;
            mkdir(obj.Data.files.sort.folder);
         else
            error(['Directory already exists.' ...
               ' Files not saved.']);
         end
      case 'Overwrite' % Delete old directory and remake
         rmdir(obj.Data.files.sort.folder,'s');
         mkdir(obj.Data.files.sort.folder);
         fprintf(1,'Files in %s overwritten.\n', ...
            obj.Data.files.sort.folder);
      otherwise   % Otherwise cancel
         fprintf(1,'Sorting not saved.\n');
   end
end

% After getting directory info, loop through and save channel info.
for ch = 1:obj.Data.files.N
   CRC_SaveChannelSpikeClusters(obj,ch);
end

% Alert user
beep; pause(0.1); beep; pause(0.25); beep; pause(0.5); beep; 
pause(0.1); beep; pause(0.3); beep; % because I'm obnoxious

% If debugging, update obj.Data in base workspace
if obj.Data.DEBUG
   handles = obj.Data;
   CRC_mtb(handles);
end

end