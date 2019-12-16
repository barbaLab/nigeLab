function addScoringMetadata(blockObj,fieldName,info)
% ADDSCORINGMETADATA  Appends scoring metadata to Block record
%
%  blockObj.addScoringMetadata(fieldName,info);
%  % Adds table row in 'info' to table in blockObj.Scoring.(fieldName)
%
%  % example:
%  hashStr = nigeLab.utils.getHash();
%  T = table('FB',datestr(datetime,'YYYY-mm-dd'),'in progress',...
%     'VariableNames',{'User','Date','Status'},...
%     'RowNames',hashStr);
%  blockObj.addScoringMetadata('Video',T);  
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     nigeLab.Block class object
%
%  fieldName   :     Name of field in nigeLab.Block.Scoring to update.
%
%  info        :     Table entry to append to table in that field

%% Check that Scoring and Scoring.(fieldName) are initialized.
if ~isstruct(blockObj.Scoring)
   blockObj.Scoring = struct;
end

if ~isfield(blockObj.Scoring,fieldName)
   blockObj.Scoring.(fieldName) = table;
end

%% Assign using hashed row names
blockObj.Scoring.(fieldName)(info.Properties.RowNames,:) = info;

end