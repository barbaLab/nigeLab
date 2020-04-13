function exportVideoFrames(videofilename,nframes,outpath)
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

LABEL_STRING = 'train_img-%04g.png';
OUTPATH_DEFAULT_ROOT = 'P:\Rat\BilateralReach\Video\training';

if nargin < 1
   [fname,pname] = uigetfile('*.*','Select video file',...
      'P:\Rat\BilateralReach\BilateralAudio\R19-162\R19-162_2019_08_29_1\Video');
   if fname == 0
      disp('No file selected.');
      return;
   else
      videofilename = fullfile(pname,fname);
   end
end

if nargin < 2
   nframes = 50;
end

if nargin < 3
   if isempty(OUTPATH_DEFAULT_ROOT)
      [out,fname,~] = fileparts(videofilename);
      outpath = fullfile(out,fname);
   else
      outpath = OUTPATH_DEFAULT_ROOT;
   end
else
   [~,fname,~] = fileparts(videofilename);
end

if exist(outpath,'dir')==0
   mkdir(outpath);
end

V = VideoReader(videofilename);
t = V.Duration;

iCount = 1;
fprintf(1,'Exporting frames for %s: %03g / %03g\n',fname,0,nframes);
while (iCount <= nframes)
   tCur = rand(1) * t;
   V.CurrentTime = tCur;
   A = readFrame(V);
   imwrite(A,fullfile(outpath,sprintf(LABEL_STRING,iCount)));
   fprintf(1,'\b\b\b\b\b\b\b\b\b\b%03g / %03g\n',iCount,nframes);
   iCount = iCount + 1;
end

end