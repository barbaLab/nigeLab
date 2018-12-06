%% CLEAR WORKSPACE
clear; clc;

%% DEFAULTS
saveLoc = 'P:\Extracted_Data_To_Move\Rat\Intan\R18-68';
recFileName = 'R:\Rat\Intan\R18-68\R18-68_2018_07_24_1_180724_141452.rhd';

%% MAKE BLOCK AND EXTRACT
b = orgExp.Block('RecFile',recFileName,'SaveLoc',saveLoc);

rawTic = tic; doRawExtraction(b);  rawToc = toc(rawTic);
filtTic = tic; doUnitFilter(b); filtToc = toc(filtTic);     
refTic = tic; doReReference(b); refToc = toc(refTic);    
sdTic = tic; doSD(b); sdToc = toc(sdTic);             
lfpTic = tic; doLFPExtraction(b); lfpToc = toc(lfpTic);

linkTic = tic; linkToData(b); linkToc = toc(linkTic);

%% OUTPUT TIMES
clc;
fprintf(1,'\n\t\tLINK\t\t|\t\tRAW\t\t\t|\t\tFILT\t\t|\t\tREF\t\t\t|\t\tSD\t\t\t|\t\tLFP\t\t\n');
fprintf(1,  '------------------------------------------------------------------------------------------------------------------------\n');
fprintf(1,  '\t\t%.4gs\t\t|\t\t%.4gs\t\t|\t\t%.4gs\t\t|\t\t%.4gs\t\t|\t\t%.4gs\t\t|\t\t%.4gs\t\t\n',...
            linkToc,rawToc,filtToc,refToc,sdToc,lfpToc);
