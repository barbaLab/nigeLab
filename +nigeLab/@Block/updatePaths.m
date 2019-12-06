function flag = updatePaths(blockObj,saveLoc)
% UPDATEPATHS  Update the path tree of the Block object
%
%  flag = blockObj.updatePaths();
%  flag = blockObj.updatePaths(saveLoc);  Update blockObj.Paths.SaveLoc
%
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

if nargin == 2
   blockObj.Paths.SaveLoc = saveLoc;
end

% Get old paths, removing 'SaveLoc' from the list of Fields that need Paths
% found for them.
OldP = blockObj.Paths;
OldFN_ = fieldnames(OldP);
OldFN_(strcmp(OldFN_,'SaveLoc'))=[];
OldFN = [];

% generate new blockObj.Paths
blockObj.genPaths(fileparts(blockObj.Paths.SaveLoc.dir));
P = blockObj.Paths;


uniqueTypes = unique(blockObj.FieldType);

% look for old data to move
filePaths = [];
for jj=1:numel(uniqueTypes)
    if ~isempty(blockObj.(uniqueTypes{jj}))
        ff = fieldnames(blockObj.(uniqueTypes{jj})(1));
        
        fieldsToMove = ff(cellfun(@(x) ~isempty(regexp(class(x),'DiskData.\w', 'once')),...
            struct2cell(blockObj.(uniqueTypes{jj})(1))));
        OldFN = [OldFN;OldFN_(ismember(OldFN_,fieldsToMove))]; %#ok<*AGROW>
        for hh=1:numel(fieldsToMove)
            if all(blockObj.getStatus(fieldsToMove{hh}))
                filePaths = [filePaths; ...
                   cellfun(@(x)x.getPath,{blockObj.(uniqueTypes{jj}).(fieldsToMove{hh})},...
                    'UniformOutput',false)'];
            end %fi
        end %hh
    end %fi
end %jj

% moves all the files from folder to folder
for ii=1:numel(filePaths)
    source = filePaths{ii};
    [~,target] = strsplit(source,'\\\w*\\\w*.mat','DelimiterType', 'RegularExpression');
    target = fullfile(P.SaveLoc.dir,target{1});
    [status,msg] = nigeLab.utils.FileRename.FileRename(source,target);
end

% copy all the info files from one folder t the new one
for jj = 1:numel(OldFN)
%     moveFiles(OldP.(OldFN{jj}).file, P.(OldFN{jj}).file);
    moveFilesAround(OldP.(OldFN{jj}).info,P.(OldFN{jj}).info,'cp');
end
blockObj.linkToData;
blockObj.save;
flag = true;

end

function moveFilesAround(oldPath,NewPath,str)
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
            if isempty(tmp),tmp=length(source(offs:end));end
            ind(2,hh) = offs -1 + tmp(1);
            offs = ind(2,hh);
            VarParts{hh} = source(ind(1,hh):ind(2,hh));
        end % hh
        target = fullfile( sprintf(strrep(strjoin(newPathSplit, '%s'),'\','/'),  VarParts{:}));
        
        switch str
            case 'mv'
        [status,msg] = nigeLab.utils.FileRename.FileRename(source,target);
            case 'cp'
           [status,msg] = copyfile(source,target);     
        end %str
    end %kk
end
