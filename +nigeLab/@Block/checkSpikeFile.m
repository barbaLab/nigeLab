function flag = checkSpikeFile(blockObj,ch)
%% CHECKSPIKEFILE    Check to make sure spike file is correct format, and CONVERT it
%
%  flag = CHECKSPIKEFILE(blockObj,ch);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     nigeLab.Block class object.
%
%    ch        :     Channel index for blockObj.Channels struct array.
%
%  --------
%   OUTPUT
%  --------
%   flag       :     Logical value indicating whether Spikes file needed to
%                       be converted. Returns true if the file was
%                       converted.
%
% By: Max Murphy & Federico Barban MAECI 2019 Collaboration

%% CHECK FOR OLD VERSIONS
% If old version, will have 7 fields from whos
info = getInfo(blockObj.Channels(ch).Spikes);
flag = numel(info) > 1;

if ~flag
   return;
end

%% IF OLD VERSION, FIX IT
names = {info.name};
spikes = blockObj.Channels(ch).Spikes.spikes;
peak_train = blockObj.Channels(ch).Spikes.peak_train;
features = blockObj.Channels(ch).Spikes.features;
artifact = blockObj.Channels(ch).Spikes.artifact;

tIdx = find(peak_train);

nSpk = numel(tIdx);
nArt = numel(artifact);

% Format spikes data
type = zeros(nSpk,1);
value = tIdx;
tag = getSort(blockObj,ch,true);
ts = tIdx./blockObj.SampleRate;
spk = [type, value, tag, ts, spikes];

% Format features data
feat = [type, value, tag, ts, features];

% Format artifact data
type = zeros(nArt,1);
value = artifact;
tag = zeros(nArt,1);
ts = artifact./blockObj.SampleRate;
snippet = zeros(nArt,1);

art = [type, value, tag, ts, snippet];

if ~blockObj.saveChannelSpikingEvents(ch,spk,feat,art)
   error('Could not save spikes for channel %d.',ch);
end

end