function MultiColorHighlight(src,~,varargin)
%% MULTICOLORHIGHLIGHT       Similar to LINECALLBACK but with multi-color
%
%   MULTICOLORHIGHLIGHT(src,~,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%     src       :       Matlab graphical line object. When specifying a
%                       'ButtonDownFcn', if passed anonymously (i.e.
%                       @lineCallback), this will be included automatically
%                       as the first argument.
%
%   varargin    :       (Optional) 'NAME', value input argument pairs. When
%                       specifying 'ButtonDownFcn', you must pass this in a
%                       cell array:
%                       {@lineCallback,'NAME1',value1,'NAME2',value2,...}
%
%                       => 'SEL_COL1': (def [0.4 0.4 0.8]; Highlight color 
%                                      for line when it is first clicked)
%                       => 'SEL_COL2': (def [0.8 0.4 0.4]; Highlight color 
%                                      for line when it is 2nd clicked)
%                       => 'SEL_COL3': (def [0.4 0.8 0.4]; Highlight color 
%                                      for line when it is 3rd clicked)
%
%                       => 'UNSEL_COL': (def [0.94 0.94 0.94]; Unselect
%                                        color for lines that have not been
%                                        clicked, or clicked 4 times)
%
%                       => 'BRING_FORWARD': (def false; Set to true to
%                                            bring line to front, but must
%                                            configure other axes
%                                            properties to use with it)
%
%   --------
%    OUTPUT
%   --------
%   Setting the ButtonDownFcn property of a line object to this function
%   will allow you to change the color of the line by clicking on it.
%
%   By: Max Murphy  v1.0    06/10/2017  Original version (R2017a)
% See also: PLOT, LINE

%% DEFAULTS
SEL_COL1 = [0.4 0.4 0.8];
SEL_COL2 = [0.8 0.4 0.4];
SEL_COL3 = [0.4 0.8 0.4];
UNSEL_COL = [0.94 0.94 0.94];
BRING_FORWARD = false;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% SWITCH COLORS
if ~any(src.Color - SEL_COL1)
    src.Color = SEL_COL2;
    col = 2;
elseif ~any(src.Color - SEL_COL2)
    src.Color = SEL_COL3;
    col = 3;
elseif ~any(src.Color - SEL_COL3)
    src.Color = UNSEL_COL;
    src.LineWidth = 2;
    col = 4;
else
    src.Color = SEL_COL1;
    src.LineWidth = 4;
    col = 1;
end

tempLine = struct;
    tempLine.col = col;
    tempLine.XData = src.XData;
    tempLine.YData = src.YData;
mtb(tempLine);

%% (OPTIONAL) BRING LINE TO FRONT
if BRING_FORWARD
    p = src.Parent;
    ind = find(abs(p.UserData-src.UserData)<eps,1,'first');
    vec = 1:numel(p.UserData);
    vec = vec(abs(vec-ind)>eps);
    p.Children = p.Children([ind,vec]);
    p.UserData = p.UserData([ind,vec]);
end

end