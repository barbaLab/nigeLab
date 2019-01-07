classdef audioSync < handle
%% AUDIOSYNC Class to manage video/neural sync data
%   
%  obj = AUDIOSYNC(blockDirectory);
%
%  ex: 
%  audioSyncObj = audioSync('P:\Your\Recording\Directory\Here');
%
%  AUDIOSYNC Properties:
%     Name - Name of recording BLOCK (immutable)
%     
%     DIR - Full path of recording BLOCK (immutable)
%
%     neuralSync - Struct pointing to neural sync signal files (immutable)
%
%     cameraSync - Struct pointing to camera sync signal files (immutable)
%
%     videoData - Struct pointing to video files (immutable)
%
%  AUDIOSYNC Methods:
%     audioSync - Class constructor.
%
%     syncData - Returns struct with video start times relative to neural.
%
% By: Max Murphy  v1.0  07/17/2018  Original version (R2017b)

%% Properties   
   properties (SetAccess = public)
      neuralSync % Neural sync signals (DIGITAL- or ANALOG-in)
      cameraSync % Camera sync signals
      videoData  % Video camera recordings
   end

   properties (SetAccess = private)
      syncPath = '_Digital';           % Identifier for digital path
      neuSyncID = '*sync.mat';         % Identifier for digital sync file
      camSyncID = '*CamAudio-*_0.mat'; % Identifier for camera audio file
      videoID = '*Cam-*_0.mp4';        % Identifier for video file
      
      corrBuff = 20;    % Samples to buffer on either end of corr signal
      deBounce = 0.75;  % De-bounce time on digital "HIGH" signal (seconds)
      dutyCycle = 0.4;  % Duty cycle duration (seconds)
      audioLim = 180;   % Truncate audio signal (seconds)
      
      neuCorrStart      % Start index of "tone" in digital record
      neuCorrStop       % Stop index of "tone" in digital record
      
      tonePulse         % Modified "tone" pulse record used for sync
   end
   
   properties (SetAccess = immutable)
      Name     % Name of BLOCK (from DIR for convenience)
      DIR      % Recording BLOCK path
      digPath  % Digital path
   end

%% Methods
   methods (Access = public)
      function obj = audioSync(blockDirectory)
         % AUDIOSYNC Construct an instance of this class
         
         % Set immutable properties
         obj.DIR = blockDirectory;
         obj.Name = strsplit(blockDirectory,filesep);
         obj.Name = obj.Name{end};
         obj.digPath = fullfile(obj.DIR,[obj.Name obj.syncPath]);
         
         % Get video Data
         obj.videoData = dir(fullfile(obj.DIR,...
                                     [obj.Name obj.videoID]));
         
         % Get neuralSync and cameraSync file names
         obj.neuralSync = dir(fullfile(obj.digPath, ...
                                      [obj.Name obj.neuSyncID]));
                                   
         obj.cameraSync = dir(fullfile(obj.digPath, ...
                                      [obj.Name obj.camSyncID]));
                                   
         if isempty(obj.cameraSync)
            obj.ripAudio;
            obj.cameraSync = dir(fullfile(obj.digPath,...
                                          [obj.Name obj.camSyncID]));
         end
      end
      
      
      function vSync = syncData(obj)
      %% SYNCDATA  Synchronize neural and audio data
         
         % Get neural "corr" signaler
         neu = load(fullfile(obj.digPath,obj.neuralSync.name),'data','fs');
         obj.neuCorrStart = find(neu.data>0,1,'first')-obj.corrBuff;
         obj.neuCorrStop = find(neu.data>0,1,'last')+obj.corrBuff;
         
         L = obj.neuCorrStop - obj.neuCorrStart + 1;
         
         obj.getNeuralSync(neu.data,neu.fs);
                  
         vSync = struct('vid',cell(size(obj.cameraSync,1),1),'start',nan);
         tic;
         for ii = 1:size(obj.cameraSync,1)
            nIdx = regexp(obj.cameraSync(ii).name,'CamAudio-\d')+9;
            n = obj.cameraSync(ii).name(nIdx);
            vSync(ii).vid = n;
            
            cam = load(fullfile(obj.digPath,obj.cameraSync(ii).name),...
                        'data','fs');
                     
            x = abs(resample(double(cam.data(1,:)),neu.fs,cam.fs));
            
            xc = conv(x,fliplr(obj.tonePulse),'same');
            
            [~,idx] = max(xc);
            vSync(ii).start = obj.neuCorrStart + ceil(L/2) - idx;
            figure;
            subplot(3,1,1);
            plot(x); title('audio');
            subplot(3,1,2);
            plot(obj.tonePulse); title('digital tone');
            subplot(3,1,3);
            plot(xc); title('xcorr');
            
         end
         toc;
      end
      
   end
   
   methods (Access = private)
      function ripAudio(obj)
      %% RIPAUDIO    Take audio tracks from video and save as mat file
         for ii = 1:size(obj.videoData,1)
            fname = fullfile(obj.DIR,obj.videoData(ii).name);
            [data,fs] = audioread(fname); 
            idx = min(size(data,1),round(fs*obj.audioLim));
            data = data(1:idx,:).';
            syncName = ['_' obj.camSyncID(2:end)];
            nIdx = regexp(obj.videoData(ii).name,'Cam-\d')+4;
            n = obj.videoData(ii).name(nIdx);
            syncName = strrep(syncName,'*',n);
            save(fullfile(obj.digPath,[obj.Name syncName]),...
               'data','fs','-v7.3'); 
         end
      end
      
      function getNeuralSync(obj,data,fs)
      %% GETNEURALSYNC  Get clipped/processed neural sync signal
         
         deBounceSamples = round(obj.deBounce * fs);
         obj.tonePulse = data(obj.neuCorrStart:obj.neuCorrStop);
      
         idx = find(obj.tonePulse > 0);
         diff_thresh = [true, diff(idx) > deBounceSamples];
         idx = idx(diff_thresh);
         dutyCycleSamples = round(obj.dutyCycle * fs);
         
         for ii = 1:numel(idx)
            obj.tonePulse(idx(ii):(idx(ii)+dutyCycleSamples)) = 1;
         end
         
         
         
      end
   end
end

