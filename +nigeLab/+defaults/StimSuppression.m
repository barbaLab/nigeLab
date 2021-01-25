function varargout = StimSuppression(varargin)
%% defaults.StimSuppression    Initialize parameters for stimulation suppression
%
%   pars = nigeLab.defaults.StimSuppression('NAME',value,...);
%
%
% By: MAECI 2020 collaboration (Max Murphy & Federico Barban)

pars.SDMethodName = 'regr';



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
