function flag = linkVideosField(blockObj,field)
%% LINKVIDEOSFIELD  Connect the data saved on the disk to Videos
%
%  b = nigeLab.Block;
%  flag = LINKVIDEOSFIELD(b);
%
%  Returns flag as true when a file is missing.


%%
flag = false;
str = nigeLab.utils.printLinkFieldString(blockObj.getFieldType(field),field);
if isempty(blockObj.Videos)
   return;
end
[~,updateFlags] = getFile(blockObj.Videos,field);
blockObj.updateStatus(field,updateFlags);
pct = round((sum(updateFlags)/numel(updateFlags)) * 100);
blockObj.reportProgress(str,pct);

flag = true;

end