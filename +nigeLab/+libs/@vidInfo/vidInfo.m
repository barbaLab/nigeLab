classdef vidInfo < handle
% VIDINFO  Constructor for nigeLab.libs.vidInfo object
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

%% Properties
   properties (SetAccess = immutable, GetAccess = public)
      Block    % nigeLab.Block class object handle
      Panel    % nigeLab.libs.nigelPanel container for display graphics
   end

   properties(SetAccess = public, GetAccess = public)
      
      vidPanel        % Container for video
      
      vidListIdx = 0    % Index of current video in use (from array)
      frame = 0;        % Frame currently viewed
      playTimer         % Video playback timer
      
      videoStart = 0  % Video offset from neural data (seconds)
      vid_F           % Struct from 'dir' of videos associated with object
      
      f     % field name for scoring events ('ScoredEvents' by default)
   end
   
   properties(SetAccess = private, GetAccess = private)
      FPS               % Frames per second
      maxFrame          % Total number of frames in video
      TimerPeriod       % Time between video play timer refresh requests
      
      NeuralTimeDisp % Graphics object: displays frame equivalent neural time
      AnimalNameDisp % Graphics object: displays name of animal
      HUDPanel % Graphics object: container for "heads-up-display"
      VidTimeDisp % Graphics object: displays frame equivalent video time
      VidSelectPanel % Graphics object: container for video selection lists
      VidSelectListBox % Graphics object: listbox for selecting specific video
      VidImAx % Graphics object: Axes with video image frames shown on it
      VidIm % Graphics object: Handle to image frame image object
      
      tNeu = 0              % Current neural data time
      tVid = 0              % Current video time
   end
   
   properties(SetAccess = immutable, GetAccess = private)
      verbose = false; % For debugging
   end
   
%% Events
   events
      frameChanged  % Emitted AFTER any frame changes
      timesUpdated  % Emitted AFTER any video/neural times are updated
      vidChanged    % Emitted AFTER video is changed
      offsetChanged % Emitted AFTER offset is changed
   end
   
%% Methods
   methods (Access = public)
      % Create the video information object
      function obj = vidInfo(blockObj,nigelPanelObj)
         % VIDINFO  Constructor for nigeLab.libs.vidInfo object
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

         % Assign key properties in constructor
         if ~isa(blockObj,'nigeLab.Block')
            error('First input argument must be class nigeLab.Block');
         end
         obj.Block = blockObj;
         
         if nargin < 2
            nigelPanelObj = nigeLab.libs.nigelPanel(...
               'Units','Normalized',...
               'Tag','vidInfo',...
               'Position',[0 0 1 1],...
               'Scrollable','off');
         end
         obj.Panel = nigelPanelObj;
         
         obj.f = obj.Block.Pars.Video.ScoringEventFieldName;
         obj.vid_F = getVid_F(obj.Block.Videos.v); 
         
         % Initialize current video time
         obj.setVidTime(); % no input: default to tVid == 0
         
         % Make video panel display and the "Heads Up Display" (HUD)
         obj.buildVidDisplay;
         obj.buildHeadsUpDisplay(obj.vid_F(1).name);
         
         % Construct video selection interface and load video
         obj.buildVidSelectionList;
      end
       
      % Play or pause the video
      function playPauseVid(obj)
         % PLAYPAUSEVID  Toggle between stopping and starting the "play
         %               video" timer.
         
         %toggle between stoping and starting the "play video" timer
         if strcmp(get(obj.playTimer,'Running'), 'off')
            set(obj.playTimer, 'Period', obj.TimerPeriod);
            start(obj.playTimer);
         else
            stop(obj.playTimer);
         end
      end
      
      % Function that runs while video is playing from timer object
      function advanceFrame(obj,~,~) 
         % ADVANCEFRAME Increment the current frame by 1
         
         %executed at each timer period, when playing the video
         newFrame = obj.frame + 1;
         obj.setFrame(newFrame);
      end
      
      % Function to go backwards some frames
      function retreatFrame(obj,n)
         % RETREATFRAME  Go backwards n frames
         %
         %  obj.retreatFrame(n);
         
         newFrame = obj.frame - n;
         obj.setFrame(newFrame);
      end
   end
   
   % "GET" methods
   methods (Access = public)
      % Return graphics objects struct associated with video object
      function graphics = getGraphics(obj)
         % GETGRAPHICS  Returns graphics struct with fields as graphics
         %
         %  graphics = obj.getGraphics;
         
         graphics = struct('neuTime_display',obj.NeuralTimeDisp,...
            'vidTime_display',obj.VidTimeDisp,...
            'vidSelect_listBox',obj.VidSelectListBox,...
            'image_display',obj.VidIm,...
            'image_displayAx',obj.VidImAx,...
            'hud_panel',obj.HUDPanel);
      end
      
      % Return corresponding time for video or neural data
      function t = getTime(obj,t_type,val)
         % GETTIME  Returns time or converted time for either 'neu' or
         %          'vid' depending on value of "t_type" input. If no "val"
         %          is specified, then it returns the corresponding current
         %          video time based on "t_type."
         %
         %  t = obj.getTime();       Returns current video time (default)
         %
         %  t = obj.getTime('neu');  Returns current neural time
         %  --> Can specify as {'neu','neural','data'} all would work
         %     (Use interchangeably to add clarity on use of method call)
         %
         %  t = obj.getTime('vid');  Returns current video time
         %  --> Can specify as {'cur','current','v','frame'} all would work
         %     (Use interchangeably to add clarity on use of method call)
         %
         %  tVid = obj.getTime('vid',neu_t); % Converts neu_t to video time
         %
         %  tNeu = obj.getTime('neu',vid_t); % Converts vid_t to neu time
         
         % If less than 2 args, return current vid time
         if nargin < 2
            t_type = 'vid';
         end
         
         % If less than 3 args, then return either current neu or vid time
         if nargin < 3
            switch lower(t_type)
               case {'neu','neural','data'}
                  t = obj.tNeu;
               case {'vid','cur','current','v','frame'}
                  t = obj.tVid;
               otherwise
                  error('Invalid value of t_type: %s',t_type);
            end
            return;
         end
         
         % If all 3 args, then do conversion
         switch lower(t_type)
            case {'neu','neural','data'}
               t = obj.toNeuTime(val);
            case {'vid','cur','current','v','frame'}
               t = obj.toVidTime(val);
            otherwise
               error('Invalid value of t_type: %s',t_type);
         end
      end
   end
   
   % "REFERENCE" methods to data in obj.Block.Events
   methods (Access = public)
      % Quick reference to putative Trial times
      function ts = Trial(obj,trialIdx)
         % TRIAL  Returns column vector of putative trial times (seconds)
         %
         %  ts = obj.Trial; Returns all values of Trial
         %  ts = obj.Trial(trialIdx); Returns indexed values of Trial
         

         ts = getEventData(obj.Block,obj.f,'ts','Trial');
         if nargin > 1
            ts = ts(trialIdx);
         end

      end
      
      
   end

   % "SET" methods
   methods (Access = public)
      % Set the current video index for the listener object
      function setCurrentVideo(obj,src,~)
         % SETCURRENTVIDEO  Set the current video index based on the Value
         %                  of a uicontrol (src)
         %
         %  uiControlPushButton.Callback = @obj.setCurrentVideo;
         %
         %  src: uicontrol with Value that corresponds to index of Videos
         
         % If source is uicontrol listbox, then parse the index as its
         % 'Value' property. Otherwise, index can be given directly as an
         % argument.
         if isa(src,'matlab.ui.control.UIControl')
            val = src.Value;
         elseif isnumeric(src) % Can give index directly
            val = src;
         end
         
         % If the given video index value is the same as the current video 
         % index, don't update anything
         if val == obj.vidListIdx % obj.vidListIdx is initialized to zero
            return;
         end
         
         % Update value of vidListIdx and issue 'vidChanged' notification
         obj.vidListIdx = val;
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.vidInfo',...
               'setCurrentVideo');
            fprintf(1,'-->\tvidChanged event issued: %s\n',s);
         end 
         notify(obj,'vidChanged');

      end
      
      % Set the current video frame
      function setFrame(obj,newFrame,forceSet)
         % SETFRAME  Set frame index of current video frame and update it
         %
         % obj.setFrame;            % Initialize frames (newFrame == 1)
         % obj.setFrame(newFrame);  % changes frame to newFrame (if valid)
         % obj.setFrame(newFrame,forceSet); % Sets idx even if newFrame ==
         %                                      obj.frame
         
         if nargin < 2
            newFrame = 1;
         end
         
         if nargin < 3
            forceSet = false;
         end
         
         % If newFrame is out of range, do nothing
         if (newFrame < 1) || (newFrame > obj.maxFrame)
            return;
         end
            
         % If newFrame is same as previous frame, do nothing
         if (newFrame == obj.frame) && (~forceSet)
            % obj.frame is initialized to zero on constructor
            if obj.verbose
               s = nigeLab.utils.getNigeLink(...
                  'nigeLab.libs.vidInfo',...
                  'setFrame');
               fprintf(1,'-->\tnewFrame (%g) == obj.frame (%g): %s\n',...
                  newFrame,obj.frame,s);
            end
            return;
         end
         
         % If newFrame is valid, update frame index and corresponding time
         obj.frame = newFrame;
         obj.updateTime;

         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.vidInfo',...
               'setFrame');
            fprintf(1,'-->\tframeChanged event issued: %s\n',s);
         end 
         notify(obj,'frameChanged');
      end
      
      % Set the current video time
      function setFrameFromTime(obj,newVidTime)
         % SETFRAMEFROMTIME  Change the frame to that of newVidTime
         %             NOTE: This method changes the actual video frame,
         %             but does not change the video offset between video
         %             time and neural data. Therefore, the frame and video
         %             data are both changed.
         %
         %  obj.setVidFromTime(); % Goes to first frame (time == 0)
         %  obj.setVidFromTime(newVidTime); % Update obj.tVid to newVidTime
         
         % If no "newVidTime" input, initialize current time to zero
         if nargin < 2
            newVidTime = 0;
         end
         
         % Do error checking on "newVidTime" input
         if (~isnumeric(newVidTime)) || (~isscalar(newVidTime))
            error('newVidTime must be a numeric scalar.');
         end
         
         if isnan(newVidTime)
            error('newVidTime cannot be NaN.');
         end
         
         if isempty(newVidTime)
            error('newVidTime cannot be empty.');
         end
         
         % Update the frame value
         newFrame = floor(newVidTime * obj.FPS)+1; % Not zero-indexed
         obj.setFrame(newFrame,true);
      end
      
      % Change the video offset
      function setOffset(obj,new_offset)
         % SETOFFSET  Update the offset to new_offset
         %
         %  obj.setOffset(new_offset);
         
         % Check for invalid values
         if ~isnumeric(new_offset)
            error('new_offset must be a numeric value.');
         end
         
         if isnan(new_offset)
            error('new_offset should not be NaN.');
         end
         
         % Update offset value
         obj.videoStart = new_offset;
         
         % Also update the actual offset between tNeu and tVid
         obj.tNeu = obj.tVid + new_offset(max(obj.vidListIdx,1));
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.vidInfo',...
               'setOffset');
            fprintf(1,'-->\toffsetChanged event issued: %s\n',s);
         end 
         notify(obj,'offsetChanged');
      end
      
      % Add information about a new video file
      function setVideoInfo(obj,frameRate,nFrames)
         % SETVIDEOINFO  Add information about new video file
         %
         %  obj.setVideoInfo(frameRate,nFrames); 
         %
         %  inputs:
         %  frameRate  --  Frames per second of video recording
         %  nFrames  --  Total number of frames in video recording
         
         obj.FPS = frameRate; 
         obj.maxFrame = nFrames;

         obj.TimerPeriod = 2*round(1000/obj.FPS)/1000;
         obj.playTimer = timer('TimerFcn',@obj.advanceFrame, ...
                               'ExecutionMode','fixedRate');
         setFrame(obj);
      end
      
      % Set the current video time
      function setVidTime(obj,newVidTime)
         % SETVIDTIME  Sets obj.tVid to that of newVidTime
         %             NOTE: this sets the video time for the CURRENT
         %             frame. It does not change the video frame. It DOES
         %             update the video offset (between tVid and tNeu).
         %
         %  obj.setVidTime();             % Initialize obj.tVid to zero
         %  obj.setVidTime(newVidTime);   % Update obj.tVid to newVidTime
         
         % If no "newVidTime" input, initialize current time to zero
         if nargin < 2
            newVidTime = 0;
         end
         
         % Do error checking on "newVidTime" input
         if (~isnumeric(newVidTime)) || (~isscalar(newVidTime))
            error('newVidTime must be a numeric scalar.');
         end
         
         if isnan(newVidTime)
            error('newVidTime cannot be NaN.');
         end
         
         if isempty(newVidTime)
            error('newVidTime cannot be empty.');
         end
         
         % Update private obj.tVid property
         obj.tVid = newVidTime;
         % Update videoStart property
         obj.videoStart(max(obj.vidListIdx,1)) = obj.tNeu - obj.tVid;
         
      end
   end
   
   % "BUILD" methods to be referenced within this class only
   methods (Access = private)
      % Build "Heads Up Display" (HUD)
      function buildHeadsUpDisplay(obj,label)
         % BUILDHEADSUPDISPLAY  Builds the "Heads-Up-Display" (HUD) that
         %                      has the animal name, current video time,
         %                      and corresponding sync'd neural time.
         %
         %  obj.buildHeadsUpDisplay(label); --> From method of vidInfo obj
         %
         %  label: String that goes at the top about the video. Typically
         %           this is the video filename. If not given, defaults to
         %           'Video'
         
         if nargin < 2
            label = 'Video';
         end
         
         obj.HUDPanel = nigeLab.libs.nigelPanel(obj.Panel,...
            'Units','Normalized',...
            'String',strrep(label,'_','\_'),...
            'Position',[0 0.765 0.75 0.235],...
            'TitleBarLocation','bottom',...
            'TitleBarColor',nigeLab.defaults.nigelColors('surface'),...
            'TitleColor',nigeLab.defaults.nigelColors('onsurface'),...
            'Tag','HUDPanel');
         obj.Panel.nestObj(obj.HUDPanel,'HUDPanel');
         
         obj.VidTimeDisp = annotation(obj.HUDPanel.Panel, ...
            'textbox',[0.125 0.35 0.25 0.20],...
            'Units', 'Normalized', ...
            'Position', [0.125 0.35 0.25 0.20], ...
            'FontName','DroidSans',...
            'FontSize',24,...
            'FontWeight','bold',...
            'Color',nigeLab.defaults.nigelColors('onsurface'),...
            'EdgeColor','none',...
            'String','loading...');
 
         obj.NeuralTimeDisp = annotation(obj.HUDPanel.Panel,...
            'textbox',[0.625 0.35 0.25 0.20],...
            'Units', 'Normalized', ...
            'Position', [0.625 0.35 0.25 0.20], ...
            'Color',nigeLab.defaults.nigelColors('onsurface'),...
            'FontName','DroidSans',...
            'FontSize',24,...
            'FontWeight','bold',...
            'EdgeColor','none',...
            'String', 'loading...');
      end
      
      % Build video display
      function buildVidDisplay(obj)
         % BUILDVIDDISPLAY  Initialize the video display axes and image
         %
         %  obj.buildVidDisplay;
         
         % Make image object container axes
         obj.VidImAx=axes(obj.Panel.Panel,...
            'Units','Normalized',...
            'Position',[0 0 1 0.75],...
            'NextPlot','replacechildren',...
            'XTick',[],...
            'YTick',[],...
            'XLim',[0 1],...
            'YLim',[0 1],...
            'XLimMode','manual',...
            'YLimMode','manual',...
            'YDir','reverse');
         obj.Panel.nestObj(obj.VidImAx,'VidImAx');
         
         % Make image object
         C=zeros(2,2); 
         x = [0 1];
         y = [0 1];
         obj.VidIm = imagesc(obj.VidImAx,x,y,C); 
      end
      
      % Build listbox for video selection
      function buildVidSelectionList(obj)
         % BUILDVIDSELECTIONLIST  Build listbox for video selection
         %
         %  obj.buildVidSelectionList;
         
         % Panel for selecting which video
         obj.VidSelectPanel = nigeLab.libs.nigelPanel(obj.Panel,...
            'Units','Normalized',...
            'String','Video List',...
            'TitleFontSize',8,...
            'TitleFontWeight','normal',...
            'TitleStringX',0.35,...
            'Position',[0.75 0.75 0.25 0.25],...
            'TitleBarColor',nigeLab.defaults.nigelColors('secondary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onsecondary'),...
            'Tag','VidSelectPanel');
         obj.Panel.nestObj(obj.VidSelectPanel,'VidSelectPanel');
         
         % List of videos
         obj.VidSelectListBox = uicontrol(obj.VidSelectPanel.Panel,...
            'Style','listbox',...
            'Units','Normalized',...
            'FontName','Arial',...
            'FontSize',14,...
            'Position',[0.025 0.025 0.95 0.95],...
            'Value',1,...
            'String',{obj.vid_F.name}.',...
            'Callback',@obj.setCurrentVideo);
      end
      
   end
   
   % Methods from older naming convention (to be deprecated)
   methods (Access = public, Hidden = true)
      % Get "neural time" from corresponding video timestamp
      function neuTime = toNeuTime(obj,vid_t)
         % TONEUTIME  Returns the converted neural time based on video time
         %
         %  neuTime = obj.toNeuTime(vid_t);  vid_t: Video timestamp
         
         neuTime = vid_t + obj.videoStart(obj.vidListIdx);
      end
      
      % Get "video time" from corresponding neural timestamp
      function vidTime = toVidTime(obj,neu_t)
         % TOVIDTIME  Returns the converted video time based on neural time
         %
         %  vidTime = obj.toVidTime(neu_t);  neu_t: Neural timestamp
         
         vidTime = neu_t - obj.videoStart(obj.vidListIdx);
      end  

   end
   
   % "UPDATE" methods to be referenced within this class only
   methods (Access = private)
      % Update the video and neural times
      function updateTime(obj)
         % UPDATETIME  Update the video and neural times to reflect new
         %             position in the record.
         %
         %  obj.updateTime;  Uses obj.frame, obj.FPS to set video time
         %                   (obj.tVid); after setting obj.tVid, updates
         %                   neural time (obj.tNeu) with known offset
         %                   between video and neural data (obj.videoStart)
         
         % obj.frame should be set prior to "updateTime"
         obj.tVid = obj.frame / obj.FPS;
         obj.tNeu = obj.tVid + obj.videoStart;
         if obj.verbose
            s = nigeLab.utils.getNigeLink(...
               'nigeLab.libs.vidInfo',...
               'updateTime');
            fprintf(1,'-->\ttimesUpdated event issued: %s\n',s);
         end 
         notify(obj,'timesUpdated');
      end
   end
   
end