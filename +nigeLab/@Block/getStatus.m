function Status = getStatus(blockObj,stage)
%% GETSTATUS  Returns the operations performed on the block to date
%
%  Status = GETSTATUS(blockObj,stage);
%
%  --------
%   INPUTS
%  --------
%  blockObj       :     nigeLab.Block class object.
%
%   stage         :     (Char vector) Name of processing stage:
%                       -> 'Raw'          || Has raw data been extracted
%                       -> 'Dig'          || Were digital streams parsed
%                       -> 'Filt'         || Has bandpass filter been done
%                       -> 'CAR'          || Has CAR been done
%                       -> 'LFP'          || Has LFP been extracted
%                       -> 'Spikes'       || Has spike detection been done
%                       -> 'Sorted'       || Has manual sorting been done
%                       -> 'Clusters'     || Has SPC been performed
%                       -> 'Meta'         || Has metadata been parsed
%
%  --------
%   OUTPUT
%  --------
%   Status        :     Returns false if stage is incomplete, or true if
%                          it's complete. If stage is invalid, Status is
%                          returned as empty.
%
% By: FB & MM 2018 MAECI collaboration

%% DEFAULTS
N_CHAR_TO_MATCH = 3;

%%
Status = blockObj.Fields;
% Status = blockObj.updateStatus;   % returns list of available statuses
if nargin<2 % If no input provided
    if any(blockObj.Status)
        Status = Status(blockObj.Status)';
    else
        Status={'none'};
    end
else
   % Only match (case-insensitive) first N chars
    OpInd=strncmpi(Status,stage,N_CHAR_TO_MATCH); 
    Status = blockObj.Status(OpInd);
    if isempty(Status)
      warning('No computation stage with that name');
    end
        
end
