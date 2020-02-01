%% nigeLab - Demo command line
clear
clc

% Check current path and if "inside" the package, move to top-level
nigelPath = pwd;
if contains(nigelPath,'+nigeLab')
   disp('Matlab `Current Folder` is inside +nigeLab. Moving out.');
   nigelPath = nigelPath(1:(regexp(nigelPath,'+nigeLab')-1));
   cd(nigelPath);
end
L = import; % Make sure it is not imported from previous `import` call
if ~ismember('nigeLab.*',L)
   import nigeLab.*;
   L = import; % Double-check if it was imported successfully
   if ~ismember('nigeLab.*',L)  % Throw error if still cannot find it
      error(['nigeLab:' mfilename ':BadPath'],...
         ['Please ensure +nigeLab is on search path\n' ...
         '\t->\t(Current Folder: %s)\n'],pwd);
   else % Otherwise we successfully imported it; move to top-level folder
      nigelPath = nigeLab.utils.getNigelPath();
      cd(nigelPath);
   end
end
demoPath = fullfile(nigelPath,'+nigeLab','setup','demo');

% Get input data path
inputPath = fullfile(demoPath,'myTank');
% unzip data if needed
if ~exist(inputPath,'dir')
   unzip(fullfile(inputPath,'myTank.zip'));
end

% Get output location and make folder if needed
outputPath = fullfile(demoPath,'demo_experiment');
if ~exist(outputPath,'dir')
   mkdir(outputPath);
end

%% create a tank object 
% you will be asked to select the source (myTank) and destination (you can 
% choose every folder, we suggest to use `'demo_experiment'`) 
tankObj = nigeLab.Tank(inputPath,outputPath); 

% this will create a tank object with all the linked metadata and will save
% it in the destination folder. check the folder tree that was created. If
% anything looks wrong, please refer to documentation at the wiki page:
%
%  https://github.com/m053m716/ePhys_packages/wiki/Startup_Init

% prompt user to proceed with extraction
str = nigeLab.utils.uidropdownbox(...
   'Run Extraction?','Proceed with `doRawExtraction`?',{'Yes','No'},false);
if strcmp(str,'No')
   return;
end

%% extract raw data and save it in the corresponding folder
% --> (on all Animals and Blocks within Tank)
tankObj.doRawExtraction;
linkToData(tankObj);

% prompt user to proceed with filtering
str = nigeLab.utils.uidropdownbox(...
   'Run Spike Filter?','Proceed with `doUnitFilter`?',{'Yes','No'},false);
if strcmp(str,'No')
   return;
end

%% Perform multi-unit bandpass filter for spike detection 
% --> (on all Animals and Blocks within Tank)
tankObj.doUnitFilter
linkToData(tankObj);

% prompt user to proceed with re-reference
str = nigeLab.utils.uidropdownbox(...
   'Run Virtual Re-Reference?','Proceed with `doReReference`?',...
   {'Yes','No'},false);
if strcmp(str,'No')
   return;
end

%% Perform common-average re-reference
% --> (on only the first Animal (for example))
animalObj = tankObj{1};
doReReference(animalObj);
linkToData(tankObj);

% Prompt user to proceed with spike detection
str = nigeLab.utils.uidropdownbox(...
   'Detect Spikes?','Proceed with `doSD`?',{'Yes','No'},false);
if strcmp(str,'No')
   return;
end

%% Perform spike detection and feature extraction (wavelet decomposition)
% --> (on only the third Block of the second Animal)
blockObj = tankObj{2,3};
doSD(blockObj);
linkToData(blockObj);

% Prompt user to proceed with LFP extraction
str = nigeLab.utils.uidropdownbox(...
   'Do Auto-Clustering?','Proceed with `doAutoClustering`?',...
   {'Yes','No'},false);
if strcmp(str,'No')
   return;
end

%% Perform auto-clustering on detected spikes
% --> (on only the third Block of the second Animal)
doAutoClustering(blockObj);
linkToData(blockObj);

% Prompt user to proceed with LFP extraction
str = nigeLab.utils.uidropdownbox(...
   'Do LFP Decimation?','Proceed with `doLFPExtraction`?',...
   {'Yes','No'},false);
if strcmp(str,'No')
   return;
end

%% Down-sample raw data to LFP
% --> (on only the first Block of the first Animal and 2nd/3rd Blocks of 2nd Animal)
blockObj = tankObj{[1,2],{1,[2,3]}};
doLFPExtraction(blockObj);
linkToData(blockObj);
nigeLab.sounds.play('bell',1.5);
