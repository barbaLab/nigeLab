function flag = linkField(blockObj,fieldIndex)
%% LINKFIELD   Connect the data saved on the disk to a Field of Block
%
%  b = nigeLab.Block;
%  flag = LINKFIELD(b);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
flag = false;
field = blockObj.Fields{fieldIndex};
fType = blockObj.FileType{fieldIndex};
switch blockObj.FieldType{fieldIndex}
   case 'Channels'
      % Streamed data from the high-resolution neurophysiological
      % amplifiers. Typically this is a relatively high channel count that
      % is acquired in parallel and manipulated together for downstream
      % processing and analyses.
      
      flag = blockObj.linkChannelsField(field,fType);
   case 'Streams'
      % Streams are like Channels, but from DAC or ADC, etc. so they are
      % not associated with the neurophysiological recording Channels
      % structure
      flag = blockObj.linkStreamsField(field);
   case 'Events'
      % Events have the following fields:
      % 'type', 'value', 'tag', 'ts', 'snippet'
      flag = blockObj.linkEventsField(field);
   case 'Video'
      flag = blockObj.linkVideoField(field);
   case 'Meta'
      % Metadata are special cases, basically
      switch lower(field)
         case 'notes'
            flag = blockObj.linkNotes;
            blockObj.updateStatus(field,true);
         case 'probes'
            flag = blockObj.linkProbe;
            blockObj.updateStatus(field,true);
         case 'time'
            flag = blockObj.linkTime;
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