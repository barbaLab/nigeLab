classdef remoteMonitor < handle
   %REMOTEMONITOR   Monitor changes in ongoing jobs and update visual cues
   %
   %  This class is an "intermediate" between any interface that uses the
   %  `nigeLab.libs.nigelProgress` progress bars and the actual queueing of
   %  the jobs that is tracked by the bars indicating job progress. When a
   %  given job is completed, it issues the `JobCompleted` event and
   %  associated `nigeLab.libs.jobCompleted` event.EventData so that the
   %  correct bar can be appropriately updated. It also makes sure that
   %  bars are correctly created and destroyed.
   %  
   %  REMOTEMONITOR Properties:
   %     qPanel  --  nigeLab.libs.nigelPanel (container for "queue" panel)
   %
   %     bars  -- nigeLab.libs.nigelProgress (array of "progress" bars)
   %
   %     listeners  --  event.listener  (array of listener handles)
   %
   %     runningJobs  --  Number of currently-running jobs
   %        * Used when "starting" a new bar to give it the correct
   %          position in the visual queue, or when a job is finished to
   %          make sure that jobs all "slide up" correctly if the bar is
   %          hidden by the user.
   %
   %     pars  --  Parameters struct
   %
   %     delim  --  Delimiter for parsing job tags (usually '||')
   %
   %     tankObj  --  Handle to `nigeLab.Tank` Tank object
   %
   %  REMOTEMONITOR Events:
   %     JobCompleted  --  Event issued when progress bar hits 100%
   %        Associated event.EventData class is `nigeLab.evt.jobCompleted`
   %
   %  REMOTEMONITOR Methods:
   %     remoteMonitor  -- Constructor for object to monitor progress bars
   %      >> monitorObj = nigeLab.libs.remoteMonitor();  
   %      >> monitorObj = nigeLab.libs.remoteMonitor(nigelPanelObj);
   
   properties
      qPanel   nigeLab.libs.nigelPanel     % Graphics container for "queue" panel
      bars     nigeLab.libs.nigelProgress  % "progress" bars
      listeners  event.listener  % Array of listener handles
   end
   
   properties (Access = ?nigeLab.libs.nigelProgress)
      runningJobs = 0         % Number of running jobs
      pars        struct      % Parameters struct
      delim       char        % Delimiter for parsing job tags
      tankObj     nigeLab.Tank  % Tank object
   end
   
   events
      JobCompleted  % Event issued when progress bar hits 100%
   end
   
   methods (Access = {?nigeLab.libs.DashBoard,?timer})
      % Class constructor for nigeLab.libs.remoteMonitor object handle
      function monitorObj = remoteMonitor(tankObj,nigelPanelObj)
         %REMOTEMONITOR   Constructor for object to monitor progress bars
         %
         %  monitorObj = nigeLab.libs.remoteMonitor(nigelPanelObj);
         %
         %  tankObj  --  nigeLab.Tank object to monitor
         %  nigelPanelObj -- A uipanel, nigeLab.libs.nigelPanel, or 
         %                   figure handle
         
         if nargin < 2
            nigelPanelObj = gcf;
         end
         
         monitorObj.tankObj = tankObj;
         
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
         
         % Error check on multi-job submissions
         if ~isempty(bar.job)
            error(['nigeLab:' mfilename ':InvalidJobSubmission'],...
               'Cannot run multiple jobs for the same Block simultaneously.');
         end

         % Increment counter of running jobs
         bar.Progress = 0;
         bar.Name = name;
         bar.job = job;
         
         % Changing BarIndex toggles the visibility, queue position etc.
         bar.BarIndex = monitorObj.runningJobs+1;
         
         bar.startBar();
         
      end
         
   end

   methods (Access = {?nigeLab.libs.nigelProgress})
      % Handles different types of `StateChanged` events from
      % `nigeLab.libs.nigelProgress` progress bar class
      function barStateCB(monitorObj,src,evt)
         switch evt.Type
            case 'Start'
               % Increment the counter of running jobs
               monitorObj.runningJobs = monitorObj.runningJobs + 1;
               
            case 'Stop'
               % Reduce number of running jobs and if there are still jobs
               % running, start the timer again
               monitorObj.runningJobs = monitorObj.runningJobs - 1;
               
            case 'Clear'
               %% For example, when the red X is clicked or job destroyed
               % Decrement the appropriate .BarIndex property:
               monitorObj.bars = monitorObj.bars - src;
               
            otherwise
               error(['nigeLab:' mfilename ':UnrecognizedEvent'],...
                  'Unexpected event type: %s',evt.Type);
         end
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
                  [-inf -inf 50 15],... % -inf indicates no min constraint
                  [0.005, ... % Norm x-pos in panel
                   0.930, ... % Norm y-pos in panel (start)
                   0.925, ... % Norm total width in panel
                   0.065]);   % Norm height in panel
         pp = uipanel(...
            'BackgroundColor',nigeLab.defaults.nigelColors(0.1),...
            'Units','Normalized',...
            'Position',pos,...
            'BorderType','none',...
            'Tag',name);

         % Create the actual nigelProgress bar object
         bar = nigeLab.libs.nigelProgress(pp,name,sel,monitorObj);
         bar.BarIndex = nan;
         
         %%% Nest the panel in in the nigelPanel
         monitorObj.qPanel.nestObj(bar.Parent,...
            sprintf('ProgressBar_%s',name));
         
         %%% store the bars in the remoteMonitor obj
         monitorObj.bars = [monitorObj.bars, bar];
         monitorObj.listeners = [monitorObj.listeners, ...
            addlistener(blockObj,'ProgressChanged',@bar.getState),...
            addlistener(bar,'StateChanged',@monitorObj.barStateCB)];
      end
      
   end
   
end

