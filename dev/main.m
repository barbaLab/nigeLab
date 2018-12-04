%% CLEAR WORKSPACE
clear; clc;

%% DEFAULTS
saveLoc = 'P:\Extracted_Data_To_Move\Rat\Intan\R18-68';
% saveLoc = 'P:\Extracted_Data_To_Move\Rat\Intan\R18-00';
recFileName = 'R:\Rat\Intan\R18-68\R18-68_2018_07_24_1_180724_141452.rhd';
% recFileName = 'R:\Rat\Intan\DEV\R18-00_2018_01_24_0_180124_165330.rhd';
% recFileName = 'R:\Rat\Intan\DEV\R18-00_2018-02-01_0_180201_184622.rhs';

%% MAKE BLOCK AND EXTRACT
b = orgExp.Block('RecFile',recFileName,'SaveLoc',saveLoc);
linkToData(b);
% qRawExtraction(b); % Working...yes. ~20 minutes
doRawExtraction(b);  % Working...yes. ~6 minutes (?)
doUnitFilter(b);     % Working...yes.
doReReference(b);    % Working...yes.
doSD(b);             % Working...?
doLFPExtraction(b);
