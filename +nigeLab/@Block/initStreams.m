function flag = initStreams(blockObj)
%% INITSTREAMS Initialize Streams struct for nigeLab.Block class object
%
%  flag = INITSTREAMS(blockObj);
%
% By: Max Murphy  v1.0  2019/01/11  Original version (R2017a)

%%
flag = false;
fieldIdx = ismember(blockObj.FieldType,'Streams');
nStreamTypes = sum(fieldIdx);
if sum(fieldIdx) == 0
   flag = true;
   disp('No STREAMS to initialize.');
   return;
end

fieldIdx = find(fieldIdx);
blockObj.Streams = struct;

headerFields = fieldnames(blockObj.Meta.Header);

%%%%%%%%%%% FB modified 10/4/19
% MM modified 2019-11-20
jj=0;
tmp = repmat({nigeLab.utils.initChannelStruct('Streams',0)},1,nStreamTypes);
tmpSize=zeros(1,nStreamTypes);
for ii = 1:nStreamTypes
   name = blockObj.Fields{fieldIdx(ii)};
   
   headerStructName = [name 'Channels'];
   if ismember(headerStructName,headerFields)
      jj=jj+1;
      tmp{jj} = blockObj.Meta.Header.(headerStructName);
      tmpSize(jj) = numel(tmp{jj})';
   end
end

blockObj.Streams=nigeLab.utils.initChannelStruct('Streams',sum(tmpSize));
index = 1;
for ii = 1:jj
    blockObj.Streams(index:(tmpSize(ii)+index-1)) = tmp{ii};
    index = index + tmpSize(ii);
end

flag = true;


end

