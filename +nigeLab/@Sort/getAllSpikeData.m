function [spikes,feat,class,tag,ts,blockIdx] = getAllSpikeData(sortObj,ch)
%% GETALLSPIKEDATA  Concatenate all spike data for a given channel
%
%  [spikes,feat,class,tag,ts,blockIdx] = GETALLSPIKEDATA(sortObj)
%
%  --------
%   INPUTS
%  --------
%  sortObj     :     nigeLab.Sort class object.
%
%  --------
%   OUTPUT
%  --------
%   spikes     :     All spikes for all blocks on channel indexed by ch
%                       from the master channel ID list.
%
%   feat       :     Same as spikes, but rows are extracted features for
%                       each spike.
%
%   class      :     Current spike assignments for each spike.
%
%    tag       :     Current tag assignment for each spike.
%
%     ts       :     Spike time of each spike.
%
%   blockIdx   :     Index of each block for each spike.
%
% By: Max Murphy  v1.0  2019/01/09  Original version (R2017a)

%% ONLY ITERATE ON BLOCKS THAT HAVE THIS CHANNEL
vec = find(~isnan(sortObj.Channels.Idx(ch,:)));

%% FOR EACH BLOCK IN THE SUBSET, RETRIEVE SPIKES, FEATURES, AND CLASS
spikes = [];
feat = [];
class = [];
tag = [];
ts = [];
blockIdx = [];
for ii = vec
   % If multiple sample rates, warn the user and exit
   if abs(sortObj.Blocks(ii).SampleRate-sortObj.spk.fs)>eps
      error('Recordings with different sample rates are incompatible.');
   end
   
   % Retrieve associated spikes
   tmp = getEventData(sortObj.Blocks(ii),'Spikes','snippet',...
      sortObj.Channels.Idx(ch,ii));
   spikes = [spikes; tmp]; %#ok<*AGROW>
   
   % Retrieve associated features
   tmp = getEventData(sortObj.Blocks(ii),'SpikeFeatures','snippet',...
      sortObj.Channels.Idx(ch,ii));
   feat = [feat; tmp];
   
   % Retrieve associated class
   tmp = getSort(sortObj.Blocks(ii),sortObj.Channels.Idx(ch,ii));
   tmp(tmp < 1) = 1; % Anything less than 1 is assigned to 'OUT' cluster
   tmp(tmp > sortObj.pars.SpikePlotN) = 1; % Any too large is also 'OUT'
   class = [class; tmp];
   
   % Retrieve associated tag
   tmp = getTag(sortObj.Blocks(ii),sortObj.Channels.Idx(ch,ii));
   tag = [tag; tmp];
   
   % Retrieve associated ts
   tmp = getSpikeTimes(sortObj.Blocks(ii),sortObj.Channels.Idx(ch,ii));
   ts = [ts; tmp];
   
   % Make sure to associate each element with the corresponding block
   blockIdx = [blockIdx; ones(size(tmp)).*ii];
end

% Normalize to standard deviation:
feat = (feat - mean(feat,1))./std(feat,[],1);

end