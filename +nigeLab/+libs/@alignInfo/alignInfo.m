classdef alignInfo < handle
% ALIGNINFO  Constructor for handle object that keeps track of
%            synchronization information between video record and
%            digital (neural) streams record.
%
%  obj = nigeLab.libs.alignInfo(blockObj);
%  obj = nigeLab.libs.alignInfo(blockObj,nigelPanelObj);

   % % % PROPERTIES % % % % % % % % % %
   % TRANSIENT,PUBLIC/IMMUTABLE
   properties(Transient,GetAccess=public,SetAccess=immutable)
      Block       % nigeLab.Block object handle
      Panel       % nigeLab.libs.nigelPanel object
      Figure      % Handle to figure containing streams plots
   end

   % PUBLIC/PROTECTED
   properties(GetAccess=public,SetAccess=protected)
      ax          % Axes to plot streams on
      
      tVid        % Current video time
      tNeu        % Current neural time
      
      dig      % Struct for "digital" reference (graphics handles go here)
      vid      % Struct for "video" reference (graphics handle go here)
      
      vidTime_line     % Line indicating current video time

      offset = 0;     % Current alignment lag offset
      timeAtClickedPoint      % Time corresponding to clicked point on axes
      
      curAxLim    % Axes limits for current axes
   end
   
   % PROTECTED
   properties(Access=protected)
      FS = 125;                  % Resampled rate for correlation
      VID_FS = 30000/1001;       % Frame-rate of video
      currentVid = 1;            % If there is a list of videos
      axLim = [0 1000];          % Stores "outer" axes ranges
      zoomOffset = 4;            % # Seconds to buffer zoom window
      moveStreamFlag = false;    % Flag for moving objects on top axes
      cursorX                    % "Locked" cursor time point to reference
      curOffsetPt                % Last-clicked position for dragging line
      xStart = -10;              % (seconds) - lowest x-point to plot
      zoomFlag = false;          % Is the time-series axis zoomed in?      
   end
   % % % % % % % % % % END PROPERTIES %

   % % % EVENTS % % % % % % % % % % % %
   % PUBLIC
   events (ListenAccess=public,NotifyAccess=public)
      offsetChanged  % Alignment has been dragged/moved in some way
      saveFile       % Output file has been saved
      axesClick      % Skip to current clicked point in axes (in video)
      zoomChanged    % Axes zoom has been altered
   end
   % % % % % % % % % % END EVENTS % % %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded methods, constructor)
   methods 
      % Construct alignInfo object that tracks offset between vid and neu
      function obj = alignInfo(blockObj,nigelPanelObj)
         % ALIGNINFO  Constructor for handle object that keeps track of
         %            synchronization information between video record and
         %            digital (neural) streams record.
         %
         %  obj = nigeLab.libs.alignInfo(blockObj);
         %  obj = nigeLab.libs.alignInfo(blockObj,nigelPanelObj);
         
         % Allow empty constructor etc.
         if nargin < 1
            obj = nigeLab.libs.alignInfo.empty();
            return;
         elseif isnumeric(blockObj)
            dims = blockObj;
            if numel(dims) < 2 
               dims = [zeros(1,2-numel(dims)),dims];
            end
            obj = repmat(obj,dims);
            return;
         end
         
         % Require that first argument is Block
         if ~isa(blockObj,'nigeLab.Block')
            error('First input argument must be of class nigeLab.Block');
         end
         obj.Block = blockObj;
         
         if nargin < 2
            fig = gcf;
            nigelPanelObj = nigeLab.libs.nigelPanel(fig,...
               'String',strrep(blockObj.Name,'_','\_'),...
               'Tag','alignPanel',...
               'Units','normalized',...
               'Position',[0 0 1 1],...
               'Scrollable','off',...
               'PanelColor',nigeLab.defaults.nigelColors('surface'),...
               'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
               'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
         elseif ~isa(nigelPanelObj,'nigeLab.libs.nigelPanel')
            error('Second input argument must be of class nigeLab.libs.nigelPanel');
         end
         
         obj.Panel = nigelPanelObj;
         
         if ~isa(obj.Panel.Parent,'matlab.ui.Figure')
            error(['Must be a "top-level" nigelPanel ' ...
                   '(nigelPanelObj.Parent must be a figure handle).']);
         end
         
         obj.Figure = obj.Panel.Parent;
         obj.Figure.WindowButtonMotionFcn = @obj.setCursorPos;

         obj.initGraphicsHandles();
         obj.buildStreamsGraphics;
         obj.initOffset();
      end
   end
   
   % PUBLIC
   methods (Access=public)
      % Create graphics objects associated with this class
      function graphics = getGraphics(obj)
         % GETGRAPHICS  Return a struct where fieldnames match graphics
         %              labels from other "Info" objects so that
         %              "graphicsUpdater" class can parse interactions with
         %              the correct objects.
         %
         %  graphics = obj.getGraphics;
         %
         %  --> 'vidTime_line'     :  obj.vidTime_line
         %  --> 'alignment_panel'  :  obj.AlignmentPanel
         
         % Pass everything to listener object in graphics struct
         graphics = struct(...
            'vidTime_line',obj.vidTime_line,...
            'alignment_panel',obj.Panel,...
            'stream_axes',obj.ax);
      end
      
      % Set new neural time
      function setNeuTime(obj,t)
         % SETNEUTIME  Set new value of neural time
         %
         %  obj.setNeuTime(t);  Sets obj.tNeu to t
         %  --> Does not change frame
         %  --> Does not recompute video offset
         
         obj.tNeu = t;
      end
      
      % Set new video time
      function setVidTime(obj,t)
         % SETVIDTIME  Set video time.
         %  
         %  obj.setVidTime(t);  Updates obj.tVid to t
         %  --> Does not change the video frame
         %  --> Does not recompute video offset
         
         obj.tVid = t;
      end
      
      % Set new neural offset
      function setNewOffset(obj,x)
         % SETNEWOFFSET  Sets new neural offset, using the value in x and
         %               the current neural time marker XData. The
         %
         %  obj.setNewOffset(x);   x could be, for example, some new value
         %                          of the time we think the offset should
         %                          be moved to.
         
         align_offset = x - obj.curNeuT.XData(1);
         align_offset = obj.offset - align_offset;
         
         obj.setAlignment(align_offset);
      end

      % Save the output file
      function saveAlignment(obj)
         % SAVEALIGNMENT  Save the alignment lag (output)
         %
         %  obj.saveAlignment;
         
         setEventData(obj.Block,[],'ts','Header',obj.offset);
         notify(obj,'saveFile');
      end
      
      % Zoom out on beam break/paw probability time series (top axis)
      function zoomOut(obj)
         % ZOOMOUT  Make the axes x-limits larger, to effectively zoom out
         %          the streams so that it's easier to look at the general
         %          trend of matching transitions for streams through time.
         %
         %  obj.zoomOut;
         
         set(obj.ax,'XLim',obj.axLim);
         obj.curAxLim = obj.axLim;
         for i = 1:numel(obj.dig)
            set(obj.dig(i).h,'LineWidth',1);
         end
         set(obj.vidTime_line,'LineStyle','none');
         obj.zoomFlag = false;
         notify(obj,'zoomChanged');
      end
      
      % Zoom in on beam break/paw probability time series (top axis)
      function zoomIn(obj)
         % ZOOMIN  Make the axes x-limits smaller, to effectively "zoom" on
         %         the streams so that transitions from LOW TO HIGH or HIGH
         %         TO LOW are clearer with respect to the marker for the
         %         current frame.
         %
         %  obj.zoomIn;
         
         obj.curAxLim = [obj.tVid - obj.zoomOffset,...
                         obj.tVid + obj.zoomOffset];
         set(obj.ax,'XLim',obj.curAxLim);
         obj.zoomFlag = true;
         for i = 1:numel(obj.dig)
            set(obj.dig(i).h,'LineWidth',2);
         end
         set(obj.vidTime_line,'LineStyle',':');
         notify(obj,'zoomChanged');
      end
      
   end
   
   % HIDDEN,PUBLIC (callbacks)
   methods (Hidden,Access=public)      
      % Callback for when time changes on graphicsUpdater object
      function timesChangedCB(obj,src,~)
         % TIMESCHANGEDCB  Callback that is requested whenever there is a
         %                 'timesChanged' event notification from src (in
         %                 this case, nigeLab.libs.graphicsUpdater class
         %                 object). 
         %
         %  addlistener(graphicsUpdaterObj,'timesChanged',...
         %              @alignInfoObj.timesChangedCB);
                  
         obj.setVidTime(src.tVid);
         obj.setNeuTime(src.tNeu);
      end
   end
   
   % PROTECTED
   methods (Access=protected)
      % Make all the graphics for tracking relative position of neural
      % (beam/press) and video (paw probability) time series
      function buildStreamsGraphics(obj)
         % BUILDSTREAMGRAPHICS  Make all graphics for tracking relative
         %                      position of neural-sync'd streams (e.g.
         %                      BEAM BREAK or BUTTON PRESS) with video
         %                      (e.g. PAW PROBABILITY) time series.
         %
         %  obj.buildStreamsGraphics(nigelPanelObj);
         
         % Make axes for graphics objects
         obj.ax = axes('Units','Normalized',...
              'Position',[0 0 1 1],...
              'NextPlot','add',...
              'XColor','w',...
              'YLim',[-0.2 1.2],...
              'YTick',[],...
              'Tag','Streams',...
              'ButtonDownFcn',@(~,~)obj.clickAxes);
         obj.Panel.nestObj(obj.ax,'Streams');
         
         % Make current position indicators for neural and video times
         x = zeros(1,2); % Vid starts at zero
         y = [0 1.1]; % Make slightly taller
         obj.vidTime_line = line(obj.ax,x,y,...
            'DisplayName','Current Frame',...
            'Tag','Frame',...
            'LineWidth',2.5,...
            'LineStyle','none',...
            'Marker','v',...
            'MarkerIndices',2,... % Only show top marker
            'MarkerSize',16,...
            'MarkerEdgeColor',nigeLab.defaults.nigelColors('b'),...
            'MarkerFaceColor',nigeLab.defaults.nigelColors('b'),...
            'Color',nigeLab.defaults.nigelColors('b'),...
            'ButtonDownFcn',@(~,~)obj.clickAxes);         
         
         
         % Plot video stream (if it's present)
         if ~isempty(obj.vid.h)
            obj.vid.h = plot(obj.ax,...
               obj.vid.t,...
               obj.vid.data,...
               'Color',nigeLab.defaults.nigelColors(1),...
               'DisplayName',obj.vid.name,...
               'Tag',obj.vid.name,...
               'ButtonDownFcn',@obj.clickAxes);
         end

         % Plot any digital streams
         for i = 1:numel(obj.dig)
            obj.dig(i).h = plot(obj.ax,...
               obj.dig(i).t,...
               obj.dig(i).data,...
               'Tag',obj.dig(i).name,...
               'DisplayName',obj.dig(i).name,...
               'LineWidth',1.5,...
               'Color',nigeLab.defaults.nigelColors(i+1),...
               'UserData',nigeLab.defaults.nigelColors(i+1),...
               'ButtonDownFcn',@obj.clickSeries);
         end
         
         if isempty(obj.vid.h)
            txt = ['Frame', {obj.dig.name}];
         else
            txt = ['Frame', obj.vid.name, {obj.dig.name}];
         end
         legend(obj.ax,txt,...
            'Location','northoutside',...
            'Orientation','horizontal',...
            'FontName','Arial',...
            'FontSize',14);
   
         % Get the max. axis limits
         obj.resetAxesLimits;
         
      end
      
      % ButtonDownFcn for top axes and children
      function clickAxes(obj,~,~)
         % CLICKAXES  ButtonDownFcn for the alignment axes and its children
         %
         %  ax.ButtonDownFcn = @(~,~)obj.clickAxes;
         
         obj.timeAtClickedPoint = obj.ax.CurrentPoint(1,1);
         
         % If FLAG is enabled
         if obj.moveStreamFlag
            % Place the (dragged) neural (beam/press) streams with cursor
            obj.resetAxesLimits;
            for i = 1:numel(obj.dig)
               obj.dig(i).h.Color = obj.dig.h.UserData;
               obj.dig(i).h.LineWidth = 2;
               obj.dig(i).h.LineStyle = '-';
            end
            obj.moveStreamFlag = false;            
         else % Otherwise, allows to skip to point in video
            notify(obj,'axesClick');
         end
      end
      
      % ButtonDownFcn for neural sync time series (beam/press)
      function clickSeries(obj,src,~)
         % CLICKSERIES  ButtonDownFcn callback for clicking on the neural
         %              sync time series (e.g. BEAM BREAKS or BUTTON PRESS)
         
         if ~obj.moveStreamFlag
            % Toggle to "dragging" the data stream graphic object
            obj.moveStreamFlag = true;
            obj.curOffsetPt = obj.cursorX;
            src.Color = nigeLab.defaults.nigelColors('light');
            src.LineStyle = '--';
            src.LineWidth = 2.5;
         else
            % "Release" the data stream graphic object
            src.Color = src.UserData;
            src.LineStyle = '-';
            src.LineWidth = 1.5;
            obj.resetAxesLimits;
            obj.moveStreamFlag = false;
         end
         
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
         new_align_offset = obj.offset + align_offset_delta;
         
      end
      
      % Initialize struct for main graphics reference
      function initGraphicsHandles(obj,digStreamInfo,vidStreamInfo)
         % INITGRAPHICSHANDLES  Initialize struct for main graphics ref
         %
         %  obj.initGraphicsHandles;
         %
         %  Initializes obj.dig and obj.vid structs
         
         if nargin < 3
            vidStreamInfo = obj.Block.UserData.vidStreamInfo;
         end
         
         if nargin < 2
            digStreamInfo = obj.Block.UserData.digStreamInfo;
         end
         
         obj.dig = struct;
         obj.vid = struct;
         
         % First, deal with digital streams
         ds = digStreamInfo;
         n = numel(ds);
         obj.dig = struct('name',cell(1,n),...
            'data',cell(1,n),...
            't',cell(1,n),...
            't0',cell(1,n),...
            'fs',cell(1,n),...
            'h',cell(1,n));
         
         keepvec = true(size(obj.dig));
         for i = 1:n
            tmp = obj.Block.getStream(ds(i).name);
            if isempty(tmp)
               keepvec(i) = false;
               continue;
            end
            obj.dig(i).name = tmp.name;
            obj.dig(i).data = tmp.data;
            obj.dig(i).fs = tmp.fs;
            obj.dig(i).t = tmp.t;
            obj.dig(i).t0 = tmp.t;
            obj.dig(i).h = gobjects(1);
         end
         obj.dig = obj.dig(keepvec);
         
         vs = vidStreamInfo;
         if isempty(vs)
            % If empty, initialize "empty" matching fields
            obj.vid.name = '';
            obj.vid.data = nan;
            obj.vid.t = nan;
            obj.vid.fs = 1;
            obj.vid.h = [];
            return;
         elseif strcmpi(vs.name,'none')
            obj.vid.name = '';
            obj.vid.data = nan;
            obj.vid.t = nan;
            obj.vid.fs = 1;
            obj.vid.h = [];
            return;
         end
         s = getStream(obj.Block.Videos,vs.name,...
               obj.Block.Pars.Video.VideoEventCamera);
         obj.vid.name = s.name(1:3);
         obj.vid.data = s.data;
         obj.vid.t = s.t;
         obj.vid.t0 = s.t;
         obj.vid.fs = s.fs;
         obj.vid.h = gobjects(1);
      end
      
      % Initialize offset depending on contents of diskfile
      function initOffset(obj,forcedOffset)
         % INITOFFSET  Initialize offset depending on contents of diskfile
         %
         %  obj.initOffset();  Check diskfile and use current offset value
         %                     or else make "best guess" and use that.
         %
         %  obj.initOffset(forcedOffset); Uses scalar or vector
         %                                forcedOffset for obj.offset
         %                                instead.
         
         if nargin > 1
            obj.offset = forcedOffset;
            return;
         end
         
         curOffset = getEventData(obj.Block,[],'ts','Header');
         if any(~isnan(curOffset))
            % Suppress NaN values if at least one offset is set already
            curOffset(isnan(curOffset)) = 0; 
         else
            % Otherwise, everything was NaN
            curOffset = obj.Block.guessVidStreamAlignment(...
               obj.Block.UserData.digStreamInfo,...
               obj.Block.UserData.vidStreamInfo);
         end
         obj.offset = curOffset;
         obj.updateStreamTime;   % Reflect the updated offset
      end
      
      % Extend or shrink axes x-limits as appropriate
      function resetAxesLimits(obj)
         % RESETAXESLIMITS  Extend or shrink axes x-limits as appropriate
         %
         %  obj.resetAxesLimits;
         
         obj.axLim = nan(1,2);
         obj.axLim(1) = 0;
         obj.axLim(2) = -inf;
         for i = 1:numel(obj.dig)
            obj.axLim(2) = max(obj.axLim(2),obj.dig(i).t(end));
         end
         if ~isempty(obj.vid.h)
            obj.axLim(2) = max(obj.axLim(2),obj.vid.t(end));
         end
         if ~obj.zoomFlag
            set(obj.ax,'XLim',obj.axLim);
            obj.curAxLim = obj.axLim;
            notify(obj,'zoomChanged');
         end
      end
      
      % Set the alignment and emit a notification about the event
      function setAlignment(obj,align_offset)
         % SETALIGNMENT  Set alignment and emit notification about it
         %
         %  obj.setAlignment(align_offset);
         %
         %  --> Align offset is the "VideoStart" where a positive value
         %        denotes that the video started AFTER the neural recording
         
         obj.offset = align_offset;
         obj.updateStreamTime;
         notify(obj,'offsetChanged');
      end
      
      % Update the current cursor X-position in figure frame
      function setCursorPos(obj,src,~)
         % SETCURSORPOS  Update the current cursor X-position based on
         %               mouse cursor movement in current figure frame.
         %
         %  fig.WindowButtonMotionFcn = @obj.setCursorPos;  
         %
         %  alignInfoObj is not associated with a figure handle explicitly;
         %  therefore, this method can be set as a callback for any figure
         %  it is "attached" to 
         
         if isempty(obj.ax)
            return;
         end
         x = src.CurrentPoint(1,1);
         obj.cursorX = x * diff(obj.ax.XLim) + obj.ax.XLim(1);
         if obj.moveStreamFlag
            % If the moveStreamFlag is HIGH, then compute a new offset and
            % set the alignment using the current cursor position.
            new_align_offset = obj.computeOffset(obj.curOffsetPt,obj.cursorX);
            obj.curOffsetPt = obj.cursorX;
            obj.setAlignment(new_align_offset); % update the shadow positions
            
         end
      end
      
      % Updates stream times and graphic object times associated with
      function updateStreamTime(obj)
         % UPDATESTREAMTIME  Update stream times and graphic object times
         %                   associated with those streams.
         %
         %  obj.updateStreamTime;
         %
         %  Move the "beam" and "press" streams (for example), relative to
         %  the VIDEO. These are streams that are locked into the NEURAL
         %  record; moving them relative to the current frame denotes that
         %  we have changed the offset by some amount.
         
         % Moves the beam and press streams, relative to VIDEO
         for i = 1:numel(obj.dig)
            obj.dig(i).t = obj.dig(i).t0 - obj.offset;
            obj.dig(i).h.XData = obj.dig(i).t;
         end

      end
      
   end
   
   % STATIC,PUBLIC
   methods (Static,Access=public)
      % Create "Empty" object or object array
      function obj = empty(n)
         %EMPTY  Return empty nigeLab.libs.alignInfo object or array
         %
         %  obj = nigeLab.libs.alignInfo.empty();
         %  --> Return scalar (0 x 0) object
         %
         %  obj = nigeLab.libs.alignInfo.empty(n);
         %  --> Specify number of empty objects
         
         if nargin < 1
            dims = [0, 0];
         else
            if ~isscalar(n)
               error(['nigeLab:' mfilename ':invalidEmptyDims'],...
                  'Input to nigeLab.libs.alignInfo.empty should be scalar.');
            end
            dims = [0, n];
         end
         
         obj = nigeLab.libs.alignInfo(dims);
      end
   end
   % % % % % % % % % % END METHODS% % %
end