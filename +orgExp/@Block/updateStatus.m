function operations = updateStatus(blockObj,operation,value)
%% updates status of block

[~,operations_] = orgExp.defaults.blockDefaults();


switch nargin
    case 1
        operations=operations_;
        return;
    case 2
        if ischar(operation) && strcmp('init',operation)
           blockObj.Status = false(size(operations_));
        else
            error('undefined input parameter %s',operation);
        end
    case 3
        st = strcmp(operations_,operation);
        blockObj.Status(st) = value;
    otherwise
        error('not enough input parameters');
end


end