function flag = initVideos(blockObj)
%% INITVIDEOS Initialize Videos struct for nigeLab.Block class object
%
%  flag = INITVIDEOS(blockObj); Returns false if initialization fails

%% Get parameters associated with video
flag = false; % Initialize to false
[~,p] = blockObj.updateParams('Video');
if ~p.HasVideo
   flag = true;
   return;
end

%% Get string for parsing matched video file names
dynamicVars = cellfun(@(x)x(2:end),p.DynamicVars,'UniformOutput',false);
idx = find(ismember(dynamicVars,fieldnames(blockObj.Meta)));
if isempty(idx)
   error('Could not find any metadata fields to use for parsing Video filenames.');
end

matchStr = '*';
for i = 1:numel(idx)
   matchStr = [matchStr, blockObj.Meta.(dynamicVars{idx(i)}) '*']; %#ok<*AGROW>
end
matchStr = [matchStr, p.FileExt];

%% Look for video files. Stop after first path where videos are found.
i = 0;
while i < numel(p.VidFilePath)
   i = i + 1;
   F = dir(nigeLab.utils.getUNCPath(fullfile(p.VidFilePath{i},matchStr)));
   if ~isempty(F)
      break;
   end
end
% Throw error if no videos are found
if isempty(F)
   error(['Couldn''t find video files (matchStr: ''%s''). '...
          'Check defaults.Video(''DynamicVars'')'], matchStr);
end

% Make "Videos" fieldtype object or array
vidFieldObj = nigeLab.libs.VideosFieldType(F,p);

%% Initialize "VidStreams" if it is a Field (special case)
if ~ismember('VidStreams',blockObj.Fields)
   flag = true;
   return;
end

if isempty(p.CameraSourceVar) % Should have same streams for all videos
   vidStreamSignals = p.VidStream;
   blockObj.Videos = nigeLab.libs.VidStreamsType(...
      vidFieldObj,vidStreamSignals);
   
else % If different videos contain different streams (for example, TOP vs DOOR)
   nVid = numel(vidFieldObj);
   blockObj.Videos = nigeLab.libs.VidStreamsType(nVid);
   
   for iVid = 1:nVid
      [source,signalIndex] = blockObj.Videos(iVid).getVideoSourceInfo;
      source = repmat({source},1,numel(p.VidStreamGroup{signalIndex}));
      vidStreamSignals = nigeLab.utils.signal(...
         p.VidStreamGroup{signalIndex},...
         p.VidStreamField{signalIndex},...
         p.VidStreamFieldType{signalIndex},...
         source,...
         p.VidStreamName{signalIndex},...
         p.VidStreamSubGroup{signalIndex});
      
      blockObj.Videos(iVid) = nigeLab.libs.VidStreamsType(...
         vidFieldObj(iVid),vidStreamSignals);
      
   end
end
setPath(blockObj.Videos,nigeLab.utils.getUNCPath(blockObj.Paths.VidStreams.file));


flag = true;


end