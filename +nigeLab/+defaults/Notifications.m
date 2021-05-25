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
pars.DBLoc = 'C:/Remote_Matlab_Debug_Logs';
pars.DBFile = 'logs.txt';
pars.DebugOn = false; % Set to true to turn on "remote debug" mode (slower)

% For below, see nigeLab.utils.jobTag2Pct()
pars.TagDelim = '||'; % This should separate TagString between naming and % complete
pars.TagString.String = ['%s.%s %s' pars.TagDelim '%.3d%%']; % regexp for Tag updates
pars.TagString.Vars = {'AnimalID','BlockID'}; % These are matched to blockObj.Meta "special" parsed dynamic variables

% regexp for command window updates
pars.NotifyString.String = '\t%s.%s -> %s: %.3d%%'; 
%    FORMAT  ::             >>[tab]Animal.Block -> operation : DDD%

% Command window update variables
pars.NotifyString.Vars = {'AnimalID','BlockID'}; % These are matched to blockObj.Meta "special" parsed dynamic variables
pars.ConstantString.String = ...
   ['%s', repmat('.%s',1,numel(pars.NotifyString.Vars)-1)];

pars.NotifyTimer = 2; % timer period (seconds) for remote monitor checks
pars.UseParallel=0;
pars.MinIncrement = 5;
pars.CompleteKey = 'Done'; % Keyword for "JOB DONE" state

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

