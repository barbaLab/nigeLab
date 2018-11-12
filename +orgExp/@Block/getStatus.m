function Status = getStatus(blockObj,stage)
%% Returns the operations performed on the block to date

Status = blockObj.updateStatus;   % returns list of available statuses
if nargin<2
    if any(blockObj.Status)
        Status = Status(blockObj.Status)';
    else
        Status={'none'};
    end
else
    Status = blockObj.Status(strcmp(blockObj.updateStatus,stage));
end

