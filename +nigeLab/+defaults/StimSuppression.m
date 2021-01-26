function varargout = StimSuppression(varargin)
%% defaults.StimSuppression    Initialize parameters for stimulation suppression
%
%   pars = nigeLab.defaults.StimSuppression('NAME',value,...);
%
%
% By: MAECI 2020 collaboration (Max Murphy & Federico Barban)

pars.Method = 'softpoly';

pars.StimIdx = 'all';       % index of the stimultation pulses to correct. 
pars.stimL = 400e-6;        % Stimulation legth [s] 


%% UNLIKELY TO CHANGE
% Parameters for each type stored as individual files in ~/+SD
StimSuppressionPath = fullfile(nigeLab.utils.getNigelPath,...
   '+nigeLab','+defaults','+StimSuppression');
% Load all the method-specific parameters:
SDConfigFiles = dir(fullfile(StimSuppressionPath,'*.m'));
for ff = SDConfigFiles(:)'
   parName = ff.name(1:end-2); % dropping .m
   pars.(parName) = eval(sprintf('nigeLab.defaults.StimSuppression.%s',...
      parName));
end


%% Parse output
if nargin < 1
   varargout = {pars};
else
   varargout = cell(1,nargin);
   f = fieldnames(pars);
   for i = 1:nargin
      idx = ismember(lower(f),lower(varargin{i}));
      if sum(idx) == 1
         varargout{i} = pars.(f{idx});
      end
   end
end
