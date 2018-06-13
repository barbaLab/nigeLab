function PlotSpikes(obj,ch)
%% PLOTSPIKES  Show all spike clusters for a given channel.
%
%  obj.PLOTSPIKES(ch)
%
%  --------
%   INPUTS
%  --------
%     ch    :     Channel number to show spikes for.
%
%
% By: Max Murphy  v1.1  08/27/2017  Original version (R2017a)
% See also: SPIKEIMAGE

%% CHECK FOR SPIKES
if isempty(obj.Spikes.dir)
   error('No spikes currently detected.');
end

%% FIND CORRESPONDING CHANNELS FROM SPIKES FILE
ind = find(abs(obj.Spikes.ch-ch)<eps,1,'first');
load(fullfile(obj.Spikes.dir(ind).folder,...
   obj.Spikes.dir(ind).name),'spikes','peak_train','pars');

fs = pars.FS;

%% CHECK FOR CLUSTERS AND GET CORRESPONDING CHANNEL
if ~isempty(obj.Sorted.dir)
   ind = find(abs(obj.Sorted.ch-ch)<eps,1,'first');
   load(fullfile(obj.Sorted.dir(ind).folder,...
      obj.Sorted.dir(ind).name),'class');
elseif ~isempty(obj.Clusters.dir)
   ind = find(abs(obj.Clusters.ch-ch)<eps,1,'first');
   load(fullfile(obj.Clusters.dir(ind).folder,...
      obj.Clusters.dir(ind).name),'class');
else
   % (If no clusters yet, just make everything class "1")
   class = ones(size(spikes,1),1);
end

obj.Graphics.Spikes = orgExp.libs.SpikeImage(spikes,fs,peak_train,class,...
                        'NumClus_Max',numel(unique(class)));
end