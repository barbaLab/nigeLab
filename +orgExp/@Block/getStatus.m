function Status = getStatus(blockObj)
%% Returns the operations performed on the block to date

Status = blockObj.updateStatus;   % returns list of available statuses
if any(blockObj.Status)
    Status = Status{blockObj.Status};
else
    Status={'none'};
end

