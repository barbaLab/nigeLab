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
ConstructProps = {'Block','Shortcuts','Animal','Tank'};
PropsToSkip ={'nigelColors','Tempdir'};

% Make sure a valid parameter type is selected:
tmp = what('+nigeLab/+defaults');
allDefs = cellfun(@(x)x(1:(end-2)),tmp(1).m,'UniformOutput',false);

% The following properties do not apply or should be set in constructor:
tmp = setdiff(allDefs,[PropsToSkip,ConstructProps]);

if nargin < 2 % if not supplied, select from list...
   idx = promptForParamType(tmp);
   paramType = tmp{idx};
elseif iscell(paramType) % Use recursion to run if cell array is given
   %       flag = false(size(paramType));
   %       for i = 1:numel(paramType)
   %          flag(i) = tankObj.updateParams(paramType{i});
   %       end
   %       return;
   % ;) Max do you like it? -- Isn't this less efficient? You have to load the
   %                           full paramType array into memory each time, so
   %                           you end up taking up a block that is
   %                           N+(N/2)*(N-1). The other way, you take a single
   %                           array element each time, resulting in the
   %                           initial N elements (from the first instance),
   %                           then only N more elements (each loop element).
   %                           So I believe your way is less efficient :P
   %
   %                             But I'm not a computer scientist -- MM
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
   idx = promptForParamType(allDefs);
   paramType = allDefs{idx};
else % even if it does, make sure it has correct syntax...
   paramType = allDefs{idx};
end
end

%% LOAD CORRECT CORRESPONDING PARAMETERS
% at this point paramType should be a simple string
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

for i = 1:numel(tankObj.Animals)
   tankObj.Animals(i).updateParams(paramType);
end

flag = true;

%% SUB-FUNCTIONS
   function idx = promptForParamType(str_options)
      [~,idx] = nigeLab.utils.uidropdownbox(...
         'Select parameters to re-load',...
         'Select parameter TYPE:',...
         str_options);
   end

end

