function PlotWaves(obj,WAV,SPK)
%% PLOTWAVES  Uses PLOTCHANNELS for this recording BLOCK
%
%  obj.PLOTWAVES
%  obj.PLOTWAVES(WAV)
%  obj.PLOTWAVES(WAV,SPK)
%
%  --------
%   INPUTS
%  --------
%     WAV   :     Folder containing either FILT or CARFILT waves.
%
%     SPK   :     Folder containing either SORTED, CLUSTERS, or
%                 SPIKES.
%
%  See also: PLOTCHANNELS

%% PARSE VARARGIN
if nargin==1
   if ~isempty(obj.CAR.dir)
      WAV = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
         obj.ID.CAR.Folder]);
   elseif ~isempty(obj.Filt.dir)
      WAV = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
         obj.ID.Filt.Folder]);
   else
      plotChannels;
      return;
   end
   
   if ~isempty(obj.Sorted.dir)
      SPK = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
         obj.ID.Sorted.Folder]);
   elseif ~isempty(obj.Clusters.dir)
      SPK = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
         obj.ID.Clusters.Folder]);
   elseif ~isempty(obj.Spikes.dir)
      SPK = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
         obj.ID.Spikes.Folder]);
   else
      plotChannels('DIR',WAV);
      return;
   end
end

if nargin==2
   if ~isempty(obj.Sorted.dir)
      SPK = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
         obj.ID.Sorted.Folder]);
   elseif ~isempty(obj.Clusters.dir)
      SPK = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
         obj.ID.Clusters.Folder]);
   elseif ~isempty(obj.Spikes.dir)
      SPK = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
         obj.ID.Spikes.Folder]);
   else
      plotChannels('DIR',WAV);
      return;
   end
end
obj.Graphics.Waves = plotChannels('DIR',WAV,'SPK',SPK);


end