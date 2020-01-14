function varargout = LFP(varargin)
%% LFP      Template for initializing parameters related to LFP analysis
%
%   pars = nigeLab.defaults.LFP;

%% CAN CHANGE
pars = struct;
pars.DecimateCascadeM=[5 3 2]; % Decimation factor
pars.DecimateCascadeN=[3 5 5]; % Chebyshev LPF order

%% DO NOT CHANGE
pars.DecimationFactor=prod(pars.DecimateCascadeM);

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

