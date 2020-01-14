classdef (ConstructOnLoad) dashChanged < event.EventData
   % DASHCHANGED  Issued by `nigeLab.libs.DashBoard` on Open or Close
   %
   %  DASHCHANGED Properties:
   %     IsOpen - logical - True if DashBoard figure is open.
   %  
   %     Type - char - Can be: 'Opened', 'Closed', 'Requested'
   %
   %  DASHCHANGED Methods:
   %     
   %     dashChanged  --  Event data class constructor
   %        evt = nigeLab.evt.dashChanged('State');
   
   properties (Access = public)
      IsOpen (1,1) logical      
      Type         char  % {'Opened','Closed','Requested'}
   end
   
   methods (Access = public)
      function evt = dashChanged(Type)
         % DASHCHANGED  Issued by `nigeLab.libs.DashBoard` on Open or Close
         %
         %  evt = nigeLab.evt.dashChanged(Type);
         %  --> Creates event data that can be passed via `notify` during a
         %      'DashChanged' event of nigeLab.Block
         %  --> Valid values of Type (not case-sensitive):
         %      {'Opened','Closed','Requested'}
         
         ValidTypes_ = {'opened','closed','requested'};
         idx = ismember(ValidTypes_,lower(Type));
         if idx == 1
            evt.Type = ValidTypes_{idx};
         end
         evt.Type = Type;
         evt.IsOpen = strcmp(evt.Type,'Opened');
      end
   end
   
end

