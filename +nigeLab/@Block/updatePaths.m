function flag = updatePaths(blockObj,SaveLoc)

%% Script to update the path tree of the block Object.
% generates a new path tree starting from the SaveLoc input and moves any
% files found in the old path to the new one.
% in order to match the old path with the new one the Paths struct in
% object is used. The script detects any variablke part of the name (eg %s)
% and replicates it in the new file. This means that if the old file had
% two variable parts, typically probe and channels, the new one must have
% two varible parts as well.
%
% This is a problem only when changing the naming in the defaults params.

flag = false;

if nargin ==2
   blockObj.Paths.SaveLoc = SaveLoc;
end

% Get old paths
OldP = blockObj.Paths;
OldFN = fieldnames(OldP);
OldFN(strcmp(OldFN,'SaveLoc'))=[];

% generate new paths
blockObj.genPaths(fileparts(blockObj.Paths.SaveLoc));
P = blockObj.Paths;

% look for old data to move
for jj=1:numel(OldFN)
   
   moveFiles(OldP.(OldFN{jj}).file, P.(OldFN{jj}).file);
   moveFiles(OldP.(OldFN{jj}).info,P.(OldFN{jj}).info);
   
   
end

blockObj.linkToData;
blockObj.save;
flag = true;

end
function moveFiles(oldPath,NewPath)
oldPathSplit = regexpi(oldPath,'%[\w\W]*?[diuoxfegcs]','split');
newPathSplit = regexpi(NewPath,'%[\w\W]*?[diuoxfegcs]','split');
source_ = dir([oldPathSplit{1} '*']);
numVarParts = numel(strfind(oldPath,'%'));
for kk = 1:numel(source_)
   source = fullfile(source_(kk).folder,source_(kk).name);
   offs=1;
   ind=[];VarParts={};
   for hh=1:numVarParts
      tmp = strfind(source(offs:end),oldPathSplit{hh}) + length(oldPathSplit{hh});
      ind(1,hh) = offs -1 + tmp(1);
      offs = ind(1,hh);
      tmp = strfind(source(offs:end),oldPathSplit{hh+1})-1;
      if isempty(tmp)
         tmp=length(source(offs:end));
      end
      ind(2,hh) = offs -1 + tmp(1);
      offs = ind(2,hh);
      VarParts{hh} = source(ind(1,hh):ind(2,hh));
   end
   target = fullfile( sprintf(strrep(strjoin(newPathSplit, '%s'),'\','/'),  VarParts{:}));
   [status,msg] = movefile(source,target);
end
end