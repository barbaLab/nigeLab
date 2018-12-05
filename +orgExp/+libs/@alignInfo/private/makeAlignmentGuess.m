function alignGuess = makeAlignmentGuess(p,F,varargin)
%% MAKEALIGNMENTGUESS Modified version of guessAlignment method for batch processing
%
%  alignGuess = MAKEALIGNMENTGUESS(p,F);
%  alignGuess = MAKEALIGNMENTGUESS(p,F,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     p     :     Probability time-series for detected grasp paw from
%                 video. Has same sampling rate as video.
%
%     F     :     Struct with 'folder' and 'name' fields as returned by
%                 'dir' function. Should point to file with beam-break
%                 stream.
%
%  varargin :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  alignGuess :   Best guess for video alignment to neural time-series
%                 (offset) based on maximally correlated lag between the
%                 two series. Not perfect but works well-enough to help the
%                 manual alignment process.
%
% By: Max Murphy  v1.0  08/29/2018   Original version (R2017b)

%% DEFAULTS
FS = 125;
VID_FS = 30000/1001;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

% Upsample by 16 because of weird FS used by TDT...
beam = loadStream(F);
ds_fac = round((double(beam.fs) * 16) / FS);
x = resample(double(beam.data),16,ds_fac);

% Resample DLC paw data to approx. same FS
y = resample(p,FS,round(VID_FS));

% Guess the lag based on cross correlation between 2 streams
tic;
fprintf(1,...
   'Please wait, making best guess for %s (usually 1-2 mins)...',...
   F.name);
[R,lag] = getR(x,y);
alignGuess = parseR(R,lag);
fprintf(1,'complete.\n');
toc;
end