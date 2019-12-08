function [fname,data] = behaviorData2BlockEvents(behaviorData,f_out,f_str)
%% BEHAVIORDATA2BLOCKEVENTS  Convert behaviorData table to EVENT data files
%
%  nigeLab.workflow.behaviorData2BlockEvents(behaviorData,f_out,f_str);
%
%  Inputs:
%     --> behaviorData  : Matlab table where each row is a behavioral Trial
%     --> f_out  :  Location where file should be saved
%     --> f_str  :  Naming convention string

%%
if nargin < 3
   f_str = 'Curated_%s_Events.mat';
end

iMetadata = behaviorData.Properties.UserData > 1;
nFile = sum(~iMetadata) + 1; % plus 1 "header"
nEvent = size(behaviorData,1);

% Init data output
fname = cell(nFile,1);
data = cell(nFile,1);

% Make meta "header" first
fname{1} = nigeLab.utils.getUNCPath(fullfile(f_out,sprintf(f_str,'Header')));
data{1} = nigeLab.utils.initEventData(1,sum(iMetadata),2);
data{1}(1,5:end) = behaviorData.Properties.UserData(iMetadata);

% make "Trial" (special Event type)
fname{2} = nigeLab.utils.getUNCPath(fullfile(f_out,sprintf(f_str,'Trial')));
data{2} = nigeLab.utils.initEventData(nEvent,sum(iMetadata),1);
data{2}(:,4) = behaviorData.Trial;
data{2}(:,5:end) = table2array(behaviorData(:,iMetadata));

% make the rest of the Event files
varName = setdiff(behaviorData.Properties.VariableNames(~iMetadata),'Trial');
if numel(varName) ~= (nFile - 2)
   error('Weird number of variables.');
end
for i = 1:numel(varName)
   fname{i+2} = nigeLab.utils.getUNCPath(fullfile(f_out,sprintf(f_str,varName{i})));
   data{i+2} = nigeLab.utils.initEventData(nEvent,0,1);
   data{i+2}(:,4) = behaviorData.(varName{i});
end


end