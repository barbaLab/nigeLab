function set(ro, varargin)
%SET  Overloaded 'Set' method for ROLLOVER objects
%
%  set(ro,'PropName1',PropVal1,...);

switch nargin
   % One argument only : show a description of members
   case 1
      % Temporary structure
      description = struct(ro);
      
      % Description of each member of the ROLLOVER object
      description.Handles = '[Array of pushbutton handles]';
      description.StringsDefault = '{Array of strings for pushbuttons'' labels during normal behavior}';
      description.IconsDefault = '{Array of icons during normal behavior}';
      description.StringsOver = '{Array of strings for pushbuttons'' labels during normal behavior}';
      description.IconsOver = '{Array of icons during normal behavior}';
      description.CurrentButtonHdl = 'Handle of the pushbutton over which mouse pointer currently moves.';
      description.NigelButtonHdl = 'Handle of the nigeLab.libs.nigelButton over which mouse pointer currently moves.';
      description.Parent = 'Handle of the figure containing the ROLLOVER object. READ-ONLY';

      % Show class summary
      disp(' ')
      disp('Description of ROLLOVER members :')
      disp(' ')
      disp(description);
      return;
      
   otherwise
      % Set given property
      properties_values = varargin;
      while length(properties_values) >= 2
         prop = properties_values{1};
         val  = properties_values{2};
         properties_values = properties_values(3:end);
         
         switch prop
            % Set pushbutton handles
            case 'Handles'
               % Validate given handles
               if all(ishandle(val)) && all(strcmp(get(val, 'Type'), 'uicontrol')) && all(strcmp(get(val, 'Style'), 'pushbutton'))
                  ro.Handles = val;
                  ro.StringsDefault = get(ro.Handles, 'String');
                  ro.IconsDefault = get(ro.Handles, 'CData');
                  ro.CurrentButtonHdl(:) = [];
                  % Rollover labels = default labels by default
                  ro.StringsOver = ro.StringsDefault;
                  % Rollover icons = default icons by default
                  ro.IconsOver = ro.IconsDefault;
               else
                  error('Handles must be a valid array of pushbutton handles !!');
               end
               
               % Labels during rollover behavior
            case 'StringsOver'
               % As many strings and pushbuttons ?
               if numel(val) == numel(ro.Handles)
                  ro.StringsOver = val;
               else
                  warning('Equal number of labels and pushbuttons needed !! Default labels kept');
               end
               
               % Icons during rollover behavior
            case 'IconsOver'
               % As many icons and pushbuttons ?
               if numel(val) == numel(ro.Handles)
                  ro.IconsOver = val;
               else
                  warning('Equal number of icons and pushbuttons needed !! Default icons kept');
               end
               
               % Handle of currebtly rollovered pushbutton
            case 'CurrentButtonHdl'
               if isempty(val)
                  % If CurrentButtonHdl is set AND not already empty,
                  % it means that mouse just left the pushbutton:
                  % return to default label and default icon
                  bIdx = ro.Handles == ro.CurrentButtonHdl;
                  set(ro.CurrentButtonHdl, ...
                     'String', ro.StringsDefault{bIdx}, ...
                     'CData', ro.IconsDefault{bIdx});
                  ro.CurrentButtonHdl(:) = [];
               elseif find(ro.Handles == val)
                  % Set label and icon during rollover
                  vIdx = ro.Handles == val;
                  set(val, 'String', ro.StringsOver{vIdx}, ...
                           'CData', ro.IconsOver{vIdx});
                  if ~isempty(ro.CurrentButtonHdl) && ...
                        val ~= ro.CurrentButtonHdl
                     bIdx = ro.Handles == ro.CurrentButtonHdl;
                     set(ro.CurrentButtonHdl, ...
                        'String', ro.StringsDefault{bIdx}, ...
                        'CData', ro.IconsDefault{bIdx});
                  end
                  ro.CurrentButtonHdl = val;
               else
                  error('Handle of current pushbutton must belong to the list of rollover-capable pushbuttons !!');
               end
            case 'NigelButtonHdl'
               % If a NigelButton is hovered, just update its 'Hovered'
               % property to 'on' and its edges will glow.
               if isempty(val)
                  ro.NigelButtonHdl.Hovered = 'off';
                  ro.NigelButtonHdl(:) = [];
               else
                  if ~isempty(ro.NigelButtonHdl)
                     if (val~=ro.NigelButtonHdl)
                        ro.NigelButtonHdl.Hovered = 'off';
                     end
                  end
                  val.Hovered = 'on';
                  ro.NigelButtonHdl = val;
               end
               % Handle of the figure containing the ROLLOVER object
               % Read-only
            case 'Parent'
               error('Parent is read-only !!');
         end
      end
end

% Save updated version in application data
setappdata(get(ro,'Parent'),'rollover',ro);

end