function varargout = Notifications(varargin)
% NOTIFICATIONS     Default notifications parameters for nigeLab
%
%  pars = nigeLab.defaults.Notifications(); Returns full struct
%  pars = nigeLab.defaults.Notifications('paramName'); Returns single param
%  [par1,par2,...] = nigeLab.defaults.Notifications('pName1','pName2',...);
%  --> Return multiple specific parameter names

%%
pars = struct;
pars.NMaxNameChars = 15;  % If less than this, uses full name on notifications

% For below, see nigeLab.utils.jobTag2Pct(), as well as Block method
% notifyUser():
pars.TagDelim = '||'; % This should separate TagString between naming and % complete
pars.TagString.String = ['%s.%s %s' pars.TagDelim '%.3d%%']; % regexp for Tag updates
pars.TagString.Vars = {'AnimalID','RecID'};
%               Animal.Block operation TagDelim progress


% regexp for command window updates
pars.NotifyString.String = '\t%s.%s -> %s: %.3d%%'; 
% Command window update variables
pars.NotifyString.Vars = {'AnimalID','RecID'};
%                 Animal.Block -> operation : progress
pars.NotifyTimer = 0.5; % timer period (seconds) for remote monitor checks
pars.UseParallel=0;
pars.MinIncrement = 5;

% Fixed "normalized" prog bar height
pars.FixedProgBarHeightNormUnits = 0.12; 

%% Error checking and assignment
if nargin > 0
   varargout = cell(1,nargin);
   f = fieldnames(pars);
   for i = 1:nargin
      idx = ismember(lower(f),varargin{i});
      if sum(idx) < 1
         warning('Could not find parameter: %s (returned [])',varargin{i});
         varargout{i} = [];
      elseif sum(idx) > 1
         warning('Parameter is ambiguously named: %s (returned [])',varargin{i});
         varargout{i} = [];
      else
         varargout{i} = pars.(f{idx});
      end
   end
else
   varargout = {pars};
      
end

end

