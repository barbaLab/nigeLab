function flag = linkVideosField(blockObj,field)
%% LINKVIDEOSFIELD  Connect the data saved on the disk to Videos
%
%  b = nigeLab.Block;
%  flag = LINKVIDEOSFIELD(b);
%
%  Returns flag as true when a file is missing.
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2019 collaboration (Freddy & Max)

%%
flag = false;
str = nigeLab.utils.printLinkFieldString(blockObj.getFieldType(field),field);

[~,updateFlags] = getFile(blockObj.Videos,field);
blockObj.updateStatus(field,updateFlags);
pct = round((sum(updateFlags)/numel(updateFlags)) * 100);
blockObj.reportProgress(str,pct);

flag = true;

end