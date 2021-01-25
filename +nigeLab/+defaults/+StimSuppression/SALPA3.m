function varargout = SALPA3(varargin)
%% defaults.StimSuppression    Initialize parameters for SALPA stimualtion suppression
%
%   pars = nigeLab.defaults.regr('NAME',value,...);
%
%
% By: MAECI 2020 collaboration (Max Murphy & Federico Barban)





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