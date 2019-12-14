function flag = doEventDetection(blockObj,behaviorData,vidOffset)
% DOEVENTDETECTION  "Detects" putative Trial events
%
%  flag = blockObj.doEventDetection; 
%  flag = blockObj.doEventDetection(behaviorData); --> To port old format
%  flag = blockObj.doEventDetection(behaviorData,vidOffset); --> Port
%
%  Returns true if event detection proceeds correctly.
%  Generates a list of timestamps for putative "Trial" behavioral events.
%  This is used if blockObj.Pars.Video.ScoringEventFieldName is not empty.

%%
flag = false;
blockObj.updateParams('Video');
blockObj.updateParams('Event');

f = blockObj.Pars.Video.ScoringEventFieldName;
if isempty(f)
   warning(1,'No scoring to be done for %s.\n',blockObj.Name);
   extractHeader = false;
else
   extractHeader = ~blockObj.Status.(f);
end

% Always make the "Header" Events file using the most arguments possible. 
% Depending on number of inputs
if nargin < 3
   vidOffset = [];
end

if nargin < 2
   behaviorData = [];
end

if extractHeader
   blockObj.doEventHeaderExtraction(behaviorData,vidOffset);
end

ePars = blockObj.Pars.Event;
vPars = blockObj.Pars.Video;
switch nargin
   case 1 % Actually does the extraction
      % Always extract 'Trial' first
      if ~isempty(f)
         detPars = ePars.TrialDetectionInfo;
         ft = blockObj.getFieldType(detPars.Field);
         switch ft
            case 'Videos'
               trial = getStream(blockObj.Videos,detPars.Name,detPars.Source);
            case 'Streams'
               trial = blockObj.getStream(detPars.Name);
            otherwise
               error('Should be either ''Videos'' or ''Streams'', (not %s)',ft);
         end
         % Get 'Trial' times
         ts = nigeLab.utils.binaryStream2ts(trial.data,trial.fs,...
               detPars.Threshold,detPars.Type,detPars.Debounce);
         nEvent = numel(ts);
            
         % Save 'Trial' times
         iEventTimes = vPars.VarType <= 1;
         fname = nigeLab.utils.getUNCPath(fullfile(blockObj.Paths.(f).dir,...
            sprintf(blockObj.BlockPars.(f).File, 'Trial')));
         data = nigeLab.utils.initEventData(nEvent,sum(~iEventTimes),1);
         data(:,4) = ts;
         out = nigeLab.libs.DiskData('Event',fname,data);
         
         % Check for the rest of "iEventTimes" files
         v = vPars.VarsToScore(iEventTimes);
         for iV = 1:numel(v)
            fname = nigeLab.utils.getUNCPath(fullfile(blockObj.Paths.(f).dir,...
               sprintf(blockObj.BlockPars.(f).File, v{iV})));
            if exist(fname,'file')==0 % Only overwrite if nothing there
               data = nigeLab.utils.initEventData(nEvent,0,1);
               out = nigeLab.libs.DiskData('Event',fname,data);
            end
         end
      end
      % Find 'EventType' == 'auto' and create corresponding disk file
      % that is a list of times based on the 'Type' of transition
      for iE = 1:numel(ePars.Name)
         if ~strcmpi(ePars.EventType(ePars.Fields{iE}),'auto')
            continue; % Don't do this for 'manual' fields
         end         
         ft = blockObj.getFieldType(ePars.Fields{iE});
         switch ft
            case 'Videos'
               stream = getStream(blockObj.Videos,ePars.Name,vPars.VideoEventCamera);
            case 'Streams'
               stream = blockObj.getStream(ePars.Name);
            otherwise
               error('Should be either ''Videos'' or ''Streams'', (not %s)',ft);
         end
         if isempty(stream)
            continue;
         end
         ts = nigeLab.utils.binaryStream2ts(stream.data,stream.fs,...
               detPars.Threshold,...
               ePars.EventDetectionType{iE},...
               detPars.Debounce);
            
         fname = nigeLab.utils.getUNCPath(fullfile(blockObj.Paths.(ft).dir,...
            sprintf(blockObj.BlockPars.(ft).File, ePars.Name)));
         
         data = nigeLab.utils.initEventData(nEvent,sum(~iEventTimes),1);
         data(:,4) = ts;
         out = nigeLab.libs.DiskData('Event',fname,data);
      end      
      
   case {2,3} % Assign from behaviorData table
      iEventTimes = behaviorData.Properties.UserData <= 1;
      v = behaviorData.Properties.VariableNames(iEventTimes);
      meta = behaviorData.Properties.VariableNames(~iEventTimes);
      nEvent = size(behaviorData,1);
      % Cycle through all 'EventTimes' table variables (columns) and make a
      % separate file for each of them. This will include the 'Trial'
      % event, effectively doing the 'Trial' extraction.
      for iV = 1:numel(v)
         fname = nigeLab.utils.getUNCPath(fullfile(blockObj.Paths.(f).dir,...
            sprintf(blockObj.BlockPars.(f).File, v{iV})));
         switch v{iV}
            case 'Trial'
               data = nigeLab.utils.initEventData(nEvent,sum(~iEventTimes),1);
               data(:,5:end) = table2array(behaviorData(:,meta));
            otherwise
               data = nigeLab.utils.initEventData(nEvent,0,1);
         end
         data(:,4) = behaviorData.(v{iV});
         out = nigeLab.libs.DiskData('Event',fname,data);
      end      
   otherwise
      error('Invalid number of input arguments (%g)',nargin);
end

end