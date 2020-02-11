classdef VidGraphics < matlab.mixin.SetGet
% VIDINFO  Constructor for nigeLab.libs.VidGraphics object
%
%  obj = nigeLab.libs.vidInfo(blockObj);
%  obj = nigeLab.libs.vidInfo(blockObj,nigelPanelObj);
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

   % % % PROPERTIES % % % % % % % % % %
   % TRANSIENT,PUBLIC
   properties (Transient,Access=public)
      Block     % nigeLab.Block class object handle
      Figure    % "parent" figure handle
      Panel     % nigeLab.libs.nigelPanel container for display graphics
      PlayTimer           timer          % Video playback timer
      TimePanel % nigeLab.libs.nigelPanel for Time graphics
      TimeAxes  % nigeLab.libs.TimeScrollerAxes
   end

   % PUBLIC
   properties (Access=public)
      FrameIndex    (1,1) double = nan   % Frame currently viewed
   end
   
   % DEPENDENT,PUBLIC
   properties (Dependent,Access=public)
      FPS         (1,1) double   % Frames per second
      FrameTime   (1,1) double   % Timestamp of current frame
      GrossOffset (1,1) double   % NeuOffset + VideoOffset
      NeuOffset   (1,1) double   % Offset from video to neural data
      NumFrames   (1,1) double   % Maximum number of frames
      SeriesIndex (1,1) double   % Movie index within series
      TrialOffset (1,1) double   % "Specific" trial/camera offset for individual trial
      NeuTime     (1,1) double   % Current Neural time
      TimerPeriod (1,1) double   % Time between video play timer refresh requests
      Verbose     (1,1) logical  % Display extra text to command window for debug?
      VideoIndex  (1,1) double   % Index of current video in use (from array)
      VideoOffset (1,1) double   % Offset relative to start of video-series
      VideoSource       char     % 'View' for camera for video(s) under consideration
   end
   
   % TRANSIENT,DEPENDENT,PUBLIC
   properties (Transient,Dependent,Access=public)
      VFR         VideoReader    % Video File reader
      Video                      % nigeLab.libs.VideosFieldType object
   end

   % PUBLIC/PROTECTED
   properties (GetAccess=public,SetAccess=protected)
      NeuralTimeLabel   % Graphics object: displays frame equivalent neural time
      AnimalNameLabel    % Graphics object: displays name of animal
      HUDPanel          % Graphics object: container for "heads-up-display"
      TimeDisp          % Graphics object: container for Time annotations
      VidTimeDisp       % Graphics object: displays frame equivalent video time
      VidSelectPanel    % Graphics object: container for video selection lists
      VidSelectListBox  % Graphics object: listbox for selecting specific video
      VidImAx           % Graphics object: Axes with video image frames shown on it
      VidIm             % Graphics object: Handle to image frame image object
   end
   
   % TRANSIENT,PROTECTED
   properties (Transient,Access=protected)
      SeriesList                 % Videos related to this video
      lh                         % event.listeners array
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
         
         % Construct "heads up display" with time axes and vid selector
         buildHeadsUpDisplay(obj,initMode);
         
         % Construct video "display" interface
         buildVidDisplay(obj);
         
         % Initialize the timer object
         obj.PlayTimer = timer('TimerFcn',@(~,~)obj.advanceFrame(1), ...
                               'ExecutionMode','fixedSpacing');
         
         % Add alignment stuff
         obj.Figure = obj.Panel.Parent;
         
         % "Force" select the video (for init)
         selectVideo(obj,1,true);
      end
       
   end
   
   % NO ATTRIBUTES (overloaded methods)
   methods
      % [DEPENDENT]  Returns .FrameTime property
      function value = get.FrameTime(obj)
         %GET.FRAMETIME  Returns .FrameTime property
         %
         %  value = get(obj,'FrameTime');
         
         value = 0; % Init to zero
         if isnan(obj.FPS)
            return;
         elseif isnan(obj.FrameIndex)
            return;
         end
          
         value = (obj.FrameIndex-1) / obj.FPS; 
      end
      % [DEPENDENT]  Assigns .FrameTime property (sets .FrameIndex)
      function set.FrameTime(obj,value)
         %SET.FRAMETIME  Assigns .FrameTime property (sets .FrameIndex)
         %
         %  set(obj,'FrameTime',value);
         %  NOTE: This "set" method DOES NOT CHANGE obj.NeuTime
         
         if isnan(obj.FPS)
            return;
         end
         % Set FrameIndex; only remove .VideoOffset ("series" offset)
         newFrame = round((value - obj.VideoOffset) * obj.FPS + 1);
         setFrame(obj,newFrame); % This updates the FrameTime display
         
      end
      
      % [DEPENDENT] Returns .GrossOffset property (from linked Video obj)
      function value = get.GrossOffset(obj)
         %GET.GROSSOFFSET  Returns .GrossOffset property (from Video obj)
         %
         %  value = get(obj,'GrossOffset');
         
         if isempty(obj.Video)
            value = 0;
            return;
         end
         value = obj.Video.GrossOffset;
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
         
         if isempty(obj.Video)
            return;
         end
         obj.Video.GrossOffset = value;
         set(obj,'NeuTime',obj.FrameTime+obj.GrossOffset+obj.TrialOffset);
      end
      
      % [DEPENDENT]  Returns .NeuTime property
      function value = get.NeuTime(obj)
         %GET.NEUTIME  Returns .NeuTime property
         %
         %  value = get(obj,'NeuTime');
         
         value = 0; % Init to zero
         if isempty(obj.Block)
            return;
         end
         value = obj.FrameTime + obj.VideoOffset + obj.NeuOffset;
      end
      % [DEPENDENT]  Assigns .NeuTime property
      function set.NeuTime(obj,value)
         %SET.FRAMETIME  Does nothing
         
         % At least update the time display
         if ~isempty(obj.NeuralTimeLabel)
            if isvalid(obj.NeuralTimeLabel)
               tNeu_ms = round(rem(value,1)*1000);
               tStrNeu = nigeLab.utils.sec2time(value);
               set(obj.NeuralTimeLabel,'String',...
                  sprintf('Neural Time: %s.%03g',tStrNeu,tNeu_ms));
            end
         end
         if isempty(obj.Block)
            return;
         end
         obj.Block.CurNeuralTime = value;
      end
      
      % [DEPENDENT] Returns .NeuOffset property (from linked Video obj)
      function value = get.NeuOffset(obj)
         %GET.NEUOFFSET  Returns .NeuOffset property (from linked Video obj)
         %
         %  value = get(obj,'NeuOffset');
         %  --> Returns NaN or offset between video and neural time
         %  (positive value for neural data started before video record)
         
         if isempty(obj.Block)
            value = nan;
            return;
         end
         
         offset_neu = obj.Video.GrossOffset; % Neural offset
         offset_specific = obj.Block.TrialVideoOffset(...
            obj.VideoIndex,obj.Block.TrialIndex);
         value = offset_neu + offset_specific;
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
         
         if isempty(obj.Video)
            return;
         end
         obj.Video.NeuOffset = value;
         set(obj,'NeuTime',obj.FrameTime+obj.GrossOffset+obj.TrialOffset);
      end
      
      % [DEPENDENT] Returns .TrialOffset property (from linked Block)
      function value = get.TrialOffset(obj)
         %GET.NEUOFFSET  Returns .NeuOffset property (from linked Block)
         %
         %  value = get(obj,'TrialOffset');
         %  --> Returns Trial/Camera-specific offset for current trial
         
         if isempty(obj.Video)
            value = 0;
            return;
         end
         value = obj.Video.TrialOffset;
      end
      % [DEPENDENT] Assign .TrialOffset property
      function set.TrialOffset(obj,value)
         %SET.TRIALOFFSET  Assign corresponding video of linked Block   
         %
         %  set(obj,'TrialOffset',value);
         %  --> value should be:
         %  value = (tNeu - tEvent) - GrossOffset;
         %  Where "GrossOffset" is the VideosFieldType.GrossOffset property
         
         if isempty(obj.Video)
            return;
         end
         obj.Video.TrialOffset = value;
      end
      
      % [DEPENDENT]  Returns .SeriesIndex (index to .SeriesList)
      function value = get.SeriesIndex(obj)
         %GET.SERIESINDEX Returns .SeriesIndex (index in .SeriesList)
         
         if isempty(obj.SeriesList)
            value = 1;
            return;
         elseif isempty(obj.Video)
            value = 1;
            return;
         end
         value = findVideo(obj.Video,obj.SeriesList);
      end
      % [DEPENDENT]  Assigns .SeriesIndex property
      function set.SeriesIndex(obj,value)
         %SET.SERIESINDEX  Updates .SeriesIndex and resets the Frame
         
         obj.VideoIndex = findVideo(obj.SeriesList(value));
      end
      
      % [DEPENDENT]  Returns .TimerPeriod property (from .FPS)
      function value = get.TimerPeriod(obj)
         %GET.TIMERPERIOD  Returns .TimerPeriod property (from .FPS)
         
         if isnan(obj.FPS)
            value = 0.034; % 60 fps default
            return;
         end
         value = 2*round(1000/obj.FPS)/1000;
      end
      % [DEPENDENT]  Assigns .TimerPeriod property (cannot)
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
      
      % [DEPENDENT]  Returns .VFR property (from linked VideosFieldType)
      function value = get.VFR(obj)
         %GET.VFR  Returns .VFR property (VideoFileReader from link)
         %
         %  value = get(obj,'VFR');
         %  --> Returns 'VideoReader' object from obj.Block.Videos(curVid)
         
         if isempty(obj.Block)
            value = VideoReader.empty();
            return;
         end
         vObj = obj.Block.Videos(obj.VideoIndex); 
         value = Ready(vObj); % Return "readied" object
      end
      % [DEPENDENT] Assign .VFR property (cannot)
      function set.VFR(~,~)
         %SET.VFR  Does nothing
         if obj.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDINFO.SET]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: VFR\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns "linked" Video object
      function value = get.Video(obj)
         %GET.VIDEO  Returns "linked" Video object (.Video property)
         %
         %  value = get(obj,'Video');
         %  --> Returns current element of Block.Videos, a
         %  nigeLab.libs.VideosFieldType object
         
         if isempty(obj.Block)
            value = [];
            return;
         end
         
         value = obj.Block.Videos(obj.VideoIndex);
      end
      % [DEPENDENT]  Assigns "linked" Video object
      function set.Video(obj,value)
         %SET.VIDEO  Sets "linked" Video object (.Video property)
         %
         %  set(obj,'Video',value);
         %  --> Updates the listbox Index to the indicated .Video object
         
         if isempty(obj.Block)
            return;
         end
         obj.VideoIndex = value.VideoIndex;
      end
      
      % [DEPENDENT]  Returns Index for Video from .ListBox
      function value = get.VideoIndex(obj)
         %GET.VIDEOINDEX  Returns "Source" for Video (from .Videos)
         %
         %  value = get(obj,'VideoIndex');
         %  --> Returns index to video from list of videos in listbox
         
         value = 1;
         if isempty(obj.VidSelectListBox)
            return;
         elseif ~isvalid(obj.VidSelectListBox)
            return;
         end
         value = obj.VidSelectListBox.Value;
      end
      % [DEPENDENT]  Assigns Index for Video based on .ListBox
      function set.VideoIndex(obj,value)
         %SET.VIDEOINDEX  Assigns index of video based on .ListBox         
         if isempty(obj.VidSelectListBox)
            return;
         elseif ~isvalid(obj.VidSelectListBox)
            return;
         end
         obj.VidSelectListBox.Value = value;
      end
      
      % [DEPENDENT]  Returns "Source" for Video
      function value = get.VideoSource(obj)
         %GET.VIDEOSOURCE  Returns "Source" for Video (from .Videos)
         %
         %  value = get(obj,'VideoSource');
         %  --> Returns camera angle, such as 'Front' or 'Left-A'
         
         value = '';
         if isempty(obj.Block)
            return;
         end
         
         value = obj.Block.Videos(obj.VideoIndex).Source;
      end
      % [DEPENDENT]  Assigns "Source" for Video
      function set.VideoSource(obj,~)
         %SET.VIDEOSOURCE  Does nothing
         
         if obj.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDINFO.SET]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: VideoSource\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT] Returns .VideoOffset property (from linked Video obj)
      function value = get.VideoOffset(obj)
         %GET.OFFSET  Returns .VideoOffset property (from linked Video obj)
         %
         %  value = get(obj,'VideoOffset');
         %  --> Returns NaN or offset between video and neural time
         %  (positive value for neural data started before video record)
         
         if isempty(obj.Video)
            value = nan;
            return;
         end
         value = obj.Video.VideoOffset; % Video "series" offset
      end
      % [DEPENDENT] Assign .VideoOffset property
      function set.VideoOffset(obj,value)
         %SET.VideoOffset  Assign corresponding video of linked Block
         obj.Block.Videos(obj.VideoIndex).VideoOffset = value;
         obj.Block.CurNeuralTime = obj.FrameTime + obj.VideoOffset + obj.NeuOffset;
      end
      
      % [DEPENDENT] Returns .FPS property (video frame rate)
      function value = get.FPS(obj)
         %GET.FPS  Returns .FPS property (video frame rate)
         %
         %  value = get(obj,'FPS');
         %  --> Returns .fs property of obj.Block.Videos(VideoIndex)
         
         value = nan;
         if isempty(obj.Block)
            return;
         end
         value = obj.Block.Videos(obj.VideoIndex).fs;
      end
      % [DEPENDENT] Assigns .FPS property (cannot)
      function set.FPS(~,~)
         %SET.FPS  Does nothing
         if obj.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDINFO.SET]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: FPS\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT] Returns .NumFrames property (total # frames in current)
      function value = get.NumFrames(obj)
         %GET.NUMFRAMES  Returns .NumFrames property (total # frames)
         %
         %  value = get(obj,'NumFrames');
         %  --> Returns .NumFrames from obj.Block.Videos(obj.VideoIndex);
         
         value = nan;
         if isempty(obj.Block)
            return;
         end
         value = obj.Block.Videos(obj.VideoIndex).NumFrames;
      end
      % [DEPENDENT] Assigns .NumFrames property (cannot)
      function set.NumFrames(~,~)
         %SET.NUMFRAMES  Does nothing
         if obj.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDINFO.SET]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: NumFrames\n');
            fprintf(1,'\n');
         end
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
         
         % Remove any valid listeners
         if ~isempty(obj.lh)
            for i = 1:numel(obj.lh)
               if isvalid(obj.lh(i))
                  delete(obj.lh(i));
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
      function addListeners(obj)
         %ADDLISTENERS  Add listeners for time change events
         %
         %  addListeners(obj);
         
         obj.lh=[...
            addlistener(obj.TimeAxes,'AxesClicked', @obj.axesClickCB),...
            addlistener(obj.Block,'TrialIndex','PostSet',@obj.trialIndexListenerCB)...
         ];
      end
      
      % % % SCORING % % %
      % Function that runs while video is playing from timer object
      function advanceFrame(obj,n) 
         % ADVANCEFRAME Increment the current frame by n frames
         %
         %  obj.advanceFrame;    Advance frame index by 1 frame
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
         elseif ~islogical(forceSelection)
            forceSelection = false;
         end
         
         % Do not re-load video if it's the same index
         if (idx == obj.VideoIndex) && ~forceSelection
            return;
         end
         
         % Set video index (updates .VFR)
         if ~isa(src,'matlab.ui.control.UIControl')
            obj.VideoIndex = idx;    
         end
         
         obj.SeriesList = FromSame(obj.Block.Videos,obj.VideoSource);
         
         if forceSelection
            obj.NeuTime = obj.Block.Trial(obj.Block.TrialIndex);
            % If this is out of range, will select correct video:
            obj.FrameTime = obj.NeuTime - obj.VideoOffset; 
         else
            obj.FrameTime = 0;
         end
         set(obj.TimeAxes,'XLim',[]);
      end
   end
   
   % PROTECTED 
   methods (Access=protected)      
      % Build "Heads Up Display" (HUD)
      function buildHeadsUpDisplay(obj,initMode)
         % BUILDHEADSUPDISPLAY  Builds the "Heads-Up-Display" (HUD) that
         %                      has the animal name, current video time,
         %                      and corresponding sync'd neural time.
         %
         %  obj.buildHeadsUpDisplay(label); --> From method of vidInfo obj
         %
         %  initMode : 'score' (default) or 'align'
         %  --> Used to initialize differently for 'TimeAxes' property
         
         if nargin < 2
            initMode = 'score';
         end
         
         % Construct video selection interface
         buildVidSelectionList(obj);
         
         % Nest the HUD panel in the main Panel
         label = obj.Block.Videos(obj.VideoIndex).Name;
         obj.HUDPanel = nigeLab.libs.nigelPanel(obj.Panel,...
            'Units','Normalized',...
            'String',strrep(label,'_','\_'),...
            'Position',[0 0.765 0.75 0.235],...
            'TitleBarLocation','bot',...
            'TitleBarColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleColor',nigeLab.defaults.nigelColors('onsurface'),...
            'Tag','HUDPanel');
         nestObj(obj.Panel,obj.HUDPanel,'HUDPanel');
         
         % Nest the "Time Axes" panel in the HUD panel
         obj.TimePanel = nigeLab.libs.nigelPanel(obj.HUDPanel.Panel,...
            'Units','Normalized',...
            'String','Video Timeline',...
            'Tag','TimeAxesPanel',...
            'Position',[0 0.35 0.5 0.6],...
            'Scrollable','off');
         nestObj(obj.HUDPanel,obj.TimePanel,'TimeAxesPanel');
         
         % Build "Time Axes" object for skipping & alignment
         obj.TimeAxes = nigeLab.libs.TimeScrollerAxes(obj,initMode);
         
         % Build "Time Display" axes container for showing time displays
         obj.TimeDisp = axes(obj.HUDPanel.Panel,...
            'Units','Normalized',...
            'Position',[0.5 0.5 0.5 0.5],...
            'Color','none',...
            'XColor','none',...
            'YColor','none',...
            'NextPlot','add');
         % Nest the "Time Display" container in the HUDPanel
         nestObj(obj.HUDPanel,obj.TimeDisp,'TimeDisp');
         
         obj.VidTimeDisp = text(obj.TimeDisp, ...
            0.025, 0.325, 'loading...', ...
            'Units', 'Normalized', ...
            'FontName','DroidSans',...
            'FontSize',24,...
            'FontWeight','bold',...
            'Color',nigeLab.defaults.nigelColors('onsurface'));
 
         obj.NeuralTimeLabel = text(obj.TimeDisp,...
            0.025, 0.725, 'loading...', ...
            'Units', 'Normalized', ...
            'Color',nigeLab.defaults.nigelColors('onsurface'),...
            'FontName','DroidSans',...
            'FontSize',24,...
            'FontWeight','bold');
         
         text(obj.TimeDisp,...
            0.025, 0.005, '(hh:mm:ss.sss)', ...
            'Units', 'Normalized', ...
            'Color',[0.66 0.66 0.66],...
            'FontName','DroidSans',...
            'FontSize',16);
      end
      
      % Build video display
      function buildVidDisplay(obj)
         % BUILDVIDDISPLAY  Initialize the video display axes and image
         %
         %  obj.buildVidDisplay;
         
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
            'YLim',[0 1],...
            'YDir','reverse');
         nestObj(obj.Panel,obj.VidImAx,'VidImAx');
         
         % Make image object
         C = readFrame(obj.VFR);
         obj.FrameTime = get(obj.VFR,'CurrentTime');
         x = [0 1];
         y = [0 1];
         obj.VidIm = imagesc(obj.VidImAx,x,y,C); 
      end
      
      % Build listbox for video selection
      function buildVidSelectionList(obj)
         % BUILDVIDSELECTIONLIST  Build listbox for video selection
         %
         %  obj.buildVidSelectionList;
         
         % Nest the video selection panel in the main panel
         obj.VidSelectPanel = nigeLab.libs.nigelPanel(obj.Panel,...
            'Units','Normalized',...
            'String','Video List',...
            'TitleFontSize',8,...
            'TitleFontWeight','normal',...
            'TitleStringX',0.5,...
            'TitleAlignment','center',...
            'FontName','DroidSans',...
            'Position',[0.75 0.75 0.25 0.25],...
            'TitleBarColor',nigeLab.defaults.nigelColors('secondary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onsecondary'),...
            'Tag','VidSelectPanel');
         nestObj(obj.Panel,obj.VidSelectPanel,'VidSelectPanel');
         
         % Only UI Control on this panel is the video selection listbox
         obj.VidSelectListBox = uicontrol(obj.VidSelectPanel.Panel,...
            'Style','listbox',...
            'Units','Normalized',...
            'FontName','DroidSans',...
            'FontSize',13,...
            'Position',[0.025 0.025 0.95 0.95],...
            'Value',1,... % Initialize to the first video in list
            'String',{obj.Block.Videos.Name}.',...
            'Callback',@obj.selectVideo);
         nestObj(obj.VidSelectPanel,obj.VidSelectListBox,'VidSelectListBox');
      end
   end
   
   % SEALED,PROTECTED
   methods (Sealed,Access=protected)
      % Callback function for 'axesClick' notification from graphics
      function axesClickCB(obj,~,evt)
         % AXESCLICKCB  Callback that listens for 'axesClick'
         %
         %  addlistener(graphicsUpdaterObj,...
         %       'axesClick',@obj.axesClickCB);
         %
         %  src  --  graphicsUpdaterObj
         %  evt  --  nigeLab.evt.timeAxesClicked event.eventdata
         %
         %  Note: This method changes BOTH obj.NeuTime and obj.FrameTime
         
         % No Video offset is needed; it is incorporated in evt.time:
         set(obj,'NeuTime',evt.time + obj.NeuOffset);
         
         % But, that means we must subtract it to get correct FrameTime:
         obj.FrameTime = evt.time - obj.VideoOffset;
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
         if (newFrame < 1)
            if obj.SeriesIndex > 1
               obj.SeriesIndex = obj.SeriesIndex - 1;
               obj.FrameTime = obj.NeuTime-obj.VideoOffset-obj.NeuOffset;
               return;
            else
               obj.FrameTime = 0;
               return;
            end
         elseif (newFrame > obj.NumFrames)
            if obj.SeriesIndex < numel(obj.SeriesList)
               obj.SeriesIndex = obj.SeriesIndex + 1;
               obj.FrameTime = obj.NeuTime-obj.VideoOffset-obj.NeuOffset;
               return;
            else
               if strcmp(obj.PlayTimer.Running,'on')
                  stop(obj.PlayTimer);
               end
               if ~isempty(obj.SeriesList)
                  obj.FrameTime = Max(obj.SeriesList);
               end
               return;
            end
         end
         
         % If newFrame is same as previous frame, do nothing
         if newFrame == obj.FrameIndex
            % obj.FrameIndex is initialized to 1 on constructor
            return;
         elseif isempty(obj.VidIm)
            return;
         elseif ~isvalid(obj.VidIm)
            return;
         end
         
         % If newFrame is valid, update frame index and corresponding time
         obj.FrameIndex = newFrame;
         set(obj.VFR,'CurrentTime',obj.FrameTime);
         set(obj.VidIm,'CData',readFrame(obj.VFR)); 
         indicateTime(obj.TimeAxes);
         
         % Return the "best-estimate" neural time by correcting for jitter 
         % on each trial
         tNeu = obj.FrameTime+obj.GrossOffset+obj.TrialOffset;
         
         % Update current FrameTime display (NeuTime only updates if set)
         tStrVid = nigeLab.utils.sec2time(obj.FrameTime);
         tVid_ms = round(rem(obj.FrameTime,1)*1000);
         set(obj.VidTimeDisp,'String',...
            sprintf('Video Time: %s.%03g',tStrVid,tVid_ms));
      end
      
      % [LISTENER CALLBACK]: Block.TrialIndex changes
      function trialIndexListenerCB(obj,~,~)
         %TRIALINDEXLISTENERCB  Update frame/time based on new Trial Index
         
         tNeu = obj.Block.Trial(obj.Block.TrialIndex);
         obj.NeuTime = tNeu;
         
         tSeries = obj.Block.Trial(obj.Block.TrialIndex)-obj.NeuOffset-obj.TrialOffset;
         obj.FrameTime = tSeries;
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