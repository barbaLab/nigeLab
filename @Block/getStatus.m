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
      status = parseStatus(blockObj,operation);
      
   case 3 % If channel is given
      status = parseStatus(blockObj,operation);
      status = ~any(~status(channel));
      
   otherwise
      error('Too many input arguments (%d; max: 3).',nargin);
end

   function status = parseStatus(blockObj,stage)
      %% PARSESTATUS  Check that it is a valid stage and return the output
      if ~iscell(stage)
         stage = {stage};
      end
      opInd=ismember(blockObj.Fields,stage);
      
      if sum(opInd) < numel(stage)
         warning('No computation stage with that name (%s).',stage{:});
         status = false;
      elseif (sum(opInd) > numel(stage))
         warning('Stage name is ambiguous (%s).',stage{:});
         status = false;
      else
         status = false(size(stage));
         if numel(stage) == 1 % If only one stage, return all channel status
            status = blockObj.Status.(stage{1});
         else
            for ii = 1:numel(stage) % Otherwise, just get whether stages are complete
               status(ii) = any(blockObj.Status.(stage{ii}));
            end
         end
      end
   end
end
