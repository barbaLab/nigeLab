function freeSpace(blockObj,ask)
%% deletes the raw data folders to free some space
if nargin<2
    ask=true;
end

if ask
    promptMessage = sprintf('Do you want to delete the extracted raw files?\nThis procedure is irreversible.');
    button = questdlg(promptMessage, 'Are you sure?', 'Cancel', 'Continue', 'Cancel');
    if strcmpi(button, 'Cancel')
        return;
    end
end

if exist(blockObj.paths.RW,'dir') && any(strcmp('Filt',blockObj.getStatus))
    rmdir(blockObj.paths.RW,'s');
    
    if isfield(blockObj.Channels,'rawData')
        blockObj.Channels = rmfield(blockObj.Channels,'rawData');
    end
    blockObj.updateStatus('Raw',false);
    
end

if exist(blockObj.paths.FW,'dir') && any(strcmp('CAR',blockObj.getStatus))
    rmdir(blockObj.paths.FW,'s');
    
    if isfield(blockObj.Channels,'Filtered')
        blockObj.Channels = rmfield(blockObj.Channels,'Filtered');
    end
    blockObj.updateStatus('Filt',false);    
end

end