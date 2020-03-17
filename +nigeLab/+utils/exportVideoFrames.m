function exportVideoFrames(videofilename,nframes,outpath,varargin)
%EXPORTVIDEOFRAMES  Export `nframes` random images from video for training
%
%  exportVideoFrames(videofilename);
%  
%  exportVideoFrames(videofilename,nframes);
%  --> default `nframes` is 50
%
%  exportVideoFrames(videofilename,nframes,outpath);
%  --> default outpath is 
%  OUTPATH_DEFAULT_ROOT + (non-extension) filename part of full filename

% DEFINE DEFAULT PARAMETERS:
pars = struct;
pars.LABEL_STRING = 'train_img-%04g.png';
% pars.OUTPATH_DEFAULT_ROOT = ''; 
pars.OUTPATH_DEFAULT_ROOT = 'P:\Rat\BilateralReach\Video\training';
pars.INPUT_DEFAULT_ROOT = 'P:\Rat\BilateralReach\BilateralAudio';
% pars.FRAME_RANGE = [0 1]; % Frame range limits as ratio (0 to 1) of duration
pars.FRAME_RANGE = [0.25 0.85]; % Frame range limits as ratio (0 to 1) of duration
pars.DEF_NUM_FRAMES = 50;

% Parse input arguments
for iV = 1:2:numel(varargin)
   pars.(upper(varargin{iV})) = varargin{iV+1};
end

if nargin < 1
   [fname,pname] = uigetfile('*.*','Select video file',pars.INPUT_DEFAULT_ROOT);
   if fname == 0
      disp('No file selected.');
      return;
   else
      videofilename = fullfile(pname,fname);
   end
end

if nargin < 2
   nframes = pars.DEF_NUM_FRAMES;
end

if nargin < 3
   if isempty(pars.OUTPATH_DEFAULT_ROOT)
      fprintf(1,['->\tNo default path. ' ...
         'Exporting frames to folder on <strong>input</strong> path:\n']);
      [outpath,~,~] = fileparts(videofilename);
      fprintf(1,'\t->\t(<strong>%s</strong>)\n',outpath);
   elseif exist(pars.OUTPATH_DEFAULT_ROOT,'dir')==0
      fprintf(1,['->\tDefault path (<strong>%s</strong>) ' ...
         'does not exist.\n'],pars.OUTPUT_DEFAULT_ROOT);
      [outpath,~,~] = fileparts(videofilename);
      fprintf(1,...
         ['\t->\tExporting frames to folder on input path:\n' ...
         '\t\t->\t(<strong>%s</strong>)\n'],...
         outpath);
   else
      outpath = pars.OUTPATH_DEFAULT_ROOT;
      fprintf(1,'->\tExporting frames to folder on default path:\n');
      fprintf(1,'\t\t->\t(<strong>%s</strong>)\n',outpath);
   end 
end

% Optionally, allow iteration on cell array of input names
if iscell(videofilename)
   if numel(nframes) == 1
      nframes = repmat(nframes,1,numel(videofilename));
   end
   if ~iscell(outpath)
      outpath = repmat({outpath},size(videofilename));
   end
   for i = 1:numel(outpath)
      nigeLab.utils.exportVideoFrames(...
         videofilename{i},nframes(i),outpath{i},varargin{:});
   end
   return;
end

% % % Handle output location % % % %
% If it ends with file separator, remove last character
if ismember(outpath(end),{'\','/'})
   outpath = outpath(1:(end-1));
end
% Make a comparison to see if the last folder matches name of video
[~,fname,~] = fileparts(videofilename);
[~,tmp,~] = fileparts(outpath);
% If not, then it is a "root" output path: append name of video
if ~strcmpi(tmp,fname)
   outpath = fullfile(outpath,fname);
end

if exist(outpath,'dir')==0
   mkdir(outpath);
end

% % % Create VideoReader and begin saving frames from relevant portion of
% video, by specifying a fixed percentage offset from the start of the
% video to the end of the video that won't be used for generating any .PNG
% files % % %
V = VideoReader(videofilename);
t = V.Duration;

pct_offset = pars.FRAME_RANGE(1);
pct_scl = pars.FRAME_RANGE(2) - pars.FRAME_RANGE(1);

iCount = 1;
fprintf(1,'  --  Exporting frames for %s: %03g / %03g  --  \n',...
   fname,0,nframes);
while (iCount <= nframes)
   k = rand(1)*pct_scl + pct_offset; 
   tCur = k * t;
   V.CurrentTime = tCur;
   A = readFrame(V);
   imwrite(A,fullfile(outpath,sprintf(pars.LABEL_STRING,iCount)));
   fprintf(1,'\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%03g / %03g  --  \n',...
      iCount,nframes);
   iCount = iCount + 1;
end

end