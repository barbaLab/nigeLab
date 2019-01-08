function flag = setOverlay(blockObj,val)
%% SETOVERLAY  Set overlay values for plotting
%
%  flag = SETOVERLAY(blockObj);
%
%  --------
%   INPUTS
%  --------
%  blockObj :     BLOCK class object from orgExp package.
%
%    val    :     Values vector that should be the same size as CHANNELS
%                    struct field.
%
%  --------
%   OUTPUT
%  --------
%    flag   :     Returns true if the figure is successfully generated.
%
% By: Max Murphy  v1.0  12/11/2018  Original version (R2017a)

%% DEFAULTS
flag = false;
blockObj.PlotPars = nigeLab.defaults.Plot();

%% PARSE INPUT
if numel(val)~=blockObj.NumChannels
   warning('Overlay values not set. Dimension mismatch with channels.');
   return;
end

%% SET VALUES
for iCh = 1:blockObj.NumChannels
   blockObj.Channels(iCh).overlay = val(iCh);
end

flag = true;
end