classdef TimeScrollerAxes < matlab.mixin.SetGet
   %TIMESCROLLERAXES  Axes that allows "jumping" through a movie
   %
   %  ax = nigeLab.libs.TimeScrollerAxes(VidGraphicsObj);
   %
   %  Constructor is restricted to `nigeLab.libs.VidGraphics` object. This
   %  should only be created in combination with a `VidGraphics` object.
   %
   %  ax = nigeLab.libs.TimeScrollerAxes(VidGraphicsObj,'align');
   %  --> Assumes "alignment" configs
   %
   %  ax = nigeLab.libs.TimeScrollerAxes(VidGraphicsObj,'score');
   %  --> Assumes "score" configs (default)
   %
   %  ax = nigeLab.libs.TimeScrollerAxes(___,'Name',value,...);
   %  --> Assign properties using <'Name',value> pair syntax
   
   % % % PROPERTIES % % % % % % % % % %
   % DEPENDENT,PUBLIC
   properties (Dependent,Access=public)
      FrameTime   (1,1) double  = 0    % From .VidGraphicsObj (time of current frame)
      NeuOffset   (1,1) double  = 0    % Alignment offset between vid and dig
      NeuTime     (1,1) double  = 0    % Neural time corresponding to current frame (from parent)
      Parent                           % Handle to obj.Panel (matlab.ui.container.Panel)
      Position    (1,4) double  = [0 0.15 0.6 0.8]  % Position of obj.Axes
      TrialOffset (1,1) double  = 0    % Trial/Camera-specific offset
      Verbose     (1,1) logical = true % From obj.VidGraphicsObj
      VideoOffset (1,1) double  = 0    % Alignment offset from start of video series
      Zoom        (1,1) double  = 4    % Current axes "Zoom" offset
   end
   
   % DEPENDENT,TRANSIENT,PUBLIC
   properties (Dependent,Transient,Access=public)
      Axes           % Axes that holds the "TimeScrollerAxes"
      Block          % "Parent" nigeLab.Block object
      CMap           % Colormap (depends on "Zoom" level)
      Panel          % "Parent" panel object
      Figure         % "Parent" figure object
   end
   
   % TRANSIENT,PUBLIC
   properties (Transient,Access=public)
      BehaviorInfoObj            % "Parent" BehaviorInfo object
      VidGraphicsObj             % "Parent" VidGraphics object
   end
   
   % HIDDEN,DEPENDENT,PUBLIC
   properties (Hidden,Dependent,Access=public)
      XLim                                % X limits depend on parent Video object
      ZoomLevel      (1,1) double = 0     % Index for XLim "zoom"
   end
   
   % HIDDEN,PUBLIC
   properties (Hidden,Access=public)
      Legend                        % legend on axes
      HoldWindowButtonMotionFcn     % Holds WindowMotionFcn while monitoring cursor movement
      TimeStampNames   cell   = {}  % Label cell array for TimeStamp lines for legend
      TimeStampValues  double = []  % Times (seconds) for any timestamps       
      Now                           % Vertical line, "current time" indicator
      TimeStamps                    % Lines indicating times of different events
      ScrollLeftBtn                 % Patch to scroll left
      ScrollRightBtn                % Patch to scroll right
   end
   
   % TRANSIENT,PROTECTED
   properties (Transient,Access=protected)
      Axes_                         % "Stored" matlab.graphics.axis.Axes container
      CMap_            double       % "Stored" Colormap value based on zoom level
      DX_        (1,1) double = 1   % "Stored" axes limit difference
      Panel_                        % "Stored" matlab.ui.container.Panel
      Position_  (1,4) double = [0 0.15 0.6 0.8]  % "Stored" Axes .Position value
      XLim_      (1,2) double = [0 1]  % "Stored" axes limits
      Zoom_      (1,1) double = 4      % "Stored" Current "zoom" offset     
      ZoomLevel_ (1,1) double = 0      % "Stored" Zoom Level
   end
   
   % PROTECTED
   properties (Access=protected)
      icons       (1,1)struct = struct('leftarrow',[],'rightarrow',[],'circle',[]);
      dig                              % nigeLab.libs.nigelStreams object or array of digital streams
      flags       (1,1)struct          % "flags" struct of logical values
      mode             char            % 'score' or 'align'
      vid                              % nigeLab.libs.nigelStreams object or array of video streams
      x           (1,1)struct          % "XData" struct of position values
   end
   
   % CONSTANT,PROTECTED
   properties (Constant,Access=protected)
      ZoomedOffset = [4 1 2e-2]
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded get/set)
   methods
      % [DEPENDENT]  Return .Axes (container for TimeScrollerAxes graphic)
      function value = get.Axes(obj)
         %GET.AXES  Return .Axes (container for graphic)
         %
         %  value = get(obj,'Axes');
         %  --> Return value is stored in .Axes_ protected property
         
         value = obj.Axes_;
      end
      % [DEPENDENT]  Assign .Axes (container for TimeScrollerAxes graphic)
      function set.Axes(obj,value)
         %SET.AXES  Assign .Axes (container for graphic)
         %
         %  set(obj,'Axes',value);
         %  --> value is stored in .Axes_ protected property
         
         obj.XLim_ = get(value,'XLim');
         obj.DX_ = diff(obj.XLim_);
         obj.Axes_ = value;
         obj.Position_ = value.Position;
      end
      
      % [DEPENDENT]  Returns .Block (from "parent" VidGraphics object)
      function value = get.Block(obj)
         %GET.BLOCK  Returns .Block from "parent" VidGraphics object
         %
         %  value = get(obj,'Block');
         
         value = obj.VidGraphicsObj.Block;
      end
      % [DEPENDENT]  Assigns .Block
      function set.Block(obj,value)
         %SET.BLOCK  Assigns .Block via VidGraphicsObj
         obj.VidGraphicsObj.Block = value;
      end
      
      % [DEPENDENT]  Returns .CMap  (default colormap)
      function value = get.CMap(obj)
         %GET.CMAP  Returns .CMap (default colormap)
         %
         %  value = get(obj,'CMap');
         
         % Return "default" nigeLab colormap
         value = obj.CMap_;
      end
      % [DEPENDENT]  Assign .CMap (sets .CMap_)
      function set.CMap(obj,value)
         %SET.CMAP  Assigns value to .CMap_
         obj.CMap_ = value;
      end
      
      % [DEPENDENT]  Returns .Figure (from "parent" VidGraphics object)
      function value = get.Figure(obj)
         %GET.FIGURE  Returns .Figure from "parent" VidGraphics object
         %
         %  value = get(obj,'Figure');

         value = obj.VidGraphicsObj.Figure;
      end
      % [DEPENDENT]  Assign .Figure (via VidGraphicsObj)
      function set.Figure(obj,value)
         % SET.FIGURE  Assigns .Figure property via VidGraphicsObj
         %
         %  set(obj,'Figure',value);

         obj.VidGraphicsObj.Figure = value;
      end
      
      % [DEPENDENT]  Returns .FrameTime (from "parent" VidGraphics object)
      function value = get.FrameTime(obj)
         %GET.FRAMETIME  Returns .FrameTime from "parent" VidGraphics object
         %
         %  value = get(obj,'FrameTime');
         %  --> If unset, default value is 0
         value = obj.VidGraphicsObj.FrameTime;
      end
      % [DEPENDENT]  Assign .FrameTime to parent
      function set.FrameTime(obj,value)
         %SET.FRAMETIME  Assigns .FrameTime to parent VideoGraphics object
         %
         %  set(obj,'FrameTime',value);
         %  --> Sets time of "desired" frame (causing parent VideoReader to
         %        "jump" and display the corresponding frame time)

         obj.VidGraphicsObj.FrameTime = value;
      end
      
      % [DEPENDENT]  Returns .NeuOffset (from "parent" VidGraphics object)
      function value = get.NeuOffset(obj)
         %GET.OFFSET  Returns .Figure from "parent" VidGraphics object
         %
         %  value = get(obj,'NeuOffset');
         %  --> If unset, default value is 0

         value = obj.VidGraphicsObj.NeuOffset;
      end
      % [DEPENDENT]  Assign .NeuOffset
      function set.NeuOffset(obj,value)
         %SET.NEUOFFSET  set(obj.VidGraphicsObj,'NeuOffset',value);

         obj.VidGraphicsObj.NeuOffset = value;
      end
      
      % [DEPENDENT]  Returns .NeuTime (from "parent" VidGraphics object)
      function value = get.NeuTime(obj)
         %GET.NEUTIME  Returns .Figure from "parent" VidGraphics object
         %
         %  value = get(obj,'NeuTime');
         %  --> If unset, default value is 0
         
         value = obj.VidGraphicsObj.NeuTime;
      end
      % [DEPENDENT]  Assign .NeuTime
      function set.NeuTime(obj,value)
         %SET.NEUOFFSET  Assign neural time of current frame
         %
         %  set(obj.VidGraphicsObj,'NeuTime',value);
         
         obj.VidGraphicsObj.NeuTime = value;
      end
            
      % [DEPENDENT]  Returns .Panel (from "parent" VidGraphics object)
      function value = get.Panel(obj)
         %GET.PANEL  Returns .Panel from "parent" VidGraphics object
         %
         %  value = get(obj,'Panel');
         %  --> If unset, return empty
         
         value = obj.Panel_;
      end
      % [DEPENDENT]  Assign .Panel
      function set.Panel(obj,value)
         %SET.PANEL   Assign .Panel
         obj.Panel_ = value;
      end
      
      % [DEPENDENT]  Returns .Parent (from "parent" VidGraphics object)
      function value = get.Parent(obj)
         %GET.PARENT  Returns .Panel from "parent" VidGraphics object
         %
         %  value = get(obj,'Parent');
         %  --> If unset, return empty
         
         value = obj.Panel;
      end
      % [DEPENDENT]  Assign .Panel 
      function set.Parent(obj,value)
         %SET.PARENT 
         if isa(value,'nigeLab.libs.nigelPanel')
            obj.Panel = value.Panel;
         else
            obj.Panel = value;
         end
      end
      
      % [DEPENDENT]  Returns .Position (from .Position_)
      function value = get.Position(obj)
         %GET.POSITION  Returns .Position (from .Position_)
         value = obj.Position_;
      end
      % [DEPENDENT]  Assigns .Position (to .Axes, .Position_)
      function set.Position(obj,value)
         %SET.POSITION  Assigns .Position (to .Axes, .Position_)
         obj.Position_ = value;
         obj.Axes.Position = value;
      end
      
      % [DEPENDENT]  Returns .TrialOffset (from "parent" VidGraphics object)
      function value = get.TrialOffset(obj)
         %GET.TRIALOFFSET  Returns .TrialOffset from "parent" VidGraphics object
         %
         %  value = get(obj,'TrialOffset');
         %  --> If unset, default value is 0
         
         value = obj.VidGraphicsObj.TrialOffset;
      end
      % [DEPENDENT]  Assign .TrialOffset
      function set.TrialOffset(obj,value)
         %SET.TRIALOFFSET  Assign trial-specific "jitter" offset
         %
         %  set(obj.VidGraphicsObj,'TrialOffset',value);

         obj.VidGraphicsObj.TrialOffset = value;
      end
      
      % [DEPENDENT]  Returns .Verbose (from "parent" VidGraphics object)
      function value = get.Verbose(obj)
         %GET.VERBOSE  Returns .Figure from "parent" VidGraphics object
         %
         %  value = get(obj,'Verbose');
         %  --> If unset, default value is true
         
         value = true;
         if isempty(obj.VidGraphicsObj)
            return;
         end
         value = obj.VidGraphicsObj.Verbose;
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
         
         value = obj.VidGraphicsObj.VideoOffset;
      end
      % [DEPENDENT]  Assign .VideoOffset (assigns to parent VideoGraphics)
      function set.VideoOffset(obj,value)
         %SET.VideoOffset  Assigns to parent VideoGraphics object
         %
         %  set(obj,'VideoOffset',value);
         %  --> Updates parent VideoGraphics object .VideoOffset property
         
         obj.VidGraphicsObj.VideoOffset = value;
      end
      
      % [DEPENDENT]  Returns .XLim (from "parent" VidGraphics object)
      function value = get.XLim(obj)
         %GET.XLIM  Returns .Figure from "parent" VidGraphics object
         %
         %  value = get(obj,'XLim');
         
         if obj.ZoomLevel < 1
            value = [0, Max(FromSame(obj.Block.Videos,obj.VidGraphicsObj.VideoSource))];
         else
            value = [obj.FrameTime - obj.Zoom, obj.FrameTime + obj.Zoom];
         end
      end
      % [DEPENDENT]  Assign .XLim
      function set.XLim(obj,value)
         %SET.XLIM  set(obj,'XLim',__);
         %
         %  set(obj,'XLim','far');  Sets full range on X-Axis
         %  set(obj,'XLim','near'); Zooms in around the current timecursor
         if ischar(value)
            switch value
               case {'far','all'}
                  xLim = [0, Max(FromSame(obj.VidGraphicsObj.Block.Videos,obj.VidGraphicsObj.VideoSource))];
               case {'near','close'}
                  if obj.ZoomLevel < 1
                     obj.ZoomLevel = 1;
                  end
                  xLim = [obj.FrameTime - obj.Zoom,...
                          obj.FrameTime + obj.Zoom];
            end
         elseif isnumeric(value) && (numel(value)==2) && (value(2) > value(1))
            xLim = value;
         else
            error(['nigeLab:' mfilename ':InvalidValue'],...
               ['[TIMESCROLLERAXES]: XLim must be either ''far'', '...
               '''close'', or [a b]']);
         end
         set(obj.Axes,'XLim',xLim);
      end
      
      % [DEPENDENT]  Returns .Zoom property (current axes "Zoom" amount)
      function value = get.Zoom(obj)
         %GET.ZOOM  Returns .Zoom property (current axes "Zoom" amount)
         %
         %  value = get(obj,'Zoom');
         %  --> Determined by obj.ZoomOffset(obj.ZoomLevel);
         
         value = obj.Zoom_;
      end
      % [DEPENDENT]  Assign .Zoom property
      function set.Zoom(obj,value)
         %SET.ZOOM  Sets .Zoom_ value
         obj.Zoom_ = value;
         updateZoom(obj);
      end
      
      % [DEPENDENT]  Returns .ZoomLevel property (.ZoomLevel_)
      function value = get.ZoomLevel(obj)
         value = obj.ZoomLevel_;
      end      
      % [DEPENDENT]  Assign .ZoomLevel property (sets .ZoomLevel_,.CMap)
      function set.ZoomLevel(obj,value)
         %SET.ZOOMLEVEL  Assign .ZoomLevel property (sets .ZoomLevel_)
         obj.ZoomLevel_ = value;
         if value == 0
            C = getColorMap(obj.Block);
         else
            C = getJetHeatmap(obj);
            obj.Zoom_ = obj.ZoomedOffset(value);
         end
         obj.CMap_ = C;
      end
   end
   
   % RESTRICTED:nigeLab.libs.VidGraphics
   methods (Access=?nigeLab.libs.VidGraphics)
      % Constructor
      function obj = TimeScrollerAxes(VidGraphicsObj,initMode,varargin)
         %TIMESCROLLERAXES  Axes that allows "jumping" through a movie
         %
         %  ax = nigeLab.libs.TimeScrollerAxes(VidGraphicsObj);
         %
         %  ax = nigeLab.libs.TimeScrollerAxes(VidGraphicsObj,'align');
         %  --> Assumes "alignment" configs
         %
         %  ax = nigeLab.libs.TimeScrollerAxes(VidGraphicsObj,'score');
         %  --> Assumes "score" configs (default)
         %
         %  ax = nigeLab.libs.TimeScrollerAxes(___,'Name',value,...);
         %  --> Assign properties using <'Name',value> pair syntax
         
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
         
         % Initialize in "score" mode by default
         if nargin < 2
            initMode = 'score';
         end
         
         obj.VidGraphicsObj = VidGraphicsObj;
         obj.Parent = VidGraphicsObj.Panel;
         obj.XLim_ = [0 Max(obj.VidGraphicsObj.Block.Videos)];
         obj.DX_ = diff(obj.XLim_);
         obj.ZoomLevel = 0; % Initialize CMap and Zoom
         
         % Initialize different property structs
         obj.flags = struct('BeingDragged',false);
         obj.x = struct('new',0,'orig',0,...
            'updated_offset',obj.VidGraphicsObj.Video.NeuOffset,...
            'axes_offset',0,'axes_scaling',1);
         
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
         
         % Parse input arguments
         for iV = 1:2:numel(varargin)
            obj.(varargin{iV}) = varargin{iV+1};
         end
         
         % Initialize x-scaling and x-offset (based on "Parents" of fig)
         parseXScaling(obj);
         obj.Figure.WindowButtonMotionFcn = @obj.cursorMotionCB;
      end
   end
   
   % RESTRICTED:nigeLab.libs.behaviorInfo
   methods (Access=?nigeLab.libs.behaviorInfo)
      % Add BehaviorInfo object
      function addBehaviorInfoObj(obj,BehaviorInfoObj)
         %ADDBEHAVIORINFOOBJ  Adds BehaviorInfo object to TimeScroller
         %
         %  addBehaviorInfoObj(obj,BehaviorInfoObj);
         %  Note: This is called from nigeLab.libs.behaviorInfo/addTimeAxes
         
         obj.BehaviorInfoObj = BehaviorInfoObj;
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
         
         C = colormap('winter');
         idx = round(linspace(1,64,n+k));
         c = C(idx,:);
         keepvec = true(1,n);
         for i = 1:n
            tmp = getStream(obj.Block,streamName{i});
            if isempty(tmp)
               keepvec(i) = false;
               continue;
            end
            dig_(i).name = tmp.name;
            dig_(i).obj = tmp;
            dig_(i).fs = tmp.fs;
            dig_(i).index = i + k;
            dig_(i).col = c(i+k,:);
            dig_(i).shaded_col = dig_(i).col .* 0.75;
            dig_(i).h = gobjects(1);
         end
         dig_ = dig_(keepvec);
         
         obj.dig = horzcat(obj.dig,dig_);
         plotAllStreams(obj);
      end
      
      % Add "Time Marker" line to axes
      function addTimeMarker(obj)
         %ADDTIMEMARKER  Adds "time marker" line to axes
         %
         %  addTimeMarker(obj);
         
         obj.Now = line(obj.Axes,[0 0],[0 1.1],...
            'DisplayName','Time',...
            'Tag','Time',...
            'LineWidth',1,...
            'LineStyle','-',...
            'Marker','v',...
            'MarkerIndices',2,... % Only show top marker
            'MarkerSize',10,...
            'MarkerEdgeColor',[0 0 0],...
            'MarkerFaceColor',nigeLab.defaults.nigelColors('g'),...
            'Color',nigeLab.defaults.nigelColors('g'),...
            'ButtonDownFcn',@obj.axesClickedCB);
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
         C = colormap('autumn');
         idx = round(linspace(1,64,n+k));
         c = C(idx,:);
         for i = 1:n
            camOpts = nigeLab.utils.initCamOpts(...
               'csource','cname',...
               'cname',streamName{i});
            s = getStream(obj.Block.Videos,camOpts);
            if isempty(s)
               keepvec(i) = false;
               continue;
            end
            vid_.name = s.name;
            vid_.obj = s;
            vid_.fs = s.fs;
            vid_.index = i + k;
            vid_(i).col = c(i+k,:);
            vid_.h = gobjects(1);
         end
         vid_ = vid_(keepvec);
         obj.vid = horzcat(obj.vid,vid_);
         plotAllStreams(obj);
      end
      
      % Check/update axes limits
      function checkAxesLimits(obj)
         %CHECKAXESLIMITS  Check and update axes x-limits
         %
         %  checkAxesLimits(obj);
         
         if (obj.FrameTime>obj.XLim_(2)) || (obj.FrameTime<obj.XLim_(1))
            updateZoom(obj);
         end
      end
      
      % Clear TimeStamps
      function clearTimeStamps(obj)
         %CLEARTIMESTAMPS  Remove all timestamp lines from .TimeStamps
         %
         %  clearTimeStamps(obj);
         
         for i = 1:numel(obj.TimeStamps)
            if isvalid(obj.TimeStamps(i))
               delete(obj.TimeStamps(i));
            end
         end
         % "Detach" them as well
         obj.TimeStamps(:) = [];
      end
      
      % Update time for indicator "marker" associated with current frame
      function indicateTime(obj)
         %INDICATETIME  Updates the time "marker"
         %
         %  indicateTime(obj);
         
         % Obj.VideoOffset == "Series Offset" for GoPro series videos
         obj.Now.XData = ones(1,2)*(obj.FrameTime+obj.VideoOffset);
         
         % Fix axis limits
         checkAxesLimits(obj);
      end
      
      % Set timestamps (make new objects)
      function setTimeStamps(obj,ts,style,varargin)
         %SETTIMESTAMPS  Set timestamp markers for events of interest
         %
         %  setTimeStamps(obj,ts); % Update existing
         %  setTimeStamps(obj,ts,'name1',...,'namek');
         %  * For k elements of ts, supply k names to update legend entries

         
         clearTimeStamps(obj);
         obj.TimeStamps = gobjects(numel(ts));
         obj.TimeStampValues = ts;

         if numel(varargin) >= numel(ts)
            C = getColorMap(obj.Block);
            c = C(obj.Block.TrialIndex,:);
            for i = 1:numel(ts)
               obj.TimeStamps(i) = ...
                  line(obj.Axes,ones(1,2).*ts(i),[0.2 0.8],...
                  'Tag',varargin{i},...
                  'DisplayName',varargin{i},...
                  'LineWidth',3,...
                  'Marker','^',...
                  'MarkerIndices',1,...
                  'MarkerFaceColor',c,...
                  'MarkerEdgeColor','none',...
                  'Color',obj.CMap(i,:),...
                  'ButtonDownFcn',@obj.axesClickedCB);
               obj.TimeStamps(i).Annotation.LegendInformation.IconDisplayStyle = style;
            end
            obj.TimeStampNames = varargin(1:numel(ts));
         else
            for i = 1:numel(ts)
               obj.TimeStamps(i) = ...
                  line(obj.Axes,ones(1,2).*ts(i),[0.2 0.8],...
                  'LineWidth',3,...
                  'Marker','v',...
                  'MarkerIndices',2,...
                  'MarkerEdgeColor','w',...
                  'MarkerFaceColor','none',...
                  'Color',obj.CMap(i,:),...
                  'ButtonDownFcn',@obj.axesClickedCB);
               obj.TimeStamps(i).Annotation.LegendInformation.IconDisplayStyle = style;
            end
            obj.TimeStampNames = varargin;
         end
         setLegend(obj,obj.TimeStampNames{:});

      end
      
      % Update timestamps (only set times)
      function updateTimeStamps(obj,ts)
         %UPDATETIMESTAMPS  Set times only (do not create new objects)
         %
         %  updateTimeStamps(obj,ts);
         
         for i = 1:numel(ts)
            obj.TimeStamps(i).XData = ones(1,2).*ts(i);
         end
      end
      
      % Update Zoom based on "ZoomLevel" and current location of cursor
      function updateZoom(obj)
         %UPDATEZOOM  Update Zoom based on "Zoom Level" and current cursor
         %
         %  updateZoom(obj);
         
         obj.XLim_ = obj.XLim;
         obj.DX_ = diff(obj.XLim_);
         obj.Axes.XLim = obj.XLim;
         [tLabel,tVec] = nigeLab.libs.TimeScrollerAxes.parseXAxes(obj.XLim);
         obj.Axes.XTick=tVec;
         obj.Axes.XTickLabels=tLabel;
         
      end
      
      % Zoom out on beam break/paw probability time series (top axis)
      function zoomOut(obj)
         % ZOOMOUT  Make the axes x-limits larger, to effectively zoom out
         %          the streams so that it's easier to look at the general
         %          trend of matching transitions for streams through time.
         %
         %  obj.zoomOut;
         
         obj.ZoomLevel = max(obj.ZoomLevel-1,0);
         updateZoom(obj);
         switch obj.ZoomLevel
            case 0
               for i = 1:numel(obj.dig)
                  set(obj.dig(i).h,'LineWidth',1);
               end
               set(obj.Now,'LineStyle','-','LineWidth',1.50);
            case 1
               set(obj.Now,'LineStyle','--','LineWidth',2.00);
            case 2
               set(obj.Now,'LineStyle','-.','LineWidth',2.25);
         end
         if ~isempty(obj.BehaviorInfoObj)
            updateTimeAxesIndicators(obj.BehaviorInfoObj);
         end
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
         for i = 1:numel(obj.dig)
            set(obj.dig(i).h,'LineWidth',2);
         end
         switch obj.ZoomLevel
            case 1
               for i = 1:numel(obj.dig)
                  set(obj.dig(i).h,'LineWidth',1.50);
               end
               set(obj.Now,'LineStyle','--','LineWidth',2.00);
            case 2
               set(obj.Now,'LineStyle','-.','LineWidth',2.25);
            case 3
               set(obj.Now,'LineStyle',':','LineWidth',2.50);
         end
         if ~isempty(obj.BehaviorInfoObj)
            updateTimeAxesIndicators(obj.BehaviorInfoObj);
         end
      end
      
   end
   
   % SEALED,PROTECTED
   methods (Sealed,Access=protected)
      % When axes is clicked, depends on mouse location
      function axesClickedCB(obj,src,evt)
         % AXESCLICKEDCB  ButtonDownFcn for the alignment axes and its children
         %
         %  ax.ButtonDownFcn = @obj.axesClickedCB;
         
         % If obj.flags.BeingDragged, then we are "dropping" at this point
         if obj.flags.BeingDragged     
            % Depends on button
            switch evt.Button
               case 1
                  obj.NeuOffset = obj.NeuOffset + obj.x.updated_offset;
               case 3
                  for i = 1:numel(obj.dig)
                     obj.dig(i).h.XData = obj.dig(i).obj.t;
                  end
            end
            
            % Place the (dragged) neural streams with cursor
            for i = 1:numel(obj.dig)
               obj.dig(i).h.Color = obj.dig(i).col;
               obj.dig(i).h.LineStyle = '-';
               obj.dig(i).h.LineWidth = 1.5;
            end
            
            % Return the window button motion function to normal
            obj.Figure.WindowButtonMotionFcn = obj.HoldWindowButtonMotionFcn;
            obj.flags.BeingDragged = false;
            
            % Update the axes limits
            if obj.ZoomLevel == 0
               set(obj,'XLim','far')
            else
               set(obj,'XLim','near');
            end
         else % Otherwise, allows to skip to point in video
            if isa(src,'matlab.graphics.primitive.Image')
               tUpdate = obj.Now.XData(1) + ...
                  src.UserData.direction * obj.DX_/2;
            else
               tUpdate = obj.Axes.CurrentPoint(1,1);
            end
            obj.VidGraphicsObj.NeuTime=tUpdate+...
               obj.VidGraphicsObj.NeuOffset+obj.VidGraphicsObj.TrialOffset-obj.VidGraphicsObj.VideoOffset;
            obj.VidGraphicsObj.FrameTime = tUpdate;
            obj.Figure.UserData.FrameTime = tUpdate;
            
            updateTimeLabelsCB(obj.VidGraphicsObj,...
               obj.VidGraphicsObj.FrameTime,obj.VidGraphicsObj.NeuTime);
         end
      end
      
      % When button is down, indicate this by switching icon
      function buttonClickedCB(obj,src,~)
         %BUTTONCLICKEDCB  Indicate that button is pressed
         %
         %  obj.ScrollLeftBtn.ButtonDownFcn = @(s,~)obj.buttonClickedCB;
         %  obj.ScrollRightBtn.ButtonDownFcn = @(s,~)obj.buttonClickedCB;
         
         if src.UserData.down
            return;
         end
         src.UserData.down = true;
         src.CData = obj.icons.circle.img;
         src.AlphaData = obj.icons.circle.alpha;
         drawnow;
         obj.buttonExecuteCB(src);
      end
      
      % Execute left-scroll or right-scroll button callback
      function buttonExecuteCB(obj,src,~)
         %BUTTONEXECUTECB  Left-scroll or right-scroll button callback
         %
         %  obj.ScrollLeftBtn.Callback = @(s,~)obj.buttonExecuteCB;
         %  obj.ScrollRightBtn.Callback = @(s,~)obj.buttonExecuteCB;
         
         obj.axesClickedCB(src,struct('Button',1));
         src.CData = obj.icons.(src.UserData.icon).img;
         src.AlphaData = obj.icons.(src.UserData.icon).alpha;
         pause(0.25); % Debounce
         src.UserData.down = false;
      end
      
      % Update the current cursor X-position in figure frame, taking into
      % account: Width of any parent panels, width of axes relative to
      % panels.
      function cursorMotionCB(obj,~,~)
         % CURSORMOTIONCB  Update the current cursor X-position based on
         %               mouse cursor movement in current figure frame.
         %
         %  fig.WindowButtonMotionFcn = @obj.setCursorPos;
         %
         %  alignInfoObj is not associated with a figure handle explicitly;
         %  therefore, this method can be set as a callback for any figure
         %  it is "attached" to

%          unscaledX = src.CurrentPoint(1,1) - obj.x.axes_offset;
%          curX = unscaledX * obj.DX_ / obj.x.axes_scaling;
         curX = obj.Axes.CurrentPoint(1,1);

         if obj.flags.BeingDragged
            % If the flag is HIGH, then compute a new offset and
            % set the alignment using the current cursor position.
            obj.x.updated_offset = curX - obj.x.orig;
            
            % Moves the beam and press streams, relative to VIDEO
            for i = 1:numel(obj.dig)
               obj.dig(i).h.XData = obj.dig(i).obj.t + obj.x.updated_offset;
            end
            drawnow;
         end
      end
      
      % Returns 'jet' heatmap
      function C = getJetHeatmap(obj)
         %GETJETHEATMAP  Returns jet heatmap based on # events per trial
         %
         %  C = getJetHeatmap(obj);
         
         type = obj.Block.Pars.Video.VarType;
         N = numel(type==1);
         C = colormap('jet');
         idx = round(linspace(1,64,N));
         C = C(idx,:);
      end
      
      % ButtonDownFcn for neural sync time series (beam/press)
      function seriesClickedCB(obj,src,evt)
         % SERIESCLICKEDCB  ButtonDownFcn callback for clicking on
         %                  the neural sync time series
         %                  (e.g. BEAM BREAKS or BUTTON PRESS)
         
         if obj.flags.BeingDragged
            % "Release" the data stream graphic object
            axesClickedCB(obj,src.Parent,evt);  
         else
            % Toggle to "dragging" the data stream graphic object
            obj.flags.BeingDragged = true;
            obj.HoldWindowButtonMotionFcn = obj.Figure.WindowButtonMotionFcn;
            
            % Mark the current origin location
            obj.x.orig = src.Parent.CurrentPoint(1,1);
%             obj.Figure.WindowButtonMotionFcn = @(s,~)cursorMotionCB(obj,s,obj.x.orig);
            obj.Figure.WindowButtonMotionFcn = @obj.cursorMotionCB;

            src.Color = obj.dig(src.UserData).shaded_col;
            src.LineStyle = ':';
            src.LineWidth = 2.5;         
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
         
         [tLabel,tVec] = nigeLab.libs.TimeScrollerAxes.parseXAxes(obj.XLim);
         
         % Make axes for graphics objects
         obj.Axes = nigeLab.libs.nigelBackground(...
            obj.Panel,...
            'Units','Normalized',...
            'Position',[0 0.05 1 0.8],...
            'NextPlot','add',...
            'Curvature',[0.25 0.75],...
            'Color','none',...
            'FontWeight','bold',...
            'XColor','none',...
            'XLim',obj.XLim,...
            'XTick',tVec,...
            'XTickLabels',tLabel,...
            'XAxisLocation','top',...
            'YLim',[-0.2 1.2],...
            'FaceColor',nigeLab.defaults.nigelColors('bg'),...
            'YColor','none',...
            'Tag','TimeAxes',...
            'ButtonDownFcn',@obj.axesClickedCB);
         obj.Axes.XTickLabelColor = 'k';         
         
         initIconCData(obj);  
         u = struct('direction',-1,'icon','leftarrow','down',false);
         ax = axes(obj.Panel,...
            'Color','none',...
            'XLim',[1 16],...
            'XTick',[],...
            'XColor','none',...
            'YLim',[1 16],...
            'YTick',[],...
            'YColor','none',...
            'Units','Normalized',...
            'NextPlot','replacechildren',...
            'Position',[0.035 0.86 0.015 0.025]);
         
         obj.ScrollLeftBtn = imagesc(ax,1:16,1:16,...
            obj.icons.leftarrow.img,...
            'AlphaData',obj.icons.leftarrow.alpha,...
            'UserData',u,...
            'ButtonDownFcn',@obj.buttonClickedCB);
         u = struct('direction',1,'icon','rightarrow','down',false);
         ax = axes(obj.Panel,...
            'Color','none',...
            'XLim',[1 16],...
            'XTick',[],...
            'XColor','none',...
            'YLim',[1 16],...
            'YTick',[],...
            'YColor','none',...
            'Units','Normalized',...
            'NextPlot','replacechildren',...
            'Position',[0.585 0.86 0.015 0.025]);
         
         obj.ScrollRightBtn = imagesc(ax,1:16,1:16,...
            obj.icons.rightarrow.img,...
            'AlphaData',obj.icons.rightarrow.alpha,...
            'UserData',u,...
            'ButtonDownFcn',@obj.buttonClickedCB);
         nestObj(obj.VidGraphicsObj.Panel,obj.ScrollLeftBtn,'LeftBtn');
         nestObj(obj.VidGraphicsObj.Panel,obj.ScrollRightBtn,'RightBtn');
         if autoInitStreams
            initTimeAxesStreamData;
         else
            plotAllStreams(obj);
         end
      end
      
      % Initialize CData struct containing icon images
      function initIconCData(obj)
         %INITICONCDATA  Initialize CData struct with icon images
         %
         %  initIconCData(obj);
         
         [obj.icons.rightarrow.img,...
          obj.icons.rightarrow.alpha] = nigeLab.utils.getMatlabBuiltinIcon(...
            'greenarrowicon.gif',...
            'Background','bg',...
            'BackgroundIndex',9 ...
            );
         obj.icons.leftarrow.img = fliplr(obj.icons.rightarrow.img);
         obj.icons.leftarrow.alpha = fliplr(obj.icons.rightarrow.alpha);
         [obj.icons.circle.img,...
          obj.icons.circle.alpha] =nigeLab.utils.getMatlabBuiltinIcon(...
            'greencircleicon.gif',...
            'Background','bg',...
            'BackgroundIndex',8 ...
            );
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
         
         obj.x.axes_offset = obj.Axes.Position(1) * ... % Axes offset component
            obj.VidGraphicsObj.Panel.Position(3) * obj.Panel.Position(3) + ...
            obj.Panel.InnerPosition(1) * ... % Panel (inner) offset component
            obj.VidGraphicsObj.Panel.Position(3) + ...
            obj.VidGraphicsObj.Panel.Position(1);  % Panel (outer) offset component
         
         obj.x.axes_scaling = obj.Axes.Position(3) * ... % Axes width component
            obj.Panel.Position(3) * ... % Panel width component (inner)
            obj.VidGraphicsObj.Panel.Position(3); % Panel width component (outer)
         
      end
      
      % Plot all streams on axes
      function plotAllStreams(obj)
         % Plot video stream (if it's present)                 
         cla(obj.Axes);
         % Add "segments" indicating timing from different vids
         tmp = FromSame(obj.VidGraphicsObj.Block.Videos,obj.VidGraphicsObj.VideoSource);
         c = linspace(0.75,0.95,numel(tmp)-1);
         for i = 1:(numel(tmp)-1)
            t = max(tmp(i).tVid);
            sep = line(obj.Axes,[t,t],[-0.15 0.05],...
               'LineWidth',2,...
               'Color',nigeLab.defaults.nigelColors('light'),...
               'Displayname','','Tag','',...
               'MarkerIndices',1,'Marker','^','LineStyle','-',...
               'MarkerFaceColor',ones(1,3)*c(i),...
               'MarkerEdgeColor',ones(1,3)*c(i),...
               'Clipping','off',...
               'LineJoin','miter','PickableParts','none');
            sep.Annotation.LegendInformation.IconDisplayStyle = 'off';
         end
         
         % Add indicator for current times
         addTimeMarker(obj);
         
         % Add any potential streams
         for i = 1:numel(obj.vid)
            obj.vid(i).h = ...
               plot(obj.Axes,...
               obj.vid(i).obj.t,...       % Time from diskfile_
               obj.vid(i).obj.data,...    % Data from diskfile_
               'Color',obj.v(i).col,...
               'Displayname',obj.v(i).name,...
               'Tag',obj.v(i).name,...
               'Clipping','on',...
               'UserData',i,...
               'ButtonDownFcn',@obj.axesClickedCB);
         end
         
         % Plot any digital streams (if present)
         for i = 1:numel(obj.dig)
            obj.dig(i).h = ...
               plot(obj.Axes,...
               obj.dig(i).obj.t,...       % Time from diskfile_
               obj.dig(i).obj.data,...    % Data from diskfile_
               'Tag',obj.dig(i).name,...
               'DisplayName',obj.dig(i).name,...
               'LineWidth',1.5,...
               'Color',obj.dig(i).col,...
               'Clipping','on',...
               'UserData',i,...
               'ButtonDownFcn',@obj.seriesClickedCB);
         end
         
         if ~isempty(obj.TimeStampValues)
            setTimeStamps(obj,obj.TimeStampValues,'on',obj.TimeStampNames{:});
         else
            setLegend(obj);            
         end
         set(obj,'XLim','far');
      end
      
      % Sets the legend on TimeScrollerAxes
      function setLegend(obj,varargin)
         %SETLEGEND  Sets legend on TimeScrollerAxes
         %
         %  setLegend(obj);
         %  * Appends names automatically parsed from any plotted streams
         %
         %  setLegend(obj,'name1',...,'namek');
         %  * Appends additional names for example to match 'Event' times
         
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
         
         labs = ['Frame', vname, dname, varargin];
         obj.Legend = legend(obj.Axes,labs{:});
         obj.Legend.Orientation = 'horizontal';
         obj.Legend.FontName = 'DroidSans';
         obj.Legend.FontSize = 10;
         obj.Legend.Location = 'northoutside';
         obj.Legend.Color = nigeLab.defaults.nigelColors('bg');
         obj.Legend.Box = 'off';
         obj.Legend.TextColor = 'w';
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
   
   % STATIC,PROTECTED
   methods (Static,Access=protected)
      function [tLabel,tVec] = parseXAxes(xLim)
         %PARSEXAXES  Parse xtick locations and labels based on scale
         %
         %  [tLabel,tVec] = parseXAxes(xLim);
         %
         %  xLim : Limits of current axes
         %
         %  tLabel : Cell array of char arrays containing X-tick labels
         %  tVec   : 8-element row vector of X-tick locations
         
         if diff(xLim) > 120
            tUnits = 'm';
            tVal = linspace(xLim(1)/60,xLim(2)/60,10);
            % Drop first and last ticks
            tVec = tVal(2:(end-1));

            % Labels reflect `tVal` (minutes)
            tLabel = sprintf('\\color[rgb]{0,0,0} %5.1f:',tVec); 
            tLabel = strsplit(tLabel(1:(end-1)),':');
            tLabel = cellfun(@(s)sprintf('%s%s',s,tUnits),tLabel,...
               'UniformOutput',false);
            tVec = tVec .* 60;
         else
            tUnits = 's';
            tVal = linspace(xLim(1),xLim(2),7);
            % Drop first and last ticks
            tVec = tVal(2:(end-1));

            % Labels reflect `tVal` (seconds)
            tLabel = sprintf('\\color[rgb]{0,0,0} %7.3f:',tVec); 
            tLabel = strsplit(tLabel(1:(end-1)),':');
            tLabel = cellfun(@(s)sprintf('%s%s',s,tUnits),tLabel,...
               'UniformOutput',false);
         end
      end
   end
   % % % % % % % % % % END METHODS% % %
end

