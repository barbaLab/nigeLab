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
%
% By: Max Murphy  & Fred Barban MAECI 2018 collaboration

%% DEFAULTS
N_CHAR_COMPARE = 7;

%% PARSE INPUT FOR MULTIPLE COMMANDS
if nargin > 2
   if iscell(operation) && iscell(value)
      if numel(operation)~=numel(value)
         error(['''operation'' (%d) and ''value'' (%d) must have same' ...
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
% Do it this way instead of referencing blockObj.Fields, so that in case
% Block.m in +defaults is modified, the possible fields can be changed
% dynamically.... Although I am not sure that this will ever come up in
% practice once debugging is complete (I hope?)
[~,allPossibleOperations] = nigeLab.defaults.Block();

switch nargin
   case 0 % Must have input arguments (method of nigeLab.Block class)
      error('Not enough input arguments.');
      
   case 1 % If no input just return all the possible operations
      opOut=allPossibleOperations(1:end);
      return;
      
   case 2 % If only 1 input, 'init' command resets status of all
      if ~ischar(operation)
         error('operation input argument must be a char');
      end
      
      if strncmpi('init',operation,N_CHAR_COMPARE)
         blockObj.Status = struct; % Change this to a struct
         for i = 1:numel(allPossibleOperations)
             switch blockObj.FieldType{i}
                 case 'Channels'
                     n = blockObj.NumChannels;
                 case 'Streams'
                     n = numel(blockObj.Streams.(allPossibleOperations{i}));
                 case 'Videos'
                     n = numel(blockObj.Videos);
                 otherwise
                     strNumCh = ['Num' allPossibleOperations{i}];
                     if isprop(blockObj,strNumCh)
                         n = blockObj.(strNumCh);
                     else
                         n = 1;
                     end                     
             end
             blockObj.Status.(allPossibleOperations{i}) = ...
                 false(1,n);
         end      
         blockObj.Fields = allPossibleOperations;
      else
         error('''operation'' input argument is not valid (%s)',operation);
      end
      opOut = [];
      
   case 3 % If 2 inputs, set value of that operation status to value
      if ~ischar(operation)
         error('operation input argument must be a char');
      end
      idx = find(strncmpi(allPossibleOperations,operation,N_CHAR_COMPARE));
      if ~isempty(idx)
         opOut = allPossibleOperations{idx};
         blockObj.Status.(opOut) = value;
         % If it hadn't been parsed into Fields property, add it
         if ~ismember(opOut,blockObj.Fields)
            blockObj.Fields = [blockObj.Fields; opOut];
         end
      else
         opOut = [];
      end
      
   case 4 % If 3 inputs, set value of a channel for operation to value
      if ~ischar(operation)
         error('operation input argument must be a char');
      end
      idx = find(strncmpi(allPossibleOperations,operation,N_CHAR_COMPARE));
      if ~isempty(idx)
         opOut = allPossibleOperations{idx};
         blockObj.Status.(opOut)(channel) = value;
         if ~ismember(opOut,blockObj.Fields)
            blockObj.Fields = [blockObj.Fields; opOut];
         end
      else
         opOut = [];
      end
      
   otherwise
      error('Too many input arguments (%d; max: 4).',nargin);
end

end