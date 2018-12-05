function behaviorData = restoreDeletedTrials(F,varargin)
%% RESTOREDELETEDTRIALS Use "_Trials.mat" to put "deleted" trials back into table with NaNs
%
%  behaviorData = RESTOREDELETEDTRIALS(F);
%  behaviorData = RESTOREDELETEDTRIALS(F,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     F     :     Struct containing 'folder' and 'name' fields that are
%                 strings referencing the file name of the _Scoring.mat
%                 file that has already been scored.
%
%  --------
%   OUTPUT
%  --------
%  behaviorData   :     Scoring table, which has the same information as
%                       from _Scoring.mat, but with the "deleted" trials
%                       restored (from _Trials.mat). Restored trials have
%                       NaN as a default value for each scoring variable.
%
% By: Max Murphy  v1.0  09/08/2018  Original version (R2017b)

%% DEFAULTS
TRIAL_OFFSET = -0.25; % Trial offset

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% LOAD BEHAVIOR AND TRIALS VARIABLES
load(fullfile(F.folder,F.name),'behaviorData');
load(fullfile(F.folder,strrep(F.name,'_Scoring','_Trials')),'trials');

%% FIND MISSING TRIAL TIMES
behaviorData.Trial = behaviorData.Trial - TRIAL_OFFSET; %#ok<NODEF>

current_trials = behaviorData.Trial;
restored_trials = setdiff(trials,current_trials);

%% ADD THE TABLE AND SORT IT BY 
varNames = behaviorData.Properties.VariableNames;

Trial = restored_trials;
b = table(Trial);
for ii = 2:numel(varNames)
   b = [b, table(nan(size(Trial)),'VariableNames',varNames(ii))]; %#ok<AGROW>
end

%% RETURN THE SORTED TABLE
behaviorData = [behaviorData; b];
behaviorData = sortrows(behaviorData);


end