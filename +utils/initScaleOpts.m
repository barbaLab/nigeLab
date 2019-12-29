function scaleOpts_ = initScaleOpts(varargin)
% INITSCALEOPTS  Return default scale options struct for scaling streams
%
%  scaleOpts_ = nigeLab.utils.initScaleOpts();
%  scaleOpts_ = nigeLab.utils.initScaleOpts(do_scale,...);
%
%  varargin  --  Can take any number of elements corresponding to field
%                names of scaleOpts_ current variable names could be:
%
%                 --> do_scale
%                 --> range
%                    Can be: 'normalized', 'fixed_scale', or 'zscore'
%                 --> fixed_min
%                 --> fixed_range
%
%  Note that it uses variable names, so the input variables need to be
%  named accordingly.

scaleOpts_ = struct('do_scale',true,...
   'range','normalized',...
   'fixed_min',0,...
   'fixed_range',1);

for i = 1:numel(varargin)
   scaleOpts_.(inputname(i)) = varargin{i};
end


end