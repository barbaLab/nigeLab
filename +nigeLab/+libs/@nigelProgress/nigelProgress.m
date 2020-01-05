classdef nigelProgress < handle
% NIGELPROGRESS    Create a bar allowing graphical tracking of
%                  completion status via the bar progress.
%
%   bar = nigeLab.libs.nigelProgress('barName',jobObj,UserData);
%
%   bar  --  output handle to nigeLab.libs.nigelProgress object
%
%   parent -- parent container
%   name  --  char array that is descriptor of thing to monitor
%   sel  --  index referencing the animal/block combination
%            associated with this bar
%   idx  --  index associated with bar that references the
%            remoteMonitor 'bars' property array
%   starttime  --  Start time (clock()) can be assigned optionally
%   job  --  Matlab job object
%
%  PROPERTIES:
%     Parent - Parent (container) object
%     
%     Children - Cell array of Children objects, which is as follows:
%                 * prog_axes:        Axes containing progressbar
%                 * progname_label:   text "label"
%                 * progbar_rect:     rect that "grows" with progress
%                 * progpct_label:    text % as bar grows
%                 * progstatus_label: text status of task
%                 * progX_btn:        pushbutton uicontrol to cancel
%
%     UserData - Optional specified UserData that can be used for
%                indexing the task that is being tracked.
%
%  METHODS:
%     nigelProgress - Class constructor
   
   properties (Access = public, SetObservable = true)
      Color              % face color of the progress bar
      Position  double   % Position of "container" but updates graphics
      IsRemote  logical             % Flag indicating if bar is remote
      job
   end

   properties (SetAccess = private, GetAccess = public)
      Parent    matlab.ui.container.Panel     % Parent Panel object
      Children  cell                          % Array of Child objects
   end
   
   properties (Access = {?nigeLab.libs.remoteMonitor, ...
                         ?nigeLab.evt.jobCompleted, ...
                         ?nigeLab.evt.barStarted,...
                         ?nigeLab.evt.barStopped,...
                         ?nigeLab.evt.barCleared,...
                         ?nigeLab.libs.DashBoard}, SetObservable = true)
      
      BarIndex = nan                % Index of this bar in remoteMonitor
      Name      char                % Name of bar
      Progress  double              % From 0 to 100, progress of bar
      Status   = ''                 % Currently-displayed status
      Visible  char                 % 'on' or 'off'
   end
   
   properties (Access = {?nigeLab.libs.remoteMonitor, ...
                         ?nigeLab.evt.jobCompleted, ...
                         ?nigeLab.evt.barStarted,...
                         ?nigeLab.evt.barStopped,...
                         ?nigeLab.evt.barCleared,...
                         ?nigeLab.libs.DashBoard})
      BlockSelectionIndex  double   % Index of the [animal block]
      IsComplete    =      false    % Flag indicating completion status
      Timer                timer    % Timer running "remote" monitor
   end
   
   properties (Access = public, Hidden = true)
      starttime
   end
   
   properties (Access = private)
      Tank        nigeLab.Tank           % Tank "parent"
      Block       nigeLab.Block          % Block associated with this bar
      Monitor     nigeLab.libs.remoteMonitor    % Monitor "parent"
      TagDelim       char   % Delimiter for parsing status from job tag
      NotifyTimer    double % Interval (sec) for checking tag
      CompleteKey    char   % Keyword for "JOB DONE" state
      listeners   event.listener  % Event listener handle array
      joblistener event.listener  % Specific listener for job deletion
   end
   
   events
      StateChanged  % Issue eventdata for 'Start' or 'Stop' Type events
   end
   
   methods (Access = {?nigeLab.libs.remoteMonitor, ...
                      ?nigeLab.libs.DashBoard,...
                      ?parallel.job.MJSCommunicatingJob})
      % Class constructor for NIGELPROGRESS class
      function bar = nigelProgress(parent,name,sel,monitorObj)
         % NIGELPROGRESS    Create a bar allowing graphical tracking of
         %                  completion status via the bar progress.
         %
         %   bar = nigeLab.libs.nigelProgress('barName',jobObj,UserData);
         %
         %   bar  --  output handle to nigeLab.libs.nigelProgress object
         %
         %   parent -- parent container
         %   name  --  char array that is descriptor of thing to monitor
         %   sel  --  index referencing the animal/block combination
         %            associated with this bar
         %
         %  bar = nigeLab.libs.nigelProgress(5);
         %  --> Return an empty column array of 5 nigelProgres bars
         
         %% Check input
         if nargin < 1
            bar = repmat(bar,0);
            return;
         end
         
         if nargin == 1
            if isnumeric(parent)
               dims = parent;
               if isscalar(dims)
                  dims = [dims, 1];
               end
               bar = repmat(bar,dims);
               return;
            elseif isa(parent,'nigeLab.libs.nigelPanel')
               parent = parent.Panel;
            end
         end
         
         %% Assign basic properties
         bar.Name = name;
         bar.Parent = parent;
         bar.Position = parent.Position;
         bar.BlockSelectionIndex = sel;
         bar.Tank = monitorObj.tankObj;
         bar.Block = bar.Tank{sel(1,1),sel(1,2)};
         bar.Monitor = monitorObj;
         
         if ~isfield(bar.Tank.Pars,'Notifications')
            bar.Tank.updateParams('Notifications');
         elseif ~isfield(bar.Tank.Pars.Notifications,'TagDelim') || ...
                ~isfield(bar.Tank.Pars.Notifications,'NotifyTimer') || ...
                ~isfield(bar.Tank.Pars.Notifications,'CompleteKey')
            bar.Tank.updateParams('Notifications');
         end
         bar.TagDelim = bar.Tank.Pars.Notifications.TagDelim;
         bar.NotifyTimer = bar.Tank.Pars.Notifications.NotifyTimer;
         bar.CompleteKey = bar.Tank.Pars.Notifications.CompleteKey;
         
         %% Build Children graphics
         bar.Children = cell(7,1);
         bar.Children{1} = axes(bar.Parent, ...
            'Units','Normalized',...
            'Position', [0.025 0.025 0.900 0.950], ...
            'XLimMode','manual',...
            'XLim', [-0.1 1.0], ...
            'YLimMode','manual',...
            'YLim', [0 1], ...
            'Box', 'off', ...
            'ytick', [], ...
            'xtick', [],...
            'NextPlot','add',...
            'Tag','prog_axes',...
            'Color','none',...
            'XColor','none',...
            'YColor','none');
         
         bar.Children{7} = rectangle(bar.Children{1},...
            'Position',[-0.1 0 0.125 1],...
            'Curvature',[0.2 0.5],...
            'FaceColor',nigeLab.defaults.nigelColors('primary'),...
            'EdgeColor','none',...
            'Tag','progbar_anchor');

         bar.Children{3} = rectangle(bar.Children{1}, ...
            'Position', [0   0   1   1  ], ...
            'Curvature',[0.0 0.0],...
            'FaceColor',nigeLab.defaults.nigelColors('primary'),...
            'EdgeColor','none',...
            'Tag','progbar_rect');
         
         bar.Children{2} = text(bar.Children{1},...
            0.05, 0.5, name, ...
            'HorizontalAlignment', 'Left', ...
            'VerticalAlignment','middle',...
            'FontUnits', 'Normalized', ...
            'FontSize', 0.7,...
            'Color',nigeLab.defaults.nigelColors('onsurface'),...
            'FontName','Droid Sans',...
            'FontWeight','bold',...
            'BackgroundColor','none',...
            'Tag','progname_label');
         
         bar.Children{4} = text(bar.Children{1},...
            0.985, 0.5, '0%', ...
            'HorizontalAlignment', 'Right', ...
            'VerticalAlignment','middle',...
            'FontUnits', 'Normalized', ...
            'FontSize', 0.7,...
            'FontWeight','bold',...
            'FontName','Droid Sans',...
            'BackgroundColor','none',...
            'Color',nigeLab.defaults.nigelColors('onprimary'),...
            'Tag','progpct_label');
         
         bar.Children{5} = text(bar.Children{1},...
            0.80, 0.5, '', ...
            'HorizontalAlignment', 'Right', ...
            'VerticalAlignment','middle',...
            'FontUnits', 'Normalized', ...
            'FontSize', 0.7,...
            'FontWeight','bold',...
            'FontName','Droid Sans',...
            'BackgroundColor','none',...
            'Color',nigeLab.defaults.nigelColors('med_grey'),...
            'Tag','progstatus_label');
         
         %%%% Design and plot the cancel button
         % It goes on bar.Parent instead of on the axes object         
         bar.Children{6} = uicontrol(bar.Parent,...
            'Style','pushbutton',...
            'Units','Normalized',...
            'Position', [0.925 0.025 0.050 0.950],...
            'BackgroundColor',nigeLab.defaults.nigelColors(0.1),...
            'ForegroundColor',nigeLab.defaults.nigelColors(3),...
            'String','X',...
            'Tag','progX_btn',...
            'UserData',bar);
         
         %% Add property listeners
         bar.listeners = addPropertyListeners(bar);
         bar.job = [];
         
         %% Add Timer
         bar.Timer = timer(...
            'Name',sprintf('timer_A%02g_B%02g',sel(1),sel(2)),...
            'Period',bar.NotifyTimer,...
            'ExecutionMode','fixedSpacing',...
            'UserData',sel,...
            'TimerFcn',@(~,~)bar.updateBar);
         
         %% Add 'Cancel' callback
         setChild(bar,'X','Callback',@(~,~)bar.clearBar);
      end
      
      % Listener callback for red 'X'
      function clearBar(bar)
         %CLEARBAR  Listener callback for clicking red cancel 'X'
         %
         %  x.Callback = @(~,~)bar.clearBar;
         
         stopBar(bar);
         evt = nigeLab.evt.barCleared(bar);
         notify(bar,'StateChanged',evt);
         if bar.IsRemote
            if ~isempty(bar.job)
               if isvalid(bar.job)
                  cancel(bar.job);
                  delete(bar.job);
                  bar.job = [];
               end
            end
         end
      end
      
      % Things to do on delete function
      function delete(bar)
         % DELETE  Additional things to delete when 'delete' is called
         
         delete(bar.Parent);
         % If the job is valid to delete, then do so
         if ~isempty(bar.job)
            if isvalid(bar.job)
               cancel(bar.job);
               delete(bar.job);
            end
         end
         
         % Delete listener handles
         if ~isempty(bar.listeners)
            for lh = bar.listeners
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
         
         % Delete other (specific) job listener
         if ~isempty(bar.joblistener)
            if isvalid(bar.joblistener)
               delete(bar.joblistener);
            end
         end
         
         % Delete Timer object
         if ~isempty(bar.Timer)
            if isvalid(bar.Timer)
               delete(bar.Timer)
            end
         end
         
      end
      
      % Returns bar based on sel from list of monitorObj bars
      function bar = getBar(barArray,sel)
         % GETBAR  Returns a single bar object based on selection from list
         %         array barArray. References the 'BlockSelectionIndex'
         %         property.
         %
         %  bar = getBar(barArray,sel);
         %
         %  sel  --  [1 x 2] array [animalIndex blockIndex]
         
         for bar = barArray
            if all(bar.BlockSelectionIndex == sel)
               return;
            end
         end
         
         % If outside loop, returns empty
         bar = [];
         
      end
      
      % Return child object based on tag
      function h = getChild(bar,tag,propName)
         % GETCHILD  Return child object based on tag
         %
         %  h = bar.getChild('tag');
         %
         %  tag  --  char array. can be
         %           * prog_axes:        Axes containing progressbar
         %           * progname_label:   text "label"
         %           * progbar_rect:     rectangle "grows" with progress
         %           * progpct_label:    text % as bar grows
         %           * progstatus_label: text status of task
         %           * progX_btn:        pushbutton uicontrol to cancel
         %           * progbar_anchor:   curved rectangle "anchor"
         
         switch lower(tag)
            case {'progbar_axes','prog_axes','axes','a','ax','prog','container'}
               h = bar.Children{1};
            case {'progbar_name','name','progname_label','progname'}
               h = bar.Children{2};
            case {'progbar_x','progx_btn','btn','x','xbtn'}
               h = bar.Children{6};
            case {'progbar_status','status','progstatus_label','progstatus'}
               h = bar.Children{5};
            case {'progbar_rect','rect','progrect','patch',...
                  'progbar','bar','progress','progbar_patch'}
               h = bar.Children{3};
            case {'progbar_label','progpct_label','pct','progpct'}
               h = bar.Children{4};
            case {'progbar_anchor','anchor','proganchor'}
               h = bar.Children{7};
            otherwise
               error(['nigeLab:' mfilename ':BadChildTag'],...
                  'Could not find Child object for tag: %s',tag);
         end
         
         % If value is requested, return that instead
         if nargin > 2
            if isprop(h,propName)
               h = h.(propName);
            else
               error(['nigeLab:' mfilename ':BadPropertyName'],...
                  'Could not find Property (%s) for %s Child Object.',...
                  propName,tag);
            end
         end
      end
      
      % Private function that is issued when the bar associated with this
      % job reaches 100% completion
      function indicateCompletion(bar)
         % INDICATECOMPLETION  Callback to issue completion sound for the
         %               completed task of NIGELBAROBJ, once a particular
         %               bar has reached 100%.
         %
         %   bar.indicateCompletion();
         %
         %  bar  --  nigeLab.libs.nigelProgress "progress bar" object
         
         stopBar(bar); % Make sure it is stopped
         
         % Should only do these things if .IsComplete flag is true
         if bar.IsComplete
            % Play the bell sound! Yay!
            bar.setState(100,bar.CompleteKey);
            nigeLab.sounds.play('bell',1.5);
            if bar.IsRemote
               sel = bar.BlockSelectionIndex;
               b = bar.Tank{sel(1,1),sel(1,2)};
               b.reload(); % Reload the block so it is linked properly
               evt = nigeLab.evt.jobCompleted(bar);
               notify(bar.Monitor,'JobCompleted',evt);
               bar.job = [];
            end
         else
            % I hate this sound! Boo! You should also hate it!
            nigeLab.sounds.play('alert',3);
            bar.setState(bar.Progress,'Interrupted');

            bar.job = [];
            bar.Color = 'r';
         end
      end 
      
      % Overloaded minus function to change indexing
      function C = minus(A,B)
         % MINUS  Overloaded minus function to change indexing
         %
         %  barArray - bar;  Sets bar BarIndex to NaN and subtracts 1 from
         %                   all other BarIndex of other elements.
         
         % Only apply this if both are nigelProgress objects
         if ~isa(A,'nigeLab.libs.nigelProgress') || ...
               ~isa(B,'nigeLab.libs.nigelProgress')
            C = builtin('minus',A,B);
            return;
         end
         
         cur = B.BarIndex;
         for barObj = A
            if barObj.BarIndex > cur
               barObj.BarIndex = barObj.BarIndex - 1;
            elseif barObj.BarIndex == cur
               barObj.BarIndex = nan;
            end
         end
         C = A;
      end
      
      % Callback to get current state of bar (progress, status)
      function getState(bar,~,evt)
         % GETSTATE  Callback for getting current state of bar         
         curStatus = evt.status;
         curProgress = evt.progress;
         bar.setState(curProgress,curStatus);
      end
      
      % Set child object property based on tag
      function h = setChild(bar,tag,varargin)
         % SETCHILD  Set property of child object based on tag
         %
         %  bar.setChild('tag','propName1',propVal1,...);
         %
         %  tag  --  char array. can be
         %           * prog_axes:        Axes containing progressbar
         %           * progname_label:   text "label"
         %           * progbar_rect:     rectangle "grows" with progress
         %           * progpct_label:    text % as bar grows
         %           * progstatus_label: text status of task
         %           * progX_btn:        pushbutton uicontrol to cancel
         %           * progbar_anchor:   curved rectangle progress "anchor"
         
         switch lower(tag)
            case {'progbar_axes','prog_axes','axes',...
                  'a','ax','prog','container'}
               h = bar.Children{1};
            case {'progbar_name','name','progname_label','progname'}
               h = bar.Children{2};
            case {'progbar_x','progx_btn','btn','x','xbtn'}
               h = bar.Children{6};
            case {'progbar_status','status',...
                  'progstatus_label','progstatus'}
               h = bar.Children{5};
            case {'progbar_rect','rect','progrect','patch',...
                  'progbar','bar','progbar_patch'}
               h = bar.Children{3};
            case {'progbar_pct','progpct_label','pct','progpct'}
               h = bar.Children{4};
            case {'progbar_anchor','anchor','proganchor'}
               h = bar.Children{7};
            otherwise
               error(['nigeLab:' mfilename ':BadChildTag'],...
                  'Could not find Child object for tag: %s',tag);
         end
         for iV = 1:2:numel(varargin)
            if isprop(h,varargin{iV})
               h.(varargin{iV}) = varargin{iV+1};
            else
               error(['nigeLab:' mfilename ':BadPropertyName'],...
                  'Could not find Property (%s) for %s Child Object.',...
                  varargin{iV},tag);
            end
         end
      end
      
      % Set current state of the bar
      function setState(bar,curProgress,curStatus)
         % SETSTATE  Sets the current state of the bar
         %
         %  bar.setState(curProgress, curStatus);
         %
         %  curProgress - Progress [0 to 100] updates .Progress
         %  curStatus - Status (char array) updates .Status
         
         bar.Progress = curProgress;
         if nargin > 2
            bar.Status = curStatus;
         end
      end
      
      % Start the timer running on bar and notify event
      function startBar(bar)
         %STARTBAR  Start timer running on bar and notify event
         %
         %  bar.startBar(); Passes 'barStarted' evt via 'BarStarted' notify
         
         bar.IsComplete = false; % May need to reset if already ran
         if strcmp(bar.Timer.Running,'off')
            start(bar.Timer);
         else
            return; % Was already running, don't do other stuff
         end
         bar.setChild('progbar_rect','Curvature',[0 0]);
         bar.setChild('progbar_anchor',...
            'Position',[-0.1 0 0.125 1]);
         drawnow;
         evt = nigeLab.evt.barStarted(bar);
         notify(bar,'StateChanged',evt);
      end
      
      % Stop the timer running on bar and notify event
      function stopBar(bar)
         %STOPBAR  Stop timer running on bar and notify event
         %
         %  bar.stopBar(); Passes 'barStopped' evt via 'BarStopped' notify
         
         if strcmp(bar.Timer.Running,'on')
            stop(bar.Timer);
         else
            return; % Was already off, don't do the other stuff
         end

         evt = nigeLab.evt.barStopped(bar);
         notify(bar,'StateChanged',evt);
         if bar.IsRemote
            % From remote, job.FinishedFcn is bar.indicateCompletion();
            % So, just need .IsComplete to accurately reflect state of bar
            switch lower(bar.job.State)
               case 'finished'
                  if bar.Progress == 100
                     bar.IsComplete = true;
                  else
                     bar.IsComplete = false;
                  end
               case 'failed'
                  bar.IsComplete = false;
               otherwise
                  bar.IsComplete = false;
            end
         end
      end
      
      % Updates the progress bar with current job status
      function updateBar(bar)
         % UPDATEREBAR  Update the bar to reflect status of current job
         %
         %  monitorObj.updateRemoteMonitor();  
         %
         %  --> This method should be periodically "pinged" by the TimerFcn
         %      so that the state of the remote job can be updated.

         if ~bar.IsRemote
            str = bar.getChild('status','String');
            if strcmpi(str,bar.CompleteKey)
               pct = 100;
            else
               return;
            end
         else
            [pct,str] = nigeLab.utils.jobTag2Pct(bar.job,bar.TagDelim);
         end
         % Redraw the patch that colors in the progressbar
         bar.setState(pct,str);
         % If the job is completed, then run the completion method
         if bar.IsRemote
            if strcmpi(str,bar.CompleteKey)
               % If on remote, wait for job to finish--it will do indicator
               bar.stopBar();
               if pct >= 100
                  bar.IsComplete = true;
               else
                  bar.IsComplete = false;
               end
            end
         else
            % Otherwise just wait until it hits 100% to indicate complete
            if pct >= 100
               bar.IsComplete = true;
               bar.indicateCompletion();
               bar.stopBar();
            end
         end

      end
   end
   
   methods (Access = private)
      % Internal function to add property listeners to bar on init
      function lh = addPropertyListeners(bar)
         % ADDPROPERTYLISTENERS  Add array of property listeners that
         %                       listen for 'PostSet' events of 'job' (to
         %                       identify whether this is local or remote
         %                       job) and 'BarIndex' (to set the position
         %                       and visibility correctly) as well as
         %                       'Visible' (to update child graphic
         %                       visibility correctly) and 'IsRemote'
         %                       properties.
         %
         %  lh = addPropertyListeners(bar);  Returns array of listeners
         
         lh = addlistener(bar,'job','PostSet',@(~,~)bar.toggleIsRemote);
         lh = [lh, addlistener(bar,'BarIndex','PostSet',...
                          @(~,~)bar.setVisualQueuePosition)];
         lh = [lh, addlistener(bar,'Visible','PostSet',...
                        @(~,~)bar.toggleVisible)];
         lh = [lh, addlistener(bar,'IsRemote','PostSet',...
                        @(~,~)bar.toggleColor)];
         lh = [lh, addlistener(bar,'Position','PostSet',...
                        @(~,~)bar.updatePosition)];
         lh = [lh, addlistener(bar,'Color','PostSet',...
                        @(~,~)bar.updateColor)];
         lh = [lh, addlistener(bar,'Progress','PostSet',...
                        @(~,~)bar.updateProgress)];
         lh = [lh, addlistener(bar,'Status','PostSet',...
                        @(~,~)bar.updateStatus)];
         lh = [lh, addlistener(bar,'Name','PostSet',...
                        @(~,~)bar.updateName)];
      end

      % Internal function to deal with job being removed via Job Monitor
      function handleExternalJobDeletion(bar)
         %HANDLEEXTERNALJOBDELETION  If job is deleted from Job Monitor
         %
         %  bar.handleExternalJobDeletion;  Listener callback that waits
         %                                  for ObjectBeingDestroyed event
         
         bar.IsRemote = false;
         bar.IsComplete = false;
         bar.indicateCompletion();
      end
      
      % LISTENER CALLBACK: Update "visual" position in queue from index
      function setVisualQueuePosition(bar)
         % SETVISUALQUEUEPOSITION  Sets the position of bar depending on
         %                         its value of .BarIndex. If BarIndex is
         %                         NaN, then set Visible to 'off'
         
         if isnan(bar.BarIndex)
            bar.Visible = 'off';
            return;
         else
            bar.Visible = 'on';
            if bar.BarIndex == 1
               bar.starttime = clock(); % Start the clock if it is top
            end
         end
         
         h = bar.Position(4);
         y = bar.Position(2);
         offset = 0.005;
         yNew = 1 - (bar.BarIndex * (h + offset));
         bar.Position(2) = yNew;
         drawnow;
      end
      
      % LISTENER CALLBACK: Switches bar color depending on remote state
      function toggleColor(bar)
         % TOGGLECOLOR  Switches bar color depending on value of IsRemote
         %
         %  addlistener(bar,'IsRemote','PostSet',@(~,~)bar.toggleColor());
         
         if bar.IsRemote
            bar.Color = 'g';
         else
            bar.Color = 'b';
         end
         
      end
      
      % LISTENER CALLBACK: Switches remote depending on value of job
      function toggleIsRemote(bar)
         % TOGGLEISREMOTE  Changes remote status depending on job
         %
         %  addlistener(bar,'job','PostSet',@(~,~)bar.toggleIsRemote);
         
         if isempty(bar.job)
            bar.IsRemote = false;
            if ~isempty(bar.joblistener)
               if isvalid(bar.joblistener)
                  delete(bar.joblistener);
               end
            end
         else
            bar.IsRemote = true;
            bar.joblistener = addlistener(bar.job,'ObjectBeingDestroyed',...
               @(~,~)bar.handleExternalJobDeletion);
         end
      end
      
      % LISTENER CALLBACK: Toggle visibilty of all child objects
      function toggleVisible(bar)
         % TOGGLEVISIBLE  Toggle visibility of all child objects
         %
         %  addlistener(bar,'Visible','PostSet',@(~,~)bar.toggleVisible());
         
         ax = bar.getChild('ax');
         ax.Visible = bar.Visible;
         set(ax.Children,'Visible',bar.Visible);
         bar.Parent.Visible = bar.Visible;
         switch lower(bar.Visible)
            case 'on'
               jObj = nigeLab.utils.findjobj(getChild(bar,'progbar_x'));
               jObj.setBorder(javax.swing.BorderFactory.createEmptyBorder());
               jObj.setBorderPainted(false);
            case 'off'
               % nothing specific
         end
      end
      
      % LISTENER CALLBACK: Update the face color of bar based on Color prop
      function updateColor(bar)
         % UPDATECOLOR  Updates face color of progress bar when 'Color'
         %              property is changed.
         %
         %  addlistener(bar,'Color','PostSet',@(~,~)bar.updateColor);
         
         if ischar(bar.Color)
            bar.Color = nigeLab.defaults.nigelColors(bar.Color);
         end
         
         bar.setChild('progbar_rect','FaceColor',bar.Color);
         bar.setChild('progbar_anchor','FaceColor',bar.Color);
      end
      
      % LISTENER CALLBACK: Update parent panel position from Position prop
      function updatePosition(bar)
         % UPDATEPOSITION  Updates the parent panel position when
         %                 'Position' property is changed.
         %
         %  addlistener(bar,'Position','PostSet',@(~,~)bar.updatePosition);
         
         bar.Parent.Position = bar.Position;
      end
      
      % LISTENER CALLBACK: Update bar graphics when 'Name' is changed
      function updateName(bar)
         % UPDATENAME  Update bar graphics when 'Name' property is changed
         %
         %  addlistener(bar,'Name','PostSet',@(~,~)bar.updateName);
         
         bar.setChild('name','String',bar.Name);
      end
      
      % LISTENER CALLBACK: Update bar whenever progress is changed
      function updateProgress(bar)
         % UPDATEPROGRESS  Update bar graphic when 'Progress' property
         %                 changes.
         %  
         %  addlistener(bar,'Progress','PostSet',@(~,~)bar.updateProgress);
         
         pct = bar.Progress;

         % Compute how far the bar should be filled based on the percent
         % completion, assuming start position is 0 and end is 1.
         xStop = pct/100;
         if isnan(xStop)
            xStop = 0;
         end
         bar.setChild('progbar_rect','Position',[0, 0, xStop, 1]);
         bar.setChild('progbar_anchor','Position',[-0.1 0 0.125+0.175*xStop 1]);
         bar.setChild('progbar_pct','String',sprintf('%.3g%%',pct));
         bar.setChild('progbar_rect','Curvature',[0.05*xStop 0.5*xStop]);
         drawnow;
         
         bar.IsComplete = pct >= 100;
      end

      % LISTENER CALLBACK: Update bar status string when prop is changed
      function updateStatus(bar)
         % UPDATESTATUS  Update status graphic string when 'Status'
         %               property is changed
         %
         %  addlistener(bar,'Status','PostSet',@(~,~)bar.updateStatus);
         
         str = bar.Status;         
         bar.setChild('status','String',str);
         drawnow;
         
         switch lower(strrep(str,'.',''))
            case {'done','complete','finished','over'}
               % Ensure that it is at 100%
               bar.setState(100,bar.CompleteKey);
            otherwise
               % Do nothing
         end
      end
      
   end
   
   
end