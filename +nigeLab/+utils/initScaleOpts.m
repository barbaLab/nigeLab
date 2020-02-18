function scaleOpts = initScaleOpts(varargin)
% INITSCALEOPTS  Return default scale options struct for scaling streams
%
%  scaleOpts_ = nigeLab.utils.initScaleOpts();
%  scaleOpts_ = nigeLab.utils.initScaleOpts(do_scale,...);
%
%  varargin  --  <'Name', value> argument pairs:
%
%                 --> do_scale (true or false)
%                 --> range: 'normalized', 'fixed_scale', or 'zscore'
%                 --> fixed_min (fixed lower-bound on values)
%                 --> fixed_range (fixed range on values)

def = struct('do_scale',true,...
   'range','normalized',...
   'fixed_min',0,...
   'fixed_range',1);

scaleOpts = nigeLab.utils.getopt(def,1,varargin{:});


end