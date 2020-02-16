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
      N_BUFFER_FRAMES   (1,1) double = 31  % Should be odd integer
   end
   
   % TRANSIENT,PUBLIC
   properties (Transient,Access=public)
      Block                               % nigeLab.Block class object handle
      Figure                              % "parent" figure handle
      Panel                               % nigeLab.libs.nigelPanel container for display graphics
      PlayTimer           timer           % Video playback timer
      TimeAxes                            % nigeLab.libs.TimeScrollerAxes
   end

   % SETOBSERVABLE,PUBLIC
   properties (SetObservable,Access=public)
      FrameIndex    (1,1) double = 1         % Frame currently viewed
   end
   
   % PUBLIC
   properties (Access=public)
      ROISet        (1,1) logical = false    % Has ROI been set?
   end
   
   % PROTECTED
   properties (Access=protected)
      AnimalName_                char = ''         % Name of animal used in video
      BuffSize_                                    % Current "buffer size" (scalar; depends on ROI)
      BufferedFrames_            double            % Vector list of frame indices corresponding to C_ elements
      C_                                           % Image "Buffer" (N_BUFFER_FRAMES x nRows x nCols x 3)
      FrameIndex_          (1,1) double  = 1       % Store for previous FrameIndex_ value
      FrameIndexFlagFcn_                           % Function handle for buffering
      NeedsUpdate_         (1,1) logical = false   % Flag for if .VFR.CurrentTime needs update
      NeuTime_             (1,1) double  = 0       % Store for current neural time
      SeriesIndex_         (1,1) double  = 1       % Index of video within "source" series
      SeriesList_                                  % nigeLab.libs.VideosFieldType series for this Source
      VideoIndex_          (1,1) double  = 1       % Index to video for current "source" series of videos
      VideoName_                 cell              % Cell array of video names
      VideoSource_               char              % Current video source "store"
      VideoSourceList_           cell              % Cell array of elements in .VidSelectListBox
      VideoSourceIndex_    (1,1) double = 1        % Current index to .VidSelectListBox
      iRow_                                        % Indexing of rows for image     (vector)
      iCol_                                        % Indexing of columns for image  (vector)
      iCur_                                        % Current "buffered frame index" (scalar)
   end
   
   % ABORTSET,DEPENDENT,PUBLIC
   properties (AbortSet,Dependent,Access=public)
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
      VideoIndex  (1,1) double = 1     % Index of current video in use (from array)
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
      DataLabel         % matlab.graphics.primitive.Text   Shows trial # or data such as offset (if applicable)
      NeuralTimeLabel   % matlab.graphics.primitive.Text   Shows Neural timestamp of displayed frame
      TimeDisp          % matlab.graphics.axis.Axes Axes   Holds NeuralTimeLabel and VidTimeLabel
      VidImAx           % matlab.graphics.axis.Axes        Holds VidIm 
      VidIm             % matlab.graphics.primitive.Image  Image of current video frame
      VidMetaDisp       % matlab.graphics.axis.Axes        Holds  AnimalNameLabel and DataLabel
      VidSelectListBox  % matlab.ui.control.UIControl      Listbox for selecting specific video
      VidTimeLabel      % matlab.graphics.primitive.Text   Shows current video frame timestamp (from series)
   end
   
   % ABORTSET,DEPENDENT,HIDDEN,TRANSIENT,PUBLIC
   properties (AbortSet,Dependent,Hidden,Transient,Access=public)
      SeriesList                 % Videos related to this video
   end
   % % % % % % % % % % END PROPERTIES %
   
   events 
      LabelsUpdated
   end
   
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
         obj.SeriesList = FromSame(obj.Block.Videos,...
            obj.Block.Videos(obj.VideoIndex).Source);
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
      % [DEPENDENT]  Sets .FPS (cannot)
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
         
         value = (obj.FrameIndex-1) / obj.FPS; 
      end
      % [DEPENDENT]  Assigns .FrameTime property (sets .FrameIndex)
      function set.FrameTime(obj,value)
         %SET.FRAMETIME  Assigns .FrameTime property (sets .FrameIndex)
         %
         %  set(obj,'FrameTime',value);
         %  NOTE: This "set" method DOES NOT CHANGE obj.NeuTime

         % Set FrameIndex; only remove .VideoOffset ("series" offset)
         newFrame = round((value - obj.VideoOffset) * obj.FPS + 1);
         setFrame(obj,newFrame); % This updates the FrameTime display
      end
      
      % [DEPENDENT] Returns .GrossOffset property (from linked Video obj)
      function value = get.GrossOffset(obj)
         %GET.GROSSOFFSET  Returns .GrossOffset property (from Video obj)
         %
         %  value = get(obj,'GrossOffset');

         ts = getEventData(obj.Block,obj.Block.ScoringField,'ts','Header');
         value = ts(obj.VideoIndex_);
      end
      % [DEPENDENT] Assign .GrossOffset property
      function set.GrossOffset(obj,value)
         %SET.GROSSOFFSET  Assign corresponding video of linked Block   
         %
         %  set(obj,'GrossOffset',value);
         %  --> value should be:
         %  value = (tNeu - tEvent) - tSpecific;
         %  Where tSpecific is the "Trial-Specific" and "Camera-Specific"
         %  offset.

         setEventData(obj.Block,obj.Block.ScoringField,...
            'ts','Header',value,obj.VideoIndex);
      end
      
      % [DEPENDENT]  Returns .NeuTime property
      function value = get.NeuTime(obj)
         %GET.NEUTIME  Returns .NeuTime property
         %
         %  value = get(obj,'NeuTime');

         value = obj.NeuTime_;
      end
      % [DEPENDENT]  Assigns .NeuTime property
      function set.NeuTime(obj,value)
         %SET.FRAMETIME  Update Block
         
         % Updates Block neural time
         obj.NeuTime_ = value + obj.VideoOffset;
         obj.Block.CurNeuralTime = value + obj.VideoOffset;
      end
      
      % [DEPENDENT] Returns .NeuOffset property (from linked Video obj)
      function value = get.NeuOffset(obj)
         %GET.NEUOFFSET  Returns .NeuOffset property (from linked Video obj)
         %
         %  value = get(obj,'NeuOffset');
         %  --> Returns NaN or offset between video and neural time
         %  (positive value for neural data started before video record)
         
         value = obj.GrossOffset - obj.VideoOffset;
      end
      % [DEPENDENT] Assign .NeuOffset property
      function set.NeuOffset(obj,value)
         %SET.NEUOFFSET  Assign corresponding video of linked Block   
         %
         %  set(obj,'NeuOffset',value);
         %  --> value should be:
         %  value = (tNeu - tEvent) - tSpecific - tStart;
         %  Where tSpecific is the "Trial-Specific" and "Camera-Specific"
         %  offset, and tStart is the Video-Series offset
         
         obj.GrossOffset = value+obj.VideoOffset;
      end
      
      % [DEPENDENT] Returns .NumFrames property (total # frames in current)
      function value = get.NumFrames(obj)
         %GET.NUMFRAMES  Returns .NumFrames property (total # frames)
         %
         %  value = get(obj,'NumFrames');
         %  --> Returns .NumFrames from obj.Block.Videos(obj.VideoIndex);

         value = obj.Video.NumFrames;
      end
      % [DEPENDENT] Assigns .NumFrames property (cannot)
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
         obj.VideoIndex_ = findVideo(obj.SeriesList_(value),obj.Block.Videos);
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
         % Attempts to set VideoSource (if called from set.VideoSource,
         % then AbortSet of .VideoSource prevents redundancy here)
         obj.VideoSource = obj.SeriesList_(1).Source;
         
         obj.SeriesIndex = 1;
         obj.FrameTime = obj.NeuTime + obj.GrossOffset + obj.TrialOffset;
         updateTimeLabelsCB(obj,obj.FrameTime,obj.NeuTime);
         obj.AnimalNameLabel.String = getAnimalNameLabel(obj);
         drawnow;
      end
      
      % [DEPENDENT] .TrialOffset property (from linked Block)
      function value = get.TrialOffset(obj)
         %GET.NEUOFFSET  Returns .NeuOffset property (from linked Block)
         %
         %  value = get(obj,'TrialOffset');
         %  --> Returns Trial/Camera-specific offset for current trial
         iRow = obj.VideoIndex_;
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
        
         iRow = obj.VideoIndex;
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
         %  nigeLab.libs.VideosFieldType object
         
         value = obj.Block.Videos(obj.VideoIndex_);
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
         
         value = obj.VideoIndex_;
      end
      function set.VideoIndex(obj,value)
         %SET.VIDEOINDEX  Assigns index of video, updating VideoSource        
         
         if (value > 0) && (value <= numel(obj.Block.Videos))
            obj.VideoIndex_ = value;
         end
         % VideoSource is AbortSet; will not update if on same series
         vidSource = obj.Block.Videos(value).Source; 
         obj.VideoSource = vidSource; % Updates SeriesList, Image cropping
         obj.AnimalNameLabel.String = getAnimalNameLabel(obj);
         drawnow;
      end
      
      % [DEPENDENT]  Name of currently-displayed video
      function value = get.VideoName(obj)
         %GET.VIDEONAME  Returns name of currently-displayed video
         %
         %  value = get(obj,'VideoName');
         %  --> Value depends on source series and current time
         value = obj.VideoName_{obj.VideoIndex_};
      end
      function set.VideoName(obj,value)
         %SET.VIDEONAME  Assigns name of currently-displayed video
         %
         %  set(obj,'VideoName',value);
         %  --> Updates obj.VideoIndex_ and possibly obj.VideoSourceIndex_
         %     --> value should be of form 'VideoSource::SeriesIndex'
         %         (Where series index is obj.SeriesIndex-1 (zero-indexed))
         
         idx = find(strcmp(obj.VideoName_,value),1,'first');
         if isempty(idx) || (idx == obj.VideoIndex_)
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

         % Update current series list
         obj.SeriesList = FromSame(obj.Block.Videos,value);
         
         % Issue command as if "right-click" on video frame
         obj.setROI(obj.VidIm,struct('Button',3));
      end
      
      % [DEPENDENT]  Returns Index for Video Source from .ListBox
      function value = get.VideoSourceIndex(obj)
         %GET.VIDEOINDEX  Returns "Source" for Video (from .Videos)
         %
         %  value = get(obj,'VideoSourceIndex');
         %  --> Returns index to video from list of videos in listbox
         
         value = obj.VideoSourceIndex_;
      end
      % [DEPENDENT]  Assigns Index for Video Source based on .ListBox
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
      % [DEPENDENT] Assign .VideoOffset property
      function set.VideoOffset(obj,value)
         %SET.VideoOffset  Assign corresponding video of linked Block
         obj.Block.Videos(obj.VideoIndex).VideoOffset = value;
         obj.Block.CurNeuralTime = obj.FrameTime + obj.GrossOffset + obj.TrialOffset;
      end
      
      % [DEPENDENT]  Returns .Verbose property (from linked Block)
      function value = get.Verbose(obj)
         %GET.VERBOSE  Returns .Verbose property (if false, suppress text)
         %
         %  value = get(obj,'Verbose');
         %  --> Returns value of obj.Block.Verbose
         
         value = obj.Block.Verbose;
      end
      % [DEPENDENT] Assign .Verbose property (cannot)
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
   methods (Access = public)      
      % Function that runs while video is playing from timer object
      function advanceFrame(obj,n) 
         % ADVANCEFRAME Increment the current frame by n frames
         %
         %  obj.advanceFrame(n); Advance frame index by n frames
         %
         %  NOTE: This method CHANGES BOTH obj.FrameTime and obj.NeuTime
         
         %executed at each timer period, when playing the video
         newFrame = obj.FrameIndex + n;
         obj.NeuTime = setFrame(obj,newFrame);
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
         
         % Set video index (updates .VFR)
         obj.VideoSource = obj.VideoSourceList_{idx};
         % Setting dependent property .VideoIndex updates obj.VideoSource
         % and then updates obj.SeriesList
         
         if forceSelection
            obj.NeuTime = obj.Block.Trial(obj.Block.TrialIndex)-obj.VideoOffset;
            % If this is out of range, will select correct video:
            obj.FrameTime = obj.NeuTime+obj.VideoOffset; 
            set(obj.TimeAxes,'XLim','far');
            updateTimeLabelsCB(obj,obj.FrameTime,obj.NeuTime);
         end
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
         
         flag = src.UserData;
         switch evt.Button
            case 1 % Left-click to create bounding box and enable buffer
               if flag
                  return;
               end
               rect_pos = rbbox;
               nigeLab.sounds.play('pop',1.9);
               
               w = rect_pos(3) / obj.XImScale;
               x = (rect_pos(1) - obj.XImOffset) / obj.XImScale;
               
               h = rect_pos(4) / obj.YImScale;
               y = 1-((rect_pos(2)-obj.YImOffset) / obj.YImScale);
               
               minCol = max(1,round(x*obj.Video.Width));
               maxCol = min(round((x+w)*obj.Video.Width),obj.Video.Width);
               obj.iCol_ = minCol:maxCol;
               % Since image has to be "flipped" (lowest row indices are at
               % top-left of the image), we need to invert and start from
               % lowest to highest rows
               minRow = max(1,round((y-h)*obj.Video.Height));
               maxRow = min(round(y*obj.Video.Height),obj.Video.Height);
               obj.iRow_ = minRow:maxRow;
               updateBuffer(obj);
               if isempty(obj.iCol_) || isempty(obj.iRow_)
                  obj.iCol_ = [];
                  obj.iRow_ = [];
                  obj.C_ = [];
                  nigeLab.sounds.play('pop');
                  return;
               end
               
               x = uint8([0 1]);
               y = uint8([0 1]);
               delete(src);
               obj.VidIm = imagesc(obj.VidImAx,...
                  x,y,squeeze(obj.C_(obj.iCur_,:,:,:)),...
                  'UserData',true,'ButtonDownFcn',@obj.setROI);
               obj.FrameIndexFlagFcn_ = @(x)setFrameIndexFlag_BufferMode(obj);
            case 3 % Right-click to cancel
               if ~flag
                  return;
               end
               nigeLab.sounds.play('pop');
               obj.BuffSize_ = 1;
               obj.iCur_ = 1;
               obj.iCol_ = [];
               obj.iRow_ = [];
               obj.C_ = [];
               
               x = [0 1];
               y = [0 1];
               delete(src);
               obj.VidIm = imagesc(obj.VidImAx,x,y,...
                  readFrame(obj.VFR,'native'),'UserData',false,...
                  'ButtonDownFcn',@obj.setROI); 
               obj.FrameTime = get(obj.VFR,'CurrentTime');
               obj.FrameIndexFlagFcn_ = @(x)setFrameIndexFlag_NormalMode(obj);
         end
         obj.AnimalNameLabel.String = getAnimalNameLabel(obj);
      end
      
      % Set FrameIndex flags to know if we should update VFR FrameTime
      function setFrameIndexFlag(obj)
         %SETFRAMEINDEXFLAG  Listener callback to know if need VFR update
         %
         %  setFrameIndexFlag(obj)
         %  --> PostSet listener callback for '.FrameIndex' property

         feval(obj.FrameIndexFlagFcn_);
      end
      
      function setFrameIndexFlag_BufferMode(obj)
         % Compute FrameIndex updated difference
         delta = obj.FrameIndex - obj.FrameIndex_;
         obj.iCur_ = obj.iCur_ + delta;
         % If this puts at a point where we need update, then flag it.
         obj.NeedsUpdate_ = (obj.iCur_ < 1) || (obj.iCur_ > obj.N_BUFFER_FRAMES);
      end
      
      function setFrameIndexFlag_NormalMode(obj)
         % Compute FrameIndex updated difference
         delta = obj.FrameIndex - obj.FrameIndex_;
         % Reading sequentially without changing the .VFR.CurrentTime
         % property allows the VideoReader to go faster, as the codecs
         % rely on assumptions about temporal continuity regarding how
         % the video would be watched (to go faster)
         obj.NeedsUpdate_ = (delta~=1);
      end
      
      % Updates .C_ Buffer for video frames
      function updateBuffer(obj)
         %UPDATEBUFFER  Updates .C_ Buffer for video frames
         %
         %  updateBuffer(obj)
         %  --> Reads in images to .C_ so they can be "cached"
         
         fprintf(1,'Buffering...');
         N = obj.N_BUFFER_FRAMES;
         iStart = obj.FrameIndex - ceil(N/2);
         prevFrame = max(1,iStart);
         iStop = (prevFrame+N-1);
         maxFrame = min(obj.NumFrames,iStop);
         obj.BuffSize_ = N - (prevFrame - iStart) + (maxFrame - iStop);
         
         obj.iCur_ = ceil(N/2) - (N - obj.BuffSize_);
         set(obj.VFR,'CurrentTime',(prevFrame-1)/obj.FPS);
         
         obj.C_ = zeros(obj.BuffSize_,...
            numel(obj.iRow_),numel(obj.iCol_),3,'uint8');
         bufIdx = 1;
         obj.BufferedFrames_ = prevFrame:maxFrame;
         for iFrame = obj.BufferedFrames_
            C = readFrame(obj.VFR,'native');
            obj.C_(bufIdx,:,:,:) = C(obj.iRow_,obj.iCol_,:);
            bufIdx = bufIdx + 1;
         end
         fprintf(1,'complete\n');
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
         
         % NeedsUpdate_ gets set on
         % VidGraphics/setFrameIndexFlag(obj,forceUpdate), regardless of
         % "normal" or "cropped" state. If forceUpdate is true,
         % "NeedsUpdate_" changes to true regardless. 
         if obj.NeedsUpdate_
            set(obj.VFR,'CurrentTime',obj.FrameTime);
         end
         if isempty(obj.C_) % No buffer: read from video
            set(obj.VidIm,'CData',readFrame(obj.VFR,'native')); 
            
         else % Otherwise, we will read from buffer and/or update buffer
            % If we are out-of-bounds (for the buffer), 
            % update buffer before loading image.
            if obj.NeedsUpdate_
               updateBuffer(obj);
            end
            % Update video frame. Note that obj.iCur_ has already been
            % updated, when obj.FrameIndex was set (via listener callback:
            % VidGraphics/setFrameIndexFlag(obj,forceUpdate)
            set(obj.VidIm,'CData',squeeze(obj.C_(obj.iCur_,:,:,:)));
            
            % If we are at either "edge" of buffer, now we should update it
            % (This way, buffer is loaded for next request)
            if (obj.iCur_ == 1) || (obj.iCur_ == obj.BuffSize_)
               updateBuffer(obj);
            end
         end
         drawnow;         
      end
      
      % [LISTENER CALLBACK]: obj.Figure.WindowKeyReleaseFcn
      function updateTimeLabelsCB(obj,tFrame,tNeu)
         % Update current FrameTime display (NeuTime only updates if set)

         if nargin == 1
            tFrame = obj.FrameTime;
            tNeu = obj.NeuTime;
         end
         
         tStrVid = nigeLab.utils.sec2time(tFrame);
         tVid_ms = round(rem(tFrame,1)*1000);
         set(obj.VidTimeLabel,'String',...
            sprintf('Video Time:  %s.%03g ',tStrVid,tVid_ms));
         
         tNeu_ms = round(rem(tNeu,1)*1000);
         tStrNeu = nigeLab.utils.sec2time(tNeu);
         set(obj.NeuralTimeLabel,'String',...
            sprintf('Neural Time:  %s.%03g ',tStrNeu,tNeu_ms));
      end
   end
   
   % PROTECTED 
   methods (Access=protected)      
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
            'FontName','DroidSans',...
            'FontSize',13,...
            'Position',[0.875 0.765 0.125 0.230],...
            'Value',obj.VideoIndex,... % Initialize to the first video in list
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
            'FontName','DroidSans',...
            'FontSize',0.50,...
            'FontWeight','normal',...
            'HorizontalAlignment','left',...
            'Clipping','off',...
            'Color',nigeLab.defaults.nigelColors('onsurface'));
         
         obj.DataLabel = text(obj.VidMetaDisp, ...
            0.99, 0.25, '', ...
            'FontUnits', 'Normalized', ...
            'FontName','DroidSans',...
            'FontSize',0.50,...
            'FontWeight','normal',...
            'HorizontalAlignment','right',...
            'Clipping','off',...
            'Color',nigeLab.defaults.nigelColors('onsurface'));
         
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
            'NextPlot','replacechildren',...
            'XColor','none',...
            'YColor','none',...
            'XLimMode','manual',...
            'XLim',[0 1],...
            'YLimMode','manual',...
            'YTick',[],...
            'XTick',[],...
            'YLim',[0 1],...
            'YDir','reverse');
         nestObj(obj.Panel,obj.VidImAx,'VidImAx');
         
         % Make image object
         x = uint8([0 1]);
         y = uint8([0 1]);
         obj.iCur_ = nan;
         obj.VidIm = imagesc(obj.VidImAx,x,y,readFrame(obj.VFR,'native'),...
            'UserData',false,'ButtonDownFcn',@obj.setROI); 
         obj.FrameTime = get(obj.VFR,'CurrentTime');
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
      
      % Get names of unique video "Sources"
      function initVidSource(obj)
         % INITVIDSOURCE  Get names for listbox for video selection
         %
         %  obj.buildVidSelectionList;
         
         % Get list of video names        
         vidNames = cell(numel(obj.Block.Videos),1);
         for i = 1:numel(obj.Block.Videos)
            vidNames{i} = sprintf('%s::%s',obj.Block.Videos(i).Source,...
               obj.Block.Videos(i).Index);
         end
         obj.VideoName_   = vidNames;
         obj.VideoSourceList_ = unique({obj.Block.Videos.Source}');
         obj.VideoSource_ = obj.VideoSourceList_{1};
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
               flag = -inf;
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
      
      % Set the current video frame
      function tNeu = setFrame(obj,newFrame)
         % SETFRAME  Set frame index of current video frame and update it
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
         tNeu = obj.NeuTime;
         
         % Make sure that frame is within valid range
         newIndex = checkIfFrameIsOutOfBounds(obj,newFrame);
         if isnan(newIndex) % Then correct video
            obj.FrameIndex = newFrame; 
         elseif isinf(newIndex) % Then give up
            if newIndex < 0
               obj.FrameTime = 0;
            else
               obj.FrameTime = Max(obj.SeriesList);
            end
            return;
         else % Otherwise check new video in series
            obj.SeriesIndex = newIndex; 
            obj.FrameTime = obj.NeuTime-obj.NeuOffset-obj.TrialOffset;
            return;
         end
         
         % Set the displayed frame and check to update buffer if needed
         updateFrameImage(obj);
         
         % Update scroll bar in 'TimeAxes' object plot
         indicateTime(obj.TimeAxes);
         
         % Return the "best-estimate" neural time
         tNeu = obj.FrameTime+obj.GrossOffset+obj.TrialOffset;
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
   % % % % % % % % % % END METHODS% % %
end