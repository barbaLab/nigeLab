function flag = doVidInfoExtraction(blockObj,vidFileName,forceParamsUpdate)
%DOVIDINFOEXTRACTION   Get video metadata for associated behavioral vids
%
%  flag = DOVIDINFOEXTRACTION(blockObj);
%
%  flag = doVidInfoExtraction(blockObj,vidFileName);
%
%  flag = doVidInfoExtraction(___,forceParamsUpdate);
%  --> Optional flag can be set to true to force params from 
%      +defaults/Videos.m instead of from saved params
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class object from orgExp package.
%
%  vidFileName :     (Optional) Char array of video full file name.
%                    --> Give as cell array corresponding to elements of
%                        blockObj (if there are blockObj elements with no
%                        video, then those should have a corresponding
%                        empty cell).
%                    --> Includes the path to the file as well
%
%  --------
%   OUTPUT
%  --------
%     flag     :     Boolean logical operator to indicate whether
%                     synchronization

if nargin < 2
   vidFileName = cell(size(blockObj));
end

if nargin < 3
   forceParamsUpdate = false;
end

% Handle input
if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      flag = flag && doVidInfoExtraction(blockObj(i),...
         vidFileName{i},...
         forceParamsUpdate);
   end
   return;
else
   if iscell(vidFileName)
      vidFileName = vidFileName{:};
   end
   flag = false;
end

% Check that blockObj is OK for this
if isempty(blockObj)
   flag = true;
   return;
elseif ~isvalid(blockObj)
   flag = true;
   return;
end
   
% Check parameters
if forceParamsUpdate
   updateParams(blockObj,'Video','Direct');
elseif ~isfield(blockObj.Pars,'Video')
   updateParams(blockObj,'Video','KeepPars');
end

% Get formatting for printing outputs
[fmt,idt,type] = getDescriptiveFormatting(blockObj);

if ~isfield(blockObj.Paths,'V') % Then initVideos was old/incorrect
   if blockObj.Verbose
      nigeLab.utils.cprintf('Errors*','%s[DOVIDINFOEXTRACTION]: ',idt);
      nigeLab.utils.cprintf(fmt,'%s.Videos initialized incorrectly (%s)\n',...
         type,blockObj.Name);
      nigeLab.utils.cprintf('[0.55 0.55 0.55]','\t%s(Re-running ',idt);
      nigeLab.utils.cprintf('Keywords*','`nigeLab.Block/initVideos`');
      nigeLab.utils.cprintf('[0.55 0.55 0.55]',')\n');
   end
   % Force overwrite of video parameters in this case (in case old
   % parameters had been used):
   flag = initVideos(blockObj,true);
   return;
end

% Do this after updating the .Paths parameters, for convenience elsewhere
if ~checkActionIsValid(blockObj)
   flag = true;
   return;
end

% If vidFileName not given, try to find it using already-known block info
if isempty(vidFileName)
   paths = blockObj.Paths.V;
   if isfield(paths,'Root') && isfield(paths,'Folder')
      if ~isempty(paths.Root) && ~isempty(paths.Folder)
         p = fullfile(paths.Root,paths.Folder);
      else
         p = blockObj.Pars.Video.DefaultSearchPath;
      end
   else
      p = blockObj.Pars.Video.DefaultSearchPath;
   end
   matchStr_init = parseVidFileExpr(blockObj);
   F_init = dir(fullfile(p,matchStr_init));
   if ~isempty(F_init)
      vidFileName = fullfile(p,F_init(1).name);
   end
end


if exist(vidFileName,'file')==0
   if blockObj.Pars.Video.UseVideoPromptOnEmpty
      if isfield(blockObj.Paths.V,'Root')
         if exist(blockObj.Paths.V.Root,'dir')==0
            defPath = blockObj.Pars.Video.DefaultSearchPath;
         else
            defPath = blockObj.Paths.V.Root;
         end
      else
         defPath = blockObj.Pars.Video.DefaultSearchPath;
      end
      [fName,pName, ~] = uigetfile(blockObj.Pars.Video.ValidVidExtensions,...
         sprintf('Select VIDEO for %s',blockObj.Name),defPath);
      if fName==0
         nigeLab.utils.cprintf(fmt,...
            '%s[DOVIDINFOEXTRACTION]: No video selected for %s %s\n',...
            idt,type,blockObj.Name);
         return;
      end
      vidFileName = fullfile(pName,fName);
   else
      flag = true;
      nigeLab.utils.cprintf('[0.60 0.60 0.60]*',...
         '%s[DOVIDINFOEXTRACTION]: ',idt);
      nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
         'No videos found for %s %s\n',type,blockObj.Name);
      return;
   end
end

% Parse name, path, type of video file
[pName,fName,ext] = fileparts(vidFileName);
fName = [fName ext];

% .Root is "one-level" up (in case videos are in their own folder by
% recording, for example)
paths = struct('Root','','Folder','','KeyFile',fName,'FileExt',ext);
if ~isfield(blockObj.Paths.V,'Root')
   [paths.Root,paths.Folder,~] = fileparts(pName); % One-level-up
elseif ~contains(fullfile(pName),fullfile(blockObj.Paths.V.Root))
   [paths.Root,paths.Folder,~] = fileparts(pName); % One-level-up
else
   if isempty(blockObj.Paths.V.Root)
      [paths.Root,paths.Folder,~] = fileparts(pName); % One-level-up
   else
      paths.Root = blockObj.Paths.V.Root;
      [~,paths.Folder,~] = fileparts(pName);
   end
end
blockObj.Paths.V = paths;
blockObj.Paths.V.Match = parseVidFileExpr(blockObj);

% MATCH AND FIND OTHER VIDEOS WITH SAME NAME CONVENTION
F = dir(fullfile(pName,blockObj.Paths.V.Match));
% Give output of what is being done
nVid = numel(F);
if blockObj.Verbose
   nigeLab.utils.cprintf(fmt,'%s[DOVIDINFOEXTRACTION]: ',idt);
   nigeLab.utils.cprintf(fmt(1:(end-1)),...
      'Extracting info for %g videos (%s: %s)\n',...
      nVid,type,blockObj.Name);
end

% Start timing and invoke the constructor for
% `nigeLab.libs.VideosFieldType` via call to `updateVidInfo(blockObj)`
s = tic;
flag = updateVidInfo(blockObj);
if flag
   if isempty(blockObj.Videos)
      if blockObj.Verbose
         nigeLab.utils.cprintf(fmt(1:(end-1)),...
            '\t%sSuccessful [No videos]\n',idt);
      end
      blockObj.updateStatus('Video',false);
   else
      if blockObj.Verbose
         nigeLab.utils.cprintf(fmt(1:(end-1)),...
            '\t%sSuccessful [%g videos: %g seconds]\n',...
            idt,nVid,round(toc(s)));
      end
      vec = 1:nVid;
      blockObj.updateStatus('Video',true(1,nVid));
   end
else
   if blockObj.Verbose
      nigeLab.utils.cprintf(fmt(1:(end-1)),...
            '\t%sUnsuccessful [%g videos: %g seconds]\n',...
            idt,nVid,round(toc(s)));
   end
   blockObj.updateStatus('Video',false);
end
end

