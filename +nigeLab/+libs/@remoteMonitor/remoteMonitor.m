classdef remoteMonitor < handle
   %REMOTEMONITOR  Class to monitor changes in remote jobs and issue an
   %               event ('jobCompleted') whenever the job reaches its
   %               'Complete
   %
   %  monitorObj = nigeLab.libs.remoteMonitor();  Goes in current figure
   %  monitorObj = nigeLab.libs.remoteMonitor(nigelPanelObj);
   %
   %  nigelPanelObj  --  A uipanel, nigeLab.libs.nigelPanel, or figure
   
   properties
      qPanel   nigeLab.libs.nigelPanel     % Graphics container for "queue" panel
      bars     nigeLab.libs.nigelProgress  % "progress" bars
      listeners  event.listener  % Array of listener handles
   end
   
   properties (Access = private)
      runningJobs = 0         % Number of running jobs
      progtimer   timer       % Timer for checking progress periodically
      pars        struct      % Parameters struct
      delim       char        % Delimiter for parsing job tags
   end
   
   events
      jobCompleted  % Event issued when progress bar hits 100%
   end
   
   methods (Access = ?nigeLab.libs.DashBoard)
      % Class constructor for nigeLab.libs.remoteMonitor object handle
      function monitorObj = remoteMonitor(tankObj,nigelPanelObj)
         %REMOTEMONITOR  Class to monitor changes in remote jobs and issue 
         %               an event ('jobCompleted') whenever the job reaches
         %               its 'Complete' state (parallel.Task.State ==
         %               'Complete')
         %
         %  monitorObj = nigeLab.libs.remoteMonitor(nigelPanelObj);
         %
         %  tankObj  --  nigeLab.Tank object to monitor
         %  nigelPanelObj -- A uipanel, nigeLab.libs.nigelPanel, or 
         %                   figure handle
         
         if nargin < 2
            nigelPanelObj = gcf;
         end
         
         % Handle different input classes
         if isa(nigelPanelObj,'nigeLab.libs.nigelPanel') % nigelPanel
            monitorObj.qPanel = nigelPanelObj;
            
         elseif isa(nigelPanelObj,'matlab.ui.container.Panel') % uipanel
            p=nigeLab.libs.nigelPanel(nigelPanelObj,...
               'String','Remote Monitor',...
               'Tag','monitor','Position',[0 0 1 1],...
               'PanelColor',nigeLab.defaults.nigelColors('surface'),...
               'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
               'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
            monitorObj.qPanel = p;
            
         elseif isa(nigelPanelObj,'matlab.ui.Figure') % Figure
            p=nigeLab.libs.nigelPanel(nigelPanelObj,...
               'String','Remote Monitor',...
               'Tag','monitor','Position',[0 0 1 1],...
               'PanelColor',nigeLab.defaults.nigelColors('surface'),...
               'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
               'TitleColor',nigeLab.defaults.nigelColors('onprimary'));
            monitorObj.qPanel = p;
            
         else
            error(['nigeLab:' mfilename ':badInputType2'],...
               ['Input nigelPanelObj needs to be one of:\n',...
                '--> matlab.ui.figure\n', ...
                '--> matlab.ui.container.Panel\n' ...
                '--> nigeLab.libs.nigelPanel\n'
                '(currently: %s)'],class(nigelPanelObj));
         end
         
         % Define figure size and axes padding for the single bar case
         monitorObj.pars = tankObj.Pars.Notifications;
         monitorObj.delim = monitorObj.pars.TagDelim;
         monitorObj.progtimer = timer(...
            'Name',sprintf('%s_timer','remoteMonitor'),...
            'Period',monitorObj.pars.NotifyTimer,...
            'ExecutionMode','fixedSpacing',...
            'TimerFcn',@(~,~)monitorObj.updateRemoteMonitor);

         monitorObj.bars = nigeLab.libs.nigelProgress(0);
         
         for iA = 1:numel(tankObj.Animals)
            a = tankObj.Animals(iA);
            for iB = 1:numel(a.Blocks)
               b = a.Blocks(iB);
               monitorObj.bars = [monitorObj.bars, ...
                  monitorObj.addBar(b,[iA,iB])];
            end
         end
      end

      % Destroy timers when object is deleted
      function delete(monitorObj)
         % DELETE  Destroy the object and its timers
         %
         %  monitorObj.delete;
         
         % Delete the timer
         if ~isempty(monitorObj.progtimer)
            if isvalid(monitorObj.progtimer)
               stop(monitorObj.progtimer);
               delete(monitorObj.progtimer);
            end
         end
         
         % Delete all bars
         if ~isempty(monitorObj.bars)
            for bar = monitorObj.bars
               if isvalid(bar)
                  delete(bar);
               end
            end
         end
         
         % Delete all associated listeners
         if ~isempty(monitorObj.listeners)
            for lh = monitorObj.listeners
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
         
      end
      
      % Returns bar based on sel from list of monitorObj bars
      function bar = getBar(monitorObj,sel)
         % GETBAR  Returns a single bar object based on selection from list
         %           of  monitorObj bars.
         
         bar = getBar(monitorObj.bars,sel);
      end

      % Starts the bar based on some input selection index
      function bar = startBar(monitorObj,name,sel,job)
         % STARTBAR  Starts the bar based on some input selection index and
         %           assigns a job as well. 
         %
         %  Returns a handle to the bar object
         %
         %  bar = monitorObj.startBar('barName',[3 2],job);
         %  --> Returns the bar corresponding to 2nd block of 3rd animal
         %  --> "Starts" the TimerFcn for that Bar
         %
         %  monitorObj.startBar('barName',bar,job);
         %  --> Passes the bar to start directly to the method.
         
         if nargin < 4
            job = [];
         end
         
         switch class(sel)
            case 'nigeLab.libs.nigelProgress'
               bar = sel; % Can be passed directly
            otherwise
               if isnumeric(sel)
                  bar = monitorObj.getBar(sel);
               else
                  error(['nigeLab:' mfilename ':BadInputType2'],...
                     'Unexpected class for ''sel'' input: %s',...
                     class(sel));
               end
         end

         % Increment counter of running jobs
         monitorObj.runningJobs = monitorObj.runningJobs + 1;
         bar.Progress = 0;
         bar.Name = name;
         bar.job = job;
         bar.BarIndex = monitorObj.runningJobs;
         
         jObj = nigeLab.utils.findjobj(getChild(bar,'X'));
         jObj.setBorder(javax.swing.BorderFactory.createEmptyBorder());
         jObj.setBorderPainted(false);
         
         %%% if first bar we need to start timer
         if strcmp(monitorObj.progtimer.Running,'off')
            start(monitorObj.progtimer);
         end
         
      end
      
      % Remove a nigeLab.libs.nigelProgress object from visual queue.
      % Acts as the opposite of "STARTBAR" method.
      function stopBar(monitorObj,bar,evt)
         % STOPBAR  function to remove a nigeLab.libs.nigelProgress bar
         %            Acts as the opposite of "STARTBAR" method.
         %
         %  monitorObj.removeBar(nigelProgressObj);
         %
         %  bar  -- nigeLab.libs.nigelProgress "progress bar" to remove
         
         if nargin < 3
            evt = [];
         end
         
         % If it came from listener callback, then it was a child of
         % nigelProgressBarObj.
         if ~isa(bar,'nigeLab.libs.nigelProgress')
            bar = bar.UserData;
         end
         
         if strcmp(monitorObj.progtimer.Running,'on')
            stop(monitorObj.progtimer); % to prevent graphical updates errors
         end
         
         % If this was from clicking red 'X', it means the method was
         % canceled in the middle.
         if ~isempty(evt)
            % Then it was listener callback so cancel
            notify(bar,'JobCanceled');
         end
         
         % Decrement the appropriate .BarIndex property:
         monitorObj.bars = monitorObj.bars - bar;
         
         % Reduce number of running jobs and if there are still jobs
         % running, start the timer again
         monitorObj.runningJobs = monitorObj.runningJobs - 1;
         monitorObj.barCompleted(bar);
         
         % Restart the progress timer if there are still bars
         if monitorObj.runningJobs > 0
            if strcmp(monitorObj.progTimer.Running,'off')
               start(monitorObj.progtimer);
            end
         end
      end
         
      % Updates the remote monitor with current job status
      function updateRemoteMonitor(monitorObj)
         % UPDATEREMOTEMONITOR  Update the remote monitor with current job
         %                      status
         %
         %  monitorObj.updateRemoteMonitor();  
         %
         %  --> This method should be periodically "pinged" by the TimerFcn
         %      so that the state of the remote job can be updated.
         
         for bar = monitorObj.bars
            if ~bar.IsRemote
               if strcmpi(bar.getChild('status','String'),'Done.')
                  pct = 100;
               else
                  return;
               end
            else
               pct = nigeLab.utils.jobTag2Pct(bar.job,monitorObj.delim);
            end
            % Redraw the patch that colors in the progressbar
            bar.setState(pct);
            
            % If the job is completed, then run the completion method
            if pct == 100
               monitorObj.barCompleted(bar);
            end
            
         end

      end
   end
   
   methods (Access = {?nigeLab.libs.DashBoard,?nigeLab.libs.nigelProgress})
      % Private function that is issued when the bar associated with this
      % job reaches 100% completion
      function barCompleted(monitorObj,bar)
         % BARCOMPLETED  Callback to issue completion sound for the
         %               completed task of NIGELBAROBJ, once a particular
         %               bar has reached 100%.
         %
         %   monitorObj.barCompleted(bar);
         %
         %  bar  --  nigeLab.libs.nigelProgress "progress bar" object
         
         % Play the bell sound! Yay!
         nigeLab.sounds.play('bell',1.5);
         evtData = nigeLab.evt.jobCompletedEventData(bar);
         if bar.IsComplete
            bar.setState(100,'Done.');
         end
         notify(monitorObj,'jobCompleted',evtData);
      end      

   end
   
   % Private methods accessed internally
   methods (Access = private)
      % Adds a nigeLab.libs.nigelBar progress bar that is used in
      % combination with the remoteMonitor to track processing status
      function bar = addBar(monitorObj,blockObj,sel)
         % ADDBAR  Add a "bar" to the remoteMonitor object, allowing the
         %         remoteMonitor to track completion status via the "bar"
         %         progress.
         %
         %   bar = monitorObj.addBar('barName',sel);
         %
         %   bar  --  output handle to nigeLab.libs.nigelBar object
         %
         %   monitorObj  --  nigeLab.libs.remoteMonitor object
         %   name  --  char array that is descriptor of job to monitor
         %   sel  --  [1 x 2] index referenced by tankObj{[animal,block]}
         %   starttime  --  Current time (as returned by clock() for
         %                    format)
         %   job  --  Matlab job object

         %%%% get bar name
         if isfield(blockObj.Meta,'AnimalID') && isfield(blockObj.Meta,'RecID')
            blockName = sprintf('%s.%s',...
               blockObj.Meta.AnimalID,...
               blockObj.Meta.RecID);
         else
            warning(['Missing AnimalID or RecID Meta fields. ' ...
               'Using Block.Name instead.']);
            blockName = strrep(blockObj.Name,'_','.');
         end
         name = blockName(1:min(end,...
            blockObj.Pars.Notifications.NMaxNameChars));

         %%%% enclose everything in a panel
         % this is convenient for stacking purposes
         pos = nigeLab.utils.getNormPixelDim(monitorObj.qPanel,...
                  [-inf -inf 50 20],...
                  [0.025, ...
                   0.8870, ...
                   0.875, ...
                   0.1125]);
         pp = uipanel(...
            'BackgroundColor',nigeLab.defaults.nigelColors(0.1),...
            'Units','Normalized',...
            'Position',pos,...
            'BorderType','none',...
            'Tag',name);

         % Create the actual nigelProgress bar object
         bar = nigeLab.libs.nigelProgress(pp,name,sel);
         setChild(bar,'X','Callback',...
            @monitorObj.stopBar);
         bar.BarIndex = nan;
         
         %%% Nest the panel in in the nigelPanel
         monitorObj.qPanel.nestObj(bar.Parent,...
            sprintf('ProgressBar_%s',name));
         
         %%% store the bars in the remoteMonitor obj
         monitorObj.bars = [monitorObj.bars, bar];
         monitorObj.listeners = [monitorObj.listeners, ...
            addlistener(blockObj,'ProgressChanged',...
            @bar.getState)];
      end
      
   end
   
end

