function defaultHotkeyFcn(evt,v,b)
% DEFAULTHOTKEYFCN  Default function mapping hotkeys for video scoring
%
%  inputs:
%     evt -- Keypress eventdata, which has evt.Key for the name of
%            the key pressed and evt.Modifier for any other key,
%            such as 'alt' or 'ctrl' that was pressed concurrently.
%     v -- nigeLab.libs.VidGraphics class object that tracks video frame
%           timing and offset info, etc.
%     b -- nigeLab.libs.behaviorInfo class object that tracks event
%           data from scoring etc.
%
%  RESERVED KEYS: 'control' (modifier: control + key gives HELP)
%                 'escape' (closes the window).
%                 'h' (lists current keypress commands).

ts = v.TimeAxes.CameraObj.NeuTime_;
switch evt.Key
   case 'backquote' % set all "unset" values to preset values
      varName = b.Variable;
      value = b.Value;
      def_value = b.Defaults;
      for i = 1:numel(varName)
         if ~isnan(value(i)) || isnan(def_value(i))
            continue;
         end
         setValue(b,varName{i},def_value(i));
      end
      % If 'Init' was removed, then toggle mask value to false
      if ismember('Init',varName)
         val = getValue(b,'Init');
         if isinf(val)
            toggleTrialMask(b,0);
         end
      end
      % Last, advance to the next trial
      setTrial(b,nan,b.TrialIndex+1);
   case 'comma' % not a stereotyped trial (default)
      setValue(b,'Stereotyped',0);
   case 'period' % set as stereotyped trial
      setValue(b,'Stereotyped',1);
   case 'i' % set "initial" trial frame
      setTimeStampValue(b,v,evt,'Init',ts);
   case 'o' % clear "initial" trial frame
      setTimeStampValue(b,v,evt,'Init',inf);
   case 't' % set reach frame
      setTimeStampValue(b,v,evt,'Reach',ts);
   case 'r' % set no reach for trial
      setTimeStampValue(b,v,evt,'Reach',inf);
   case 'g' % set grasp frame
      setTimeStampValue(b,v,evt,'Grasp',ts);
   case 'f' % set no grasp for trial
      setTimeStampValue(b,v,evt,'Grasp',inf);
   case 'b' % set "both" (support) frame
      setTimeStampValue(b,v,evt,'Support',ts);
   case 'v' % (next to 'b') -> no "support" for this trial
      setTimeStampValue(b,v,evt,'Support',inf);
   case 'n' % set "nose" frame (nose poke through reach slot
      setTimeStampValue(b,v,evt,'Nose',ts);
   case 'm' % (next to 'm') -> no "nose" for this trial
      setTimeStampValue(b,v,evt,'Nose',inf);
   case 'multiply' % set trial Complete frame
      setTimeStampValue(b,v,evt,'Complete',ts);
   case 'divide' % set "no" trial Complete frame (i.e. he never
      % brought paw back into box before reaching on next
      % trial)
      setTimeStampValue(b,v,evt,'Complete',inf);
   case 'w' % set outcome as Successful
      setValue(b,'Outcome',1); 
   case 'x' % set outcome as Unsuccessful
      setValue(b,'Outcome',0);
   case 'e' % set forelimb as 'Right' (1)
      if ismember('alt',evt.Modifier) % alt + e: all trials are 'right'
         if ismember('shift',evt.Modifier)
            setValueAll(b,'Door',1);
         else
            setValueAll(b,'Forelimb',1);
         end
      else
         if ismember('shift',evt.Modifier)
            setValue(b,'Door',1);
         else
            setValue(b,'Forelimb',1);
         end
      end
   case 'q' % set forelimb as 'Left' (0)
      if ismember('alt',evt.Modifier) % alt + q: all trials are 'left'
         if ismember('shift',evt.Modifier)
            setValueAll(b,'Door',0);
         else
            setValueAll(b,'Forelimb',0);
         end
      else
         if ismember('shift',evt.Modifier)
            setValue(b,'Door',0);
         else
            setValue(b,'Forelimb',0);
         end
      end
   case 'a' % previous frame
      advanceFrame(v,-1); 
   case 'leftarrow' % previous trial
      setTrial(b,nan,b.TrialIndex-1);
   case 'd' % next frame
      advanceFrame(v,1);  
   case 'rightarrow' % next trial
      setTrial(b,nan,b.TrialIndex+1);
   case 's' % alt + s = save
      if strcmpi(evt.Modifier,'alt')
         saveScoring(b);
      end
   case 'c' % "center" axes
      v.TimeAxes.Zoom = v.TimeAxes.Zoom; % Refresh triggers `updateZoom`
   case 'uparrow' % zoom in on timescroller
      zoomIn(v.TimeAxes);
   case 'downarrow' % zoom out on timescroller
      zoomOut(v.TimeAxes);
   case 'numpad0'
      setValue(b,'Pellets',0);
   case 'numpad1'
      setValue(b,'Pellets',1);
   case 'numpad2'
      setValue(b,'Pellets',2);
   case 'numpad3'
      setValue(b,'Pellets',3);
   case 'numpad4'
      setValue(b,'Pellets',4);
   case 'numpad5'
      setValue(b,'Pellets',5);
   case 'numpad6'
      setValue(b,'Pellets',6);
   case 'numpad7'
      setValue(b,'Pellets',7);
   case 'numpad8'
      setValue(b,'Pellets',8);
   case 'numpad9'
      setValue(b,'Pellets',9);
   case 'subtract'
      setValue(b,'PelletPresent',0);
   case 'add'
      setValue(b,'PelletPresent',1);      
   case 'delete'
      toggleTrialMask(b,0);
   case 'backslash'
      toggleTrialMask(b,1);
   case 'f1' % "debug"
      printTimingData(v,evt);
   case 'space'
      playPauseVid(v);
end

% [HELPER]: TimeStamp "Type" values can be "skipped to" by holding shift
   function setTimeStampValue(b,v,evt,eventName,value)
      %SETTIMESTAMPVALUE  Sets "EventTimes" Type variables or jumps to time
      %
      %  setTimeStampValue(b,v,evt,eventName,value);
      %
      %  b : nigeLab.libs.behaviorInfo object
      %  v : nigeLab.libs.VidGraphics object
      %  evt : Event.EventData Matlab WindowKeyPressFcn object
      %  eventName : Name of variable (e.g. 'Reach' or 'Nose')
      %  value : Value to assign to variable (if 'shift' not pressed)
      %
      %  * If 'shift' is held (evt.Modifier{1} == 'shift'), then if the
      %     time has been scored for the current trial already, this allows
      %     you to jump directly to that time.
      
      if isempty(evt.Modifier)
         setValue(b,eventName,value);
      else % If `shift` is pressed, skip to the timestamp
         switch evt.Modifier{1}
            case 'shift' % Retrieve neural time for that event
               tNeu = getValue(b,eventName);
               if isnan(tNeu) || isinf(tNeu)
                  return;
               end
               v.SeriesTime = tNeu + v.NeuOffset;
         end
      end
   end

end