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
blockObj.checkActionIsValid();
blockObj.VideoPars = nigeLab.defaults.Video;
if exist(blockObj.VideoPars.Root,'dir')~=0
   defPath = blockObj.VideoPars.Root;
elseif exist(blockObj.VideoPars.AltRoot,'dir')~=0
   defPath = blockObj.vidPars.AltRoot;
else
   defPath = [];
end
blockObj.VideoPars.Root = defPath;

%% GET VIDEO FILE(S)
if nargin < 2
   [fName,pName, ~] = uigetfile(blockObj.VideoPars.FileExt,...
      'Select VIDEO', blockObj.VideoPars.Root);
else
   [fName,pName,ext] = fileparts(vidFileName);
   fName = [fName ext];
   blockObj.VideoPars.FileType = ['.' ext];
end
if fName==0
   disp('No video selected.');
   return;
end

blockObj.VideoPars.FilePath = pName((numel(blockObj.VideoPars.Root)+1):end);
blockObj.VideoPars.FileName = fName;

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
notify(blockObj,processCompleteEvent);

   function match_str = parseVidFileName(blockObj,fName,initFlag)
      %% PARSEVIDFILENAME  Get video file info from video file
      
      if nargin < 3
         initFlag = false;
      end
      
      [~,str,~] = fileparts(fName);
      strVars = strsplit(str,blockObj.VideoPars.Delimiter);
      n = min(numel(strVars),numel(blockObj.VideoPars.DynamicVars));
      
      meta = struct;
      match_str = strVars{1};
      meta.(blockObj.VideoPars.DynamicVars{1}(2:end)) = strVars{1};
      
      for ii = 2:n
         meta.(blockObj.VideoPars.DynamicVars{ii}(2:end)) = strVars{ii};
         if strcmp(blockObj.VideoPars.DynamicVars{ii}(1),blockObj.VideoPars.IncludeChar)
            match_str = strjoin({match_str strVars{ii}},'*');
         end
      end
      
      if initFlag
         blockObj.VideoPars.Meta = struct2table(meta);
      else
         blockObj.VideoPars.Meta = [blockObj.VideoPars.Meta; ...
            struct2table(meta)];
      end
      
      blockObj.VideoPars.File = [blockObj.VideoPars.File; {fName}];
      
      match_str = [match_str blockObj.VideoPars.FileExt];
   end

end

