function flag = plotOverlay(blockObj,val)
%% PLOTOVERLAY  Overlay multi-channel values, superimposed on image
%
%  flag = PLOTOVERLAY(blockObj);
%
%  --------
%   INPUTS
%  --------
%  blockObj :     BLOCK class object from orgExp package.
%
%     val   :     (Optional) Sets the overlay in one call to PLOTOVERLAY()
%                    method, instead of a separate call to SETOVERLAY()
%                    method.
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

%% CHECK THAT OVERLAY HAS BEEN SET
if nargin == 2
   blockObj.setOverlay(val);
else
   for iCh = 1:blockObj.NumChannels
      if ~isfield(blockObj.Channels(iCh),'overlay')
         warning('Overlay has not been set. Try blockObj.setOverlay method.');
         return;   
      end
   end
end

%%
if ~isfield(blockObj.Graphics,'Overlay')
   blockObj.Graphics.Overlay = figure('Name','Activity Overlay',...
      'Units','Normalized',...
      'Position',[0.1 0.1 0.8 0.8],...
      'Color','w');
elseif ~isvalid(blockObj.Graphics.Overlay)
   blockObj.Graphics.Overlay = figure('Name','Activity Overlay',...
      'Units','Normalized',...
      'Position',[0.1 0.1 0.8 0.8],...
      'Color','w');
else
   figure(blockObj.Graphics.Overlay);
end

ax = axes(blockObj.Graphics.Overlay,'NextPlot','replacechildren',...
   'XTick',[],...
   'YTick',[],...
   'XColor','w',...
   'YColor','w');
I = imread(blockObj.PlotPars.OverlayImage);

for ii = 1:blockObj.NumChannels
   k = (ismember(blockObj.Channels(ii).Hemisphere,'L')-0.5)*2;
   x = blockObj.Channels(ii).AP * blockObj.PlotPars.XScale; % x pixel off
   y = k * blockObj.Channels(ii).ML * blockObj.PlotPars.YScale; % y pixel
   pos = blockObj.PlotPars.Bregma + [x,y];
   I = insertShape(I,'FilledCircle',[pos,blockObj.PlotPars.Size]);
end

image(ax,I);

flag = true;
end