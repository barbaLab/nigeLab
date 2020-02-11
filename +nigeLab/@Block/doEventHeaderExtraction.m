function flag = doEventHeaderExtraction(blockObj,behaviorData,vidOffset,forceHeaderExtraction)
%DOEVENTHEADEREXTRACTION  Creates "header" for scored behavioral events
%
%  flag = doEventHeaderExtraction(blockObj); 
%  --> Standard format
%  
%  flag = blockObj.doEventHeaderExtraction(behaviorData); 
%  --> Convert old format (behaviorData table)
%
%  --> behaviorData can also be given as a scalar integer as the number of
%  total trials.
%  
%  flag = blockObj.doEventHeaderExtraction(behaviorData,vidOffset);
%  --> Scalar or vector for each video with the offset of each video
%  relative to the neural signal.
%
%  flag = doEventHeaderExtraction(behaviorData,vidOffset,true);
%  --> Forces to overwrite existing `header` file even if it is present.
%
%  Returns true if header extraction proceeded correctly.
%  Generates a "header" file that is a nigeLab.libs.DiskData 'Event' type
%  file. Each row corresponds to a different video, and the 'ts' property
%  (4th column) corresponds to the Video Offset (a positive value denotes
%  that the video started AFTER the neural recording). Columns of 'snippet'
%  (columns 5+) denote the 'VarType' of metadata associated with the
%  corresponding column, for blockObj.scoreVideo.
%  Depending on number of metadata variables, there are a fixed # of
%  columns of metadata 'VarType' and then after that each column
%  corresponds to an individual trial. The number of 'VarType' variables is
%  denoted in the 2nd column. The 3rd column acts as a "Mask" vector for
%  Videos.
%  
%  If "videoOffset" is column 4, and "offset_trial" is the trial-specific 
%  variable held for a particular trial of interest (after the Meta 
%  variable "VarType" columns), then 'trial-related' column variable
%  indicates the specific offset for that camera as
%
%  >> offset_trial = tNeu - (tEvent + videoOffset);
%
%  --> So, for example, if an Event timestamp is saved for 'Reach' for
%  trial 11, and a trial-specific offset is set for Camera-2, then you can
%  recover the corresponding neural timestamp for that Event as
%
%  >> tNeu = tEvent + videoOffset + offset_trial;
%
%  Note that in this case, videoOffset encompasses both 'tStart' and
%  'Offset' properties of blockObj.Videos (VideosFieldType). When 'Offset'
%  is accessed via the .Videos property, 'tStart' is automatically
%  subtracted from the value stored on the DiskFile.

if nargin < 4
   forceHeaderExtraction = false;
end

if nargin < 3
   vidOffset = [];
end

if nargin < 2
   behaviorData = [];
   nEvent = 0;
elseif istable(behaviorData)
   nEvent = size(behaviorData,1);
elseif isnumeric(behaviorData)
   nEvent = behaviorData;
else
   error(['nigeLab:' mfilename 'BadInputClass'],...
      '[DOEVENTHEADEREXTRACTION]: Invalid behaviorData class (''%s'')',...
      class(behaviorData));
end

if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      flag = flag && doEventHeaderExtraction(blockObj,behaviorData,vidOffset);
   end
   return;
else
   flag = false;
end
checkActionIsValid(blockObj);

[fmt,idt] = getDescriptiveFormatting(blockObj);
if isempty(blockObj.ScoringField)
   if blockObj.Verbose
      nigeLab.utils.cprintf('Errors*','%s[DOEVENTHEADEREXTRACTION]: ',idt);
      nigeLab.utils.cprintf(fmt,...
         'Must specify defaults.Video.ScoringEventFieldName (%s)\n',...
         blockObj.Name);
   end
   return;
else
   fname = sprintf(blockObj.Paths.(blockObj.ScoringField).file,'Header');
   if (exist(fname,'file')~=0) && (~forceHeaderExtraction)
      flag = true;
      if blockObj.Verbose
         nigeLab.utils.cprintf('Errors*','%s[DOEVENTHEADEREXTRACTION]: ',idt);
         nigeLab.utils.cprintf(fmt,'Header exists (%s)\n',blockObj.Name);
      end
      hIdx = getEventsIndex(blockObj,blockObj.ScoringField,'Header');
      blockObj.Events.(blockObj.ScoringField)(hIdx).data = ...
         nigeLab.libs.DiskData('Event',fname);
      return;
   end
end

% Get number of videos to match up with
N = numel(blockObj.Videos);
if N < 1
   if blockObj.Verbose
      nigeLab.utils.cprintf('Errors*','%s[DOEVENTHEADEREXTRACTION]: ',idt);
      nigeLab.utils.cprintf(fmt,'No videos (%s)\n',blockObj.Name);
   end
   N = 1;
end

% Extract 'VarType' (`snippet` --> columns 5+)
if nargin < 2
   VarType = blockObj.Pars.Video.VarType;
elseif isempty(behaviorData)
   VarType = blockObj.Pars.Video.VarType;
else
   if istable(behaviorData) % Extract from table
      VarType = behaviorData.Properties.UserData;
   else
      VarType = blockObj.Pars.Video.VarType;
   end
end
iMetadata = VarType > 1;
VarType = VarType(iMetadata);

% Check 'GrossOffset' (`ts` --> column 4)
if (nargin < 3)
   vidOffset = vertcat(blockObj.Videos.GrossOffset);
   offset = vertcat(blockObj.Videos.VideoOffset);
   vidOffset(isnan(vidOffset)) = offset(isnan(vidOffset));
elseif isempty(vidOffset)
   vidOffset = vertcat(blockObj.Videos.GrossOffset);
   offset = vertcat(blockObj.Videos.VideoOffset);
   vidOffset(isnan(vidOffset)) = offset(isnan(vidOffset));
end

nMeta = max(sum(iMetadata),1); % At least 1
data = nigeLab.utils.initEventData(N,nMeta+nEvent,2);
data(:,2) = nMeta;
data(:,4) = vidOffset;
data(:,5:(5+nMeta-1)) = ones(N,1) * VarType;
if nEvent > 0
   data(:,(5+nMeta):end) = zeros(N,nEvent);
end
hIdx = getEventsIndex(blockObj,blockObj.ScoringField,'Header');
blockObj.Events.(blockObj.ScoringField)(hIdx).data = ...
   nigeLab.libs.DiskData('Event',fname,data,'overwrite',true);

flag = true;

end