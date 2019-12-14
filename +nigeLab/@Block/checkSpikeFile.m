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

%% PARSE MULTIPLE ELEMENTS OF CHANNEL
if isnumeric(ch)
   if numel(ch) > 1
      flag = false(size(ch));
      for ii = 1:numel(ch)
         flag(ii) = checkSpikeFile(blockObj,ch(ii));
      end   
      return;
   end
   f = blockObj.Channels(ch).Spikes;
   info = getInfo(f);
elseif ischar(ch)
   f = matfile(ch);
   info = whos(f);
else
   error('Unrecognized input (ch) type: %s',class(ch));
end

%% CHECK FOR OLD VERSIONS
% If old version, will have 7 fields from whos


flag = numel(info) > 1;

if ~flag
   return;
end

if ischar(ch)
   [~,fname,~] = fileparts(ch);
   strinfo = strsplit(fname,blockObj.Delimiter);
   idx = find(ismember(strinfo,'Ch'),1,'first') + 1; % Channel # follows "Ch_"
   chnum = str2double(strinfo{idx});
   pnum = str2double(strinfo{idx-2}(2));
   
   ch = blockObj.matchProbeChannel(chnum,pnum);
end

%% IF OLD VERSION, FIX IT
names = {info.name};
toCheck = {'spikes','peak_train','features','artifact'};

for iCheck = 1:numel(toCheck)
   if ~ismember(toCheck{iCheck},names)
      flag = false;
      return;
   end
end

spikes = f.spikes;
peak_train = f.peak_train;
   

peak_train = f.peak_train;
features = f.features;
artifact = f.artifact;

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
value = reshape(artifact,nArt,1);
tag = zeros(nArt,1);
ts = reshape(artifact./blockObj.SampleRate,nArt,1);
snippet = zeros(nArt,1);

art = [type, value, tag, ts, snippet];



if ~blockObj.saveChannelSpikingEvents(ch,spk,feat,art)
   error('Could not save spikes for channel %d.',ch);
end

end