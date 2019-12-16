function data = applyScaleOpts(data,scaleOpts)
% APPLYSCALEOPTS  Returns the data with scaling options applied to it
%
%  data = nigeLab.utils.applyScaleOpts(data,scaleOpts);
%
%  scaleOpts -- struct with fields that are options on scaling
%
%  See Also:
%  nigeLab.utils.initScaleOpts  

if nargin < 2
   scaleOpts = nigeLab.utils.initScaleOpts;
elseif isempty(scaleOpts)
   scaleOpts = nigeLab.utils.initScaleOpts;
elseif ~isstruct(scaleOpts)
   scaleOpts = nigeLab.utils.initScaleOpts;
end

if ~scaleOpts.do_scale
   % Just returns data, which is already input
   return;
end

switch lower(scaleOpts.range)
   case {'fix','fixed','fixed_scale','flat'} 
      % data is fraction of a fixed range
      data = data - min(data);
      data = data / scaleOpts.fixed_range;
      data = data + scaleOpts.fixed_min;
      
   case {'norm','normalized','unit'}
      % data should be between zero and one
      data = data - min(data);
      if max(data) > 1
         data = data / max(data);
      end
      
   case {'z','zscore','zscale','zscored'} 
      % data is "z-scaled" for gaussian distribution
      data = (data - mean(data)) / std(data);
      
   otherwise
      warning('%s is not a handled case.',scaleOpts.range);
end

end