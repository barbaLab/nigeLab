function flag = plotSpikes(blockObj,ch,class)
%% PLOTSPIKES  Show all spike clusters for a given channel.
%
%  flag = blockObj.PLOTSPIKES(ch)
%  flag = blockObj.PLOTSPIKES(ch,class)
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class in orgExp package.
%
%    ch        :     Channel index for retrieving spikes. Must be given as
%                       a SCALAR positive integer.
%
%   class      :     (Optional) Specify the class of spikes to retrieve,
%                       based on sorting or clustering. If not specified,
%                       gets all spikes on channel. Otherwise, it will
%                       check to make sure that there are actually classes
%                       associated with the spike and issue a warning if
%                       that part hasn't been done yet.
%                       -> Can be given as a vector.
%                       -> Non-negative integer.
%                       -> Default is NaN
%
%  --------
%   OUTPUT
%  --------
%    flag   :     Returns true if the spike plot is successfully built.
%
%
% By: Max Murphy  v1.1  08/27/2017  Original version (R2017a)
% Extended by: MAECI 2018 Collaboration (Max Murphy & Federico Barban)
% See also: SPIKEIMAGE, BLOCK

%% PARSE INPUT ARGUMENTS
flag = false;
if ~ismember('Spikes',blockObj.Fields(blockObj.Status))
   warning('No spikes detected yet.');
   return;
end

if nargin < 3
   class = nan;
elseif ~ismember('Sorted',blockObj.Fields(blockObj.Status))
   class = nan;
end

if ~ParseSingleChannelInput(blockObj,ch)
   warning('Check ''ch'' input argument. SpikeImage not generated.');
   return;
end

%% GET DATA FOR SPIKEIMAGE
spikes = blockObj.getSpikes(ch,class);
peak_train = blockObj.Channels(ch).Spikes.peak_train;
fs = blockObj.SampleRate;
cl = blockObj.getSort(ch);
if isnan(cl)
   class = ones(size(spikes,1),1);
else
   class = cl(ismember(cl,class));
end

blockObj.Graphics.Spikes = nigeLab.libs.SpikeImage(spikes,fs,peak_train,class,...
                        'NumClus_Max',numel(unique(class)));
flag = true;
end