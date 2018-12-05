function CPL_plotSlowPotentials(behaviorData,varargin)
%% CPL_PLOTSLOWPOTENTIALS  Plot average RAW (or filtered) LFP.
%
%  CPL_plotSlowPotentials(behaviorData);
%  CPL_plotSlowPotentials(behaviorData,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  behaviorData   :  From CPL_READBEHAVIOR. Data table containing times and
%                                           trial outcomes / grouping
%                                           variable for trials.
%
%  --------
%   OUTPUT
%  --------
%  Plots out ensemble-averaged slow potentials for each channel and
%  alignment condition.
%
% By: Max Murphy  v1.0  05/07/2018  Original version (R2017b)

%% DEFAULTS
DIR = nan;

DEF_DIR = 'P:\Rat\BilateralReach\Murphy';
RAW_DIR = '_RawData';
RAW_ID = '_Raw_';

E_PRE = 1.0;
E_POST = 0.5;

YLIM = [-50 50];
XLIM = [-E_PRE E_POST];
LOWPASS = 10;  % Hz

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET DIRECTORY
if isnan(DIR)
   DIR = uigetdir(DEF_DIR,'Select recording BLOCK');
   if DIR == 0
      error('No recording BLOCK specified. Script aborted.');
   end
end

block = strsplit(DIR,filesep);
block = block{end};
F = dir(fullfile(DIR,[block RAW_DIR],['*' RAW_ID '*.mat']));

%% GET INDEXING FOR BEHAVIOR TYPES
iLeft = ismember(behaviorData.Forelimb,'L');
iRight = ismember(behaviorData.Forelimb,'R');

%% LOOP THROUGH AND LOOK AT ONE CHANNEL AT A TIME
% figure('Name', 'Slow Potentials Viewer',...
%        'Units','Normalized',...
%        'Color','w',...
%        'Position',[0 0 1 1]);
    
    
for ii = 1:numel(F)
   figure('Name',[block ': Channel ' num2str(ii-1,'%02g')],...
          'Color','w',...
          'NumberTitle','off',...
          'WindowStyle','docked');
       
   in = load(fullfile(F(ii).folder,F(ii).name));
   [b,a] = butter(4,2*LOWPASS/in.fs);
   data = filtfilt(b,a,double(in.data));    
   subplot(2,2,1);
   [avg,t,err] = CPL_getRawAverage(data,in.fs,behaviorData.Reach(iLeft),...
            'E_PRE',E_PRE,...
            'E_POST',E_POST);
   errorbar(t,avg,err);
   title('Reach - L');
   ylim(YLIM);
   xlim(XLIM);
   
   subplot(2,2,2);
   [avg,t,err] = CPL_getRawAverage(data,in.fs,behaviorData.Reach(iRight),...
            'E_PRE',E_PRE,...
            'E_POST',E_POST);
   errorbar(t,avg,err);
   ylim(YLIM);
   xlim(XLIM);
   title('Reach - R');
   
   
   subplot(2,2,3);
   [avg,t,err] = CPL_getRawAverage(data,in.fs,behaviorData.Grasp(iLeft),...
            'E_PRE',E_PRE,...
            'E_POST',E_POST);
   errorbar(t,avg,err);
   ylim(YLIM);
   xlim(XLIM);
   title('Grasp - L');
   
   subplot(2,2,4);
   [avg,t,err] = CPL_getRawAverage(data,in.fs,behaviorData.Grasp(iRight),...
            'E_PRE',E_PRE,...
            'E_POST',E_POST);
   errorbar(t,avg,err);
   ylim(YLIM);
   xlim(XLIM);
   title('Grasp - R');
   
   suptitle([strrep(block,'_','-') ': Channel ' num2str(ii-1,'%02g')]);
end

end