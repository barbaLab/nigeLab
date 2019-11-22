function flag = initStreams(blockObj)
%% INITSTREAMS Initialize Streams struct for nigeLab.Block class object
%
%  flag = INITSTREAMS(blockObj);
%
%  flag: Returns false if initialized correctly; otherwise, returns true
%        (so it is really "warningFlag")
%
% By: Max Murphy  v1.0  2019/01/11  Original version (R2017a)

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

%%%%%%%%%%% FB modified 10/4/19
% MM modified 2019-11-20

tmpSize=zeros(1,nStreamTypes);
for ii = 1:nStreamTypes
   name = fields{ii};
   
   headerStructName = [name 'Channels'];
   if ismember(headerStructName,headerFields)
      blockObj.Streams.(name) = blockObj.Meta.Header.(headerStructName);
   else
      warning('Missing header: %s',headerStructName);      
   end
end

flag = true;


end

