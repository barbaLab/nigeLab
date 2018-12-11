function parseNotes(blockObj,str)
%% PARSENOTES  Update metadata using notes
%
%  blockObj.parseNotes(str);
%
% By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)
%                 v1.1  12/11/2018  Bugfixes

%% PARSE EXPERIMENTAL METADATA
for ii = 1:size(str,1)
   info = strsplit(str{ii},blockObj.ExpPars.Delimiter);
   blockObj.ExpPars.(strtrim(info{1})) = strtrim(info{2});
end

end