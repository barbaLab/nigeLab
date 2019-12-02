classdef alignInfo < handle
% ALIGNINFO  Constructor for handle object that keeps track of
%            synchronization information between video record and
%            digital (neural) streams record.
%
%  obj = nigeLab.libs.alignInfo(blockObj);
%  obj = nigeLab.libs.alignInfo(blockObj,nigelPanelObj);

%% Properties 
   properties(SetAccess = immutable, GetAccess = public)
      Block       % nigeLab.Block object handle
      Panel       % nigeLab.libs.nigelPanel object
      Figure      % Handle to figure containing streams plots
   end

   properties(SetAccess = private, GetAccess = public)
      ax          % Axes to plot streams on
      
      tVid        % Current video time
      tNeu        % Current neural time
      
      vidTime_line     % Line indicating current video time
      

      beam     % Beam break times   
      paw      % Paw guesses from DLC
      press    % Button press times (may not exist)
      

      streams % File struct for data streams
      scalars % File struct for scalar values

      alignLag = nan;   % Best guess or current alignment lag offset
      guess = nan;      % Alignment guess value
      cp                % Current point on axes
      
      curAxLim    % Axes limits for current axes
   end
   
   properties(SetAccess = private, GetAccess = private)
      FS = 125;                  % Resampled rate for correlation
      VID_FS = 30000/1001;       % Frame-rate of video
      currentVid = 1;            % If there is a list of videos
      axLim                      % Stores "outer" axes ranges
      zoomOffset = 4;            % # Seconds to buffer zoom window
      moveStreamFlag = false;    % Flag for moving objects on top axes
      cursorX                    % Current cursor X position on figure
      curOffsetPt                % Last-clicked position for dragging line
      xStart = -10;              % (seconds) - lowest x-point to plot
      zoomFlag = false;          % Is the time-series axis zoomed in?      
   end
   
%% Events
   events % These correspond to different scoring events
      moveOffset  % Alignment has been dragged/moved in some way
      saveFile    % Output file has been saved
      axesClick   % Skip to current clicked point in axes (in video)
      zoomChanged % Axes zoom has been altered
   end
   
%% Methods
   methods (Access = public)
      % Construct alignInfo object that tracks offset between vid and neu
      function obj = alignInfo(blockObj,nigelPanelObj)
         % ALIGNINFO  Constructor for handle object that keeps track of
         %            synchronization information between video record and
         %            digital (neural) streams record.
         %
         %  obj = nigeLab.libs.alignInfo(blockObj);
         %  obj = nigeLab.libs.alignInfo(blockObj,nigelPanelObj);
         
         if ~isa(obj.Block,'nigeLab.Block')
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
         obj.Figure.WindowButtonMotionFcn = @(src,~)obj.setCursorPos;
         
         obj.guessAlignment;
         obj.buildStreamsGraphics;
         
      end
      
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
         graphics = struct('vidTime_line',obj.vidTime_line,...
            'alignment_panel',obj.AlignmentPanel);
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
         align_offset = obj.alignLag - align_offset;
         
         obj.setAlignment(align_offset);
      end

      % Save the output file
      function saveAlignment(obj)
         % SAVEALIGNMENT  Save the alignment lag (output)
         %
         %  obj.saveAlignment;
         
         VideoStart = obj.alignLag;
         fname = fullfile(obj.scalars.alignLag.folder,...
                          obj.scalars.alignLag.name);
         fprintf(1,'Please wait, saving %s...',fname);
         save(fname,'VideoStart','-v7.3');
         fprintf(1,'complete.\n');
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
         set(obj.paw.h,'LineWidth',1);
         set(obj.beam.h,'LineWidth',1);
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
         set(obj.paw.h,'LineWidth',2);
         set(obj.beam.h,'LineWidth',2);
         set(obj.vidTime_line,'LineStyle',':');
         notify(obj,'zoomChanged');
      end
      
      
   end
   
   methods (Access = private)
      % Make all the graphics for tracking relative position of neural
      % (beam/press) and video (paw probability) time series
      function buildStreamsGraphics(obj)
         % BUILDSTREAMGRAPHICS  Make all graphics for tracking relative
         %                      position of neural-sync'd streams (e.g.
         %                      BEAM BREAK or BUTTON PRESS) with video
         %                      (e.g. PAW PROBABILITY) time series.
         %
         %  obj.buildStreamsGraphics;
         
         % Make panel to contain graphics
         obj.AlignmentPanel = uipanel(obj.parent,'Units','Normalized',...
            'BackgroundColor','k',...
            'Position',[0 0 1 0.25]);
         
         % Make axes for graphics objects
         obj.ax = axes(obj.AlignmentPanel,'Units','Normalized',...
              'Position',[0 0 1 1],...
              'NextPlot','add',...
              'XColor','w',...
              'YLim',[-0.2 1.2],...
              'YTick',[],...
              'ButtonDownFcn',@(~,~)obj.clickAxes);
         
         % Make current position indicators for neural and video times
         x = zeros(1,2); % Vid starts at zero
         y = [0 1.1]; % Make slightly taller
         obj.vidTime_line = line(obj.ax,x,y,...
            'LineWidth',2.5,...
            'LineStyle','none',...
            'Marker','v',...
            'MarkerIndices',2,... % Only show top marker
            'MarkerSize',16,...
            'MarkerEdgeColor',[0.3 0.3 0.3],...
            'MarkerFaceColor',[0.3 0.3 0.3],...
            'Color',[0.3 0.3 0.3],...
            'ButtonDownFcn',@(~,~)obj.clickAxes);         
         
         
         % Plot paw probability time-series from DeepLabCut
         obj.paw.h = plot(obj.ax,...
            obj.paw.t,...
            obj.paw.data,...
            'Color','b',...
            'DisplayName','paw',...
            'ButtonDownFcn',@(~,~)obj.clickAxes);
         
         % Make beam break plot
         obj.beam.h = plot(obj.ax,...
            obj.beam.t,...
            obj.beam.data,...
            'Color',[0.8 0.2 0.2],...
            'Tag','beam',...
            'UserData',[0.8 0.2 0.2],...
            'DisplayName','beam',...
            'ButtonDownFcn',@(src,~)obj.clickSeries);
         
         % Check for button presses and add if present
         if isstruct(obj.press)
            obj.press.h = plot(obj.ax,...
               obj.press.t,...
               obj.press.data,...
               'Tag','press',...
               'DisplayName','press',...
               'LineWidth',1.5,...
               'Color',[0 0.75 0],...
               'UserData',[0 0.75 0],...
               'ButtonDownFcn',@obj.clickSeries);
            legend(obj.ax,{'Vid-Time';'Paw';'Beam';'Press'},...
               'Location','northoutside',...
               'Orientation','horizontal',...
               'FontName','Arial',...
               'FontSize',14);
         else
            legend(obj.ax,{'Vid-Time';'Paw';'Beam'},...
               'Location','northoutside',...
               'Orientation','horizontal',...
               'FontName','Arial',...
               'FontSize',14);
         end
                 
         % Get the max. axis limits
         obj.resetAxesLimits;
         
      end
      
      % ButtonDownFcn for top axes and children
      function clickAxes(obj)
         % CLICKAXES  ButtonDownFcn for the alignment axes and its children
         %
         %  ax.ButtonDownFcn = @(~,~)obj.clickAxes;
         
         obj.cp = obj.ax.CurrentPoint(1,1);
         
         % If FLAG is enabled
         if obj.moveStreamFlag
            % Place the (dragged) neural (beam/press) streams with cursor
            obj.resetAxesLimits;
            obj.beam.h.Color = obj.beam.h.UserData;
            obj.beam.h.LineWidth = 2;
            obj.beam.h.LineStyle = '-';
            if isstruct(obj.press)
               obj.press.h.Color = obj.press.h.UserData;
               obj.press.h.LineWidth = 2;
               obj.press.h.LineStyle = '-';
            end
            obj.moveStreamFlag = false;            
         else % Otherwise, allows to skip to point in video
            notify(obj,'axesClick');
         end
      end
      
      % ButtonDownFcn for neural sync time series (beam/press)
      function clickSeries(obj,src)
         % CLICKSERIES  ButtonDownFcn callback for clicking on the neural
         %              sync time series (e.g. BEAM BREAKS or BUTTON PRESS)
         
         if ~obj.moveStreamFlag
            obj.moveStreamFlag = true;
            obj.curOffsetPt = obj.cursorX;
            src.Color = [0.5 0.5 0.5];
            src.LineStyle = '-.';
            src.LineWidth = 1;
         else
            src.Color = src.UserData;
            src.LineStyle = '-';
            src.LineWidth = 2;
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
         %  (obj.alignLag) is equal to the previous obj.alignLag + delta.
         
         align_offset_delta = init_pt - moved_pt;
         new_align_offset = obj.alignLag + align_offset_delta;
         
      end
      
      % Extend or shrink axes x-limits as appropriate
      function resetAxesLimits(obj)
         % RESETAXESLIMITS  Extend or shrink axes x-limits as appropriate
         %
         %  obj.resetAxesLimits;
         
         obj.axLim = nan(1,2);
         obj.axLim(1) = obj.xStart;
         obj.axLim(2) = max(obj.beam.t(end),obj.paw.t(end));
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
         
         obj.alignLag = align_offset;
         obj.updateStreamTime;
         notify(obj,'moveOffset');
      end
      
      % Update the current cursor X-position in figure frame
      function setCursorPos(obj,src)
         % SETCURSORPOS  Update the current cursor X-position based on
         %               mouse cursor movement in current figure frame.
         %
         %  fig.WindowButtonMotionFcn = @(src,~)obj.setCursorPos;  
         %
         %  alignInfoObj is not associated with a figure handle explicitly;
         %  therefore, this method can be set as a callback for any figure
         %  it is "attached" to 
         
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
         obj.beam.t = obj.beam.t0 - obj.alignLag;
         obj.beam.h.XData = obj.beam.t;
         
         if isstruct(obj.press)
            obj.press.t = obj.press.t0 - obj.alignLag;
            obj.press.h.XData = obj.press.t;
            
         end
      end
      
   end

end