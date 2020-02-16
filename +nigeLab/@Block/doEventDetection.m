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
      ft = blockObj.getFieldType(detPars.Field);
      switch ft
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
               '\t-->(not %s)\n'],ft);
      end
      % Get 'Trial' times
      trial_ts = nigeLab.utils.binaryStream2ts(trial.data,trial.fs,...
            detPars.Threshold,detPars.Type,detPars.Debounce);
      nEvent = numel(trial_ts);
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

if isempty(behaviorData)
   if ~isempty(blockObj.ScoringField)
      % Save 'Trial' times
      iEventTimes = vPars.VarType <= 1;
      fname = sprintf(blockObj.Paths.(blockObj.ScoringField).file, 'Trial');
      data = nigeLab.utils.initEventData(nEvent,sum(~iEventTimes),1);
      data(:,4) = trial_ts;
      eIdx = getEventsIndex(blockObj,blockObj.ScoringField,'Trial');
      blockObj.Events.(blockObj.ScoringField)(eIdx).data = ...
         nigeLab.libs.DiskData('Event',fname,data,'overwrite',true);
      blockObj.Events.(blockObj.ScoringField)(eIdx).signal.Samples = nEvent;

      % Check for the rest of "iEventTimes" files
      v = vPars.VarsToScore(iEventTimes);
      for iV = 1:numel(v)
         fname = sprintf(blockObj.Paths.(blockObj.ScoringField).file, v{iV});
         eIdx = getEventsIndex(blockObj,blockObj.ScoringField,v{iV});
         if exist(fname,'file')==0 % Only overwrite if nothing there
            data = nigeLab.utils.initEventData(nEvent,0,1);
            blockObj.Events.(blockObj.ScoringField)(eIdx).data = ...
               nigeLab.libs.DiskData('Event',fname,data,'overwrite',true);

         else
            blockObj.Events.(blockObj.ScoringField)(eIdx).data = ...
               nigeLab.libs.DiskData('Event',fname); % Make link
            sz_ = size(blockObj.Events.(blockObj.ScoringField)(eIdx).data);
            if sz_(2) ~= 5
               name = blockObj.Events.(blockObj.ScoringField)(eIdx).name;
               nigeLab.utils.cprintf('Errors*',blockObj.Verbose,...
                  '%s[DOEVENTDETECTION]: ',idt);
               nigeLab.utils.cprintf(fmt,blockObj.Verbose,...
                  '''%s'' EventData is wrong size.\n',name);
               nigeLab.utils.cprintf('[0.55 0.55 0.55]',blockObj.Verbose,...
                  '\t%s(Re-initializing EventData)\n',idt);
               data = nigeLab.utils.initEventData(nEvent,0,1);
               blockObj.Events.(blockObj.ScoringField)(eIdx).data = ...
                  nigeLab.libs.DiskData('Event',fname,data,'overwrite',true);
            end
         end
         blockObj.Events.(blockObj.ScoringField)(eIdx).signal.Samples = nEvent;
      end
   end
   % Find 'EventType' == 'auto' and create corresponding disk file
   % that is a list of times based on the 'Type' of transition
   for iE = 1:numel(ePars.Name)
      curField = ePars.Fields{iE};
      if ~strcmpi(ePars.EventType.(curField),'auto')
         continue; % Don't do this for 'manual' fields
      end         
      ft = ePars.EventSource{iE};
      switch ft
         case 'Streams'
            stream = blockObj.getStream(ePars.Name{iE});
         otherwise
            if blockObj.Verbose
               dbstack(); % Warn that Stims (or VidStreams) is not yet parsed automatically yet
               nigeLab.utils.cprintf('Errors*','%s[DOEVENTDETECTION]: ');
               nigeLab.utils.cprintf(fmt,...
                  'Parsing for %s (%s fieldType) not yet implemented (sorry -MM)\n',...
                  ePars.Name{iE},upper(ft));
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
      nEvent = numel(ts);

      fname = sprintf(blockObj.Paths.(curField).file, ePars.Name{iE});

      data = nigeLab.utils.initEventData(nEvent,sum(~iEventTimes),1);
      data(:,4) = ts;
      eIdx = getEventsIndex(blockObj,curField,ePars.Name{iE});
      % These are parsed automatically, so it is okay to overwrite by
      % default.
      blockObj.Events.(curField)(eIdx).data = ...
         nigeLab.libs.DiskData('Event',fname,data,'overwrite',true);
      blockObj.Events.(curField)(eIdx).signal.Samples = nEvent;
   end      
else % Otherwise, behaviorData provided as Table

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
         nigeLab.libs.DiskData('Event',fname,data,'overwrite',true);
   end      
end

end