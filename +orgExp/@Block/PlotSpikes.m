function flag = plotSpikes(blockObj,ch)
%% PLOTSPIKES  Show all spike clusters for a given channel.
%
%  flag = blockObj.PLOTSPIKES(ch)
%
%  --------
%   INPUTS
%  --------
%     ch    :     Channel number to show spikes for.
%
%  --------
%   OUTPUT
%  --------
%    flag   :     Returns true if the spike plot is successfully built.
%
%
% By: Max Murphy  v1.1  08/27/2017  Original version (R2017a)
% See also: SPIKEIMAGE

%% CHECK FOR SPIKES
if isempty(blockObj.Spikes.dir)
   warning('No spikes currently detected on channel %d.',ch);
   flag = false;
   return;
end

%% FIND CORRESPONDING CHANNELS FROM SPIKES FILE
ind = find(abs(blockObj.Spikes.ch-ch)<eps,1,'first');
load(fullfile(blockObj.Spikes.dir(ind).folder,...
   blockObj.Spikes.dir(ind).name),'spikes','peak_train','pars');

fs = pars.FS;

%% CHECK FOR CLUSTERS AND GET CORRESPONDING CHANNEL
if ~isempty(blockObj.Sorted.dir)
   ind = find(abs(blockObj.Sorted.ch-ch)<eps,1,'first');
   load(fullfile(blockObj.Sorted.dir(ind).folder,...
      blockObj.Sorted.dir(ind).name),'class');
elseif ~isempty(blockObj.Clusters.dir)
   ind = find(abs(blockObj.Clusters.ch-ch)<eps,1,'first');
   load(fullfile(blockObj.Clusters.dir(ind).folder,...
      blockObj.Clusters.dir(ind).name),'class');
else
   % (If no clusters yet, just make everything class "1")
   class = ones(size(spikes,1),1);
end

blockObj.Graphics.Spikes = orgExp.libs.SpikeImage(spikes,fs,peak_train,class,...
                        'NumClus_Max',numel(unique(class)));
flag = true;
end