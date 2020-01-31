classdef behaviorInfo < handle
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
   properties (Transient,GetAccess=public,SetAccess=immutable)
      Block                            % Pointer to block object handle
      Panel                            % Pointer to nigelPanel container
   end
   
   % TRANSIENT,HIDDEN,PUBLIC (flags)
   properties (Transient,Hidden,Access=public)
      verbose (1,1) logical  = false  % Set true to print debug output
   end
   
   % PUBLIC
   properties(Access=public)
      varVal            % 1 x k vector of scalar values for a single trial
      varType           % 1 x k vector of scalar indicators of varVal type
      varName           % 1 x k label vector
      
      idx     (1,1) double    = 1   % Current variable being updated
      cur     (1,1) double    = 1   % Index of current trial for alignment
   end
   
   % PUBLIC/PROTECTED
   properties(GetAccess=public,SetAccess=protected)
      parent  % Figure handle of parent
      misc    % Struct for 'ad hoc' properties as fields
              % --> with default 'ValueShortcutFcn' property function
              %     handle, this struct gains the field 'PastPelletsValue'
              %     that keeps the last entered value for 'Pellets'
              %     metadata variable. Any subsequent trial that does not
              %     have the 'Pellets' value entered (when scoring is
              %     initiated on that trial) defaults to this value.
              %     Similar fields could be added from 'ad hoc' functions
              %     that need to store temporary variables with the
              %     behaviorInfo object.
      N       % Total number of trials
      offset = 0; % Default to 0 offset
   end
   
   % PROTECTED
   properties(Access=protected)
      hashID           % hash string to track progress in metadata table
      fieldName        % Name corresponding to "manual" scored events
      outcomeName      % Name corresponding to "Outcome" for scoring
      
      ValueShortcutFcn % Function handle for scoring heuristics
      ForceToZeroFcn   % Function handle to "force" all trial values to 0
      
      TrialBuffer      % Value to subtract from trial onset so that initial 
                       % frame starts a few frames before the start of the
                       % putative trial. This speeds up scoring since
                       % VideoReader seems to get frames faster in
                       % "forward" direction.
      
      panel                % Panel for holding graphics objects
      conPanel             % Panel for holding controls
      trkPanel             % Panel for tracking progress
      ScoringTracker_ax;   % Axes for scoring tracker image/line
      ScoringTracker_im;   % Image for overall trial progress bar
      ScoringTracker_line; % Overlay line for current trial indicator
      ScoringTracker_lab;  % Label to keep track of scoring completion
      SuccessTracker_lab;  % Label to keep track of total # successful
      trialPop;            % Popupmenu for selecting trial
      editArray;           % Cell array of handles to edit boxes
      
      loopFlag = false     % Flag indicating that all trials are looped
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % EVENTS % % % % % % % % % % % %
   % PUBLIC
   events (ListenAccess=public,NotifyAccess=public)
      scoredValueChanged      % When a value is modified during scoring
      trialChanged            % Switch to a new trial
      saveFile    % When file is saved
      closeReq    % When UI is requested to close
      countIsZero % No pellets are on platform, or pellet not present
      nSuccessChanged         % # successful trials changed
   end
   % % % % % % % % % % END EVENTS % % %
   
   % % % METHODS% % % % % % % % % % % %
   % RESTRICTED:{nigeLab.Block,nigeLab.nigelObj} (constructor)
   methods (Access={?nigeLab.Block,?nigeLab.nigelObj})
      % Construct the behaviorInfo object
      function obj = behaviorInfo(blockObj,nigelPanelObj)
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
         
         if nargin < 2
            nigelPanelObj = nigeLab.libs.nigelPanel(...
               'Units','Normalized',...
               'Position',[0 0 1 1],...
               'Scrollable','off',...
               'Tag','behaviorInfo');
         end
         obj.Panel = nigelPanelObj;
         
         % Parse properties for convenience based on Block
         obj.parseBlockProperties;
         
         % Parse properties referenced from Events field of Block
         obj.parseEventProperties;
         
         obj.misc = struct; % initialize this struct that holds misc data
                            % it can be used by ad hoc function to store a
                            % "past" value of a scoring or etc
         
         obj.setScoringMetadata; % initializes hashID as well
         
         obj.buildVideoControlPanel;
         obj.buildProgressTracker;
         
      end
   end
   
   % NO ATTRIBUTES (overloaded methods)
   methods 
      % % % GET.PROPERTY METHODS % % % % % % % % % % % %
      
      % % % % % % % % % % END GET.PROPERTY METHODS % % %
      
      % % % SET.PROPERTY METHODS % % % % % % % % % % % %
      
      % % % % % % % % % % END SET.PROPERTY METHODS % % %
   end
   
   % PUBLIC
   methods (Access=public)
      % Add or remove the grasp time for this trial
      function [varState,out] = addRemoveValue(obj,val)
         % ADDREMOVEVALUE Toggles a value between what is given by 'val'
         %  input and its current value. If the current value is equivalent
         %  to 'val', then the value is toggled to 'nan', which indicates
         %  that it has not been scored yet.
         %
         %  [varState,out] = obj.addRemoveValue(val);
         %  --> Returns true if value was previously unset (NaN)
         %  --> out is the current value associated with that variable in
         %        the behaviorInfo object, but it has not been translated
         %        over to the DiskData file yet.

         storedVal = obj.getCurrentTrialData;
         if storedVal(obj.idx)==val
            out = nan;
            varState = false;
         else
            out = val;
            varState = true;
         end
         obj.varVal(obj.idx) = out;
      end
      
      % Force the value to zero for the current variable index
      function varState = forceZeroValue(obj)
         % FORCEZEROVALUE  Sets the current variable to zero or comparable
         %   value as is appropriate for the variable type. For a
         %   timestamp, values of inf indicate that it didn't happen.
         %
         %  varState = obj.forceZeroValue;
         %  --> Returns true if values for each variable were set correctly
         
         varState = obj.ForceToZeroFcn;
      end
      
      % Returns data for current trial AND updates obj.varVal
      function data = getCurrentTrialData(obj)
         % GETCURRENTTRIALDATA  Return data array for current trial and
         %                      update obj.varVal
         %
         %  data = getCurrentTrialData(obj); Gets row vector for this trial
         
         data = nan(size(obj.varType));
         data(obj.varType == 1) = obj.EventTimes(obj.cur,'get');
         data(obj.varType >  1) = obj.Meta(obj.cur,'get');
      end
      
      % Returns current var type (either: 'EventTimes' or 'Meta')
      function type = getCurVarType(obj)
         % GETCURVARTYPE  Returns either 'EventTimes' or 'Meta' depending
         %                on current variable index.
         %
         %  type = obj.getCurVarType;  Returns 'EventTimes' or 'Meta'
         
         vt = obj.varType(obj.idx);
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
      
      % Returns a struct of handles to graphics objects
      function graphics = getGraphics(obj)
         % GETGRAPHICS  Return a struct of handles to graphics objects.
         %
         % graphics = obj.getGraphics; Returns a struct with
         % trialTracker_display, trialTracker_displayOverlay, etc. as
         % fields, each of which are different graphics.
         %
         %  graphics: struct with following fields
         %     * trialTracker_display --> obj.ScoringTracker_im
         %     * trialTracker_displayOverlay --> obj.ScoringTracker_line
         %     * successTracker_label --> obj.ScoringTracker_lab
         %     * trialPopup_display --> obj.trialPop
         %     * editArray_display --> {obj.editArray}
         %     * behavior_panel --> obj.Panel
         %     * behavior_conPanel --> obj.conPanel
         %     * behavior_trkPanel --> obj.trkPanel
         
         graphics = struct('animalName_display',obj.Panel,...
            'trialTracker_display',obj.ScoringTracker_im,...
            'trialTracker_displayOverlay',obj.ScoringTracker_line,...
            'trialTracker_label',obj.ScoringTracker_lab,...
            'successTracker_label',obj.SuccessTracker_lab,...
            'trialPopup_display',obj.trialPop,...
            'editArray_display',{obj.editArray},...
            'behavior_panel',obj.Panel,...
            'behavior_conPanel',obj.conPanel,...
            'behavior_trkPanel',obj.trkPanel);
      end
      
      % Gets the variable index for a particular named variable or array of
      % indices for set of named variables
      function idx = getVarIdx(obj,varName)
         % GETVARIDX  Matches varName to elements of obj.varName
         %
         %  idx = obj.getVarIdx(varName);
         
         idx = find(ismember(obj.varName,varName));
      end
      
      % Remove this trial (if it is an invalid trial)
      function removeTrial(obj)
         % REMOVETRIAL  Remove a trial entry
         %
         %  removeTrial(obj); Removes current trial from the array
         
         % Remove entry from list
         setEventData(obj.Block,obj.fieldName,'Trial','mask',0,obj.cur);
         obj.trialPop.String(obj.cur) = [];
         obj.ScoringTracker_im.CData(:,obj.cur,:) = [];
         
         obj.N = obj.N - 1;
         if obj.N > 0
            obj.cur = min(obj.cur,obj.N); % Make sure you don't go over
            obj.setTrial(nan,obj.cur,true);
         else
            close(gcf);
            warning('No valid trials to score for this video!');
         end
      end
      
      % Save blockObj with scoring
      function saveScoring(obj)
         % SAVESCORING  Save behaviorInfo.Block object with scoring data
         %
         %  obj.saveScoring;  Save the Block object. Even without saving
         %                    the Block object, the Events files should be
         %                    updated when a change is made. This part
         %                    basically updates the Scoring metadata and 
         
         info = getScoringMetadata(obj.Block,'Video',obj.hashID);
         info.Toc(1) = info.Toc(1) + toc(info.Tic(1));
         info.Tic(1) = tic;
         info.Status{1} = obj.checkProgress;
         obj.setScoringMetadata(info);
         save(obj.Block);
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.behaviorInfo',...
               'saveScoring');
            fprintf(1,'-->\tsaveFile event issued: %s\n',s);
         end 
         notify(obj,'saveFile');
         
      end
      
      % Save the trial timestamp data from the current trial
      function setCurrentTrialData(obj)
         % SETCURRENTTRIALDATA  Save array for current trial
         %
         %  setCurrentTrialData(obj);  Write data for this trial to the
         %                             'Event'-type DiskData associated
         %                             with obj.Block
         
         obj.EventTimes(obj.cur,'set');
         obj.Meta(obj.cur,'set');
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
            info = obj.Block.getScoringMetadata('Video');
            if isempty(info)
               obj.hashID = nigeLab.utils.makeHash();
               todays_date = nigeLab.utils.getNigelDate();
               user = obj.Block.User;
               prog = obj.checkProgress;
               info = table({user},{todays_date},{prog},tic,0,...
                  'VariableNames',{'User','Date','Status','Tic','Toc'},...
                  'RowNames',obj.hashID);    
            else
               obj.hashID = info.Properties.RowNames;
               info.Tic(1) = tic;
            end
         end
         obj.Block.addScoringMetadata('Video',info);
      end
      
      % Set the current trial button and emit notification about the event
      function setTrial(obj,src,newTrial,reset)
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
         %  newTrial  --  Trial index to set the trial to.
         %  reset  --  If true, then forces graphics fields to reset even
         %              if value of newTrial is the same as the previous
         %              trial index.
         
         % Give option of sending in a uiControl object and getting value
         % for the new trial
         if isa(src,'matlab.ui.control.UIControl')
            newTrial = src.Value;
         end
         
         % Add a "reset" arg that can be used in specific instances where
         % we WANT to reset the trial based on having the same index (for
         % example, after a trial deletion).
         if nargin < 4
            reset = false;
         end
         
         if (newTrial < 1) || (newTrial > obj.N)
            return;
         end
         
         % Add looping so you go to the correct trial if the current trial
         % is "masked"
         if ~obj.TrialMask(newTrial)
            newTrial = newTrial + 1;
            if newTrial > obj.N
               if obj.loopFlag
                  warning('No unmasked trials.');
                  obj.saveScoring;
                  obj.closeScoringRequest(true);
                  return;
               end
               newTrial = 1;
               obj.loopFlag = true;
            end
            obj.setTrial(src,newTrial,reset);
            return;
         else % Set the current varVal data to diskfile before updating
            obj.setCurrentTrialData; 
         end
         
         % Or just using newTrial as extra input argument
         if (newTrial == obj.cur) && (~reset)
            % obj.cur is initialized to 1 on constructor
            if obj.verbose
               s = nigeLab.utils.getNigeLink(...
                  'nigeLab.libs.behaviorInfo',...
                  'setTrial');
               fprintf(1,'-->\tnewTrial (%g) == obj.cur (%g): %s\n',...
                  newTrial,obj.cur,s);
            end
            return;
         end
            
         % Update "Trials" to reflect the earliest "timestamped" indicator
         % (in this case, update to the "Reach" timestamp for Trial, if it
         %  exists).
         tsIdx = find(obj.varType==1,1,'first');
         if ~isempty(tsIdx)
            t = obj.EventTimes(newTrial);
            t = nanmin(t); % Take the minimum value as the start.
            if (~isnan(t)) && (~isinf(t))
               obj.Trial(newTrial,t);
            end
         end

         obj.idx = 1;  % reset index to 1 for checking graphics
         obj.cur = newTrial;
         obj.varVal = obj.getCurrentTrialData;
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.behaviorInfo',...
               'setTrial');
            fprintf(1,'-->\ttrialChanged event issued: %s\n',s);
         end 
         notify(obj,'trialChanged');

      end
      
      % Set the associated value and notify. Parse different kinds of
      % inputs to create "shortcuts" here that automatically update certain
      % elements.
      function setValue(obj,idx,val)
         % SETVALUE  Parse different inputs to allow handling of exceptions
         %           based on variable type indexing.
         
         obj.ValueShortcutFcn(obj,idx,val);
         obj.setCurrentTrialData; % Update current trial data
      end
      
      % Set all associated values
      function setValueAll(obj,idx,val)
         % SETVALUEALL  Set all associated values of behavior
         %
         %  obj.setValueAll(idx,val);
         %  
         %  idx  --  Trial index to set.
         %  val  --  New values to update obj.varVal (the current trial's
         %              values for each variable to be scored).
         
         vec = (1:obj.N).';
         obj.varVal(idx) = val;
         obj.idx = idx;
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.behaviorInfo',...
               'setValueAll');
            fprintf(1,'-->\tscoredValueChanged event issued: %s\n',s);
         end
         notify(obj,'scoredValueChanged'); % Update first to display it
         if strcmpi(obj.getCurVarType,'Meta')
            colIdx = find(obj.idx,1,'first')+1;
            val = repmat(val,numel(vec),1);
            setEventData(obj.Block,obj.fieldName,'data','Trial',val,':',colIdx);
         else
            % Don't do this for timestamp data, that's a bad idea.
         end
      end
      
      % Increment the idx property by 1 and return false if out of range
      function flag = stepIdx(obj)
         % STEPIDX  Increment behaviorInfo.idx by 1 and return false if out
         %  of range
         %
         % flag = stepIdx(obj); Start over since finished stepping through
         %                       each variable in the array.
         
         obj.idx = obj.idx + 1;
         flag = obj.idx <= numel(obj.varType);
         if ~flag
            obj.idx = 1;
         end
      end
   end
   
   % HIDDEN,PUBLIC
   methods (Hidden,Access=public)
      % Request to close scoring UI
      function closeScoringRequest(obj,forceClose)
         % CLOSESCORINGREQUEST  Issued when requesting to close scoring UI
         
         if nargin < 2
            forceClose = false;
         end
         
         if forceClose
            if obj.verbose
               s = nigeLab.utils.getNigeLink(...
                  'nigeLab.libs.behaviorInfo',...
                  'closeScoringRequest');
               fprintf(1,'-->\tcloseReq event issued: %s\n',s);
            end 
            notify(obj,'closeReq')
         else
            str = questdlg('Exit scoring?','Close Prompt',...
               'Yes','No','Yes');
            if strcmpi(str,'Yes')
               if obj.verbose
                  s = nigeLab.utils.getNigeLink(...
                     'nigeLab.libs.behaviorInfo',...
                     'closeScoringRequest');
                  fprintf(1,'-->\tcloseReq event issued: %s\n',s);
               end 
               notify(obj,'closeReq');
            end
         end
      end
   end
   
   % SEALED,PUBLIC
   methods (Sealed,Access=public)
      % Quick reference to all varType == 1 members (timestamp scoring)
      function ts = EventTimes(obj,trialIdx,getsetmode)
         % EVENTTIMES  Scoring that contains timestamp data
         %
         %  ts = obj.EventTimes; Returns all Event Times (Reach Grasp etc)
         %  ts = obj.EventTimes(trialIdx); Returns indexed Event Times
         %  obj.EventTimes(__,'set');  Updates diskfile data for current
         %                             trial Event Times (agnostic to value
         %                             given for trialIdx).
         
         if nargin < 3
            getsetmode = 'get';
         end
         
         v = obj.varName(obj.varType == 1);
         switch lower(getsetmode)
            case 'get'
               if nargin > 1
                  ts = nan(1,numel(v));
                  for iV = 1:numel(v)
                     t = getEventData(obj.Block,obj.fieldName,'ts',v{iV});
                     ts(iV) = t(trialIdx);
                  end
               else
                  ts = nan(numel(obj.Trial),numel(v));
                  for iV = 1:numel(v)
                     ts(:,iV) = getEventData(obj.Block,obj.fieldName,'ts',v{iV});
                  end
               end
               return;
            case 'set'
               val = obj.varVal(obj.varType == 1);
               for iV = 1:numel(v)
                  setEventData(obj.Block,obj.fieldName,'ts',v{iV},val(iV),obj.cur);
               end
               return;
            otherwise
               error('Invalid getsetmode value: %s',getsetmode);
         end
         
      end
      
      % Quick reference to metadata header
      function h = Header(obj)
         % HEADER  Contains metadata variable types
         
         h = getEventData(obj.Block,obj.fieldName,'snippet','Header');
         
      end
      
      % Quick reference to scored metadata
      function data = Meta(obj,trialIdx,getsetmode)
         % META  Returns Trial metadata. Variables are defined by Header.
         %
         %  data = obj.Meta; Returns all trial metadata for all trials
         %  data = obj.Meta(trialIdx); Returns specific trial metadata
         %  obj.Meta(__,'set');        Update disk file with current
         %                              values for this trial's metadata
         %                              (agnostic to trialIdx value)
         
         if nargin < 3
            getsetmode = 'get';
         end
         
         switch lower(getsetmode)
            case 'get'
               data = getEventData(obj.Block,obj.fieldName,'snippet','Trial');
               if nargin > 1
                  data = data(trialIdx,:);
               end
               return;
            case 'set'
               val = obj.varVal(obj.varType > 1);
               setEventData(obj.Block,obj.fieldName,'meta','Trial',val,obj.cur);
            otherwise
               error('Invalid getsetmode value: %s',getsetmode);
         end
         
         
         
      end
      
      % Quick reference for video offset from header
      function offset = Offset(obj)
         % OFFSET  Gets the video offset (seconds) for each video
         
         offset = getEventData(obj.Block,obj.fieldName,'ts','Header');
         offset(isnan(offset)) = 0; % Set any "NaN" offset to zero
      end
      
      % Quick reference for Outcome
      function out = Outcome(obj,trialIdx)
         % OUTCOME  Returns false for unsuccessful, true for successful
         %           pellet retrievals.
         %
         %  out = obj.Outcome; Returns all trial outcomes
         %  out = obj.Outcome(trialIdx); Returns indexed trial outcomes
         
         vName = obj.varName(obj.varType > 1);
         
         if isempty(obj.outcomeName)
            out = true(obj.N,1);
            return;
         end
         
         iOut = strcmpi(vName,obj.outcomeName);
         
         out = getEventData(obj.Block,obj.fieldName,'snippet','Trial');
         if nargin > 1
            out = logical(out(trialIdx,iOut));
         else
            out = logical(out(:,iOut));
         end
      end
      
      % Quick reference to putative Trial times
      function ts = Trial(obj,trialIdx,val)
         % TRIAL  Returns column vector of putative trial times (seconds)
         %
         %  ts = obj.Trial; Returns all values of Trial
         %  ts = obj.Trial(trialIdx); Returns indexed values of Trial
         %  obj.Trial(trialIdx,val);  Sets indexed values of Trial
         
         if nargin < 3
            ts = getEventData(obj.Block,obj.fieldName,'ts','Trial');
            if nargin > 1
               ts = ts(trialIdx);
            end
         else
            if nargout > 0
               error('Trying to get and set at the same time?');
            end
            setEventData(obj.Block,obj.fieldName,'ts','Trial',val,trialIdx);
         end
      end
      
      % Quick reference to Trial mask
      function mask = TrialMask(obj,trialIdx)
         % TRIALMASK Returns column vector of zero (masked) or one
         %     (unmasked) for each putative Trial
         %
         % mask = obj.TrialMask;
         
         mask = getEventData(obj.Block,obj.fieldName,'mask','Trial');
         mask = logical(mask);
         if nargin > 1
            mask = mask(trialIdx);
         end
      end
   end
   
   % PROTECTED
   methods (Access=protected)
      % Construct the scoring progress tracker graphics objects
      function buildProgressTracker(obj)
         % BUILDPROGRESSTRACKER  Builds socring progress tracker graphics
         %  objects that act as a progress bar based on trial scoring
         %  completion.
         
         % Create tracker and set all to red to start
         C = zeros(1,obj.N,3);
         C(1,1:(obj.cur-1),3) = 1; % Set already-scored trials to blue
         C(1,obj.cur:obj.N,1) = 1; % set unscored trials to red
         x = [0 1];
         y = [0 1];
         
         % Put these things into a separate panel
         obj.trkPanel = nigeLab.libs.nigelPanel(obj.Panel,...
            'Units','Normalized',...
            'Position',[0 0.75 1 0.25],...
            'TitleBarColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleColor',nigeLab.defaults.nigelColors('onsurface'),...
            'Tag','trkPanel');
         obj.Panel.nestObj(obj.trkPanel,'trkPanel');
         
         % Create axes that will display "progress" image
         obj.ScoringTracker_ax = axes(obj.trkPanel.Panel,...
            'Units','Normalized',...
            'Position',[0.025 0.025 0.95 0.5],...
            'Color','none',...
            'NextPlot','replacechildren',...
            'XLim',[0 1],...
            'YLim',[0 1],...
            'XLimMode','manual',...
            'YLimMode','manual',...
            'YDir','reverse',...
            'XTick',[],...
            'YTick',[],...
            'XColor','none',...
            'YColor','none');
         
         obj.ScoringTracker_lab = annotation(obj.trkPanel.Panel, ...
            'textbox',[0.025 0.600 0.95 0.125],...
            'Units', 'Normalized', ...
            'Position', [0.025 0.600 0.95 0.125], ...
            'FontName','DroidSans',...
            'FontSize',13,...
            'FontWeight','bold',...
            'Color','w',...
            'EdgeColor','none',...
            'String','Progress Indicator');
         
         obj.SuccessTracker_lab = annotation(obj.trkPanel.Panel, ...
            'textbox',[0.025 0.825 0.95 0.125],...
            'Units', 'Normalized', ...
            'Position', [0.025 0.825 0.95 0.125], ...
            'FontName','DroidSans',...
            'FontSize',13,...
            'FontWeight','bold',...
            'Color','w',...
            'EdgeColor','none',...
            'String',sprintf('%g Successful Trials',...
                     nansum(obj.Outcome(obj.TrialMask))));
         
         % Make the progress image and an overlay line to indicate
         % current trial.
         obj.ScoringTracker_im = image(obj.ScoringTracker_ax,x,y,C);
         obj.ScoringTracker_line = line(obj.ScoringTracker_ax,[0 0],[0 1],...
            'LineWidth',2,...
            'Color',[0 0.7 0],...
            'LineStyle',':');
         
      end
      
      % Construct the video controller graphics objects for scoring
      function buildVideoControlPanel(obj)
         % BUILDVIDEOCONTROLPANEL  Build the controller panel with
         %  different scoring elements that allow navigation for example to
         %  different Trials or to select different cameras.
         
         % Need a panel to separate this stuff from other
         obj.conPanel = nigeLab.libs.nigelPanel(obj.Panel,...
            'Units','Normalized',...
            'String','Trial Metadata',...
            'TitleFontSize',16,...
            'Position',[0 0 1 0.75]);
         
         % Make text labels for controls
         labs = reshape(obj.varName,numel(obj.varName),1);
         [~,yPos,~,H] = nigeLab.utils.uiMakeLabels(...
            obj.conPanel.Panel,['Trials'; labs]);
         
         % Make controller for switching between trials
         str = cellstr(num2str(obj.Trial(1)));
         % This makes it look nicer:
         str = cellfun(@(x) strrep(x,' ',''),str,'UniformOutput',false);
         
         % Make box for selecting current trial
         obj.trialPop = uicontrol(obj.conPanel.Panel,'Style','popupmenu',...
            'Units','Normalized',...
            'Position',[0.5 yPos(1)-H/2 0.475 H],... % div by 2 to center
            'FontName','Arial',...
            'FontSize',14,...
            'String',str,...
            'UserData',obj.Trial,...
            'Callback',@obj.setTrial);
         
         % Add separator
         annotation(obj.conPanel.Panel,'line',...
            [0.025 0.975],[yPos(1) yPos(1)]+H,...
            'Color',[0.75 0.75 0.75],...
            'LineStyle','-',...
            'LineWidth',3);
         
         % Make "disabled" edit boxes to display trial scoring data
         obj.editArray = nigeLab.utils.uiMakeEditArray(...
            obj.conPanel.Panel,yPos(2:end),...
            'H',H,'TAG',obj.varName);
      end
      
      % Check to see if scoring is complete and return either 'Complete' or
      % 'In Progress' as output string.
      function status = checkProgress(obj)
         % CHECKPROGRESS  Return 'Complete' or 'In Progress' depending on
         %     state of video scoring
         %
         %  status = obj.checkProgress; 
         
         X = obj.getFullDataArray;
         if ~any(any(isnan(X),2),1)
            status = 'Complete';
         else
            status = 'In Progress';
         end  

         
      end
      
      % Find next trial to score, if loading a previous session
      function nextTrial = findNextToScore(obj)
         % FINDNEXTTOSCORE  Helper function to set the current trial index
         %     to the next necessary file to score. Designed to facilitate
         %     continued scoring of a file that was partially scored.
         
         X = obj.getFullDataArray;
         nextTrial = find(any(isnan(X),2),1,'first');
         
         %          % If it can't find any NaN entries, its already been fully scored.
         %          % Default to final trial to indicate that.
         %          if isempty(nextTrial)
         %             nextTrial = obj.N;
         %          end
         
         % 2019-10-15: Change this to initialize to first trial to
         % facilitate appending the 'Stereotyped' tag to trials.
         if isempty(nextTrial)
            nextTrial = 1;
         end
      end
      
      % Get key Block properties for quick reference
      function parseBlockProperties(obj)
         % PARSEBLOCKPROPERTIES  Parse key Block params as properties
         %
         % obj.parseBlockProperties; 
         %  Sets following properties:
         %     * obj.varType
         %     * obj.varName
         %     * obj.fieldName
         %     * obj.TrialBuffer
         %     * obj.ValueShortcutFcn
         %     * obj.ForceToZeroFcn
         
         obj.varType = obj.Block.Pars.Video.VarType;
         obj.varName = obj.Block.Pars.Video.VarsToScore;
         obj.fieldName = obj.Block.Pars.Video.ScoringEventFieldName;
         obj.TrialBuffer = obj.Block.Pars.Video.TrialBuffer;
         obj.ValueShortcutFcn = obj.Block.Pars.Video.ValueShortcutFcn;
         obj.ForceToZeroFcn = obj.Block.Pars.Video.ForceToZeroFcn;
      end
      
      % Get key "Events" properties for quick reference
      function parseEventProperties(obj)
         % PARSEEVENTPROPERTIES  Get key "Events" properties for quick ref
         %
         %  obj.parseEventProperties;
         
         obj.offset = obj.Offset(); % note that obj.Offset is a METHOD
         obj.N = numel(obj.Trial);
         obj.varVal = obj.getCurrentTrialData;
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
   end
   % % % % % % % % % % END METHODS% % %
end