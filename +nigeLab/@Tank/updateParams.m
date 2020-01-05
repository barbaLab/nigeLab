function flag = updateParams(tankObj,paramType)
%% UPDATEPARAMS   Update the nigeLab.Tank class default parameters for paramType
%
%  flag = updateParams(tankObj);
%  flag = updateParams(tankObj,paramType);
%
%  --------
%   INPUTS
%  --------
%  tankObj     :     nigeLab.Tank class object.
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
if isempty(tankObj)
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
   if tankObj.HasParsFile
      flag = tankObj.loadParams();
      if ~flag
         flag = tankObj.updateParams('all'); % Then load all from +defaults
      end
   end
   return;
elseif iscell(paramType) % Use recursion to run if cell array is given
   N = numel(paramType);
   if N==0, flag = true; return; end % ends recursion
   paramType = paramType(:); % just in case it wasn't a vector for some reason;
   flag = tankObj.updateParams(paramType(2:N)) && tankObj.updateParams(paramType{1});
   return;
elseif strcmpi(paramType,'all') % otherwise, if 'all' option is invoked:
   paramType = tmp;
   flag = tankObj.updateParams(paramType);
   return;
   
elseif strcmpi(paramType,'init')
   paramType = ConstructProps;
   flag = tankObj.updateParams(paramType);
   return;
   
else
   % otherwise, check if not an appropriate member
   idx = find(strncmpi(allDefs,paramType,3),1,'first');
   if isempty(idx)
      error(['nigeLab:' mfilename ':BadParamsField'],...
         'Bad tankObj.Pars field name (''%s'')\n',paramType);
   else % even if it does, make sure it has correct syntax...
      paramType = allDefs{idx};
   end
end

%% LOAD CORRECT CORRESPONDING PARAMETERS
% at this point paramType should be a simple char array
if tankObj.HasParsFile
   flag = tankObj.loadParams(paramType);
   if ~flag % If could not load
      applyUpdate(tankObj,paramType); % Then get Pars from defaults
      nigeLab.utils.cprintf('Comments',...
         '\n->\tSaving %s params for TANK %s (User: ''%s'')\n',...
         paramType,tankObj.Name,tankObj.User);
      saveParams(tankObj,tankObj.User,paramType); % Save to file
      flag = true;
   end
else
   applyUpdate(tankObj,paramType);
   nigeLab.utils.cprintf('Comments',...
         '\n->\tSaving %s params for TANK %s (User: ''%s'')\n',...
         paramType,tankObj.Name,tankObj.User);
   tankObj.saveParams(tankObj.User,paramType);
   flag = true;
end

for i = 1:numel(tankObj.Animals)
   tankObj.Animals(i).updateParams(paramType);
end

% Helper function to apply update to specific parameter field
   function applyUpdate(tankObj,paramType)
      Pars = nigeLab.defaults.(paramType)();
      F = fields(Pars);
      if isempty(tankObj.Pars)
         tankObj.Pars = struct;
      end
      for ii=1:numel(F)   % populate Pars struct preserving values
         tankObj.Pars.(F{ii}) =  Pars.(F{ii}); % for backwards-compatible
      end
      tankObj.Pars.(paramType) = Pars; % For future
      if strcmp(paramType,'Block')
         tankObj.Fields = Pars.Fields;
         tankObj.FieldType = Pars.FieldType;
      end
   end

end

