classdef TimeScrollerAxes < matlab.mixin.SetGet
   %TIMESCROLLERAXES  Axes that allows "jumping" through a movie
   %
   %  ax = nigeLab.libs.TimeScrollerAxes(VidGraphicsObj);
   
   % % % PROPERTIES % % % % % % % % % %
   % DEPENDENT,PUBLIC
   properties (Dependent,Access=public)
      FrameTime   (1,1) double    % From .V (time of current frame)
      NeuOffset   (1,1) double    % Alignment offset between vid and dig
      TrialOffset (1,1) double    % Trial/Camera-specific offset
      Verbose     (1,1) logical   % From obj.V
      VideoOffset (1,1) double    % Alignment offset from start of video series
   end
   
   % DEPENDENT,TRANSIENT,PUBLIC
   properties (Dependent,Transient,Access=public)
      Panel          % "Parent" panel object
   end
   
   % TRANSIENT,PUBLIC
   properties (Transient,Access=public)
      V              % "Parent" Vid object
   end
   
   % HIDDEN,DEPENDENT,PUBLIC
   properties (Hidden,Dependent,Access=public)
      Figure         % "Parent" figure object
      XLim           % X limits depend on parent Video object
   end
   
   % HIDDEN,PUBLIC
   properties (Hidden,Access=public)
      Axes           % axes container
      Legend         % legend on axes
      Now            % Vertical line, "current time" indicator
   end
   
   % HIDDEN,PUBLIC/PROTECTED
   properties (Hidden,GetAccess=public,SetAccess=protected)
      ZoomLevel      (1,1) double = 0  % Index for XLim "zoom"
   end
   
   % PROTECTED
   properties (Access=protected)
      ax_   (1,1)struct                % Struct with info for Axes
      dig     % nigeLab.libs.nigelStreams object or array of digital streams
      flags (1,1)struct                % "flags" struct of logical values
      mode       char                  % 'score' or 'align'
      vid     % nigeLab.libs.nigelStreams object or array of video streams
      x     (1,1)struct                % "XData" struct of position values
   end
   
   % CONSTANT,PROTECTED
   properties (Constant,Access=protected)
      ZoomedOffset = [4 1 1e-3]
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % EVENTS % % % % % % % % % % % %
   events (ListenAccess=public,NotifyAccess=public)
      AxesClicked  % To indicate "skip" to a particular time point
      LimitReached % "Video Limit" bound exceeded
   end
   % % % % % % % % % % END EVENTS % % %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded get/set)
   methods
      % [DEPENDENT]  Returns .Figure (from "parent" VidGraphics object)
      function value = get.Figure(obj)
         %GET.FIGURE  Returns .Figure from "parent" VidGraphics object
         %
         %  value = get(obj,'Figure');
         
         value = [];
         if isempty(obj.V)
            return;
         end
         value = obj.V.Figure;
      end
      % [DEPENDENT]  Assign .Figure (cannot)
      function set.Figure(obj,value)
         % SET.FIGURE  DOES NOTHING
         if isempty(obj.V)
            if obj.Verbose
               nigeLab.sounds.play('pop',2.7);
               dbstack();
               nigeLab.utils.cprintf('Errors*','[TIMESCROLLERAXES]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Failed attempt to set DEPENDENT property: Verbose\n');
               fprintf(1,'\n');
            end
         end
         obj.V.Figure = value;
      end
      
      % [DEPENDENT]  Returns .FrameTime (from "parent" VidGraphics object)
      function value = get.FrameTime(obj)
         %GET.FRAMETIME  Returns .FrameTime from "parent" VidGraphics object
         %
         %  value = get(obj,'FrameTime');
         %  --> If unset, default value is 0
         
         if isempty(obj.V)
            value = 0;
            return;
         end
         value = obj.V.FrameTime;
         
      end
      % [DEPENDENT]  Assign .FrameTime to parent
      function set.FrameTime(obj,value)
         %SET.FRAMETIME  Assigns to parent VideoGraphics object
         if isempty(obj.V)
            return;
         end
         obj.V.FrameTime = value;
      end
      
      % [DEPENDENT]  Returns .NeuOffset (from "parent" VidGraphics object)
      function value = get.NeuOffset(obj)
         %GET.OFFSET  Returns .Figure from "parent" VidGraphics object
         %
         %  value = get(obj,'NeuOffset');
         %  --> If unset, default value is 0
         if isempty(obj.V)
            value = 0;
            return;
         end
         value = obj.V.NeuOffset;
      end
      % [DEPENDENT]  Assign .NeuOffset
      function set.NeuOffset(obj,value)
         %SET.NEUOFFSET  set(obj.V,'NeuOffset',value);
         if isempty(obj.V)
            if obj.Verbose
               nigeLab.sounds.play('pop',2.7);
               dbstack();
               nigeLab.utils.cprintf('Errors*','[TIMESCROLLERAXES]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Failed attempt to set DEPENDENT property: NeuOffset\n');
               fprintf(1,'\n');
            end
            return;
         end
         obj.V.NeuOffset = value;
      end
      
      % [DEPENDENT]  Returns .Panel (from "parent" VidGraphics object)
      function value = get.Panel(obj)
         %GET.PANEL  Returns .Panel from "parent" VidGraphics object
         %
         %  value = get(obj,'Panel');
         %  --> If unset, return empty
         
         if isempty(obj.V)
            value = [];
            if obj.Verbose
               nigeLab.sounds.play('pop',2.7);
               dbstack();
               nigeLab.utils.cprintf('Errors*','[TIMESCROLLERAXES]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Failed attempt to get DEPENDENT property: Panel\n');
               fprintf(1,'\n');
            end
            return;
         end
         value = obj.V.TimePanel;
      end
      % [DEPENDENT]  Assign .Panel (cannot)
      function set.Panel(obj,~)
         %SET.PANEL   (Does nothing)
         if obj.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[TIMESCROLLERAXES]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Panel\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .TrialOffset (from "parent" VidGraphics object)
      function value = get.TrialOffset(obj)
         %GET.TRIALOFFSET  Returns .TrialOffset from "parent" VidGraphics object
         %
         %  value = get(obj,'TrialOffset');
         %  --> If unset, default value is 0
         if isempty(obj.V)
            value = 0;
            return;
         end
         value = obj.V.TrialOffset;
      end
      % [DEPENDENT]  Assign .NeuOffset
      function set.TrialOffset(obj,value)
         %SET.TRIALOFFSET  set(obj.V,'TrialOffset',value);
         if isempty(obj.V)
            if obj.Verbose
               nigeLab.sounds.play('pop',2.7);
               dbstack();
               nigeLab.utils.cprintf('Errors*','[TIMESCROLLERAXES]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Failed attempt to set DEPENDENT property: TrialOffset\n');
               fprintf(1,'\n');
            end
            return;
         end
         obj.V.TrialOffset = value;
      end
      
      % [DEPENDENT]  Returns .Verbose (from "parent" VidGraphics object)
      function value = get.Verbose(obj)
         %GET.VERBOSE  Returns .Figure from "parent" VidGraphics object
         %
         %  value = get(obj,'Verbose');
         %  --> If unset, default value is true
         
         value = true;
         if isempty(obj.V)
            return;
         end
         value = obj.V.Verbose;
      end
      % [DEPENDENT]  Assign .VideoOffset (does nothing)
      function set.Verbose(obj,~)
         %SET.VERBOSE  (Does nothing)
         if obj.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[TIMESCROLLERAXES]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Verbose\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .VideoOffset (from "parent" VidGraphics object)
      function value = get.VideoOffset(obj)
         %GET.VideoOffset  Returns .Figure from "parent" VidGraphics object
         %
         %  value = get(obj,'VideoOffset');
         %  --> If unset, default value is 0
         
         if isempty(obj.V)
            value = 0;
            return;
         end
         value = obj.V.VideoOffset;
      end
      % [DEPENDENT]  Assign .VideoOffset (assigns to parent VideoGraphics)
      function set.VideoOffset(obj,value)
         %SET.VideoOffset  Assigns to parent VideoGraphics object
         %
         %  set(obj,'VideoOffset',value);
         %  --> Updates parent VideoGraphics object .VideoOffset property
         
         if isempty(obj.V)
            return;
         end
         obj.V.VideoOffset = value;
      end
      
      % [DEPENDENT]  Returns .XLim (from "parent" VidGraphics object)
      function value = get.XLim(obj)
         %GET.XLIM  Returns .Figure from "parent" VidGraphics object
         %
         %  value = get(obj,'XLim');
         
         value = [];
         if isempty(obj.V)
            return;
         elseif isempty(obj.V.VideoSource)
            return;
         end
         value = [0, Max(FromSame(obj.V.Block.Videos,obj.V.VideoSource))];
      end
      % [DEPENDENT]  Assign .XLim
      function set.XLim(obj,~)
         %SET.XLIM  set(obj,'XLim',__);
         
         if isempty(obj.Axes)
            return;
         elseif ~isvalid(obj.Axes)
            return;
         end
         value = [0, Max(FromSame(obj.V.Block.Videos,obj.V.VideoSource))];
         set(obj.Axes,'XLim',value);
      end
   end
   
   % RESTRICTED:nigeLab.libs.VidGraphics
   methods (Access=?nigeLab.libs.VidGraphics)
      % Constructor
      function obj = TimeScrollerAxes(VidGraphicsObj,initMode)
         %TIMESCROLLERAXES  Axes that allows "jumping" through a movie
         %
         %  ax = nigeLab.libs.TimeScrollerAxes(VidGraphicsObj);
         %
         %  ax = nigeLab.libs.TimeScrollerAxes(VidGraphicsObj,'align');
         %  --> Assumes "alignment" configs
         %
         %  ax = nigeLab.libs.TimeScrollerAxes(VidGraphicsObj,'score');
         %  --> Assumes "score" configs (default)
         
         % Allow empty constructor etc.
         if nargin < 1
            obj = nigeLab.libs.TimeScrollerAxes.empty();
            return;
         elseif isnumeric(VidGraphicsObj)
            dims = VidGraphicsObj;
            if numel(dims) < 2 
               dims = [zeros(1,2-numel(dims)),dims];
            end
            obj = repmat(obj,dims);
            return;
         end
         
         if nargin < 2
            initMode = 'score';
         end
         
         obj.V = VidGraphicsObj;
         xLim = [0 Max(obj.V.Block.Videos)];
         
         % Initialize different property structs
         obj.flags = struct('BeingDragged',false,'Zoom',false);
         obj.x = struct('new',0,'orig',0,'cursor',0,'offset',0,'scaling',1);         
         obj.ax_ = struct('ZoomLevel',1,'MaxXVal',xLim(2),'XLim',xLim);
         
         % Depending on purpose, make application-specific differences here
         obj.mode = lower(initMode);
         switch obj.mode
            case 'score'
               buildTimeAxesGraphics(obj,false);
            case 'align'
               buildTimeAxesGraphics(obj,true);
            otherwise
               error(['nigeLab:' mfilename ':BadCase'],...
                  '[TIMESCROLLERAXES]: Not expecting ''%s'' initMode\n',...
                  initMode);
         end
         
         % Initialize x-scaling and x-offset (based on "Parents" of fig)
         parseXScaling(obj);
         obj.Figure.WindowButtonMotionFcn = @obj.cursorMotionCB;
      end
      
   end
   
   % PUBLIC
   methods (Access=public)
      
      % Add Digital Streams
      function addDigStreams(obj,varargin)
         %ADDDIGSTREAMS  Add digital streams to the time axes
         %
         %  addDigStreams(obj,struct('name','streamName'));
         %  addDigStreams(obj,'streamName');
         %  addDigStreams(obj,'streamName1','streamName2',...);
         
         if numel(varargin) > 1
            n = numel(varargin);
            streamName = varargin;
         else
            digStreamInfo = varargin{1};
            if isstruct(digStreamInfo)
               n = numel(digStreamInfo);
               streamName = cell(1,n);
               [streamName{:}] = deal(digStreamInfo.name);
            elseif ischar(digStreamInfo)
               n = 1;
               streamName = {digStreamInfo};
            end
         end
         
         k = numel(obj.dig);
         
         dig_ = struct(...
            'name',cell(1,n),...
            'obj',cell(1,n),...
            'fs',cell(1,n),...
            'index',cell(1,n),...
            'col',cell(1,n),...
            'shaded_col',cell(1,n),...
            'h',cell(1,n));
         
         keepvec = true(1,n);
         for i = 1:n
            tmp = getStream(obj.Block,streamName{i});
            if isempty(tmp)
               keepvec(i) = false;
               continue;
            end
            dig_(i).name = tmp.name(1:3);
            dig_(i).obj = tmp;
            dig_(i).fs = tmp.fs;
            dig_(i).index = i + k;
            dig_(i).col = min(1,(i+k)/5) * nigeLab.defaults.nigelColors('b');
            dig_(i).shaded_col = nigeLab.defaults.nigelColors('light');
            dig_(i).h = gobjects(1);
            obj.ax_.MaxXVal = max(obj.ax_.MaxXVal,max(dig_.obj.t));
         end
         dig_ = dig_(keepvec);
         obj.dig = horzcat(obj.dig,dig_);
      end
      
      % Add "Time Marker" line to axes
      function addTimeMarker(obj)
         %ADDTIMEMARKER  Adds "time marker" line to axes
         %
         %  addTimeMarker(obj);
         
         obj.Now = line(obj.Axes,[0 0],[0 1.1],...
            'DisplayName','Time',...
            'Tag','Time',...
            'LineWidth',2.5,...
            'LineStyle','none',...
            'Marker','v',...
            'MarkerIndices',2,... % Only show top marker
            'MarkerSize',16,...
            'MarkerEdgeColor',nigeLab.defaults.nigelColors('g'),...
            'MarkerFaceColor',nigeLab.defaults.nigelColors('g'),...
            'Color',nigeLab.defaults.nigelColors('g'),...
            'ButtonDownFcn',@(~,~)obj.axesClickedCB);
      end
      
      % Add Video Streams
      function addVidStreams(obj,varargin)
         %ADDVIDSTREAMS  Add video streams to the time axes
         %
         %  addVidStreams(obj,struct('name','streamName'));
         %  addVidStreams(obj,'streamName');
         %  addVidStreams(obj,'streamName1','streamName2',...);
         
         if numel(varargin) > 1
            n = numel(varargin);
            streamName = varargin;
         else
            vidStreamInfo = varargin{1};
            if isstruct(vidStreamInfo)
               n = numel(vidStreamInfo);
               streamName = cell(1,n);
               [streamName{:}] = deal(vidStreamInfo.name);
            elseif ischar(vidStreamInfo)
               n = 1;
               streamName = {vidStreamInfo};
            end
         end
         
         k = numel(obj.vid);

         vid_ = struct(...
            'name',cell(1,n),...
            'obj',cell(1,n),...
            'fs',cell(1,n),...
            'col',cell(1,n),...
            'index',cell(1,n),...
            'h',cell(1,n));
         keepvec = true(1,n);
         for i = 1:n
            camOpts = nigeLab.utils.initCamOpts(...
               'csource','cname',...
               'cname',streamName{i});
            s = getStream(obj.Block.Videos,camOpts);
            if isempty(s)
               keepvec(i) = false;
               continue;
            end
            vid_.name = s.name(1:3);
            vid_.obj = s;
            vid_.fs = s.fs;
            vid_.index = i + k;
            vid_(i).col = min(1,(i+k)/5) * nigeLab.defaults.nigelColors('r');
            vid_.h = gobjects(1);
            obj.ax_.MaxXVal = max(obj.ax_.MaxXVal,max(vid_.obj.t));
         end
         vid_ = vid_(keepvec);
         obj.vid = horzcat(obj.vid,vid_);
      end
      
      % Compute the relative change in alignment and update alignment Lag
      function new_align_offset = computeOffset(obj,init_pt,moved_pt)
         % COMPUTEOFFSET  Get the relative change in alignment and update
         %                the alignment Lag
         %
         %  new_align_offset = obj.computeOffset(init_pt,moved_pt);
         %
         %  init_pt  :  Initial point ("in memory") of where the stream
         %                 used to be.
         %
         %  moved_pt :  New updated point of where the stream has been
         %                 moved to. 
         %
         %  The difference (delta = init_pt - moved_pt) is equivalent to a
         %  "change in alignment offset"; therefore, the new alignment
         %  (obj.offset) is equal to the previous obj.offset + delta.
         
         align_offset_delta = init_pt - moved_pt;
         new_align_offset = obj.NeuOffset + align_offset_delta;
         
      end
      
      % Update time for indicator "marker" associated with current frame
      function indicateTime(obj)        
         %INDICATETIME  Updates the time "marker" 
         %
         %  indicateTime(obj);
         
         % If VidTimeLine is not empty, that means there is the alignment
         % axis plot so we should update that too:

         set(obj.Now,'XData',ones(1,2) * (obj.FrameTime+obj.VideoOffset));
            
         % Fix axis limits
         axLim = obj.Axes.XLim;
         if (obj.FrameTime >= axLim(2)) || (obj.FrameTime <= axLim(1))
            updateZoom(obj);
         end
      end
      
      % Set new neural offset
      function setNewOffset(obj,x)
         % SETNEWOFFSET  Sets new neural offset, using the value in x and
         %               the current neural time marker XData. The
         %
         %  obj.setNewOffset(x);   x could be, for example, some new value
         %                          of the time we think the offset should
         %                          be moved to.
         
         delta_offset = x - obj.Now.XData(1);
         obj.NeuOffset = obj.NeuOffset - delta_offset;
         
         % Moves the beam and press streams, relative to VIDEO
         for i = 1:numel(obj.dig)
            obj.dig(i).h.XData = obj.dig(i).obj.t - obj.NeuOffset;
         end
      end
      
      % Update Zoom based on "ZoomLevel" and current location of cursor
      function updateZoom(obj)
         %UPDATEZOOM  Update Zoom based on "Zoom Level" and current cursor
         %
         %  updateZoom(obj);
         
         if obj.ZoomLevel > 0
            xLim = [obj.V.FrameTime - obj.ZoomedOffset(obj.ZoomLevel),...
                    obj.V.FrameTime + obj.ZoomedOffset(obj.ZoomLevel)];
         else
            if isempty(obj.XLim)
               xLim = obj.ax_.XLim;
            else
               xLim = obj.XLim;
            end
         end
         set(obj.Axes,'XLim',xLim);
      end
      
      % Zoom out on beam break/paw probability time series (top axis)
      function zoomOut(obj)
         % ZOOMOUT  Make the axes x-limits larger, to effectively zoom out
         %          the streams so that it's easier to look at the general
         %          trend of matching transitions for streams through time.
         %
         %  obj.zoomOut;
         
         obj.ZoomLevel = max(obj.ZoomLevel+1,0);
         updateZoom(obj);
         for i = 1:numel(obj.dig)
            set(obj.dig(i).h,'LineWidth',1);
         end
         set(obj.Now,'LineStyle','none');
         obj.flags.Zoom = false;
      end
      
      % Zoom in on beam break/paw probability time series (top axis)
      function zoomIn(obj)
         % ZOOMIN  Make the axes x-limits smaller, to effectively "zoom" on
         %         the streams so that transitions from LOW TO HIGH or HIGH
         %         TO LOW are clearer with respect to the marker for the
         %         current frame.
         %
         %  obj.zoomIn;
         
         obj.ZoomLevel = min(obj.ZoomLevel+1,numel(obj.ZoomedOffset));
         updateZoom(obj);
         obj.flags.Zoom = true;
         for i = 1:numel(obj.dig)
            set(obj.dig(i).h,'LineWidth',2);
         end
         set(obj.Now,'LineStyle',':');
      end
      
   end
   
   % SEALED,PROTECTED
   methods (Sealed,Access=protected)
      % When axes is clicked, depends on mouse location
      function axesClickedCB(obj,~,~)
         % AXESCLICKEDCB  ButtonDownFcn for the alignment axes and its children
         %
         %  ax.ButtonDownFcn = @obj.axesClickedCB;
         
         obj.x.orig = obj.Axes.CurrentPoint(1,1);
         
         % If FLAG is enabled
         if obj.flags.BeingDragged
            % Place the (dragged) neural (beam/press) streams with cursor
            set(obj,'XLim',[]);
            for i = 1:numel(obj.dig)
               obj.dig(i).h.Color = obj.dig.h.UserData;
               obj.dig(i).h.LineWidth = 2;
               obj.dig(i).h.LineStyle = '-';
            end
            obj.moveStreamFlag = false;            
         else % Otherwise, allows to skip to point in video
            evt = nigeLab.evt.timeAxesClicked(obj.x.orig);
            notify(obj,'AxesClicked',evt);
         end
      end
      
      % Update the current cursor X-position in figure frame, taking into
      % account: Width of any parent panels, width of axes relative to
      % panels.
      function cursorMotionCB(obj,src,~)
         % CURSORMOTIONCB  Update the current cursor X-position based on
         %               mouse cursor movement in current figure frame.
         %
         %  fig.WindowButtonMotionFcn = @obj.setCursorPos;  
         %
         %  alignInfoObj is not associated with a figure handle explicitly;
         %  therefore, this method can be set as a callback for any figure
         %  it is "attached" to 

         winX = src.CurrentPoint(1,1);
         unscaledX = winX-obj.x.offset;
         curX = unscaledX / (obj.x.scaling / diff(obj.Axes.XLim));
         
         obj.x.cursor = curX;
         if obj.flags.BeingDragged
            % If the flag is HIGH, then compute a new offset and
            % set the alignment using the current cursor position.
            new_align_offset = obj.computeOffset(obj.x.new,obj.x.cursor);
            obj.x.new = obj.x.cursor;
            setNewOffset(obj,new_align_offset); % update the shadow positions
            
         end
      end
      
      % ButtonDownFcn for neural sync time series (beam/press)
      function seriesClickedCB(obj,src,~)
         % SERIESCLICKEDCB  ButtonDownFcn callback for clicking on 
         %                  the neural sync time series 
         %                  (e.g. BEAM BREAKS or BUTTON PRESS)
         
         if ~obj.flags.BeingDragged
            % Toggle to "dragging" the data stream graphic object
            obj.flags.BeingDragged = true;
            obj.x.new = obj.x.cursor;
            src.Color = nigeLab.defaults.nigelColors('light');
            src.LineStyle = '--';
            src.LineWidth = 2.5;
         else
            % "Release" the data stream graphic object
            src.Color = src.UserData;
            src.LineStyle = '-';
            src.LineWidth = 1.5;
            set(obj,'XLim',[]);
            obj.flags.BeingDragged = false;
         end
         
      end
   end
   
   % PROTECTED
   methods (Access=protected)      
      % Make all the graphics for tracking relative position of neural
      function buildTimeAxesGraphics(obj,autoInitStreams)
         % BUILDSTREAMGRAPHICS  Make all graphics for tracking relative
         %                      position of neural-sync'd streams (e.g.
         %                      BEAM BREAK or BUTTON PRESS) with video
         %                      (e.g. PAW PROBABILITY) time series.
         %
         %  obj.buildStreamsGraphics(nigelPanelObj);
         
         if nargin < 2
            autoInitStreams = false;
         end
         
         if isempty(obj.XLim)
            xLim = obj.ax_.XLim;
         else
            xLim = obj.XLim;
         end
         
         if max(xLim) > 60
            tUnits = 'm';
            tVal = linspace(0,max(xLim)/60,6);
         else
            tUnits = 's';
            tVal = linspace(0,max(xLim),6);
         end
         tLabel = sprintf('%4.3g:',tVal);
         tLabel = strsplit(tLabel(1:(end-1)),':');
         tVec = linspace(0,max(xLim),6);
         
         % Make axes for graphics objects
         obj.Axes = axes(...
            'Units','Normalized',...
            'Position',[0 0.15 1 0.7],...
            'NextPlot','add',...
            'Color',nigeLab.defaults.nigelColors('background'),...
            'XColor','w',...
            'XLim',xLim,...
            'XTick',tVec,...
            'XTickLabels',tLabel,...
            'YLim',[-0.2 1.2],...
            'YColor','none',...
            'YTick',[],...
            'Tag','TimeAxes',...
            'ButtonDownFcn',@obj.axesClickedCB);
         nestObj(obj.V.TimePanel,obj.Axes,'TimeScrollerAxes');
         xlabel(obj.Axes,sprintf('Time (%s)',tUnits),...
            'FontName','Arial','FontWeight','bold','Color','w');
         
         if autoInitStreams
            initTimeAxesStreamData;
         else
            plotAllStreams(obj);
         end
      end
      
      % Initialize struct for main graphics reference
      function initTimeAxesStreamData(obj,digStreamInfo,vidStreamInfo)
         % INITTIMEAXESSTREAMDATA  Initialize struct for main graphics ref
         %
         %  obj.initTimeAxesStreamData;
         %
         %  Initializes obj.dig and obj.vid structs
         
         if nargin < 3
            vidStreamInfo = obj.Block.UserData.vidStreamInfo;
         end
         
         if nargin < 2
            digStreamInfo = obj.Block.UserData.digStreamInfo;
         end
         
         % Initialize the streams
         addDigStreams(obj,digStreamInfo);
         addVidStreams(obj,vidStreamInfo);
         
         % Add the rest of the graphics
         plotAllStreams(obj);
      end
      
      % Parse scaling and offset constants for x data (relative to figure)
      function parseXScaling(obj)
         %PARSEXSCALING  Parse scaling and offset constants for x-data
         %
         %  parseXScaling(obj);
         
         MAX_DEPTH = 10; % To prevent unwanted accidental infinite loop
         
         p = obj.Panel;
         k = 0;
         while (~isa(p,'matlab.ui.Figure')) && (k < MAX_DEPTH)
            if ~strcmpi(p.Units,'Normalized')
               set(p,'Units','Normalized');
            end
            k = k + 1;
            % "Total" offset is incremented by parent container x-offset
            obj.x.offset = p.Position(1) * obj.x.scaling;
            % "Total" scaling is fraction of parent container width
            obj.x.scaling = obj.x.scaling * p.Position(3); 
            
            p = p.Parent;
         end
         if k == MAX_DEPTH
            error(['nigeLab:' mfilename ':BadContainerStructure'],...
               ['[TIMESCROLLERAXES]: TimeAxes is nested within at least ' ...
               '10 layers of containers-- is this correct?']);
         end
      end
      
      % Plot all streams on axes
      function plotAllStreams(obj)
         % Plot video stream (if it's present) 
         
         cla(obj.Axes);
         % Add "segments" indicating timing from different vids
         tmp = FromSame(obj.V.Block.Videos,obj.V.VideoSource);
         c = linspace(0.75,0.95,numel(tmp)-1);
         for i = 1:(numel(tmp)-1)
            t = max(tmp(i).tVid);
            sep = line(obj.Axes,[t,t],[-0.15 0.05],...
               'LineWidth',2,'Color','k',...
               'Displayname','','Tag','',...
               'MarkerIndices',1,'Marker','^','LineStyle','-',...
               'MarkerFaceColor',ones(1,3)*c(i),...
               'MarkerEdgeColor',ones(1,3)*c(i),...
               'LineJoin','miter','PickableParts','none');
            sep.Annotation.LegendInformation.IconDisplayStyle = 'off';
         end
         
         % Add indicator for current times
         addTimeMarker(obj);   
         
         % Add any potential streams
         for i = 1:numel(obj.vid)
            v = obj.vid(i);
            obj.vid(i).h = ...
               plot(obj.Axes,v.t,v.obj.data,...
               'Color',v.col,'Displayname',v.name,'Tag',v.name,...
               'ButtonDownFcn',@obj.axesClickedCB);
         end

         % Plot any digital streams (if present)
         for i = 1:numel(obj.dig)
            d = obj.dig(i);
            obj.dig(i).h = ...
               plot(obj.Axes,d.t,d.obj.data,...
               'Tag',d.name,'DisplayName',d.name,...
               'LineWidth',1.5,'Color',d.col,...
               'UserData',d.shaded_col,...
               'ButtonDownFcn',@obj.seriesClickedCB);
         end
         
         if isempty(obj.vid)
            vname = {};
         else
            vname = horzcat(obj.vid.name);
         end
         
         if isempty(obj.dig)
            dname = {};
         else
            dname = horzcat(obj.dig.name);
         end

         if ~isempty(obj.Legend)
            if isvalid(obj.Legend)
               delete(obj.Legend);
            end
         end
         obj.Legend = legend(obj.Axes,['Frame', vname, dname],...
            'Orientation','horizontal',...
            'FontName','DroidSans',...
            'FontSize',12,...
            'Location','best');
         obj.Legend.Color = nigeLab.defaults.nigelColors('bg');
         obj.Legend.Box = 'off';
         obj.Legend.TextColor = 'w';
         set(obj,'XLim',[]);
      end
   end
   
   % STATIC,PUBLIC
   methods (Static,Access=public)
      % Create "Empty" object or object array
      function obj = empty(n)
         %EMPTY  Return empty nigeLab.libs.TimeScrollerAxes object or array
         %
         %  obj = nigeLab.libs.TimeScrollerAxes.empty();
         %  --> Return scalar (0 x 0) object
         %
         %  obj = nigeLab.libs.TimeScrollerAxes.empty(n);
         %  --> Specify number of empty objects
         
         if nargin < 1
            dims = [0, 0];
         else
            if ~isscalar(n)
               error(['nigeLab:' mfilename ':invalidEmptyDims'],...
                  'Input to nigeLab.libs.TimeScrollerAxes.empty should be scalar.');
            end
            dims = [0, n];
         end
         
         obj = nigeLab.libs.TimeScrollerAxes(dims);
      end
   end
   % % % % % % % % % % END METHODS% % %
end

