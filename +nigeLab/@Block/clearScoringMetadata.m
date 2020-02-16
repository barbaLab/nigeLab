function clearScoringMetadata(blockObj,fieldName)
%CLEARSCORINGMETADATA  Deletes 'Scoring' table for 'fieldName'
%  'fieldName'. This can be used to get the 'tic' for a particular table
%  entry, to track the total time spent.
%
%  clearScoringMetadata(blockObj,fieldName);
%
%  inputs- 
%  blockObj : nigeLab.Block class object
%  fieldName : Name of field to score (e.g. 'Video'). Acts as an index into
%              struct property Scoring (e.g. blockObj.Scoring.(fieldName))
%
%  Removes the field `fieldName` from blockObj.Scoring

if ~isfield(blockObj.Scoring,fieldName)
   if blockObj.Verbose
      nigeLab.sounds.play('pop',0.5);
      dbstack();
      nigeLab.utils.cprintf('Errors*','\t\t->\t[CLEARSCORINGMETADATA]: ');
      nigeLab.utils.cprintf('Errors',...
         '(Block %s) -- No such Scoring field: %s\n',...
         blockObj.Name,fieldName);
   end
   return;
end

if isstruct(blockObj.Scoring.(fieldName))
   if ~isfield(blockObj.Scoring.(fieldName),'Toc')
      if blockObj.Verbose
         nigeLab.sounds.play('pop',0.5);
         dbstack();
         nigeLab.utils.cprintf('Errors*','\t\t->\t[CLEARSCORINGMETADATA]: ');
         nigeLab.utils.cprintf('Errors',...
            '(Block %s) -- Scoring field ''%s'' is struct but missing .Toc field\n',...
            blockObj.Name,fieldName);
      end
      return;
   end
   iClean = false(size(blockObj.Scoring.(fieldName)));
   
   for i = 1:numel(iClean)
      iClean(i) = blockObj.Scoring.(fieldName)(i).Toc == 0;
   end
   blockObj.Scoring.(fieldName)(iClean) = [];
elseif istable(blockObj.Scoring.(fieldName))
   if ~ismember('Toc',blockObj.Scoring.(fieldName).Properties.VariableNames)
      if blockObj.Verbose
         nigeLab.sounds.play('pop',0.5);
         dbstack();
         nigeLab.utils.cprintf('Errors*','\t\t->\t[CLEARSCORINGMETADATA]: ');
         nigeLab.utils.cprintf('Errors',...
            '(Block %s) -- Scoring field ''%s'' is table but missing .Toc Variable\n',...
            blockObj.Name,fieldName);
      end
      return;
   end
   
   iClean = blockObj.Scoring.(fieldName).Toc == 0;
   blockObj.Scoring.(fieldName)(iClean,:) = [];
else
   blockObj.Scoring = rmfield(blockObj.Scoring,fieldName);
end

end