function flag = saveChannelSpikingEvents(blockObj,ch,spk,feat,art)
%SAVECHANNELSPIKINGEVENTS   Save spike events for a nigeLab.Block Channel
%
%  flag = blockObj.saveChannelSpikingEvents(ch,spk,feat,art);
%
%  --------
%   INPUTS
%  --------
%  blockObj       :     nigeLab.Block class object.
%
%    ch           :     Recording channel. Index of Channels property
%                          struct from blockObj.
%
%    spk          :     Spike data file matrix.
%                       |type|value|tag|ts|snippet|
%                       |zero|sampleIndex|sortingCluster|peakTime|spikes|
%
%   feat          :     Spike features data file matrix.
%                       |type|value|tag|ts|snippet|
%                       |zero|sampleIndex|sortingCluster|peakTime|features|
%
%    art          :     Artifact data file matrix.
%                       |type|value|tag|ts|snippet|
%                       |zero|artIndex|zero|artTime|zero|
%
%  --------
%   OUTPUT
%  --------
%    flag         :     Logical value indicating that save was completed
%                          successfully.
flag = false;
% CHECK FILE PATH INFO
if any(~ismember({'Spikes','SpikeFeatures','Artifact'},blockObj.Fields))
   if ~blockObj.genPaths
      warning(['nigeLab:' mfilename ':BadPaths'],...
         'Could not make correct paths.');
      return;
   end
elseif any(~ismember({'Spikes','SpikeFeatures','Artifact'},...
      fieldnames(blockObj.Paths)))
   if ~blockObj.genPaths
      warning(['nigeLab:' mfilename ':BadPaths'],...
         'Could not make correct paths.');
      return;
   end
end

% MAKE FILE NAMES
pNum  = num2str(blockObj.Channels(ch).probe);
chNum = blockObj.Channels(ch).chStr;

fNameSpikes = nigeLab.utils.getUNCPath(...
   sprintf(strrep(blockObj.Paths.Spikes.file,'\','/'),...
      pNum,chNum));
fNameFeats = nigeLab.utils.getUNCPath(...
   sprintf(strrep(blockObj.Paths.SpikeFeatures.file,'\','/'),...
      pNum,chNum));
fNameArt = nigeLab.utils.getUNCPath(...
   sprintf(strrep(blockObj.Paths.Artifact.file,'\','/'),...
      pNum,chNum));
% SAVE FILES
% Save Spikes using DiskData pointer to the file:
if exist(fullfile(fNameSpikes),'file')~=0
   delete(fullfile(fNameSpikes));
end
if exist(blockObj.Paths.Spikes.dir,'dir')==0
   mkdir(blockObj.Paths.Spikes.dir);
end
blockObj.Channels(ch).Spikes = ...
   nigeLab.libs.DiskData('Event',fullfile(fNameSpikes),...
   spk,'access','w','overwrite',true);
lockData(blockObj.Channels(ch).Spikes);
blockObj.updateStatus('Spikes',true,ch);
% Save Features using DiskData pointer to the file:
if exist(fullfile(fNameFeats),'file')~=0
   delete(fullfile(fNameFeats));
end
if exist(blockObj.Paths.SpikeFeatures.dir,'dir')==0
   mkdir(blockObj.Paths.SpikeFeatures.dir);
end
blockObj.Channels(ch).SpikeFeatures = ...
   nigeLab.libs.DiskData('Event',fullfile(fNameFeats),...
   feat,'access','w','overwrite',true);
lockData(blockObj.Channels(ch).SpikeFeatures);
blockObj.updateStatus('SpikeFeatures',true,ch);
% Save Artifact using DiskData pointer to the file:
if exist(fullfile(fNameArt),'file')~=0
   delete(fullfile(fNameArt));
end
if exist(blockObj.Paths.Artifact.dir,'dir')==0
   mkdir(blockObj.Paths.Artifact.dir);
end
blockObj.Channels(ch).Artifact = ...
   nigeLab.libs.DiskData('Event',fullfile(fNameArt),...
   art,'access','w','overwrite',true);
lockData(blockObj.Channels(ch).Artifact);
blockObj.updateStatus('Artifact',true,ch);
flag = true;
end