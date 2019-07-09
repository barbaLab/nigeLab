function flag = updateVidInfo(blockObj)
%% UPDATEVIDINFO    Update the video info associated with Block object
%
%  Called as part of DOVIDINFOEXTRACTION.
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class object from orgExp package.
%
%  --------
%   OUTPUT
%  --------
%    flag      :     Flag indicating if setting new path was successful.
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%% ITERATE ON EACH VIDEO IN VIDPARS
flag = false;

if isempty(blockObj.VidPars)
   warning('Video parameters not yet set. Try DOVIDINFOEXTRACTION.');
   return;
elseif isempty(blockObj.VideoPars.File)
   warning('No video files associated (path: ~/%s).',...
      blockObj.VideoPars.FilePath);
   return;
end

Props = cell(numel(blockObj.VideoPars.File),1);
for iV = 1:numel(blockObj.VideoPars.File)
   V = VideoReader(fullfile(blockObj.VideoPars.Root,...
                            blockObj.VideoPars.FilePath,...
                            blockObj.VideoPars.File{iV})); %#ok<TNMLP>
                         
   propNames = properties(V);
   Props{iV} = struct;
   for iP = 1:numel(propNames)
      Props{iV}.(propNames{iP}) = V.(propNames{iP});
   end
   
end
clear V
blockObj.VideoPars.Props = Props;

flag = true;

end

