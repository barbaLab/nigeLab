function [y,h] = uiGetVerticalSpacing(n,varargin)
%UIGETVERTICALSPACING   Get spacing in y-direction for array of graphics
%
%  y = nigeLab.utils.uiGetVerticalSpacing(n);
%  y = nigeLab.utils.uiGetVerticalSpacing(n,'NAME',value,...);
%  [y,h] = nigeLab.utils.uiGetVerticalSpacing(n,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     n     :     Number of elements in graphics array.
%
%  varargin :     (Optional) 'NAME', value input arguments.
%
%                 -> 'BOT' [def: 0.025] // Offset from bottom border
%                 (normalized from 0 to 1)
%
%                 -> 'TOP' [def: 0.025] // Offset from top border
%                 (normalized from 0 to 1)
%
%                 -> 'YLIM' [def: NaN] // Coordinate limits
%                 (can be given as scalar, in which case lower lim is
%                 assumed to be zero. Otherwise, should be a two-element
%                 vector where the first is the lower bound and second is
%                 upper bound)
%
%  --------
%   OUTPUT
%  --------
%     y     :     Vector of scalar values normalized between 0 and 1 giving
%                 the second Position argument for Matlab graphics objects
%                 (y position).
%
%     h     :     Scalar singleton normalized between 0 and 1 giving
%                 corresponding 4th Position argument for Matlab graphics
%                 objects (height).

% DEFAULTS
pars = struct;
pars.Top = 0.125; % Offset (norm to height) of bottom border of graphical item [0, 1]
pars.Bot = 0.125; % Offset (norm to height) of graphical item [0, 1]
pars.YLim = [0 1];

% PARSE VARARGIN
if numel(varargin) == 1
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin = {};
   else
      error(['nigeLab:' mfilename ':BadSyntax'],...
         ['\n\t\t->\t<strong>[UIGETVERTICALSPACING]:</strong> ' ...
         'Optional inputs should be <''NAME'',value> pairs or '...
         'a scalar `pars` struct.\n']);
   end
else
   pars = nigeLab.utils.getopt(pars,1,varargin{:});
end

if abs(pars.Top - 1) > 1
   error(['nigeLab:' mfilename ':ParameterOutOfBounds'],...
         ['\n\t\t->\t<strong>[UIGETVERTICALSPACING]:</strong> ' ...
         'pars.Top (%7.4f) offset must be in the range [0, 1]\n'],...
         pars.Top);
end

if abs(pars.Bot - 1) > 1
   error(['nigeLab:' mfilename ':ParameterOutOfBounds'],...
         ['\n\t\t->\t<strong>[UIGETVERTICALSPACING]:</strong> ' ...
         'pars.Bot (%7.4f) offset must be in the range [0, 1]\n'],...
         pars.Bot);
end

% COMPUTE
if isscalar(pars.YLim) % Assume "bottom" is at origin ([~,0])
   if isnan(pars.YLim)
      top = 1;
   else
      top = pars.YLim;
   end
   bot = 0; % Assume starts at origin
   hTotal = top / n; % Total height
   
else
   top = pars.YLim(2);
   bot = pars.YLim(1);
   hTotal = diff(pars.YLim) / n;
end

% Compute bottom offset and top offset as fraction of "total" object height
botOffset = hTotal * pars.Bot;
topOffset = hTotal * pars.Top;

% Height of each element must account for offset removed (for spacing)
h = hTotal - topOffset - botOffset; 

if ~isfield(pars,'VerticalAlignment')
   pars.VerticalAlignment = 'middle';
end

switch pars.VerticalAlignment
   case 'top'
      yBot = bot + botOffset + h;
      yTop = top - topOffset;
      y = yTop:-hTotal:yBot;
      y = fliplr(y);
   case 'middle'
      yBot = bot + botOffset + h/2;
      yTop = top - topOffset - h/2;
      y = yBot:hTotal:yTop;
   otherwise
      % Get y-coordinate of bottom for first and last element
      yBot = bot + botOffset;
      yTop = top - topOffset - h;
      y = yBot:hTotal:yTop;
end
 

if numel(y) < n % If there will be clipping, notify user
   warning(['nigeLab:' mfilename ':ExceedsBoundaries'],...
      ['\n\t\t->\t<strong>[UIGETVERTICALSPACING]:</strong> ' ...
      'Requested %g elements, but only %g elements "fit".\n ' ...
      '\t\t\t->\t(Top-most %g element(s) will be clipped)\n'],n,numel(y),...
      n - numel(y));
   y = yBot:hTotal:((n-1)*hTotal + yBot);
end

end