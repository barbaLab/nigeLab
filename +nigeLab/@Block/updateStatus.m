function opOut = updateStatus(blockObj,operation,value,channel)
%% UPDATESTATUS  Updates Status property of nigeLab.Block class object
%
%  opOut = UPDATESTATUS(blockObj);
%  opOut = UPDATESTATUS(blockObj,operation);
%  opOut = UPDATESTATUS(blockObj,operation,value);
%  opOut = UPDATESTATUS(blockObj,operation,value,channel);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     nigeLab.Block class object.
%
%  operation   :     Operation (stage/field) to set the status of
%                       processing for that stage.
%
%                    -> 'init' // Set all fields to false
%                    -> 'raw' // etc... anything in nigeLab.Block class
%                                         property Fields.
%
%                    -> Can be given as a cell array, with value given as a
%                       matching corresponding cell array.
%
%   value      :     Value to set the status to
%
%   channel    :     Channel to set that particular status for
%
%  --------
%   OUTPUT
%  --------
%    opOut     :     Returns a list of operations from Block defaults m
%                       file, which can be adjusted as a template by the
%                       user.

%% PARSE INPUT FOR MULTIPLE COMMANDS
if nargin > 2
   if iscell(operation) && iscell(value)
      if numel(operation)~=numel(value)
         error(['nigeLab:' mfilename ':InputSizeMismatch'],...
            ['"operation" (%d) and "value" (%d) must have same' ...
            ' number of elements if given as cell array.'],...
            numel(operation), numel(value));
      end
      % Use recursion if given as cell array
      opOut = [];
      for i = 1:numel(operation)
         opOut = [opOut; {updateStatus(blockObj,operation{i},value{i})}]; %#ok<AGROW>
      end
      return;
   end
end

%%
allOps = blockObj.Fields;

switch nargin
   case 0 % Must have input arguments (method of nigeLab.Block class)
      error(['nigeLab:' mfilename ':TooFewInputArgs'],...
             'Not enough input arguments.');
      
   case 1 % If no input just return all the possible operations
      opOut=allOps(1:end);
      return;
      
   case 2 % If only 1 input, 'init' command resets status of all
      if ~ischar(operation)
         error(['nigeLab:' mfilename ':BadInputType2'],...
            '"operation" input argument must be a char (was %s)',...
            class(operation));
      end
      
      if strcmpi('init',operation)
         blockObj.Status = struct; % Change this to a struct
         for i = 1:numel(allOps)
            switch blockObj.FieldType{i}
               case 'Channels'
                  n = blockObj.NumChannels;
               case 'Streams'
                  n = numel(blockObj.Streams.(allOps{i}));
               case 'Videos'
                  n = numel(blockObj.Videos);
               otherwise
                  strNumCh = ['Num' allOps{i}];
                  if isprop(blockObj,strNumCh)
                     n = blockObj.(strNumCh);
                  else
                     n = 1;
                  end
            end
            blockObj.Status.(allOps{i}) = ...
               false(1,n);
            notifyStatus(blockObj,allOps{i},false(1,n));
         end
         blockObj.Fields = allOps;
      elseif strcmpi('notify',operation)
         allOps = reshape(fieldnames(blockObj.Status),1,...
            numel(fieldnames(blockObj.Status)));
         for op = allOps
            notifyStatus(blockObj,op{:},blockObj.Status.(op{:}));
         end
         opOut = [];
         return;
      else
         error(['nigeLab:' mfilename ':BadInputType3'],...
            'If only "operation" is provided, must be ''init''');
      end
      opOut = [];
      
   case 3 % If 2 inputs, set value of that operation status to value
      if ~ischar(operation)
         error(['nigeLab:' mfilename ':BadInputType2'],...
            '"operation" input argument must be a char (currently: %s)',...
            class(operation));
      end
      idx = find(strcmpi(allOps,operation));
      if ~isempty(idx)
         opOut = allOps{idx};
         blockObj.Status.(opOut) = value;
         % If it hadn't been parsed into Fields property, add it
         if ~ismember(opOut,blockObj.Fields)
            blockObj.Fields = [blockObj.Fields; opOut];
         end
         notifyStatus(blockObj,opOut,blockObj.Status.(opOut));
      else
         opOut = [];
      end
      
   case 4 % If 3 inputs, set value of a channel for operation to value
      if ~ischar(operation)
         error(['nigeLab:' mfilename ':BadInputType2'],...
            '"operation" input argument must be a char (currently: %s)',...
            class(operation));
      end
      idx = strcmpi(allOps,operation);
      if sum(idx)==1
         opOut = allOps{idx};
         blockObj.Status.(opOut)(channel) = value;
         if ~ismember(opOut,blockObj.Fields)
            blockObj.Fields = [blockObj.Fields; opOut];
         end
         notifyStatus(blockObj,opOut,blockObj.Status.(opOut));
      else
         opOut = [];
      end
      
      return;
   otherwise
      error(['nigeLab:' mfilename ':TooManyInputArgs'],...
         'Too many input arguments (%d; max: 4).',nargin);
end

end