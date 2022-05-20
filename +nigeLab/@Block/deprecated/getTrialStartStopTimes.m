function [tStart,tStop] = getTrialStartStopTimes(blockObj,optStart,optStop)
%GETTRIALSTARTSTOPTIMES  Returns neural times of "trial" start and stop times
%
%  [tStart,tStop] = getTrialStartStopTimes(blockObj);
%  --> Returns start and stop times (seconds; neural record) of trials.
%      Rows of each column vector correspond to each other. Uses
%      blockObj.Pars.Video.StartExportVariable and
%      blockObj.Pars.Video.StopExportVariable for `optStart` and `optStop`
%      as defaults, respectively.
%
%  [...] = getTrialStartStopTimes(blockObj,optStart,optStop);
%  --> Manually specify `optStart` and `optStop`, the scored variable names
%      of 'EventTimes' variables to use for start and stop times of
%      individual trials instead of parsing from 'trial-running' (or
%      equivalent) flag transitions from low-to-high and high-to-low,
%      respectively.
%  
%  example:
%  ```
%     [trialStarts,trialStops] = getTrialStartStopTimes(...
%        blockObj,'Init','Complete');
%  ```

% Video parameters
pars = blockObj.Pars.Video;
% Detection stream parameters
detPars = blockObj.Pars.Event.TrialDetectionInfo;

if nargin < 3
   optStop = pars.StopExportVariable;
end

if nargin < 2
   optStart = pars.StartExportVariable;
end

% Parse start times from optional start variable OR from 'Trials'
v = pars.VarsToScore;
preBuffer = pars.PreTrialBuffer;
if ismember(optStart,v)
   tStart = getEventData(blockObj,blockObj.ScoringField,'ts',optStart);
else
   tStart = blockObj.Trial;
end
tStart =  tStart - preBuffer;

% Parse stop times from optional stop variable AND from "end of trial"
% indicator: in some instances, he may leave his paw out of the box for a
% long time so we flag "Complete" as `inf`, but the trial still technically
% has a completion time, and we would still like to export that video
% probably.
trial = getStream(blockObj,detPars.Name);
postBuffer = pars.PostTrialBuffer;
if ismember(optStop,v)
   trialCompletions = getEventData(blockObj,blockObj.ScoringField,'ts',optStop);
   trialCompletions = trialCompletions + postBuffer;
else
   trialCompletions = inf(size(tStart));
end
tStop = nigeLab.utils.binaryStream2ts(trial.data,trial.fs,...
      detPars.Threshold,'Falling',detPars.Debounce);
tStop = tStop + postBuffer;
if numel(tStop)~=numel(tStart)
   if blockObj.Verbose
      warning(['nigeLab:' mfilename ':BadTrialStructure'],...
         ['\t\t->\t<strong>[GETTRIALSTARTSTOPTIMES]</strong>: ' ...
         'Number of tStart (%g) does not equal number of tStop (%g)'],...
         numel(tStart),numel(tStop));
   end
   keepvec = true(size(trialCompletions));
   for i = 1:numel(trialCompletions)
      if ~isinf(trialCompletions(i))
         continue;
      end
      tDiff = tStop - tStart(i);
      tDiff(tDiff > 0) = [];
      if isempty(tDiff)
         keepvec(i) = false;
      else
         trialCompletions(i) = min(tDiff);
      end
   end 
   tStop = trialCompletions;
   tStop(~keepvec) = [];
else % If the same size, just use any that are not inf
   idx = ~isinf(trialCompletions);
   tStop(idx) = trialCompletions(idx);
end

end