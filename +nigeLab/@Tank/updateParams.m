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
tmp = cellfun(@(x)x(1:(end-2)),tmp(1).m,'UniformOutput',false);

% The following properties do not apply or should be set in constructor:
tmp = setdiff(tmp,[PropsToSkip,ConstructProps]); 

if nargin < 2 % if not supplied, select from list...
   idx = promptForParamType(tmp);
   paramType = tmp{idx};
elseif strcmpi(paramType,'all') % otherwise, if 'all' option is invoked:
    paramType = tmp;
    flag = tankObj.updateParams(paramType);
    return;
elseif iscell(paramType) % Use recursion to run if cell array is given
%       flag = false(size(paramType));
%       for i = 1:numel(paramType)
%          flag(i) = tankObj.updateParams(paramType{i});
%       end
%       return;      
% ;) Max do you like it?
        N = numel(paramType);
        if N==0, flag = true; return; end % ends recursion
        paramType = paramType(:); % just in case it wasn't a vector for some reason;
        flag = tankObj.updateParams(paramType(2:N)) && tankObj.updateParams(paramType{1});
        return;
elseif any(ismember(paramType,ConstructProps))
    ... Right now no action is required here
else
   % otherwise, check if not an appropriate member
   idx = find(strncmpi(tmp,paramType,3),1,'first');
   if isempty(idx)
      idx = promptForParamType(tmp);
      paramType = tmp{idx};
   else % even if it does, make sure it has correct syntax...
      paramType = tmp{idx};
   end
end

%% LOAD CORRECT CORRESPONDING PARAMETERS
% at this point paramType should be a simple string
Pars = nigeLab.defaults.(paramType)();
F = fields(Pars);
for ii=1:numel(F)   % populate Pars struct preserving values
    tankObj.Pars.(F{ii}) =  Pars.(F{ii});
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

