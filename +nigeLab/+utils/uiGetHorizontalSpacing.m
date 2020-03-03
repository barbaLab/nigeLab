function [x,w] = uiGetHorizontalSpacing(n,varargin)
%UIGETHORIZONTALSPACING   Get spacing in x-direction for array of graphics
%
%  x = nigeLab.utils.uiGetHorizontalSpacing(n);
%  x = nigeLab.utils.uiGetHorizontalSpacing(n,'NAME',value,...);
%  [x,w] = nigeLab.utils.uiGetHorizontalSpacing(n,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     n     :     Number of elements in graphics array.
%
%  varargin :     (Optional) 'NAME', value input arguments.
%
%                 -> 'LEFT' [def: 0.025] // Offset from left border
%                 (normalized from 0 to 1 as fraction of object width)
%
%                 -> 'RIGHT' [def: 0.475] // Offset from right border
%                 (normalized from 0 to 1 as fraction of object width)
%
%                 -> 'XLIM' [def: NaN] // Coordinate limits
%                 (can be given as scalar, in which case lower lim is
%                 assumed to be zero. Otherwise, should be a two-element
%                 vector where the first is the lower bound and second is
%                 upper bound)
%
%  --------
%   OUTPUT
%  --------
%     x     :     Vector of scalar values normalized between 0 and 1 giving
%                 the first Position argument for Matlab graphics objects
%                 (x position).
%
%     w     :     Scalar singleton normalized between 0 and 1 giving
%                 corresponding 3rd Position argument for Matlab graphics
%                 objects (width).

% DEFAULTS
pars = struct;
pars.Left = 0.025; % Offset (norm to height) of bottom border of graphical item [0, 1]
pars.Right = 0.025; % Offset (norm to height) of graphical item [0, 1]
pars.XLim = [0 1];

% PARSE VARARGIN
if numel(varargin) == 1
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin = {};
   else
      error(['nigeLab:' mfilename ':BadSyntax'],...
         ['\n\t\t->\t<strong>[UIGETHORIZONTALSPACING]:</strong> ' ...
         'Optional inputs should be <''NAME'',value> pairs or '...
         'a scalar `pars` struct.\n']);
   end
else
   pars = nigeLab.utils.getopt(pars,1,varargin{:});
end

if abs(pars.Left - 1) > 1
   error(['nigeLab:' mfilename ':ParameterOutOfBounds'],...
         ['\n\t\t->\t<strong>[UIGETHORIZONTALSPACING]:</strong> ' ...
         'pars.Left (%7.4f) offset must be in the range [0, 1]\n'],...
         pars.Left);
end

if abs(pars.Right - 1) > 1
   error(['nigeLab:' mfilename ':ParameterOutOfBounds'],...
         ['\n\t\t->\t<strong>[UIGETHORIZONTALSPACING]:</strong> ' ...
         'pars.Right (%7.4f) offset must be in the range [0, 1]\n'],...
         pars.Right);
end

% COMPUTE
if isscalar(pars.XLim) % Assume "bottom" is at origin ([~,0])
   if isnan(pars.XLim)
      right = 1;
   else
      right = pars.XLim;
   end
   left = 0; % Assume starts at origin
   wTotal = right / n; % Total width
   
else
   left = pars.XLim(1);
   right = pars.XLim(2);
   wTotal = diff(pars.XLim) / n;
end

% Compute left offset and right offset as fraction of "total" object width
leftOffset = wTotal * pars.Left;
rightOffset = wTotal * pars.Right;

% Width of each element must account for offset removed (for spacing)
w = wTotal - rightOffset - leftOffset; 

% Get x-coordinate of left edge for first and last element
if ~isfield(pars,'HorizontalAlignment')
   pars.HorizontalAlignment = 'left';
end
switch pars.HorizontalAlignment
   case 'right'
      xLeft = left + leftOffset + w;
      xRight = right - rightOffset;
      x = xRight:-wTotal:xLeft;
      x = fliplr(x);
   otherwise
      xLeft = left + leftOffset;
      xRight = right - rightOffset - w;
      x = xLeft:wTotal:xRight; 
end

if numel(x) < n % If there will be clipping, notify user
   warning(['nigeLab:' mfilename ':ExceedsBoundaries'],...
      ['\n\t\t->\t<strong>[UIGETHORIZONTALSPACING]:</strong> ' ...
      'Requested %g elements, but only %g elements "fit".\n ' ...
      '\t\t\t->\t(Right-most %g element(s) will be clipped)\n'],n,numel(x),...
      n - numel(x));
   x = xLeft:wTotal:((n-1)*wTotal + xLeft);
end

end