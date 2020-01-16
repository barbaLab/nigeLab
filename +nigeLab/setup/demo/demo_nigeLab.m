%% nigeLab - Demo command line
clear
clc

% Change the current folder to the folder of this m-file.
if(~isdeployed)
  cd(fileparts(which(mfilename)));
end

% unzip data
if ~exist('myTank','dir'), unzip('myTank.zip');end
% create destination folder for analysis
mkdir('demo_experiment')

%% create a tank object 
% you will be asked to select the source (myTank) and destination (you can 
% choose every folder, we suggest to use myTank_anamysis) 
tankobj = nigeLab.Tank(fullfile(pwd,'myTank'),fullfile(pwd,'demo_experiment')); 

% this will create a tank object with all the linked metadata and will save
% it in the destination folder. check the folder tree that was created. If
% anything looks wrong, please refer to Initialize_Data_Structure wiki page
% on github.

%% extract raw data and save it in the corresponding folder
tankobj.doRawExtraction;

%% Perform multi-unit bandpass filter for spike detection for all Animals and Blocks within Tank.
tankobj.doUnitFilter

%% Perform common-average re-reference for all Animals and Blocks within Tank.
tankobj.doReReference

%% Perform spike detection and feature extraction (wavelet decomposition)
%% on all Animals and all Blocks within the Tank
tankobj.doSD

%% downsample raw data to LFP
tankobj.doLFPExtraction;

%% 