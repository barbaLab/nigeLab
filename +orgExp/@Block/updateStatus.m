function operations = updateStatus(blockObj,operation,value)
%% updates status of block
% possible operations are:
% 'ext'             extraction
% 'filt'            filtering
% 'CAR'             re referencing
% 'LFP'             local field potential
% 'SD'              spike detection
% 'sorting'         sorting

operations = {'ext';
              'filt';
              'CAR';
              'LFP';
              'SD';
              'sorting';
              '';
              '';
                };

if nargin<2
    return;
elseif nargin == 3
    st = strcmp(operations,operation);
    blockObj.Status(st) = value;
else
   error('not enough input parameters'); 
end


end