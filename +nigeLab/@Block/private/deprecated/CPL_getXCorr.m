function corr_data = CPL_getXCorr(varargin)
%% CPL_GETXCORR   Get cross correlations of all spike trains in a block.
%
%  CPL_GETXCORR;
%  CPL_GETXCORR('NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%                    -> 'BLOCK' [def: nan]; If not specified, UI prompts
%                                           for recording block folder.
%                                           Otherwise, specify as a string
%                                           path of that folder.
%
%  --------
%   OUTPUT
%  --------
%  corr_data   :     Cross-correlations between all spike trains in a given
%                    block.
%
% By: Max Murphy  v1.0  04/28/2018  Original version (R2017b)

%% DEFAULTS
BLOCK = nan;
DEF_DIR = 'P:\Rat\BilateralReach\Murphy';
SPIKE_DIR = '_wav-sneo_CAR_Spikes';
SORT_DIR = '_wav_sneo_SPC_CAR_Sorted';
SPIKE_ID = '*ptrain*.mat';
SORT_ID = '*sort*.mat';

CORR_ID = '_CorrData.mat';
FS = nan;
TLIM = [-250 250];     % Limits for binning vector (ms)
BIN = 5;               % Bin width (ms)

EPOCH = [nan, nan];  % Specify as values (in seconds) for start/stop times

AUTOSAVE = true;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET INPUT DATA
if isnan(BLOCK)
   BLOCK = uigetdir(DEF_DIR,'Select recording BLOCK');
   if BLOCK==0
      error('No block selected. Script canceled.');
   end   
end
name = strsplit(BLOCK,filesep);
name = name{end};
spk_dir = fullfile(BLOCK,[name SPIKE_DIR]);
F = dir(fullfile(spk_dir,SPIKE_ID));

%% LOAD ALL TIME SERIES
spk = cell(numel(F),1);
in = load(fullfile(spk_dir,F(1).name),'pars');
if ~isfield(in,'pars')
   if isnan(FS)
      error('No sampling frequency loaded or specified.');
   else
      fs = FS;
   end
else 
   fs = in.pars.FS;
end

if ~isnan(EPOCH(1))
   EPOCH = round(EPOCH * fs);
end

% Load spikes
for iF = 1:numel(F)
   in = load(fullfile(spk_dir,F(iF).name),'peak_train');
   ts = find(in.peak_train);
   spk{iF} = ts;   
end

% Load sorting (if present) and get multi-units
sort_dir = strrep(spk_dir,SPIKE_DIR,SORT_DIR);
if exist(sort_dir,'dir')~=0
   S = dir(fullfile(sort_dir,SORT_ID));
   for iS = 1:numel(S)
      in = load(fullfile(sort_dir,S(iS).name),'class');
      spk{iS}(in.class==1) = [];
   end
end

%% DO CROSS CORRELATION BATCH FOR THIS BLOCK

corr_data = [];

tic;

fprintf(1,'->\tCorrelating pairs from %s...',BLOCK);
for iTS_1 = 1:numel(F)
   for iTS_2 = 1:numel(F)
      if isnan(EPOCH(1))
         ts1 = spk{iTS_1};
         ts2 = spk{iTS_2};
      else
         ts1 = spk{iTS_1}(spk{iTS_1} >= EPOCH(1) & spk{iTS_1} <= EPOCH(2));
         ts2 = spk{iTS_2}(spk{iTS_2} >= EPOCH(1) & spk{iTS_2} <= EPOCH(2));
      end
      
      out = CPL_spikecorr(ts1,ts2,fs,...
         'SHOW_PROGRESS',false,...
         'TLIM',TLIM,...
         'BIN',BIN);

      out.fname = {F(iTS_1).name; F(iTS_2).name};

      out.block = BLOCK;
      corr_data = [corr_data; out]; %#ok<AGROW>
   end      
end   
fprintf(1,'complete.\n');

toc;

if AUTOSAVE
   params = struct;
   params.TLIM = TLIM;
   params.BIN = BIN; %#ok<STRNU>
   save(fullfile(BLOCK,[name CORR_ID]),'corr_data','params','-v7.3');
end

end