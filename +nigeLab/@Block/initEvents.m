function flag = initEvents(blockObj)
% INITEVENTS  Initialize events struct for nigeLab.Block class object
%
%  flag = INITEVENTS(blockObj);
%  --> Returns true if Events field was initialized without incident.
%  
%  This is a two-step procedure. 
%  Step-1:
%  * Parse "header-like" struct for each sub-field of .Events
%  * Add "special" 'Trial' and 'Header' fields in the case that there will
%      be manual behavior curation/scoring (check ~/+defaults/Events.m to
%      configure this part; one of the .EventType parameter struct fields
%      that corresponds to an element existing in the .Fields parameter
%      cell array should be set to 'manual' for 'Trial' and 'Header' to be
%      added, allowing manual curation).
%
%  Step-2:
%  * Once all sub-fields of .Events have been initialized, initialize any
%     Events-related matfiles that do not exist yet but which should be
%     parsed automatically.
%  * This part only applies to elements of the Events parameter .Fields
%     which correspond to a .EventType of 'auto'; the .EventDetectionType
%     specifies how the events will be automatically parsed for those
%     fields.


flag = false;
[~,ePars] = updateParams(blockObj,'Event');
updateParams(blockObj,'Video');
[uF,~,iU] = unique(ePars.Fields);
nEventTypes = numel(uF);
if nEventTypes == 0
   flag = true;
   [fmt,idt] = blockObj.getDescriptiveFormatting();
   nigeLab.utils.cprintf(fmt,'%s[INITEVENTS]: ',idt);
   nigeLab.utils.cprintf(fmt(1:(end-1)),'No ');
   nigeLab.utils.cprintf(fmt,'EVENTS ');
   nigeLab.utils.cprintf(fmt(1:(end-1)),'to initialize (%s)\n',...
      blockObj.Name);
   return;
end

% Get reduced subset of event names (removing 'manual' equivalents)
tmpf = fieldnames(ePars.EventType);
allSource = ePars.EventSource;
allField = ePars.Fields;
for ii = 1:numel(tmpf)
   if strcmp(ePars.EventType.(tmpf{ii}),'manual')
      iRm = strcmp(allSource,tmpf{ii});
      allSource(iRm) = [];
      allField(iRm) = [];
   end
end

% Initialize Events property as a struct
blockObj.Events = struct;
key = getKey(blockObj,'Public');
for ii = 1:nEventTypes
   % Find "Events" Fields that correspond to this "Field" 
   % (e.g. find all Events of 'ScoredEvents' field or 'DigEvents' field)
   idx = find(iU == ii);
   n = numel(idx);
   
   % k is just there to make it easy to understand the indexing
   k = 0;
   field_ = uF{ii};
   blockObj.Events.(field_) = nigeLab.utils.initChannelStruct('Events',n);
   % If there is a 'Scoring' type of Events, then they must be handled as
   % an exception; they will have 'Trial' and 'Header'
   eType = ePars.EventType.(field_);
   if strcmpi(eType,'auto')
      eSource = allSource(strcmp(allField,field_));
   else
      eSource = repmat({'Scoring'},n,1);
   end
   if ~isempty(blockObj.ScoringField)
      if strcmpi(field_,blockObj.ScoringField)
         % Add 'Trial' to 'ScoredEventFieldName'
         blockObj.Events.(field_) = nigeLab.utils.initChannelStruct('Events',n+2);
         k = k + 1; % k = 1
         blockObj.Events.(field_)(k).name = 'Trial'; % "special" Events name
         blockObj.Events.(field_)(k).status = false;
         detInfo = ePars.TrialDetectionInfo;
         blockObj.Events.(field_)(k).signal = nigeLab.utils.signal(...
            'Trial',[],field_,'Events',detInfo.Field,'Trial',detInfo.Name);
         blockObj.Events.(field_)(k).Key = [key '::' char(double(field_) + k)];
         
         % Add 'Header' to 'ScoringEventFieldName'
         k = k + 1; % k = 2
         blockObj.Events.(field_)(k).name = 'Header'; % "special" Events name
         blockObj.Events.(field_)(k).status = false;
         blockObj.Events.(field_)(k).signal = nigeLab.utils.signal(...
            'Header',[],field_,'Events','VideoParams','Header',eType);
         blockObj.Events.(field_)(k).Key = [key '::' char(double(field_) + k)];
         
      end
   end
   
   % k just accounts for the case that "special" 'Trial' Named Event was
   % incorporated for this Field
   
   for u = (1 + k):(n + k)
      blockObj.Events.(field_)(u).name = ePars.Name{idx(u-k)};
      blockObj.Events.(field_)(u).status = false;
      blockObj.Events.(field_)(u).signal = nigeLab.utils.signal(...
            'Standard',[],field_,'Events',eSource{u-k},...
            ePars.Name{idx(u-k)},eType);
      blockObj.Events.(field_)(u).Key = [key '::' char(double(field_) + u)];
   end
end
flag = true;
end