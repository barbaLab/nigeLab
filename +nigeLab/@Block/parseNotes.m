function parseNotes(blockObj,str)
%PARSENOTES  Update metadata using "notes" string.
%
%  blockObj.parseNotes(str);
%
% See also: nigeLab, nigeLab.Block, nigeLab.libs, nigeLab.libs.NotesUI

%Parse experimental metadata
probes = struct;
if isempty(blockObj.Notes)
   blockObj.Notes = struct;
end

for ii = 1:size(str,1)
   % Catch whitespace errors
   if isempty(str{ii})
      continue;
   elseif strcmpi(str{ii},'')
      continue;
   end
   
   % Split based on Experiment Parameters
   info = strsplit(str{ii},blockObj.Pars.Experiment.Delimiter);
   varName = strtrim(info{1});
   varValue = strtrim(info{2});
   if contains(varName,'.')
      varNameParts = strsplit(varName,'.');
      tmp = varValue;
      tmp2 = struct;
      for ik = numel(varNameParts):-1:1
         tmp2.(varNameParts{ik}) = tmp;
         tmp = tmp2;
      end
      blockObj.Notes.(varNameParts{1}) = tmp;
   else
      blockObj.Notes.(varName) = varValue;
      probes = parseProbeName(probes,varName,varValue,...
         blockObj.Pars.Probe.ProbeIndexParseFcn);
   end
end

blockObj.Notes.Probes = probes;


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