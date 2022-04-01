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
      VidComPanel
      FigComPanel
      SigComPanel
      sigAxes
      cmdPanel
      camPanel
      loadingPanel
      exportPanel
      
      
      evtFigure
      evtPanel
      lblPanel
      evtElementList     matlab.ui.container.Panel
      lblElementList     matlab.ui.container.Panel
      link = [];
      trialProgAx
      trialProgBar
      
      Now
      SignalTree
      
      colors
      icons       (1,1)struct = struct('leftarrow',[],'rightarrow',[],'circle',[],'play',[],'pause',[]);

      TimerBtn
      AutoSaveBtn
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
       
       nigelCam             % preferred camera
       nigelCamArray        % Array of nigelCam obj
       Block                % "Parent" nigeLab.Block object
       
       listeners
       AutoSaveTimer
       
   end
   
   % HIDDEN,DEPENDENT,PUBLIC
   properties (Hidden,Access=public)
      
      PerformanceTimer struct = struct('T_elaps',0,'Trial_scored',0,'Timer',[]);
      Evts           struct = repmat(struct('Time',[],'Name',[],'Trial',[],'Misc',[],'graphicObj',[]),1,0);
      TrialLbls      struct = repmat(struct('Time',[],'Name',[],'Trial',[],'Misc',[],'graphicObj',[]),1,0);
   end
   
   % HIDDEN,PUBLIC
   properties (Hidden,Access=public)
       exportFrom    matlab.ui.control.CheckBox                % flags to activate/deactivate export of videos
   end
   
   
   % TRANSIENT,PROTECTEDadd
   properties (Access=protected)
      DX        (1,1) double = 1   % "Stored" axes limit difference
      XLim      (1,2) double = [0 1]  % "Stored" axes limits
   end
     
   % % % % % % % % % % END PROPERTIES %
   
   events
      evtAdded
      lblAdded
      evtDeleted
      lblDeleted
      evtModified
   end
   
   % % % METHODS% % % % % % % % % % % %
   
   %Constructors
   methods %(Access=?nigeLab.libs.VidGraphics)
      % Constructor
      function obj = VidScorer(nigelCams,varargin)
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
         elseif isnumeric(nigelCams)
            dims = nigelCams;
            if numel(dims) < 2
               dims = [zeros(1,2-numel(dims)),dims];
            end
            obj = repmat(obj,dims);
            return;
         end
         
         obj.nigelCamArray = nigelCams;
         arrayfun(@(v)v.setActive(false),obj.nigelCamArray(2:end));

         obj.nigelCam = nigelCams(1);
         obj.VideoTime = obj.nigelCam.getTimeSeries;
         obj.VideoTime = obj.VideoTime- ...
             obj.nigelCam.VideoOffset- ...
             (1:numel(obj.VideoTime)).* obj.nigelCam.VideoStretch;
         
         obj.Block = obj.nigelCam.Parent;
         obj.NeuTime =obj.Block.Time(:);
         if isempty(obj.NeuTime)
             obj.NeuTime = (1:obj.Block.Samples)./obj.Block.SampleRate * 1e3;
         end
         obj.XLim = [0 obj.nigelCam.Meta(end).duration*1.05];
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
         

        obj.buildTimeAxesGraphics();
        setToLoading(obj,true);
        obj.buildCmdPanel();
        obj.buildExportPanel();
        obj.buildCamPanel();
        buildEventPanel(obj);
        
              
        obj.nigelCam.showThumb();
        obj.nigelCam.startBuffer();
        
        obj.addListeners();
        obj.paintTrials();
        
        
        % recover events and labels from block
         lblIdx = isnan([obj.Block.Events.Ts]);
         lbls = obj.Block.Events(lblIdx);
         for this = lbls
             idx = find(cellfun(@isnumeric,this.Data));
             addNewLabel(obj,this.Name{:},this.Data{idx(1)},this.Trial,false)
         end
         evts = obj.Block.Events(~lblIdx);
         for this = evts
             if iscell(this.Name)
                this.Name = this.Name{:};
             end
             addNewEvent(obj,this.Name,this.Ts,this.Trial,false)
         end
        
        updateTimeMarker(obj);
        
        obj.AutoSaveTimer = timer('TimerFcn',@(~,~)save(obj.Block),'Period',300,'ExecutionMode','fixedDelay');
        setToLoading(obj,false);
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
          stop(obj.AutoSaveTimer);
          delete(obj.AutoSaveTimer);
          % request all cameras to close, to be implemented in c++
          arrayfun(@(x) x.closeFig,obj.nigelCamArray)
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
          obj.listeners = addlistener(obj.nigelCam,'timeChanged',@(src,evt)obj.updateTimeMarker);
          obj.listeners = [obj.listeners addlistener(obj,'evtDeleted',@(src,evt)obj.updateEvtGraphicList)];
          obj.listeners = [obj.listeners addlistener(obj,'lblDeleted',@(src,evt)obj.updateLblGraphicList)];
          
          obj.listeners = [obj.listeners addlistener(obj.nigelCam,'streamAdded',@(src,evt)obj.updateStreams(evt,src))];
          
          obj.listeners = [obj.listeners addlistener(obj,'TrialIdx','PostSet',@obj.TrialIdxChanged)];
          obj.listeners = [obj.listeners addlistener(obj,'NeuOffset','PostSet',@obj.NeuOffsetChanged)];
          
          obj.listeners = [obj.listeners addlistener(obj,'evtAdded',@(src,evt)obj.Block.addEvent(evt))];
          obj.listeners = [obj.listeners addlistener(obj,'evtDeleted',@(src,evt)obj.Block.deleteEvent(evt))];
          obj.listeners = [obj.listeners addlistener(obj,'lblAdded',@(src,evt)obj.Block.addEvent(evt))];
          obj.listeners = [obj.listeners addlistener(obj,'lblDeleted',@(src,evt)obj.Block.deleteEvent(evt))];
          
          obj.listeners = [obj.listeners addlistener(obj,'evtModified',@(src,evt)obj.Block.modifyEvent(evt))];

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
      function updateTimeMarker(obj)
          obj.Now.XData = ones(2,1)*obj.nigelCam.Time;

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
      function updateSigAxLimits(obj,dir)
          nXl = obj.sigAxes.XLim;
          diff = obj.sigAxes.XLim*[-1 1]';
          if dir == 1
              nXl(2) = min(nXl(2)+diff,obj.XLim(2));
              nXl(1) = nXl(2) - diff;
          elseif dir == -1
              nXl(1) = max(nXl(1)-diff,obj.XLim(1));
              nXl(2) = nXl(1) + diff;
          end
          xlim(obj.sigAxes,nXl);
      end
      
      function TrialIdxChanged(obj,~,~)
          pct = obj.TrialIdx ./ obj.nTrial;
          obj.trialProgBar.XData = [0 pct pct 0];
          
          obj.TrialLabel.Value = num2str(obj.TrialIdx);
          
          % updating event list hiding events outside of this trial
          [obj.evtElementList.Visible] = deal(false);
          [obj.evtElementList([obj.Evts.Trial] == obj.TrialIdx).Visible] = deal(true);
          
          % updating lbl list hiding events outside of this trial
          [obj.lblElementList.Visible] = deal(false);
          [obj.lblElementList([obj.TrialLbls.Trial] == obj.TrialIdx).Visible] = deal(true);
      end
      function NeuOffsetChanged(obj,~,~)
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
       
      % retrieves events or label by name and time
      function [evt,idx] = getEvtByKey(obj,Time,Name)
          evt_ = [];
          idx_ = [];
          if ~isscalar(Time)
              [evt_,idx_] = getEvtByKey(obj,Time(2:end),Name(2:end));
              Time = Time(1);
              Name = Name(1);
          end
           idx = [obj.Evts.Time] == Time;
           if sum(idx)>1
              idx2 = strcmp({obj.Evts(idx).Name},Name);
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
           if sum(idx)>0
              idx2 = strcmp({obj.TrialLbls(idx).Name},name);
              idx(idx) = idx2;
           end
           evt = [evt_ obj.TrialLbls(idx)];
           idx = [idx_ find(idx)];
      end
      
      function updateStreams(obj,src,~)
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
      
      function T = projectInVideoTime(obj,t)
          T = nan(size(t));
          [~,idx]=arrayfun(@(x) min(abs(obj.VideoTime  - x)),t);
          trueVideoTime = obj.nigelCam.getTimeSeries;
          T = trueVideoTime(idx);
      end
   end
   
   % SEALED,PROTECTED Callbacks
   methods (Sealed,Access=protected)
       % Signal Axes click callback, seeks the video
       function sigAxClick(obj,~,evt)
           obj.Now.XData = ones(2,1)*evt.IntersectionPoint(1);
           arrayfun(@(v) v.seek(obj.Now.XData(1)), obj.nigelCamArray);
       end
       
       function toggleAutoSave(obj,src)
           if src.UserData.AutoSave
               src.UserData.AutoSave = false;
               src.Icon = obj.icons.saveOff.img;
               stop(obj.AutoSaveTimer);
           else
               src.Icon = obj.icons.saveOn.img;
               src.UserData.AutoSave = true;
               start(obj.AutoSaveTimer);
           end
           drawnow;
       end
       
       function toggleTimer(obj,src)
           if ~src.Value
               %if active we stop the timer and report performance
               %struct('T_elaps',0,'Trial_scored',0,'Timer',[]);
               obj.PerformanceTimer.T_elaps = toc(obj.PerformanceTimer.Timer);
               
               disp('----------------------------------------------------------------------');
               disp('Performance report:');
               fprintf('%d trials were scored in %f seconds.\n',...
                   numel(obj.PerformanceTimer.Trial_scored),obj.PerformanceTimer.T_elaps);
               
               fprintf('The mean scoring time was %d.\n',...
                   numel(obj.PerformanceTimer.Trial_scored)./obj.PerformanceTimer.T_elaps);
               
               trialsLeft = size(obj.Block.Trial,1)-numel(unique([obj.TrialLbls.Trial]));
               fprintf('Estimated time of arrival for this Block is %f seconds.\n',...
                   obj.PerformanceTimer.T_elaps./numel(obj.PerformanceTimer.Trial_scored)*trialsLeft);
           else
               %if inactive we start the timer
               obj.PerformanceTimer.Timer = tic();
               obj.PerformanceTimer.Trial_scored = [];
           end
       end
       
       
      % Play/Paue button. When clicked, also switches icon
      function buttonPlayPause(obj,src)
         %BUTTONCLICKEDCB  Indicate that button is pressed
         %DA RIFAREEEEEE
         %  obj.ScrollLeftBtn.ButtonDownFcn = @(s,~)obj.buttonClickedCB;
         %  obj.ScrollRightBtn.ButtonDownFcn = @(s,~)obj.buttonClickedCB;
         if src.UserData.VideoRunning
             src.UserData.VideoRunning = false;
             src.Icon = obj.icons.play.img;
             obj.nigelCam.pause();
             arrayfun(@(v) v.seek(obj.nigelCam.Time), obj.nigelCamArray(obj.nigelCamArray~=obj.nigelCam));

         else
             src.Icon = obj.icons.pause.img;
             src.UserData.VideoRunning = true;
             obj.nigelCam.play();
         end
         drawnow;
      end
      
      function skipToNext(obj,direction)
          if (obj.TrialIdx+direction <= 0) || (obj.TrialIdx+direction > size(obj.Block.Trial,1))
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
               
               if isempty(obj.sigAxes.UserData.lineObj)
                  % npthing moved
                  obj.sigAxes.UserData = [];
                  return;
               end
              
               UDAta_ = obj.sigAxes.UserData;

              Question = sprintf('Do you want nigel to update the Events'' time?\n');
              ButtonName = questdlg(Question, 'Change Event Time?', 'Yes', 'No', 'Yes');
              if strcmp(ButtonName,'Yes')
                  % Assign the new timeline to the nigelCam.
                  % Change all Events' time accordingly.
                  
                 EvtsT = [obj.Evts.Time]; 
                 if ~isempty(EvtsT)
                     [~,EvtsS] = min(abs(EvtsT*1e3 - obj.VideoTime(:)));
                 end
                 obj.VideoTime = UDAta_.lineObj.x{1};%--move x data
                 % update Evts
                for ii=1:numel(obj.Evts)
                    thisEventObj = obj.Evts(ii).graphicObj;
                    OldName = obj.Evts(ii).Name;
                    OldTime = obj.Evts(ii).Time;
                    NewTime = obj.VideoTime(EvtsS(ii))./1e3; % get corresponding shifted time. From ms to s
                    modifyEventEntry(obj,thisEventObj,OldName,OldTime,OldName,NewTime)
                end
              else
                  obj.VideoTime = UDAta_.lineObj.x{1};%--move x data
              end
              
              ShiftedTime = obj.nigelCam.getTimeSeries - obj.nigelCam.VideoOffset;
              obj.nigelCam.VideoStretch = (ShiftedTime(end) - obj.VideoTime(end))./numel(obj.VideoTime);
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
              UDAta.xNew =out(1,1);
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
              
              if isempty(obj.sigAxes.UserData.lineObj)
                  % npthing moved
                  obj.sigAxes.UserData = [];
                  return;
              end
              
              UDAta_ = obj.sigAxes.UserData;
              
              Question = sprintf('Do you want nigel to update the Events'' time?\n');
              ButtonName = questdlg(Question, 'Change Event Time?', 'Yes', 'No', 'Yes');
              if strcmp(ButtonName,'Yes')
                  % Assign the new timeline to the nigelCam.
                  % Change all Events' time accordingly.
                  
                 EvtsT = [obj.Evts.Time]; 
                 if ~isempty(EvtsT),[~,EvtsS] = min(abs(EvtsT*1e3 - obj.VideoTime(:)));end
                 obj.VideoTime = UDAta_.lineObj.x{1};%--move x data
                
                 % update Evts
                for ii=1:numel(obj.Evts)
                    thisEventObj = obj.Evts(ii).graphicObj;
                    OldName = obj.Evts(ii).Name;
                    OldTime = obj.Evts(ii).Time;
                    NewTime = obj.VideoTime(EvtsS(ii))./1e3; % get corresponding shifted time. From ms to s
                    modifyEventEntry(obj,thisEventObj,OldName,OldTime,OldName,NewTime)
                end
              else
                  obj.VideoTime = UDAta_.lineObj.x{1};%--move x data
              end
              
              ShiftedTime = obj.nigelCam.getTimeSeries - obj.nigelCam.VideoOffset;
              obj.nigelCam.VideoStretch = (ShiftedTime(end) - obj.VideoTime(end))./numel(obj.VideoTime);
              
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
              UDAta.xNew =out(1,1);
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
      
      function treecheckchange(obj,~,src,plotStruct)
%           plotStruct = evt.Nodes.UserData;
          hold(obj.sigAxes,'on')
          setToLoading(obj,true)
          if ismember('ReducedPlot',fieldnames(plotStruct))
              if ~src.Source.Checked
                 plotStruct.ReducedPlot.h_plot.Visible = 'on';
                 src.Source.Checked = true;
              else
                  plotStruct.ReducedPlot.h_plot.Visible = 'off';
                  src.Source.Checked = false;

              end
          else
             
              tt = plotStruct.Time();  % function handle returning the full time vector in ms       
              dd = plotStruct.Data(:);
              dd = dd./max(dd);
              if isempty(tt)
                  if strcmp(plotStruct.Type,'Video')
                      % this should never happend, but just in case
                      if isempty(obj.VideoTime)
                          tt = (1:numel(dd)) ./ obj.nigelCam.Meta(1).frameRate * 1000;
                      else
                          tt = obj.VideoTime;
                      end
                  else
                      if isempty(obj.NeuTime)
                          tt = (1:numel(dd)) ./ obj.Block.SampleRate * 1000;
                      else
                          tt = obj.NeuTime;
                      end
                  end
              end
              plotStruct.ReducedPlot = nigeLab.utils.LinePlotReducer(obj.sigAxes, tt(:)', dd(:)');
              plotStruct.ReducedPlot.h_plot.HitTest = 'off';
              plotStruct.ReducedPlot.h_plot.PickableParts = 'none';

          end
          set(src.Source,'MenuSelectedFcn',@(evt,src)obj.treecheckchange(evt,src,plotStruct))
          hold(obj.sigAxes,'off')
          setToLoading(obj,false)
      end
      
      function eventSelect(obj,src,~)
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
      function labelSelect(obj,src,~)
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
           arrayfun(@(v) v.frameF, obj.nigelCamArray);
       end
       function previousFrame(obj)
           arrayfun(@(v) v.frameB, obj.nigelCamArray);
       end
       function nextTrial(obj)
           obj.skipToNext(1);
       end
       function previousTrial(obj)
           obj.skipToNext(-1);
       end
       function addExternalStreamToCam(obj,prompt,~,~)
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
       function deleteExternalStreamToCam(obj,~,~,stream,strmNode)
           selection = uiconfirm(obj.sigFig,...
               sprintf('Are you sure?\nThis will also erase the signal from the disk.'),...
               'Delete signal','Icon','warning');
           if strcmp(selection,'ok')
               if isfield(stream,'data')
                   delete(stream.data.getPath);
               end
               if isfield(stream,'time')
                   delete(stream.data.getPath);
               end
               
               idx = obj.nigelCam.Streams == stream;
               delete(stream);
               obj.nigelCam.Streams(idx) = [];
               
               delete(strmNode);
               
           end
       end
       function exportFrame(obj)
           arrayfun(@(x) x.exportFrame,obj.nigelCamArray([obj.exportFrom.Value]));
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
         
         obj.sigFig = uifigure('Units','pixels',...
             'Position',[195 110 1500 325],...
             'ToolBar','none',...
             'MenuBar','none',...
             'Color',nigeLab.defaults.nigelColors('bg'),...
             'KeyPressFcn',@(src,evt)nigeLab.workflow.defaultVideoScoringHotkey(evt,obj),...
             'CloseRequestFcn',@(src,evt)obj.delete);
         g = uigridlayout(obj.sigFig,[2 3],...
             'Padding',3*ones(1,4),...
             'BackgroundColor',nigeLab.defaults.nigelColors('bg'),...
             'RowSpacing',2,...
             'ColumnSpacing',2,...
             'ColumnWidth', {'3x','1x','fit'},...             'ColumnWidth', {296,298,298,298,296},...
             'RowHeight',{'1x',70});
         
         obj.VidComPanel = uipanel(g,'Units','normalized',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'BorderType','none',...
             'Title','Video Controls',...
             'FontSize',15,...
             'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'),...
             'ButtonDownFcn',@(~,~)obj.minimizePopUps());
         obj.VidComPanel.Layout.Column = 1; obj.VidComPanel.Layout.Row = 2;
         
         obj.SigComPanel = uipanel(g,'Units','normalized',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'BorderType','none',...
             'Title','Application Controls',...
             'FontSize',15,...
             'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'));
         obj.SigComPanel.Layout.Column = 3; obj.SigComPanel.Layout.Row = 2;
         
         obj.FigComPanel = uipanel(g,'Units','normalized',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'BorderType','none',...
             'Title','Figure Controls',...
             'FontSize',15,...
             'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'));
         obj.FigComPanel.Layout.Column = 2; obj.FigComPanel.Layout.Row = 2;
         
         
         % Make axes for graphics objects
         axGrid = uigridlayout(g,[1 3],...
             'BackgroundColor',nigeLab.defaults.nigelColors('bg'),...
             'ColumnSpacing',1,...
             'RowSpacing',1,...
             'Padding',ones(1,4),...
             'ColumnWidth', {23,'1x',23},...
             'RowHeight',{'1x'});
         axGrid.Layout.Row    = 1;        axGrid.Layout.Column = [1 2];

         axPnl = uipanel(axGrid,'Units','normalized',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'BorderType','none',...
             'AutoResizeChildren','off');
         axPnl.Layout.Row    = 1;        axPnl.Layout.Column = 2;
         ax = axes(axPnl,'XTick',tVec,'XTickLabel',tLabel,...
             'Units','normalized',...
             'Position',[.001 .1 .998 .89],...
             'ButtonDownFcn',@obj.sigAxClick);
         drawnow;
         beforeBtn=uibutton(axGrid,'push',...
             'Text','<',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'FontColor',nigeLab.defaults.nigelColors('onsfc'),...
             'Tooltip','Move time backwards',...
             'ButtonPushedFcn',@(evt,src)obj.updateSigAxLimits(-1));
         beforeBtn.Layout.Row    = 1;beforeBtn.Layout.Column    = 1;
         afterBtn=uibutton(axGrid,'push',...
             'Text','>',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'FontColor',nigeLab.defaults.nigelColors('onsfc'),...
             'Tooltip','Move time forwards',...
             'ButtonPushedFcn',@(evt,src)obj.updateSigAxLimits(1));
         afterBtn.Layout.Row    = 1;afterBtn.Layout.Column    = 3;

         xlim(ax,obj.XLim);
         ax.YAxis.Visible = 'off';
         ylim(ax,[0 1.2]);
         
         
         
         %% Init tree for streams visualization
         obj.SignalTree = uitree(g);
         % Assign it to the right spot in the layout
         obj.SignalTree.Layout.Column = 3; obj.SignalTree.Layout.Row = 1;
        
         set(obj.SignalTree,...      % set all properties
             'FontName','Droid Sans',...
             'FontSize',15,...
             'Tag','Tree',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'FontColor',nigeLab.defaults.nigelColors('onsfc'));
         
         % add a parent node for the streams inherited from Block
         blkNode = uitreenode(obj.SignalTree,...
             'Text','Block streams',...
             'Parent',obj.SignalTree);
         blkStreams = fieldnames(obj.Block.Streams);
         
         for ss = 1:numel(blkStreams) % for all the different stream types
             strmTypeNode = uitreenode(blkNode,'Text',blkStreams{ss});
             
             % create another root node
             for tt =1:numel(obj.Block.Streams.(blkStreams{ss}))
                 
                 % get time and convert it from samples to ms without loading data in memory
                 pltData.Time = @(t) obj.Block.Time(:).* 1000; 
                 pltData.Data = obj.Block.Streams.(blkStreams{ss})(tt).data;
                 if obj.Block.Time.length ~= pltData.Data.length
                     pltData.Time = [1:length(pltData.Data)]./obj.Block.Streams.(blkStreams{ss})(tt).fs * 1000;
                 end
                 pltData.Type = 'ePhys';
                 
                 % create the menu to plut or hide
                 mm = uicontextmenu(obj.sigFig);
                 m1 = uimenu(mm,'Text','Plot signal',...
                     'Checked',false,...
                     'MenuSelectedFcn',@(evt,src)obj.treecheckchange(evt,src,pltData));
                 
                 % finally make the node
                 strmNode = uitreenode(strmTypeNode,...
                     'Text',obj.Block.Streams.(blkStreams{ss})(tt).name,...
                     'UIContextMenu',mm);
             end
         end
         
         %% video streams
         
         % create a menu for the top level video nodes to add external
         % signals or signals gathered from videos
         mm = uicontextmenu(obj.sigFig);
         m1 = uimenu(mm,'Text','Add stream from video','MenuSelectedFcn',@(evt,src)obj.addExternalStreamToCam(false,evt,src));
         m1 = uimenu(mm,'Text','Add external stream','MenuSelectedFcn',@(evt,src)obj.addExternalStreamToCam(true,evt,src));
         vidNode = uitreenode(obj.SignalTree,...
             'Text','Video streams',...
             'UIContextMenu',mm);
         for tt =1:numel(obj.nigelCam.Streams)
             % create structure with everything to plot signals
             pltData.Time = @(t) obj.VideoTime(:);
             pltData.Data = obj.nigelCam.Streams(tt).data;
             pltData.Type = 'Video';
             
             % actually create the nodes
             strmNode = uitreenode(vidNode,...
                 'Text',obj.nigelCam.Streams(tt).name);
             
              % create treenode menu to plot/hide and delete
             mm = uicontextmenu(obj.sigFig);
             m1 = uimenu(mm,'Text','Delete',...
                 'MenuSelectedFcn',@(evt,src)obj.deleteExternalStreamToCam(evt,src,obj.nigelCam.Streams(tt),strmNode));
             m1 = uimenu(mm,'Text','Plot signal',...
                 'Checked',false,...
                 'MenuSelectedFcn',@(evt,src)obj.treecheckchange(evt,src,pltData));
             set(strmNode,'UIContextMenu',mm);
         end
         
         
%          obj.SignalTree.CheckedNodesChangedFcn = @obj.treecheckchange;
         obj.sigAxes = ax;
         obj.addTimeMarker();
      end
      
      function buildCmdPanel(obj)
                    
         % Create axes for "left-scroll" arrow
         initIconCData(obj);  
         
         obj.ScrollLeftBtn = uibutton(obj.VidComPanel, 'push',...
             'Position',[20 10 24 24],...
             'Icon',obj.icons.leftarrow.img,...
             'Text','',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'ButtonPushedFcn',@(src,evt)obj.skipToNext(-1),...
             'Tooltip','Previous trial');
         
         % Create axes for "right-scroll" button
         obj.ScrollRightBtn = uibutton(obj.VidComPanel, 'push',...
             'Position',[50 10 24 24],...
             'Icon',obj.icons.rightarrow.img,...
             'Text','',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'ButtonPushedFcn',@(src,evt)obj.skipToNext(1),...
             'Tooltip','Next trial');
        obj.TrialLabel = uitextarea(obj.VidComPanel,...
             'Position',[80 10 30 30],...
             'BackgroundColor',nigeLab.defaults.nigelColors('onsurface'),...
             'Value','1',...
             'Tooltip','Trial Index');
         fcnlist = {{@(src,evt)set(obj,'TrialIdx',str2double(src.String))},...
             {@(src,evt)obj.sigAxClick([],struct('IntersectionPoint',obj.Block.Trial(round(str2double(src.String)),1)*1e3)) }};
         
        obj.TrialLabel.ValueChangedFcn = @(src,evt)nigeLab.utils.multiCallbackWrap(src,evt,fcnlist);         
         
         obj.PlayPauseBtn = uibutton(obj.VidComPanel, 'push',...
             'Position',[130 10 24 24],...
             'Icon',obj.icons.play.img,...
             'Text','',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'UserData',struct('VideoRunning',false),...
             'ButtonPushedFcn',@(src,evt)obj.buttonPlayPause(src),...
             'Tooltip','Play');
         
         obj.StopBtn = uibutton(obj.VidComPanel, 'push',...
             'Position',[160 10 24 24],...
             'Icon',obj.icons.stop.img,...
             'Text','',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'UserData',struct('BufferRunning',true),...
             'ButtonPushedFcn',@(src,evt)obj.buttonStop(src),...
             'Tooltip','Stop buffering');
         
         frameBBtn = uibutton(obj.VidComPanel, 'push',...
             'Position',[210 10 24 24],...
             'Icon',obj.icons.backF.img,...
             'Text','',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'UserData',struct('VideoRunning',false),...
             'ButtonPushedFcn',@(src,evt)arrayfun(@(v)v.frameB,obj.nigelCamArray),...
             'Tooltip','Previous frame');          
         frameFBtn = uibutton(obj.VidComPanel, 'push',...
             'Position',[240 10 24 24],...
             'Icon',obj.icons.nextF.img,...
             'Text','',...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'UserData',struct('VideoRunning',false),...
             'ButtonPushedFcn',@(src,evt)arrayfun(@(v)v.frameF,obj.nigelCamArray),...
             'Tooltip','Next frame');
         
         
         obj.SpeedSlider = uislider(obj.VidComPanel,...
             'Position',[290 30 100 3],...
             'Limits',[1 5],...
             'Value',3,...
             'MajorTicks',[1:5],...
             'MajorTickLabels',{'1/3','1/2','1','2','3'},...
             'Tooltip','Speed',...
             'FontName','Droid Sans',...
             'FontSize',8,...
             'FontColor',nigeLab.defaults.nigelColors('onsurface'));
         
         vals = [1/3 1/2 1 2 3];
         fcnlist = @(src,evt)obj.nigelCam.setSpeed(vals(src.Value));             
         obj.SpeedSlider.ValueChangedFcn = fcnlist;
         
         
         
         obj.SynchButton = uibutton(obj.SigComPanel,'state',...
             'Position',[200 2 80 20],...
             'Text','Synch',...
             'BackgroundColor',nigeLab.defaults.nigelColors('primary'),...
             'FontColor',nigeLab.defaults.nigelColors('onprimary'),...
             'ValueChangedFcn',@(src,evt)obj.buttonSynch(src),...
             'Tooltip','Activate synch mode: move the video time to synch it with ePhys.');
         
         obj.StretchButton = uibutton(obj.SigComPanel,'state',...
             'Position',[200 25 80 20],...
             'Text','Stretch',...
             'BackgroundColor',nigeLab.defaults.nigelColors('primary'),...
             'FontColor',nigeLab.defaults.nigelColors('onprimary'),...
             'ValueChangedFcn',@(src,evt)obj.buttonStretch(src),...
             'Tooltip','Activate stretch mode: stretch the video time to synch it with ePhys.');
         
         obj.AutoSaveBtn = uibutton(obj.SigComPanel, 'state',...
             'Position',[10 10 24 24],...
             'Text','',...
             'Icon',obj.icons.saveOff.path,...
             'UserData',struct('AutoSave',false),...
             'ValueChangedFcn',@(src,evt)obj.toggleAutoSave(src),...
             'Tooltip','5 minutes Auto Save');
         
          obj.TimerBtn = uibutton(obj.SigComPanel, 'state',...
             'Position',[40 10 24 24],...
             'Text','',...
             'Icon',obj.icons.timer.path,...
             'UserData',struct('AutoSave',false),...
             'ValueChangedFcn',@(src,evt)obj.toggleTimer(src),...
             'Tooltip','Start timer');
         
         
         
         obj.ZoomButton = uibutton(obj.FigComPanel,'state',...
             'Position',[10 10 24 24],...
             'Text','',...
             'Icon',obj.icons.zoom.path,...
             'Tooltip','Toggles zoom');
         
         obj.PanButton = uibutton(obj.FigComPanel,'state',...
             'Position',[40 10 24 24],...
             'Text','',...
             'Icon',obj.icons.pan.path,...
             'Tooltip','Toggles pan');
         
         fcnlist = {{@(src,evt)zoom(obj.sigAxes,[bool2onoff(src.Value)])}
             {@(~,~)set(obj.PanButton,'Value',0)}};
         obj.ZoomButton.ValueChangedFcn = {@nigeLab.utils.multiCallbackWrap, fcnlist};
         
         fcnlist = {{@(src,evt)pan(obj.sigAxes,[bool2onoff(src.Value)])}
             {@(~,~)set(obj.ZoomButton,'Value',0)}};
         obj.PanButton.ValueChangedFcn = {@nigeLab.utils.multiCallbackWrap, fcnlist};
         
         
          function str = bool2onoff(val)
              if val
                  str = 'xon';
              else
                  str = 'off';
              end
          end
          
   
          ViewBtn = uibutton(obj.VidComPanel,'push',...
              'Position',[750 10 120 24],...
              'Text','Camera views',...
              'Icon',obj.icons.arrow.path,...
              'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
              'FontColor',nigeLab.defaults.nigelColors('onsfc'),...
              'Tooltip','Select what camera to display.',...
              'ButtonPushedFcn',@(~,~)set(obj.camPanel,'Visible',true));
          
          ExportBtn = uibutton(obj.VidComPanel,'push',...
              'Position',[650 10 80 24],...
              'Text','Export',...
              'Icon',obj.icons.arrow.path,...
              'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
              'FontColor',nigeLab.defaults.nigelColors('onsfc'),...
              'Tooltip','Select what camera to display.',...
              'ButtonPushedFcn',@(~,~)set(obj.exportPanel,'Visible',true));
          
          drawnow;

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
              'Position',[0 0.03 .499 .96],...
              'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
              'BorderType','line',...
              'Title','Events',...
              'FontSize',15,...
              'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'),...
              'SizeChangedFcn',@(src,evt)obj.updateEvtGraphicList);
          obj.lblPanel = uipanel(obj.evtFigure,'Units','normalized',...
              'Position',[0.5 0.03 .499 .96],...
              'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
              'BorderType','line',...
              'Title','Labels',...
              'FontSize',15,...
              'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'),...
              'SizeChangedFcn',@(src,evt)obj.updateLblGraphicList);
          
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
              'Position',[0 0 1 .03],'Toolbar',[],...
              'Color',nigeLab.defaults.nigelColors('sfc'));
          obj.trialProgAx.XAxis.Visible = false;
          obj.trialProgAx.YAxis.Visible = false;
          xlim(obj.trialProgAx,[0 1]);
          ylim(obj.trialProgAx,[0 1]);
          pct = obj.TrialIdx ./ obj.nTrial;
          obj.trialProgBar = patch([0 pct pct 0],[0 0 1 1],nigeLab.defaults.nigelColors('primary'));
          
      end
      
      function buildCamPanel(obj)
         % Builds a hidden panel to add new views and change the primary
         % view
         
          obj.camPanel = uipanel(obj.sigFig,...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'Position',[753 35 250 200],...
             'BorderType','line',...
             'FontSize',15,...
             'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'),...
             'Visible',false);
          
         uibutton(obj.camPanel,...
             'Position',[225 170 20 20],...
             'Text','X',...
             'ButtonPushedFcn',@(~,~)set(obj.camPanel,'Visible',false),...
             'FontColor',nigeLab.defaults.nigelColors('onsfc'),...
             'BackgroundColor',nigeLab.defaults.nigelColors('orange'));
         
         uilabel(obj.camPanel,...
             'Position',[10 165 100 30],...
             'FontSize',15,...
             'Text','Camera views',...
             'FontColor',nigeLab.defaults.nigelColors('onsfc'));
         
         camNames = {obj.nigelCamArray.Name};
         
         
         for ii=1:numel(camNames)
             if isempty(camNames{ii})
                camNames{ii} = ''; 
             end
             
             camBoxes(ii)=uicheckbox(obj.camPanel,...
                 'Position',[10 130-(ii-1)*20 100 30],...
                 'Value',ii==1,...
                 'Text',camNames{ii},...
                 'FontSize',10,...
                 'FontColor',nigeLab.defaults.nigelColors('onsfc'),...
                 'ValueChangedFcn',@(src,evt)obj.setViewActive(src,evt,ii));
         end
         
         
         uilabel(obj.camPanel,...
                 'Position',[130 130 100 30],...
                 'FontSize',13,...
                 'FontColor',nigeLab.defaults.nigelColors('onsfc'),...
                 'Text','Main view');
         
         fcnList = {{@(src,evt)set(camBoxes(src.Value),'Value',true)}
             {@(src,evt)obj.setMainView(src.Value)}};
         uidropdown(obj.camPanel,...
                 'Position',[127 100 80 30],...
                 'FontSize',13,...
                 'FontColor',nigeLab.defaults.nigelColors('onsfc'),...
                 'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                 'Items',camNames,...
                 'ItemsData',1:numel(camNames),...
                 'ValueChangedFcn',{@nigeLab.utils.multiCallbackWrap, fcnList});
         
      end
      function setMainView(obj,ii)   
         obj.nigelCam  = obj.nigelCamArray(ii);
         obj.VideoTime = obj.nigelCam.getTimeSeries;
         obj.VideoTime = obj.VideoTime- ...
             obj.nigelCam.VideoOffset- ...
             (1:numel(obj.VideoTime)).* obj.nigelCam.VideoStretch; 
      end
      function setViewActive(obj,~,src,ii)
          obj.nigelCamArray(ii).setActive(src.Value);
          obj.nigelCamArray(ii).seek(obj.nigelCam.Time);
          
          obj.exportFrom(ii).Value = src.Value;
      end
      
      function buildExportPanel(obj)
          %TODO panel to export videos in chunks, useful for deepLabCut
          %integration. 
          % Might also add paired frame export for calibration and kmenas
          % for dlc frame selection
          
          obj.exportPanel = uipanel(obj.sigFig,...
             'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
             'Position',[650 35 250 200],...
             'BorderType','line',...
             'FontSize',15,...
             'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'),...
             'Visible',false);
          
         uibutton(obj.exportPanel,...
             'Position',[225 170 20 20],...
             'Text','X',...
             'ButtonPushedFcn',@(~,~)set(obj.exportPanel,'Visible',false),...
             'FontColor',nigeLab.defaults.nigelColors('onsfc'),...
             'BackgroundColor',nigeLab.defaults.nigelColors('orange'));
         
         uilabel(obj.exportPanel,...
             'Position',[10 165 100 30],...
             'FontSize',15,...
             'Text','Export frames',...
             'FontColor',nigeLab.defaults.nigelColors('onsfc'));
         
         % create the checkboxes to select the cams from where to export
         % frames
         uilabel(obj.exportPanel,...
             'Position',[10 130 100 30],...
             'FontSize',10,...
             'Text','Export from: ',...
             'FontColor',nigeLab.defaults.nigelColors('onsfc'));
         
          camNames = {obj.nigelCamArray.Name};
          for ii=1:numel(camNames)
             if isempty(camNames{ii})
                camNames{ii} = ''; 
             end
             
             obj.exportFrom(ii)=uicheckbox(obj.exportPanel,...
                 'Position',[10 110-(ii-1)*20 100 30],...
                 'Value',ii==1,...
                 'Text',camNames{ii},...
                 'FontSize',10,...
                 'FontColor',nigeLab.defaults.nigelColors('onsfc'));
          end
         
          
          exportBtn = uibutton(obj.exportPanel,'push',...
              'Text','Export',...
              'Position',[10 30 100 30],...
              'ButtonPushedFcn',@(~,~)obj.exportFrame);
      end
      
      function addNewLabel(obj,Name,Value,Trial,notify_)
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
          if nargin < 5 % Name and Time provided
              notify_ = true;
          end
          if ~isempty(obj.getLblByKey(Trial,Name))
              warning(sprintf('Only one label with ID %s is permitted for trial %d.\nOperation aborted.\n',Name,obj.TrialIdx));
              return;
          end
          
          if isnan(Trial) || isinf(Trial)
             return;
          end
          
          % compute correct position of the panel with name and value. It
          % depends on how many labels or events there are in this trial
          obj.lblPanel.Units = 'pixels';
          pnlH = 20;
          maxW = obj.lblPanel.InnerPosition(3);
          pnlW = maxW-10;
          dist = 5;
          Top = obj.lblPanel.InnerPosition(4)-10;
          thisTrialLbls = find([obj.TrialLbls.Trial] == Trial);
          n = numel(thisTrialLbls)+1;
          pos = [5 Top-(pnlH+dist)*n ,...
              pnlW pnlH];
          if pos(2)<0
              pos(2) = obj.lblElementList(thisTrialLbls(end)).Position(2);
              for c = obj.lblElementList(thisTrialLbls)
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
              'ContextMenu',cm,...
              'Visible',notify_);
          
          Valuelabel = uicontrol(thisEvent,'Style','text',...
              'String','',...
              'FontSize',12,...
              'Units','pixels',...
              'Enable','inactive',...
              'ButtonDownFcn',@obj.labelSelect,...
             'ForegroundColor', nigeLab.defaults.nigelColors('onsurface'),...
             'BackgroundColor', nigeLab.defaults.nigelColors('sfc'),...
             'Position',[pnlW/2 0 40 20],'HitTest','off');
          Namelabel = uicontrol(thisEvent,'Style','text',...
              'String','',...
              'FontSize',12,...
              'Units','pixels',...
              'Enable','inactive',...
              'ButtonDownFcn',@obj.labelSelect,...
             'ForegroundColor', nigeLab.defaults.nigelColors('onsurface'),...
             'BackgroundColor', nigeLab.defaults.nigelColors('sfc'),...
             'Position',[0 0 40 20],'HitTest','off');
         
         obj.link = [ obj.link    linkprop([thisEvent,Valuelabel,Namelabel],'BackgroundColor')];
         obj.lblElementList = [obj.lblElementList thisEvent];

         Valuelabel.String = num2str(Value);
         Namelabel.String = Name;
         Namelabel.Position(3) = min(Namelabel.Extent(3),pnlW/2);
         Valuelabel.Position(3) = min(Valuelabel.Extent(3),pnlW/2);
         
         m1 = uimenu(cm,'Text','Edit','MenuSelectedFcn',@(thisMenu,evt)obj.modifyLabelEntry(thisEvent,Name,Value));
         m2 = uimenu(cm,'Text','Delete','MenuSelectedFcn',@(src,evt)obj.deleteLabelEntry(thisEvent,Name,Value));
         
         this = struct('Name',Namelabel.String,'Time',nan,'Trial',Trial,'Misc',Value,'graphicObj',thisEvent);
         obj.TrialLbls = [obj.TrialLbls this];
         if notify_
             notify(obj,'lblAdded',nigeLab.evt.evtChanged({this.Name},nan,{this.Misc},numel(obj.TrialLbls),[this.Trial]));
         end
         
         if ~any(this.Trial == obj.PerformanceTimer.Trial_scored)
             obj.PerformanceTimer.Trial_scored(end+1) = this.Trial;
         end
         obj.lblPanel.Units = 'normalized';
      end
      function addNewEvent(obj,Name,Time,Trial,notify_)
          % Time is in seconds
          if nargin == 1 % no info provided, prompt the user
             [Pars] = inputdlg({'Event Name';'Event Time'},'Enter event values.',[1 10],{'event', num2str(obj.VideoTime(obj.nigelCam.FrameIdx)./1e3)});
             if isempty(Pars)  % cancelled
                 return;
             end
             Time = str2double(Pars{2});
             Name = Pars{1};
             Trial = obj.TrialIdx;
             notify_ = true;
         elseif nargin == 2 % Only name provided
             Time = obj.VideoTime(obj.nigelCam.FrameIdx)./1e3;
             Trial = obj.TrialIdx;
             notify_ = true;
          elseif nargin == 3
              Trial = obj.TrialIdx;
              notify_ = true;
          elseif nargin == 4
              notify_ = true;
          end

          if ~isempty(obj.getEvtByKey(Time,Name))
              warning(sprintf('Only one label with ID %s is permitted for trial %d.\nOperation aborted.\n',Name,obj.TrialIdx));
              return;
          end

          if isnan(Trial) || isinf(Trial)
             return;
          end
           
          % compute correct position of the panel with name and value. It
          % depends on how many labels or events there are in this trial
          obj.evtPanel.Units = 'pixels';
          pnlH = 20;
          maxW = obj.evtPanel.InnerPosition(3);
          pnlW = maxW-10;
          dist = 5;
          Top = obj.evtPanel.InnerPosition(4)-10;
          thisTrialEvts = find([obj.Evts.Trial] == Trial);
          n = numel(thisTrialEvts)+1;
          pos = [5 Top-(pnlH+dist)*n ,...
              pnlW pnlH];
          if pos(2)<0
              pos(2) = obj.evtElementList(thisTrialEvts(end)).Position(2);
              for c = obj.evtElementList(thisTrialEvts)
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
              'ContextMenu',cm,...
              'Visible',notify_);
          
          Timelabel = uicontrol(thisEvent,'Style','text',...
              'String','',...
              'FontSize',12,...
              'Units','pixels',...
              'Enable','inactive',...
              'ForegroundColor', nigeLab.defaults.nigelColors('onsurface'),...
              'BackgroundColor', nigeLab.defaults.nigelColors('sfc'),...
              'Position',[pnlW/2 0 40 20],'HitTest','off');
         Namelabel = uicontrol(thisEvent,'Style','text',...
             'String','',...
             'FontSize',12,...
             'Units','pixels',...
             'Enable','inactive',...
             'ForegroundColor', nigeLab.defaults.nigelColors('onsurface'),...
             'BackgroundColor', nigeLab.defaults.nigelColors('sfc'),...
             'Position',[0 0 40 20],'HitTest','off');
         

         obj.link = [ obj.link    linkprop([thisEvent,Timelabel,Namelabel],'BackgroundColor')];
         obj.evtElementList = [obj.evtElementList thisEvent];

         Timelabel.String = sprintf('%.3f',Time);
         Namelabel.String = Name;
         Namelabel.Position(3) = min(Namelabel.Extent(3),pnlW/2);
         Timelabel.Position(3) = min(Timelabel.Extent(3),pnlW/2);
         
         m1 = uimenu(cm,'Text','Edit','MenuSelectedFcn',@(thisMenu,evt)obj.modifyEventEntry(thisEvent,Name,Time));
         m2 = uimenu(cm,'Text','Delete','MenuSelectedFcn',@(src,evt)obj.deleteEventEntry(thisEvent,Name,Time));
         [~,zz] = min( abs(obj.VideoTime  - Time*1e3));
         T = obj.nigelCam.getTimeSeries;
         m2 = uimenu(cm,'Text','Go to','MenuSelectedFcn',@(src,evt)obj.nigelCam.seek(T(zz)));

         this = struct('Name',Namelabel.String,'Time',Time,'Trial',Trial,'Misc',[],'graphicObj',thisEvent);
         obj.Evts = [obj.Evts this];
         if notify_
             notify(obj,'evtAdded',nigeLab.evt.evtChanged({this.Name},[this.Time],{this.Misc},numel(obj.Evts),[this.Trial]));
         end
         
         if ~any(this.Trial == obj.PerformanceTimer.Trial_scored)
             obj.PerformanceTimer.Trial_scored(end+1) = this.Trial;
         end
         obj.evtPanel.Units = 'normalized';
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
      
      function modifyEventEntry(obj,thisEventObj,OldName,OldTime,NewName,NewTime)
          
          if nargin < 5
              [Pars] = inputdlg({'Event Name';'Event Time'},'Enter event values.',[1 10],[OldName,{sprintf('%.2f',OldTime)}]);
              NewTime = str2double(Pars{2});
              NewName = Pars{1};
          end
          % Get the correct menu
           mIdx = strcmp({thisEventObj.ContextMenu.Children.Text},'Edit');
           menu = thisEventObj.ContextMenu.Children(mIdx);         
          % find selected event
          [Old,idx] = obj.getEvtByKey(OldTime,OldName);
          % get the objects to change
          maxW = thisEventObj.InnerPosition(3);
          Namelabel = thisEventObj.Children(1);
          Timelabel = thisEventObj.Children(2);
          % change GUI
          Timelabel.String = sprintf('%.2f',NewTime);
          Namelabel.String = NewName;
          Namelabel.Position(3) = min(Namelabel.Extent(3),maxW/2);
          Timelabel.Position(3) = min(Timelabel.Extent(3),maxW/2);
          % change evt 
          obj.Evts(idx).Name = NewName;
          obj.Evts(idx).Time = NewTime;
          New = obj.Evts(idx);
          menu.MenuSelectedFcn = @(thisMenu,evt)obj.modifyEventEntry(thisEventObj,obj.Evts(idx).Name ,obj.Evts(idx).Time);
          notify(obj,'evtModified',nigeLab.evt.evtChanged({New.Name},New.Time,{New.Misc},idx,New.Trial,Old));

      end
      function modifyLabelEntry(obj,thisEventObj,OldName,OldValue,NemwName,NewValue)
          
          if nargin < 5
              [Pars] = inputdlg({'Label Name';'Data'},'Enter event values.',[1 10],{OldName,sprintf('%f',OldValue)});
              NewValue = str2double(Pars{2});
              NemwName = Pars{1};
          end
          % Get the correct menu
           mIdx = strcmp({thisEventObj.ContextMenu.Children.Text},'Edit');
           menu = thisEventObj.ContextMenu.Children(mIdx);         
          % find selected label
          [Old,idx] = obj.getLblByKey(obj.TrialIdx,OldName);
          % get the objects to change
          maxW = thisEventObj.InnerPosition(3);
          Namelabel = thisEventObj.Children(1);
          Datalabel = thisEventObj.Children(2);
          % change GUI
          Datalabel.String = sprintf('%f',NewValue);
          Namelabel.String = NemwName;
          Namelabel.Position(3) = min(Namelabel.Extent(3),maxW/2);
          Datalabel.Position(3) = min(Datalabel.Extent(3),maxW/2);
          % change lbl
          obj.TrialLbls(idx).Name = NemwName;
          obj.TrialLbls(idx).Misc = NewValue;
          New = obj.TrialLbls(idx);
          menu.MenuSelectedFcn = @(thisMenu,evt)obj.modifyLabelEntry(thisEventObj,obj.TrialLbls(idx).Name ,obj.TrialLbls(idx).Misc);
          notify(obj,'evtModified',nigeLab.evt.evtChanged({New.Name},New.Time,{New.Misc},idx,New.Trial,Old));
      end
      
      function deleteEventEntry(obj,thisEventObj,name,time)
          [this,idx] = obj.getEvtByKey(time,name);
          delete(thisEventObj);
          notify(obj,'evtDeleted',nigeLab.evt.evtChanged(this.Name,this.Time,this.Misc,idx,this.Trial));
      end  
      function deleteLabelEntry(obj,thisEventObj,name,value)
          [this,idx] = obj.getLblByKey(obj.TrialIdx,name);
          delete(thisEventObj);
          notify(obj,'lblDeleted',nigeLab.evt.evtChanged(this.Name,nan,this.Misc,idx,this.Trial));
      end
      
      function updateEvtGraphicList(obj)
          % delete invalid/deleted entries
          idx = ~isvalid(obj.evtElementList);
          offset = cumsum(idx);
          obj.evtElementList(idx) = [];
          obj.Evts(idx) = [];
          
          % reset position in panel
          thisTrialEvts = obj.evtElementList([obj.Evts.Trial] == obj.TrialIdx);
          if numel(thisTrialEvts)>0
              set(obj.evtPanel,'Units','pixels');Top = obj.evtPanel.InnerPosition(4)-10;set(obj.evtPanel,'Units','normalized');
              ofs = 25;
              allPos = cat(1,thisTrialEvts.Position);
              allPos(:,2) = Top - ofs*(1:numel(thisTrialEvts));
              arrayfun(@(c) set(thisTrialEvts(c),'Position',allPos(c,:)),1:numel(thisTrialEvts))
          end
          
          
      end
      function updateLblGraphicList(obj)
          % delete invalid/deleted entries
          idx = ~isvalid(obj.lblElementList);
          offset = cumsum(idx);
          obj.lblElementList(idx) = [];
          obj.TrialLbls(idx) = [];
          
          % reset position in panel
          thisTrialLbls = obj.lblElementList([obj.TrialLbls.Trial] == obj.TrialIdx);
          if numel(thisTrialLbls)>0
              set(obj.lblPanel,'Units','pixels');Top = obj.lblPanel.InnerPosition(4)-10;set(obj.lblPanel,'Units','normalized');
              ofs = 25;
              allPos = cat(1,thisTrialLbls.Position);
              allPos(:,2) = Top - ofs*(1:numel(thisTrialLbls));
              arrayfun(@(c) set(thisTrialLbls(c),'Position',allPos(c,:)),1:numel(thisTrialLbls))
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
          obj.icons.rightarrow.alpha,...
          obj.icons.rightarrow.path] = nigeLab.utils.getMatlabBuiltinIcon(...
            'continue_MATLAB_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',9 ...
            );
         obj.icons.leftarrow.img = fliplr(obj.icons.rightarrow.img);
         obj.icons.leftarrow.alpha = fliplr(obj.icons.rightarrow.alpha);
         [obj.icons.circle.img,...
          obj.icons.circle.alpha,...
          obj.icons.circle.path] =nigeLab.utils.getMatlabBuiltinIcon(...
            'greencircleicon.gif',...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.nextF.img,...
          obj.icons.nextF.alpha,...
          obj.icons.nextF.path] = nigeLab.utils.getMatlabBuiltinIcon(...
            'Goto_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',9 ...
            );
        obj.icons.backF.img = fliplr(obj.icons.nextF.img);
        obj.icons.backF.alpha = fliplr(obj.icons.nextF.alpha);
        
        [obj.icons.play.img,...
          obj.icons.play.alpha,...
          obj.icons.play.path] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Run_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.stop.img,...
          obj.icons.stop.alpha,...
          obj.icons.stop.path] =nigeLab.utils.getMatlabBuiltinIcon(...
            'End_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        
        [obj.icons.pause.img,...
          obj.icons.pause.alpha,...
          obj.icons.pause.path] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Pause_MATLAB_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.plus.img,...
          obj.icons.plus.alpha,...
          obj.icons.plus.path] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Add_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        
        [obj.icons.clear.img,...
          obj.icons.clear.alpha,...
          obj.icons.clear.path] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Clear_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.zoom.img,...
          obj.icons.zoom.alpha,...
          obj.icons.zoom.path] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Zoom_In_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.pan.img,...
          obj.icons.pan.alpha,...
          obj.icons.pan.path] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Pan_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
         [obj.icons.saveOn.img,...
          obj.icons.saveOn.alpha,...
          obj.icons.saveOn.path] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Save_Dirty_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.saveOff.img,...
            obj.icons.saveOff.alpha,...
            obj.icons.saveOff.path] =nigeLab.utils.getMatlabBuiltinIcon(...
            'Save_24.PNG',...
            'IconPath',fullfile(matlabroot,'toolbox\shared\controllib\general\resources\toolstrip_icons'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.timer.img,...
            obj.icons.timer.alpha,...
            obj.icons.timer.path] =nigeLab.utils.getMatlabBuiltinIcon(...
            'stopwatch.PNG',...
            'IconPath',fullfile(nigeLab.utils.getNigelPath,'+nigeLab','+libs','@VidScorer','private'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
        [obj.icons.arrow.img,...
            obj.icons.arrow.alpha,...
            obj.icons.arrow.path] =nigeLab.utils.getMatlabBuiltinIcon(...
            'arrow.PNG',...
            'IconPath',fullfile(nigeLab.utils.getNigelPath,'+nigeLab','+libs','@VidScorer','private'),...
            'Background','sfc',...
            'BackgroundIndex',8 ...
            );
        
      end

      % Plots trial ovelay on the signal axes
      function paintTrials(obj)
          HasTrials = ~isempty(obj.Block.Trial);
          if isempty(obj.trialsOverlayChk )
              if HasTrials,Status = 'on';else,Status = 'off';end
                  obj.trialsOverlayChk = uicheckbox(obj.FigComPanel,...
                  'Position',[80 20 80 20],...
                  'Text','View Trials',...
                  'Enable',Status,...
                  'FontColor',nigeLab.defaults.nigelColors('onsfc'));
          end
          if HasTrials
              
              X = [obj.Block.Trial fliplr(obj.Block.Trial)]'*1e3;
              obj.nTrial = size(X,2);
              Y = [zeros(obj.nTrial,2) ones(obj.nTrial,2)]';
              P = patch(obj.sigAxes,X,Y,nigeLab.defaults.nigelColors('primary'),'EdgeColor','none','FaceAlpha',0.75,'HitTest','off');
              obj.trialsOverlayChk.ValueChangedFcn = @(src,evt)set(P,'Visible',src.Value);
              obj.trialsOverlayChk.Value = true;
          end
      end
            
      % Inactivate all panels and show loading screen
      function setToLoading(obj,loading)
          if loading
              obj.loadingPanel = uihtml(obj.sigFig,...
                  'Position',[0 0 obj.sigFig.Position(3:4)-2],...
                  'HTMLSource',fullfile(nigeLab.utils.getNigelPath,'+nigeLab','+libs','@VidScorer','private','prova.html'));
              
          else
              delete(obj.loadingPanel);
          end
         drawnow;
      end
      
      function minimizePopUps(obj)
          % helper function to minimize all popups
         popupPans = [obj.exportPanel obj.camPanel];
         set(popupPans,'Visible',false);
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

