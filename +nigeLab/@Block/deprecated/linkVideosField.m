function flag = linkVideosField(blockObj,field)
%LINKVIDEOSFIELD  Connect the data saved on the disk to Videos
%
%  b = nigeLab.Block;
%  flag = LINKVIDEOSFIELD(b);
%
%  Returns flag as true when a file is missing.

if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      flag = flag && linkVideosField(blockObj(i),field);
   end
   return;
else
   flag = false;
end

if isempty(blockObj)
   flag = true;
   return;
elseif ~isvalid(blockObj)
   flag = true;
   return;
end

% If this is called before videos are initialized, then it will never
% "link" the videos properly; however, videos should always be initialized
% first.
if isempty(blockObj.Cameras)
   blockObj.updateStatus(field,false);
   return;
else
   for ii=1:numel(blockObj.Cameras)
       blockObj.Cameras(ii).addVideos;
   end
   updateFlags = true(1,numel(blockObj.Cameras));
   blockObj.updateStatus(field,updateFlags,1:numel(blockObj.Cameras));

end

end