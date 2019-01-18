function status = getStatus(blockObj,operation,channel)
%% GETSTATUS  Returns the operations performed on the block to date
%
%  status = GETSTATUS(blockObj);
%  status = GETSTATUS(blockObj,operation);
%  status = GETSTATUS(blockObj,operation,channel);
%
%  --------
%   INPUTS
%  --------
%  blockObj       :     nigeLab.Block class object.
%
%  operation      :     (Char vector) Name of processing stage:
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
%  channel       :     (optional) Default: Set as a channel or array of
%                          channels, which must all return a true value for
%                          the selected operation Status in order for the
%                          output of getStatus() to return as true.
%
%  --------
%   OUTPUT
%  --------
%   status        :     Returns false if stage is incomplete, or true if
%                          it's complete. If stage is invalid, Status is
%                          returned as empty.
%
% By: FB & MM 2018 MAECI collaboration

%% DEFAULTS
N_CHAR_TO_MATCH = 7;

%%
switch nargin
   case 0
      error('Not enough input arguments provided.');
      
   case 1 % If no input provided
      f = fieldnames(blockObj.Status);
      stat = false(size(f));
      for i = 1:numel(f)
         stat(i) = ~any(~blockObj.Status.(f{i}));
      end
      
      % Give names of all completed operations
      if any(stat)
         status = blockObj.Fields(stat)';
      else
         status={'none'};
      end
      
   case 2 % If one input given
      status = parseStatus(blockObj,operation,N_CHAR_TO_MATCH);
      
   case 3 % If optional 'all' argument is given
      status = parseStatus(blockObj,operation,N_CHAR_TO_MATCH);
      status = ~any(~status(channel));
      
   otherwise
      error('Too many input arguments (%d; max: 3).',nargin);
end

   function status = parseStatus(blockObj,stage,nMatch)
      %% PARSESTATUS  Check that it is a valid stage and return the output
      opInd=strncmpi(blockObj.Fields,stage,nMatch);
      
      if sum(opInd)==0
         warning('No computation stage with that name (%s).',stage);
         status = false;
      elseif sum(opInd) > 1
         warning('Stage name is ambiguous (%s).',stage(1:nMatch));
         status = false;
      else
         opName = blockObj.Fields{opInd};

         if ismember(opName,fieldnames(blockObj.Status))
            status = blockObj.Status.(opName);
         else
            warning('No computation stage with that name (%s).',opName);
            status = false;
         end
      end
   end
end
