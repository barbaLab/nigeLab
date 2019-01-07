function CRC_mtb(variable,varargin)
%% MTB  Move variable to base workspace
%
%   MTB(variable)
%
%   MTB('var1_name',var1,'var2_name',var2,...)
%
%   --------
%    INPUTS
%   --------
%   variable    :       Variable from current workspace that you want to
%                       move to base (main) workspace.
%
% By: Max Murphy    v1.0    03/23/2017


%% CHECK NUMBER OF ARGUMENTS IN

if nargin == 1
   mult_sel = false;
else
   mult_sel = true;
end

%% MOVE VARIABLE OR VARIABLES

if mult_sel
   varargin = reshape(varargin,numel(varargin),1);
   varargin = [variable; varargin];
   nVar = numel(varargin);
   for iVar = 1:2:nVar
      var_name = varargin{iVar};
      assignin('base',var_name,varargin{iVar+1});
   end
else
   var_name = inputname(1);
   assignin('base',var_name,variable);
end

end