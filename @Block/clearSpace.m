function flag = clearSpace(blockObj,ask)
%% CLEARSPACE   Delete the raw data folder to free some storage space
%
%  b = nigeLab.Block;
%  flag = clearSpace(b);
%  flag = clearSpace(b,ask);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     orgExp BLOCK class.
%
%    ask       :     True or false. CAUTION: setting this to false and
%                       running the CLEARSPACE method will automatically
%                       delete the rawData folder and its contents, without
%                       prompting to continue.
%
%  --------
%   OUTPUT
%  --------
%    flag      :     Boolean flag to report whether data was deleted.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% CHECK TO MAKE SURE IF WE SHOULD CONTINUE
if nargin<2
   ask=true;
end

flag = false;
fprintf(1,'%s\n---------------------\n',blockObj.Name);

if ask
   promptMessage = sprintf(['Do you want to delete the extracted ' ...
                           'raw files?\nThis procedure is irreversible.']);
   button = questdlg(promptMessage, 'Are you sure?', ...
                     'Cancel', 'Continue', 'Cancel');
   if strcmpi(button, 'Cancel')
      fprintf(1,'-> No data deleted.\n');
      return;
   end
end

%% REMOVE RAW DATA FOLDER AND CONTENTS
if exist(blockObj.paths.RW,'dir') && any(strcmp('Filt',blockObj.getStatus))
   rmdir(blockObj.paths.RW,'s');
   
   if isfield(blockObj.Channels,'rawData')
      blockObj.Channels = rmfield(blockObj.Channels,'rawData');
   end
   blockObj.updateStatus('Raw',false);
   fprintf(1,'-> Raw data folder and contents deleted.\n');
end

%% REMOVE FILTERED DATA FOLDER AND CONTENTS
% Only if there exists a CAR folder, since they are presumably redundant
if exist(blockObj.paths.FW,'dir') && any(strcmp('CAR',blockObj.getStatus))
   rmdir(blockObj.paths.FW,'s');
   
   if isfield(blockObj.Channels,'Filtered')
      blockObj.Channels = rmfield(blockObj.Channels,'Filtered');
   end
   blockObj.updateStatus('Filt',false);
   fprintf(1,'-> Filtered data folder and contents deleted.\n');
end

flag = true;

end