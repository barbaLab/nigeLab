function [tEvent,sync,user] = CPL_optiSync(varargin)
%% CPL_OPTISYNC   Get event times from synchronized optiTrack record.
%
%  tEvent = CPL_OPTISYNC;
%  tEvent = CPL_OPTISYNC('NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%                    -> 'DIR' [def: NaN]; If specified, use as a string
%                                         path name to recording BLOCK
%                                         directory.
%
%  --------
%   OUTPUT
%  --------
%   tEvent     :     Event times struct for manually curating OptiTrack
%                    data in Motive around those time stamps to find reach
%                    or whatever you are tracking.
%
%    sync      :     Data struct containing OptiTrack sync from External
%                    Output on OptiHub.
%
%    user      :     Data struct containing data stream from Manual User
%                    Button Press. In the case of Bilateral Reach, it
%                    corresponds to times when the rat reached, which may
%                    mean different things depending on the Block (e.g.
%                    sometimes it is only pressed on alternating trials;
%                    sometimes it's pressed only for L- or R- paw for every
%                    reach attempt--look at notes).
%
% By: Max Murphy  v1.0  05/03/2018  Original version (R2017b)

%% DEFAULTS
% Path info
DIR = nan;
DEF_DIR = 'P:\Rat\BilateralReach\Murphy';
COMBINE = true;   % Flag to automatically prompt for CPL_getButtonSync info

% Lockout/de-bounce for button press
DEBOUNCE = 0.250; % seconds

% Identifier tokens
DIG_DIR = '_Digital';
DIG_ID = '_DIG';
SYNC_ID = '_sync.mat';
USER_ID = '_user.mat';


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

%% LOAD DATA
sync = load(fullfile(DIR,[name DIG_DIR],[name DIG_ID SYNC_ID]));
user = load(fullfile(DIR,[name DIG_DIR],[name DIG_ID USER_ID]));

%% GET SYNC DATA
tEvent = struct;

tEvent.name = name;
tEvent.block = DIR;

tEvent.tRecord = 0:(1/sync.fs):((numel(sync.data)-1)/sync.fs);


tEvent.sync = struct;
tEvent.sync.start = tEvent.tRecord(find(sync.data>0,1,'first'));
tEvent.sync.stop = tEvent.tRecord(...
   find(sync.data(tEvent.sync.start:end)<1,1,'first')+...
   find(sync.data>0,1,'first')-1);
if isempty(tEvent.sync.stop)
   warning('Movie was still recording at end of ePhys record.');
   tEvent.sync.stop = tEvent.tRecord(end);
end
tEvent.sync.units = 'seconds';

%% GET USER BUTTON PRESS DATA
tEvent.user = struct;

% Find where current sample is high and previous sample was low
bp = find(user.data > 0 & ([0, user.data(1:(end-1))] < 1));

% Convert debounce from seconds to samples
db = DEBOUNCE * user.fs;

% Exclude any button presses that occurred within the debounce period
bp = bp(diff([-inf, bp]) > db);

tEvent.user.raw = bp;
tEvent.user.shifted = tEvent.tRecord(bp) - tEvent.sync.start;

tEvent.T = cell(numel(bp),1);
for iT = 1:numel(tEvent.T)
   t_bp = tEvent.user.shifted(iT);
   hh = floor(t_bp/3600);
   t_bp = t_bp - (hh * 3600);
   mm = floor(t_bp/60);
   ss = t_bp - (mm * 60);
   
   tEvent.T{iT} = sprintf('%02g:%02g:%05.4g',hh,mm,ss);
end

%% (OPTIONALLY) PROMPT FOR # FRAMES & FRAMERATE (MOTIVE)
if COMBINE
   prompt = {'Enter number of video frames:', ...
             'Enter video framerate:'};
   dlg_title = 'MOTIVE info input';
   num_lines = 1;
   default_answer = {'#####','100'};
   answer = inputdlg(prompt,dlg_title,num_lines,default_answer);
   
   nFrames = str2double(answer{1});
   frameRate = str2double(answer{2});
   
   tEvent = CPL_getButtonSync(nFrames,frameRate,tEvent);
end

end