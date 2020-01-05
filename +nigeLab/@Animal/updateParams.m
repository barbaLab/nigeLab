function flag = updateParams(animalObj,paramType)
%% UPDATEPARAMS   Update the parameters struct property for paramType
%
%  flag = updateParams(animalObj);
%  flag = updateParams(animalObj,paramType);
%
%  --------
%   INPUTS
%  --------
%  animalObj   :     nigeLab.Animal class object.
%
%  paramType   :     (optional; char array) Name of parameter type to
%                       update
%                    -> Can be passed as cell array to update multiple
%                       parameters.
%                    -> If specified as 'all', then initializes all
%                       parameters fields except for Block and Shortcuts.
%
%  --------
%   OUTPUT
%  --------
%    flag      :     Flag indicating if setting new path was successful.
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%% PARSE INPUT
flag = false;
if isempty(animalObj)
   return;
end
ConstructProps = {'Block','Shortcuts','Animal','Tank'};
PropsToSkip ={'nigelColors','Tempdir'};

% Make sure a valid parameter type is selected:
tmp = what('+nigeLab/+defaults');
allDefs = cellfun(@(x)x(1:(end-2)),tmp(1).m,'UniformOutput',false);

% The following properties do not apply or should be set in constructor:
tmp = setdiff(allDefs,[PropsToSkip,ConstructProps]);

if nargin < 2 % if not supplied then it is 'loadParams: all'
   if animalObj.HasParsFile
      flag = loadParams(animalObj);
   end
   return;
elseif iscell(paramType) % Use recursion to run if cell array is given
   N = numel(paramType);
   if N==0
      flag = true;
      return;
   end % ends recursion
   paramType = paramType(:); % just in case it wasn't a vector for some reason;
   flag = animalObj.updateParams(paramType{1}) && animalObj.updateParams(paramType(2:N));
   return;
elseif strcmpi(paramType,'all') % otherwise, if 'all' option is invoked:
   paramType = tmp;
   flag = animalObj.updateParams(paramType);
   return;
   
elseif strcmpi(paramType,'init')
   paramType = ConstructProps;
   flag = animalObj.updateParams(paramType);
   return;
   
else
   % otherwise, check if not an appropriate member
   idx = find(strncmpi(allDefs,paramType,3),1,'first');
   if isempty(idx)
      error(['nigeLab:' mfilename ':BadParamsField'],...
         'Bad animalObj.Pars field name (''%s'')\n',paramType);
   else % even if it does, make sure it has correct syntax...
      paramType = allDefs{idx};
   end
end


%% LOAD CORRECT CORRESPONDING PARAMETERS
% at this point paramType should be a simple char array
if animalObj.HasParsFile
   flag = loadParams(animalObj,paramType);
   if ~flag % If could not load
      applyUpdate(animalObj,paramType); % Then get Pars from defaults
      nigeLab.utils.cprintf('Comments',...
         '\n->\tSaving %s params for ANIMAL %s (User: ''%s'')\n',...
         paramType,animalObj.Name,animalObj.User);
      saveParams(animalObj,animalObj.User,paramType); % Save to file
      flag = true;
   end
   
else   
   % Otherwise just apply update as normal
   applyUpdate(animalObj,paramType);
   nigeLab.utils.cprintf('Comments',...
         '\n->\tSaving %s params for ANIMAL %s (User: ''%s'')\n',...
         paramType,animalObj.Name,animalObj.User);
   saveParams(animalObj,animalObj.User,paramType);
   flag = true;
end

for i = 1:numel(animalObj.Blocks)
   animalObj.Blocks(i).updateParams(paramType);
end

% Helper function to apply update to specific parameter field
   function applyUpdate(animalObj,paramType)
      Pars = nigeLab.defaults.(paramType)();
      F = fields(Pars);
      if isempty(animalObj.Pars)
         animalObj.Pars = struct;
      end
      for ii=1:numel(F)   % populate Pars struct preserving values
         animalObj.Pars.(F{ii}) =  Pars.(F{ii}); % old
      end
      animalObj.Pars.(paramType) = Pars; % new
      if strcmp(paramType,'Block')
         animalObj.Fields = Pars.Fields;
         animalObj.FieldType = Pars.FieldType;
      end
   end

end

