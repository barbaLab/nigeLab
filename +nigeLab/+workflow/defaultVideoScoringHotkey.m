function defaultVideoScoringHotkey(evt,obj)
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

switch evt.Key
    case 'comma' % not a stereotyped trial (default)
        add(obj,'lbl','Stereotyped',0);
    case 'period' % set as stereotyped trial
        add(obj,'lbl','Stereotyped',1);
    case 't' % set reach frame
        add(obj,'evt','ReachStarted');
        add(obj,'lbl','Reach',1);
    case 'r' % set no reach for trial
        add(obj,'lbl','Reach',0);
    case 'g' % set grasp frame
        add(obj,'evt','GraspStarted');
        add(obj,'lbl','Grasp',1);
    case 'f' % set no grasp for trial
        add(obj,'lbl','Grasp',0);
    case 'b' % set "both" (support) frame
        add(obj,'lbl','Support',1);
    case 'v' % (next to 'b') -> no "support" for this trial
        add(obj,'lbl','Support',0);
    case 'multiply' % set trial Complete frame
        add(obj,'evt','EndOfTrial');
        add(obj,'lbl','Complete',1);
    case 'divide' % set "no" trial Complete frame (i.e. he never
        % brought paw back into box before reaching on next
        % trial)
        add(obj,'lbl','Complete',0);
    case 'w' % set outcome as Successful
        add(obj,'lbl','Outcome',1);
    case 'x' % set outcome as Unsuccessful
        add(obj,'lbl','Outcome',0);
    case 'e' % set forelimb as 'Right' (1)
        if ismember('alt',evt.Modifier) % alt + e: all trials are 'right'
            if ismember('shift',evt.Modifier)
                addAllTrials(obj,'Door',1);
            else
                addAllTrials(obj,'Forelimb',1);
            end
        else
            if ismember('shift',evt.Modifier)
                add(obj,'lbl','Door',1);
            else
                add(obj,'lbl','Forelimb',1);
            end
        end
    case 'q' % set forelimb as 'Left' (0)
        if ismember('alt',evt.Modifier) % alt + q: all trials are 'left'
            if ismember('shift',evt.Modifier)
                addAllTrials(obj,'Door',0);
            else
                addAllTrials(obj,'Forelimb',0);
            end
        else
            if ismember('shift',evt.Modifier)
                add(obj,'lbl','Door',0);
            else
                add(obj,'lbl','Forelimb',0);
            end
        end
    case 'a' % previous frame
        previousFrame(obj);
    case 'leftarrow' % previous trial
        previousTrial(obj);
    case 'd' % next frame
        nextFrame(obj);
    case 'rightarrow' % next trial
        nextTrial(obj);
    case 's' % alt + s = save
        if strcmpi(evt.Modifier,'alt')
            saveScoring(obj);
        end
    case 'numpad0'
        add(obj,'lbl','Pellets',0);
    case 'numpad1'
        add(obj,'lbl','Pellets',1);
    case 'numpad2'
        add(obj,'lbl','Pellets',2);
    case 'numpad3'
        add(obj,'lbl','Pellets',3);
    case 'numpad4'
        add(obj,'lbl','Pellets',4);
    case 'numpad5'
        add(obj,'lbl','Pellets',5);
    case 'numpad6'
        add(obj,'lbl','Pellets',6);
    case 'numpad7'
        add(obj,'lbl','Pellets',7);
    case 'numpad8'
        add(obj,'lbl','Pellets',8);
    case 'numpad9'
        add(obj,'lbl','Pellets',9);
    case 'subtract'
        add(obj,'lbl','PelletPresent',0);
    case 'add'
        add(obj,'lbl','PelletPresent',1);
    case 'delete'
        toggleTrialMask(obj);
    case 'space'
        playpause(obj);
end

end