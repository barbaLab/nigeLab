classdef (ConstructOnLoad) figButtonUp < event.EventData
% FIGBUTTONUP  Event for notifying listeners of "buttonup" from click type
%
%  FIGBUTTONUP Methods:
%     figButtonUp  -  Class constructor
%        evt = nigeLab.evt.figButtonUp(SelectionType);
%
%  FIGBUTTONUP Properties:
%     Name  -  'left', 'right', 'double', 'both', or 'unknown'
%     
%     SelectionType - 'normal', 'alt', 'open', or 'extend'

   properties
      Name           char  % "Name" of click type: {'left','right','double','both','unknown'}
      SelectionType  char  % Type of button event: {'normal','alt','open','extend'}
   end

   methods
      function evt = figButtonUp(SelectionType)
         % FIGBUTTONUP  Event for notifying listeners of "button
         %                       up" from click type.
         %
         %  evt = nigeLab.evt.figButtonUp(SelectionType);
         %
         %  evt.Name: {'left','right','double','both', or 'unknown'}
         %  evt.SelectionType: {'normal,'alt','open','extend'};
         
         evt.SelectionType = SelectionType;
         switch lower(evt.SelectionType)
            case 'normal' % Left-clicked
               evt.Name = 'left';
            case 'alt'    % Right-clicked
               evt.Name = 'right';
            case 'open'   % Double-clicked
               evt.Name = 'double';
            case 'extend' % Both clicked
               evt.Name = 'both';
            otherwise
               warning('Unexpected click type: %s',SelectionType);
               evt.Name = 'unknown';
         end
      end
   end
   
end