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
if isempty(blockObj.Videos)
   blockObj.updateStatus(field,false);
   return;
end

flag = updateVidInfo(blockObj,true);
if ~flag
   blockObj.updateStatus(field,false);
else
   updateFlags = true(1,numel(blockObj.Videos));
   blockObj.updateStatus(field,updateFlags,1:numel(blockObj.Videos));
end

end