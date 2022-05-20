function offset = guessVidStreamAlignment(blockObj,digStreamInfo,vidStreamInfo)
% GUESSALIGNMENT  Compute "best guess" offset using
%
%  offset = blockObj.guessAlignment;
%  --> For if blockObj.UserData is set as a struct with fields 'digStreams'
%      and 'vidStreams' (as is set during blockObj.alignVideoManual)
%
%  offset = blockObj.guessAlignment(digStreamInfo,vidStreamInfo); 
%  --> Uses digital stream specified by digStreamInfo(1) and video stream
%      specified by vidStreamInfo(1) to compute the "best guess" alignment
%      using correlation between the two signals sampled to approximately
%      the same sample rate.
%
%  offset is returned as a time in seconds, where a positive value denotes
%  that the video starts after the neural record. The value of offset is
%  automatically saved as the 'ts' property of a special 'Header' file
%  located with the other 'ScoredEvents' files in the block hierarchy.

% Parse input
if nargin < 3
   if isempty(blockObj.UserData)
      error('If UserData property is not set, must provide all 3 args.');
   end
   digStreamInfo = blockObj.UserData.digStreamInfo(1);
else
   digStreamInfo = digStreamInfo(1); % Only use first array element
end

if nargin < 2
   if isempty(blockObj.UserData)
      error('If UserData property is not set, must provide all 3 args.');
   end
   vidStreamInfo = blockObj.UserData.vidStreamInfo;
end

if vidStreamInfo.idx == 0
   warning(1,'-->\tNo vidStream selected (idx == 0).\n');
   offset = zeros(size(blockObj.Videos));
   return;
end

curAlign = getEventData(blockObj,[],'ts','Header');
if any(~isnan(curAlign))
   str = nigeLab.utils.uidropdownbox('Overwrite alignment with new guess?',...
      'Overwrite alignment with new guess?',{'No','Yes'},true);
   if strcmp(str,'No')
      offset = curAlign;
      offset(isnan(curAlign)) = 0; % "zero out" any NaN possibilities
      return;
   end
end

blockObj.updateParams('Video');

% Get streams to correlate
dig = blockObj.getStream(digStreamInfo.name);
camOpts = nigeLab.utils.initCamOpts(...
   'csource','cname',...
   'cname',vidStreamInfo.Name);
vid = getStream(blockObj.Videos,camOpts);
fs = blockObj.Pars.Video.Alignment_FS.(blockObj.RecSystem.Name);

switch blockObj.RecSystem.Name
   case 'TDT'
      % Upsample by 16 because TDT uses multiples of 5 for FS stuff
      ds_fac = round((double(dig.fs) * 16) /fs);
      x = resample(double(dig.data),16,ds_fac);
   otherwise
      % Intan recordings sample rates are 20kHz, 30kHz etc.
      ds_fac = round(dig.fs / fs);
      x = decimate(double(dig.data),ds_fac);
end
y = resample(double(vid.data),fs,round(vid.fs));

% Guess the lag based on cross correlation between 2 streams
tic;
fprintf(1,'Please wait, making best alignment offset guess (usually 1-2 mins)...');
[R,lag] = nigeLab.utils.getR(x,y);
offset = nigeLab.utils.parseR(R,lag,fs);
setEventData(blockObj,[],'ts','Header',offset);
fprintf(1,'complete.\n');
toc;
end