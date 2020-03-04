function [csvFullName,metaName] = getVideoFileList(blockObj,trialVideoStatus)
%GETVIDEOFILELIST  Returns name of .csv file and table field of .Meta
%
%  [csvFullName,metaName] = getVideoFileList(blockObj);
%  --> Uses blockObj.HasVideoTrials to parse `trialVideoStatus`
%  * csvFullName : Full filename to .csv table file
%  * metaName : Name of field in blockObj.Meta corresponding to table
%
%  [...] = getVideoFileList(blockObj,trialVideoStatus);
%  --> Manually set trial video status

if nargin < 2
   trialVideoStatus = blockObj.HasVideoTrials;
else
   blockObj.HasVideoTrials = trialVideoStatus;
end

if trialVideoStatus
   csvName = blockObj.Pars.Video.TrialVideoListFile;
   metaName = 'TrialVideo';
else
   csvName = blockObj.Pars.Video.OriginalVideoListFile;
   metaName = 'Video';
end
csvFullName = fullfile(blockObj.Paths.Video.dir,csvName);

end