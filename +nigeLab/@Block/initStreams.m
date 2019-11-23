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
%       blockObj.Streams.(name) = 
   end
end
flag = true;

%%%%%%%%%%% FB modified 10/4/19
% jj=1;
% tmp = cell(1,nStreamTypes);
% tmpSize=zeros(1,nStreamTypes);
% for ii = 1:nStreamTypes
%    name = blockObj.Fields{fieldIdx(ii)};
%    
%    headerStructName = [name 'Channels'];
%    if ismember(headerStructName,headerFields)
%       tmp{jj} = blockObj.Meta.Header.(headerStructName);
%       tmpSize(jj) = numel(tmp{jj})';
%       jj=jj+1;
%    end
% end
% 
% blockObj.Streams=repmat(channel_struct(),1,sum(tmpSize));
% index = 1;
% for ii = 1:jj-1
%     blockObj.Streams(index:(tmpSize(ii)+index-1)) = tmp{ii};
%     index = index + tmpSize(ii);
% end
% 
% flag = true;


end

