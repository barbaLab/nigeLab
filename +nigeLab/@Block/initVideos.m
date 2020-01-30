function flag = initVideos(blockObj,forceNewParams)
%INITVIDEOS Initialize Videos struct for nigeLab.Block class object
%
%  flag = initVideos(blockObj); Returns false if initialization fails
%
%  flag = blockObj.initVideos(true);
%  --> forceNewParams is false by default; this forces to update the video
%      parameter struct from the +defaults/Videos.m file

if nargin < 2
   forceNewParams = true;
end
if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      flag = flag && initVideos(blockObj(i),forceNewParams);
   end
   return;
else
   flag = false; % Initialize to false
end
if isempty(blockObj)
   flag = true;
   return;
elseif ~isvalid(blockObj)
   flag = true;
   return;
end
% Get parameters associated with video
if forceNewParams
   blockObj.updateParams('Video','Direct');
elseif ~isfield(blockObj.Pars,'Video')
   blockObj.updateParams('Video','KeepPars');
end
% Initialize Videos version of Paths
initKeyFile=[strrep(blockObj.Name,blockObj.Pars.Block.Concatenater,'*') ...
   '*' blockObj.Pars.Video.FileExt];
[initRoot,initFolder] = fileparts(blockObj.Pars.Video.DefaultSearchPath);
blockObj.Paths.V = struct(...
   'Root',initRoot,...
   'Folder',initFolder,...
   'KeyFile', initKeyFile,...
   'FileExt',blockObj.Pars.Video.FileExt);
[fmt,idt,~] = blockObj.getDescriptiveFormatting();

if ~isfield(blockObj.Meta,'Video')
   blockObj.Meta.Video = []; % Initialize 'Video' meta field
end

if ~blockObj.Pars.Video.HasVideo
   flag = true;
   nigelab.utils.cprintf(fmt,'%s[BLOCK/INITVIDEOS]: ');
   nigeLab.utils.cprintf(fmt(1:(end-1)),...
      'Skipped video initialization (%s)\n',blockObj.Name);
   return;
end

% % % % Fills out .V paths struct % % % %
% First, use default config to try and automatically find ONE video file
% that is associated with this particular recording block.
blockObj.Paths.V.Match = parseVidFileExpr(blockObj);
% Note that parseVidFileName calls nigeLab.libs.VideosFieldType.parse()
f_search = fullfile(...
   blockObj.Paths.V.Root,...
   blockObj.Paths.V.Folder,...
   blockObj.Paths.V.Match);
blockObj.Paths.V.F = dir(f_search);

if ~isempty(blockObj.Paths.V.F)
   vidFileName = fullfile(blockObj.Paths.V.Root,blockObj.Paths.V.Folder,...
                           blockObj.Paths.V.F(1).name);
else
   if blockObj.Pars.Video.UseVideoPromptOnEmpty
      [fName,pName, ~] = uigetfile(blockObj.Pars.Video.ValidVidExtensions,...
         sprintf('Select VIDEO for %s',blockObj.Name),...
         blockObj.Pars.Video.DefaultSearchPath);
      if fName==0
         nigeLab.utils.cprintf(fmt,...
            '%s[DOVIDINFOEXTRACTION]: No video selected for %s %s\n',...
            idt,type,blockObj.Name);
         dbstack(); % See note below:
         return;    % Should throw error due to flag == false
         % Will leave it as-is; this could easily happen if .HasVideo is
         % accidentally configured to false. Would be easier for user to just
         % change .HasVideo in ~/+defaults/Video.m and retry the Block
         % constructor than to cancel every video selection.
      end
      vidFileName = fullfile(pName,fName);
   else
      flag = true; % Indicate this is fine; there are just no videos for 
                   % this particular Block (probably from a batch
                   % initialization where some blocks have video and others
                   % do not)
      return;
   end
end

% Parse name, path, type of video file
[pName,fName,ext] = fileparts(vidFileName);
fName = [fName ext];

% .Root is "one-level" up (in case videos are in their own folder by
% recording, for example)
[root,folder] = fileparts(pName);
blockObj.Paths.V = struct(...
   'Root',root,...
   'Folder',folder,...
   'KeyFile',fName,...
   'FileExt',ext);
blockObj.Paths.V.Match = parseVidFileExpr(blockObj);

% Make "Videos" fieldtype object or array
blockObj.Videos = nigeLab.libs.VideosFieldType(blockObj);
uView = unique({blockObj.Videos.Source});
initRelativeTimes(blockObj.Videos,uView);
flag = true;
end