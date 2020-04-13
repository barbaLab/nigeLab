function [x,y,w,h] = uiGetGrid(nRow,nCol,varargin)
%UIGETGRID  Returns [x,y,w,h] graphics position vector for (nRow,nCol)
%
%  [x,y,w,h] = nigeLab.utils.uiGetGrid(nRow);
%  * Returns coordinates assuming only 1 column
%
%  [x,y,w,h] = nigeLab.utils.uiGetGrid([],nCol);
%  * Returns coordinates assuming only 1 row
%
%  [x,y,w,h] = nigeLab.utils.uiGetGrid(nRow,nCol);
%  * Returns coordinates for nRow and nCol, assuming normalized units
%     spaced between [0, 1]
%
%  [x,y,w,h] = nigeLab.utils.uiGetGrid(__,'NAME',value,...);
%  -- 'NAME' options --
%  --> 'TOP' : (default: 0.025; offset normalized to derived grid height)
%  --> 'BOT' : (default: 0.025; offset normalized to derived grid height)
%  --> 'YLIM' : (default: nan; see nigeLab.utils.getVerticalSpacing)
%  --> 'LEFT' : (default: 0.025; offset normalized to derived grid width)
%  --> 'RIGHT' : (default: 0.025; offset normalized to derived grid width)
%  --> 'YLIM' : (default: nan; see nigeLab.utils.getHorizontalSpacing)
%
%  Outputs:
%  x : <MESHGRID MATRIX> X-coordinate of each grid element
%  y : <MESHGRID MATRIX> Y-coordinate of each grid element
%  w : <SCALAR> Width of each grid element
%  h : <SCALAR> Height of each grid element

% DEFAULT PARAMETERS
pars = struct;
pars.Top = 0.05; % Offset from TOP border ([0 1])
pars.Bot = 0.10; % Offset from BOTTOM border ([0 1])
pars.YLim = nan;  % Y-limits or scalar assuming origin is at zero

pars.Left = 0.05;  % Offset from LEFT border ([0 1])
pars.Right = 0.05; % Offset from RIGHT border ([0 1])
pars.XLim = nan;    % X-limits or scalar assuming origin is at zero

% PARSE VARARGIN
if numel(varargin) == 1
   if isstruct(varargin{1})
      pars = varargin{1};
      varargin = {};
   else
      error(['nigeLab:' mfilename ':BadSyntax'],...
         ['\n\t\t->\t<strong>[UIGETGRID]:</strong> ' ...
         'Optional inputs should be <''NAME'',value> pairs or '...
         'a scalar `pars` struct.\n']);
   end
else
   pars = nigeLab.utils.getopt(pars,1,varargin{:});
end

% PARSE INPUT
if nargin < 2
   nCol = 1;
elseif isempty(nCol)
   nCol = 1;
end

if nargin < 1
   nRow = 1;
elseif isempty(nRow)
   nRow = 1;
end

[yVec,h] = nigeLab.utils.uiGetVerticalSpacing(nRow,pars);
[xVec,w] = nigeLab.utils.uiGetHorizontalSpacing(nCol,pars);

[x,y] = meshgrid(xVec,yVec);
end