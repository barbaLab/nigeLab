function flag = initVideos(blockObj)
%% INITVIDEOS Initialize Videos struct for nigeLab.Block class object
%
%  flag = INITVIDEOS(blockObj); Returns false if initialization fails

%% Get parameters associated with video
flag = false; % Initialize to false
[~,pars] = blockObj.updateParams('Video',true);
if ~pars.HasVideo
   flag = true;
   return;
end

% Make "Videos" fieldtype object or array
blockObj.Videos = nigeLab.libs.VideosFieldType(blockObj);
if isempty(blockObj.Videos)
   flag = true;
   return;
end

%% Initialize "VidStreams" if it is a Field (special case)
if ~ismember('VidStreams',blockObj.Fields)
   flag = true;
   return;
end

if isempty(pars.CameraSourceVar) % Should have same streams for all videos
   vidStreamSignals = pars.VidStream;
   blockObj.Videos.addStreams(vidStreamSignals);
   
else % If different videos contain different streams (for example, TOP vs DOOR)
   addStreams(blockObj.Videos); % Don't give vidStreamSignals input arg
end


flag = true;


end