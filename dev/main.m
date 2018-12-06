%% CLEAR WORKSPACE
clear; clc;

%% DEFAULTS
saveLoc = 'P:\Extracted_Data_To_Move\Rat\Intan\R18-68';
recFileName = 'R:\Rat\Intan\R18-68\R18-68_2018_07_24_1_180724_141452.rhd';

%% MAKE BLOCK AND EXTRACT
b = orgExp.Block('RecFile',recFileName,'SaveLoc',saveLoc);
linkTic = tic; linkToData(b); linkToc = toc(linkTic);
rawTic = tic; doRawExtraction(b);  rawToc = toc(rawTic);
filtTic = tic; doUnitFilter(b); filtToc = toc(filtTic);     
refTic = tic; doReReference(b); refToc = toc(refTic);    
sdTic = tic; doSD(b); sdToc = toc(sdToc);             
lfpTic = tic; doLFPExtraction(b); lfpToc = toc(lfpTic);

%% OUTPUT TIMES
fprintf(1,'\n  LINK |  RAW  |  FILT  |  REF  |  SD  |  LFP  \n');
fprintf(1,  '-----------------------------------------------');
fprintf(1,  ' %gs   | %gs   | %gs    | %gs   | %gs  | %gs   \n',...
            linkToc,rawToc,filtToc,refToc,sdToc,lfpToc);
