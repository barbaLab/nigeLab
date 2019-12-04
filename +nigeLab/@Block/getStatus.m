function status = getStatus(blockObj,field,channel)
% GETSTATUS  Returns the operations performed on the block to date
%
%  status = GETSTATUS(blockObj);
%  status = GETSTATUS(blockObj,field);
%  status = GETSTATUS(blockObj,field,channel);
%
%  --------
%   INPUTS
%  --------
%  blockObj       :     nigeLab.Block class object.
%
%    field        :     (Char vector) Name of processing stage:
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
      
      status = parseStatus(blockObj,field);
      if isfield(blockObj.Pars,'Video') && status
         if ~isempty(blockObj.Pars.Video.ScoringEventFieldname)
            switch field
               case blockObj.Pars.Video.ScoringEventFieldname
                  if ~isstruct(blockObj.Scoring)
                     blockObj.Scoring = struct;
                  end
                  if ~isfield(blockObj.Scoring,'Status')
                     blockObj.Scoring.Status = struct;
                  end
                  if ~isfield(blockObj.Scoring.Status,'Video')
                     blockObj.Scoring.Status.Video = [];
                  end
                  if ~isfield(blockObj.Scoring,'Video')
                     status = false; 
                     return;
                  end
                  
                  if isempty(blockObj.Scoring.Video)
                     status = false;
                     return;
                  end
                  
                  status = strcmpi(blockObj.Scoring.Video.Status{...
                     size(blockObj.Scoring.Video,1)},'Complete');
               otherwise
                  % do nothing
            end
         end
      end
      
   case 3 % If channel is given
      status = parseStatus(blockObj,field);
      status = ~any(~status(channel));
      
   otherwise
      error('Too many input arguments (%d; max: 3).',nargin);
end

   function status = parseStatus(blockObj,stage)
      % PARSESTATUS  Check that it is a valid stage and return the output
      %
      %  status = parseStatus(blockObj,stage);
      %
      %  stage  --  Char array or cell of char arrays
      
      % Ensure that stage is a cell so that checks return correct number of
      % elements (one per "word")
      if ~iscell(stage)
         stage = {stage};
      end
      opInd=ismember(blockObj.Fields,stage);
      
      % If "stage" doesn't belong, throw an error.
      if sum(opInd) < numel(stage)
         warning('No Field with that name (%s).',stage{:});
         status = false;
         
      % Otherwise, if there are too many matches, that is also not good.
      elseif (sum(opInd) > numel(stage))
         warning('Stage name is ambiguous (%s).',stage{:});
         status = false;
         
      else
         status = false(size(stage));
         % If only one stage, return all channel status
         if numel(stage) == 1 
            status = blockObj.Status.(stage{:});
            
         else
            % Otherwise, just get whether stages are complete
            maskExists = ~isempty(blockObj.Mask);
            for ii = 1:numel(stage) 
               channelStage = strcmp(blockObj.getFieldType(stage{ii}),...
                                     'Channels');
               flags = blockObj.Status.(stage{ii});
               % If this is a 'Channels' FieldType Stage AND there is a
               % Channel Mask specified, then require ALL elements to be
               % true; otherwise, just require 'Any' element to be true
               if channelStage && maskExists
                  status(ii) = all(flags(blockObj.Mask));
               else
                  status(ii) = any(flags);
               end
               
            end
         end
      end
   end
end
