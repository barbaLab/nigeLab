function flag = updateVidInfo(blockObj,forceExtraction)
%UPDATEVIDINFO    Update the video info associated with Block object
%
%  Private method: Called as part of nigeLab.Block/doVidInfoExtraction()
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class object from orgExp package.
%
%  forceExtraction   :     Default is false. Set to true (called from
%                             linkVideosField) to force extraction if no
%                             Videos are detected.
%                          --> Method called from /doVidInfoExtraction
%                              should NOT have this flag set to true
%                              (otherwise potential infinite loop)
%
%  --------
%   OUTPUT
%  --------
%    flag      :     Flag indicating if setting new path was successful.

if nargin < 2
   forceExtraction = false;
end

% ITERATE ON EACH BLOCK IN AN ARRAY
if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      flag = flag && updateVidInfo(blockObj(i));
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

[fmt,idt,type] = blockObj.getDescriptiveFormatting();
if ~isfield(blockObj.Paths,'V')
   if ~forceExtraction
      nigelab.utils.cprintf('Errors*','%s[UPDATEVIDINFO]: ',idt);
      nigeLab.utils.cprintf(fmt(1:(end-1)),...
         'Video info for %s %s not yet set. See: ',...
         type,blockObj.Name);
      nigeLab.utils.cprintf('Keywords*','doVidInfoExtraction\n');
   else
      doVidInfoExtraction(blockObj);
   end
   return;
   
elseif ~isfield(blockObj.Paths.V,'Match')
   nigelab.utils.cprintf('Errors*','%s[UPDATEVIDINFO]: ',idt);
   nigeLab.utils.cprintf(fmt,...
      'No videos initialized for %s %s.\n',...
      type,blockObj.Name);
   flag = true;
   return;

end

blockObj.Videos = nigeLab.libs.VideosFieldType(blockObj);
uView = unique(blockObj.Meta.Video.View);
initRelativeTimes(blockObj.Videos,uView);

flag = true;

end

