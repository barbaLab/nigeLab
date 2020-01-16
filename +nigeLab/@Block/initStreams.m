function flag = initStreams(blockObj,header)
%INITSTREAMS Initialize Streams struct for nigeLab.Block class object
%
%  flag = INITSTREAMS(blockObj);
%
%  flag: Returns false if initialized correctly; otherwise, returns true
%        (so it is really "warningFlag")

flag = false;
if nargin < 2
   header = blockObj.parseHeader();
end

[fieldIdx,nStreamTypes] = blockObj.getFieldTypeIndex('Streams');
fields = blockObj.Fields(fieldIdx);
if sum(fieldIdx) == 0
   flag = true;
   disp('No STREAMS to initialize.');
   return;
end

blockObj.Streams = struct;


for ii = 1:nStreamTypes
   name = fields{ii};
   headerFields = fieldnames(header);
   headerStructName = [name 'Channels'];
   if isempty(header.(headerStructName))
      warning('Empty header for %s. Check that defaults match your experiment.',name);
      blockObj.Streams.(name) = nigeLab.utils.initChannelStruct('Streams',0);
      continue;
   end
   if ismember(headerStructName,headerFields)
      blockObj.Streams.(name) = nigeLab.utils.initChannelStruct('Streams',...
         header.(headerStructName));
   else
      warning('Missing header: %s',headerStructName); 
      fprintf(1,'Initializing empty Streams struct: %s\n',headerStructName);
      blockObj.Streams.(name) = nigeLab.utils.initChannelStruct('Streams',0);
   end
end
flag = true;


end

