function [x,w] = uiGetHorizontalSpacing(n,varargin)
%% UIGETVERTICALSPACING   Get spacing in y-direction for array of graphics
%
%  x = UIGETHORIZONTALSPACING(n);
%  x = UIGETHORIZONTALSPACING(n,'NAME',value,...);
%  [x,w] = UIGETHORIZONTALSPACING(n,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     n     :     Number of elements in graphics array.
%
%  varargin :     (Optional) 'NAME', value input arguments.
%
%                 -> 'LEFT' [def: 0.025] // Offset from left border
%                 (normalized from 0 to 1)
%
%                 -> 'RIGHT' [def: 0.475] // Offset from right border
%                 (normalized from 0 to 1)
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
%
% By: Max Murphy  v1.0  08/30/2018   Original version (R2017b)

%% DEFAULTS
LEFT = 0.025;
RIGHT = 0.500;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% COMPUTE
w = (1/n) - (LEFT + RIGHT);
x = linspace(LEFT,1-RIGHT-w,n);


end