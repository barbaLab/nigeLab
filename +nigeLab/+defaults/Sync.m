function varargout = Sync(varargin)
%SYNC      Template for initializing parameters related to experiment trigger synchronization
%
%   pars = nigeLab.defaults.Sync;

%%
pars = struct;
pars.DeBounce = 250;    % de-bounce time (milliseconds)
pars.ID = 'sync';       % file identifier (for digital input file)

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

