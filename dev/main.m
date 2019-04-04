%% CLEAR WORKSPACE
clear; clc;
fold = fileparts(mfilename('fullpath'));
%% DEFAULTS
saveLoc = fullfile(fold,'expmpl');
recFileName = fullfile(fold,'exmpl','R18-04_Basal1_180525_135852.rhs');

%% MAKE BLOCK AND EXTRACT
b = nigeLab.Block('RecFile',recFileName,'SaveLoc',saveLoc);

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

%% Dependencies
fold = fileparts(fold);
D = dir(fullfile(fold,'+nigeLab','*\*.m'));   % looks for mfiles
D = [D; dir(fullfile(fold,'+nigeLab','*\*\*.m'))];   % looks for private mfiles
funfolds = {D.folder};
funnames = {D.name};
paths = cellfun(@fullfile,funfolds,funnames,'UniformOutput', false);
names = dependencies.toolboxDependencyAnalysis(paths) ;
fprintf(1,'Necessary toolboxes to run the pipeline are:\n');
for ii=1:numel(names)
   fprintf(1,'%s\n',names{ii});
end
