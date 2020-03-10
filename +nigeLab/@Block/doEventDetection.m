function flag = doEventDetection(blockObj,behaviorData,vidOffset,forceHeaderExtraction)
% DOEVENTDETECTION  "Detects" putative Trial events
%
%  flag = doEventDetection(blockObj); 
%  --> Standard; works on scalar or array blockObj
%  
%  flag = blockObj.doEventDetection(behaviorData); 
%  --> To port old format (behaviorData table)
%  
%  flag = blockObj.doEventDetection(behaviorData,vidOffset); 
%  --> Port video offset scalar and behaviorData table
%
%  flag = doEventDetection(behaviorData,vidOffset,true);
%  --> "Force" Header extraction (forceHeaderExtraction == false default)
%
%  Returns true if event detection proceeds correctly.
%  Generates a list of timestamps for putative "Trial" behavioral events.
%  This is used if blockObj.ScoringField is not empty.

if nargin < 4
   forceHeaderExtraction = [];
end

if nargin < 3
   vidOffset = [];
end

if nargin < 2
   behaviorData = [];
end

if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      flag = flag && doEventDetection(blockObj(i),...
         behaviorData,vidOffset,forceHeaderExtraction);
   end
   return;
else
   flag = false;
end

% Check that this can be done and make shortcut to video and event params
checkActionIsValid(blockObj);
vPars = blockObj.Pars.Video;
ePars = blockObj.Pars.Event;

%
% Always extract 'Trial' first
if isempty(behaviorData)
   if ~isempty(blockObj.ScoringField)
      detPars = ePars.TrialDetectionInfo;
      fieldType = blockObj.getFieldType(detPars.Field);
      switch fieldType
         case 'Videos'
            camOpts = nigeLab.utils.initCamOpts(...
               'cview',detPars.Source);
            trial = getStream(blockObj.Videos,camOpts);
         case 'Streams'
            trial = getStream(blockObj,detPars.Name);
         otherwise
            error(['nigeLab:' mfilename ':BadType'],...
               ['Event FieldType should be either:\n' ...
               '-->''Videos'' or\n' ...
               '-->''Streams''\n'
               '\t-->(not %s)\n'],fieldType);
      end
      % Get 'Trial' times
      trial_onset_ts = nigeLab.utils.binaryStream2ts(trial.data,trial.fs,...
            detPars.Threshold,'Rising',detPars.Debounce);
      trial_offset_ts = nigeLab.utils.binaryStream2ts(trial.data,trial.fs,...
            detPars.Threshold,'Falling',detPars.Debounce);
      if numel(trial_offset_ts) < numel(trial_onset_ts)
         trial_offset_ts(end) = inf;
      elseif numel(trial_onset_ts) < numel(trial_offset_ts)
         trial_offset_ts(1) = [];
      end
      nEvent = numel(trial_onset_ts);
   end
else
   nEvent = size(behaviorData,1);
end

% Check if Header extraction needs to be done
[fmt,idt] = getDescriptiveFormatting(blockObj);
if isempty(blockObj.ScoringField)
   if blockObj.Verbose
      nigeLab.utils.cprintf(fmt,'%s[DOEVENTDETECTION]: ',idt);
      nigeLab.utils.cprintf(fmt(1:(end-1)),'No scoring to be done for %s\n',...
         blockObj.Name);
   end
   forceHeaderExtraction = false;
elseif isempty(forceHeaderExtraction)
   forceHeaderExtraction = ~any(getStatus(blockObj,blockObj.ScoringField));
end


if forceHeaderExtraction
   if isempty(behaviorData)
      arg2 = nEvent;
   else
      arg2 = behaviorData;
   end
   if ~doEventHeaderExtraction(blockObj,arg2,vidOffset,forceHeaderExtraction)
      if blockObj.Verbose
         nigeLab.utils.cprintf('Errors*','\t\t->\t[DOEVENTDETECTION]: ');
         nigeLab.utils.cprintf('[0.5 0.5 0.5]*',...
            'Failed to initialize Header (%s)\n',blockObj.Name);
      end
      return;
   end
end

if ~isempty(behaviorData) && istable(behaviorData)% Then use the provided `behaviorData` table
   iEventTimes = behaviorData.Properties.UserData <= 1;
   v = behaviorData.Properties.VariableNames(iEventTimes);
   meta = behaviorData.Properties.VariableNames(~iEventTimes);
   % Cycle through all 'EventTimes' table variables (columns) and make a
   % separate file for each of them. This will include the 'Trial'
   % event, effectively doing the 'Trial' extraction.
   for iV = 1:numel(v)
      fname = sprintf(blockObj.Paths.(blockObj.ScoringField).file, v{iV});
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
         nigeLab.libs.DiskData('Event',fname,data,'overwrite',true,...
         'Complete',zeros(1,1,'int8'));
   end   
   return; % Does not use the rest of the configured Block parsing
else
   % Otherwise, attempt to use the configured `ScoringField`
   scoringField = blockObj.ScoringField;
   if isempty(scoringField)
      if blockObj.Verbose
         fprintf(1,['\n\t\t->\t<strong>[DOEVENTDETECTION]:</strong> ' ...
            'No ScoringField configured, but `behaviorData` not given either.\n' ...
            '\t\t\t->\t(See: ~/+nigeLab/+defaults/Event.m; ' ...
            'pars.Fields and pars.EventType)\n']);
      end
      trial_onset_ts = []; % No "Trials"
      trial_offset_ts = [];
   else
      % Save 'Trial' times
      iEventTimes = vPars.VarType <= 1;
      fname = sprintf(blockObj.Paths.(scoringField).file, 'Trial');
      data = nigeLab.utils.initEventData(nEvent,sum(~iEventTimes),1);
      data(:,2) = 0;
      data(:,4) = trial_onset_ts;
      eIdx = getEventsIndex(blockObj,scoringField,'Trial');
      blockObj.Events.(scoringField)(eIdx).data = ...
         nigeLab.libs.DiskData('Event',fname,data,'overwrite',true,...
         'chunks',[1 size(data,2)],'access','w',...
         'Complete',zeros(1,1,'int8'),...
         'Index',1);
      blockObj.Events.(scoringField)(eIdx).signal.Samples = nEvent;

      % Check for the rest of "iEventTimes" files
      v = vPars.VarsToScore(iEventTimes);
      for iV = 1:numel(v)
         fname = sprintf(blockObj.Paths.(scoringField).file, v{iV});
         eIdx = getEventsIndex(blockObj,scoringField,v{iV});
         if exist(fname,'file')==0 % Only overwrite if nothing there
            data = nigeLab.utils.initEventData(nEvent,0,1);
            blockObj.Events.(scoringField)(eIdx).data = ...
               nigeLab.libs.DiskData('Event',fname,data,...
               'overwrite',true,'access','w',...
               'Complete',zeros(1,1,'int8'),'Index',1);

         else
            blockObj.Events.(scoringField)(eIdx).data = ...
               nigeLab.libs.DiskData('Event',fname,...
               'Complete',zeros(1,1,'int8')); % Make link
            sz_ = size(blockObj.Events.(scoringField)(eIdx).data);
            if sz_(2) ~= 5
               name = blockObj.Events.(scoringField)(eIdx).name;
               nigeLab.utils.cprintf('Errors*',blockObj.Verbose,...
                  '%s[DOEVENTDETECTION]: ',idt);
               nigeLab.utils.cprintf(fmt,blockObj.Verbose,...
                  '''%s'' EventData is wrong size.\n',name);
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',blockObj.Verbose,...
                  '\t%s(Re-initializing EventData)\n',idt);
               data = nigeLab.utils.initEventData(nEvent,0,1);
               blockObj.Events.(scoringField)(eIdx).data = ...
                  nigeLab.libs.DiskData('Event',fname,data,...
                  'overwrite',true,'Complete',zeros(1,1,'int8'),...
                  'access','w');
            end
         end
         blockObj.Events.(scoringField)(eIdx).signal.Samples = nEvent;
      end
   end
end

% Find 'EventType' == 'auto' and create corresponding disk file
% that is a list of times based on the 'Type' of transition
for iE = 1:numel(ePars.Name)
   curField = ePars.Fields{iE};
   if ~strcmpi(ePars.EventType.(curField),'auto')
      continue; % Don't do this for 'manual' fields
   end         
   fieldType = ePars.EventSource{iE};
   switch fieldType
      case 'Streams'
         stream = getStream(blockObj,ePars.Name{iE});
      otherwise
         if blockObj.Verbose
            dbstack(); % Warn that Stims (or VidStreams) is not yet parsed automatically yet
            nigeLab.utils.cprintf('Errors*','%s[DOEVENTDETECTION]: ');
            nigeLab.utils.cprintf(fmt,...
               'Parsing for %s (%s fieldType) not yet implemented (sorry -MM)\n',...
               ePars.Name{iE},upper(fieldType));
         end
         stream = [];
   end
   if isempty(stream)
      continue;
   end
   ts = nigeLab.utils.binaryStream2ts(stream.data,stream.fs,...
         detPars.Threshold,...
         ePars.EventDetectionType{iE},...
         detPars.Debounce);
   

   fname = sprintf(blockObj.Paths.(curField).file, ePars.Name{iE});
   eIdx = getEventsIndex(blockObj,curField,ePars.Name{iE});
   
   % If this "auto" Event is to be used as a Default for a "manual" event,
   % then for each `Trial` use the timestamp closest to the `Trial`
   % timestamp as the default for the "manual" scored time.
   targetManualEvent = ePars.UseAutoAsDefaultScoredEvent{iE};
   
   % If not configured or there are no trial times, then assign ts and
   % write data automatically; otherwise, we should pare down this list of
   % event times and use it for the `targetManualEvent` Event
   if ~isempty(targetManualEvent) && ~isempty(trial_onset_ts)
      tmp = ts;
      ts = nan(size(trial_onset_ts));
      nEvent = numel(ts);
      for iTrial = 1:nEvent
         % In event of ties, this syntax takes the first element:
         [~,tmpidx] = min(abs(tmp - trial_onset_ts(iTrial)));
         tCur = tmp(tmpidx);
         if (tCur >= trial_onset_ts(iTrial)) && (tCur <= trial_offset_ts(iTrial))
            ts(iTrial) = tCur; 
         else
            ts(iTrial) = trial_onset_ts(iTrial);
         end
      end     
      % Find the manual events index and assign these as initial times:
      mIdx = getEventsIndex(blockObj,scoringField,targetManualEvent);
      % Make sure file is unlocked for writing
      lockFlag = blockObj.Events.(scoringField)(mIdx).data.Locked;
      if lockFlag
         unlockData(blockObj.Events.(scoringField)(mIdx).data);
      end
      blockObj.Events.(scoringField)(mIdx).data.ts = ts;
      if lockFlag
         lockData(blockObj.Events.(scoringField)(mIdx).data);
      end
   else
      nEvent = numel(ts);
   end
   
   data = nigeLab.utils.initEventData(nEvent,sum(~iEventTimes),1);
   data(:,4) = ts;
   % These are parsed automatically, so it is okay to overwrite by
   % default.
   blockObj.Events.(curField)(eIdx).data = ...
      nigeLab.libs.DiskData('Event',fname,data,'overwrite',true,...
      'Complete',ones(1,1,'int8'));
   blockObj.Events.(curField)(eIdx).signal.Samples = nEvent;
   
end         


end