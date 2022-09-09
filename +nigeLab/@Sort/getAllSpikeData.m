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
ts = []; maxTs = 0;
blockIdx = [];
for ii = vec
   % If multiple sample rates, warn the user and exit
   if abs(sortObj.Blocks(ii).SampleRate-sortObj.spk.fs)>eps
      error(['nigeLab:' mfilename ':IncompatibleSampleRates'],...
         'Recordings with different sample rates are incompatible.');
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
   tmp( tmp > 0) = mod(tmp( tmp > 0) - 1, sortObj.pars.SpikePlotN-2) + 2; % everything is brought back to the clusters 1-9.
   tmp(tmp < 1 | isnan(tmp)) = 1; % Anything less than 1 is assigned to 'OUT' cluster
% TODO add a warning in case there are more then 8 clusters
   class = [class; tmp];
   
   % Retrieve associated tag
   tmp = getTag(sortObj.Blocks(ii),sortObj.Channels.Idx(ch,ii));
   tag = [tag; tmp];
   
   % Retrieve associated ts
   tmp = getSpikeTimes(sortObj.Blocks(ii),sortObj.Channels.Idx(ch,ii)) + maxTs;
   ts = [ts; tmp]; 
   maxTs = max(ts);
   
   % Make sure to associate each element with the corresponding block
   blockIdx = [blockIdx; ones(size(tmp)).*ii];
end

% Normalize to standard deviation:
feat = (feat - mean(feat,1))./std(feat,[],1);

end