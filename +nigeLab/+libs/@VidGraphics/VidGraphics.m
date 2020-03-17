classdef VidGraphics < matlab.mixin.SetGet
   % VIDGRAPHICS Constructor for nigeLab.libs.VidGraphics object
   %
   %  vidGraphicsObj = nigeLab.libs.VidGraphics(blockObj,nigelPanelObj);
   %  vidGraphicsObj = nigeLab.libs.VidGraphics(___,initMode);
   %
   %  Inputs:
   %  blockObj -- nigeLab.Block object
   %
   %  nigelPanelObj -- nigeLab.libs.nigelPanel "container" class
   %  --> If not provided,
   %
   %  initMode -- 'score' (default) or 'align'
   %     * Influences how initialization works, based on the intended video
   %       displaying purposes. Currently, the only configured option is
   %       'score', which probably ends up handling most elements of 'align'
   
   % % % PROPERTIES % % % % % % % % % %
   % CONSTANT,PUBLIC
   properties (Constant,Access=public)
      N_BUFFER_FRAMES   (1,1) double = 3  % Should be odd integer
   end
   
   % TRANSIENT,PUBLIC
   properties (Transient,Access=public)
      Block                               % nigeLab.Block class object handle
      Figure                              % "parent" figure handle
      Panel                               % nigeLab.libs.nigelPanel container for display graphics
      PlayTimer           timer           % Video playback timer
      TimeAxes                            % nigeLab.libs.TimeScrollerAxes
   end
   
   % ABORTSET,SETOBSERVABLE,PUBLIC
   properties (AbortSet,SetObservable,Access=public)
      FrameIndex    (1,1) double = 1      % Frame currently viewed
   end
   
   % PUBLIC
   properties (Access=public)
      ROISet        (1,1) logical = false % Has ROI been set?
   end
   
   % PROTECTED
   properties (Access=protected)
      AnimalName_                char = ''         % Name of animal used in video
      BuffSize_                                    % Current "buffer size" (scalar; depends on ROI)
      BufferedFrames_            double            % Vector list of frame indices corresponding to C_ elements
      C_                                           % Image "Buffer" (N_BUFFER_FRAMES x nRows x nCols x 3)
      FrameIndexFlagFcn_                           % Function handle for buffering
      NeuTime_             (1,1) double  = 0       % Store for current neural time
      SeriesList_                                  % nigeLab.libs.VideosFieldType series for this Source
      SeriesTime_          (1,1) double  = 0       % Container for `SeriesTime`
      VideoName_                 cell              % Cell array of video names
      VideoSourceList_           cell              % Cell array of elements in .VidSelectListBox
      VideoSourceIndex_    (1,1) double = 1        % Current index to .VidSelectListBox
   end
   
   % ABORTSET,HIDDEN,PUBLIC
   properties (AbortSet,Hidden,Access=public)
      SeriesIndex_               double  = 1       % Index of video within "source" series
      VideoSource_               char              % Current video source "store"
   end
   
   % HIDDEN,PUBLIC
   properties (Hidden,Access=public)
      FrameIndex_          (1,1) double  = 1       % Store for previous FrameIndex_ value
      NeedsUpdate_         (1,1) logical = false   % Flag for if .VFR.CurrentTime needs update
      NewVideo_            (1,1) logical = false   % Flag for if new video has been opened
      ScoringField_                                % Initialize
      iRow_                                        % Indexing of rows for image     (vector)
      iCol_                                        % Indexing of columns for image  (vector)
      iCur_                                        % Current "buffered frame index" (scalar)
   end
   
   % ABORTSET,DEPENDENT,PUBLIC
   properties (AbortSet,Dependent,Access=public)
      SeriesTime  (1,1) double = 0     % Current "series"-related time for video series
      VideoIndex  (1,1) double = 1     % Index of current video in use (from array)
      VideoOffset (1,1) double = 0     % Offset relative to start of video-series
      VideoName         char           % Name of currently-selected video
      VideoSource       char           % 'View' for camera for video(s) under consideration
   end
   
   % DEPENDENT,PUBLIC
   properties (Dependent,Access=public)
      FPS         (1,1) double = 60    % Frames per second
      FrameTime   (1,1) double = 0     % Timestamp of current frame
      GrossOffset (1,1) double = 0     % NeuOffset + VideoOffset
      NeuOffset   (1,1) double = 0     % Offset from video to neural data
      NumFrames   (1,1) double         % Maximum number of frames
      SeriesIndex (1,1) double = 1     % Movie index within series
      TrialOffset (1,1) double = 0     % "Specific" trial/camera offset for individual trial
      NeuTime     (1,1) double = 0     % Current Neural time
      TimerPeriod (1,1) double = 0.034 % Time between video play timer refresh requests
      VideoSourceIndex  double = 1     % Current video camera series "source" camera index
      Verbose     (1,1) logical= true  % Display extra text to command window for debug?
      XImScale    (1,1) double = 1     % Scaling for Image: X-dimension
      XImOffset   (1,1) double = 0     % Offset for Image: X-dimension
      YImScale    (1,1) double = 1     % Scaling for Image: Y-dimension
      YImOffset   (1,1) double = 0     % Scaling for Image: Y-dimension
   end
   
   % HIDDEN,TRANSIENT,PUBLIC
   properties (Hidden,Transient,Access=public)
      Listeners      % Event.Listeners
   end
   
   % TRANSIENT,DEPENDENT,PUBLIC
   properties (Transient,Dependent,Access=public)
      VFR         VideoReader    % Video File reader
      Video                      % nigeLab.libs.VideosFieldType object
   end
   
   % TRANSIENT,PUBLIC/RESTRICTED:nigeLab.libs.TimeScrollerAxes,behaviorInfo
   properties (Transient,GetAccess=public,...
         SetAccess={?nigeLab.libs.TimeScrollerAxes,?nigeLab.libs.behaviorInfo})
      AnimalNameLabel   % matlab.graphics.primitive.Text   Shows name of animal/block
      AssignROIMenu     % Menu item for assigning ROI
      DataLabel         % matlab.graphics.primitive.Text   Shows trial #
      ExcludeVideoMenuItem % Menu item for assigning false value to video mask
      GroupOffsetMenu   % Menu item for assigning offset to "group" of videos (all .Videos)
      Menu              % uicontextmenu for interacting with current image frame
      NeuralTimeLabel   % matlab.graphics.primitive.Text   Shows Neural timestamp of displayed frame
      TimeDisp          % matlab.graphics.axis.Axes Axes   Holds NeuralTimeLabel and VidTimeLabel
      TrialMaskMenu     % Menu item for assigning trial "mask" status
      TrialOffsetLabel  % matlab.ui.control.UIControl      Shows offset for current trial
      UseVideoMenuItem  % Menu item for assigning "true" value to video mask
      VidImAx           % matlab.graphics.axis.Axes        Holds VidIm
      VidIm             % matlab.graphics.primitive.Image  Image of current video frame
      VideoMaskIndicator% Image superimposed on video image axes
      VidMetaDisp       % matlab.graphics.axis.Axes        Holds  AnimalNameLabel and DataLabel
      VidSelectListBox  % matlab.ui.control.UIControl      Listbox for selecting specific video
      VidTimeLabel      % matlab.graphics.primitive.Text   Shows current video frame timestamp (from series)
   end
   
   % ABORTSET,DEPENDENT,HIDDEN,TRANSIENT,PUBLIC
   properties (AbortSet,Dependent,Hidden,Transient,Access=public)
      SeriesList                 % Videos related to this video
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % RESTRICTED:{nigeLab.Block,nigeLab.nigelObj}
   methods (Access={?nigeLab.Block,?nigeLab.nigelObj})
      % Create the video information object
      function obj = VidGraphics(blockObj,nigelPanelObj,initMode)
         % VIDGRAPHICS  Constructor for nigeLab.libs.VidGraphics object
         %
         %  obj = nigeLab.libs.vidInfo(blockObj);
         %  obj = nigeLab.libs.vidInfo(blockObj,nigelPanelObj);
         %  obj = nigeLab.libs.vidInfo(blockObj,nigelPanelObj,initMode);
         %
         %  Inputs:
         %  blockObj -- nigeLab.Block class object that has all the
         %              event-related and video-related behavior linked to
         %              it.
         %  nigelPanelObj -- nigeLab.libs.nigelPanel custom panel class
         %                    that acts as a container for all graphics
         %                    associated with vidInfo object. If this is
         %                    not specified, a default nigelPanel container
         %                    is created that fills the current figure (or
         %                    creates a figure and fills it if there is no
         %                    current figure).
         %
         %  initMode -- 'score' (default) or 'align'
         %     * Influences how initialization works, based on the purpose
         %     it will be used for
         
         % Allow empty constructor etc.
         if nargin < 1
            obj = nigeLab.libs.VidGraphics.empty();
            return;
         elseif isnumeric(blockObj)
            dims = blockObj;
            if numel(dims) < 2
               dims = [zeros(1,2-numel(dims)),dims];
            end
            obj = repmat(obj,dims);
            return;
         end
         
         % Require that first argument is `nigeLab.Block`
         if ~isa(blockObj,'nigeLab.Block')
            error(['nigeLab:' mfilename ':BadClass'],...
               '[VIDINFO]: First input argument must be class nigeLab.Block');
         end
         obj.Block = blockObj;
         obj.ScoringField_ = blockObj.ScoringField;
         
         if nargin < 2
            nigelPanelObj = nigeLab.libs.nigelPanel(...
               'Units','Normalized',...
               'Tag','MainPanel',...
               'Position',[0 0 1 1],...
               'Scrollable','off');
         end
         obj.Panel = nigelPanelObj;
         
         if nargin < 3
            initMode = 'score';
         end
         
         obj.SeriesList_ = FromSame(obj.Block.Videos,...
            obj.Block.Videos(obj.VideoIndex).Source);
         if obj.Block.HasVideoTrials
            obj.SeriesIndex_ = obj.Block.TrialIndex;
         else
            obj.SeriesIndex_ = find(obj.SeriesList_ == ...
               obj.Block.Videos(obj.VideoIndex),1,'first');
         end
         
         % Construct video "display" interface
         buildVidDisplay(obj,initMode);
         
         % Construct "heads up display" with time axes and vid selector
         buildHeadsUpDisplay(obj);
         
         % Initialize the timer object
         obj.PlayTimer = timer('TimerFcn',@(~,~)obj.advanceFrame(1), ...
            'ExecutionMode','fixedSpacing',...
            'BusyMode','queue');
         
         % Add alignment stuff
         obj.Figure = obj.Panel.Parent;
         if ~isstruct(obj.Figure.UserData)
            obj.Figure.UserData = struct;
         end
         
         % Set FrameIndex flag function (used by Property Listeners)
         obj.FrameIndexFlagFcn_ = @(x)setFrameIndexFlag_NormalMode(obj);
         
         % Add Listener objects
         obj.Listeners = [...
            addlistener(obj,'FrameIndex','PreSet',...
            @(h,~,~)updateFrameIndexPrev(obj)), ...
            addlistener(obj,'FrameIndex','PostSet',...
            @(h,~,~)setFrameIndexFlag(obj))...
            ];
         
         set(obj.Figure,'WindowKeyReleaseFcn',...
            @(h,~,~)updateTimeLabelsCB(obj));
         
         % "Force" select the video (for init)
%          obj.SeriesList = FromSame(obj.Block.Videos,...
%             obj.Block.Videos(obj.VideoIndex).Source);
         curX = ones(1,2).*(obj.TimeAxes.CameraObj.Time + obj.NeuOffset);
         indicateTime(obj.TimeAxes,curX);
      end
      
   end
   
   % NO ATTRIBUTES (overloaded methods)
   methods
      % [DEPENDENT]  Returns .FPS (frames-per-second) property
      function value = get.FPS(obj)
         %GET.FPS  Returns .FPS (frames-per-second) from .Video object
         %
         %  value = get(obj,'FPS');
         %  --> Returns obj.Video.fs;
         
         value = obj.Video.fs;
      end
      function set.FPS(obj,~)
         %SET.FPS  Does nothing
         if obj.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDGRAPHICS.SET]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: FPS\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .FrameTime property
      function value = get.FrameTime(obj)
         %GET.FRAMETIME  Returns .FrameTime property
         %
         %  value = get(obj,'FrameTime');
         
         value = min(max((obj.FrameIndex-1)/obj.FPS,0),obj.Video.Duration);
      end
      function set.FrameTime(obj,value)
         %SET.FRAMETIME  Assigns .FrameTime property (sets .FrameIndex)
         %
         %  set(obj,'FrameTime',value);
         %  NOTE: This "set" method DOES NOT CHANGE obj.NeuTime
         
         if obj.TimeAxes.CameraObj.Time ~= (value + obj.VideoOffset)
            obj.TimeAxes.CameraObj.Time = value + obj.VideoOffset;
            return;
         end
         
         % Set FrameIndex; only remove .VideoOffset ("series" offset)
         newFrame = max(round(value * obj.FPS),1);
         % This updates the FrameTime display
         setFrame(obj,newFrame);
      end
      
      % [DEPENDENT] Returns .GrossOffset property (from linked Video obj)
      function value = get.GrossOffset(obj)
         %GET.GROSSOFFSET  Returns .GrossOffset property (from Video obj)
         %
         %  value = get(obj,'GrossOffset');
         
         if obj.Block.HasVideoTrials
            value = obj.TrialOffset;
         else
            ts = getEventData(obj.Block,obj.ScoringField_,'ts','Header');
            value = ts(obj.Block.VideoIndex);
         end
      end
      function set.GrossOffset(obj,value)
         %SET.GROSSOFFSET  Assign corresponding video of linked Block
         %
         %  set(obj,'GrossOffset',value);
         %  --> value should be:
         %  value = (tNeu - tEvent) - tSpecific;
         %  Where tSpecific is the "Trial-Specific" and "Camera-Specific"
         %  offset.
         
         if obj.Block.HasVideoTrials
            obj.TrialOffset = value;
         else
            setEventData(obj.Block,obj.ScoringField_,...
               'ts','Header',value,obj.Block.VideoIndex);
         end
      end
      
      % [DEPENDENT] Returns .NeuTime property
      function value = get.NeuTime(obj)
         %GET.NEUTIME  Returns .NeuTime property
         %
         %  value = get(obj,'NeuTime');
         
         if isempty(obj.TimeAxes)
            value = obj.NeuTime_;
         else
            value = obj.TimeAxes.CameraObj.NeuTime_;
         end
      end
      function set.NeuTime(obj,value)
         %SET.FRAMETIME  Update Block
         
         % Updates Block neural time
         obj.NeuTime_ = value;
         obj.Block.CurNeuralTime = value;
      end
      
      % [DEPENDENT] Returns .NeuOffset property (from linked Video obj)
      function value = get.NeuOffset(obj)
         %GET.NEUOFFSET  Returns .NeuOffset property (from linked Video obj)
         %
         %  value = get(obj,'NeuOffset');
         %  --> Returns NaN or offset between video and neural time
         %  (positive value for neural data started before video record)
         
         value = obj.Video.NeuOffset;
      end
      function set.NeuOffset(obj,value)
         %SET.NEUOFFSET  Assign corresponding video of linked Block
         %
         %  set(obj,'NeuOffset',value);
         %  --> value should be:
         %  value = (tNeu - tEvent) - tSpecific - tStart;
         %  Where tSpecific is the "Trial-Specific" and "Camera-Specific"
         %  offset, and tStart is the Video-Series offset
         
         % Set the offset for any other videos in this camera series
         for iVid = obj.SeriesIndex_:numel(obj.SeriesList_)
            obj.SeriesList_(iVid).NeuOffset = value;
         end
      end
      
      % [DEPENDENT] Returns .NumFrames property (total # frames in current)
      function value = get.NumFrames(obj)
         %GET.NUMFRAMES  Returns .NumFrames property (total # frames)
         %
         %  value = get(obj,'NumFrames');
         %  --> Returns .NumFrames from obj.Block.Videos(obj.VideoIndex);
         
         value = obj.Video.NumFrames;
      end
      function set.NumFrames(~,~)
         %SET.NUMFRAMES  Does nothing
         if obj.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDGRAPHICS.SET]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: NumFrames\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .SeriesIndex (index to .SeriesList)
      function value = get.SeriesIndex(obj)
         %GET.SERIESINDEX Returns .SeriesIndex (index in .SeriesList)
         
         value = obj.SeriesIndex_;
      end
      function set.SeriesIndex(obj,value)
         %SET.SERIESINDEX  Updates .SeriesIndex and resets the Frame
         
         obj.SeriesIndex_ = value;
         obj.TimeAxes.CameraObj.SeriesIndex_ = value;
         obj.VideoIndex = obj.SeriesList_(value).VideoIndex;
      end
      
      % [DEPENDENT]  .SeriesList (array of same-source vids)
      function value = get.SeriesList(obj)
         %GET.SERIESLIST  Returns .SeriesList (array of same-source vids)
         %
         %  value = get(obj,'SeriesList');
         %  --> Returns nigeLab.libs.VideosFieldType array of same-source
         value = obj.SeriesList_;
      end
      function set.SeriesList(obj,value)
         %SET.SERIESLIST  Assigns .SeriesList (array of same-source vids)
         %
         %  set(obj,'SeriesList',value);
         %  --> Sets .SeriesList_ store property and updates video indexing
         
         if isempty(setdiff(value,obj.SeriesList_))
            return;
         end
         obj.SeriesList_ = value;
         if ~isempty(obj.TimeAxes)
            % Update the CameraObj video object series list
            obj.TimeAxes.CameraObj.Series = value; % No longer updates dependent property .Index
            if isempty(obj.SeriesIndex_)
               return; % Then out-of-range
            end
            % Still need to update .VideoIndex; can do this now we know the Video
            obj.Video = value(obj.SeriesIndex_);
            
            % Now that VideoIndex is correct, complete "Index" update
            obj.TimeAxes.CameraObj.Index = obj.SeriesIndex_;
         else
            % Attempts to set VideoSource (if called from set.VideoSource,
            % then AbortSet of .VideoSource prevents redundancy here)
            obj.VideoSource = obj.SeriesList_(1).Source;
            obj.SeriesIndex = 1;
         end
      end
      
      % [DEPENDENT]  .SeriesTime (time within video series)
      function value = get.SeriesTime(obj)
         %GET.SERIESTIME  Returns time accounting for prior series videos
         %
         %  value = get(obj,'SeriesTime');
         
         if isempty(obj.TimeAxes)
            value = 0;
            return;
         end
         value = obj.TimeAxes.CameraObj.Time;
      end
      function set.SeriesTime(obj,value)
         %SET.SERIESTIME  Assigns time within series
         %
         %  set(obj,'SeriesTime',value);
         %  --> Assigns .TimeAxes.CameraObj.Time as well
         
         obj.SeriesTime_ = value;
         % Update obj.FrameTime via Dependent property of CameraObj:
         obj.TimeAxes.CameraObj.Time = value;
      end
      
      % [DEPENDENT] .TrialOffset property (from linked Block)
      function value = get.TrialOffset(obj)
         %GET.NEUOFFSET  Returns .NeuOffset property (from linked Block)
         %
         %  value = get(obj,'TrialOffset');
         %  --> Returns Trial/Camera-specific offset for current trial
         iRow = obj.Block.VideoSourceIndex;
         iCol = obj.Block.TrialIndex;
         value = obj.Block.TrialVideoOffset(iRow,iCol);
      end
      function set.TrialOffset(obj,value)
         %SET.TRIALOFFSET  Assign corresponding video of linked Block
         %
         %  set(obj,'TrialOffset',value);
         %  --> value should be:
         %  value = (tNeu - tEvent) - GrossOffset;
         %  Where "GrossOffset" is the VideosFieldType.GrossOffset property
         
         iRow = obj.VideoSourceIndex;
         iCol = obj.Block.TrialIndex;
         obj.Block.TrialVideoOffset(iRow,iCol) = value;

      end
      
      % [DEPENDENT]  .TimerPeriod property (from .FPS)
      function value = get.TimerPeriod(obj)
         %GET.TIMERPERIOD  Returns .TimerPeriod property (from .FPS)
         
         if isnan(obj.FPS)
            value = 0.034; % 60 fps default
            return;
         end
         value = 2*round(1000/obj.FPS)/1000;
      end
      function set.TimerPeriod(obj,~)
         %SET.TIMERPERIOD  (Does nothing)
         if obj.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDINFO.SET]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: TimerPeriod\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  .VFR property (from linked VideosFieldType)
      function value = get.VFR(obj)
         %GET.VFR  Returns .VFR property (VideoFileReader from link)
         %
         %  value = get(obj,'VFR');
         %  --> Returns 'VideoReader' object from obj.Block.Videos(curVid)
         
         vObj = obj.Block.Videos(obj.VideoIndex);
         value = Ready(vObj); % Return "readied" object
      end
      function set.VFR(obj,~)
         %SET.VFR  Does nothing
         if obj.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDGRAPHICS.SET]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set READ-ONLY property: VFR\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  "linked" Video object
      function value = get.Video(obj)
         %GET.VIDEO  Returns "linked" Video object (.Video property)
         %
         %  value = get(obj,'Video');
         %  --> Returns current element of Block.Videos, a
         %        nigeLab.libs.VideosFieldType object
         
         value = obj.Block.Videos(obj.Block.VideoIndex);
      end
      function set.Video(obj,value)
         %SET.VIDEO  Sets "linked" Video object (.Video property)
         %
         %  set(obj,'Video',value);
         %  --> Updates the listbox Index to the indicated .Video object
         
         obj.VideoIndex = value.VideoIndex;
      end
      
      % [DEPENDENT]  Index for current video from series
      function value = get.VideoIndex(obj)
         %GET.VIDEOINDEX  Returns Index for current Video from series
         %
         %  value = get(obj,'VideoIndex');
         %  --> Returns index to current video from series
         
         value = obj.Block.VideoIndex;
      end
      function set.VideoIndex(obj,value)
         %SET.VIDEOINDEX  Assigns index of video, updating VideoSource
         
         if (value > 0) && (value <= numel(obj.Block.Videos))
            direction = sign(value - obj.Block.VideoIndex);
            obj.Block.VideoIndex = value;
         else
            error(['nigeLab:' mfilename ':InvalidVideoIndex'],...
               ['\n\t\t->\t<strong>[VIDGRAPHICS]:</strong> ' ...
               'Value of .VideoIndex (%g) is out of range.\n'],value);
         end
         
         % VideoSource is AbortSet; will not update if on same series
         vidSource = obj.Block.Videos(value).Source;
         obj.VideoSource_ = vidSource; % Updates SeriesList, Image cropping
         obj.AnimalNameLabel.String = getAnimalNameLabel(obj);
         obj.VideoMaskIndicator.AlphaData = 0.5 - (0.5 * obj.Video.Masked);
         if ~isempty(obj.TimeAxes)
            refreshGraphics(obj.TimeAxes.BehaviorInfoObj);
            switch direction
               case 1  % Then we "forwarded" trials
                  
               case -1 % Then we "reduced" trials
                  
               case 0  % Then we are on the same trial (shouldn't happen)
               
            end
               
         end
      end
      
      % [DEPENDENT]  Name of currently-displayed video
      function value = get.VideoName(obj)
         %GET.VIDEONAME  Returns name of currently-displayed video
         %
         %  value = get(obj,'VideoName');
         %  --> Value depends on source series and current time
         value = obj.VideoName_{obj.Block.VideoIndex};
      end
      function set.VideoName(obj,value)
         %SET.VIDEONAME  Assigns name of currently-displayed video
         %
         %  set(obj,'VideoName',value);
         %  --> Updates obj.VideoIndex
         %     --> value should be of form 'VideoSource::SeriesIndex'
         %         (Where series index is obj.SeriesIndex-1 (zero-indexed))
         
         idx = find(strcmp(obj.VideoName_,value),1,'first');
         if isempty(idx) || (idx == obj.Block.VideoIndex)
            return;
         end
         obj.VideoIndex = idx;
      end
      
      % [DEPENDENT]  "Source" for Video
      function value = get.VideoSource(obj)
         %GET.VIDEOSOURCE  Returns "Source" for Video (from .Videos)
         %
         %  value = get(obj,'VideoSource');
         %  --> Returns camera angle, such as 'Front' or 'Left-A'
         
         value = obj.VideoSource_;
      end
      function set.VideoSource(obj,value)
         %SET.VIDEOSOURCE  Will not enter unless Source has changed
         %
         %  set(obj,'VideoSource',value);
         %  --> VideoSource is AbortSet. This will update the SeriesList
         %      since the video camera source has to have changed if this
         %      value was set.
         
         % Update "store"
         obj.VideoSource_ = value;
         
         % If the same or not member of source list, then do nothing
         obj.VideoSourceIndex = find(strcmp(obj.VideoSourceList_,value),1,'first');
         
         % At this point, still have not updated .VideoIndex: should be
         % done in obj.SeriesList set method, since to decide VideoIndex we
         % first need to know the SeriesIndex, for which we need to know
         % the SeriesList so we can parse the correct index based on the
         % current SeriesTime.
         
         % Update current series list
         obj.SeriesList = FromSame(obj.Block.Videos,value);
         
         % After this, VideoIndex has been set correctly.
         neuOffset = obj.Block.Videos(obj.VideoIndex).NeuOffset;
         grossOffset = obj.Block.Videos(obj.VideoIndex).GrossOffset;
         trialOffset = obj.Block.Videos(obj.VideoIndex).TrialOffset;
         seriesTime = obj.NeuTime+grossOffset+trialOffset;
         obj.TimeAxes.CameraObj.SeriesTime_ = seriesTime;
         
         % Issue command as if "right-click" on video frame
         setROI(obj,obj.VidIm,struct('Button',3));
         
         % Update TimeAxes "streams" XData if there is an alignment stream
         resetStreamXData(obj.TimeAxes,neuOffset+trialOffset);
         
      end
      
      % [DEPENDENT]  Returns Index for Video Source from .ListBox
      function value = get.VideoSourceIndex(obj)
         %GET.VIDEOINDEX  Returns "Source" for Video (from .Videos)
         %
         %  value = get(obj,'VideoSourceIndex');
         %  --> Returns index to video from list of videos in listbox
         
         value = obj.VideoSourceIndex_;
      end
      function set.VideoSourceIndex(obj,value)
         %SET.VIDEOSOURCEINDEX  Assigns index of source based on .ListBox
         
         if (value > 0) && (value <= numel(obj.VideoSourceList_))
            obj.VideoSourceIndex_ = value;
         end
         if obj.VidSelectListBox.Value ~= value
            obj.VidSelectListBox.Value = value;
         end
         
      end
      
      % [DEPENDENT] Returns .VideoOffset property (from linked Video obj)
      function value = get.VideoOffset(obj)
         %GET.OFFSET  Returns .VideoOffset property (from linked Video obj)
         %
         %  value = get(obj,'VideoOffset');
         %  --> Returns NaN or offset between video and neural time
         %  (positive value for neural data started before video record)
         
         value = obj.Video.VideoOffset; % Video "series" offset
      end
      function set.VideoOffset(~,~)
         %SET.VideoOffset  Assign corresponding video of linked Block
         %          obj.Block.Videos(obj.VideoIndex).VideoOffset = value;
         %          obj.Block.CurNeuralTime = obj.FrameTime + ...
         %             obj.GrossOffset + obj.TrialOffset;
         warning('Cannot set READ-ONLY property: <strong>VideoOffset</strong>');
      end
      
      % [DEPENDENT]  Returns .Verbose property (from linked Block)
      function value = get.Verbose(obj)
         %GET.VERBOSE  Returns .Verbose property (if false, suppress text)
         %
         %  value = get(obj,'Verbose');
         %  --> Returns value of obj.Block.Verbose
         
         value = obj.Block.Verbose;
      end
      function set.Verbose(~,~)
         %SET.VERBOSE  Does nothing
         if obj.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[GRAPHICSUPDATER.SET]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Verbose\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns `XImScale` (scaling of panel width)
      function value = get.XImScale(obj)
         % Video image axes (.VidImAx)
         %  * nested in Panel (.Panel)
         %  --> Image "X" Scale is based on ratio of Panel Width to
         %      Figure, as well as the Width of the Figure Image itself
         axW = obj.VidImAx.Position(3) * obj.Panel.Panel.Position(3);
         panelW = obj.Panel.Position(3);
         value = panelW * axW;
      end
      function set.XImScale(~,~)
         warning('Cannot set READ-ONLY property: <strong>XImScale</strong>');
      end
      
      function value = get.XImOffset(obj)
         % Video image axes (.VidImAx)
         %  * nested in Panel (.Panel)
         
         % Offset within-panel is scaled by height of panel
         axOffset = obj.VidImAx.Position(1) * ...
            obj.Panel.Position(3) * obj.Panel.Panel.Position(3);
         % Offset of panel is just the .InnerPosition of panel
         panelOffset = obj.Panel.Panel.InnerPosition(1)*...
            obj.Panel.Position(3) + obj.Panel.Position(1);
         value = axOffset + panelOffset;
      end
      function set.XImOffset(~,~)
         warning('Cannot set READ-ONLY property: <strong>XImOffset</strong>');
      end
      
      function value = get.YImScale(obj)
         % Video image axes (.VidImAx)
         %  * nested in Panel (.Panel)
         %  --> Image "Y" Scale is based on ratio of Panel Height to
         %      Figure, as well as the Height of the Figure Image itself
         axH = obj.VidImAx.Position(4) * obj.Panel.Panel.Position(4);
         panelH = obj.Panel.Position(4);
         
         value = panelH * axH;
      end
      function set.YImScale(~,~)
         warning('Cannot set READ-ONLY property: <strong>YImScale</strong>');
      end
      
      function value = get.YImOffset(obj)
         % Video image axes (.VidImAx)
         %  * nested in Panel (.Panel)
         
         % Offset within-panel is scaled by height of panel
         axOffset = obj.VidImAx.Position(2) * ...
            obj.Panel.Position(4) * obj.Panel.Panel.Position(4);
         % Offset of panel is just the .InnerPosition of panel
         panelOffset = obj.Panel.Panel.InnerPosition(2)*...
            obj.Panel.Position(4) + obj.Panel.Position(2);
         value = axOffset + panelOffset;
      end
      function set.YImOffset(~,~)
         warning('Cannot set READ-ONLY property: <strong>YImOffset</strong>');
      end
      
      % Clean up TIMERS (no VIDEOREADER associated with VIDINFO)
      function delete(obj)
         % DELETE  Ensure TIMER is deleted on vidInfo object destruction
         
         % Idle all Videos
         if ~isempty(obj.Block)
            Idle(obj.Block.Videos);
         end
         
         % Delete the PlayTimer
         if ~isempty(obj.PlayTimer)
            if isvalid(obj.PlayTimer)
               delete(obj.PlayTimer);
            end
         end
         
         % Delete Listeners
         if ~isempty(obj.Listeners)
            for i = 1:numel(obj.Listeners)
               if isvalid(obj.Listeners(i))
                  delete(obj.Listeners(i));
               end
            end
         end
         
         % Delete "Parent" figure handle
         if ~isempty(obj.Figure)
            if isvalid(obj.Figure)
               delete(obj.Figure);
            end
         end
      end
   end
   
   % PUBLIC
   methods (Access=public)
      % Function that runs while video is playing from timer object
      function advanceFrame(obj,n)
         % ADVANCEFRAME Increment the current frame by n frames
         %
         %  obj.advanceFrame(n); Advance frame index by n frames
         %
         %  NOTE: This method CHANGES BOTH obj.FrameTime and obj.NeuTime
         
         %executed at each timer period, when playing the video
         newFrame = obj.FrameIndex + n;
         % Make sure that frame is within valid range
         newIndex = checkIfFrameIsOutOfBounds(obj,newFrame);
         if isnan(newIndex) % Then this is the correct video
            obj.FrameIndex = newFrame;
            setFrame(obj);
         elseif isinf(newIndex) % Then give up
            if newIndex < 0
               obj.SeriesTime = 0;
            else
               obj.SeriesTime = Max(obj.SeriesList);
            end
            return;
         else % Otherwise check new video in series
            obj.SeriesIndex = newIndex; % This will re-trigger setFrame
            return;
         end
         
      end
      
      % Play or pause the video
      function playPauseVid(obj)
         % PLAYPAUSEVID  Toggle between stopping and starting the "play
         %               video" timer.
         
         %toggle between stoping and starting the "play video" timer
         if strcmp(get(obj.PlayTimer,'Running'), 'off')
            set(obj.PlayTimer, 'Period', obj.TimerPeriod);
            start(obj.PlayTimer);
         else
            stop(obj.PlayTimer);
         end
      end
      
      % Prompts user to run trial extraction
      function promptForTrialExtraction(obj,skipPrompt)
         %PROMPTFORTRIALEXTRACTION  Prompts user to run trial extraction
         %
         %  promptForTrialExtraction(obj);
         %
         %  promptForTrialExtraction(obj,skipPrompt);
         %  --> By default, skipPrompt is false (if unspecified)
         
         if nargin < 2
            skipPrompt = false;
         end
         
         if skipPrompt
            str = 'Yes';
         else
            str = questdlg('Run `doTrialVidExtraction`?',...
               'All Source ROIs Set','Yes','No','Yes');
         end
         
         if strcmp(str,'Yes')
            obj.Figure.Visible = 'off';
            drawnow;
            try
               doTrialVidExtraction(obj.Block);
               drawnow;
            catch me
               obj.Figure.Visible = 'on';
               drawnow;
               rethrow(me);
            end
            if obj.Block.HasVideoTrials
               save(obj.Block); % Save after extracting
               scoreVideo(obj.Block); % Open a new interface
               delete(obj); % Delete this interface
            else
               obj.Figure.Visible = 'on';
            end
         end
      end
      
      % Callback from video selection list box
      function selectVideo(obj,src,forceSelection)
         % SELECTVIDEO  Set the current video index based on the Value
         %                  of a uicontrol (src)
         %
         %  uiControlPushButton.Callback = @obj.selectVideo;
         %  --> Selects video as callback when listbox is clicked
         %
         %  or
         %
         %  selectVideo(obj,2);
         %  --> Select 2nd video from list
         %
         %  src: uicontrol with Value that corresponds to index of Videos
         
         % Parse input
         if isnumeric(src)
            idx = src;
         else
            idx = src.Value;
         end
         
         if nargin < 3
            forceSelection = false;
         end
         
         % Do not re-load video if it's the same index
         if (idx == obj.VideoSourceIndex_) && ~forceSelection
            return;
         end
         
         % This set triggers a bunch of dependent set methods that update
         % both the nigeLab.libs.nigelCamera object (TimeAxes.CameraObj) as
         % well as the rest of the Indexing and time properties of the
         % VidGraphics obj that relate to the new video.
         obj.VideoSource = obj.VideoSourceList_{idx};
         
         obj.AnimalNameLabel.String = getAnimalNameLabel(obj);
         
         % Update mask indicator alpha value based on mask value
         obj.VideoMaskIndicator.AlphaData = 0.5 - (0.5 * obj.Video.Masked);
         
         % Reset focus to Video Figure
         uicontrol(obj.TrialOffsetLabel);
         if obj.Block.HasVideoTrials
            obj.TrialOffsetLabel.String = ...
               sprintf('Trial Offset: %6.3f sec  ||  FPS: %6.2f Hz',...
               obj.TrialOffset,obj.FPS);
         else
            obj.TrialOffsetLabel.String = ...
               sprintf('Gross Offset: %6.3f sec  ||  FPS: %6.2f Hz',...
               obj.GrossOffset,obj.FPS);
         end
         
      end
      
      % Set the current video frame
      function tNeu = setFrame(obj,newFrame)
         % SETFRAME  Set frame index of current video frame and update it
         %
         %  setFrame(obj);
         %  --> Assumes that obj.FrameIndex has been set elsewhere, and
         %  proceeds with the rest of the "frame-set" updates (for the
         %  image etc, time marker on axes, etc)
         %
         %  setFrame(obj,newFrame);
         %  --> Changes frame to newFrame (if valid)
         %
         %  tNeu = setFrame(obj,newFrame);
         %  --> Assigns output tNeu as the current neural time based on the
         %  frame time. You can assign obj.tNeu on a call to setFrame to
         %  update the current alignment, if you are not trying to use
         %  `setFrame` to update the offset.
         
         % Initialize output as copy of current neural time
         if nargin == 2
            obj.FrameIndex = newFrame;
         end
         
         % Set the displayed frame and check to update buffer if needed
         updateFrameImage(obj);
         
         tSeries = obj.FrameTime + obj.VideoOffset;
         
         if obj.NewVideo_
            if obj.TimeAxes.ZoomLevel > 0
               % Update the "zoom" as well
               dx =  diff(obj.TimeAxes.Axes.XLim);
               xl = [-dx/2+obj.TimeAxes.CameraObj.SeriesTime_, ...
                  dx/2+obj.TimeAxes.CameraObj.SeriesTime_];
               updateZoom(obj.TimeAxes,xl);
            end
            obj.NewVideo_ = false;
         end
         
         % Update scroll bar in 'TimeAxes' object plot
         obj.TimeAxes.CameraObj.SeriesTime_ = tSeries;
         indicateTime(obj.TimeAxes,[tSeries, tSeries]);
         
         % Return the "best-estimate" neural time
         tNeu = tSeries-obj.NeuOffset;
      end
      
      % Set FrameIndex flags to know if we should update VFR FrameTime
      function setFrameIndexFlag(obj)
         %SETFRAMEINDEXFLAG  Listener callback to know if need VFR update
         %
         %  setFrameIndexFlag(obj)
         %  --> PostSet listener callback for '.FrameIndex' property
         
         % feval(obj.FrameIndexFlagFcn_); % deprecated
         %                                (do not use "buffer mode" as it
         %                                 does not seem to offer any
         %                                 performance increases)
         
         % Compute FrameIndex updated difference
         delta = obj.FrameIndex - obj.FrameIndex_;
         % Reading sequentially without changing the .VFR.CurrentTime
         % property allows the VideoReader to go faster, as the codecs
         % rely on assumptions about temporal continuity regarding how
         % the video would be watched (to go faster)
         obj.NeedsUpdate_ = (delta~=1);
      end
      
      % Frame Index updater Callback with buffer
      function setFrameIndexFlag_BufferMode(obj)
         %SETFRAMEINDEXFLAG_BUFFERMODE  Sets .NeedUpdate_ based on buffsize
         %
         %
         
         % Compute FrameIndex updated difference
         delta = obj.FrameIndex - obj.FrameIndex_;
         obj.iCur_ = obj.iCur_ + delta;
         % If this puts at a point where we need update, then flag it.
         obj.NeedsUpdate_ = (obj.iCur_ < 1) || (obj.iCur_ > obj.BuffSize_);
      end
      
      % Frame Index updater Callback for no buffer
      function setFrameIndexFlag_NormalMode(obj)
         %SETFRAMEINDEXFLAG_NORMALMODE  Sets .NeedsUpdate_ based on ~= 1
         %
         %  setFrameIndexFlag_NormalMode(obj);
         %  --> If obj.FrameIndex - obj.FrameIndex_ ~= 1, need to update
         
         % Compute FrameIndex updated difference
         delta = obj.FrameIndex - obj.FrameIndex_;
         % Reading sequentially without changing the .VFR.CurrentTime
         % property allows the VideoReader to go faster, as the codecs
         % rely on assumptions about temporal continuity regarding how
         % the video would be watched (to go faster)
         obj.NeedsUpdate_ = (delta~=1);
      end
      
      % Set the "Masked" status for the current trial
      function setMask(obj,src)
         %SETMASK  Set the "Masked" status for the current trial
         %
         %  uimenuObj.Callback = @(src,~)obj.setMask;
         %
         %  obj : nigeLab.libs.VidGraphics object
         %  src : matlab.ui.container.Menu
         
         status = src.UserData;
         if obj.Block.HasVideoTrials
            % Note this has the same effect of setting obj.Video.Masked
            obj.Block.TrialMask(obj.Block.TrialIndex) = src.UserData;
            if ~isempty(obj.TimeAxes)
               updateMetaCompletionStatus(obj.TimeAxes.BehaviorInfoObj);
               updateEventTimeCompletionStatus(obj.TimeAxes.BehaviorInfoObj);
            end
         else
            % Otherwise, may not be 1:1 with Trials, so apply Mask to all
            % videos in series since this likely means we just don't want
            % that "angle"
            for i = 1:numel(obj.SeriesList)
               obj.SeriesList(i).Masked = status;
            end
         end
         obj.VideoMaskIndicator.AlphaData = 0.5 - (0.5 * status);
         
         addBoundaryIndicators(obj.TimeAxes);
         setMaskMenu(obj,status);
         uistack(obj.VideoMaskIndicator,'top');
         drawnow;
      end
      
      % Define ROI to make video loading faster
      function setROI(obj,src,evt)
         %SETROI  Define ROI to allow video to "buffer" into memory
         %
         %  Set as callback for ButtonDownFcn of Image displaying the
         %  current Video frame.
         %
         %  obj.VidIm.ButtonDownFcn = @(s,e)setROI(obj,s,e);
         %
         %  obj : nigeLab.libs.VidGraphics object
         %  src (s, in callback) : Source (same as obj.VidIm)
         %  evt (e, in callback) : Event.EventData (from ButtonDownFcn)
         
         switch evt.Button
            case 1 % Left-click to create bounding box and enable buffer
               if src.UserData
                  return;
               end
               fcn = makeConstrainToRectFcn('imrect',src.XLim,src.YLim);
               W = obj.Block.Pars.Video.ROI.Width;
               w = W / obj.Video.Width;
               H = obj.Block.Pars.Video.ROI.Height;
               h = H / obj.Video.Height;
               
               rect_drag = imrect(src,...
                  [src.CurrentPoint(1,1),src.CurrentPoint(1,2),w,h],...
                  'PositionConstraintFcn',fcn);
               setColor(rect_drag,'k');
               nigeLab.sounds.play('pop',1.25);
               
               rect_pos = wait(rect_drag);
               
               
               
               minCol = max(round(rect_pos(1)*obj.Video.Width),1);
               minRow = max(round(rect_pos(2)*obj.Video.Height),1);
               
               maxCol = min(minCol+W-1,obj.Video.Width);
               maxRow = min(minRow+H-1,obj.Video.Height);
               
               iCol = minCol:maxCol;
               iRow = minRow:maxRow;
               
               if (numel(iCol)<2) || (numel(iRow)<2)
                  delete(rect_drag);
                  nigeLab.sounds.play('pop',0.5);
                  return;
               else
                  setColor(rect_drag,'b');
                  nigeLab.sounds.play('pop',1.90);
               end
               
               C = readFrame(obj.VFR,'native');
               
               for i = 1:numel(obj.SeriesList)
                  obj.SeriesList(i).ROI = {iRow,iCol,':'};
               end
               
               obj.VidIm.CData = C(obj.Video.ROI{:});
               
               delete(rect_drag);
               if obj.Block.HasROI
                  promptForTrialExtraction(obj);
               end
            case 3 % Right-click to cancel
               % Move this to uicontextmenu
         end
         obj.AnimalNameLabel.String = getAnimalNameLabel(obj);
      end
      
      % Assigns ROI of curent video frame image
      function setROI_assign(obj)
         %SETROI_ASSIGN  Assigns ROI of current video frame image to Video
         %
         %  setROI_assign(obj);
         
         if obj.Block.HasROI
            promptForTrialExtraction(obj,true);
         end
      end
      
      % Resets ROI on video frame image
      function setROI_reset(obj)
         %SETROI_RESET  Reset ROI to full image
         
         if ~obj.VidImAx.UserData
            return;
         end
         nigeLab.sounds.play('pop',0.5);
         for i = 1:numel(obj.SeriesList_)
            obj.SeriesList_(i).ROI = {':',':',':'};
         end
         obj.VidIm.CData = readFrame(obj.VFR,'native');
         obj.FrameTime = get(obj.VFR,'CurrentTime');
         obj.VidImAx.UIContextMenu = obj.Menu;
      end
      
      % Set offset for current trial start (for current camera)
      function setTrialOffset(obj)
         %SETTRIALOFFSET  Sets offset for current trial
         if obj.Block.HasVideoTrials
            nigeLab.sounds.play('pop',0.5,-30);
            warning(['nigeLab:' mfilename ':TrialVideosExtracted'],...
               ['\n\t\t->\t<strong>[SCOREVIDEO]:</strong> ' ...
               'Trial videos already extracted. Cannot modify Offsets.\n']);
            return;
         end
         
         obj.TrialOffset = obj.Block.Trial(obj.Block.TrialIndex) - ...
            obj.FrameTime;

      end
      
      % Update .FrameIndex_ for comparator
      function updateFrameIndexPrev(obj)
         %UPDATEFRAMEINDEXPREV  Updates .FrameIndex_ for PostSet comparator
         %
         %  updateFrameIndexPrev(obj);
         %  --> PreSet listener callback for '.FrameIndex' property
         
         obj.FrameIndex_ = obj.FrameIndex;
      end
      
      % Update the current image frame of the video
      function updateFrameImage(obj)
         %UPDATEFRAMEIMAGE  Update the current image frame of video
         %
         %  updateFrameImage(obj);
         %  --> Depending on FrameIndex flags, load from buffer or read
         %  directly
         
         if obj.VFR.hasFrame
            % NeedsUpdate_ gets set on
            % VidGraphics/setFrameIndexFlag(obj,forceUpdate), regardless of
            % "normal" or "cropped" state. If forceUpdate is true,
            % "NeedsUpdate_" changes to true regardless.
            if obj.NeedsUpdate_
               set(obj.VFR,'CurrentTime',obj.FrameTime);
               obj.FrameIndex_ = max(round(obj.FrameTime * obj.FPS),1);
               obj.FrameIndex = obj.FrameIndex_ + 1;
            end

            C = readFrame(obj.VFR,'native');
            set(obj.VidIm,'CData',C(obj.Video.ROI{:}));         
            drawnow;
         end

      end
      
      % [LISTENER CALLBACK]: obj.Figure.WindowKeyReleaseFcn
      function updateTimeLabelsCB(obj,tSeries,tNeu)
         % Update current FrameTime display (NeuTime only updates if set)
         
         if nargin == 1
            tSeries = obj.SeriesTime;
            tNeu = obj.NeuTime;
         end
         
         tStrVid = nigeLab.utils.sec2time(tSeries);
         tVid_ms = round(rem(tSeries,1)*1000);
         set(obj.VidTimeLabel,'String',...
            sprintf('Video Time:  %s.%03g ',tStrVid,tVid_ms));
         
         tNeu_ms = round(rem(tNeu,1)*1000);
         tStrNeu = nigeLab.utils.sec2time(tNeu);
         set(obj.NeuralTimeLabel,'String',...
            sprintf('Neural Time:  %s.%03g ',tStrNeu,tNeu_ms));
         
         set(obj.AnimalNameLabel,'String',getAnimalNameLabel(obj));
      end
   end
   
   % HIDDEN,PUBLIC
   methods (Hidden,Access=public)
      % Print formatted `Timing` data to command window for debugging
      function printTimingData(obj,evt)
         %PRINTTIMINGDATA  Prints timing offset and other data for debug
         %
         %  printTimingData(obj);
         %  --> By default this is bound to 'f1' Window Key Button Press
         
         if nargin < 2
            mod = '';
         elseif isempty(evt.Modifier)
            mod = '';
         else
            mod = evt.Modifier{1};
         end
         clc;
         
         nigeLab.libs.VidGraphics.printPropLine(obj.Block,...
            {'TrialIndex','VideoIndex'});
         if isempty(mod)
            axObj = obj.TimeAxes;
            behaviorObj = axObj.BehaviorInfoObj;
            camObj = axObj.CameraObj;
            labs = {'(sec)',''};
            bData = [behaviorObj.Variable.'; ...
               num2cell(behaviorObj.Value); ...
               labs((behaviorObj.Type>1)+1)];
            nigeLab.libs.VidGraphics.printPropLine(obj,...
               {'VideoIndex','SeriesIndex','FrameTime','NeuTime','SeriesTime',...
                'TrialOffset','VideoOffset','NeuOffset','GrossOffset'},...
               [cell(1,2),repmat({'(sec)'},1,7)]);
            nigeLab.libs.VidGraphics.printPropLine(axObj,...
               {'FrameTime','NeuTime','TrialOffset','VideoOffset','NeuOffset'},...
               '(sec)');
            nigeLab.libs.VidGraphics.printPropLine(camObj,...
               {'Index','Time','SeriesTime_','SeriesTime__','NeuTime_'},...
               [{'(Series Index)'},repmat({'(sec)'},1,4)]);
            fprintf(1,'\n  --  <strong>nigeLab.libs.behaviorInfo:</strong> --  \n');
            nigeLab.libs.VidGraphics.printPropLine(bData);
         else
            T = obj.TimeAxes.CameraObj.Time_(:,2:3).';
            T = [1:size(T,2); T];
            fprintf(1,'\n  --  <strong>nigeLab.libs.nigelCamera:</strong> --  \n');
            fprintf(1,'\t<strong>| %+4s | %+10s (vid) | %+10s (vid) |</strong>\n',...
               'Row','tStart','tStop');
            fprintf(1,'\t| %4g | %10g (sec) | %10g (sec) |\n',T);
         end
      end
   end
   
   % PROTECTED
   methods (Access=protected)
      % Add context menu item with submenu
      function addMenu(obj)
         %ADDMENU  Add "Trial Mask" context menu item with submenu
         %
         %  addMenu(obj);
                
         obj.Menu = uicontextmenu('HandleVisibility','off');
         uimenu(obj.Menu,'Label','Assign Trial Offset','Callback',...
            @(~,~)obj.setTrialOffset);
         uimenu(obj.Menu,'Label','Reset ROI',...
            'Callback',@(~,~)obj.setROI_reset);
         obj.AssignROIMenu = ...
            uimenu(obj.Menu,'Label','Assign Current ROI',...
            'Callback',@(~,~)obj.setROI_assign,...
            'Separator','on');
         
         obj.TrialMaskMenu = uimenu(obj.Menu,'Label','Status','Checked','off');
         obj.UseVideoMenuItem = uimenu(obj.TrialMaskMenu,'Label','Use',...
            'UserData',1,'Callback',@(s,~)obj.setMask(s),'Checked','on');
         obj.ExcludeVideoMenuItem = uimenu(obj.TrialMaskMenu,'Label','Exclude',...
            'UserData',0,'Callback',@(s,~)obj.setMask(s),'Checked','off');
         setMaskMenu(obj,obj.Video.Masked,obj.Block.HasVideoTrials);
         obj.VidImAx.UIContextMenu = obj.Menu;
      end
      
      % Build "Heads Up Display" (HUD)
      function buildHeadsUpDisplay(obj)
         % BUILDHEADSUPDISPLAY  Builds the "Heads-Up-Display" (HUD) that
         %                      has the animal name, current video time,
         %                      and corresponding sync'd neural time.
         %
         %  obj.buildHeadsUpDisplay(label); --> From method of vidInfo obj
         
         % Nest video selection listbox in the Panel (main)
         obj.VidSelectListBox = uicontrol(obj.Panel.Panel,...
            'Style','listbox',...
            'Units','Normalized',...
            'FontName','Droid Sans',...
            'FontSize',13,...
            'Position',[0.875 0.765 0.125 0.230],...
            'Value',obj.VideoSourceIndex,... % Initialize to the first video in list
            'String',obj.VideoSourceList_,...
            'Callback',@(s,~)obj.selectVideo(s));
         nestObj(obj.Panel,obj.VidSelectListBox,'VidSelectListBox');
         
         % Build "Vid Meta Display" for containing updates about video
         %  --> Separate from "Time Display", which is about the video
         %      also, but strictly for displaying strings about Time info
         obj.VidMetaDisp = axes(obj.Panel.Panel,...
            'Units','Normalized',...
            'Color','none',...
            'XColor','none',...
            'YColor','none',...
            'XLim',[0 1],...
            'XTick',[],...
            'YLim',[0 1],...
            'YTick',[],...
            'Position',[0.025 0.765 0.60 0.035]);
         obj.AnimalNameLabel = text(obj.VidMetaDisp, ...
            0.025, 0.25, getAnimalNameLabel(obj), ...
            'FontUnits', 'Normalized', ...
            'FontName','Droid Sans',...
            'FontSize',0.50,...
            'FontWeight','normal',...
            'HorizontalAlignment','left',...
            'Clipping','off',...
            'Color',nigeLab.defaults.nigelColors('onsurface'));
         
         obj.DataLabel = text(obj.VidMetaDisp, ...
            0.99, 0.25, '', ...
            'FontUnits', 'Normalized', ...
            'FontName','Droid Sans',...
            'FontSize',0.50,...
            'FontWeight','normal',...
            'HorizontalAlignment','right',...
            'Clipping','off',...
            'Color',nigeLab.defaults.nigelColors('onsurface'));
         
         obj.TrialOffsetLabel = uicontrol(obj.Panel.Panel,...
            'Style','text',...
            'Units','Normalized',...
            'Position',[0.185,  0.7515, 0.325, 0.035],...
            'String', sprintf('Gross Offset: %6.3f sec  ||  FPS: %6.2 Hz',obj.GrossOffset,obj.FPS),...
            'FontName','Droid Sans',...
            'FontSize',14,...
            'FontWeight','normal',...
            'BackgroundColor',nigeLab.defaults.nigelColors('surface'),...
            'HorizontalAlignment','center',...
            'ForegroundColor',nigeLab.defaults.nigelColors('onsurface'));
         
         % Build "Time Display" axes container for showing time displays
         obj.TimeDisp = axes(obj.Panel.Panel,...
            'Units','Normalized',...
            'Position',[0.625 0.765 0.25 0.23],...
            'Color','none',...
            'XColor','none',...
            'XLim',[0 1],...
            'XTick',[],...
            'YLim',[0 1],...
            'YTick',[],...
            'YColor','none',...
            'NextPlot','add');
         % Nest the "Time Display" container in the main Panel
         nestObj(obj.Panel,obj.TimeDisp,'TimeDisp');
         
         obj.VidTimeLabel = text(obj.TimeDisp, ...
            0.985, 0.45, 'loading...', ...
            'FontUnits', 'Normalized', ...
            'FontName','FixedWidth',...
            'FontWeight','bold',...
            'FontSize',0.075,...
            'HorizontalAlignment','right',...
            'Clipping','off',...
            'Color',nigeLab.defaults.nigelColors('onsurface'));
         
         obj.NeuralTimeLabel = text(obj.TimeDisp,...
            0.985, 0.65, 'loading...', ...
            'FontUnits', 'Normalized', ...
            'Color',nigeLab.defaults.nigelColors('onsurface'),...
            'FontName','FixedWidth',...
            'FontWeight','bold',...
            'FontSize',0.075,...
            'HorizontalAlignment','right',...
            'Clipping','off');
         
         text(obj.TimeDisp,...
            0.985, 0.25, '(hh:mm:ss.sss)', ...
            'FontUnits', 'Normalized', ...
            'FontWeight','bold',...
            'HorizontalAlignment','right',...
            'Color',[0.66 0.66 0.66],...
            'FontName','FixedWidth',...
            'Clipping','off',...
            'FontSize',0.075);
      end
      
      % Build video display
      function buildVidDisplay(obj,initMode)
         % BUILDVIDDISPLAY  Initialize the video display axes and image
         %
         %  buildVidDisplay(obj,initMode);
         %
         %  obj : nigeLab.libs.VidGraphics object
         %  initMode : 'score' (default) or 'align'
         %  --> Used to initialize differently for 'TimeAxes' property
         
         if nargin < 2
            initMode = 'score';
         end
         
         % Initialize list of video names and sources
         initVidSource(obj);
         
         % Build "Time Axes" object for skipping & alignment (no need to
         % use `nestObj`, as it is associated within its own constructor)
         obj.TimeAxes = nigeLab.libs.TimeScrollerAxes(obj,initMode,...
            'Position',[0.025 0.80 0.60 0.145]);
         
         % Make image object container axes
         obj.VidImAx=axes(obj.Panel.Panel,...
            'Units','Normalized',...
            'Position',[0.00 0.00 1.00 0.75],...
            'NextPlot','add',...
            'XColor','none',...
            'YColor','none',...
            'XLimMode','manual',...
            'XLim',[0 1],...
            'YLimMode','manual',...
            'YTick',[],...
            'XTick',[],...
            'YLim',[0 1],...
            'YDir','reverse',...
            'ButtonDownFcn',@obj.setROI);
         nestObj(obj.Panel,obj.VidImAx,'VidImAx');
         
         % Make image object
         x = uint8([0 1]);
         y = uint8([0 1]);
         obj.iCur_ = nan;
         obj.VidIm = imagesc(obj.VidImAx,x,y,readFrame(obj.VFR,'native'),...
            'UserData',false,'PickableParts','none');
         CData = nigeLab.utils.getMatlabBuiltinIcon('warning.gif',...
            'Type','uint8');
         if obj.Video.Masked
            obj.VideoMaskIndicator = imagesc(obj.VidImAx,x,y,CData,...
               'AlphaData',0,'PickableParts','none');
         else
            obj.VideoMaskIndicator = imagesc(obj.VidImAx,x,y,CData,...
               'AlphaData',0.5,'PickableParts','none');
         end
         
         obj.FrameTime = get(obj.VFR,'CurrentTime');
         
         
         % Create ui context menus for interacting with object
         addMenu(obj);
      end
      
      % Returns string for .AnimalNameLabel
      function str = getAnimalNameLabel(obj)
         if isfield(obj.Block.Meta,'AnimalID') % Otherwise it defaults ''
            obj.AnimalName_ = obj.Block.Meta.AnimalID;
         end
         
         if obj.VidIm.UserData % Cropped
            str = sprintf('%s %s -- Cropped',...
               obj.AnimalName_,obj.VideoName);
         else % Otherwise, Normal
            str = sprintf('%s %s',obj.AnimalName_,obj.VideoName);
         end
      end
      
      % Set .VideoName_, .VideoSourceList_, .VideoSource_
      function initVidSource(obj)
         % INITVIDSOURCE  Set .VideoName_, .VideoSourceList_, .VideoSource_
         %
         %  initVidSource(obj);
         %  --> Organizes properties using data in obj.Block.Videos
         
         % Get list of video names
         vidNames = cell(numel(obj.Block.Videos),1);
         for i = 1:numel(obj.Block.Videos)
            vidNames{i} = sprintf('%s::%s',obj.Block.Videos(i).Source,...
               obj.Block.Videos(i).Index);
         end
         obj.VideoName_   = vidNames;
         obj.VideoSourceList_ = unique({obj.Block.Videos.Source}');
         obj.VideoSource_ = obj.Block.Videos(obj.Block.VideoIndex).Source;
         obj.VideoSourceIndex_ = find(ismember(obj.VideoSourceList_,obj.VideoSource_),1,'first');
      end
      
      % Sets current state of 'mask' uicontextmenu
      function setMaskMenu(obj,maskState,trialState)
         %SETMASKMENU  Sets current state of 'mask' uicontextmenu
         %
         %  setMaskMenu(obj,maskState,trialState);
         %  --> By default, maskState is obj.Video.Masked if unspecified
         %  --> By default, trialState is obj.Block.HasVideoTrials if
         %        unspecified
         
         if nargin < 2
            maskState = obj.Video.Masked;
         end
         
         if nargin < 3
            trialState = obj.Block.HasVideoTrials;
         end
         
         if maskState
            enable_chk = 'on';
            disable_chk = 'off';
         else
            enable_chk = 'off';
            disable_chk = 'off';
         end
         
         if trialState
            str = 'Trial Status';
         else
            str = 'Video Status';
         end
         
         set(obj.TrialMaskMenu,'Label',str);
         set(obj.TrialMaskMenu,'Checked',enable_chk);
         set(obj.UseVideoMenuItem,'Checked',enable_chk);
         set(obj.ExcludeVideoMenuItem,'Checked',disable_chk);
      end
   end
   
   % SEALED,PROTECTED
   methods (Sealed,Access=protected)
      % Check that the frame is within-bounds given the total # frames
      function idx = checkIfFrameIsOutOfBounds(obj,newFrame)
         %CHECKIFFRAMEISOUTOFBOUNDS  Checks that the frame is within-bounds
         %
         %  idx = checkIfFrameIsOutOfBounds(obj,newFrame);
         %  --> New series index if needs updated. Otherwise, returns:
         %     * inf  == Give up
         %     * nan  == This is correct video
         
         if (newFrame < 1) % If it is zero or less, invalid index
            if obj.SeriesIndex > 1 % If there are more videos, check them
               idx = obj.SeriesIndex - 1;
               return;
            else % Otherwise, it's just a bad index.
               idx = -inf;
               return;
            end
         elseif (newFrame > obj.NumFrames) % If it is too large, check other videos in list
            if obj.SeriesIndex < numel(obj.SeriesList) % If there are more, check them.
               idx = obj.SeriesIndex + 1;
               return;
            else % Otherwise, it is just a bad index.
               if strcmp(obj.PlayTimer.Running,'on') % Stop the timer if it's running
                  stop(obj.PlayTimer);
               end
               idx = inf;
               return;
            end
         end
         % Then we passed the check: return false
         idx = nan;
      end
   end
   
   % STATIC,PUBLIC
   methods (Static,Access=public)
      % Create "Empty" object or object array
      function obj = empty(n)
         %EMPTY  Return empty nigeLab.libs.VidGraphics object or array
         %
         %  obj = nigeLab.libs.VidGraphics.empty();
         %  --> Return scalar (0 x 0) object
         %
         %  obj = nigeLab.libs.VidGraphics.empty(n);
         %  --> Specify number of empty objects
         
         if nargin < 1
            dims = [0, 0];
         else
            if ~isscalar(n)
               error(['nigeLab:' mfilename ':invalidEmptyDims'],...
                  'Input to nigeLab.libs.VidGraphics.empty should be scalar.');
            end
            dims = [0, n];
         end
         
         obj = nigeLab.libs.VidGraphics(dims);
      end
   end
   
   % STATIC,PROTECTED
   methods (Static,Access=protected)
      % Print a formatted "property value" line (for debug)
      function printPropLine(propVal,propName,tag)
         %PRINTPROPLINE  Prints a formatted "property value" line 
         %
         %  nigeLab.libs.VidGraphics.printPropLine(propVal,propName);
         %  --> Print formatted string for a property name and value
         %
         %  nigeLab.libs.VidGraphics.printPropLine(propVal,propName,tag);
         %  --> Print formatted string with tag at end
         %
         %  nigeLab.libs.VidGraphics.printPropLine(obj,propName);
         %  --> Adds a line above with the name of the class
         %  --> Print property value of a given object
         %
         %  nigeLab.libs.VidGraphics.printPropLine(obj,...
         %     {prop1,prop2,...},tag);
         %  --> Adds a line above with the name of the class
         %  --> Print multiple properties with same tag
         %        (Each one gets its own line)
         %
         %  nigeLab.libs.VidGraphics.printPropLine(obj,...
         %     {prop1,prop2,...,tagk},...
         %     {tag1,tag2,...,tagk});
         %  --> Adds a line above with the name of the class
         %  --> Print properties with unique tags
         
         STR_EXPR = '\t->\t[%+15s]: %13g %s\n';
         
         if nargin < 3
            tag = '';
         end
         
         if nargin < 2
            fprintf(1,STR_EXPR,propVal{:});
         else
            if iscell(propName)
               if ~iscell(tag)
                  tag = repmat({tag},numel(propName),1);
               end
               c = class(propVal);
               fprintf(1,'\n  --  <strong>%s:</strong> --  \n',c);
               for i = 1:numel(propName)
                  fprintf(1,STR_EXPR,...
                     propName{i},propVal.(propName{i}),tag{i});
               end               
            else
               if isnumeric(propVal)
                  fprintf(1,STR_EXPR,propName,propVal,tag);
               else
                  c = class(propVal);
                  fprintf(1,'\n  --  <strong>%s:</strong> --  \n',c);
                  fprintf(1,STR_EXPR,propName,propVal.(propName),tag);
               end
            end
         end
      end
   end
   % % % % % % % % % % END METHODS% % %
end