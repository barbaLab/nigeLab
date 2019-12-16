function ts_out = matchWindowedPointElements(ts_in,ts_match,window)
% MATCHWINDOWEDPOINTELEMENTS  Returns matched elements according to
%                             ts_match for the closest element of ts_in
%                             within "window" of the corresponding ts_match
%                             element.
%
%  ts_out = nigeLab.utils.matchWindowedPointElements(ts_in,ts_match);
%  ts_out = nigeLab.utils.matchWindowedPointElements(__,window);
%
%  inputs:
%  ts_in  --  n x 1 vector of time stamps to use in filling out "ts_out"
%  ts_match  --  m x 1 vector of time stamps to "match"
%  window  --  (optional) Scalar: furthest a time in ts_in can be from
%                             ts_match. If specified, then any element of
%                             ts_match that for which no element of ts_in
%                             is within "window" range, returns NaN
%                             for the corresponding ts_out element.
%
%                          If specified as an empty array ([]), then this
%                          uses nigeLab.defaults.Event('MaxTrialDistance')
%
%  output:
%  ts_out  --  m x 1 vector of time stamps, which may have redundant
%                 entries from ts_in, or no elements from ts_in at all (if
%                 window is specified; in which case elements outside the
%                 window are NaN). 

%%
if nargin < 3
   window = inf;
elseif isempty(window)
   window = nigeLab.defaults.MaxTrialDistance;
end

if nargin < 2
   error('Must specify at least 2 input arguments.');
end

%%
ts_out = nan(numel(ts_match),1);
for i = 1:numel(ts_match)
   [val,idx] = min(abs(ts_in - ts_match(i)));
   if val < window
      ts_out(i) = ts_in(idx);
   end
end

end