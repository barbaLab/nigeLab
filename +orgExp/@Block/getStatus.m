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
    OpInd=strcmp(blockObj.updateStatus,stage);
    Status = blockObj.Status(OpInd);
    if isempty(Status)
    end
        warning('No computation stage with that name');
end
