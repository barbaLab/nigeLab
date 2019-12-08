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
   end
   
   properties (Access = private)
      progtimer   timer       % Timer for checking progress periodically
      pars        struct      % Parameters struct
   end
   
   events
      jobCompleted  % Event issued when progress bar hits 100%
   end
   
   methods (Access = public)
      % Class constructor for nigeLab.libs.remoteMonitor object handle
      function monitorObj = remoteMonitor(nigelPanelObj)
         %REMOTEMONITOR  Class to monitor changes in remote jobs and issue 
         %               an event ('jobCompleted') whenever the job reaches
         %               its 'Complete' state (parallel.Task.State ==
         %               'Complete')
         %
         %  monitorObj = nigeLab.libs.remoteMonitor(nigelPanelObj);
         %
         %  nigelPanelObj -- A uipanel, nigeLab.libs.nigelPanel, or 
         %                   figure handle
         
         if nargin < 1
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
         monitorObj.pars = nigeLab.defaults.Notifications();
         monitorObj.progtimer = timer(...
            'Name',sprintf('%s_timer','remoteMonitor'),...
            'Period',monitorObj.pars.NotifyTimer,...
            'ExecutionMode','fixedSpacing',...
            'TimerFcn',@(~,~)monitorObj.updateRemoteMonitor);

         monitorObj.bars = nigeLab.libs.nigelProgress(0);
      end
      
      % Adds a nigeLab.libs.nigelBar progress bar that is used in
      % combination with the remoteMonitor to track processing status
      function bar = addBar(monitorObj,name,job,UserData,starttime)
         % ADDBAR  Add a "bar" to the remoteMonitor object, allowing the
         %         remoteMonitor to track completion status via the "bar"
         %         progress.
         %
         %   bar = monitorObj.addBar('barName',jobObj,UserData);
         %
         %   bar  --  output handle to nigeLab.libs.nigelBar object
         %
         %   monitorObj  --  nigeLab.libs.remoteMonitor object
         %   name  --  char array that is descriptor of job to monitor
         %   job  --  Matlab job object
         %   UserData  --  Any data to associate with the bar
         %   starttime  --  Current time (as returned by clock() for
         %                    format)
      
         if nargin < 3
            job = [];
         end
         
         if nargin < 4
            UserData = [];
         end
         
         if nargin < 5
            starttime = clock();
         end
         
         % Get indexing to track this bar
         nBars = numel(monitorObj.bars);
         idx = nBars+1;

         %%%% enclose everything in a panel
         % this is convenient for stacking purposes
         pos = nigeLab.utils.getNormPixelDim(monitorObj.qPanel,...
                  [10 -inf 50 20],...
                  [0.05, ...
                  1 - (monitorObj.pars.FixedProgBarHeightNormUnits * idx), ...
                  0.85, ...
                  0.1125]);
         pp = uipanel(...
            'BackgroundColor',nigeLab.defaults.nigelColors(0.1),...
            'Units','Normalized',...
            'Position',pos,...
            'BorderType','none',...
            'Tag',name);

         % Create the actual nigelProgress bar object
         bar = nigeLab.libs.nigelProgress(pp,name,...
                           job,idx,UserData,starttime);
         setChild(bar,'X','Callback',@(~,~,bar)obj.deleteBar(bar));

         %%% Nest the panel in in the nigelPanel
         monitorObj.qPanel.nestObj(bar.Parent,...
            sprintf('ProgressBar_%02d',idx));
         
         %%% store the bars in the remoteMonitor obj
         monitorObj.bars(idx)=bar;
         
         % So fancy
         jObj = nigeLab.utils.findjobj(XButton);
         jObj.setBorder(javax.swing.BorderFactory.createEmptyBorder());
         jObj.setBorderPainted(false);
         
         %%% if first bar we need to start timer
         if strcmp(monitorObj.progtimer.Running,'off')
               start(monitorObj.progtimer);
         end
      end
      
      % Destroy timers when object is deleted
      function delete(obj)
         % DELETE  Destroy the object and its timers
         %
         %  obj.delete;
         
         stop(obj.progtimer);
         delete(obj.progtimer);
         delete(obj);
      end
      
      % "DELETE" function to remove a nigeLab.libs.nigelProgress object.
      % Acts as the opposite of "ADDBAR" method.
      function deleteBar(monitorObj,nigelProgressObj)
         % DELETEBAR  function to remove a nigeLab.libs.nigelProgress bar
         %            Acts as the opposite of "ADDBAR" method.
         %
         %  monitorObj.deleteBar(nigelProgressObj);
         %
         %  nigelProgressObj  --  "bar" to remove
         
         stop(monitorObj.progtimer); % to prevent graphical updates errors
         
         ind =  getChild(nigelProgressObj,'ax','UserData');
         
         % This also deletes the container (panel), which subsequently
         % deletes all Child graphics in the panel
         delete(nigelProgressObj);
         
         % "Bump" the lower bars "up" so they are in correct position
         for jj=ind+1:numel(monitorObj.bars)
            monitorObj.bars(jj).setChild('axes','UserData',jj-1);
            y = monitorObj.bars(jj).Position(2);
            y = y + monitorObj.pars.FixedProgBarHeightNormUnits;
            monitorObj.bars(jj).Position = pos;
         end
         
         % If the job is valid to delete, then do so
         if isa(nigelProgressObj.job,'parallel.Task') || ...
               isa(nigelProgressObj.job,'parallel.Job')
            if ~isempty(nigelProgressObj.job)
               cancel(nigelProgressObj.job);
               delete(nigelProgressObj.job);
            end
         end
         
         % Remove this bar from the "pointer" bars property of
         % remoteMonitor object
         monitorObj.bars(ind) = [];
         
         if numel(monitorObj.bars) > 0
            start(monitorObj.progtimer);
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
         
         for ii=1:numel(monitorObj.bars)
            bar = monitorObj.bars(ii);
            if isempty(bar.job)
               if strcmp(bar.getChild('status','String'),'Done.')
                  pct = 100;
               else
                  pct = nan;
               end
            else
               pct = nigeLab.utils.jobTag2Pct(bar.job);
            end
            % Get the offset of the progressbar from the left of the panel
            xStart = bar.progpatch.XData(1);
            
            % Compute how far the bar should be filled based on the percent
            % completion, accounting for offset from left of panel
            xStop = xStart + (1-xStart) * (pct/100);
            
            % Redraw the patch that colors in the progressbar
            bar.setChild('progbar','XData',[xStart, xStop, xStop, xStart]);
            bar.setChild('pct','String',sprintf('%.3g%%',pct));
            drawnow;
            
            % If the job is completed, then run the completion method
            if pct == 100
               monitorObj.barCompleted(bar);
            end
            
         end

      end

      
   end
   
   methods (Access = private)
      % Private function that is issued when the bar associated with this
      % job reaches 100% completion
      function barCompleted(monitorObj,nigelProgressObj)
         % BARCOMPLETED  Callback to issue completion sound for the
         %               completed task of NIGELBAROBJ, once a particular
         %               bar has reached 100%.
         %
         %   monitorObj.barCompleted(nigelBarObj);
         
         % Play the bell sound! Yay!
         nigeLab.sounds.play('bell',1.5);
         evtData = nigeLab.evt.jobCompletedEventData(nigelProgressObj);
         notify(monitorObj,'jobCompleted',evtData);
         monitorObj.updateStatus(nigelProgressObj,'Done.')
      end
      
      

   end
   
end

