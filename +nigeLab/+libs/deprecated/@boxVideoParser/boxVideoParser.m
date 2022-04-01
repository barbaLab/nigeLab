classdef boxVideoParser < handle
%% BOXVIDEOPARSER    Class for parsing videos from behavioral box

%% Properties
   properties(SetAccess = public, GetAccess = public)
      animalID = '';    % animal id (e.g. MM-H1)
      surgID   = '';    % surgery id for this animal if it exists
   end
   
   properties(SetAccess = private, GetAccess = public)
      date           % date of this video
      tag            % tag for this video
      
      meta           % struct with video metadata
      vid            % array of associated video files
   end
   
   properties(SetAccess = private, GetAccess = private)
      leftROI
      rightROI
      
      curTime     % Current video time
      curIdx      % Current video index (from vid array)
      V           % Current videoreader object
      
   end
   
%% Events
   events
      animalIDset
      surgIDset
      dateset
   end
   
%% Methods
   methods (Access = public)
      % Create the video information object
      function obj = boxVideoParser(file,animalID,surgID)
         %% BOXVIDEOPARSER    Parse information from video file
         
         %% Parse input
         if nargin < 1
            file = [];
         end
         
         if nargin < 2
            animalID = '';
         end
         
         if nargin < 3
            surgID = '';
         end
         
         %%
         if isempty(file)
            [fname,pname,~] = uigetfile('*.MP4','Select first video',...
               'C:\Temp\');
            if fname == 0
               error('No file selected. Parsing canceled.');
            end
            [~,fname,ext] = fileparts(fname);
         else
            [pname,fname,ext] = fileparts(file);
         end
         
         obj.meta = struct;
         obj.meta.id = str2double(fname((end-3):end));
         
         obj.vid = dir(fullfile(pname,['GH*' fname((end-3):end) ext]));
         obj.meta.start = datetime(obj.vid(1).date,...
            'Format','dd-MMM-yyyy HH:mm:ss');
         obj.setDate(datestr(obj.meta.start,'yyyy_mm_dd'));
         
         %% ONLY PROMPT FOR ID IF ANIMALID IS EMPTY (NOT SURG)
         if isempty(animalID)
            str = inputdlg({'Animal ID'; 'Surgical ID'},...
               '(Optional) Input ID data',...
               1,{animalID,surgID});
            animalID = str{1};
            surgID = str{2};
         end
         
         if ~isempty(animalID)
            obj.setAnimalID(animalID);
         end
         
         if ~isempty(surgID)
            obj.setsurgID(surgID);
         end
         
      end
      
      
      function extractTrialsVid(obj)
         %% EXTRACTTRIALSVID  Extract a shortened "trials" version of video
         
         
         
      end
      
      function setAnimalID(obj,animalID)
         %% SETANIMALID    Set the animal ID for the video
         if ~(ischar(animalID) || isstring(animalID))
            error('Invalid animalID format. Must be char or string.');
         end
         
         obj.animalID = animalID;
         notify(obj,'animalIDset');
      end
      
      function setSurgID(obj,surgID)
         %% SETSURGICALID    Set the surgical ID for animal in the video
         if ~(ischar(surgID) || isstring(surgID))
            error('Invalid surgID format. Must be char or string.');
         end
         
         obj.surgID = surgID;
         notify(obj,'surgIDset');
      end
      
      function setDate(obj,date)
         %% SETDATE   Set the date for the video
         if ~(ischar(date) || isstring(date))
            error('Invalid date format. Must be char or string.');
         end
         
         obj.date = date;
         notify(obj,'dateset');
      end
      
   end

   methods (Access = private)
      function setLEDroi(obj,time)
         %% SETLEDROI   Set ROI for LEFT (blue box) and RIGHT (red box) LED
         
         if nargin < 2
            time = 60; % video frame time (sec)
         end
         
         obj.V = VideoReader(fullfile(obj.vid(1).folder,obj.vid(1).name));
         obj.V.CurrentTime = time;
         
         fig = figure('Name','LED ROI Selector Interface',...
            'Units','Normalized',...
            'Position',[0.1 0.1 0.8 0.8],...
            'Color','w');
         
         im = readFrame(obj.V);
         imagesc(im);
         
         
      end
      
   end
   
end