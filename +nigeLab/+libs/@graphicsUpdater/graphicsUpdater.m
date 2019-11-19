classdef graphicsUpdater < handle
   %% GRAPHICSUPDATER   Class to update video scoring UI on frame update
   
   
   properties (SetAccess = private, GetAccess = public)
      parent % figure handle
      
      % Keep track of time scalars
      tVid                 % Current video time
      tNeu                 % Current neural time (TDT recording)
      
      % Video properties
      videoFile_list       % 'dir' struct of videos
      videoFile            % VideoReader file object
      
      % 'graphics' arg fields from vidInfoObj
      animalName_display   % Text displaying animal name/recording
      neuTime_display      % Text displaying neural data time
      vidTime_display      % Text displaying video time
      image_display        % Graphics object for displaying current frame
      image_displayAx      % Axes container for image display
      vidSelect_listBox    % Video selection listbox
      hud_panel            % Panel for heads-up-display (HUD)
      
      % 'graphics' arg fields for alignInfoObj:
      vidTime_line         % Line indicating video time
      alignment_panel      % Panel containing graphics objs for alignment
      
      % 'graphics' arg fields for behaviorInfoObj:
      trialTracker_display          % Graphic for displaying trial progress
      trialTracker_displayOverlay   % Graphic for tracking current trial
      trialTracker_label            % Graphic label for progress tracking
      successTracker_label          % Graphic label for success tracking
      trialPopup_display            % Graphic for selecting current trial
      editArray_display             % Array of edit box display graphics
      
      
      % Information variables for video scoring:
      % State variables for updating the "progress tracker" for each trial
      varState               % False - variable not scored for this trial
      varName                % List of variables that may be updated
      curState = false;      % Current "state" of scoring (is it finished?)
      nTotal                 % Total number of trials
      vidOffset = 0;         % Video offset
      
      % Constant for alignment tracking:
      zoomOffset = 4; % Offset (sec)
      xLim            % Track x-limits for centering video tracking line
   end
   
   properties (SetAccess = immutable, GetAccess = private)
      verbose = false;
   end
   
   
   methods (Access = public)
      
      % Create the video information listener that updates other objects on
      % a frame change (to prevent copy/paste a lot of the same stuff into
      % many sub-functions of the scoreVideo main funciton)
      function obj = graphicsUpdater(vid_F,variable_names)
         % Get list of video files
         obj.videoFile_list = vid_F;
         
         % First variable is "trial" so its state is always "true"
         obj.varState = [true,false(1,numel(variable_names)-1)];
         obj.varName = variable_names;
         
      end
      
      function addListeners(obj,vidInfo_obj,varargin)
         % Define parent handle on constructor
         obj.parent = vidInfo_obj.parent;
         
         % Add listeners for event notifications from video object
         addlistener(vidInfo_obj,...
            'frameChanged',@obj.frameChangedVidCB);
         addlistener(vidInfo_obj,...
            'vidChanged',@obj.vidChangedVidCB);
         
         % Add listeners for event notifications from associated
         % information tracking object
         for iV = 1:numel(varargin)
            switch class(varargin{iV})
               case 'behaviorInfo'
                  addlistener(varargin{iV},...
                     'closeReq',@obj.closeCB);
                  addlistener(varargin{iV},...
                     'saveFile',@obj.saveFileCB);
                  addlistener(varargin{iV},...
                     'newTrial',@(o,e) obj.newTrialBehaviorCB(o,e,vidInfo_obj));
                  addlistener(varargin{iV},...
                     'update',@obj.updateBehaviorCB);
                  addlistener(varargin{iV},...
                     'countIsZero',@obj.updateBehaviorZeroCaseCB);
                  addlistener(vidInfo_obj,...
                     'offsetChanged',@(o,e) obj.offsetChangedBehaviorCB(o,e,varargin{iV}));
                  
               case 'alignInfo'
                  addlistener(varargin{iV},...
                     'zoomChanged',@obj.zoomChangedAlignCB);
                  addlistener(varargin{iV},...
                     'saveFile',@obj.saveFileCB);
                  addlistener(varargin{iV},...
                     'moveOffset',@(o,e) obj.moveOffsetAlignCB(o,e,vidInfo_obj));
                  addlistener(varargin{iV},...
                     'axesClick',@(o,e) obj.axesClickAlignCB(o,e,vidInfo_obj));
                  addlistener(vidInfo_obj,...
                     'timesUpdated',@(o,e) obj.timesUpdateAlignCB(o,e,varargin{iV}));
                  
               otherwise
                  fprintf(1,'%s is not a class supported by vidUpdateListener.\n',...
                     class(varargin{iV}));
            end
         end
      end
      
      % Add graphics object handles to properties
      function addGraphics(obj,graphics)
         % Get graphics objects
         gobj = fieldnames(graphics);
         for ii = 1:numel(gobj)
            if ismember(gobj{ii},properties(obj))
               obj.(gobj{ii}) = graphics.(gobj{ii});
               if obj.verbose
                  fprintf(1,'->\tAdded %s to listener object.\n',gobj{ii});
               end
            end
         end
      end
      
      % Update image object
      function updateImageObject(obj,x,y,C)
         set(obj.image_display,'XData',x,'YData',y,'CData',C);
      end
      
      %% Functions for vidInfo class:
      % Change any graphics associated with a frame update
      function frameChangedVidCB(obj,src,~)
         
         set(obj.neuTime_display,'String',...
            sprintf('Neural Time: %0.3f',src.tNeu));
         set(obj.vidTime_display,'String',...
            sprintf('Video Time: %0.3f',src.tVid));
         set(obj.image_display,'CData',...
            obj.videoFile.read(src.frame));
         
         obj.tNeu = src.tNeu;
         obj.tVid = src.tVid;
         
         % If vidTime_line is not empty, that means there is the alignment
         % axis plot so we should update that too:
         if ~isempty(obj.vidTime_line)
            set(obj.vidTime_line,'XData',ones(1,2) * src.tVid);
            
            % Fix axis limits
            if (src.tVid >= obj.xLim(2)) || (src.tVid <= obj.xLim(1))
               obj.updateZoom;
               set(obj.vidTime_line.Parent,'XLim',obj.xLim);
            end
         end
         
      end
      
      % Change any graphics associated with a different video
      function vidChangedVidCB(obj,src,~)
         % Get the file name information
         path = obj.videoFile_list(src.vidListIdx).folder;
         fname = obj.videoFile_list(src.vidListIdx).name;
         vfname = fullfile(path,fname);
         
         % Read the actual video file
         obj.setVideo(vfname);
         
         % Update metadata about new video
         FPS=obj.videoFile.FrameRate;
         nFrames=obj.videoFile.NumberOfFrames;
         src.setVideoInfo(FPS,nFrames);
         
         % Update the image (in case dimensions are different)
         C = obj.videoFile.read(1);
         x = [0,1];
         y = [0,1];
         obj.updateImageObject(x,y,C);
         
         % Move video to the correct time
         src.setVidTime(src.tVid);
         obj.updateZoom;
         
         % Update the correct frame, last
         obj.frameChangedVidCB(src,nan);
         
      end
      
      % Change the actual video file
      function setVideo(obj,vfname)
         delete(obj.videoFile);
         if obj.verbose
            tic;
            [~,name,ext] = fileparts(vfname);
            fprintf(1,...
               'Please wait, loading %s.%s (can be a minute or two)...',...
               name,ext);
         end
         obj.videoFile = VideoReader(vfname);
         if obj.verbose
            fprintf(1,'complete.\n');
            toc;
         end
      end
      
      %% Functions for alignInfo class:
      % Change color of the animal name display
      function saveFileCB(obj,src,~) %#ok<INUSD>
         set(obj.animalName_display,'Color',[0.1 0.7 0.1]);
         if obj.curState
            str = questdlg('Save successful. Exit?','Close Prompt',...
               'Yes','No','Yes');
            if strcmpi(str,'Yes')
               obj.parent.UserData = 'Force';
               closeCB(obj);
            end
         end
      end
      
      % Close everything if verified
      function closeCB(obj,~,~)
         close(obj.parent);
      end
      
      % Change the neural and video times in the videoInfoObject
      function moveOffsetAlignCB(obj,src,~,v)
         v.setOffset(src.alignLag);
         v.updateTime;
         obj.frameChangedVidCB(v,nan);
         obj.curState = true; % Now, when save is done, prompt to exit
      end
      
      % Skip to a point from clicking in axes plot
      function axesClickAlignCB(~,src,~,v)
         v.setVidTime(src.cp);
      end
      
      % Update the known axes limits
      function zoomChangedAlignCB(obj,src,~)
         obj.xLim = src.curAxLim;
      end
      
      % Update associated times when video info times are changed
      function timesUpdateAlignCB(~,src,~,a)
         a.setVidTime(src.tVid);
         a.setNeuTime(src.tNeu);
      end
      
      %% Functions for behaviorInfo class:
      % Go to the next candidate trial and update graphics to reflect that
      function newTrialBehaviorCB(obj,src,~,v)
         for ii = 1:numel(obj.varState)
            obj.varState(ii) = ~isnan(src.varVal(ii));
         end
         
         % Increment through the variables (columns of behaviorData)
         while src.stepIdx
            % For each variable get the appropriate corresponding value,
            % turn it into a string, and update the graphics with that:
            val = obj.translateMarkedValue(src);
            str = obj.getGraphicString(src,val);
            obj.updateBehaviorEditBox(src.idx,str);
         end
         
         % Update graphics pertraining to which trial it is
         obj.updateBehaviorTrialPopup(src.cur);
         obj.updateCurrentBehaviorTrial(src.cur);
         
         % Update graphics pertaining to scoring progress
         if ismember('Outcome',src.behaviorData.Properties.VariableNames)
            obj.updateBehaviorTracker(src.cur,src.N,nansum(src.behaviorData.Outcome));
         else
            obj.updateBehaviorTracker(src.cur,src.N);
         end
         
         % Update the current video frame
         v.setVidTime(src.Trials(src.cur)); % already in "vid" time
         
      end
      
      % Update graphics to reflect update to behaviorData
      function updateBehaviorCB(obj,src,~)
         % Only update a single (notified) value
         val = src.varVal(src.idx);
         
         % Decide if the state is changed and put new value into the table
         % which will be saved as an output.
         obj.varState(src.idx) = src.addRemoveValue(val);
         str = obj.getGraphicString(src,val);
         
         % Update graphics pertaining to this variable
         obj.updateBehaviorEditBox(src.idx,str);
         
         % Update graphics pertaining to scoring progress
         if ismember('Outcome',src.behaviorData.Properties.VariableNames)
            obj.updateBehaviorTracker(src.cur,src.N,nansum(src.behaviorData.Outcome));
         else
            obj.updateBehaviorTracker(src.cur,src.N);
         end
      end
      
      % Update graphics to reflect update to behaviorData for ZERO count
      function updateBehaviorZeroCaseCB(obj,src,~)
         % Decide if the state is changed and put new value into the table
         % which will be saved as an output.
         obj.varState(src.idx) = src.forceZeroValue;
         str = obj.getGraphicString(src,zeros(size(src.idx)));
         
         % Update graphics pertaining to this variable
         if iscell(str)
            for i = 1:numel(str)
               obj.updateBehaviorEditBox(src.idx(i),str{i});
            end
         else
            obj.updateBehaviorEditBox(src.idx,str);
         end
         
         % Update graphics pertaining to scoring progress
         if ismember('Outcome',src.behaviorData.Properties.VariableNames)
            obj.updateBehaviorTracker(src.cur,src.N,nansum(src.behaviorData.Outcome));
         else
            obj.updateBehaviorTracker(src.cur,src.N);
         end
      end
      
      % Update the graphics to reflect to new video offset
      function offsetChangedBehaviorCB(obj,src,~,b)
         % Get list of trial video times
         tVideo = b.behaviorData.(b.varName{1});
         obj.vidOffset = src.videoStart;
         tNeural = src.toNeuTime(tVideo);
         str = cellstr(num2str(tNeural));
         
         % This makes it look nicer:
         str = cellfun(@(x) strrep(x,' ',''),str,'UniformOutput',false);
         
         % Update the popupbox list of times to reflect neural times
         obj.trialPopup_display.String = str;
      end
      
      % Update the tracker image by reflecting the "state" using red or
      % blue coloring in an image
      function updateBehaviorTracker(obj,curTrial,n,nSuccessful)
         if nargin < 4
            nSuccessful = 0;
         end
         
         if ~any(~obj.varState)
            obj.trialTracker_display.CData(1,curTrial,:)=[0 0 1];
         else
            obj.trialTracker_display.CData(1,curTrial,:)=[1 0 0];
         end
         
         tr = curTrial-1 + ~any(~obj.varState);
         obj.nTotal = n;
         obj.trialTracker_label.String = sprintf(...
            'Progress Indicator      %g/%g',...
            tr,...
            obj.nTotal);       
         
         if nSuccessful == 1
            obj.successTracker_label.String = '1 Successful Retrieval';
         else
            obj.successTracker_label.String = sprintf(...
               '%g Successful Retrievals',nSuccessful);
         end  
         
         if tr == n
            obj.animalName_display.Color = 'y';
            obj.trialTracker_label.Color = 'y';
            obj.successTracker_label.Color = 'y';
            obj.curState = true;
         else
            obj.animalName_display.Color = 'r';
            obj.trialTracker_label.Color = 'w';
            obj.successTracker_label.Color = 'w';
            obj.curState = false;
         end
         
      end
      
      % Update the tracker to reflect which trial is being looked at
      % currently
      function updateCurrentBehaviorTrial(obj,curTrial)
         x = linspace(0,1,size(obj.trialTracker_display.CData,2)+1);
         x = x(2:end) - mode(diff(x))/2;
         obj.trialTracker_displayOverlay.XData = [x(curTrial),x(curTrial)];
      end
      
      % Update the graphics object associated with grasp time
      function updateBehaviorEditBox(obj,idx,str)
         % Offset by 1 because first "var" corresponds to the popup list
         % graphics object, while the rest are all the editBoxes.
         arrayIdx = idx - 1;
         
         if obj.varState(idx)
            obj.editArray_display{arrayIdx}.String = str;
         else
            obj.editArray_display{arrayIdx}.String = 'N/A';
         end
      end
      
      % Update the graphics object associated with trial button
      function updateBehaviorTrialPopup(obj,curTrial)
         obj.trialPopup_display.Value = curTrial;
      end
      
   end
   
   methods (Access = private)
      % Get appropriate string to put in controller edit box
      function str = getGraphicString(obj,src,val)
         if numel(src.idx) > 1
            str = cell(size(src.idx));
            for iIdx = 1:numel(src.idx)
               str{iIdx} = getStr(obj,src.varType(src.idx(iIdx)),val(iIdx));
            end
            return;
         else
            str = getStr(obj,src.varType(src.idx),val);
            return;
         end
         
         function str = getStr(obj,vType,val)
            switch vType
               case 5 % Currently, which paw was used for the trial
                  if val > 0
                     str = 'Right';
                  else
                     str = 'Left';
                  end
                  
               case 4 % Currently, outcome of the pellet retrieval attempt
                  if val > 0
                     str = 'Successful';
                  else
                     str = 'Unsuccessful';
                  end
                  
               case 3 % Currently, presence of pellet in front of rat
                  if val > 0
                     str = 'Yes';
                  else
                     str = 'No';
                  end
                  
               case 2 % Currently, # of pellets on platform
                  if val > 8
                     str = '9+';
                  else
                     str = num2str(val);
                  end
                  
               otherwise
                  % Already in video time: set to neural time for display
                  str = num2str(obj.toNeuTime(val));
            end
         end
      end
      
      % Get corresponding value
      function val = translateMarkedValue(obj,src)
         val = src.behaviorData.(obj.varName{src.idx})(src.cur);
      end
      
      % Convert to video time
      function tVid = toVidTime(obj,tNeu)
         tVid = tNeu + (obj.tVid - obj.tNeu); % Gets the offset
      end
      
      % Convert to neural time
      function tNeu = toNeuTime(obj,tVid)
         tNeu = tVid + (obj.tNeu - obj.tVid);
      end
      
      % Fix zoom on axes
      function updateZoom(obj)
         obj.xLim = [obj.tVid - obj.zoomOffset, obj.tVid + obj.zoomOffset];
      end
   end
end