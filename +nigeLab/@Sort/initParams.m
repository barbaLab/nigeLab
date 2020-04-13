function flag = initParams(sortObj,nigelObj)
%INITPARAMS  Initialize parameters structure for Spike Sorting UI.
%
%  flag = INITPARAMS(sortObj);
%  --> Load `Sort` defaults from nigeLab.defaults.Sort();
%  
%  flag = INITPARAMS(sortObj,nigelObj);
%  --> Load `Sort` parameters from nigelObj directly

% MODIFY SORT CLASS OBJECT PROPERTIES HERE
flag = false;

if nargin < 2
   pars = nigeLab.defaults.Sort();
   flag = true;
else
   pars = cell(size(nigelObj)); % In case it is array
   [pars{:}] = getParams(nigelObj,'Sort');
   pars(cellfun(@isempty,pars)) = [];
   if isempty(pars)
      warning(['[INITPARAMS]: Array of %g %g objects does not ' ...
         'have `Sort` parameters initialized yet.\n'],...
         numel(nigelObj),class(nigelObj));
      return;
   elseif isscalar(pars)
       flag = true;
   elseif isequal(pars{:})
      flag = true;
   else
      warning(['[INITPARAMS]: Array of %g %g objects does not ' ...
         'contain identical `Sort` parameters for each object.\n'],...
         numel(nigelObj),class(nigelObj));
      return;
   end
end

% UPDATE PARS PROPERTY
sortObj.pars = pars{1};


end