function flag = linkField(blockObj,fieldIndex)
%% LINKFIELD   Connect the data saved on the disk to a Field of Block
%
%  b = nigeLab.Block;
%  flag = LINKFIELD(b,fieldIndex); % fieldIndex is a numeric scalar
%  flag = LINKFIELD(b,fieldName);  % fieldName is a char array matching
%                                    an element of blockObj.Fields
%
%  Used to "link" all the pointers contained in blockObj (e.g.
%  blockObj.Channels.Raw or blockObj.Events.DigIO) to the appropriate data
%  stored on the disk, and update the status to reflect whether the file
%  exists in the correct format.
%
%  flag returns true if something was not linked correctly. This is
%  assigned to an array element of 'warningRef' that is then used to issue
%  command window warnings to the user.

%%
flag = false;
if isnumeric(fieldIndex)
   if ~isscalar(fieldIndex)
      error('fieldIndex must be scalar if it is numeric');
   end
   field = blockObj.Fields{fieldIndex};
elseif ischar(fieldIndex)
   field = fieldIndex;
   fieldIndex = blockObj.checkCompatibility(field);
end
fileType = blockObj.getFileType(field);
switch blockObj.FieldType{fieldIndex}
   case 'Channels'
      % Streamed data from the high-resolution neurophysiological
      % amplifiers. Typically this is a relatively high channel count that
      % is acquired in parallel and manipulated together for downstream
      % processing and analyses.
      
      flag = blockObj.linkChannelsField(field,fileType);
   case 'Streams'
      % Streams are like Channels, but from DAC or ADC, etc. so they are
      % not associated with the neurophysiological recording Channels
      % structure
      flag = blockObj.linkStreamsField(field);
   case 'Events'
      % Events have the following fields:
      % 'type', 'value', 'tag', 'ts', 'snippet'
      flag = blockObj.linkEventsField(field);
   case 'Videos'
      flag = blockObj.linkVideosField(field);
   case 'Meta'
      % Metadata are special cases, basically
      switch lower(field)
         case 'notes'
            flag = blockObj.linkNotes;
            blockObj.updateStatus(field,flag);
         case 'probes'
            flag = blockObj.linkProbe;
            % blockObj.updateStatus called in linkProbe method
         case 'time'
            flag = blockObj.linkTime;
            % blockObj.updateStatus is called in linkTime method
         otherwise
            warning('Parsing is not configured for FieldType: %s',...
               blockObj.FieldType{fieldIndex});
            return;
      end
      
   otherwise
      warning('Parsing is not configured for FieldType: %s',...
         blockObj.FieldType{fieldIndex});
      return;
end

end