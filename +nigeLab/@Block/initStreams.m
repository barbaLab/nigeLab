function flag = initStreams(blockObj)
%% INITSTREAMS Initialize Streams struct for nigeLab.Block class object
%
%  flag = INITSTREAMS(blockObj);
%
%  flag: Returns false if initialized correctly; otherwise, returns true
%        (so it is really "warningFlag")

%%
flag = false;
[fieldIdx,nStreamTypes] = blockObj.getFieldTypeIndex('Streams');
fields = blockObj.Fields(fieldIdx);
if sum(fieldIdx) == 0
   flag = true;
   disp('No STREAMS to initialize.');
   return;
end

blockObj.Streams = struct;
headerFields = fieldnames(blockObj.Meta.Header);

% MM modified 2019-11-20
tmp = repmat({nigeLab.utils.initChannelStruct('Streams',0)},1,nStreamTypes);
for ii = 1:nStreamTypes
   name = fields{ii};

   headerStructName = [name 'Channels'];
   if ismember(headerStructName,headerFields)
      blockObj.Streams.(name) = blockObj.Meta.Header.(headerStructName);
   else
      warning('Missing header: %s',headerStructName); 
      fprintf(1,'Initializing empty Streams struct: %s\n',headerStructName);
      blockObj.Streams.(name) = nigeLab.utils.initChannels('Streams',0);
   end
end
flag = true;


end

