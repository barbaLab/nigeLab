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

flag = false;
blockObj.checkActionIsValid();
blockObj.updateParams('Video');
blockObj.updateParams('Event');

[fmt,idt] = blockObj.getDescriptiveFormatting();
f = blockObj.Pars.Video.ScoringEventFieldName;
if isempty(f)
   nigeLab.utils.cprintf(fmt,'%s[DOEVENTDETECTION]: ',idt);
   nigeLab.utils.cprintf(fmt(1:(end-1)),'No scoring to be done for %s\n',...
      blockObj.Name);
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
   if ~blockObj.doEventHeaderExtraction(behaviorData,vidOffset)
      nigeLab.utils.cprintf('Errors*','\t\t->\t[DOEVENTDETECTION]: ');
      nigeLab.utils.cprintf('[0.5 0.5 0.5]*',...
         'Failed to initialize Header (%s)\n',blockObj.Name);
      return;
   end
end

% So they are not such long variable names:
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
         fname = sprintf(blockObj.Paths.(f).file, 'Trial');
         data = nigeLab.utils.initEventData(nEvent,sum(~iEventTimes),1);
         data(:,4) = ts;
         eIdx = getEventsIndex(blockObj,f,'Trial');
         blockObj.Events.(f)(eIdx).data = ...
            nigeLab.libs.DiskData('Event',fname,data,'overwrite',true);
         blockObj.Events.(f)(eIdx).signal.Samples = nEvent;
         
         % Check for the rest of "iEventTimes" files
         v = vPars.VarsToScore(iEventTimes);
         for iV = 1:numel(v)
            fname = sprintf(blockObj.Paths.(f).file, v{iV});
            eIdx = getEventsIndex(blockObj,f,v{iV});
            if exist(fname,'file')==0 % Only overwrite if nothing there
               data = nigeLab.utils.initEventData(nEvent,0,1);
               blockObj.Events.(f)(eIdx).data = ...
                  nigeLab.libs.DiskData('Event',fname,data,'overwrite',true);
               
            else
               blockObj.Events.(f)(eIdx).data = ...
                  nigeLab.libs.DiskData('Event',fname); % Make link
            end
            blockObj.Events.(f)(eIdx).signal.Samples = nEvent;
         end
      end
      % Find 'EventType' == 'auto' and create corresponding disk file
      % that is a list of times based on the 'Type' of transition
      for iE = 1:numel(ePars.Name)
         f = ePars.Fields{iE};
         if ~strcmpi(ePars.EventType.(f),'auto')
            continue; % Don't do this for 'manual' fields
         end         
         ft = ePars.EventSource{iE};
         switch ft
            case 'Streams'
               stream = blockObj.getStream(ePars.Name{iE});
            otherwise
               dbstack(); % Warn that Stims (or VidStreams) is not yet parsed automatically yet
               nigeLab.utils.cprintf('Errors*','%s[DOEVENTDETECTION]: ');
               nigeLab.utils.cprintf(fmt,...
                  'Parsing for %s (%s fieldType) not yet implemented (sorry -MM)\n',...
                  ePars.Name{iE},upper(ft));
               stream = [];
         end
         if isempty(stream)
            continue;
         end
         ts = nigeLab.utils.binaryStream2ts(stream.data,stream.fs,...
               detPars.Threshold,...
               ePars.EventDetectionType{iE},...
               detPars.Debounce);
         nEvent = numel(ts);
            
         fname = sprintf(blockObj.Paths.(f).file, ePars.Name{iE});
         
         data = nigeLab.utils.initEventData(nEvent,sum(~iEventTimes),1);
         data(:,4) = ts;
         eIdx = getEventsIndex(blockObj,f,ePars.Name{iE});
         blockObj.Events.(f)(eIdx).data = ...
            nigeLab.libs.DiskData('Event',fname,data,'overwrite',true);
         blockObj.Events.(f)(eIdx).signal.Samples = nEvent;
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
         fname = sprintf(blockObj.Paths.(f).file, v{iV});
         switch v{iV}
            case 'Trial'
               data = nigeLab.utils.initEventData(nEvent,sum(~iEventTimes),1);
               data(:,5:end) = table2array(behaviorData(:,meta));
            otherwise
               data = nigeLab.utils.initEventData(nEvent,0,1);
         end
         data(:,4) = behaviorData.(v{iV});
         eIdx = getEventsIndex(blockObj,blockObj.ScoringField,v{iV});
         blockObj.Events.(blockObj.ScoringField)(eIdx).data = ...
            nigeLab.libs.DiskData('Event',fname,data,'overwrite',true);
      end      
   otherwise
      error('Invalid number of input arguments (%g)',nargin);
end

end