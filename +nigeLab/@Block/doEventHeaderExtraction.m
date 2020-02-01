function flag = doEventHeaderExtraction(blockObj,behaviorData,vidOffset)
%DOEVENTHEADEREXTRACTION  Creates "header" for scored behavioral events
%
%  flag = blockObj.doEventHeaderExtraction; --> Standard
%  flag = blockObj.doEventHeaderExtraction(behaviorData); --> Convert old
%  flag = blockObj.doEventHeaderExtraction(VarType); 
%  --> This is the same as passing behaviorData, as behaviorData is only
%        used to determine varType for Event DiskData type.
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

flag = false;
blockObj.checkActionIsValid();
blockObj.updateParams('Video');
f = blockObj.Pars.Video.ScoringEventFieldName;

[fmt,idt] = blockObj.getDescriptiveFormatting();
if isempty(f)
   if blockObj.Verbose
      nigeLab.utils.cprintf('Errors*','%s[DOEVENTHEADEREXTRACTION]: ',idt);
      nigeLab.utils.cprintf(fmt,...
         'Must specify defaults.Video.ScoringEventFieldName (%s)\n',...
         blockObj.Name);
   end
   return;
else
   fname = sprintf(blockObj.Paths.(f).file,'Header');
   if exist(fname,'file')~=0
      flag = true;
      if blockObj.Verbose
         nigeLab.utils.cprintf('Errors*','%s[DOEVENTHEADEREXTRACTION]: ',idt);
         nigeLab.utils.cprintf(fmt,'Header exists (%s)\n',blockObj.Name);
      end
      out = nigeLab.libs.DiskData('Event',fname);
      return;
   end
end

% Get number of videos to match up with
N = sum(blockObj.Status.Video);
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
data(:,5:end) = ones(N,1) * VarType;
hIdx = getEventsIndex(blockObj,f,'Header');
blockObj.Events.(f)(hIdx).data = ...
   nigeLab.libs.DiskData('Event',fname,data,'overwrite',true);

flag = true;

end