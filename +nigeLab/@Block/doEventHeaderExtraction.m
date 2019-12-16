function flag = doEventHeaderExtraction(blockObj,behaviorData,vidOffset)
% DOEVENTHEADEREXTRACTION  Creates "header" for scored behavioral events
%
%  flag = blockObj.doEventHeaderExtraction; --> Standard
%  flag = blockObj.doEventHeaderExtraction(behaviorData); --> Convert old
%
%  Returns true if header extraction proceeded correctly.
%  Generates a "header" file that is a nigeLab.libs.DiskData 'Event' type
%  file. Each row corresponds to a different video, and the 'ts' property
%  (4th column) corresponds to the Video Offset (a positive value denotes
%  that the video started AFTER the neural recording). Columns of 'snippet'
%  (columns 5+) denote the 'VarType' of metadata associated with the
%  corresponding column, for blockObj.scoreVideo.
%  If behaviorData is provided, then it is used to assign 'VarType'. This
%  second input can also just be given as 'VarType' directly.

%%
flag = false;
blockObj.checkActionIsValid();
blockObj.updateParams('Video');
f = blockObj.Pars.Video.ScoringEventFieldName;

if isempty(f)
   warning(1,'Must specify defaults.Video.ScoringEventFieldName to extract Header.');
   return;
else
   fname = nigeLab.utils.getUNCPath(fullfile(blockObj.Paths.(f).dir,...
         sprintf(blockObj.BlockPars.(f).File, 'Header')));
   if exist(fname,'file')~=0
      flag = true;
      fprintf(1,'Header already exists for %s.\n',blockObj.Name);
      return;
   end
end

% Get number of videos to match up with
N = sum(blockObj.Status.Video);
if N < 1
   warning('No videos associated with %s',blockObj.Name);
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
   else % Or assign the vector directly
      VarType = behaviorData;
   end
end
iMetadata = VarType > 1;
VarType = VarType(iMetadata);

% Check 'Offset' (`ts` --> column 4)
if (nargin < 3)
   vidOffset = nan;
elseif isempty(vidOffset)
   vidOffset = nan;
end

data = nigeLab.utils.initEventData(N,sum(iMetadata),2);
data(:,4) = vidOffset;
data(:,5:end) = VarType;
out = nigeLab.libs.DiskData('Event',fname,data);

flag = true;

end