function status = getStatus(blockObj,varargin)
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

if ~isscalar(blockObj)
    stat = cell(size(blockObj(:)));
    for bb = 1:numel(blockObj)
        stat{bb,1} = getStatus(blockObj(bb),varargin{:});
    end
    switch nargin
        case 1
            status = stat;
        case 2
            if isempty(varargin{1})
                status = cat(1,stat{:});
            elseif iscell(varargin{1})
                if isscalar(varargin{1})
                    status = cellfun(@all,stat);
                else
                    status = cat(1,stat{:});
                end
            elseif ischar(varargin{1})
                status = cellfun(@all,stat);
            end
        otherwise
            status = cat(2,stat{:});
    end
    return;
end

switch nargin
    case 1
        field = blockObj.Fields;
        channel = 'all';
    case 2
        channel = 'all';
        field = varargin{1};
        if isempty(field) || any(strcmp(field,'all'))
            field = blockObj.Fields;
        end
    case 3
        field = varargin{1};
        channel = varargin{2};
        if isempty(field) || any(strcmp(field,'all'))
            field = blockObj.Fields;
        end
        if isempty(channel) 
            channel = 'all';
        end
end
if ~iscell(field),field = {field};end
% Handle array of block objects
stat = parseStatus(blockObj,field);



%% Behavior depends on total number of inputs
switch nargin
   case 1 % Only blockObj is given (1 input)

      status = field(stat)';
      if isempty(status)
          status = {'none'};
      end
    case 2
        status = stat;
    case 3 
     if isscalar(field)
         if strcmp(channel,'all')
             idx = ismember(field,blockObj.Fields);
             channel = 1:numel(blockObj.(blockObj.FieldType{idx}));
         end
        status = all(stat(channel),2);
     end
   otherwise
      error(['nigeLab:' mfilename ':tooManyInputArgs'],...
         'Too many input arguments (%d; max: 3).',nargin);
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
         maskExists = ~isempty(blockObj.Mask);
         % If only one stage, return all channel status
         if numel(stage) == 1 
            status = blockObj.Status.(stage{:});
            channelStage = strcmp(blockObj.getFieldType(stage{:}),'Channels');
            if maskExists && channelStage
               vec = 1:numel(status);
               % Masked channels are automatically true
               status(setdiff(vec,blockObj.Mask)) = true;
            end
         else
            status = false(size(stage));
            status = reshape(status,1,numel(status));
            % Otherwise, just get whether stages are complete
            for ii = 1:numel(stage) 
               channelStage = strcmp(blockObj.getFieldType(stage{ii}),...
                                     'Channels');
               if isfield(blockObj.Status,stage{ii})
                  flags = blockObj.Status.(stage{ii});
               elseif channelStage
                  flags = false(1,blockObj.NumChannels); 
               else
                  flags = false;
               end
               % If this is a 'Channels' FieldType Stage AND there is a
               % Channel Mask specified, then require ALL elements to be
               % true; otherwise, just require 'Any' element to be true
               if channelStage && maskExists
                  status(ii) = all(flags(blockObj.Mask));
               else
                  status(ii) = all(flags);
               end
               
            end
         end
      end
   end
end
