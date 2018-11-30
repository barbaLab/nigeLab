%% CLEAR WORKSPACE
clear; clc;

%% DEFAULTS
saveLoc = 'P:\Extracted_Data_To_Move\Rat\Intan\R18-68';
recFileName = 'R:\Rat\Intan\R18-68\R18-68_2018_07_24_1_180724_141452.rhd';
bkName = 'R18-68_2018_07_24_1';

%% MAKE BLOCK AND EXTRACT
b = orgExp.Block('RecFile',recFileName,'SaveLoc',saveLoc);
% linkToData(b);
qRawExtraction(b);