function flag = plotWaves(blockObj,WAV,SPK)
%% PLOTWAVES  Uses PLOTCHANNELS for this recording BLOCK
%
%  flag = blockObj.PLOTWAVES
%  flag = blockObj.PLOTWAVES(WAV)
%  flag = blockObj.PLOTWAVES(WAV,SPK)
%
%  --------
%   INPUTS
%  --------
%     WAV   :     Folder containing either FILT or CARFILT waves.
%
%     SPK   :     Folder containing either SORTED, CLUSTERS, or
%                 SPIKES.
%
%  --------
%   OUTPUT
%  --------
%    flag   :     Returns true if the figure is successfully generated.
%
%  See also: PLOTCHANNELS
%
% By: Max Murphy  v1.1  06/14/2018  Added flag output.

%% PARSE VARARGIN
if nargin==1
   if ~isempty(blockObj.CAR.dir)
      WAV = fullfile(blockObj.DIR,[blockObj.Name blockObj.ID.Delimiter ...
         blockObj.ID.CAR.Folder]);
   elseif ~isempty(blockObj.Filt.dir)
      WAV = fullfile(blockObj.DIR,[blockObj.Name blockObj.ID.Delimiter ...
         blockObj.ID.Filt.Folder]);
   else
      try
         plotChannels;
         flag = true;
      catch
         flag = false;
      end
      return;
   end
   
   if ~isempty(blockObj.Sorted.dir)
      SPK = fullfile(blockObj.DIR,[blockObj.Name blockObj.ID.Delimiter ...
         blockObj.ID.Sorted.Folder]);
   elseif ~isempty(blockObj.Clusters.dir)
      SPK = fullfile(blockObj.DIR,[blockObj.Name blockObj.ID.Delimiter ...
         blockObj.ID.Clusters.Folder]);
   elseif ~isempty(blockObj.Spikes.dir)
      SPK = fullfile(blockObj.DIR,[blockObj.Name blockObj.ID.Delimiter ...
         blockObj.ID.Spikes.Folder]);
   else
      try
         plotChannels('DIR',WAV);
         flag = true;
      catch
         flag = false;
      end
      return;
   end
end

if nargin==2
   if ~isempty(blockObj.Sorted.dir)
      SPK = fullfile(blockObj.DIR,[blockObj.Name blockObj.ID.Delimiter ...
         blockObj.ID.Sorted.Folder]);
   elseif ~isempty(blockObj.Clusters.dir)
      SPK = fullfile(blockObj.DIR,[blockObj.Name blockObj.ID.Delimiter ...
         blockObj.ID.Clusters.Folder]);
   elseif ~isempty(blockObj.Spikes.dir)
      SPK = fullfile(blockObj.DIR,[blockObj.Name blockObj.ID.Delimiter ...
         blockObj.ID.Spikes.Folder]);
   else
      try
         plotChannels('DIR',WAV);
         flag = true;
      catch
         flag = false;
      end
      return;
   end
end

try
   blockObj.Graphics.Waves = plotChannels('DIR',WAV,'SPK',SPK);
   flag = true;
catch
   flag = false;
end


end