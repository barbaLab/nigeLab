function roll(ro)
%ROLL  Method of nigeLab.libs.Mouse.rollover that is assigned to the
%        WindowButtonMotionFcn of the parent figure.

% Mouse pointer over which control ?
obj = hittest;

% Test whether current_object is a button or not
if strcmp(get(obj, 'Type'), 'uicontrol') && ...
      strcmp(get(obj, 'Style'), 'pushbutton')
    % List of rollover-capable pushbuttons
    allowed_buttons = get(ro, 'Handles');

    % current_object belongs to previous list ?
    if sum(obj == allowed_buttons)~=1
        return
    end

    % Change ro.CurrentButtonHdl to current_object 
    % (and update label and icon)
    set(ro, 'CurrentButtonHdl', obj);
    if ~isempty(get(ro, 'NigelButtonHdl'))
       set(ro,'NigelButtonHdl',[]);
    end
elseif isa(obj,'matlab.graphics.primitive.Rectangle')
   % Otherwise, if this is a Rectangle
   if strcmp(obj.Tag,'Button')
      % Then if it is a "special" nigelButton rectangle:
      if isa(obj.UserData,'nigeLab.libs.nigelButton')
         % Make the edges glow!
         set(ro, 'NigelButtonHdl', obj.UserData);
      end
   end
   if ~isempty(get(ro, 'CurrentButtonHdl'))
        set(ro, 'CurrentButtonHdl',[]);
    end
else
    % current_object is not a button
    % If ro.CurrentButtonHdl is not empty, pushbutton is being left by the
    % mouse pointer -> revert to default label and icon with
    % set(ro, 'CurrentButtonHdl', []);
    % Otherwise, do nothing (labels and icons of other buttons have already
    % been reverted back to normal)
    if ~isempty(get(ro, 'CurrentButtonHdl'))
        set(ro, 'CurrentButtonHdl',[]);
    end
    if ~isempty(get(ro, 'NigelButtonHdl'))
       set(ro,'NigelButtonHdl',[]);
    end
end