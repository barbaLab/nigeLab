function [csvFullName,metaName,formatSpec] = getVideoFileList(blockObj,trialVideoStatus)
%GETVIDEOFILELIST  Returns name of .csv file and table field of .Meta
%
%  [csvFullName,metaName,formatSpec] = getVideoFileList(blockObj);
%  --> Uses blockObj.HasVideoTrials to parse `trialVideoStatus`
%  * csvFullName : Full filename to .csv table file
%  * metaName : Name of field in blockObj.Meta corresponding to table
%  * formatSpec : Format for reading from *.csv table
%
%  [...] = getVideoFileList(blockObj,trialVideoStatus);
%  --> Manually set trial video status

% updateParams(blockObj,'Video','Direct');   % Uncomment this if getting
                                             % error of missing parameter, 
                                             % but it will run slower if 
                                             % this is left uncommented

if nargin < 2
   trialVideoStatus = blockObj.HasVideoTrials;
end

if trialVideoStatus
   csvName = blockObj.Pars.Video.TrialVideoListFile;
   metaName = 'TrialVideo';
   formatSpec = '%s%s%s%s%s%s%s%s%[^\n\r]';
else
   csvName = blockObj.Pars.Video.OriginalVideoListFile;
   metaName = 'Video';
   formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';
end
csvFullName = fullfile(blockObj.Paths.Video.dir,csvName);

end