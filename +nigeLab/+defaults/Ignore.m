function varargout = Ignore(varargin)
%% defaults.SD    Initialize parameters for spike detection, Artefact rejection and feature extraction
%
%   pars = nigeLab.defaults.SD('NAME',value,...);
%
%   General SD pars are defined here as well as the default method to use.
%   To customize specific methods parameters, please refer to the SD folder
%   inside here
%
%
% By: MAECI 2018 collaboration (Max Murphy & Federico Barban)


pars = struct;


%% User defined parameters for spike detection
pars.n = 1;
pars.Ignore  = {'nigelColors','Tempdir','Contents','Ignore'};            % Pre-specified stim times

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

end
