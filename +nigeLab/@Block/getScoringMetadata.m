function info = getScoringMetadata(blockObj,fieldName,scoringID)
%GETSCORINGMETADATA  Returns table row corresponding to 'scoringID' for
%  'fieldName'. This can be used to get the 'tic' for a particular table
%  entry, to track the total time spent.
%
%  info = getScoringMetadata(blockObj,fieldName,scoringID);
%
%  inputs- 
%  blockObj : nigeLab.Block class object
%  fieldName : Name of field to score (e.g. 'Video'). Acts as an index into
%              struct property Scoring (e.g. blockObj.Scoring.(fieldName))
%  scoringID : Unique 16-digit alphanumeric hash corresponding to table row
%
%  outputs-
%  info : Table row for a given scoring run


info = [];
if ~isstruct(blockObj.Scoring)
   return;
end

if ~isfield(blockObj.Scoring,fieldName)
   return;
end

% If only 2 inputs, see if it is possible to match the combo of 'user' and
% 'date' for the scoring of this block. Otherwise just return empty.
if nargin < 3
   if isfield(blockObj.Pars,fieldName)
      s = blockObj.Scoring.(fieldName);
      v = s.Properties.VariableNames;
      td = nigeLab.utils.getNigelDate();
      if (isfield(blockObj.Pars.(fieldName),'User')) && ...
            (all(ismember({'User','Date'},v)))
         u = blockObj.Pars.(fieldName).User;
         idx = strcmp(s.Date,td) & strcmpi(s.User,u);
         if sum(idx) == 0
            return;
         end
         idx = find(idx,1,'last'); % Only retrieve 1 row at most
         scoringID = blockObj.Scoring.(fieldName).Properties.RowNames(idx);
      else
         return;         
      end
   else
      return;
   end
end

info = blockObj.Scoring.(fieldName)(scoringID,:);

end