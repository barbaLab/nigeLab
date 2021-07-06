classdef VidScorer < matlab.mixin.SetGet
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
   properties (Access=public)
      VideoTime    double  = 0    % From .VidGraphicsObj (time of current frame)
      NeuTime      double  = 0    % Neural time corresponding to current frame (from parent)
      Parent                           % Handle to obj.Panel (matlab.ui.container.Panel)
      Position    (1,4) double  = [0 0.15 0.6 0.8]  % Position of obj.Axes
      TrialOffset (1,1) double  = 0    % Trial/Camera-specific offset
      Verbose     (1,1) logical = true % From obj.VidGraphicsObj
      VideoOffset (1,1) double  = 0    % Alignment offset from start of video series
      Zoom        (1,1) double  = 4    % Current axes "Zoom" offset
      nTrial      (1,1) double  = 0
   end
   
   properties (SetObservable)
      TrialIdx    (1,1) double  = 0
      NeuOffset   (1,1) double  = 0    % Alignment offset between vid and dig

   end
   
   % Gui eleemnts
   properties (Transient,Access=public)
      sigFig
      sigPanel
      sigAxes
      
      cmdPanel
      
      evtFigure
      evtPanel
      lblPanel
      evtElementList = [];
      lblElementList = [];
      link = [];
      trialProgAx
      trialProgBar
      
      Now
      SignalTree
      
      colors
      icons       (1,1)struct = struct('leftarrow',[],'rightarrow',[],'circle',[],'play',[],'pause',[]);
      
      ScrollLeftBtn
      PlayPauseBtn
      StopBtn
      ScrollRightBtn
      SpeedSlider
      SynchButton
      StretchButton
      trialsOverlayChk
      ZoomButton
      PanButton
      TrialLabel
   end
   
   % Other nigeLab linked obj
   properties (Transient,Access=public)
%       MaskObj                    % Image for showing "grayed out" non-included regions
      nigelCam             % "Parent" VidGraphics object      
      Block          % "Parent" nigeLab.Block object
      
      listeners
     
   end
   
   % HIDDEN,DEPENDENT,PUBLIC
   properties (Hidden,Access=public)
      ZoomLevel      (1,1) double = 0     % Index for XLim "zoom"
      
      Evts           struct = repmat(struct('Time',[],'Name',[],'Trial',[],'Misc',[],'graphicObj',[]),1,0);
      TrialLbls      struct = repmat(struct('Time',[],'Name',[],'Trial',[],'Misc',[],'graphicObj',[]),1,0);
   end
   
   % HIDDEN,PUBLIC
   properties (Hidden,Access=public)
      Legend                        % legend on axes
      HoldWindowButtonMotionFcn     % Holds WindowMotionFcn while monitoring cursor movement
      TimeStampNames   cell   = {}  % Label cell array for TimeStamp lines for legend
      TimeStampValues  double = []  % Times (seconds) for any timestamps       
      TimeStamps                    % Lines indicating times of different events

   end
   
   
   % TRANSIENT,PROTECTED
   properties (Access=protected)
      DX        (1,1) double = 1   % "Stored" axes limit difference
      XLim      (1,2) double = [0 1]  % "Stored" axes limits
   end
     
   % CONSTANT,PROTECTED
   properties (Constant,Access=protected)
      ZoomedOffset = [30 10 4 1 2e-2]
   end
   % % % % % % % % % % END PROPERTIES %
   
   events
      evtAdded
      lblAdded
      evtDeleted
      lblDeleted
   end
   
   % % % METHODS% % % % % % % % % % % %

   %Constructors
   methods %(Access=?nigeLab.libs.VidGraphics)
      % Constructor
      function obj = VidScorer(nigelCam,varargin)
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
         elseif isnumeric(nigelCam)
            dims = nigelCam;
            if numel(dims) < 2
               dims = [zeros(1,2-numel(dims)),dims];
            end
            obj = repmat(obj,dims);
            return;
         end
         
         obj.nigelCam = nigelCam;
         obj.VideoTime = nigelCam.getTimeSeries;
         obj.VideoTime = obj.VideoTime- obj.nigelCam.VideoOffset- (1:numel(obj.VideoTime)).* obj.nigelCam.VideoStretch;
         obj.Block = nigelCam.Parent;
         obj.NeuTime =obj.Block.Time(:);
         if isempty(obj.NeuTime)
             obj.NeuTime = (1:obj.Block.Samples)./obj.Block.SampleRate * 1e3;
         end
         obj.XLim = [0 max(nigelCam.Meta(end).duration)];
         obj.DX = diff(obj.XLim);
         if isempty(obj.nigelCam.VideoOffset)
             obj.NeuOffset = 0;
         else
             obj.NeuOffset =  -obj.nigelCam.VideoOffset;
         end
         
         % Parse input arguments
         for iV = 1:2:numel(varargin)
            obj.(varargin{iV}) = varargin{iV+1};
         end
         
         % Initialize x-scaling and x-offset (based on "Parents" of fig)
%          parseXScaling(obj);

        obj.buildTimeAxesGraphics();
        obj.buildCmdPanel();
        buildEventPanel(obj);
        
        obj.nigelCam.showThumb();
        obj.nigelCam.startBuffer();
        
        obj.addListeners();
        obj.paintTrials();
      end
      
      
      function delete(obj)
          if ~isempty(obj.listeners)
              for o = obj.listeners
                 o.Enabled = false; 
              end
              delete(obj.listeners);
              obj.listeners = [];
          end
          
          
          if ~isempty(obj.link)
              delete(obj.link);
          end
          
          delete(obj.evtFigure);
          delete(obj.sigFig);
          % request camA to close, to be implemented in c++
          obj.nigelCam.closeFig;
      end

   end
   
   
   % PUBLIC
   methods (Access=public)
      
      % Add Boundary Indicators
      function addBoundaryIndicators(obj)
         %ADDBOUNDARYINDICATORS  Adds "boundary indicator" patches
         %
         %  addBoundaryIndicators(obj);
         
         % Add "segments" indicating timing from different vids
         tmp = FromSame(obj.VidGraphicsObj.Block.Videos,obj.VidGraphicsObj.VideoSource);
         c = linspace(0.75,0.95,numel(tmp)-1);
         if ~isempty(obj.BoundsIndicator)
            if isvalid(obj.BoundsIndicator)
               delete(obj.BoundsIndicator);
            end
         end
         obj.BoundsIndicator = gobjects(numel(tmp)-1);
         for i = 1:(numel(tmp)-1)
            if tmp(i).Masked
               rX = max(tmp(i).tVid);
            else
               rX = min(tmp(i).tVid);
            end
            rW = max(rX - min(tmp(i+1).tVid),0.005);
            obj.BoundsIndicator(i) = rectangle(obj.Axes,...
               'Position',[rX,-0.15,rW,1.15],...
               'Curvature',[0.2 0.2],...
               'EdgeColor','none',...
               'FaceColor',nigeLab.defaults.nigelColors('light'),...
               'Tag','Video Boundary',...
               'Clipping','on',...
               'PickableParts','none');
         end
      end
      
      % Add Listeners
      function addListeners(obj)
          obj.listeners = addlistener(obj.nigelCam,'timeChanged',@(src,evt)obj.updateTimeMakrer);
          obj.listeners = [obj.listeners addlistener(obj,'evtDeleted',@(src,evt)obj.updateEvtGraphicList)];
          obj.listeners = [obj.listeners addlistener(obj,'lblDeleted',@(src,evt)obj.updateLblGraphicList)];
          
          obj.listeners = [obj.listeners addlistener(obj.nigelCam,'streamAdded',@(src,evt)obj.updateStreams(evt,src))];
          
          obj.listeners = [obj.listeners addlistener(obj,'TrialIdx','PostSet',@obj.TrialIdxChanged)];
          obj.listeners = [obj.listeners addlistener(obj,'NeuOffset','PostSet',@obj.NeuOffsetChanged)];
          
          obj.listeners = [obj.listeners addlistener(obj,'evtAdded',@(src,evt)obj.Block.addEvent(evt))];
          obj.listeners = [obj.listeners addlistener(obj,'evtDeleted',@(src,evt)obj.Block.deleteEvent(evt))];
          obj.listeners = [obj.listeners addlistener(obj,'lblAdded',@(src,evt)obj.Block.addEvent(evt))];
          obj.listeners = [obj.listeners addlistener(obj,'lblDeleted',@(src,evt)obj.Block.deleteEvent(evt))];

      end
      
      % Add "Time Marker" line to axes
      function addTimeMarker(obj)
         %ADDTIMEMARKER  Adds "time marker" line to axes
         %
         %  addTimeMarker(obj);
         x = obj.nigelCam.Time;
         obj.Now = line(obj.sigAxes,[x x],[0 1.1],...
            'DisplayName','Time',...
            'Tag','Time',...
            'LineWidth',1,...
            'LineStyle','-',...
            'Marker','v',...
            'MarkerIndices',2,... % Only show top marker
            'MarkerSize',10,...
            'MarkerEdgeColor',[0 0 0],...
            'MarkerFaceColor',nigeLab.defaults.nigelColors('g'),...
            'Color',nigeLab.defaults.nigelColors('sfc'),...
            'HitTest','off');
      end
      function updateTimeMakrer(obj)
          obj.Now.XData = ones(2,1)*obj.VideoTime(obj.nigelCam.FrameIdx);
          trueTime = obj.nigelCam.getTimeSeries;
          thisTrial = find(obj.Block.Trial(:,1)*1e3 <= (obj.Now.XData(1)+5),1,'last'); % maybe change with min(abs()) ?
          if isempty(thisTrial),thisTrial = 0;end
          obj.TrialIdx = thisTrial;
          xl = xlim(obj.sigAxes);
          
          if obj.Now.XData(1) > xl(2)
              xlim(obj.sigAxes,diff(xl)/2*[-1 1]+obj.Now.XData(1))
          elseif obj.Now.XData(1) < xl(1)
              xlim(obj.sigAxes,diff(xl)/2*[-1 1]+obj.Now.XData(1))
          end
      end
      
      function TrialIdxChanged(obj,src,evt)
          pct = obj.TrialIdx ./ obj.nTrial;
          obj.trialProgBar.XData = [0 pct pct 0];
          
          obj.TrialLabel.String = num2str(obj.TrialIdx);
      end
      function NeuOffsetChanged(obj,src,evt)
          obj.VideoOffset = -obj.NeuOffset;
          obj.Block.VideoOffset = obj.VideoOffset;
          obj.nigelCam.VideoOffset = -obj.NeuOffset;
         VidNodes =  obj.SignalTree.Root.Children(strcmp({obj.SignalTree.Root.Children.Name},'Video streams')).Children;
%          for nn = VidNodes
%              UD = nn.UserData;
%              if isfield(UD,'ReducedPlot')
%                  UD.ReducedPlot.x = {UD.Time + obj.NeuOffset};
%              end
%          end
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
            mask = obj.Block.TrialMask;
            outcome = obj.BehaviorInfoObj.Outcome;
            state = obj.BehaviorInfoObj.State;
            
            for i = 1:numel(ts)
               if mask(i)
                  if state(i)
                     if outcome(i)
                        col = obj.colors.success;
                     else
                        col = obj.colors.fail;
                     end                     
                  else
                     col = obj.colors.unscored;
                  end                  
               else
                  col = obj.colors.excluded;
               end
               obj.TimeStamps(i) = ...
                  line(obj.Axes,ones(1,2).*ts(i),[0.2 0.8],...
                  'LineWidth',3,...
                  'Marker','v',...
                  'MarkerIndices',2,...
                  'MarkerEdgeColor',col,...
                  'MarkerFaceColor',col,...
                  'Color',obj.CMap(i,:),...
                  'ButtonDownFcn',@obj.axesClickedCB);
               obj.TimeStamps(i).Annotation.LegendInformation.IconDisplayStyle = style;
            end
            obj.TimeStampNames = varargin;
         end
         setLegend(obj,obj.TimeStampNames{:});

      end
           
      % retrieves events or label by name and time
      function [evt,idx] = getEvtByKey(obj,time,name)
          evt_ = [];
          idx_ = [];
          if ~isscalar(time)
              [evt_,idx_] = getEvtByKey(obj,time(2:end),name(2:end));
              time = time(1);
              name = name(1);
          end
           idx = [obj.Evts.Time] == time;
           if sum(idx)>1
              idx2 = strcmp({obj.Evts(idx).Name},name);
              idx(idx) = idx2;
           end
           evt = [evt_ obj.Evts(idx)];
           idx = [idx_ find(idx)];
      end
      function [evt,idx] = getLblByKey(obj,trial,name)
          evt_ = [];
          idx_ = [];
          if ~isscalar(trial)
              [evt_,idx_] = getEvtByKey(obj,trial(2:end),name(2:end));
              trial = trial(1);
              name = name(1);
          end
           idx = [obj.TrialLbls.Trial] == trial;
           if sum(idx)>1
              idx2 = strcmp({obj.TrialLbls(idx).Name},name);
              idx(idx) = idx2;
           end
           evt = [evt_ obj.TrialLbls(idx)];
           idx = [idx_ find(idx)];
      end
      
      function updateStreams(obj,src,evt)
          if isfield(src,'time') || isprop(src,'time')
              pltData.Time = src.time;
          else
              pltData.Time = obj.nigelCam.getTimeSeries;
          end
              pltData.Data = src.data;
              vidNode = obj.SignalTree.Root.Children(2);
              strmNode = uiw.widget.CheckboxTreeNode('Parent',vidNode,...
                  'Name',src.name,...
                  'UserData',pltData,'CheckboxEnabled',true);
      strmNode.Checked = true;
      end
   end
   
   % SEALED,PROTECTED Callbacks
   methods (Sealed,Access=protected)
       % Signal Axes click callback, seeks the video
       function sigAxClick(obj,~,evt)
           obj.Now.XData = ones(2,1)*evt.IntersectionPoint(1);
           [~,idx] = min( abs(obj.VideoTime  - evt.IntersectionPoint(1)));
           trueVideoTime = obj.nigelCam.getTimeSeries;
           obj.nigelCam.seek(trueVideoTime(idx));
       end
       
      % Play/Paue button. When clicked, also switches icon
      function buttonPlayPause(obj,src)
         %BUTTONCLICKEDCB  Indicate that button is pressed
         %DA RIFAREEEEEE
         %  obj.ScrollLeftBtn.ButtonDownFcn = @(s,~)obj.buttonClickedCB;
         %  obj.ScrollRightBtn.ButtonDownFcn = @(s,~)obj.buttonClickedCB;
         if src.UserData.VideoRunning
             src.UserData.VideoRunning = false;
             src.CData = obj.icons.play.img;
             obj.nigelCam.pause();
         else
             src.CData = obj.icons.pause.img;
             src.UserData.VideoRunning = true;
             obj.nigelCam.play();
         end
         drawnow;
      end
      
      function skipToNext(obj,direction)
          if obj.TrialIdx+direction <= 0
              return;
          end
          trialTime = obj.Block.Trial(obj.TrialIdx+direction,1)*1e3;
          evt.IntersectionPoint = trialTime;
          obj.sigAxClick([],evt);   % as if the user clicked on the timeline.
      end
      
      % Enables synch mode
      function buttonSynch(obj,src)
          SelectedNodes = obj.SignalTree.SelectedNodes;
          CheckedNodes = obj.SignalTree.SelectedNodes;
          zoom(obj.sigAxes,'off');
          if src.Value % synch mode selected
              if numel(SelectedNodes) < 1
                  src.Value = false;
                 error('Not enough nodes selected to perform synchronization!');
              end
              obj.SignalTree.SelectionChangeFcn = @(~,~)set(obj.SignalTree,'SelectedNodes',SelectedNodes);
              for nn = SelectedNodes
                 if ~nn.Checked
                     nn.Checked = 1;
                 end
                 nn.UserData.ReducedPlot.h_plot.LineWidth = 1.5;
                 nn.UserData.ReducedPlot.h_plot.HitTest = 'on';
                 nn.UserData.ReducedPlot.h_plot.PickableParts = 'visible';

                 nn.UserData.ReducedPlot.h_plot.ButtonDownFcn = @(src,evt)initMove(nn.UserData.ReducedPlot,obj.sigFig,obj);
                % set(obj.sigFig, 'windowbuttondownfcn', @(src,evt)initMove(obj.sigAxes));
                 set(obj.sigFig, 'windowbuttonmotionfcn', @(src,evt)moveStuff(obj.sigAxes,obj.sigFig,obj));
                 set(obj.sigFig, 'windowbuttonupfcn', @(src,evt)disableMove(obj.sigAxes,obj.sigFig,SelectedNodes,obj));
                 set(obj.sigAxes,'ButtonDownFcn',[]);

                 CheckedNodes(CheckedNodes==nn) = [];
              end
              
             obj.sigAxes.UserData = struct('init_state',[],'lineObj',[],...
                 'macro_active',false,'xpos0',[],'currentlinestyle',[],...
                 'xData',[],'currentTitle','','xNew',[]);
          else % synch mode deactivated
              obj.SignalTree.SelectionChangeFcn = [];
               for nn = CheckedNodes
                  nn.UserData.ReducedPlot.h_plot.LineWidth = .2;
                  nn.UserData.ReducedPlot.h_plot.HitTest = 'off';
                  nn.UserData.ReducedPlot.h_plot.PickableParts = 'none';
                 nn.UserData.ReducedPlot.h_plot.ButtonDownFcn = [];
               end
               set(obj.sigFig, 'windowbuttonmotionfcn', []);
               set(obj.sigFig, 'windowbuttonupfcn', []);
               set(obj.sigAxes,'ButtonDownFcn',@obj.sigAxClick);
               obj.sigAxes.UserData = [];
          end
          
          
          function initMove(reducedPlot,fig,obj)
              ax = reducedPlot.h_axes;
              %     disp('interactive_move enable')
              UDAta = ax.UserData;
              %UDAta.init_state = uisuspend(fig);

              out=get(ax,'CurrentPoint');
              UDAta.lineObj = reducedPlot;
              set(ax,'NextPlot','replace')
              set(fig,'Pointer','crosshair');
              UDAta.macro_active = 1;
              UDAta.xpos0 = out(1,1);%--store initial position x
              xl=get(ax,'XLim');
              if ((UDAta.xpos0 > xl(1) && UDAta.xpos0 < xl(2)))% &&...
                      %(UDAta.ypos0 > yl(1) && UDAta.ypos0 < yl(2))) %--disable if outside axes
                  UDAta.currentlinestyle = UDAta.lineObj.h_plot.LineStyle;
                  UDAta.currentmarker = UDAta.lineObj.h_plot.Marker;

                  UDAta.lineObj.h_plot.Marker = '.';
                  UDAta.lineObj.h_plot.LineStyle = 'none';
                  UDAta.xData = UDAta.lineObj.x{1};%--assign x data
                  UDAta.xOffs = obj.NeuOffset;
                  UDAta.currentTitle=get(get(ax, 'Title'), 'String');                  
                  title(ax,['[' num2str(out(1,1)) ']']);
                  ax.UserData = UDAta;
              else
                  ax.UserData = UDAta;
                  disableMove(ax,fig);
              end
              
          end
          %--------function to handle event
          function moveStuff(ax,fig,obj)
              UDAta = ax.UserData;             
              if UDAta.macro_active
                  out=get(ax,'CurrentPoint');
                  set(fig,'Pointer','crosshair');
                  title(['[' num2str(out(1,1)) ']']);
                  if ~isempty(UDAta.lineObj)                      
                      UDAta.lineObj.x = {UDAta.xData(:)-(UDAta.xpos0-out(1,1))};%--move x data
                      UDAta.xNew =out(1,1);
                      title(['[' num2str(out(1,1)) '], offset=[' num2str(UDAta.xpos0-out(1,1)) ']']);
                  end
              end
              ax.UserData = UDAta;
          end
          
          % stop moving stuff
          function disableMove(ax,fig,SelectedNodes,obj)
              
              UDAta = ax.UserData;
              UDAta.macro_active=0;
              title(UDAta.currentTitle);
              ax.UserData = UDAta;
%               uirestore(UDAta.init_state);
              set(fig,'Pointer','arrow');
              set(ax,'NextPlot','add')
              if ~isempty(UDAta.lineObj)
                  set(UDAta.lineObj.h_plot,'LineStyle',UDAta.currentlinestyle);
                  set(UDAta.lineObj.h_plot,'Marker',UDAta.currentmarker);
              end
              
%               SRate = arrayfun(@(ud) diff(ud.ReducedPlot.x{1}(1:2)),[SelectedNodes.UserData]);
%               allPLots = [SelectedNodes.UserData];
%               allPLots = [allPLots.ReducedPlot];
%               thisPlot = allPLots == UDAta.lineObj;
%               xfixed = SelectedNodes(~thisPlot).UserData.ReducedPlot.x{1};
%               [~,kf] = min(abs(xfixed-UDAta.xNew));
%               
%               xmov = UDAta.xData;
%               km = dsearchn(xmov,UDAta.xpos0);
              
%               SelectedNodes(thisPlot).UserData.ReducedPlot.x = {x + x(k) - UDAta.xpos0 - obj.NeuOffset};
%               obj.NeuOffset = UDAta.xOffs - (xmov(km)-xfixed(kf));
              obj.NeuOffset = UDAta.xOffs - UDAta.xpos0 + UDAta.xNew;
              fprintf(1,'adjusted for %d ms\n',abs(UDAta.xpos0 - UDAta.xNew))
%               UDAta.lineObj.x = {UDAta.xData-(xmov(km)-xfixed(kf))};
              obj.VideoTime = UDAta.lineObj.x{:};
          end
      end
      
      % Enab;es strecth mode
      function buttonStretch(obj,src)
          % In stretch mode, the data can be compressed or streched on the
          % x axis to better align the sampling
          
          SelectedNodes = obj.SignalTree.SelectedNodes;
          CheckedNodes = obj.SignalTree.SelectedNodes;
          zoom(obj.sigAxes,'off');obj.ZoomButton.Value = false;
          if src.Value % synch mode selected
              if numel(SelectedNodes) < 2
                  src.Value = false;
                  error('Not enough nodes selected to perform synchronization!');
              end
              obj.SignalTree.SelectionChangeFcn = @(~,~)set(obj.SignalTree,'SelectedNodes',SelectedNodes);
              for nn = SelectedNodes
                  if ~nn.Checked
                      nn.Checked = 1;
                  end
                  nn.UserData.ReducedPlot.h_plot.LineWidth = 1.5;
                  nn.UserData.ReducedPlot.h_plot.HitTest = 'on';
                  nn.UserData.ReducedPlot.h_plot.PickableParts = 'visible';
                  
                  nn.UserData.ReducedPlot.h_plot.ButtonDownFcn = @(src,evt)initStretch(nn.UserData.ReducedPlot,obj.sigFig,obj);
                  % set(obj.sigFig, 'windowbuttondownfcn', @(src,evt)initMove(obj.sigAxes));
                  set(obj.sigFig, 'windowbuttonmotionfcn', @(src,evt)stretchStuff(obj.sigAxes,obj.sigFig,obj));
                  set(obj.sigFig, 'windowbuttonupfcn', @(src,evt)disableStretch(obj.sigAxes,obj.sigFig,SelectedNodes,obj));
                  set(obj.sigAxes,'ButtonDownFcn',[]);
                  
                  CheckedNodes(CheckedNodes==nn) = [];
              end 
              
              obj.sigAxes.UserData = struct('init_state',[],'lineObj',[],...
                 'macro_active',false,'xpos0',[],'currentlinestyle',[],...
                 'xData',[],'currentTitle','','xNew',[],'idx0',[]);
          else
              obj.SignalTree.SelectionChangeFcn = [];
              for nn = CheckedNodes
                  nn.UserData.ReducedPlot.h_plot.LineWidth = .2;
                  nn.UserData.ReducedPlot.h_plot.HitTest = 'off';
                  nn.UserData.ReducedPlot.h_plot.PickableParts = 'none';
                  nn.UserData.ReducedPlot.h_plot.ButtonDownFcn = [];
              end
              set(obj.sigFig, 'windowbuttonmotionfcn', []);
              set(obj.sigFig, 'windowbuttonupfcn', []);
              set(obj.sigAxes,'ButtonDownFcn',@obj.sigAxClick);
              
              Question = sprintf('Do you want nigel to change the Video Time as well?\nThis is usually done when a Video Stream is modified.');
              ButtonName = questdlg(Question, 'Change Video Time?', 'Yes', 'No', 'Yes');
              if strcmp(ButtonName,'Yes')
                 UDAta_ = obj.sigAxes.UserData;
                 obj.VideoTime = UDAta_.lineObj.x{1};%--move x data
                 obj.nigelCam.VideoStretch = (UDAta_.xpos0-UDAta_.xNew)./UDAta_.idx0;
              end
              
              obj.sigAxes.UserData = [];
          end
          
          
          function initStretch(reducedPlot,fig,obj)
              ax = reducedPlot.h_axes;
              %     disp('interactive_move enable')
              UDAta = ax.UserData;
              %UDAta.init_state = uisuspend(fig);

              out=get(ax,'CurrentPoint');
              UDAta.lineObj = reducedPlot;
              set(ax,'NextPlot','replace')
              set(fig,'Pointer','crosshair');
              UDAta.xpos0 = out(1,1);%--store initial position x
              xl=get(ax,'XLim');
              if ((UDAta.xpos0 > xl(1) && UDAta.xpos0 < xl(2)))% &&...
                      %(UDAta.ypos0 > yl(1) && UDAta.ypos0 < yl(2))) %--disable if outside axes
                  UDAta.currentlinestyle = UDAta.lineObj.h_plot.LineStyle;
                  UDAta.currentmarker = UDAta.lineObj.h_plot.Marker;

                  UDAta.lineObj.h_plot.Marker = '.';
                  UDAta.lineObj.h_plot.LineStyle = 'none';
                  UDAta.xData = UDAta.lineObj.x{1};%--assign x data
                  [~,UDAta.idx0] = min(abs(UDAta.xpos0-UDAta.xData));
                  UDAta.xOffs = obj.NeuOffset;
                  UDAta.currentTitle=get(get(ax, 'Title'), 'String');                  
                  title(ax,['[' num2str(out(1,1)) ']']);
                  UDAta.macro_active = 1;
                  ax.UserData = UDAta;

              else
                  ax.UserData = UDAta;
                  disableStretch(ax,fig);
              end
              
          end
          %--------function to handle event
          function stretchStuff(ax,fig,obj)
              UDAta = ax.UserData;             
              if UDAta.macro_active
                  out=get(ax,'CurrentPoint');
                  set(fig,'Pointer','crosshair');
                  title(['[' num2str(out(1,1)) ']']);
                  if ~isempty(UDAta.lineObj)
                      mismatch = (UDAta.xpos0-out(1,1))./UDAta.idx0;
                      UDAta.lineObj.x = {UDAta.xData(:) - (1:numel(UDAta.xData))'.*mismatch};%--move x data
                      UDAta.xNew =out(1,1);
                      title(['[' num2str(out(1,1)) '], offset=[' num2str(UDAta.xpos0-out(1,1)) ']']);
                  end
              end
              ax.UserData = UDAta;
          end
          
          % stop moving stuff
          function disableStretch(ax,fig,SelectedNodes,obj)
              
              UDAta = ax.UserData;
              UDAta.macro_active=0;
              title(UDAta.currentTitle);
              ax.UserData = UDAta;
%               uirestore(UDAta.init_state);
              set(fig,'Pointer','arrow');
              set(ax,'NextPlot','add')
              if ~isempty(UDAta.lineObj)
                  set(UDAta.lineObj.h_plot,'LineStyle',UDAta.currentlinestyle);
                  set(UDAta.lineObj.h_plot,'Marker',UDAta.currentmarker);
              end
              
              
          end
      end
      
      function treecheckchange(obj,src,evt)
          plotStruct = evt.Nodes.UserData;
          hold(obj.sigAxes,'on')
          if ismember('ReducedPlot',fieldnames(plotStruct))
              if evt.Nodes.Checked
                 plotStruct.ReducedPlot.h_plot.Visible = 'on'; 
              else
                  plotStruct.ReducedPlot.h_plot.Visible = 'off';
              end
          else
              if strcmp(evt.Nodes.Parent.Name,'Video streams')
                  offset = obj.NeuOffset;
              else
                  offset = 0;
              end
              tt = plotStruct.Time(:) + offset ;
              dd = plotStruct.Data(:);
              dd = dd./max(dd);
              if isempty(tt)
                  if strcmp(evt.Nodes.Parent.Name,'Video streams')
                      if isempty(obj.VideoTime)
                          tt = (1:numel(dd)) ./ obj.nigelCam.Meta(1).frameRate * 1000;
                      else
                          tt = obj.NeuTime;
                      end
                  else
                      if isempty(obj.NeuTime)
                          tt = (1:numel(dd)) ./ obj.Block.SampleRate * 1000;
                      else
                          tt = obj.NeuTime;
                      end
                  end
              end
              plotStruct.ReducedPlot = nigeLab.utils.LinePlotReducer(obj.sigAxes, tt, dd);
              plotStruct.ReducedPlot.h_plot.HitTest = 'off';
              plotStruct.ReducedPlot.h_plot.PickableParts = 'none';

          end
          evt.Nodes.UserData = plotStruct;
          hold(obj.sigAxes,'off')
      end
      
      function eventSelect(obj,src,evt)
          k = obj.evtFigure.UserData;
          switch k
              case 'control'
              src.UserData = ~src.UserData;   
              if src.UserData
                  src.BackgroundColor = nigeLab.defaults.nigelColors('primary');
              else
                  src.BackgroundColor = nigeLab.defaults.nigelColors('sfc');
              end
              
              case 'shift'
                  this = find([obj.evtElementList] == src);
                  top = find([obj.evtElementList.UserData],1,'last');
                  toSelect = obj.evtElementList([this:top top:this]);
                  toDeSelect = setdiff(obj.evtElementList,toSelect);
                  for c = toSelect
                      c.UserData = true;
                      c.BackgroundColor = nigeLab.defaults.nigelColors('primary');
                  end
                  
                  for c = toDeSelect
                      c.UserData = false;
                      c.BackgroundColor = nigeLab.defaults.nigelColors('sfc');
                  end
                  
          otherwise
              idx = [obj.evtElementList.UserData];
              [obj.evtElementList(idx).UserData] = deal(false);
              [obj.evtElementList(idx).BackgroundColor] = deal(nigeLab.defaults.nigelColors('sfc'));
              src.UserData = true;
              src.BackgroundColor = nigeLab.defaults.nigelColors('primary');
          end
          
      end
      function labelSelect(obj,src,evt)
          k = obj.evtFigure.UserData;
          switch k
              case 'control'
              src.UserData = ~src.UserData;   
              if src.UserData
                  src.BackgroundColor = nigeLab.defaults.nigelColors('primary');
              else
                  src.BackgroundColor = nigeLab.defaults.nigelColors('sfc');
              end
              
              case 'shift'
                  this = find([obj.lblElementList] == src);
                  top = find([obj.lblElementList.UserData],1,'last');
                  toSelect = obj.lblElementList([this:top top:this]);
                  toDeSelect = setdiff(obj.lblElementList,toSelect);
                  for c = toSelect
                      c.UserData = true;
                      c.BackgroundColor = nigeLab.defaults.nigelColors('primary');
                  end
                  
                  for c = toDeSelect
                      c.UserData = false;
                      c.BackgroundColor = nigeLab.defaults.nigelColors('sfc');
                  end
                  
          otherwise
              idx = [obj.lblElementList.UserData];
              [obj.lblElementList(idx).UserData] = deal(false);
              [obj.lblElementList(idx).BackgroundColor] = deal(nigeLab.defaults.nigelColors('sfc'));
              src.UserData = true;
              src.BackgroundColor = nigeLab.defaults.nigelColors('primary');
          end
          
      end
   end
   
   % Interface methods to use with external apps or shortcuts
   methods (Access=public)
       % Function for hotkeys
       function add(obj,type,Name,Value)
           if nargin<3
               Value = 0;
           end
           switch lower(type)
               case {'evt' 'event' 'events'}
                   obj.addNewEvent(Name);
               case {'lbl' 'label' 'labels'}
                   obj.addNewLabel(Name,Value);
           end
       end
       function addAllTrials(obj,Name,Value)
           if nargin<3
               Value = 0;
           end
           for tt= 1:obj.nTrial
               obj.addNewLabel(Name,Value,trial);
           end
       end
       function playpause(obj)
           buttonPlayPause(obj,obj.PlayPauseBtn);
       end
       function nextFrame(obj)
           obj.nigelCam.frameF;
       end
       function previousFrame(obj)
           obj.nigelCam.frameB;
       end
       function nextTrial(obj)
           obj.skipToNext(1);
       end
       function previousTrial(obj)
           obj.skipToNext(-1);
       end
       function addExternalStreamToCam(obj,prompt,evt,src)
           if prompt
            [file,path] = uigetfile(fullfile(obj.Block.Out.Folder,'*.*'),'Select stream to add to nigelCam');
            if file==0
                return;
            end
            PathToFile = fullfile(path,file);
            variables = who('-file', PathToFile);
            if numel(variables) == 1
            obj.nigelCam.addStream(PathToFile);
            else
                this = nigeLab.utils.uidropdownbox('Select variable,','The selected file has more than 1 varibale stored in it.\nPlease select the correct one.',variables);
                if strcmp(this,'none')
                    return;
                end
                obj.nigelCam.addStream(PathToFile);
            end
           else
            obj.nigelCam.addStream();
           end
       end
   end
   
   
   % PROTECTED, build graphical objects
   methods (Access=protected)
      % Make all the graphics for tracking relative position of neural
      function buildTimeAxesGraphics(obj)
         % BUILDSTREAMGRAPHICS  Make all graphics for tracking relative
         %                      position of neural-sync'd streams (e.g.
         %                      BEAM BREAK or BUTTON PRESS) with video
         %                      (e.g. PAW PROBABILITY) time series.
         %
         %  obj.buildStreamsGraphics(nigelPanelObj);

         [tLabel,tVec] = nigeLab.libs.VidScorer.parseXAxes(obj.XLim);
         
         obj.sigFig = figure('Units','normalized',...
             'Position',[0.1 0.1 0.8 0.3],...
             'ToolBar','none',...
             'MenuBar','none',...
             'Color',nigeLab.defaults.nigelColors('bg'),...
             'KeyPressFcn',@(src,evt)nigeLab.workflow.defaultVideoScoringHotkey(evt,obj),...
             'CloseRequestFcn',@(src,evt)obj.delete);
         obj.sigPanel = uipanel(obj.sigFig,'Units','normalized',...
             'Position',[0 0 .8 1],...
              'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),'BorderType','none');
         obj.sigPanel.Units = 'pixels';
         obj.sigPanel.Position([2 4]) = obj.sigPanel.Position([2 4]) + [1 -1]*70;
         btnPanel = uipanel(obj.sigFig,'Units','normalized',...
             'Position',[.8 0 .2 1],...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),'BorderType','none');
         % Make axes for graphics objects
        ax = axes(obj.sigPanel,'XTick',tVec,'XTickLabel',tLabel,...
            'Units','normalized',...
            'Position',[0 0 1 1],...
            'ButtonDownFcn',@obj.sigAxClick);
        xlim(ax,obj.XLim);
        set(ax,'Units','pixels')
        ax.Position = ax.Position + [0 1 0 -1]*25;
        ax.YAxis.Visible = 'off';
        ylim(ax,[0 1.2]);
        
        % Init tree for streams visualization
         obj.SignalTree = uiw.widget.CheckboxTree(...
                'Units', 'normalized', ...
                'Position',[0 .2 1 .8],...
                'FontName','Droid Sans',...
                'FontSize',15,...
                'Tag','Tree',...
                'Parent',btnPanel,...
                'SelectionType','discontiguous',...
                'DigIn',false,...
                'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                'TreeBackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                'TreePaneBackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'),...
                'SelectionBackgroundColor',nigeLab.defaults.nigelColors('primary'),...
                'SelectionForegroundColor',nigeLab.defaults.nigelColors('sfc'));
         set(obj.SignalTree.Root,'Name','Signals to view','CheckboxVisible',0,'CheckboxEnabled',false)
         blkNode = uiw.widget.CheckboxTreeNode(...
                            'Name','Block streams',...
                            'Parent',obj.SignalTree,'CheckboxVisible',0,...
                            'CheckboxEnabled',false);
         blkStreams = fieldnames(obj.Block.Streams);
         for ss = 1:numel(blkStreams)
             strmTypeNode = uiw.widget.CheckboxTreeNode('Parent',blkNode,'Name',blkStreams{ss},'CheckboxEnabled',false,'CheckboxVisible',false);
             for tt =1:numel(obj.Block.Streams.(blkStreams{ss}))
                 pltData.Time = obj.Block.Time;
                 pltData.Data = obj.Block.Streams.(blkStreams{ss})(tt).data;
                 strmNode = uiw.widget.CheckboxTreeNode('Parent',strmTypeNode,...
                     'Name',obj.Block.Streams.(blkStreams{ss})(tt).name,...
                     'UserData',pltData,'CheckboxEnabled',true);
             end
         end
         
         % video streams
         mm = uicontextmenu(obj.sigFig);
         m1 = uimenu(mm,'Text','Add stream from video','MenuSelectedFcn',@(evt,src)obj.addExternalStreamToCam(false,evt,src));
         m1 = uimenu(mm,'Text','Add external stream','MenuSelectedFcn',@(evt,src)obj.addExternalStreamToCam(true,evt,src));
         vidNode = uiw.widget.CheckboxTreeNode(...
             'Name','Video streams',...
             'Parent',obj.SignalTree,'UIContextMenu',mm,'CheckboxEnabled',false,'CheckboxVisible',false);
         for tt =1:numel(obj.nigelCam.Streams)
             pltData.Time = obj.nigelCam.getTimeSeries;
             pltData.Data = obj.nigelCam.Streams(tt).data;
             strmNode = uiw.widget.CheckboxTreeNode('Parent',vidNode,...
                 'Name',obj.nigelCam.Streams(tt).name,...
                 'UserData',pltData,'CheckboxEnabled',true);
         end
         
         
         obj.SignalTree.CheckboxClickedCallback = @obj.treecheckchange;
         obj.sigAxes = ax;
         obj.addTimeMarker();
      end
      
      function buildCmdPanel(obj)
         
          obj.cmdPanel = uipanel(obj.sigFig,'Units','normalized','Position',[0 0 1 0],...
              'BackgroundColor', nigeLab.defaults.nigelColors('sfc'),'BorderType','none');
          obj.cmdPanel.Units = 'pixels';
          obj.cmdPanel.Position(4) = 70;
          
         % Create axes for "left-scroll" arrow
         initIconCData(obj);  
         
         obj.ScrollLeftBtn = uicontrol(obj.cmdPanel,'Style', 'push',...
             'Units', 'pixels',...
             'Position',[20 20 24 24],...
             'CData',obj.icons.leftarrow.img,...
             'Callback',@(src,evt)obj.skipToNext(-1),...
             'Tooltip','Previous trial');
         
         % Create axes for "right-scroll" button
         obj.ScrollRightBtn = uicontrol(obj.cmdPanel,'Style', 'push',...
             'Units', 'pixels',...
             'Position',[50 20 24 24],...
             'CData',obj.icons.rightarrow.img,...
             'Callback',@(src,evt)obj.skipToNext(1),...
             'Tooltip','Next trial');
        obj.TrialLabel = uicontrol(obj.cmdPanel,'Style', 'edit',...
             'Units', 'pixels',...
             'Position',[80 20 20 20],...
             'BackgroundColor',nigeLab.defaults.nigelColors('onsurface'),...
             'String','1');
         fcnlist = {{@(src,evt)set(obj,'TrialIdx',str2double(src.String))},...
             {@(src,evt)obj.sigAxClick([],struct('IntersectionPoint',obj.Block.Trial(round(str2double(src.String)),1)*1e3)) }};
         
        obj.TrialLabel.Callback = @(src,evt)nigeLab.utils.multiCallbackWrap(src,evt,fcnlist);         
         
         obj.PlayPauseBtn = uicontrol(obj.cmdPanel,'Style', 'push',...
             'Units', 'pixels',...
             'Position',[110 20 24 24],...
             'CData',obj.icons.play.img,...
             'UserData',struct('VideoRunning',false),...
             'Callback',@(src,evt)obj.buttonPlayPause(src),...
             'Tooltip','Play');
         
         obj.StopBtn = uicontrol(obj.cmdPanel,'Style', 'push',...
             'Units', 'pixels',...
             'Position',[140 20 24 24],...
             'CData',obj.icons.stop.img,...
             'UserData',struct('BufferRunning',true),...
             'Callback',@(src,evt)obj.buttonStop(src),...
             'Tooltip','Stop buffering');
         drawnow;
         
          obj.SpeedSlider = uicontrol(obj.cmdPanel,'Style', 'slider',...
             'Units', 'pixels',...
             'Position',[170 20 100 20],...
             'min',log10(1/10),'max',log10(10),'Value',0,'Tooltip','Speed');
         sliderLabel = uicontrol(obj.cmdPanel,'Style', 'edit',...
             'Units', 'pixels',...
             'Position',[275 20 20 20],...
             'BackgroundColor',nigeLab.defaults.nigelColors('onsurface'),...
             'String','1');
         fcnlist = {{@(src,evt)obj.nigelCam.setSpeed(10^src.Value)},...
             {@(src,evt)set(sliderLabel,'String',num2str(10^src.Value))}};
         obj.SpeedSlider.Callback = @(src,evt)nigeLab.utils.multiCallbackWrap(src,evt,fcnlist);
         
         fcnlist = {{@(src,evt)obj.nigelCam.setSpeed(str2double(src.String))},...
             {@(src,evt)set(obj.SpeedSlider,'Value',log10(str2double(src.String))) }};
         sliderLabel.Callback = @(src,evt)nigeLab.utils.multiCallbackWrap(src,evt,fcnlist);
         
         frameFBtn = uicontrol(obj.cmdPanel,'Style', 'push',...
             'Units', 'pixels',...
             'Position',[330 20 24 24],...
             'CData',obj.icons.nextF.img,...
             'UserData',struct('VideoRunning',false),...
             'Callback',@(src,evt)obj.nigelCam.frameF,...
             'Tooltip','Next frame');
         frameBBtn = uicontrol(obj.cmdPanel,'Style', 'push',...
             'Units', 'pixels',...
             'Position',[300 20 24 24],...
             'CData',obj.icons.backF.img,...
             'UserData',struct('VideoRunning',false),...
             'Callback',@(src,evt)obj.nigelCam.frameB,...
             'Tooltip','Previous frame');
         
         
         obj.SynchButton = uicontrol(obj.cmdPanel,'Style','togglebutton',...
             'Units', 'pixels',...
             'Position',[obj.cmdPanel.Position(3)-100 10 80 20],...
             'String','Synch mode',...
             'BackgroundColor',nigeLab.defaults.nigelColors('primary'),...
             'ForegroundColor',nigeLab.defaults.nigelColors('onprimary'),...
             'Callback',@(src,evt)obj.buttonSynch(src));
         
         obj.StretchButton = uicontrol(obj.cmdPanel,'Style','togglebutton',...
             'Units', 'pixels',...
             'Position',[obj.cmdPanel.Position(3)-100 35 80 20],...
             'String','Stretch mode',...
             'BackgroundColor',nigeLab.defaults.nigelColors('primary'),...
             'ForegroundColor',nigeLab.defaults.nigelColors('onprimary'),...
             'Callback',@(src,evt)obj.buttonStretch(src));
         
         obj.ZoomButton = uicontrol(obj.cmdPanel,'Style','togglebutton',...
             'Units', 'pixels',...
             'Position',[obj.cmdPanel.Position(3)-140 20 24 24],...
             'CData',obj.icons.zoom.img,...
             'Callback',@(src,evt)zoom(obj.sigAxes,[bool2onoff(src.Value)])...
         );
     
     obj.PanButton = uicontrol(obj.cmdPanel,'Style','togglebutton',...
             'Units', 'pixels',...
             'Position',[obj.cmdPanel.Position(3)-170 20 24 24],...
             'CData',obj.icons.pan.img,...
             'Callback',@(src,evt)pan(obj.sigAxes,[bool2onoff(src.Value)])...
         );
         
          function str = bool2onoff(val)
             if val
                 str = 'xon';
             else
                str = 'off'; 
             end
          end
         
         drawnow;
         
         
         % borders from btns
         jh = nigeLab.utils.findjobj(obj.ScrollRightBtn);
         jh1 = nigeLab.utils.findjobj(obj.ScrollLeftBtn);
         tic;
         while(isempty(jh) || isempty(jh1))
            jh = nigeLab.utils.findjobj(obj.ScrollRightBtn);
            jh1 = nigeLab.utils.findjobj(obj.ScrollLeftBtn); 
            t = toc;
            if t>5
                return;
            end
         end
         jh.setBorderPainted(false);    
         jh.setContentAreaFilled(false);
         jh1.setBorderPainted(false);    
         jh1.setContentAreaFilled(false);
          
      end
      
      function buildEventPanel(obj)
          obj.evtFigure = figure('Units','pixels',...
              'Position',[1070 330 400 650],...
              'ToolBar','none',...
              'MenuBar','none',...
              'Color',nigeLab.defaults.nigelColors('bg'),...
              'KeyPressFcn',@(src,evt)set(src,'UserData',evt.Key),...
              'KeyReleaseFcn',@(src,evt)set(src,'UserData','foobar'),...
              'UserData','foobar');
          
          obj.evtPanel = uipanel(obj.evtFigure,'Units','normalized',...
              'Position',[0 0.1 .499 .89],...
              'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
              'BorderType','line',...
              'Title','Events',...
              'FontSize',15,...
              'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'));
          obj.lblPanel = uipanel(obj.evtFigure,'Units','normalized',...
              'Position',[0.5 0.1 .499 .89],...
              'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
              'BorderType','line',...
              'Title','Labels',...
              'FontSize',15,...
              'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'));
          
          btnPnlLabel = uipanel(obj.lblPanel,'Units','normalized',...
              'Position',[0 0 1 .05],...
              'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
              'BorderType','none');
          btnPnlEvents = uipanel(obj.evtPanel,'Units','normalized',...
              'Position',[0 0 1 .05],...
              'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
              'BorderType','none');
          
          panels = [btnPnlEvents btnPnlLabel];
          fcnList = {@(src,evt)obj.addNewEvent @(src,evt)obj.addNewLabel;...
              @(src,evt)obj.clearEvents @(src,evt)obj.clearLabels};
          for ii =1:numel(panels)
              p = panels(ii);
              p.Units = 'pixels';
              midPanel = p.Position(4)/2 -12;
              addBtn = uicontrol(p,'Style','push',...
                  'Position',[10 midPanel 24 24],...
                  'CData',double(obj.icons.plus.img)./255,...
                  'String','',...
                  'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                  'Callback',fcnList{1,ii});
              clrBtn = uicontrol(p,'Style','push',...
                  'Position',[45 midPanel 24 24],...
                  'CData',double(obj.icons.clear.img)./255,...
                  'String','',...
                  'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                  'Callback',fcnList{2,ii});
              for btn = [addBtn, clrBtn]
                  jh1 = nigeLab.utils.findjobj(btn);
                  tic;
                  while(isempty(jh1))
                      jh1 = nigeLab.utils.findjobj(btn);
                      t = toc;
                      if t>5
                          return;
                      end
                  end
                  jh1.setBorderPainted(false);
                  jh1.setContentAreaFilled(false);
              end
          end
          
          % Build Trial progression bar
          obj.trialProgAx = axes(obj.evtFigure,'Units','normalized',...
              'Position',[0 0 1 .1],'Toolbar',[],...
              'Color',nigeLab.defaults.nigelColors('sfc'));
          obj.trialProgAx.XAxis.Visible = false;
          obj.trialProgAx.YAxis.Visible = false;
          xlim(obj.trialProgAx,[0 1]);
          ylim(obj.trialProgAx,[0 1]);
          pct = obj.TrialIdx ./ obj.nTrial;
          obj.trialProgBar = patch([0 pct pct 0],[0 0 1 1],nigeLab.defaults.nigelColors('primary'));
          
      end
      
      function addNewLabel(obj,Name,Value,Trial)
          if nargin == 1 % no info provided, prompt the user
             [Pars] = inputdlg({'Label Name';'Data'},'Enter label values.',[1 10],{'event', '0'});
             if isempty(Pars)  % cancelled
                 return;
             end
             Value = str2double(Pars{2});
             Name = Pars{1};
          end
          if nargin <3
              Value = 0;
          end
          if nargin < 4 % Name and Time provided
            Trial = obj.TrialIdx;
         end
          if ~isempty(obj.getLblByKey(obj.TrialIdx,Name))
              warning(sprintf('Only one label with ID %s is permitted for trial %d.\nOperation aborted.\n',Name,obj.TrialIdx));
              return;
          end
          
          obj.lblPanel.Units = 'pixels';
          pnlH = 20;
          maxW = obj.lblPanel.InnerPosition(3);
          pnlW = maxW-10;
          dist = 5;
          Top = obj.lblPanel.InnerPosition(4)-10;
          n = numel(obj.lblElementList);
          pos = [5 Top-pnlH-(pnlH+dist)*n ,...
              pnlW pnlH];
          if pos(2)<0
              pos(2) = obj.lblElementList(end).Position(2);
              for c = obj.lblElementList
                  c.Position(2) = c.Position(2)+pnlH+dist;
              end
          end
          
          
          cm = uicontextmenu(obj.evtFigure);         
          thisEvent = uipanel(obj.lblPanel,...
              'Units','pixels',...
              'Position',pos,...
              'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
              'ButtonDownFcn',@obj.labelSelect,...
              'UserData',false,...
              'BorderType','none',...
              'ContextMenu',cm);
          
          Valuelabel = uicontrol(thisEvent,'Style','text',...
              'String','',...
              'FontSize',12,...
              'Units','pixels',...
             'ForegroundColor', nigeLab.defaults.nigelColors('onsurface'),...
             'BackgroundColor', nigeLab.defaults.nigelColors('sfc'),...
             'Position',[pnlW/2 0 40 20],'HitTest','off');
          Namelabel = uicontrol(thisEvent,'Style','text',...
              'String','',...
              'FontSize',12,...
              'Units','pixels',...
             'ForegroundColor', nigeLab.defaults.nigelColors('onsurface'),...
             'BackgroundColor', nigeLab.defaults.nigelColors('sfc'),...
             'Position',[0 0 40 20],'HitTest','off');
         

         obj.link = [ obj.link    linkprop([thisEvent,Valuelabel,Namelabel],'BackgroundColor')];
         obj.lblElementList = [obj.lblElementList thisEvent];

         Valuelabel.String = num2str(Value);
         Namelabel.String = Name;
         Namelabel.Position(3) = min(Namelabel.Extent(3),pnlW/2);
         Valuelabel.Position(3) = min(Valuelabel.Extent(3),pnlW/2);
         
         m1 = uimenu(cm,'Text','Edit','MenuSelectedFcn',@(thisMenu,evt)obj.modifyLabelEntry(thisEvent,Name,Value,thisMenu));
         m2 = uimenu(cm,'Text','Delete','MenuSelectedFcn',@(src,evt)obj.deleteLabelEntry(thisEvent,Name,Value));
         
         this = struct('Name',Namelabel.String,'Time',nan,'Trial',Trial,'Misc',[],'graphicObj',thisEvent);
         obj.TrialLbls = [obj.TrialLbls this];
         notify(obj,'lblAdded',nigeLab.evt.evtChanged({this.Name},nan,{this.Misc},numel(obj.TrialLbls),[this.Trial]));
      end
      function addNewEvent(obj,Name,Time)
          if nargin == 1 % no info provided, prompt the user
             [Pars] = inputdlg({'Event Name';'Event Time'},'Enter event values.',[1 10],{'event', num2str(obj.nigelCam.Time)});
             if isempty(Pars)  % cancelled
                 return;
             end
             Time = str2double(Pars{2});
             Name = Pars{1};
         elseif nargin == 2 % Only name provided
             Time = obj.nigelCam.Time;
         end
          
          
          obj.evtPanel.Units = 'pixels';
          pnlH = 20;
          maxW = obj.evtPanel.InnerPosition(3);
          pnlW = maxW-10;
          dist = 5;
          Top = obj.evtPanel.InnerPosition(4)-10;
          n = numel(obj.evtElementList);
          pos = [5 Top-pnlH-(pnlH+dist)*n ,...
              pnlW pnlH];
          if pos(2)<0
              pos(2) = obj.evtElementList(end).Position(2);
              for c = obj.evtElementList
                  c.Position(2) = c.Position(2)+pnlH+dist;
              end
          end
          
          
          cm = uicontextmenu(obj.evtFigure);         
          thisEvent = uipanel(obj.evtPanel,...
              'Units','pixels',...
              'Position',pos,...
              'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
              'ButtonDownFcn',@obj.eventSelect,...
              'UserData',false,...
              'BorderType','none',...
              'ContextMenu',cm);
          
          Timelabel = uicontrol(thisEvent,'Style','text',...
              'String','',...
              'FontSize',12,...
              'Units','pixels',...
             'ForegroundColor', nigeLab.defaults.nigelColors('onsurface'),...
             'BackgroundColor', nigeLab.defaults.nigelColors('sfc'),...
             'Position',[pnlW/2 0 40 20],'HitTest','off');
          Namelabel = uicontrol(thisEvent,'Style','text',...
              'String','',...
              'FontSize',12,...
              'Units','pixels',...
             'ForegroundColor', nigeLab.defaults.nigelColors('onsurface'),...
             'BackgroundColor', nigeLab.defaults.nigelColors('sfc'),...
             'Position',[0 0 40 20],'HitTest','off');
         

         obj.link = [ obj.link    linkprop([thisEvent,Timelabel,Namelabel],'BackgroundColor')];
         obj.evtElementList = [obj.evtElementList thisEvent];

         Timelabel.String = num2str(Time);
         Namelabel.String = Name;
         Namelabel.Position(3) = min(Namelabel.Extent(3),pnlW/2);
         Timelabel.Position(3) = min(Timelabel.Extent(3),pnlW/2);
         
         m1 = uimenu(cm,'Text','Edit','MenuSelectedFcn',@(thisMenu,evt)obj.modifyEventEntry(thisEvent,Name,Time,thisMenu));
         m2 = uimenu(cm,'Text','Delete','MenuSelectedFcn',@(src,evt)obj.deleteEventEntry(thisEvent,Name,Time));
         
         this = struct('Name',Namelabel.String,'Time',Time,'Trial',obj.TrialIdx,'Misc',[],'graphicObj',thisEvent);
         obj.Evts = [obj.Evts this];
         notify(obj,'evtAdded',nigeLab.evt.evtChanged({this.Name},[this.Time],{this.Misc},numel(obj.Evts),[this.Trial]));
      end
      function clearEvents(obj)
          
          %Deletes selected events
          idx = [obj.evtElementList.UserData];
          alllbls = [obj.evtElementList(idx).Children];
          tt = arrayfun(@(o) str2double(o.String),  alllbls(2,:));
          nn = arrayfun(@(o) o.String,  alllbls(1,:),'UniformOutput',false);
          
          [this,idx] = obj.getEvtByKey(tt,nn);
          delete(obj.evtElementList(idx))
          notify(obj,'evtDeleted',nigeLab.evt.evtChanged({this.Name},[this.Time],{this.Misc},idx,[this.Trial]));
      end
      function clearLabels(obj)
          %Deletes selected events
          idx = [obj.lblElementList.UserData];
          alllbls = [obj.lblElementList(idx).Children];
          nn = arrayfun(@(o) o.String,  alllbls(1,:),'UniformOutput',false);
          
          [this,idx] = obj.getLblByKey(obj.TrialIdx,nn);
          delete(obj.lblElementList(idx))
          notify(obj,'lblDeleted',nigeLab.evt.evtChanged({this.Name},this.Time,{this.Misc},idx,[this.Trial]));
      end       
      
      function modifyEventEntry(obj,thisEventObj,name,time,menu)
          maxW = thisEventObj.InnerPosition(3);
          Namelabel = thisEventObj.Children(1);
          Timelabel = thisEventObj.Children(2);
          [this,idx] = obj.getEvtByKey(time,name);
          [Pars] = inputdlg({'Event Name';'Event Time'},'Enter event values.',[1 10],{name,Timelabel.String});
          Timelabel.String = Pars{2};
          Namelabel.String = Pars{1};
          Namelabel.Position(3) = min(Namelabel.Extent(3),maxW/2);
          Timelabel.Position(3) = min(Timelabel.Extent(3),maxW/2);
          obj.Evts(idx).Name = Pars{1};
          obj.Evts(idx).Time = str2double(Pars{2});
          menu.MenuSelectedFcn = @(thisMenu,evt)obj.modifyEventEntry(thisEventObj,obj.Evts(idx).Name ,obj.Evts(idx).Time,menu);
      end
      function modifyLabelEntry(obj,thisEventObj,name,menu)
          maxW = thisEventObj.InnerPosition(3);
          Namelabel = thisEventObj.Children(1);
          Datalabel = thisEventObj.Children(2);
          [this,idx] = obj.getLblByKey(obj.TrialIdx,name);
          [Pars] = inputdlg({'Label Name';'Data'},'Enter event values.',[1 10],{name,Datalabel.String});
          Datalabel.String = Pars{2};
          Namelabel.String = Pars{1};
          Namelabel.Position(3) = min(Namelabel.Extent(3),maxW/2);
          Datalabel.Position(3) = min(Datalabel.Extent(3),maxW/2);
          obj.TrialLbls(idx).Name = Pars{1};
          obj.TrialLbls(idx).Time = str2double(Pars{2});
          menu.MenuSelectedFcn = @(thisMenu,evt)obj.modifyEventEntry(thisEventObj,obj.TrialLbls(idx).Name ,obj.TrialLbls(idx).Time,menu);
      end
      
      function deleteEventEntry(obj,thisEventObj,name,time)
          [this,idx] = obj.getEvtByKey(time,name);
          delete(thisEventObj);
          notify(obj,'evtDeleted',nigeLab.evt.evtChanged(this.Name,this.Time,this.Misc,idx,this.Trial));
      end  
      function deleteLabelEntry(obj,thisEventObj,name)
          [this,idx] = obj.getLblByKey(obj.TrialIdx,name);
          delete(thisEventObj);
          notify(obj,'lblDeleted',nigeLab.evt.evtChanged(this.Name,[],this.Misc,idx,this.Trial));
      end

      function updateEvtGraphicList(obj)
                  idx = ~isvalid(obj.evtElementList);
                  offset = cumsum(idx);
                  obj.evtElementList(idx) = [];
                  obj.Evts(idx) = [];
                  if sum(~idx)>1
                      ofs = obj.evtElementList(1).Position(2) - obj.evtElementList(2).Position(2);
                      offset(idx) = [];
                      arrayfun(@(c) set(obj.evtElementList(c),'Position',obj.evtElementList(c).Position + [0 offset(c)*ofs 0 0]),1:numel(obj.evtElementList))
                  end
      end
      function updateLblGraphicList(obj)         
                  idx = ~isvalid(obj.lblElementList);
                  offset = cumsum(idx);
                  obj.lblElementList(idx) = [];
                  obj.TrialLbls(idx) = [];
                  if sum(~idx)>1
                      ofs = obj.lblElementList(1).Position(2) - obj.lblElementList(2).Position(2);
                      offset(idx) = [];
                      arrayfun(@(c) set(obj.lblElementList(c),'Position',obj.lblElementList(c).Position + [0 offset(c)*ofs 0 0]),1:numel(obj.lblElementList))
                  end
      end
      
      % Initialize colors
      function initColors(obj)
         obj.colors = struct;
         obj.colors.excluded = nigeLab.defaults.nigelColors('med')*0.75;
         obj.colors.unscored = nigeLab.defaults.nigelColors('light');
         obj.colors.success = nigeLab.defaults.nigelColors('b');
         obj.colors.fail = nigeLab.defaults.nigelColors('r');
      end
      
      % Initialize CData struct containing icon images
      function initIconCData(obj)
         %INITICONCDATA  Initialize CData struct with icon images
         %
         %  initIconCData(obj);
         
         [obj.icons.rightarrow.img,...
          obj.icons.rightarrow.alpha] = nigeLab.utils.getMatlabBuiltinIcon(...
            'continue_MATLAB_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',9 ...
            );
         obj.icons.leftarrow.img = fliplr(obj.icons.rightarrow.img);
         obj.icons.leftarrow.alpha = fliplr(obj.icons.rightarrow.alpha);
         [obj.icons.circle.img,...
          obj.icons.circle.alpha] =nigeLab.utils.getMatlabBuiltinIcon(...
            'greencircleicon.gif',...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.nextF.img,...
          obj.icons.nextF.alpha] = nigeLab.utils.getMatlabBuiltinIcon(...
            'Goto_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',9 ...
            );
        obj.icons.backF.img = fliplr(obj.icons.nextF.img);
        obj.icons.backF.alpha = fliplr(obj.icons.nextF.alpha);
        
        [obj.icons.play.img,...
          obj.icons.play.alpha] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Run_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.stop.img,...
          obj.icons.stop.alpha] =nigeLab.utils.getMatlabBuiltinIcon(...
            'End_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        
        [obj.icons.pause.img,...
          obj.icons.pause.alpha] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Pause_MATLAB_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.plus.img,...
          obj.icons.plus.alpha] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Add_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        
        [obj.icons.clear.img,...
          obj.icons.clear.alpha] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Clear_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.zoom.img,...
          obj.icons.zoom.alpha] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Zoom_In_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.pan.img,...
          obj.icons.pan.alpha] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Pan_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
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
         
%          if nargin < 3
%             vidStreamInfo = obj.Block.UserData.vidStreamInfo;
%          end
%          
%          if nargin < 2
%             digStreamInfo = obj.Block.UserData.digStreamInfo;
%          end
         
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
         addBoundaryIndicators(obj);
         
         % Add indicator for current times
         addTimeMarker(obj);
         
         % Add any potential streams
         for i = 1:numel(obj.vid)
            obj.vid(i).h = ...
               simplePlot(obj.Axes,...
               obj.vid(i).obj.t,...       % Time from diskfile_
               obj.vid(i).obj.data,...    % Data from diskfile_
               'Color',obj.v(i).col,...
               'Displayname',obj.v(i).name,...
               'Tag',obj.v(i).name,...
               'Clipping','on',...
               'UserData',struct('index',i),...
               'ButtonDownFcn',@obj.axesClickedCB);
            obj.vid(i).h.Annotation.LegendInformation.IconDisplayStyle = 'on';
         end
         
         % Plot any digital streams (if present)
         for i = 1:numel(obj.dig)
            obj.dig(i).h = ...
               simplePlot(obj.Axes,...
               obj.dig(i).obj.t,...       % Time from diskfile_
               obj.dig(i).obj.data,...    % Data from diskfile_
               'Tag',obj.dig(i).name,...
               'DisplayName',obj.dig(i).name,...
               'LineWidth',1.5,...
               'Color',obj.dig(i).col,...
               'Clipping','on',...
               'ButtonDownFcn',@obj.seriesClickedCB,...
               'UserData',struct('index',1),...
               'XTol',1,...
               'YTol',0.25);
            obj.dig(i).h.XData = obj.dig(i).h.XData + obj.NeuOffset;
            obj.dig(i).h.Annotation.LegendInformation.IconDisplayStyle = 'on';
         end
         
         if ~isempty(obj.TimeStampValues)
            setTimeStamps(obj,obj.TimeStampValues,'on',obj.TimeStampNames{:});
         else
            setLegend(obj);            
         end
         set(obj,'XLim','far');
      end
      
      function paintTrials(obj)
          HasTrials = ~isempty(obj.Block.Trial);
          if isempty(obj.trialsOverlayChk )
              if HasTrials,Status = 'on';else,Status = 'off';end
                  obj.trialsOverlayChk = uicontrol(obj.cmdPanel,'Style','checkbox',...
                  'Units', 'pixels',...
                  'Position',[obj.cmdPanel.Position(3)-260 20 80 20],...
                  'String','View Trials',...
                  'Enable',Status,...
                  'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                  'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'));
          end
          if HasTrials
              
              X = [obj.Block.Trial fliplr(obj.Block.Trial)]'*1e3;
              obj.nTrial = size(X,2);
              Y = [zeros(obj.nTrial,2) ones(obj.nTrial,2)]';
              P = patch(obj.sigAxes,X,Y,nigeLab.defaults.nigelColors('primary'),'EdgeColor','none','FaceAlpha',0.75,'HitTest','off');
              obj.trialsOverlayChk.Callback = @(src,evt)set(P,'Visible',src.Value);
              obj.trialsOverlayChk.Value = true;
          end
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
         obj.Legend.FontName = 'Droid Sans';
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
         
         if diff(xLim) > 120e3
            tUnits = 'm';
            tVal = linspace(xLim(1),xLim(2),10);
            % Drop first and last ticks
            tVec = tVal(2:(end-1));

            % Labels reflect `tVal` (minutes)
            col = nigeLab.defaults.nigelColors('onsurface');
            tLabel = sprintf('\\\\color[rgb]{%d,%d,%d} %%5.1f%c',col(1),col(2),col(3),tUnits); 
            tLabel = arrayfun(@(v)sprintf(tLabel,v),tVec./60e3,'UniformOutput',false);
         else
            tUnits = 's';
            tVal = linspace(xLim(1),xLim(2),10);
            % Drop first and last ticks
            tVec = tVal(2:(end-1));

            % Labels reflect `tVal` (seconds)
            col = nigeLab.defaults.nigelColors('onsurface');
            tLabel = sprintf('\\\\color[rgb]{%d,%d,%d} %%7.3f%c',col(1),col(2),col(3),tUnits); 
            tLabel = arrayfun(@(v)sprintf(tLabel,v),tVec./1e3,'UniformOutput',false);
         end
      end
   end
   % % % % % % % % % % END METHODS% % %
end

