classdef graphicsUpdater < handle
   % GRAPHICSUPDATER   Class to update video scoring UI on frame update.
   %     Listens for changes during video scoring on key events and updates
   %     graphics appropriately.
   %
   %  obj = nigeLab.libs.graphicsUpdater(blockObj);
   
   properties (SetAccess = immutable, GetAccess = public)
      Parent    % Parent figure handle
      Block     % nigeLab.Block class object
   end
   
   % All other properties probably go here
   properties (SetAccess = private, GetAccess = public)
      
      % Keep track of time scalars
      tVid                 % Current video time
      tNeu                 % Current neural time (TDT recording)
      
      % Video properties
      curVidIdx = 1        % Current video index
      videoFile_list       % 'dir' struct of videos
      videoFile            % VideoReader file object
      
      % 'graphics' arg fields from vidInfoObj
      animalName_display   % Text displaying animal name/recording
      neuTime_display      % Text displaying neural data time
      vidTime_display      % Text displaying video time
      image_display        % Graphics object for displaying current frame
      image_displayAx      % Axes container for image display
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
      offset = 0;            % Video offset
      
      timeAtClickedPoint     % Time corresponding to clicked axes point
      
      zoomOffset = 4; % Offset (sec)
      xLim            % Track x-limits for centering video tracking line
   end
   
   properties (GetAccess = public, SetAccess = private, SetObservable = true)
      stream_axes          % Axes containing graphics streams
      vidSelect_listBox    % Video selection listbox
   end
   
   properties (SetAccess = private, GetAccess = private)
      lh = [];  % Listener handle array
   end
   
   % Properties that are set and not changed on class construction
   properties (SetAccess = immutable, GetAccess = private)
      verbose = false; % Set true to allow debug fprintf statements
      StringFcn % Function handle for updating Strings of different varType
   end
   
   events
      axesClick      % Notify of "axes click" event
      offsetChanged  % Notify that alignment offset has changed
      timesChanged   % Notify when times are updated
      trialChanged   % Notify when new "trial" is set
      vidChanged     % Notify when video has changed
   end
   
   methods (Access = public)
      % Class constructor for GRAPHICSUPDATER object
      function obj = graphicsUpdater(blockObj,vidInfoObj,varargin)
         % GRAPHICSUPDATER  Constructor for class to listen to changes
         %  during video scoring and update graphics appropriately.
         %
         %  obj = nigeLab.libs.graphicsUpdater(blockObj,vidInfoObj);
         %  obj = nigeLab.libs.graphicsUpdater(blockObj,vidInfoObj,infoObj);
         %
         %  Must take blockObj and vidInfoObj as first two arguments. After
         %  that, any other "infoObj" that is desired can be passed.
         
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
         obj.parseKeyProps; % Initialize first video, if array
         
         % Build and add listeners to graphics objects
         obj.Parent = vidInfoObj.Panel.Parent; % Set parent Figure handle
         obj.addListeners(vidInfoObj,varargin{:});
         
         obj.setVideo;
      end
      
      % Add listeners for events from different objects tied to UI
      function addListeners(obj,varargin)
         % ADDLISTENERS  Adds listeners to inputs, which are combination of
         %               vidInfoObj and either alignInfoObj or
         %               behaviorInfoObj. 
         %
         %  obj.addListeners(infoObj);
         %  obj.addListeners(infoObj1,infoObj2,...);
         
         if numel(varargin) > 1
            for iV = 1:numel(varargin)
               obj.addListeners(varargin{iV});
            end
            return;
         end
         
         target = varargin{:}; % Should be single element now
         if ~obj.addGraphics(target)
            return; % Skip, if no graphics were added
         end

         switch class(target)
            case 'nigeLab.libs.vidInfo'
               % Add listeners for events from vidInfo object
               obj.lh = [obj.lh; addlistener(target,...
                  'frameChanged',@obj.frameChangedVidCB)];
               obj.lh = [obj.lh; addlistener(target,...
                  'vidChanged',@obj.vidChangedVidCB)];
               obj.lh = [obj.lh; addlistener(target,...
                  'timesChanged',@obj.timesChangedVidCB)];

               % Add listeners to vidInfo object from graphicsUpdater
               obj.lh = [obj.lh; addlistener(obj,...
                  'axesClick',@target.axesClickCB)];
               obj.lh = [obj.lh; addlistener(obj,...
                  'trialChanged',@target.trialChangedCB)];
               obj.lh = [obj.lh; addlistener(obj,...
                  'offsetChanged',@target.offsetChangedCB)];

            case 'nigeLab.libs.behaviorInfo'
               % Add listeners for events from behaviorInfo object
               obj.lh = [obj.lh; addlistener(target,...
                  'closeReq',@obj.closeCB)];
               obj.lh = [obj.lh; addlistener(target,...
                  'saveFile',@obj.saveFileCB)];
               obj.lh = [obj.lh; addlistener(target,...
                  'trialChanged',@obj.trialChangedBehaviorCB)];
               obj.lh = [obj.lh; addlistener(target,...
                  'scoredValueChanged',@obj.scoredValueChangedBehaviorCB)];
               obj.lh = [obj.lh; addlistener(target,...
                  'countIsZero',@obj.updateBehaviorZeroCaseCB)];

            case 'nigeLab.libs.alignInfo'
               % Add listeners for events from alignInfoObj
               obj.lh = [obj.lh; addlistener(target,...
                  'zoomChanged',@obj.zoomChangedAlignCB)];
               obj.lh = [obj.lh; addlistener(target,...
                  'saveFile',@(~,~)obj.saveFileCB)];
               obj.lh = [obj.lh; addlistener(target,...
                  'offsetChanged',@obj.offsetChangedAlignCB)];
               obj.lh = [obj.lh; addlistener(target,...
                  'axesClick',@obj.axesClickAlignCB)];

               % Add listeners to alignInfoObj from  graphicsUpdater
               obj.lh = [obj.lh; addlistener(obj, ...
                  'timesChanged',@target.timesChangedCB)];

            otherwise
               fprintf(1,'%s is not a class supported by nigeLab.libs.graphicsUpdater.\n',...
                  class(target));
         end
      end
      
      % Add graphics object handles to properties
      function flag = addGraphics(obj,graphics)
         % ADDGRAPHICS  Add graphics handle objects to this
         %              nigeLab.libs.graphicsUpdater property list
         %              according to their field names in method
         %              'getGraphics'
         %
         %  flag = obj.addGraphics(graphics); 
         %
         %  graphics  --  Typically, a struct returned by
         %                 (infoObj).getGraphics. Each field contains a
         %                 graphics object handle.
         %
         %  graphics  --  Can also be an (infoObj) such as
         %                 nigeLab.libs.alignInfo or
         %                 nigeLab.libs.behaviorInfo. In this case, it is
         %                 checked for the 'getGraphics' method. If the
         %                 method is present, then it is called and the
         %                 returned result is used to add graphics to the
         %                 nigeLab.libs.graphicsUpdater object.
         %
         %  flag  --  Returns true if able to add graphics; returns false
         %              if no properties were updated.
         
         flag = false;
         
         % Check input
         if ~isstruct(graphics)
            if ismethod(graphics,'getGraphics')
               graphics = graphics.getGraphics;
            else
               warning('No getGraphics method for class: %s',class(graphics));
               return;
            end
         end
         
         % Get graphics objects
         gobj = fieldnames(graphics);
         postSetList = obj.findAttrValue('SetObservable');
         for ii = 1:numel(gobj)
            if ismember(gobj{ii},properties(obj))
               flag = true;
               if ismember(gobj{ii},postSetList)
                  obj.lh = [obj.lh; ...
                     addlistener(obj,gobj{ii},...
                     'PostSet',@obj.postSetEventCB)];
               end
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
            if isvalid(obj.videoFile)
               delete(obj.videoFile);
            end
         end
      end
      
      % Callback whenever there is a 'PostSet' event for properties that
      % are 'SetObservable' (of graphicsUpdater class)
      function postSetEventCB(obj,~,evt)
         % POSTSETEVENTCB  Callback when 'PostSet' event is issued
         %
         %  addlistener(obj,propName,'PostSet',@obj.postSetEventCB);
         %
         %  This causes 'src', which is the graphics object that is a
         %  'SetObservable' property of nigeLab.libs.graphicsUpdater, to
         %  update some related element of 'graphicsUpdater' whenever the
         %  object property is set (typically once, on initialization).
         
         switch evt.Source.Name
            case 'stream_axes'
               obj.xLim = get(obj.stream_axes,'XLim');
               
            case 'vidSelect_listBox'
               set(obj.vidSelect_listBox,'Value',1); 
         
            otherwise
               % Do nothing
               warning('%s is not configured for postSetEventCB although it is SetObservable.',propName);
         end
      end
      
      % Update image object
      function updateImageObject(obj,x,y,C)
         % UPDATEIMAGEOBJECT  Updates the image object data with the actual
         %                    frame (as well as dimensions in x and y)
         %
         %  obj.updateImageObject(x,y,C); Set obj.image_display XData,
         %  YData, and CData properties according to x, y, C values.
         %
         %  obj.updateImageObject(); Use defaults:
         %  x = [0 1]; y = [0 1]; C = obj.videoFile.read(1);
         
         if nargin < 4
            C = obj.videoFile.read(1);
         end
         
         if nargin < 3
            x = [0,1];
         end
         
         if nargin < 2
            y = [0,1];
         end
         
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
               set(obj.stream_axes,'XLim',obj.xLim);
            end
         end
         
      end
      
      % Update associated times when video info times are changed
      function timesChangedVidCB(obj,src,~)
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'timesChangedVidCB');
            fprintf(1,'-->\ttimesChanged event triggered: %s\n',s);
         end 
         
         obj.tVid = src.getTime('vid');
         obj.tNeu = src.getTime('neu');
         notify(obj,'timesChanged');
      end
      
      % Change the actual video file
      function setVideo(obj,idx)
         % SETVIDEO  Set the current VideoReader object
         %
         %  obj.setVideo; Uses value in obj.curVidIdx to set video
         %  obj.setVideo(idx);  Update obj.curVidIdx and set video
         
         if nargin > 1
            obj.curVidIdx = idx;
         end
         
         % Get rid of the old VideoReader (if there is one)
         if ~isempty(obj.videoFile)
            if isvalid(obj.videoFile)
               delete(obj.videoFile);
            end
         end
         
         obj.videoFile = getVideoReader(obj.Block.Videos(obj.curVidIdx).v);
         notify(obj,'vidChanged');
      end
      
      % Change any graphics associated with a different video
      function vidChangedVidCB(obj,src,~)
         % VIDCHANGEDVIDCB  Callback for when vidInfo object issues the
         %                  'vidChanged' event notification.
         %
         %  addlistener(vidInfoObj,'vidChanged',@obj.vidChangedVidCB);
         
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'vidChangedVidCB');
            fprintf(1,'-->\tvidChanged event triggered: %s\n',s);
         end
         
         % Set the video reader and index
         obj.setVideo(src.vidListIdx);
         
         % Update metadata about new video
         FPS = obj.Block.Videos(obj.curVidIdx).v.FS;
         nFrames = obj.Block.Videos(obj.curVidIdx).v.NFrames;
         src.setVideoInfo(FPS,nFrames);
         
         % Update the image (in case dimensions are different)
         obj.updateImageObject();
         
         % Re-initialize video time to zero
         src.setFrame(1,true); % Force to "frame 1"
         obj.updateZoom;
         
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
               obj.Parent.UserData = 'Force';
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
         delete(obj.Parent);
      end
      
      % Change the neural and video times in the videoInfoObject
      function offsetChangedAlignCB(obj,src,~)
         % OFFSETCHANGEDALIGNCB  Issued whenever the 'offsetChanged' event
         %                    notification is issued from the
         %                    'alignInfoObj' (src).
         %
         %  addlistener(alignInfoObj,'moveOffset',...
         %     @(src,e)moveOffsetAlignCB(vidInfoObj));
         %
         %  src  --  alignInfoObj
         
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'offsetChangedAlignCB');
            fprintf(1,'-->\toffsetChanged event triggered: %s\n',s);
         end 
         
         % Change the offset in video object and issue 'timesUpdated'
         % notification.
         obj.offset = src.offset; % Update video offset
         notify(obj,'offsetChanged');  % update the video info object accordingly
         
         % Ticks a flag indicating that when save (alt + s) command is
         % issued, there should be a prompt to exit immediately.
         obj.curState = true; 
      end
      
      % Skip to a point from clicking in axes plot
      function axesClickAlignCB(obj,src,~)
         % AXESCLICKALIGNCB  Skip to a point from clicking on axes plot
         %
         %  addlistener(alignInfoObj,'axesClick',...
         %     @(src,e)obj.axesClickAlignCB(vidInfoObj));
         %
         %  src  --  alignInfoObj
         
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'axesClickAlignCB');
            fprintf(1,'-->\taxesClick event triggered: %s\n',s);
         end 
         
         obj.timeAtClickedPoint = src.timeAtClickedPoint;
         notify(obj,'axesClick');
         
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
      
      %% Functions for behaviorInfo class:
      % Go to the next candidate trial and update graphics to reflect that
      function trialChangedBehaviorCB(obj,src,~)
         % TRIALCHANGEDBEHAVIORCB Go to the next candidate trial and update
         %                        graphics to reflect new values of that
         %                        trial.
         %
         %  trialChangedBehaviorCB(obj,src);
         %
         %  inputs:
         %  obj  --  nigeLab.libs.graphicsUpdater class object
         %  src  --  "Source" is a nigeLab.libs.behaviorInfo class object. 
         %     --> Makes use of src.stepIdx method to iterate on each
         %         variable in src.varVal and update the corresponding
         %         graphics for that variable.
         %
         %  Updates obj.tVid based on src.Trial(src.cur).
         
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.graphicsUpdater',...
               'trialChangedBehaviorCB');
            fprintf(1,'-->\ttrialChanged event triggered: %s\n',s);
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
         obj.tVid = src.Trial(src.cur);
         
         % Update the current video frame
         notify(obj,'trialChanged');
         
      end
      
      % Update graphics to reflect updated scoring
      function scoredValueChangedBehaviorCB(obj,src,~)
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
         obj.offset = src.offset;
         
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
        
         if obj.varState(idx)
            obj.editArray_display{idx}.String = str;
         else
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
   
   methods (Access = private)
      function cl_out = findAttrValue(obj,attrName,attrValue)
         % FINDATTRVALUE  Find properties given an attribute value
         %
         %  cl_out = obj.findAttrValue(attrName);
         %  cl_out = obj.findAttrValue(attrName,attrValue);
         %
         %  attrName : e.g. 'SetAccess' etc (property attributes)
         %  attrValue : (optional) e.g. 'private' or 'public' etc
         %  Adapted from TheMathworks getting-information-about-properties
         
         if nargin < 3
            attrValue = '';
         end
         
         if ischar(obj)
            mc = meta.class.fromName(obj);
         elseif isobject(obj)
            mc = metaclass(obj);
         end
         ii = 0; numb_props = length(mc.PropertyList);
         cl_array = cell(1,numb_props);
         for  c = 1:numb_props
            mp = mc.PropertyList(c);
            if isempty (findprop(mp,attrName))
               error('Not a valid attribute name')
            end
            val = mp.(attrName);
            if val
               if islogical(val) || strcmp(attrValue,val)
                  ii = ii + 1;
                  cl_array(ii) = {mp.Name};
               end
            end
         end
         cl_out = cl_array(1:ii);
      end
   end
end