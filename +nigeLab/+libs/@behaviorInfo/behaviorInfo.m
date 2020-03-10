classdef behaviorInfo < matlab.mixin.SetGetExactNames
% BEHAVIORINFO  Class for behavior data tracking in manual scoring
%
%  obj = nigeLab.libs.behaviorInfo(figH,blockObj);
%  --> Builds object that tracks Block Events data and issues
%        notifications when that data is changed. This is also in
%        charge of "writing" the events data to disk files.
%
%  obj = nigeLab.libs.behaviorInfo(figH,blockObj,container);
%  --> Specifies a container (such as uipanel) to put the
%        associated graphics objects into.
   
   % % % PROPERTIES % % % % % % % % % %
   % TRANSIENT,PUBLIC/IMMUTABLE
   properties (Transient,Access=public)
      Block                            % Pointer to block object handle
      Figure                           % Pointer to figure container
      Panel                            % Pointer to nigelPanel container
   end
   
   % DEPENDENT,TRANSIENT,HIDDEN,PUBLIC (flags)
   properties (Dependent,Transient,Hidden,Access=public)
      Defaults             double            % Default values for Events
      EventTimes           double            % All "Event" Event-type DiskData variables (for all trials)
      EventNames           char              % Names of all "Event" Event-type DiskData variables
      Header               double            % Header data associated with videos/events
      Mask                 logical           % "Mask" for included/excluded trials
      Meta                 double            % All "Meta" Event-Type DiskData variables (for all trials)
      MetaNames            char              % Names of all "Meta" Event-type DiskData variables
      NScored        (1,1) double            % Total number of scored trials
      NSuccessful    (1,1) double            % Total number of trials
      NTotal         (1,1) double            % Total number of trials
      Outcome              double            % True == successful trial
      OutcomeVarName       char              % Name corresponding to "Outcome" for scoring
      SetValueFcn
      State                logical           % 1 x k vector of flags indicating that elements of Value are valid
      StringFcn                              % Function handle (from Block)
      Trial                double            % Trial timestamps
      TrialBuffer    (1,1) double            % Buffer to add or subtract to 'Trials' guesses
      TrialIndex     (1,1) double            % Index of current trial for alignment
      Type                                   % 1 x k vector of scalar indicators of Value type
      Variable                               % 1 x k label vector
      Verbose              logical           % Set true to print debug output
   end
   
   % PUBLIC
   properties(Access=public)
      Value                                  % 1 x k vector of scalar values for a single trial
      VariableIndex        double    = 1     % Current variable being updated
   end
   
   % PUBLIC/PROTECTED
   properties(GetAccess=public,SetAccess=protected)
      misc  (1,1) struct = struct % Struct for 'ad hoc' properties 
              % --> with default 'ValueShortcutFcn' property function
              %     handle, this struct gains the field 'PastPelletsValue'
              %     that keeps the last entered value for 'Pellets'
              %     metadata variable. Any subsequent trial that does not
              %     have the 'Pellets' value entered (when scoring is
              %     initiated on that trial) defaults to this value.
              %     Similar fields could be added from 'ad hoc' functions
              %     that need to store temporary variables with the
              %     behaviorInfo object.
   end
   
   % PROTECTED
   properties(Access=protected)
      ScoringID           % hash string to track progress in metadata table
      ScoringField
   end
   
   % TRANSIENT,PUBLIC/PROTECTED (graphics objects)
   properties(Transient,GetAccess=public,SetAccess=protected)
      IndicatorPanel             % Panel indicating progress, # successful
      IndicatorAxes              % Axes container for Label graphics
      MouseRollover              % Object that tracks mouse-over on buttons
      ProgressLabel              % Label to keep track of scoring completion
      SuccessIndicatorLabel      % Label to keep track of total # successful
      TimeAxes                   % nigeLab.libs.TimeScrollerAxes
      TrialButtonArray           % Array of buttons that indicates progress 
      TrialButtonAxes            % Axes for indicator button array 
      TrialLabel                 % Label to keep track of current trial index
      TrialPopupMenu             % Popupmenu for selecting trial
      ValuesDisplayArray         % Array of handles to edit boxes
      ValuesPanel             	% Panel for holding controls
      VidGraphics                % Object for handling video graphics
   end
   
   % TRANSIENT,HIDDEN,PUBLIC
   properties(Transient,Hidden,Access=public)
      ValueLabels       % uicontrol array
   end
   
   % TRANSIENT,HIDDEN,PROTECTED
   properties(Transient,Hidden,Access=protected)
      NeedsSave   (1,1) logical = false
      NeedsLabels (1,1) logical = true
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % RESTRICTED:{nigeLab.Block,nigeLab.nigelObj} (constructor)
   methods (Access={?nigeLab.Block,?nigeLab.nigelObj,?nigelab.libs.VidGraphics})
      % Construct the behaviorInfo object
      function obj = behaviorInfo(blockObj,nigelPanelObj,vidGraphicsObj)
         % BEHAVIORINFO  Class for behavior data tracking in manual scoring
         %
         %  obj = nigeLab.libs.behaviorInfo(blockObj);
         %  --> Builds object that tracks Block Events data and issues
         %        notifications when that data is changed. This is also in
         %        charge of "writing" the events data to disk files.
         %
         %  obj = nigeLab.libs.behaviorInfo(blockObj,nigelPanelObj);
         %  --> Specifies a nigelPanel to put the behaviorInfo-associated
         %        graphics into.
         %
         %  obj = nigeLab.libs.behaviorInfo(__,timeAxesObj);
         %  --> Specifies Time Axes as part of the constructor, so it does
         %  not need to be added later with a separate method call.
         
         % Allow empty constructor etc.
         if nargin < 1
            obj = nigeLab.libs.behaviorInfo.empty();
            return;
         elseif isnumeric(blockObj)
            dims = blockObj;
            if numel(dims) < 2 
               dims = [zeros(1,2-numel(dims)),dims];
            end
            obj = repmat(obj,dims);
            return;
         end
         
         % Otherwise, require that first input is nigeLab.Block
         if ~isa(blockObj,'nigeLab.Block')
            error(['nigeLab:' mfilename ':BadClass'],...
               'First input argument must be class nigeLab.Block');
         end
         obj.Block = blockObj;
         obj.ScoringField = blockObj.ScoringField;
         
         % If no "container" given, then make it in its own figure
         % (modular)
         if nargin < 2
            fig = figure('Name','BehaviorInfo',...
               'NumberTitle','off',...
               'Color',nigeLab.defaults.nigelColors('background'),...
               'Units','Normalized',...
               'Position',[0.6 0.1 0.3 0.8]);
            nigelPanelObj = nigeLab.libs.nigelPanel(fig,...
               'Units','Normalized',...
               'Position',[0 0 1 1],...
               'Scrollable','off',...
               'Tag','behaviorInfo');
         end
         obj.Panel = nigelPanelObj;   
         obj.Figure = obj.Panel.Parent;
         
         % Initialize obj.Value property
         obj.Value = getTrialData(obj,obj.TrialIndex);   
         iPell = find(obj.Type==2,1,'first');
         obj.misc.PrevPelletValue = obj.Value(iPell);
         setScoringMetadata(obj); % initializes ScoringID as well
         
         % Add `TimeScrollerAxes` or `VidGraphics` object if given
         if nargin > 2
            switch class(vidGraphicsObj)
               case 'nigeLab.libs.VidGraphics'
                  addVidGraphics(obj,vidGraphicsObj);
               case 'nigeLab.libs.TimeScrollerAxes'
                  addTimeAxes(obj,vidGraphicsObj);
            end
         end 
         
         buildValuePanel(obj);
         buildProgressTracker(obj);
         
         if nargin > 2
            if obj.TimeAxes.ZoomLevel == 0
               ts = obj.Trial + obj.VidGraphics.NeuOffset;
               setTimeStamps(obj.TimeAxes,ts,'off');
               obj.NeedsLabels = true;
            else
               ts = obj.EventTimes(obj.TrialIndex,:) + obj.VidGraphics.NeuOffset;
               setTimeStamps(obj.TimeAxes,ts,'on',obj.EventNames{:});
               obj.NeedsLabels = false;
            end
         end
         
         % Move to correct trial
         setTrial(obj,obj.VidGraphics,obj.TrialIndex);           
      end
      
      % Add 'TimeScrollerAxes' object to behaviorInfo object
      function addTimeAxes(obj,timeAxesObj)
         %ADDTIMEAXES  Add (existing) 'TimeScrollerAxes' object
         %
         %  addTimeAxes(obj,timeAxesObj);
         %
         %  obj :          nigeLab.libs.behaviorInfo object
         %  timeAxesObj :  nigeLab.libs.TimeScrollerAxes object
         
         obj.TimeAxes = timeAxesObj;
         addBehaviorInfoObj(timeAxesObj,obj);
         addDigStreams(timeAxesObj,obj.Block.TrialField);
      end
      
      % Add 'VidGraphics' object to behaviorInfo object
      function addVidGraphics(obj,vidGraphicsObj)
         %ADDVIDGRAPHICS  Add (existing) 'VidGraphics' object
         %
         %  addVidGraphics(obj,vidGraphicsObj);
         %
         %  obj :                nigeLab.libs.behaviorInfo object
         %  vidGraphicsObj :     nigeLab.libs.VidGraphics object
         
         obj.VidGraphics = vidGraphicsObj;
         addTimeAxes(obj,vidGraphicsObj.TimeAxes);
      end
   end
   
   % NO ATTRIBUTES (overloaded methods)
   methods 
      % [DEPENDENT]  Default values for Events
      function value = get.Defaults(obj)
         %GET.DEFAULTS  Returns default values for Events
         %
         %  get(obj,'Default');
         %  --> Returns values configured in +defaults/Video.m `defPars`
         
         value = obj.Block.Pars.Video.VarDefs;
      end
      function set.Defaults(obj,value)
         %SET.DEFAULTS  Sets default values for Events
         %
         %  set(obj,'Defaults',value);
         
         if numel(value) == numel(obj.Block.Pars.Video.VarDefs)
            obj.Block.Pars.Video.VarDefs = value;
         else
            warning(['nigeLab:' mfilename ':BadSize'],...
               'Tried to set VarDefs (%g elements) with value of wrong size (%g elements)',...
               numel(obj.Block.Pars.Video.VarDefs),numel(value));
         end
      end
      
      % [DEPENDENT]  Handles .EventTimes (from DiskData; wrt NEURAL rec)
      function value = get.EventTimes(obj)
         %GET.EVENTTIMES  Returns .EventTimes property
         %
         %  value = get(obj,'EventTimes');
         
         v = obj.Variable(obj.Type == 1);
         value = nan(numel(obj.Trial),numel(v));
         f = obj.ScoringField;
         for iV = 1:numel(v)
            value(:,iV) = getEventData(obj.Block,f,'ts',v{iV});
         end
      end
      function set.EventTimes(obj,~)
         %SET.EVENTTIMES  Assigns .EventTimes property
         %
         %  set(obj,'EventTimes',__);
         %  --> Uses values stored (transiently) in obj.Value
         
         idx = obj.Type == 1;
         v = obj.Variable(idx);         
         val = obj.Value(idx);
         f = obj.ScoringField;
         for iV = 1:numel(v)
            setEventData(obj.Block,f,...
               'ts',v{iV},val(iV),obj.TrialIndex);
            useTimestamp = double((~isnan(val(iV))) && (~isinf(val(iV))));
            [flag,idx] = setEventData(obj.Block,f,...
               'tag',v{iV},useTimestamp,obj.TrialIndex);
            if flag
               % Update files to reflect "last-scored" element
               obj.Block.Events.(f)(idx).data.Index = obj.TrialIndex;
               updateEventTimeCompletionStatus(obj,idx);               
            end
         end
      end
      
      % [DEPENDENT]  Returns .EventNames property
      function value = get.EventNames(obj)
         %GET.EVENTNAMES  Returns .EventNames property
         %
         %  value = get(obj,'EventNames');
         %  --> Return all 'timestamp' event names (e.g. reach, grasp etc)
         
         idx = obj.Type == 1;
         value = obj.Variable(idx); 
      end
      function set.EventNames(obj,value)
         % SET.EVENTNAMES  Sets subset of variables of 'EventTime' type
         %
         %  set(obj,'EventNames',value);
         idx = obj.Type == 1;
         obj.Variable(idx) = value;
      end

      % [DEPENDENT]  Returns .Header property
      function value = get.Header(obj)
         %GET.HEADER  Returns .EventTimes property
         %
         %  value = get(obj,'Header');
         
         value = obj.Block.VideoHeader;
      end
      function set.Header(obj,value)
         %SET.HEADER  Assigns .Header property
         obj.Block.VideoHeader = value;
      end
      
      % [DEPENDENT]  Returns .Mask property
      function value = get.Mask(obj)
         %GET.Mask  Returns .Mask property
         %
         %  value = get(obj,'Mask');
         
         value = obj.Block.TrialMask;
      end
      function set.Mask(obj,value)
         %SET.Mask  Assigns .Mask property
         %
         %  set(obj,'Mask',value);
         
         obj.Block.TrialMask = value;
      end
      
      % [DEPENDENT]  Returns .Meta property
      function value = get.Meta(obj)
         %GET.META  Returns .EventTimes property
         %
         %  value = get(obj,'Meta');
         
         f = obj.ScoringField;
         value = getEventData(obj.Block,f,'snippet','Trial');
      end
      function set.Meta(obj,~)
         %SET.META  Assigns .Meta property
         %
         %  set(obj,'Meta',_);
         %  --> Uses values stored (transiently) in obj.Value
         
         idx = obj.Type > 1;       
         val = obj.Value(idx);
         f = obj.ScoringField;
         flag = setEventData(obj.Block,f,'snippet','Trial',val,...
            obj.TrialIndex,1:numel(val));
         % Do not update .Index because it is already associated with
         % obj.Block, which is what generates obj.TrialIndex
         
         if flag
            updateMetaCompletionStatus(obj);
         end
      end
      
      % [DEPENDENT]  Returns .MetaNames property
      function value = get.MetaNames(obj)
         %GET.METANAMES  Returns .MetaNames property
         %
         %  value = get(obj,'MetaNames');
         %  --> Return all 'qualitative' names (e.g. NumPellets, Outcome)
         
         idx = obj.Type > 1;
         value = obj.Variable(idx); 
      end
      function set.MetaNames(obj,value)
         % SET.METANAMES  Assigns .MetaNames property
         
         idx = obj.Type > 1;
         obj.Variable(idx) = value; 
      end
      
      % [DEPENDENT]  Returns .Outcome property
      function value = get.Outcome(obj)
         %GET.Outcome  Returns .EventTimes property
         %
         %  value = get(obj,'Outcome');
         
         vName = obj.Variable(obj.Type > 1);
         iOut = strcmpi(vName,obj.OutcomeVarName);
         if sum(iOut)~=1
            warning(['nigeLab:' mfilename ':BadConfig'],...
               ['No matching Meta variable: <strong>%s</strong>\n' ...
               '\t->\t(May need to check ~/+defaults/Events.m\n'],...
               obj.OutcomeVarName);
            value = false;
            return;
         end
         
         value = obj.Meta(:,iOut);
         value(isnan(value)) = false;
      end
      function set.Outcome(obj,value)
         %SET.Outcome  Assigns obj.Outcome 
         %
         %  set(obj,'Outcome',value);

         vName = obj.Variable(obj.Type > 1);
         iOut = strcmpi(vName,obj.OutcomeVarName);
         if sum(iOut)~=1
            warning(['nigeLab:' mfilename ':BadConfig'],...
               ['No matching Meta variable: <strong>%s</strong>\n' ...
               '\t->\t(May need to check ~/+defaults/Events.m\n'],...
               obj.OutcomeVarName);
            return;
         end
         obj.Meta(:,iOut) = value;
         refreshGraphics(obj);
      end
      
      % [DEPENDENT]  Returns .OutcomeVarName property
      function value = get.OutcomeVarName(obj)
         %GET.OutcomeVarName  Returns .OutcomeVarName property
         %
         %  value = get(obj,'OutcomeVarName');
         
         value = obj.Block.Pars.Video.OutcomeEvent;
      end
      function set.OutcomeVarName(obj,value)
         %SET.OutcomeVarName  Updates obj.Block.Pars.Event.OutcomeVarName
         obj.Block.Pars.Video.OutcomeEvent = value;
      end
      
      % [DEPENDENT]  Returns .NScored property (number of trials scored)
      function value = get.NScored(obj)
         %GET.NSCORED  Returns .NScored property (# of trials scored)
         %
         %  value = get(obj,'NScored');
         
         value = sum(obj.State | (~obj.Mask));
      end
      function set.NScored(~,~)
         % SET.NSCORED  Does nothing
      end 
      
      % [DEPENDENT]  Returns .NSuccessful property (number of trials)
      function value = get.NSuccessful(obj)
         %GET.NSUCCESSFUL  Returns .NSuccessful property (# of trials)
         %
         %  value = get(obj,'NSuccessful');
         
         value = nansum(obj.Outcome);
      end
      function set.NSuccessful(~,~)
         % SET.NSUCCESSFUL  Does nothing
      end 
      
      % [DEPENDENT]  Returns .NTotal property (number of trials)
      function value = get.NTotal(obj)
         %GET.NTotal  Returns .NTotal property (# of trials)
         %
         %  value = get(obj,'NTotal');
         
         value = numel(obj.Trial);
         % Don't want to divide by zero or something
         if value == 0
            value = 1;
            if obj.Verbose
               warning(['nigeLab:' mfilename 'BadTrialsInit'],...
                  'No Trials detected. Is this correct?');
            end
         end
      end
      function set.NTotal(~,~)
         % SET.NTotal  Does nothing
      end  
      
      % [DEPENDENT]  Returns .SetValueFcn (from .Block)
      function value = get.SetValueFcn(obj)
         %GET.SETVALUEFCN  Returns handle to function for setting .Value
         %
         %  value = get(obj,'SetValueFcn');
         
         value = obj.Block.Pars.Video.ValueShortcutFcn;
      end
      function set.SetValueFcn(~,~)
         %SET.SETVALUEFCN  Does nothing
      end
      
      % [DEPENDENT]  Returns .State property (from linked .Value)
      function value = get.State(obj)
         %GET.STATE  Returns .State property (if false, suppress text)
         %
         %  value = get(obj,'Verbose');
         %  --> Returns equivalent to ~isnan(obj.Value)
         
         value = ~any(isnan(getFullDataArray(obj)),2);
      end
      function set.State(~,~)
         %SET.STATE  Does nothing
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[BEHAVIORINFO.SET]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set READ-ONLY property: State\n');
         fprintf(1,'\n');
      end
      
      % [DEPENDENT]  Returns .StringFcn property (from linked .Block)
      function value = get.StringFcn(obj)
         %GET.STRINGFCN  Returns .StringFcn property 
         %
         %  value = get(obj,'StringFcn');
         %  --> Returns equivalent to
         %  obj.Block.Pars.Video.VideoScoringStringsFcn

         value = obj.Block.Pars.Video.VideoScoringStringsFcn;
      end
      function set.StringFcn(~,~)
         %SET.STRINGFCN  Does nothing
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[BEHAVIORINFO.SET]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set READ-ONLY property: StringFcn\n');
         fprintf(1,'\n');
      end
      
      % [DEPENDENT]  Returns putative Trial times
      function value = get.Trial(obj)
         % GET.TRIAL  Returns column vector of putative trial times (seconds)
         %
         %  ts = obj.Trial; Returns all values of Trial
         %  ts = obj.Trial(trialIdx); Returns indexed values of Trial
         %  obj.Trial(trialIdx,val);  Sets indexed values of Trial

         value = obj.Block.Trial;

      end
      function set.Trial(obj,value)
         %SET.TRIAL  Assigns putative Trial timestamps
         %
         %  set(obj,'Trial',value);
         %  --> Update list of candidate Trial timestamps

         obj.Block.Trial = value;
      end
      
      % [DEPENDENT]  Returns current trial index
      function value = get.TrialIndex(obj)
         %GET.TRIALINDEX  Returns value stored in .TrialIndex_
         %
         %  value = get(obj,'TrialIndex');
         %  --> Simply return value in protected .TrialIndex_ property
         
         value = obj.Block.TrialIndex; 
      end
      function set.TrialIndex(obj,value)
         %SET.TRIALINDEX  Sets trial popup box value to ensure match
         
         % In case .TrialIndex set from outside callback of listbox
         if obj.TrialPopupMenu.Value ~= value
            obj.TrialPopupMenu.Value = value;
         end
         
         if isempty(obj.Block)
            return;
         end
         
         if value == obj.Block.TrialIndex
            return; % Do not update
         end
         obj.Block.TrialIndex = value;
         refreshGraphics(obj,value);
      end
      
      % [DEPENDENT]  Returns .TrialBuffer property (from .Block.Pars)
      function value = get.TrialBuffer(obj)
         %GET.TRIALBUFFER  Returns value from .Block.Pars
         %
         %  value = get(obj,'TrialBuffer');
         %  --> Simply return value of obj.Block.Pars.Video.TrialBuffer
         
         value = obj.Block.Pars.Video.PreTrialBuffer; 
      end
      function set.TrialBuffer(obj,value)
         %SET.TRIALBUFFER  Assign to block parameter
         obj.Block.Pars.Video.PreTrialBuffer = value;
      end
      
      % [DEPENDENT]  Returns .Type property (indexes "type" of .Variable)
      function value = get.Type(obj)
         % GET.TYPE  Returns column vector of putative trial times (seconds)
         %
         %  ts = obj.Trial; Returns all values of Trial
         %  ts = obj.Trial(trialIdx); Returns indexed values of Trial
         %  obj.Trial(trialIdx,val);  Sets indexed values of Trial
         
         value = [];         
         if isempty(obj.Block)
            return;
         end
         value = obj.Block.Pars.Video.VarType;

      end
      function set.Type(obj,value)
         %SET.TYPE  Assigns .Type to current .Video
         obj.VidGraphics.Video.VarType = value;
      end
      
      % [DEPENDENT]  Returns .Variable property (names of .Value elements)
      function value = get.Variable(obj)
         % GET.VARIABLE  Returns column vector of putative trial times (seconds)
         %
         %  value = get(obj,'Variable');
         %  --> Returns cell array corresponding to each element of .Value
         
         value = obj.Block.Pars.Video.VarsToScore;
      end
      function set.Variable(obj,value)
         %SET.VARIABLE Assigns value to obj.Block.Pars.Video.VarsToScore
         
         obj.Block.Pars.Video.VarsToScore = value;
      end
      
      % [DEPENDENT]  Returns .Verbose property (from linked Block)
      function value = get.Verbose(obj)
         %GET.VERBOSE  Returns .Verbose property (if false, suppress text)
         %
         %  value = get(obj,'Verbose');
         %  --> Returns value of obj.Block.Verbose
         
         value = false;
         if isempty(obj.Block)
            return;
         end
         value = obj.Block.Verbose;
      end
      function set.Verbose(~,~)
         %SET.VERBOSE  Does nothing
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[BEHAVIORINFO.SET]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set READ-ONLY property: Verbose\n');
         fprintf(1,'\n');
      end
      
      % Overloaded `delete` method to "clean-up" related scoring
      function delete(obj)
         %DELETE  Overload to "clean-up" any related scoring
         
         if obj.NeedsSave % Prompt for save if necessary
            str = questdlg('Save scoring?','Save Scoring?',...
               'Yes','No','Yes');
            if strcmp(str,'Yes')
               saveScoring(obj);
            end
         end
         
         if ~isempty(obj.Block)
            if isvalid(obj.Block)
               % Remove any rows where Toc == 0 (never saved)
               clearScoringMetadata(obj.Block,'Video');
            end
         end
         
         % Destroy Rollover object
         if ~isempty(obj.MouseRollover)
            if isvalid(obj.MouseRollover)
               delete(obj.MouseRollover);
            end
         end
      end
   end
   
   % PUBLIC
   methods (Access=public)  
      % Assigns value to a particular variable (does not use .SetValueFcn)
      function assignValue(obj,name,value)
         %ASSIGNVALUE  Assigns value to a particular variable
         %
         %  assignValue(obj,name,value);
         %
         %  obj : nigeLab.libs.behaviorInfo object
         %  name : Char array, name of variable to assign
         %  value : Value (numeric) to assign
         
         idx = findVariable(obj,name);
         if isempty(idx)
            return;
         end
         obj.Value(idx) = value;
         iTS = obj.Type(idx)==1;
         v = obj.Variable(iTS);
         if ~isempty(obj.TimeAxes) && ~isempty(v)
            val = value(iTS) + obj.VidGraphics.NeuOffset ...
               - obj.VidGraphics.VideoOffset - obj.VidGraphics.TrialOffset;
            updateEventTime(obj.TimeAxes,v,val);
         end
      end
      
      % Returns data for current trial AND updates obj.Value
      function data = getTrialData(obj,curTrial)
         % GETCURRENTTRIALDATA  Return single-trial data from DiskData 
         %
         %  data = getTrialData(obj);
         %  --> Gets row vector for this trial (curTrial = obj.TrialIndex)
         %
         %  data = getTrialData(obj,curTrial);
         %  --> Override default (obj.TrialIndex) value for curTrial
         
         if nargin < 2
            curTrial = obj.TrialIndex;
         end
         
         data = nan(1,numel(obj.Type));
         data(1,obj.Type == 1) = obj.EventTimes(curTrial,:);
         data(1,obj.Type >  1) = obj.Meta(curTrial,:);
      end
      
      % Returns current var type (either: 'EventTimes' or 'Meta')
      function type = getCurVarType(obj)
         % GETCURVARTYPE  Returns either 'EventTimes' or 'Meta' depending
         %                on current variable index.
         %
         %  type = getCurVarType(obj);  
         %  --> Returns 'EventTimes' or 'Meta' (translates based on .Type)
         
         vt = obj.Type(obj.VariableIndex);
         if vt > 1
            type = 'Meta';
         else
            type = 'EventTimes';
         end
      end
      
      % Returns the full data array with all EventTimes and Meta entries
      function data = getFullDataArray(obj)
         % GETFULLDATAARRAY Return full data array with all EventTimes and
         %                  Meta entries for every Trial in the record.
         %
         %  data = obj.getFullDataArray;  Each column is a variable, each
         %                                row is a trial. The first columns
         %                                are obj.EventTimes, second set of
         %                                columns is obj.Meta.
         
         data = [obj.EventTimes, obj.Meta];
      end
      
      % Get the associated value in the .Value buffer
      function value = getValue(obj,variableName)
         %GETVALUE  Returns value associated with `variableName`
         %
         %  value = getValue(obj,variableName);
         idx = strcmpi(obj.Variable,variableName);
         if sum(idx) == 1
            value = obj.Value(idx);
         elseif sum(idx) > 1
            value = [];
            warning(['nigeLab:' mfilename ':BadName'],...
               'Variable name ''%s'' is case-ambiguous\n',variableName);
         else
            value = [];
            warning(['nigeLab:' mfilename ':BadName'],...
               'Could not find variable named ''%s''\n',variableName);
         end
      end
         
      % Gets the index for a particular variable or array from .Variable
      function index = findVariable(obj,variableName)
         % FINDVARIABLE  Matches Variable to elements of obj.Variable
         %
         %  index = obj.FINDVARIABLE('variableName');
         
         if iscell(variableName)
            index = nan(1,numel(variableName));
            for i = 1:numel(variableName)
               % Make sure they are matched respectively to elements of
               % variableName
               tmp = find(ismember(obj.Variable,variableName),1,'first');
               if ~isempty(tmp)
                  index(i) = tmp;
               end
            end
         else
            index = find(ismember(obj.Variable,variableName),1,'first');
            if isempty(index)
               index = nan;
            end
         end
      end
      
      % Update the tracker image by reflecting scoring "state" using color
      function refreshGraphics(obj,curTrial)
         %REFRESHGRAPHICS  Refresh all graphics for behaviorInfo object
         %
         %  refreshGraphics(obj);
         %  --> Parses curTrial from obj.TrialIndex;
         %
         %  refreshGraphics(obj,curTrial);
         
         if nargin < 2
            curTrial = obj.TrialIndex;
         end
         updateObjLabels(obj,1:numel(obj.Variable)); % Updates label strings to correct values
         updateObjColors(obj,curTrial); % Updates con panel, tracker background
         if ~isempty(obj.TimeAxes)
            updateTimeAxesIndicators(obj);
         end
         if ~isempty(obj.VidGraphics)
            set(obj.VidGraphics.TrialOffsetLabel,'String',...
               sprintf('Trial Offset: %6.3f sec ||  FPS: %6.2 Hz',...
               obj.VidGraphics.TrialOffset,obj.VidGraphics.FPS));
         end
      end
      
      % Toggle mask status for this trial
      function toggleTrialMask(obj,state)
         % TOGGLETRIALMASK  Remove a trial entry
         %
         %  removeTrial(obj); Removes current trial from the array
         
         if nargin < 2
            state = 1 - obj.Mask(obj.TrialIndex);
         end
         
         % Toggle Mask based on current state
         obj.Mask(obj.TrialIndex) = state;
         if state==0
            obj.TrialButtonArray(obj.TrialIndex).Enable = 'off';
         else
            obj.TrialButtonArray(obj.TrialIndex).Enable = 'on';
         end
         
         updateMetaCompletionStatus(obj);
         updateEventTimeCompletionStatus(obj);
         
         % Update graphics of this trial
         refreshGraphics(obj,obj.TrialIndex);
         
         if state == 0 % If trial was removed, go to next
            % Increment trial if possible without going over
            iCapped = min(obj.TrialIndex+1,obj.NTotal);         

            if obj.TrialIndex == iCapped   % Then we didn't move
               return;
            else % Otherwise, update TrialIndex and get new data
               setTrial(obj,obj.VidGraphics,iCapped);
            end
         end % Otherwise trial was enabled: stay on this trial
      end
      
      % Save blockObj with scoring
      function saveScoring(obj)
         % SAVESCORING  Save behaviorInfo.Block object with scoring data
         %
         %  obj.saveScoring;  Save the Block object. Even without saving
         %                    the Block object, the Events files should be
         %                    updated when a change is made. This part
         %                    basically updates the Scoring metadata and 
         if ~obj.Verbose
            fprintf(1,'saving...\n');
         end
         setCurrentTrialData(obj);
         info = getScoringMetadata(obj.Block,'Video',obj.ScoringID);
         info.Toc(1) = info.Toc(1) + toc(info.Tic(1));
         info.Tic(1) = tic;
         info.Status{1} = checkProgress(obj);
         setScoringMetadata(obj,info);
         save(obj.Block);    
         nigeLab.sounds.play('camera',2.25,-50);
         if ~obj.Verbose
            fprintf(1,'\b\b\b\b\b\b\b\b\b\b');
         end
      end
      
      % Save the trial timestamp data from the current trial
      function setCurrentTrialData(obj)
         % SETCURRENTTRIALDATA  Save array for current trial
         %
         %  setCurrentTrialData(obj);  Write data for this trial to the
         %                             'Event'-type DiskData associated
         %                             with obj.Block
         
         set(obj,'EventTimes',[]);
         set(obj,'Meta',[]);
         obj.NeedsSave = false;
      end
      
      % Update ID of person scoring
      function setScoringMetadata(obj,info)
         % SETSCORINGMETADATA  Set hash string for session scoring tracker
         %
         %  obj.setScoringMetadata();  Initializes a new row in session
         %                             scoring tracker; or, if one exists
         %                             for this particular day and user
         %                             combination, gets the hash for that
         %                             row entry and updates its data.
         %
         %  obj.setScoringMetadata(info); Sets metadata using table row
         %                                "info". For
         %                                nigeLab.libs.behaviorInfo, "info"
         %                                has the variables:
         %                            {'User','Date','Status','Tic','Toc'}
         
         if nargin < 2
            info = getScoringMetadata(obj.Block,'Video');
            if isempty(info)
               obj.ScoringID = nigeLab.utils.makeHash();
               todays_date = nigeLab.utils.getNigelDate();
               user = obj.Block.User;
               prog = checkProgress(obj);
               info = table({user},{todays_date},{prog},tic,0,...
                  'VariableNames',{'User','Date','Status','Tic','Toc'},...
                  'RowNames',obj.ScoringID);    
            else
               obj.ScoringID = info.Properties.RowNames;
               info.Tic(1) = tic;
            end
         end
         addScoringMetadata(obj.Block,'Video',info);
      end
      
      % Set the current trial button and emit notification about the event
      function setTrial(obj,src,newTrialIndex)
         % SETTRIAL  Set the current trial, notify about this event
         %
         %  set(uicontrolObj,'Callback',@setTrial);
         %  or
         %  obj.setTrial(nan,trialIndex);
         %  obj.setTrial(nan,trialIndex,forceReset); 
         %
         %  inputs:
         %  src  --  A uicontrol object. If method is accessed directly as
         %              a non-callback, then set this to NaN.
         %  newTrialIndex  --  Trial index to set the trial to.
         %  reset  --  If true, then forces graphics fields to reset even
         %              if value of newTrialIndex is the same as the previous
         %              trial index.
         
         % Give option of sending in a uiControl object and getting value
         % for the new trial
         if isa(src,'matlab.ui.control.UIControl')
            newTrialIndex = src.Value;
         end
         
         % Do not update if not needed or out-of-bounds
         if (newTrialIndex < 1) || (newTrialIndex > obj.NTotal) || (newTrialIndex == obj.TrialIndex) && ...
               ~isa(src,'nigeLab.libs.VidGraphics')
            return;
         end

         % Write "buffered" data to diskfile before advancing
         setCurrentTrialData(obj);
         
         % Remove "selected" highlight from old button
         obj.TrialButtonArray(obj.TrialIndex).Selected = 'off';
         obj.TrialIndex = newTrialIndex;
         
         % Add "selected" highlight to new button
         if strcmp(obj.TrialButtonArray(newTrialIndex).Selected,'off')
            obj.TrialButtonArray(newTrialIndex).Selected = 'on';
            obj.Figure.WindowButtonUpFcn = [];
         end
         
         % Update NEW trial data from diskfile
         obj.Value = getTrialData(obj,newTrialIndex);
         
         % Update video time if needed
         updateVidGraphicsTime(obj);
         
         % Update graphics to reflect new trials
         refreshGraphics(obj,newTrialIndex);
         obj.VariableIndex = 1; % Reset to initial value
      end
      
      % Set the associated value in the .Value buffer & on graphics
      function setValue(obj,variableName,newValue,curTrial)
         % SETVALUE  Parse different inputs to allow handling of exceptions
         %           based on variable type indexing.
         %
         %  variableName : Name of variable to set
         %  newValue : Value(s) to update obj.Value
         %  curTrial : (optional) Trial index to update
         
         if nargin < 4
            curTrial = obj.TrialIndex;
         end
         varIdx = findVariable(obj,variableName);
         if isempty(varIdx)
            if iscell(variableName)
               warning(['nigeLab:' mfilename ':BadVarName'],...
                  'No valid variable: %s\n',variableName{:});
            else
               warning(['nigeLab:' mfilename ':BadVarName'],...
                  'No valid variable: %s\n',variableName);
            end
            return;
         end
         % Note that instead of making a direct assignment here, the
         % ValueShortcutFcn is used instead so that it is possible to set
         % up flexible "shortcut" scoring heuristics. 
         % 
         % For example, if there was no Reach on the behavioral trial (e.g.
         % just a nose poke), then there CANNOT be a Grasp. So we can
         % create things where if there is a certain value for one
         % variable, we automatically update the other variables to reflect
         % that. This heuristic is customized in
         % Block.Pars.Video.ValueShortcutFcn.
         %  * See: 
         %
         %     ~/+nigeLab/+workflow/defaultVideoScoringShortcutFcn.m 
         %
         %     for example of how this is set up in practice.
         obj.SetValueFcn(obj,varIdx,newValue);
         refreshGraphics(obj,curTrial);
         obj.NeedsSave = true;
      end
      
      % Set values of this variable for ALL trials
      function setValueAll(obj,variableName,newValue)
         % SETVALUEALL  Set all associated values of behavior
         %
         %  obj.setValueAll(varName,val);
         %  
         %  variableName  -- Name of variable to set.
         %  newValue  --  New values to update obj.Value (the current trial's
         %              values for each variable to be scored).
         
         obj.VariableIndex = findVariable(obj,variableName);
         
         % Only do "update all" for metadata variables, not timestamps
         if strcmpi(getCurVarType(obj),'EventTimes')
            return;
         end
         obj.Value(obj.VariableIndex) = newValue;
         
         var = obj.Variable(obj.Type > 1);
         colIdx = find(strcmp(var,variableName),1,'first');
         newValue = repmat(newValue,obj.NTotal,1);
         f = obj.ScoringField;
         setEventData(obj.Block,f,'snippet','Trial',newValue,':',colIdx);

         refreshGraphics(obj,obj.TrialIndex);
         obj.NeedsSave = true;
      end
      
      % Store "miscellaneous" data as fields of .misc
      function storeMiscData(obj,miscFieldName,value)
         %STOREMISCDATA  Store "miscellaneous" data as fields of .misc
         %
         %  storeMiscData(obj,miscFieldName,value);
         %  e.g.
         %  >> storeMiscData(obj,'PrevPelletValue',8);
         %   
         %  Does not do error-checking on field-name and value.
         
         obj.misc.(miscFieldName) = value;
      end
      
      % Updates 'EventTimes' DiskFile .Complete attribute
      function updateEventTimeCompletionStatus(obj,idx)
         %UPDATEEVENTTIMECOMPLETIONSTATUS  Updates 'EventTimes' DiskFile 
         %
         %  updateEventTimeCompletionStatus(obj,idx);
         
         f = obj.ScoringField;
         
         if nargin < 2
            idx = 3:numel(obj.Block.Events.(f));
         end
         
         mask = obj.Block.TrialMask;
         for ii = 1:numel(idx)
            isComplete = ~isnan(obj.Block.Events.(f)(idx(ii)).data.ts(mask));
            obj.Block.Events.(f)(idx(ii)).data.Complete = all(isComplete);
         end
         
      end
      
      % Updates 'Meta' completion status
      function updateMetaCompletionStatus(obj)
         %UPDATEMETACOMPLETIONSTATUS  Updates 'Meta' completion status
         %
         %  updateMetaCompletionStatus(obj);
         
         f = obj.ScoringField;
         m = obj.Mask;
         varsComplete = all(~isnan(obj.Meta(m>0,:)),1);
         idx = getEventsIndex(obj.Block,f,'Trial');
         obj.Block.Events.(f)(idx).data.Complete = all(varsComplete);
      end
      
      % Update indicators on TimeAxes
      function updateTimeAxesIndicators(obj)
         %UPDATETIMEAXESINDICATORS  Update indicators on TimeAxes
         %
         %  updateTimeAxesIndicators(obj,curTrial);
         %  
         %  obj : behaviorInfo object
         %  curTrial  : (Optional) current trial index (if not given, uses
         %               obj.TrialIndex)
         %
         %  This updates the locations of 'Grasp', 'Reach', etc. indicators
         %  on the 'TimeScroller' Axes
         
         tOff = obj.Block.TrialVideoOffset(obj.Block.VideoIndex,:).';
         if obj.TimeAxes.ZoomLevel == 0
            ts = obj.Trial - tOff + obj.VidGraphics.NeuOffset;
            setTimeStamps(obj.TimeAxes,ts,'off');
            obj.NeedsLabels = true;
         else
            ts = obj.Value(obj.Type==1) + obj.VidGraphics.NeuOffset;
            if obj.NeedsLabels
               setTimeStamps(obj.TimeAxes,ts,'on',obj.EventNames{:});
               obj.NeedsLabels = false;
            else
               updateTimeStamps(obj.TimeAxes,ts);
            end
         end
      end
      
      % Updates video graphics time
      function updateVidGraphicsTime(obj)
         %UPDATEVIDGRAPHICSTIME  Updates video graphics time
         %
         %  updateVidGraphicsTime(obj,v,trialIndex);
         %
         %  obj : nigeLab.libs.behaviorInfo object
         
         v = obj.VidGraphics;
         if isempty(v)
            return;
         end
         trialIndex = obj.TrialIndex;
         startVarName = obj.Block.Pars.Video.StartExportVariable;
         
         varIdx = findVariable(obj,startVarName);
         ts = obj.Trial(trialIndex);
         if isnan(varIdx)
            
         else
            ts = obj.Value(varIdx);
            if isnan(ts) || isinf(ts)
               ts = obj.Trial(trialIndex);
            end
         end
         v.SeriesTime = ts + v.NeuOffset;
         v.DataLabel.String = sprintf('Trial: %g',trialIndex);
         v.DataLabel.Color = obj.TrialButtonArray(trialIndex).EdgeColor;
         obj.NeedsLabels = true;
      end
   end
   
   % PROTECTED
   methods (Access=protected)
      % Construct the scoring progress tracker graphics objects
      function buildProgressTracker(obj)
         % BUILDPROGRESSTRACKER  Builds socring progress tracker graphics
         %  objects that act as a progress bar based on trial scoring
         %  completion.
         
         % Put these things into a separate panel
         obj.IndicatorPanel = nigeLab.libs.nigelPanel(obj.Panel,...
            'Units','Normalized',...
            'Position',[0 0.75 1 0.25],...
            'TitleBarColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleColor',nigeLab.defaults.nigelColors('onsurface'),...
            'Tag','IndicatorPanel');
         nestObj(obj.Panel,obj.IndicatorPanel,'IndicatorPanel');
         
         % Make axes container for Label objects
         obj.IndicatorAxes = axes(obj.IndicatorPanel.Panel,...
            'Units','Normalized',...
            'Position',[0.025 0.60 0.95 0.35],...
            'Color','none',...
            'NextPlot','add',...
            'XLim',[0 1],...
            'YLim',[0 1],...
            'Tag','IndicatorAxes',...
            'XColor','none',...
            'YColor','none');
         nestObj(obj.IndicatorPanel,obj.IndicatorAxes,'IndicatorAxes');
         
         % Add a label that describes current scoring out of total trials
         str = sprintf('Progress Indicator          %g/%g',...
            obj.NScored,obj.NTotal);
         obj.ProgressLabel = text(obj.IndicatorAxes, ...
            0.025, 0.125, str,... 
            'FontName','Droid Sans',...
            'FontSize',15,...
            'FontWeight','bold',...
            'Color','w');
         
         % Add a label indicating the current trial
         str = sprintf('Current Trial: %g',obj.TrialIndex);
         obj.TrialLabel = text(obj.IndicatorAxes, ...
            0.025, 0.425, str,...
            'FontName','Droid Sans',...
            'FontSize',15,...
            'FontWeight','bold',...
            'Color','w');
         
         % Add a label that describes total # successes from session
         str = sprintf('%g Successful Trials',nansum(obj.Outcome(obj.Mask)));
         obj.SuccessIndicatorLabel = text(obj.IndicatorAxes, ...
            0.025, 0.725, str,...
            'FontName','Droid Sans',...
            'FontSize',15,...
            'FontWeight','bold',...
            'Color','w');

         % Create axes that will display "progress" image
         obj.TrialButtonAxes = axes(obj.IndicatorPanel.Panel,...
            'Units','Normalized',...
            'Position',[0.025 0.025 0.95 0.5],...
            'Color','none',...
            'NextPlot','add',...
            'XLim',[1 obj.NTotal+1],...
            'YLim',[0 1],...
            'Tag','TrialButtonAxes',...
            'XColor','none',...
            'YColor','none');
         nestObj(obj.IndicatorPanel,obj.TrialButtonAxes,'TrialButtonAxes');
         obj.TrialButtonArray = [];
         o = 0.05;
         s = 0.90;
         dcol = nigeLab.defaults.nigelColors('dark');
         C = getColorMap(obj.Block);
         for i = 1:obj.NTotal
            col = getAltColor(obj,'b','r',obj.Outcome(i));
            col = getAltColor(obj,col,'light',obj.State(i));
            col = getAltColor(obj,col,'med',obj.Mask(i));
            pos = [i+o o s s]; 
            obj.TrialButtonArray = horzcat(obj.TrialButtonArray,...
               nigeLab.libs.nigelButton(obj.TrialButtonAxes,...
               pos,num2str(i),{@obj.setTrial,obj.VidGraphics,i},...
               'Position',pos,...
               'FontUnits','points',...
               'FontSize',13,...
               'FontColor','none',...
               'FaceColor',col,...
               'EdgeColor',C(i,:),...
               'HoveredColor','g',...
               'HoveredFontColor','dark',...
               'FaceColorDisable',dcol,...
               'HoldSelection','on',...
               'SelectedColor',C(i,:),...
               'LineWidth',2.00,...
               'Curvature',[0.25 0.5]));
         end
         % Add the 'rollover' button that tracks mouse interaction
         obj.MouseRollover = nigeLab.utils.Mouse.rollover(...
            obj.Figure,obj.TrialButtonArray);
         obj.TrialButtonArray(obj.TrialIndex).Selected = 'on';
         obj.Figure.WindowButtonUpFcn = [];
      end
      
      % Construct the video controller graphics objects for scoring
      function buildValuePanel(obj)
         %BUILDVALUEPANEL  Build the "value" display panel 
         %  
         %  buildValuePanel(obj);
         %  >> Called in constructor
         
         % Need a panel to separate this stuff from other
         obj.ValuesPanel = nigeLab.libs.nigelPanel(obj.Panel,...
            'Units','Normalized',...
            'PanelColor',nigeLab.defaults.nigelColors('surface'),...
            'String','Trial Metadata',...
            'Tag','ValuesPanel',...
            'TitleFontSize',16,...
            'Position',[0 0 1 0.75]);
         
         % Make text labels for controls
         eIdx = obj.Type==1;
         mIdx = obj.Type>1;
         n = [sum(eIdx) sum(mIdx)]; 
         [nRow,moreLabels] = max(n);
         nRow = nRow + 1;
         % "EventTimes" labels get one column and "Meta" labels get second
         Labs = cell(nRow,2);
         Labs{1,1} = 'Trials';
         if moreLabels == 1
            Labs(2:nRow,1) = obj.Variable(eIdx);
            startIdx = nRow-n(2)+1; % Offset by 1 for 'Trials'
            Labs(startIdx:nRow,2) = obj.Variable(mIdx);
         else
            startIdx = nRow-n(1)+1; % Offset by 1 for 'Trials'
            Labs(startIdx:nRow,1) = obj.Variable(eIdx);
            Labs(2:nRow,2) = obj.Variable(mIdx);
         end
         Labs(cellfun(@isempty,Labs)) = {''};
         [obj.ValueLabels,xPos,yPos,~,H,ax] = nigeLab.utils.uiMakeLabels(...
            obj.ValuesPanel.Panel,Labs,...
            'Left',0.0250,'Right',0.5750);
         
         % Make "disabled" edit boxes to display trial scoring data
         ValueLabs = Labs;         
         ValueLabs{1,1} = '';
         idx = cellfun(@isempty,ValueLabs);
         ValueLabs(~idx) = {'???'};
         obj.ValuesDisplayArray = nigeLab.utils.uiMakeLabels(ax,ValueLabs,...
            'Color',nigeLab.defaults.nigelColors('disabletext'),...
            'BackgroundColor',nigeLab.defaults.nigelColors('light'),...
            'EdgeColor',nigeLab.defaults.nigelColors('secondary'),...
            'Left',0.5750,'Right',0.0250,...
            'HorizontalAlignment','left');
         obj.ValuesDisplayArray = obj.ValuesDisplayArray(:);
         % Remove empty labels
         delete(obj.ValuesDisplayArray(idx(:)));
         obj.ValuesDisplayArray(idx(:)) = [];
         
         % Format Trial times to make them look nicer in popupbox
         str = nigeLab.libs.behaviorInfo.ts2str(obj.Trial);
         
         % Add separator
         yH = yPos(1,1) + H;
         ySep = yH + (yH - yPos(1,2))*3/4; % Put between 
         annotation(obj.ValuesPanel.Panel,'line',...
            [0.025 0.975],[ySep ySep],...
            'Color',nigeLab.defaults.nigelColors('onsurface'),...
            'LineStyle','-',...
            'LineWidth',3);
         
         % Make box for selecting current trial
         xLB = xPos(1,1)+0.05;
         wLB = 0.975 - xLB;
         obj.TrialPopupMenu = uicontrol(obj.ValuesPanel.Panel,'Style','popupmenu',...
            'Units','Normalized',...
            'Position',[xLB yPos(1,1)+(H/4) wLB H],...
            'FontName','Droid Sans',...
            'FontSize',14,...
            'String',str,...
            'UserData',obj.Trial,...
            'Callback',@obj.setTrial);
      end
      
      % Check to see if scoring is complete and return either 'Complete' or
      % 'In Progress' as output string.
      function status = checkProgress(obj)
         % CHECKPROGRESS  Return 'Complete' or 'In Progress' by score state
         %
         %  status = checkProgress(obj); 
         
         f = obj.ScoringField;
         idx = getEventsIndex(obj.Block,f,'Header');
         if sum(obj.NScored)==obj.NTotal
            status = 'Complete';
            SetCompletedStatus(obj.Block.Events.(f)(idx).data,true);
         else
            status = 'In Progress';
            SetCompletedStatus(obj.Block.Events.(f)(idx).data,false);
         end  
      end
      
      % Find next trial to score, if loading a previous session
      function nextTrial = findNextToScore(obj)
         % FINDNEXTTOSCORE  Helper function to set the current trial index
         %     to the next necessary file to score. Designed to facilitate
         %     continued scoring of a file that was partially scored.
         
         nextTrial = find(obj.State & obj.Mask,1,'first');
         
         %          % If it can't find any NaN entries, its already been fully scored.
         %          % Default to final trial to indicate that.
         %          if isempty(nextTrial)
         %             nextTrial = obj.NTotal;
         %          end
         
         % 2019-10-15: Change this to initialize to first trial to
         % facilitate appending the 'Stereotyped' tag to trials.
         if isempty(nextTrial)
            nextTrial = 1;
         end
      end
      
      % Get "alternate" color based on flag (or obj.Mask(obj.TrialIndex)
      function col = getAltColor(obj,trueCol,falseCol,flag)
         %GETALTCOLOR  Gets "alternate" color based on flag (or Mask)
         %
         %  col = getAltColor(obj,trueCol,falseCol);
         %  --> Pick between trueCol and falseCol based on
         %  obj.Mask(obj.TrialIndex) value
         %
         %  col = getAltColor(obj,trueCol,falseCol,status);
         %  --> Pick between trueCol and falseCol based on logical value of
         %     `status`
         
         % Parse from # inputs
         if nargin < 3
            error(['nigeLab:' mfilename ':TooFewInputs'],...
               'Must supply at least 3 inputs.');
         end
         if nargin < 4
            if isnan(obj.TrialIndex)
               curIndex = 1;
            else
               curIndex = obj.TrialIndex;
            end
            flag = obj.Mask(curIndex);
         end
         
         % Make sure values are numeric [r,g,b]
         if ischar(trueCol)
            trueCol = nigeLab.defaults.nigelColors(trueCol);
         end
         if ischar(falseCol)
            falseCol = nigeLab.defaults.nigelColors(falseCol);
         end
         
         % Return trueCol or falseCol
         if flag
            col = trueCol;
         else
            col = falseCol;
         end
      end

      % Updates controller panel color to reflect Masking
      function updateObjColors(obj,curTrial)
         %updateObjColors  Updates controller panel color (for .Mask)
         %
         %  updateObjColors(obj);
         %  --> Uses obj.TrialIndex for curTrial
         %
         %  updateObjColors(obj,curTrial);
         %  --> Specify curTrial manually
         
         if nargin < 2
            curTrial = obj.TrialIndex;
         end
         
         flag = obj.Mask(curTrial);
         pCol = getAltColor(obj,'surface','med',flag);
         
         % Check if it is Masked or if All Variables Scored
         stateFlag = ~any(isnan(obj.Value)) || (~flag);
         
         if stateFlag
            varIdx = findVariable(obj,'Outcome');
            if isnan(obj.Value(varIdx))
               tCol = pCol;
            else
               tCol = getAltColor(obj,'b','r',obj.Value(varIdx));
            end
         else
            tCol = nigeLab.defaults.nigelColors('light');
         end
         
         % Update color of controller panel
         obj.ValuesPanel.Color.Panel = pCol; 
         
         % Update the scoring tracker color as well
         if flag
            obj.TrialButtonArray(curTrial).Enable = 'on';
            obj.TrialButtonArray(curTrial).FaceColor = tCol;
            c = tCol;
         else
            obj.TrialButtonArray(curTrial).Enable = 'off';
            obj.TrialButtonArray(curTrial).FaceColor = tCol*0.75;
            c = pCol;
         end
         if ~isempty(obj.VidGraphics)
            if obj.VidGraphics.TimeAxes.ZoomLevel == 0
               obj.VidGraphics.TimeAxes.TimeStamps(curTrial).MarkerFaceColor = c;
               obj.VidGraphics.TimeAxes.TimeStamps(curTrial).MarkerEdgeColor = c;
            end
         end
         
         % Update labels and colors based on total number scored etc.
         obj.ProgressLabel.String = sprintf(...
            'Progress Indicator          %g/%g',...
            obj.NScored,obj.NTotal);       
         if obj.NSuccessful == 1
            obj.SuccessIndicatorLabel.String = ...
               '1 Successful Retrieval';
         else
            obj.SuccessIndicatorLabel.String = sprintf(...
               '%g Successful Retrievals',obj.NSuccessful);
         end  
         
         obj.TrialLabel.String = sprintf('Current Trial: %g',curTrial);
         if ~isempty(obj.VidGraphics)
            updateTimeLabelsCB(obj.VidGraphics,...
               obj.VidGraphics.SeriesTime,obj.VidGraphics.NeuTime);
         end
         
         if obj.NScored == obj.NTotal
            obj.IndicatorPanel.Color.TitleBar = ...
               nigeLab.defaults.nigelColors('background');
            obj.IndicatorPanel.Color.TitleText = ...
               nigeLab.defaults.nigelColors('yellow');
            
            obj.ProgressLabel.Color =  ...
               nigeLab.defaults.nigelColors('yellow');
            obj.SuccessIndicatorLabel.Color =  ...
               nigeLab.defaults.nigelColors('yellow');
         else
            obj.IndicatorPanel.Color.TitleBar = ...
               nigeLab.defaults.nigelColors('surface');
            obj.IndicatorPanel.Color.TitleText =  ...
               nigeLab.defaults.nigelColors('red');
            
            obj.ProgressLabel.Color =  ...
               nigeLab.defaults.nigelColors('white');
            obj.SuccessIndicatorLabel.Color =  ...
               nigeLab.defaults.nigelColors('white');
         end
         updateTimeLabelsCB(obj.VidGraphics);
      end
      
      % Update object labels
      function updateObjLabels(obj,varIndices)
         %UPDATEOBJLABELS  Update graphics labels to correct values
         %
         %  updateObjLabels(obj,varIndices);
         %  --> varIndices : Like curTrial, if not specified it updates all
         %  of variables from current trial. Specify this to only update a
         %  subset of column indices.
         
         if nargin < 2
            varIndices = 1:numel(obj.Variable);
         end
         
         % Increment through the variables (columns of behaviorData)
         for newVarIndex = varIndices
            % For each variable get the appropriate corresponding value,
            % turn it into a string, and update the graphics with that:
            val = obj.Value(newVarIndex);
            % Note: obj.StringFcn property is configured in 
            %  ~/+defaults/Video.m
            %  --> pars.VideoScoringStringsFcn
            %
            %  It can be set to the handle of a custom function designed by
            %  the user depending on the video scoring application.
            %  Essentially, its purpose is entirely cosmetic and is for
            %  matching "types" (Block.Pars.Video.VarType, which correspond
            %  to each Event), to a corresponding output string that makes
            %  sense (for example matching 0 or 1 to "Unsuccessful or
            %  "Successful" respectively for VarType == 4 in the Default
            %  function)
            obj.ValuesDisplayArray(newVarIndex).String = ...
               obj.StringFcn(obj.Type(newVarIndex),val);
         end
      end
      
   end
   
   % STATIC,PUBLIC
   methods (Static,Access=public)
      % Create "Empty" object or object array
      function obj = empty(n)
         %EMPTY  Return empty nigeLab.libs.behaviorInfo object or array
         %
         %  obj = nigeLab.libs.behaviorInfo.empty();
         %  --> Return scalar (0 x 0) object
         %
         %  obj = nigeLab.libs.behaviorInfo.empty(n);
         %  --> Specify number of empty objects
         
         if nargin < 1
            dims = [0, 0];
         else
            if ~isscalar(n)
               error(['nigeLab:' mfilename ':invalidEmptyDims'],...
                  'Input to nigeLab.libs.behaviorInfo.empty should be scalar.');
            end
            dims = [0, n];
         end
         
         obj = nigeLab.libs.behaviorInfo(dims);
      end
      
      % Convert timestamp array to string
      function str = ts2str(ts)
         %TS2STR  Convert timestamp array to string
         %
         %  str = nigeLab.libs.behaviorInfo.ts2str(ts);
         %
         %  ts  : Column vector of timestamps (double)
         %  str : Char array of times in ts (column vector also)
         
         % Make controller for switching between trials
         str = cellstr(num2str(ts));
         % This makes it look nicer:
         str = cellfun(@(x) strrep(x,' ',''),str,'UniformOutput',false);
      end
   end
   % % % % % % % % % % END METHODS% % %
end