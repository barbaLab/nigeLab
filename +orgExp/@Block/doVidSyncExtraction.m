function flag = doVidSyncExtraction(blockObj)
%% DOVIDSYNCEXTRACTION   Get time-series for sync event cross-correlation
%
%  doBehaviorSync(blockObj);
%  doVidInfoExtraction(blockObj);
%  flag = DOVIDSYNCEXTRACTION(blockObj);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class object from orgExp package.
%
%  --------
%   OUTPUT
%  --------
%     flag     :     Boolean logical operator to indicate whether
%                     synchronization
%
%
% Adapted from CPLTools By: Max Murphy  v1.0  12/05/2018 version (R2017b)

%% DEFAULTS
flag = false;

% Code here will probably focus on isolating an ROI that contains an LED
% blinker. Therefore the defaults template could contain parameters
% associated with pixel coordinates for the ROI, based on the fixed camera
% location. There should also be defaults for the approximate levels to
% look for on the different color channels, in order to extract a
% time-series from the video for when the LED is on and off. 

% Ultimately, this will save a file ('_StreamSync.mat') in Metadata folder.
% 

end