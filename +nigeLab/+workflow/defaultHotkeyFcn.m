function defaultHotkeyFcn(evt,v,b)
% DEFAULTHOTKEYFCN  Default function mapping hotkeys for video scoring
%
%  inputs:
%     evt -- Keypress eventdata, which has evt.Key for the name of
%            the key pressed and evt.Modifier for any other key,
%            such as 'alt' or 'ctrl' that was pressed concurrently.
%     v -- nigeLab.libs.vidInfo class object that tracks video frame
%           timing and offset info, etc.
%     b -- nigeLab.libs.behaviorInfo class object that tracks event
%           data from scoring etc.
%
%  RESERVED KEYS: 'control' (modifier: control + key gives HELP)
%                 'escape' (closes the window).
%                 'h' (lists current keypress commands).

switch evt.Key
   case 'comma' % not a stereotyped trial (default)
      setValue(b,'Stereotyped',0);
   case 'period' % set as stereotyped trial
      setValue(b,'Stereotyped',1);
   case 't' % set reach frame
      setValue(b,'Reach',v.NeuTime);
   case 'r' % set no reach for trial
      setValue(b,'Reach',inf);
   case 'g' % set grasp frame
      setValue(b,'Grasp',v.NeuTime);
   case 'f' % set no grasp for trial
      setValue(b,'Grasp',inf);
   case 'b' % set "both" (support) frame
      setValue(b,'Support',v.NeuTime);
   case 'v' % (next to 'b') -> no "support" for this trial
      setValue(b,'Support',inf); 
   case 'multiply' % set trial Complete frame
      setValue(b,'Complete',v.NeuTime);
   case 'divide' % set "no" trial Complete frame (i.e. he never
      % brought paw back into box before reaching on next
      % trial)
      setValue(b,'Complete',inf);
   case 'w' % set outcome as Successful
      setValue(b,'Outcome',1); 
   case 'x' % set outcome as Unsuccessful
      setValue(b,'Outcome',0);
   case 'e' % set forelimb as 'Right' (1)
      if strcmpi(evt.Modifier,'alt') % alt + e: all trials are 'right'
         setValueAll(b,'Forelimb',1);
      else
         setValue(b,'Forelimb',1);
      end
   case 'q' % set forelimb as 'Left' (0)
      if strcmpi(evt.Modifier,'alt') % alt + q: all trials are 'left'
         setValueAll(b,'Forelimb',0);
      else
         setValue(b,'Forelimb',0);
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
      toggleTrialMask(b);
   case 'space'
      playPauseVid(v);
end

end