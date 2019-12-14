%% BATCH_ADD_TABLE_VAR  Batch script to add variable to behaviorData tables

%% Load list of blocks
clc;
if exist('block','var')==0
   clear;
   load('RC-BehaviorData-Update.mat','block');
end

for ii = 1:numel(block)
   if exist(fullfile(block(ii).folder,block(ii).name),'dir')==0
      continue;
   end
   
   F = dir(fullfile(block(ii).folder,block(ii).name,[block(ii).name '_Digital'],...
      [block(ii).name '_Scoring.mat']));
   if isempty(F)
      continue;
   end
   load(fullfile(F(1).folder,F(1).name),'behaviorData');
   behaviorData = utils.addTableVar(behaviorData,'Stereotyped',8,3,...
      zeros(size(behaviorData,1),1));
   save(fullfile(F(1).folder,F(1).name),'behaviorData','-v7.3');
end

