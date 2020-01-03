classdef (ConstructOnLoad) statusChanged < event.EventData
   % STATUSCHANGED   Event data that is issued by 
   %                 nigeLab.Block/updateStatus when the Status of
   %                 a particular field is changed.
   %
   %  STATUSCHANGED Properties:
   %     field - (char) - 'Raw' or 'Spikes' etc
   %
   %     fieldType - (char) - 'Channels' or 'Streams' etc
   %
   %     blockKey - (char) - Alphanumeric public key of a unique Block
   %
   %     status - (logical) - Current processing status of a field
   %
   %     index - (double) - Vector indexing struct elements corresponding
   %        to values of status. For example, for a 'Channels' FieldType,
   %        this might be [1,3,5] for the first, third, and fifth channels
   %        in the array that could correspond to 'A-022', 'A-005', and
   %        'B-027' or something like that.
   %
   %  STATUSCHANGED Methods:
   %     
   %     statusChanged  --  Status changed event data class constructor
   %        evt = nigeLab.evt.statusChanged('fieldName',fieldType,...
   %           key,true,channelIndex);
   
   properties (Access = public)
      field           char    % 'Raw' or 'Spikes' etc.
      fieldType       char    % Fieldtype e.g. 'Channels' or 'Streams' etc
      key             char    % Alphanumeric key corresponding to unique Block
      status          logical % True or False : Current processing status of a channel
      index           double  % Vector indexing struct elements corresponding to status values
   end
   
   methods (Access = public)
      function evt = statusChanged(field,fieldType,key,status,index)
         % STATUSCHANGED   Event data that is issued by
         %                          nigeLab.Block/updateStatus when the 
         %                          Status of a particular field is changed
         %
         %  evt = nigeLab.evt.statusChanged(field,fieldType,key);
         %  --> Creates event data that can be passed via `notify` during a
         %      'StatusChanged' event of nigeLab.Block
         %
         %  e.g.
         %  ...
         %  % Some processing
         %  ...
         %  blockObj.updateStatus('fieldName',channelIndex,true);
         %  ...
         %  key = blockObj.getKey();
         %  evt = nigeLab.evt.statusChanged('fieldName',...
         %           fieldType,key,true,channelIndex);
         %  notify(blockObj,'StatusChanged',evt);
         
         evt.field = field;
         evt.fieldType = fieldType;
         evt.key = key;
         evt.status = status;
         evt.index = index;
      end
   end
   
end

