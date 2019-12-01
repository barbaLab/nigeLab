classdef graphicsUpdater < handle
   % GRAPHICSUPDATER   Class to update video scoring UI on frame update.
   %     Listens for changes during video scoring on key events and updates
   %     graphics appropriately.
   %
   %  obj = nigeLab.libs.graphicsUpdater(blockObj);
   
   % All other properties probably go here
   properties (SetAccess = private, GetAccess = public)
      parent % figure handle
      
      % Keep track of time scalars
      tVid                 % Current video time
      tNeu                 % Current neural time (TDT recording)
      
      % Video properties
      videoFile_list       % 'dir' struct of videos
      videoFile            % VideoReader file object
      
      % 'graphics' arg fields from vidInfoObj
      animalName_display   % Text displaying animal name/recording
      neuTime_display      % Text displaying neural data time
      vidTime_display      % Text displaying video time
      image_display        % Graphics object for displaying current frame
      image_displayAx      % Axes container for image display
      vidSelect_listBox    % Video selection listbox
      hud_panel            % Panel for heads-up-display (HUD)
      
      % 'graphics' arg fields for alignInfoObj:
      vidTime_line         % Line indicating video time
      alignment_panel      % Panel containing graphics objs for alignment
      
      % 'graphics' arg fields for behaviorInfoObj:
      trialTracker_display          % Graphic for displaying trial progress
      trialTracker_displayOverlay   % Graphic for tracking current trial
      trialTracker_label            % Graphic label for progress tracking
      successTracker_label          % Graphic label for success tracking
      trialPopup_display            % Graphic for selecting current trial
      editArray_display             % Array of edit box display graphics
      
      
      % Information variables for video scoring:
      % State variables for updating the "progress tracker" for each trial
      varVal                 % Current values for variables for this trial
      varState               % False - variable not scored for this trial
      varName                % List of variables that may be updated
      curState = false;      % Current "state" of scoring (is it finished?)
      nTotal                 % Total number of trials
      vidOffset = 0;         % Video offset
      
      % Constant for alignment tracking:
      zoomOffset = 4; % Offset (sec)
      xLim            % Track x-limits for centering video tracking line
   end
   
   properties (SetAccess = private, GetAccess = private)
      lh = [];  % Listener handle array
   end
   
   % Properties that are set and not changed on class construction
   properties (SetAccess = immutable, GetAccess = private)
      verbose = false; % Set true to allow debug fprintf statements
      Block     % nigeLab.Block class object
      StringFcn % Function handle for updating Strings of different varType
   end
   
   
   methods (Access = public)
      % Class constructor for GRAPHICSUPDATER object
      function obj = graphicsUpdater(blockObj)
         % GRAPHICSUPDATER  Constructor for class to listen to changes
         %  during video scoring and update graphics appropriately.
         %
         %  obj = nigeLab.libs.graphicsUpdater(blockObj);
         
         % This is really the key thing to set on construction
         if ~isa(blockObj,'nigeLab.Block')
            error('First input argument must be class nigeLab.Block');
         end
         obj.Block = blockObj;
         
         % This function can be changed for ad hoc setups. The parameter
         % should be modified in nigeLab.defaults.Video, pointing to a
         % different corresponding function handle for a new function
         % similar to the default one residing in nigeLab.workflow.
         obj.StringFcn = obj.Block.Pars.Video.VideoScoringStringsFcn;
         
         % Set a few properties derived from blockObj for faster reference
         obj.parseKeyProps;

         
      end
      
      % Add listeners for events from different objects tied to UI
      function addListeners(obj,vidInfo_obj,varargin)
         % Define parent handle on constructor
         obj.parent = vidInfo_obj.Panel.Parent;
         
         % Add listeners for event notifications from video object
         obj.lh = [obj.lh; addlistener(vidInfo_obj,...
            'frameChanged',@obj.frameChangedVidCB)];
         obj.lh = [obj.lh; addlistener(vidInfo_obj,...
            'vidChanged',@obj.vidChangedVidCB)];
         
         % Add listeners for event notifications from associated
         % information tracking object
         for iV = 1:numel(varargin)
            switch class(varargin{iV})
               case 'nigeLab.libs.behaviorInfo'
                  obj.lh = [obj.lh; addlistener(varargin{iV},...
                     'closeReq',@obj.closeCB)];
                  obj.lh = [obj.lh; addlistener(varargin{iV},...
                     'saveFile',@(~,~)obj.saveFileCB)];
                  obj.lh = [obj.lh; addlistener(varargin{iV},...
                     'newTrial',@(o,e) obj.newTrialBehaviorCB(o,e,vidInfo_obj))];
                  obj.lh = [obj.lh; addlistener(varargin{iV},...
                     'update',@obj.updateBehaviorCB)];
                  obj.lh = [obj.lh; addlistener(varargin{iV},...
                     'countIsZero',@obj.updateBehaviorZeroCaseCB)];
                  obj.lh = [obj.lh; addlistener(vidInfo_obj,...
                     'offsetChanged',@obj.offsetChangedBehaviorCB)];
                  
               case 'nigeLab.libs.alignInfo'
                  obj.lh = [obj.lh; addlistener(varargin{iV},...
                     'zoomChanged',@obj.zoomChangedAlignCB)];
                  obj.lh = [obj.lh; addlistener(varargin{iV},...
                     'saveFile',@(~,~)obj.saveFileCB)];
                  obj.lh = [obj.lh; addlistener(varargin{iV},...
                     'moveOffset',@(o,e) obj.moveOffsetAlignCB(o,e,vidInfo_obj))];
                  obj.lh = [obj.lh; addlistener(varargin{iV},...
                     'axesClick',@(o,e) obj.axesClickAlignCB(o,e,vidInfo_obj))];
                  obj.lh = [obj.lh; addlistener(vidInfo_obj,...
                     'timesUpdated',@obj.timesUpdateAlignCB)];
                  
               otherwise
                  fprintf(1,'%s is not a class supported by vidUpdateListener.\n',...
                     class(varargin{iV}));
            end
         end
      end
      
      % Add graphics object handles to properties
      function addGraphics(obj,graphics)
         % Get graphics objects
         gobj = fieldnames(graphics);
         for ii = 1:numel(gobj)
            if ismember(gobj{ii},properties(obj))
               obj.(gobj{ii}) = graphics.(gobj{ii});
               if obj.verbose
                  fprintf(1,'->\tAdded %s to listener object.\n',gobj{ii});
               end
            end
         end
      end
      
      % Clean up listener handles and videoreader object if deleted
      function delete(obj)
         % DELETE  Delete this object along with its listeners and video
         %
         %  delete(obj);  Delete this object
         
         for i = 1:numel(obj.lh)
            delete(obj.lh(i));
         end
         
         if ~isempty(obj.videoFile)
            delete(obj.videoFile);
         end
      end
      
      % Update image object
      function updateImageObject(obj,x,y,C)
         set(obj.image_display,'XData',x,'YData',y,'CData',C);
      end
      
      %% Functions for vidInfo class:
      % Change any graphics associated with a frame update
      function frameChangedVidCB(obj,src,~)
         % FRAMECHANGEDVIDCB  Callback any time that a video frame is
         %                    changed. Source (src) is nigeLab.libs.vidInfo
         %                    object. 
         
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'frameChangedVidCB');
            fprintf(1,'-->\tframeChanged event triggered: %s\n',s);
            fprintf(1,'\t-->\tsource class: %s\n',class(src));
         end
         neu_t = src.getTime('neu');
         vid_t = src.getTime('vid');
         
         set(obj.neuTime_display,'String',...
            sprintf('Neural Time: %0.3f',neu_t));
         set(obj.vidTime_display,'String',...
            sprintf('Video Time: %0.3f',vid_t));
         set(obj.image_display,'CData',...
            obj.videoFile.read(src.frame));
         
         obj.tNeu = neu_t;
         obj.tVid = vid_t;
         
         % If vidTime_line is not empty, that means there is the alignment
         % axis plot so we should update that too:
         if ~isempty(obj.vidTime_line)
            set(obj.vidTime_line,'XData',ones(1,2) * vid_t);
            
            % Fix axis limits
            if (vid_t >= obj.xLim(2)) || (vid_t <= obj.xLim(1))
               obj.updateZoom;
               set(obj.vidTime_line.Parent,'XLim',obj.xLim);
            end
         end
         
      end
      
      % Change any graphics associated with a different video
      function vidChangedVidCB(obj,src,~)
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'vidChangedVidCB');
            fprintf(1,'-->\tvidChanged event triggered: %s\n',s);
         end
         
         % Get the file name information
         path = obj.videoFile_list(src.vidListIdx).folder;
         fname = obj.videoFile_list(src.vidListIdx).name;
         vfname = fullfile(path,fname);
         
         % Read the actual video file
         obj.setVideo(vfname);
         
         % Update metadata about new video
         FPS=obj.videoFile.FrameRate;
         nFrames=obj.videoFile.NumberOfFrames;
         src.setVideoInfo(FPS,nFrames);
         
         % Update the image (in case dimensions are different)
         C = obj.videoFile.read(1);
         x = [0,1];
         y = [0,1];
         obj.updateImageObject(x,y,C);
         
         % Re-initialize video time to zero
         src.setFrame(1,true); % Force to "frame 1"
         obj.updateZoom;
         
      end
      
      % Change the actual video file
      function setVideo(obj,vfname)
         delete(obj.videoFile);
         if obj.verbose
            tic;
            [~,name,ext] = fileparts(vfname);
            fprintf(1,...
               'Please wait, loading %s.%s (can be a minute or two)...',...
               name,ext);
         end
         obj.videoFile = VideoReader(vfname);
         if obj.verbose
            fprintf(1,'complete.\n');
            toc;
         end
      end
      
      %% Functions for alignInfo class:
      % Change color of the animal name display
      function saveFileCB(obj) 
         % SAVEFILECB  Callback for when SAVEFILE event is issued. 
         %
         %  obj.saveFileCB
         
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'saveFileCB');
            fprintf(1,'-->\tsaveFile event triggered: %s\n',s);
         end
         
         if ~isempty(obj.animalName_display)
            obj.animalName_display.Color.TitleText = ...
               nigeLab.defaults.nigelColors('primary');
            obj.animalName_display.Color.TitleBar = ...
               nigeLab.defaults.nigelColors('background');
         end
         obj.hud_panel.Color.TitleBar = ...
               nigeLab.defaults.nigelColors('primary');
         obj.hud_panel.Color.TitleText = ...
               nigeLab.defaults.nigelColors('background');
         
         if obj.curState
            str = questdlg('Save successful. Exit?','Close Prompt',...
               'Yes','No','Yes');
            if strcmpi(str,'Yes')
               obj.parent.UserData = 'Force';
               closeCB(obj);
            end
         end
      end
      
      % Close everything if verified
      function closeCB(obj,~,~)
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'closeCB');
            fprintf(1,'-->\tcloseReq event triggered: %s\n',s);
         end 
         delete(obj.parent);
      end
      
      % Change the neural and video times in the videoInfoObject
      function moveOffsetAlignCB(obj,src,~,v)
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'moveOffsetAlignCB');
            fprintf(1,'-->\tmoveOffset event triggered: %s\n',s);
         end 
         
         v.setOffset(src.alignLag);
         v.updateTime;
         obj.frameChangedVidCB(v,nan);
         obj.curState = true; % Now, when save is done, prompt to exit
      end
      
      % Skip to a point from clicking in axes plot
      function axesClickAlignCB(~,src,~,v)
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'axesClickAlignCB');
            fprintf(1,'-->\taxesClick event triggered: %s\n',s);
         end 
         
         v.setVidTime(src.cp);
      end
      
      % Update the known axes limits
      function zoomChangedAlignCB(obj,src,~)
         % ZOOMCHANGEDALIGNCB  Callback issued when ZOOM changes
         %
         %  zoomChangedAlignCB(obj,src,nan);
         
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'zoomChangedAlignCB');
            fprintf(1,'-->\tzoomChanged event triggered: %s\n',s);
         end         
         obj.xLim = src.curAxLim;
      end
      
      % Update associated times when video info times are changed
      function timesUpdateAlignCB(~,src,~,a)
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'timesUpdatedAlignCB');
            fprintf(1,'-->\ttimesUpdated event triggered: %s\n',s);
         end 
         
         a.setVidTime(src.tVid);
         a.setNeuTime(src.tNeu);
      end
      
      %% Functions for behaviorInfo class:
      % Go to the next candidate trial and update graphics to reflect that
      function newTrialBehaviorCB(obj,src,~,v)
         % NEWTRIALBEHAVIORCB  Go to the next candidate trial and update
         %                     graphics to reflect new values of that
         %                     trial.
         %
         %  newTrialBehaviorCB(obj,src,NaN,v);
         %
         %  inputs:
         %  obj  --  nigeLab.libs.graphicsUpdater class object
         %  src  --  "Source" is a nigeLab.libs.behaviorInfo class object. 
         %     --> Makes use of src.stepIdx method to iterate on each
         %         variable in src.varVal and update the corresponding
         %         graphics for that variable.
         %  -- unused arg -- (due to Matlab eventdata callback syntax)
         %  v  --  nigeLab.libs.vidInfo class object, which is referenced
         %           to set the video time at the end of everything.
         
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'newTrialBehaviorCB');
            fprintf(1,'-->\tnewTrial event triggered: %s\n',s);
            fprintf(1,'\t-->\tsource class is %s\n',class(src));
         end
         
         for ii = 1:numel(obj.varState)
            obj.varState(ii) = ~isnan(src.varVal(ii));
         end
         
         % Increment through the variables (columns of behaviorData)
         src.idx = 0; % Set the index to start at 1
         while src.stepIdx
            % For each variable get the appropriate corresponding value,
            % turn it into a string, and update the graphics with that:
            val = obj.translateMarkedValue(src);
            str = obj.getGraphicString(src,val);
            obj.updateBehaviorEditBox(src.idx,str);
         end
         
         % Update graphics pertraining to which trial it is
         obj.updateBehaviorTrialPopup(src.cur);
         obj.updateCurrentBehaviorTrial(src.cur);
         
         % Update graphics pertaining to scoring progress
         obj.updateBehaviorTracker(src.cur,src.N,nansum(src.Outcome));
         
         % Update the current video frame
         v.setFrameFromTime(src.Trial(src.cur)); % already in "vid" time
         
      end
      
      % Update graphics to reflect updated scoring
      function updateBehaviorCB(obj,src,~)
         % UPDATEBEHAVIORCB  Refresh graphics to reflect updated scoring
         %
         %  updateBehaviorCB(obj,src,~);
         %  inputs:
         %  obj  --  nigeLab.libs.graphicUpdater class object
         %  src  --  "Source" is nigeLab.libs.behaviorInfo class object
         
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'updateBehaviorCB');
            fprintf(1,'-->\tupdate event triggered: %s\n',s);
            fprintf(1,'\t-->\tsource is class: %s\n',class(src));
         end
         
         % Only update a single (notified) value
         val = src.varVal(src.idx);
         
         % Decide if the state is changed and put new value into the table
         % which will be saved as an output.
         [obj.varState(src.idx),obj.varVal(src.idx)] = src.addRemoveValue(val);
         str = obj.getGraphicString(src,val);
         
         % Update graphics pertaining to this variable
         obj.updateBehaviorEditBox(src.idx,str);
         
         % Update graphics pertaining to scoring progress
         obj.updateBehaviorTracker(src.cur,src.N,nansum(src.Outcome));
      end
      
      % Update graphics to reflect update to behaviorData for ZERO count
      function updateBehaviorZeroCaseCB(obj,src,~)
         % UPDATEBEHAVIORZEROCASECB  Update graphics if ZERO count
         
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'updateBehaviorZeroCaseCB');
            fprintf(1,'-->\tcountIsZero event triggered: %s\n',s);
         end
         
         % Decide if the state is changed and put new value into the table
         % which will be saved as an output.
         obj.varState(src.idx) = src.forceZeroValue;
         str = obj.getGraphicString(src,zeros(size(src.idx)));
         
         % Update graphics pertaining to this variable
         if iscell(str)
            for i = 1:numel(str)
               obj.updateBehaviorEditBox(src.idx(i),str{i});
            end
         else
            obj.updateBehaviorEditBox(src.idx,str);
         end
         
         % Update graphics pertaining to scoring progress
         obj.updateBehaviorTracker(src.cur,src.N,nansum(src.Outcome));
      end
      
      % Update the graphics to reflect to new video offset
      function offsetChangedBehaviorCB(obj,src,~)
         % OFFSETCHANGEDBEHAVIORCB  If 'VideoStart' (offset between neural
         %                          data and first video frame time) is
         %                          changed, this callback should trigger.
         %
         %  offsetChangedBehaviorCB(obj,src,~);
         %  --> src is nigeLab.libs.vidInfo object
         %
         %  Any time the offset between video and neural times changes
         %  (e.g. a different video is loaded), then this should fire; any
         %  graphics that rely upon the offset (e.g. lists of event times)
         %  should change to reflect the new offset value.
         
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'offsetChangedBehaviorCB');
            fprintf(1,'-->\toffsetChanged event triggered: %s\n',s);
         end
         
         % Main thing: update the new video offset
         obj.vidOffset = src.videoStart;
         
         % Update the listbox with all the trial times
         tVideo = src.Trial;
         tNeural = src.toNeuTime(tVideo);
         str = cellstr(num2str(tNeural));
         
         % This makes it look nicer:
         str = cellfun(@(x) strrep(x,' ',''),str,'UniformOutput',false);
         
         % Update the popupbox list of times to reflect neural times
         obj.trialPopup_display.String = str;
      end
      
      % Update the tracker image by reflecting the "state" using red or
      % blue coloring in an image
      function updateBehaviorTracker(obj,curTrial,n,nSuccessful)
         % UPDATEBEHAVIORTRACKER  Updates tracking graphic by changing
         %                        current-trial "tile" from red to blue or
         %                        blue to red depending on the completion
         %                        state of scoring that trial.
         %
         %  obj.updateBehaviorTracker(curTrial,n,nSuccessful);
         %
         %  inputs:
         %  curTrial -- current trial index
         %  n -- total number of trials
         %  nSuccessful -- total number of "successful" trials
         
         if nargin < 4
            nSuccessful = 0;
         end
         
         if ~any(~obj.varState)
            obj.trialTracker_display.CData(1,curTrial,:)=[0 0 1];
         else
            obj.trialTracker_display.CData(1,curTrial,:)=[1 0 0];
         end
         
         tr = curTrial-1 + ~any(~obj.varState);
         obj.nTotal = n;
         obj.trialTracker_label.String = sprintf(...
            'Progress Indicator      %g/%g',...
            tr,...
            obj.nTotal);       
         
         if nargin < 4
            if nSuccessful == 1
               obj.successTracker_label.String = '1 Successful Retrieval';
            else
               obj.successTracker_label.String = sprintf(...
                  '%g Successful Retrievals',nSuccessful);
            end  
         else % If no "success" info is given, just leave it blank
            obj.successTracker_label.String = '';
         end
         
         if tr == n
            obj.hud_panel.Color.TitleBar = ...
               nigeLab.defaults.nigelColors('background');
            obj.hud_panel.Color.TitleText = ...
               nigeLab.defaults.nigelColors('yellow');
            
            obj.trialTracker_label.Color =  ...
               nigeLab.defaults.nigelColors('yellow');
            obj.successTracker_label.Color =  ...
               nigeLab.defaults.nigelColors('yellow');
            obj.curState = true;
         else
            obj.hud_panel.Color.TitleBar = ...
               nigeLab.defaults.nigelColors('surface');
            obj.hud_panel.Color.TitleText =  ...
               nigeLab.defaults.nigelColors('red');
            
            obj.trialTracker_label.Color =  ...
               nigeLab.defaults.nigelColors('white');
            obj.successTracker_label.Color =  ...
               nigeLab.defaults.nigelColors('white');
            obj.curState = false;
         end
         
      end
      
      % Update the tracker to reflect current trial
      function updateCurrentBehaviorTrial(obj,curTrial)
         % UPDATECURRENTBEHAVIORTRIAL   Update tracking for current trial
         %
         %  obj.updateCurrentBehaviorTrial(curTrial); 
         %  --> Moves the "tracker" (line) along the trial tracker overlay.
         
         if isnan(curTrial) || isinf(curTrial)
            error('Current trial is either NaN or inf, which should not happen.');
         end
                  
         nEdges = size(obj.trialTracker_display.CData,2)+1;
         if nEdges > 2
            x = linspace(0,1,nEdges);
            x = x(2:end) - mode(diff(x))/2;
            obj.trialTracker_displayOverlay.XData = [x(curTrial),x(curTrial)];
         else
            obj.trialTracker_displayOverlay.XData = [nan, nan];
         end
      end
      
      % Update the graphics object associated with grasp time
      function updateBehaviorEditBox(obj,idx,str)
         % UPDATEBEHAVIOREDITBOX  Updates the graphics object associated
         %     with different behavioral scoring variables.
         
%          arrayIdx = idx - 1; % Account for "Trials" element
         
         if obj.varState(idx)
%             obj.editArray_display{arrayIdx}.String = str;
            obj.editArray_display{idx}.String = str;
         else
%             obj.editArray_display{arrayIdx}.String = 'N/A';
            obj.editArray_display{idx}.String = 'N/A';
         end
      end
      
      % Update the graphics object associated with trial button
      function updateBehaviorTrialPopup(obj,curTrial)
         obj.trialPopup_display.Value = curTrial;
      end
      
   end
   
   methods (Access = public)
      % Return the appropriate string to put in controller edit box
      function str = getGraphicString(obj,src,val)
         % GETGRAPHICSSTRING Return the appropriate string for edit box
         %
         %  str = obj.getGraphicString(src,val);  Returns string based on
         %                                         object passed as "src"
         %                                         and the value passed as
         %                                         "val".
         %
         %  The source ("src") should have these properties:
         %     --> src.varType : Array of integers indicating variable type
         %     --> src.idx : Index of what is the current variable being
         %                    updated
         
         if numel(src.idx) > 1
            str = cell(size(src.idx));
            for iIdx = 1:numel(src.idx)
               str{iIdx} = obj.StringFcn(obj,src.varType(src.idx(iIdx)),val(iIdx));
            end
            return;
         else
            str = obj.StringFcn(obj,src.varType(src.idx),val);
            return;
         end
         
         
      end
      
      % Set key property values for quick reference from obj.Block
      function parseKeyProps(obj)
         % PARSEKEYPROPS  Gets key properties from obj.Block for reference
         %
         %  obj.parseKeyProps;  Sets the following properties for obj:
         %                       --> obj.videoFile_list
         %                       --> obj.varName
         %                       --> obj.varState
         
         obj.videoFile_list = getVid_F(obj.Block.Videos.v);
         obj.varName = obj.Block.Pars.Video.VarsToScore;
         obj.varState = false(1,numel(obj.varName));
      end
      
      % Returns the value corresponding to what was just updated
      function val = translateMarkedValue(~,src)
         % TRANSLATEMARKEDVALUE Return the value from this trial for the
         %  current variable, which is determined by which "hotkey" was
         %  pressed.
         %
         %  This should be used as a callback for an event listener, so
         %  that src should have the properties: 
         %  * src.varVal -->  Array of variable values from current trial
         %  * src.idx  -->    Index of "current" variable to update
         
         val = src.varVal(src.idx);
      end
      
      % Convert "neural-time" to "video-time"
      function tVid = toVidTime(obj,tNeu)
         % TOVIDTIME  Convert the time (with respect to neural record) into
         %     time with respect to the video record.
         %
         %  tVid = obj.toVidTime(tNeu); Converts tNeu to tVid by adding the
         %                                computed difference between tVid
         %                                and tNeu (tVid - tNeu) to tNeu.
         
         tVid = tNeu + (obj.tVid - obj.tNeu); % Gets the offset
      end
      
      % Convert "video-time" to "neural-time"
      function tNeu = toNeuTime(obj,tVid)
         % TONEUTIME  Convert "video-time" to "neural-time"
         %
         %  tNeu = obj.toNeuTime(tVid); Converts tVid to tNeu by adding the
         %                                computed difference between tNeu
         %                                and tVid (tNeu - tVid) to tVid.
         
         tNeu = tVid + (obj.tNeu - obj.tVid);
      end
      
      % Set the zoom on axes by changing Axes XLim by some increment
      function updateZoom(obj)
         % UPDATEZOOM  Set zoom on axes by changing Axes XLim by some
         %     increment. obj.zoomOffset is set elsewhere, but that is whta
         %     determines this change.
         %
         %  obj.updateZoom; Sets the zoom by changing Axes XLim
         
         obj.xLim = [obj.tVid - obj.zoomOffset, obj.tVid + obj.zoomOffset];
      end
   end
end