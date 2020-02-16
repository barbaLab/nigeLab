function mtb(variable,varargin)
%MTB  Move variable to base workspace
% 
%  nigeLab.utils.mtb(variable)
%
%  nigeLab.utils.mtb('varName',varValue);
%
%  nigeLab.utils.mtb('var1_name',var1,'var2_name',var2,...)
%
%   --------
%    INPUTS
%   --------
%   variable    :       Variable from current workspace that you want to
%                       move to base (main) workspace.

% Determine what to do based on number inputs
if nargin == 1
    mult_sel = false;
else
    mult_sel = true;
end

% Move variable(s) to new workspace
if mult_sel
    varargin = reshape(varargin,numel(varargin),1);
    varargin = [variable; varargin];
    nVar = numel(varargin);
    for iV = 1:2:nVar
        var_name = varargin{iV};
        assignin('base',var_name,varargin{iV+1});
    end
else
    var_name = inputname(1);
    assignin('base',var_name,variable);
end

end