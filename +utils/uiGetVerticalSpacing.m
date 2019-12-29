function [y,h] = uiGetVerticalSpacing(n,varargin)
%% UIGETVERTICALSPACING   Get spacing in y-direction for array of graphics
%
%  y = UIGETVERTICALSPACING(n);
%  y = UIGETVERTICALSPACING(n,'NAME',value,...);
%  [y,h] = UIGETVERTICALSPACING(n,'NAME',value,...);
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
%
% By: Max Murphy  v1.0  08/30/2018   Original version (R2017b)

%% DEFAULTS
TOP = 0.025; % Offset from bottom border of graphical item
BOT = 0.025; % Offset from top border of graphical item

YLIM = nan;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% COMPUTE
if isnan(YLIM(1))
   h = (1/n) - (TOP + BOT);
   if h<=0
      error('TOP and/or BOT offset is too large.');
   end
   y = linspace(BOT,1-TOP-h,n);
else
   h = (diff(YLIM)/n) - (TOP + BOT);
   if h<=0
      error('TOP and/or BOT offset is too large.');
   end
   y = linspace(YLIM(1)+BOT,YLIM(2)-TOP-h,n);
end


end