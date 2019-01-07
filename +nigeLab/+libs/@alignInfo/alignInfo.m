classdef alignInfo < handle
%% ALIGNINFO  Class to update HUD & track alignment information

%% Properties 
   properties(SetAccess = private, GetAccess = public)
      % Graphics objects
      parent      % Parent figure object
      ax          % Axes to plot streams on
      
      tVid        % Current video time
      tNeu        % Current neural time
      
      vidTime_line     % Line indicating current video time
      
      % Data streams
      beam     % Beam break times   
      paw      % Paw guesses from DLC
      press    % Button press times (may not exist)
      
      % Input files
      streams % File struct for data streams
      scalars % File struct for scalar values
      
      % Scalars
      alignLag = nan;   % Best guess or current alignment lag offset
      guess = nan;      % Alignment guess value
      cp                % Current point on axes
      
      % Graphics info
      curAxLim
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
      
      
      % Graphics
      AlignmentPanel
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
      % Construct the object for keeping track of which "button press" (or
      % trial) we are currently looking at
      function obj = alignInfo(figH,dat_F)
         % Parse parent (must be figure)
         if isa(figH,'matlab.ui.Figure')
            obj.parent = figH;
         else
            error('parentFig argument must be a figure handle.');
         end
         obj.parseInputFiles(dat_F);
         
         obj.guessAlignment;
         obj.buildStreamsGraphics;
         
      end
      
      % Load the digital stream data (alignments like beam,press break)
      function parseInputFiles(obj,F)
         % Initialize data streams as NaN for checks later
         obj.press = nan;
         obj.paw = nan;
         obj.beam = nan;
         
         % Store file info structs as properties
         obj.streams = F.streams;
         obj.scalars = F.scalars;
         
         % Parse streams
         s = fieldnames(F.streams);
         s = s(ismember(s,properties(obj)));
         for ii = 1:numel(s)
            f = F.streams.(s{ii});
            obj.(s{ii}) = loadStream(f);
         end
         
         % Parse scalars
         s = fieldnames(F.scalars);
         s = s(ismember(s,properties(obj)));
         for ii = 1:numel(s)
            f = F.scalars.(s{ii});
            obj.(s{ii}) = loadScalar(f);
         end
         
         % Update if appropriate scalar values are found
         if ~isnan(obj.alignLag)
            disp('Found previous alignment lag.');
            obj.setAlignment(obj.alignLag);
         elseif isnan(obj.alignLag) && ~isnan(obj.guess)
            disp('Found alignment lag guess.');
            obj.setAlignment(obj.guess);         
         end
         
      end
      
      % Set new neural time
      function setNeuTime(obj,t)
         obj.tNeu = t;
      end
      
      % Set new video time
      function setVidTime(obj,t)
         obj.tVid = t;
      end
      
      % Set new neural offset
      function setNewOffset(obj,x)
         align_offset = x - obj.curNeuT.XData(1);
         align_offset = obj.alignLag - align_offset;
         
         obj.setAlignment(align_offset);
      end

      % Save the output file
      function saveAlignment(obj)
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
         obj.curAxLim = [obj.tVid - obj.zoomOffset,...
                         obj.tVid + obj.zoomOffset];
         set(obj.ax,'XLim',obj.curAxLim);
         obj.zoomFlag = true;
         set(obj.paw.h,'LineWidth',2);
         set(obj.beam.h,'LineWidth',2);
         set(obj.vidTime_line,'LineStyle',':');
         notify(obj,'zoomChanged');
      end
      
      % Update the current cursor X-position in figure frame
      function setCursorPos(obj,x)
         obj.cursorX = x * diff(obj.ax.XLim) + obj.ax.XLim(1);
         if obj.moveStreamFlag
            new_align_offset = obj.computeOffset(obj.curOffsetPt,obj.cursorX);
            obj.curOffsetPt = obj.cursorX;
            obj.setAlignment(new_align_offset); % update the shadow positions
            
         end
      end
      
      % Create graphics objects associated with this class
      function graphics = getGraphics(obj)
         
         % Pass everything to listener object in graphics struct
         graphics = struct('vidTime_line',obj.vidTime_line,...
            'alignment_panel',obj.AlignmentPanel);
      end
      
   end
   
   methods (Access = private)
      % Get best of offset using cross-correlation of time series
      function guessAlignment(obj)
         % If guess already exists, skip this part
         if ~isnan(obj.alignLag)
            disp('Skipping computation');
            return;
         end
         
         % Upsample by 16 because of weird FS used by TDT...
         ds_fac = round((double(obj.beam.fs) * 16) / obj.FS);
         x = resample(double(obj.beam.data),16,ds_fac);
         
         % Resample DLC paw data to approx. same FS
         y = resample(obj.paw.data,obj.FS,round(obj.paw.fs));
         
         % Guess the lag based on cross correlation between 2 streams
         tic;
         fprintf(1,'Please wait, making best alignment offset guess (usually 1-2 mins)...');
         [R,lag] = getR(x,y);
         setAlignment(obj,parseR(R,lag));
         alignGuess = obj.alignLag;
         save(fullfile(obj.scalars.guess.folder,...
                       obj.scalars.guess.name),'alignGuess','-v7.3');
         fprintf(1,'complete.\n');
         toc;
      end
      
      % Make all the graphics for tracking relative position of neural
      % (beam/press) and video (paw probability) time series
      function buildStreamsGraphics(obj)
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
              'ButtonDownFcn',@obj.clickAxes);
         
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
            'ButtonDownFcn',@obj.clickAxes);         
         
         
         % Plot paw probability time-series from DeepLabCut
         obj.paw.h = plot(obj.ax,...
            obj.paw.t,...
            obj.paw.data,...
            'Color','b',...
            'DisplayName','paw',...
            'ButtonDownFcn',@obj.clickAxes);
         
         % Make beam break plot
         obj.beam.h = plot(obj.ax,...
            obj.beam.t,...
            obj.beam.data,...
            'Color',[0.8 0.2 0.2],...
            'Tag','beam',...
            'UserData',[0.8 0.2 0.2],...
            'DisplayName','beam',...
            'ButtonDownFcn',@obj.clickSeries);
         
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
      
      % Extend or shrink axes x-limits as appropriate
      function resetAxesLimits(obj)
         obj.axLim = nan(1,2);
         obj.axLim(1) = obj.xStart;
         obj.axLim(2) = max(obj.beam.t(end),obj.paw.t(end));
         if ~obj.zoomFlag
            set(obj.ax,'XLim',obj.axLim);
            obj.curAxLim = obj.axLim;
            notify(obj,'zoomChanged');
         end
      end
      
      % ButtonDownFcn for top axes and children
      function clickAxes(obj,~,~)
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
      function clickSeries(obj,src,~)
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
         align_offset_delta = init_pt - moved_pt;
         new_align_offset = obj.alignLag + align_offset_delta;
         
      end
      
      % Set the trial hand and emit a notification about the event
      function setAlignment(obj,align_offset)
         obj.alignLag = align_offset;
         obj.updateStreamTime;
         notify(obj,'moveOffset');
      end
      
      % Updates stream times and graphic object times associated with
      function updateStreamTime(obj)
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