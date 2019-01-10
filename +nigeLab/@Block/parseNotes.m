function parseNotes(blockObj,str)
%% PARSENOTES  Update metadata using notes
%
%  blockObj.parseNotes(str);
%
% By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)
%                 v1.1  12/11/2018  Bugfixes

%% PARSE EXPERIMENTAL METADATA
probes = struct;
for ii = 1:size(str,1)
   info = strsplit(str{ii},blockObj.ExperimentPars.Delimiter);
   blockObj.ExperimentPars.(strtrim(info{1})) = strtrim(info{2});
   probes = parseProbeName(probes,info{1},info{2},...
                           blockObj.ProbePars.ProbeIndexParseFcn);
   
end
blockObj.ExperimentPars.Probes = probes;

   function probes = parseProbeName(probes,varName,varValue,idxParseFcn)
      strParts = strsplit(varName,'_');
      if numel(strParts) > 1
         probeID = strParts{1};
         probeName = strParts{2};
         if numel(probeID >= 5)
            if strcmpi('probe',probeID(1:5))
               idx = idxParseFcn(probeName);
               probes.(probeName) = struct('name',varValue,'stream',idx);
            end
         end
      end
   end

end