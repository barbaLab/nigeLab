function trials = extractTrials(fname,varargin)
%% EXTRACTTRIALS     Extract candidate trial onsets for video scoring
%
%  EXTRACTTRIALS(fname)
%  EXTRACTTRIALS(fname,'NAME',value,...);
%  trials = EXTRACTTRIALS(fname,'NAME',value,...);  
%
%  --------
%   INPUTS
%  --------
%  fname          :  Paw data stream file name (full path).
%
%  varargin       :  (Optional) 'NAME', value input argument pairs.
%
%                    -> 'TRIAL_ID' [def: '_Trials.mat'] // Appended to end
%                                                          of output
%                                                          filename.
%
%  --------
%   OUTPUT
%  --------
%  Saves a N x 1 vector of candidate trial times that are derived from
%  de-bounced threshold crossings of the paw probability time-series. 
%  These candidate trials are then used by the scoreVideo
%  function to quickly go through potential reach trials from the videos.
%
%   trials        :  N x 1 vector of candidate trial times.
%
% By: Max Murphy  v1.0  09/01/2018  Original version (R2017b)

%% DEFAULTS
TRIAL_ID = '_Trials.mat';

THRESH = 0.15;
DB = 0.25;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% PARSE FILE NAME INFO AND LOAD OTHER DATA
name = strsplit(fname,'_');
name = strjoin(name(1:(end-1)),'_');
outname = [name TRIAL_ID];

try
   fprintf(1,'Loading paw... ');
   paw = load(fname);
   fprintf(1,'complete.\n');
catch
   warning(['\n->\tMissing %s.\n' ...
          '\tCheck that files are in correct location,\n' ...
          '\tor have correct naming convention.\n'],fname);
   trials = [];
   return;
end

%% COMPUTE POSSIBLE TRIAL TIMES
t = 0:(1/paw.fs):((numel(paw.data)-1)/paw.fs);

idx = find(paw.data >= THRESH);
idx = idx(diff([-inf,idx]) > 1); % Don't use consecutive parts above thresh

trials = reshape(t(idx),numel(idx),1);

ii = 2;
while ii <= numel(trials)
   if (trials(ii)-trials(ii-1))<DB
      trials(ii) = [];
   else
      ii = ii + 1;
   end
end

%% SAVE OUTPUT
save(outname,'trials','-v7.3');
   
end