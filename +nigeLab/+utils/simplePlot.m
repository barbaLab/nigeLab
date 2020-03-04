function [h,x_red,y_red] = simplePlot(varargin)
%SIMPLEPLOT  Make a "simple" line plot using just (2D) vertex data
%
%  h = nigeLab.utils.simplePlot(y);
%  h = nigeLab.utils.simplePlot(x,y);
%  h = nigeLab.utils.simplePlot(ax,y);
%  h = nigeLab.utils.simplePlot(ax,x,y);
%  h = nigeLab.utils.simplePlot(__,'NAME',value,...);
%  [h,x_red,y_red] = nigeLab.utils.simplePlot(__);
%
%  Where x and y are data vectors of equal length, and ax is the desired
%  axes to plot on. If no `ax` argument given, it uses current axes. If no
%  `x` is given, it assumes `x` is an indexing vector of equal length to
%  `y`.
%
%  'Name', value,... syntax applies to 'matlab.graphics.primitive.Line'
%  object, except for optional parameters:
%  --> 'XTol' : X-tolerance for jitter in line to ignore
%  --> 'YTol' : Y-tolerance for jitter in line to ignore
%     --> If left unset, these are parsed from the pixel resolution of
%         monitor and the size of the window.
%
%  `h` is returned as a 'matlab.graphics.primitive.Line' object
%
%  Optionally can return the "parsed" (reduced) x- and y- values (which are
%  simply h.XData and h.YData)

% Change these values to set "tolerance" for differences to plot:
pars = struct;
pars.XTol = [];
pars.YTol = [];

if nargin < 1
   error(['nigeLab:' mfilename ':TooFewInputs'],...
      ['\n\t\t->\t<strong>[SIMPLEPLOT]:</strong> ' ...
      'Must provide at least an ''x'' and ''y'' argument.\n']);
end

if isa(varargin{1},'matlab.graphics.axis.Axes')
   ax = varargin{1};
   varargin(1) = [];
else
   ax = gca;
end

if numel(varargin) < 1
   error(['nigeLab:' mfilename ':TooFewInputs'],...
      ['\n\t\t->\t<strong>[SIMPLEPLOT]:</strong> ' ...
      'Must provide at least a ''y'' argument.\n']);
end

if isnumeric(varargin{1}) && isnumeric(varargin{2})
   XData = varargin{1};
   YData = varargin{2};
   varargin(1:2) = [];
elseif isnumeric(varargin{1})
   YData = varargin{1};
   XData = 1:numel(YData);
   varargin(1) = [];
else
   error(['nigeLab:' mfilename ':TooFewInputs'],...
      ['\n\t\t->\t<strong>[SIMPLEPLOT]:</strong> ' ...
      'Must provide at least a ''y'' argument.\n']);
end

f = fieldnames(pars);
rmIdx = false(size(varargin));
for i = 1:2:numel(varargin)
   idx = strcmpi(f,varargin{i});
   if sum(idx)==1
      pars.(f{idx}) = varargin{i+1};
      rmIdx([i, i+1]) = true;
   end
end
varargin(rmIdx) = []; % Remove "non-line" parameters

if isempty(pars.XTol)
   pos = getpixelposition(ax);
   [xd,e] = discretize(XData,round(pos(3)));
   if max(diff(e(xd))) == 0
      xTol = inf;
   else
      xTol = mean(diff(e(xd)));
   end
else
   xTol = pars.XTol;
end
if isempty(pars.YTol)
   [yd,e] = discretize(XData,round(pos(3)));
   if max(diff(e(xd))) == 0
      yTol = inf;
   else
      yTol = mean(diff(e(yd)));
   end
else
   yTol = pars.YTol;
end

[x_red,y_red] = parseXYData(XData,YData,xTol,yTol);

h = line(ax,x_red,y_red,varargin{:});

   function [x,y] = parseXYData(XData,YData,XTol,YTol)
      %PARSEXYDATA  Parses <x,y> vertices of interest
      %
      %  [x,y] = parseXYData(XData,YData,XTol,YTol);
      
      N = numel(XData);
      if numel(YData) ~= N
         error(['nigeLab:' mfilename ':DimensionMismatch'],...
            ['\n\t\t->\t<strong>[SIMPLEPLOT]:</strong> ' ...
            'Expected `x` and `y` arguments to have same size.']);
      end
      XData = reshape(XData,1,N);
      YData = reshape(YData,1,N);
      
      % Check both the "forward difference" and "reverse difference," since
      % we need "both sides" of any "transitions" larger than our tolerance
      iXf = [true, abs(diff(XData))>XTol];     
      iXb = fliplr([true, abs(diff(fliplr(XData)))>XTol]);
      iYf = [true, abs(diff(YData))>YTol];
      iYb = fliplr([true, abs(diff(fliplr(YData)))>YTol]);
      iAll = iXf | iXb | iYf | iYb;
      
      x = XData(iAll);
      y = YData(iAll);
   end

end