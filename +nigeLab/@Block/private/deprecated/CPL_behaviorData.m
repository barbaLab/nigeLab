function behaviorData = CPL_behaviorData(varargin)
%% CPL_BEHAVIORDATA  UI for selecting behavior data from a block
%
%  behaviorData = CPL_BEHAVIORDATA('NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  varargin       :  (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  behaviorData   :  Table with reach onset, grasp onset, outcome, and hand
%                    used.
%
% By: Max Murphy  v1.0  05/15/2018  Original version (R2017b)

%% DEFAULTS
DIR = nan;
DEF_DIR = 'P:\Rat\BilateralReach\Murphy';

EXCEL_ID = '_Scoring.xlsx';
EVENT_ID = '_tEvent.mat';
%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET RECORDING BLOCK
if isnan(DIR)
   DIR = uigetdir(DEF_DIR,'Select recording BLOCK');
   if DIR == 0
      error('No BLOCK selected. Script aborted.');
   end
   
else % Parse format
   if strcmp(DIR(end),'/') || strcmp(DIR(end),'\')
      DIR = DIR(1:end-1);
   end
end

name = strsplit(DIR,filesep);
name = name{end};

%% GET BEHAVIORDATA
fname = fullfile(DIR,[name EXCEL_ID]);
if exist(fname,'file')==0
   error('%s has not been created yet. Have you run CPL_optiSync and CPL_getButtonSync?',fname);
   
else
   ename = fullfile(DIR,[name EVENT_ID]);
   if exist(ename,'file')==0
      error('%s does not exist, although it should. Re-run CPL_optiSync and CPL_getButtonSync. Do overwrite when prompted.',ename);
   else
      load(ename,'tEvent');
   end
   
   behaviorData = CPL_readBehavior(fname,tEvent);
   
end

end