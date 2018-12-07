function flag = doVidInfoExtraction(blockObj,vidFileName)
%% DOVIDINFOEXTRACTION   Get video metadata for associated behavioral vids
%
%  flag = DOVIDINFOEXTRACTION(blockObj);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class object from orgExp package.
%
%  vidFileName :     (Optional) String of video full file name.
%
%  --------
%   OUTPUT
%  --------
%     flag     :     Boolean logical operator to indicate whether
%                     synchronization
%
%
% Adapted from CPLTools By: Max Murphy  v1.0  12/05/2018 version (R2017b)

%% DEFAULTS
flag = false;
blockObj.VidPars = orgExp.defaults.Video;
if exist(blockObj.VidPars.Root,'dir')~=0
   defPath = blockObj.VidPars.Root;
elseif exist(blockObj.VidPars.AltRoot,'dir')~=0
   defPath = blockObj.vidPars.AltRoot;
else
   defPath = [];
end
blockObj.VidPars.Root = defPath;

%% GET VIDEO FILE(S)
if nargin < 2
   [fName,pName, ~] = uigetfile(blockObj.VidPars.FileExt,...
      'Select VIDEO', blockObj.VidPars.Root);
else
   [fName,pName,ext] = fileparts(vidFileName);
   fName = [fName ext];
   blockObj.VidPars.FileType = ['.' ext];
end
if fName==0
   disp('No video selected.');
   return;
end

blockObj.VidPars.FilePath = pName((numel(blockObj.VidPars.Root)+1):end);
blockObj.VidPars.FileName = fName;

%% PARSE VARIABLES FROM FILE NAME
match_str = parseVidFileName(blockObj,fName,true);

%% MATCH AND FIND OTHER VIDEOS WITH SAME NAME CONVENTION
F = dir(fullfile(pName,match_str));
name = {F.name}.';
F(ismember(name,fName)) = [];
for iF = 1:numel(F)
   parseVidFileName(blockObj,F(iF).name);
end

%% FOR EACH FILE, EXTRACT VIDEO INFORMATION OF INTEREST
flag = updateVidInfo(blockObj);

   function match_str = parseVidFileName(blockObj,fName,initFlag)
      %% PARSEVIDFILENAME  Get video file info from video file
      
      if nargin < 3
         initFlag = false;
      end
      
      [~,str,~] = fileparts(fName);
      strVars = strsplit(str,blockObj.VidPars.Delimiter);
      n = min(numel(strVars),numel(blockObj.VidPars.DynamicVars));
      
      meta = struct;
      match_str = strVars{1};
      meta.(blockObj.VidPars.DynamicVars{1}(2:end)) = strVars{1};
      
      for ii = 2:n
         meta.(blockObj.VidPars.DynamicVars{ii}(2:end)) = strVars{ii};
         if strcmp(blockObj.VidPars.DynamicVars{ii}(1),blockObj.VidPars.IncludeChar)
            match_str = strjoin({match_str strVars{ii}},'*');
         end
      end
      
      if initFlag
         blockObj.VidPars.Meta = struct2table(meta);
      else
         blockObj.VidPars.Meta = [blockObj.VidPars.Meta; ...
            struct2table(meta)];
      end
      
      blockObj.VidPars.File = [blockObj.VidPars.File; {fName}];
      
      match_str = [match_str blockObj.VidPars.FileExt];
   end

end

