classdef nigelCamera < matlab.mixin.SetGet
   %NIGELCAMERA  Object with data about all videos from a source camera
   % This object handles passing from a video to the next one and stitching
   % them together. It provides a matlab interface to simple VideoReader
   % mex function built using openCV 3.1.4.3
   %
   % nigelCamera Methods to the mex interface:
   %
%    pause    -      Pauses video reproduction
%    play     -      Starts video reproduction
%    seek     -      Sets the video to a particoular time [ms]
%    frameF   -      Advances one frame.
%    framB    -      Backs one frame.
%    setBufferSize - Sets the buffer size [int - frame numbers]
%    setSpeed    -   Sets reproduction speed [int - number]
%    showThumb   -   Opens reproduction window
%    startBuffer -   Starts video buffering. Automatically called upon play
%    stopBuffer  -   Stops video buffering. Called upon delete
%    closeFig    -   Closes the reproduction figure. Called upon delete
%    crop        -   Crops the video for reproduction (does not actually modify the video)
%    exportFrame -   Exports current frame as jpeg to paths set in
%                    Paths.VidStreams of block.
%    extractSignal - Prompts the user to set a ROI and a Normalization_ROI.
%                    For each frame, it extracts the mean value of ROI 
%                    normalized over the mean value of Normalization_ROI.
%
% nigelCamera other public Methods:
% addVideos - Adds videos specified in path to nigelCamera. If no input is
%             provided refreshes the videos in Paths recreating the mex objects.
% getTimeSeries - returns the full video time in [ms] transformed by
%                 VideoOffset and VideoStretch. Original time series is
%                 stored in <a href="matlab:help nigeLab.libs.nigelCamera.TS">TS</a> property, see below.
% addStream  - Adds a stream to nigelCamera.
% setActive  - Sets the private property Active. Inactive videos do not
%              respond to comands such as play/pause, framF/B etc.
% getSynchedTime - returns input t transformed by VideoOffset and
%                  VideoStretch.
%
% nigelCamera Properties:
%  Meta - Structure containing metadata about the video parsed both from
%         video name and from video file.
% Streams - Streams associated to video file. They can be created from the
%           video itself or added from an external file. This filed is
%           populated using ADDSTREAM function
% VideoOffset - Set using nigeLab.libs.Vidscorer interface. Specifies the
%               offset between the video time and (usually) the ePhys time.
%               It is only a translational factor.
% VideoStretch - Set using nigeLab.libs.Vidscorer interface. Specifies the
%                strecthing factor i.e. corrects for inconsistencies
%                between sampling frequencies. See getSynchedTime.
% Time - Now. It returns the time corresponding to the displayed frame.
%        This is only set when the video is paused.
% FrameIdx - As above, but returns the frame index instead of frame time.
% Name - Cameta name.
% Paths - Paths to all videos in nigelCamera.
%
% TS - Hidden, readonly property with the original video timebased in [ms] 
%       (untransformed by VideoOffset and VideoStretch).




   %   
   %  cameraObj = nigeLab.libs.nigelCamera(timeAxesObj);
   
   % % % PROPERTIES % % % % % % % % % %     
   % ABORTSET,DEPENDENT,TRANSIENT,PUBLIC
   properties (Access=public)
      Meta
      Streams        struct;
   end
   
   properties (Access=private)
        VideoPaths = {}                 % cell array of paths to videos.
        WindowOpened = false;
        Active         (1,1)double = false;
   end
   
   properties (SetAccess=?nigeLab.libs.VidScorer)
        VideoOffset      (1,1)double = 0;       % double. Set beginning offset between video and world
        VideoStretch     (1,1)double = 0;       % double. Set the streatching factor: correccts for inconsistencies between sampling frequencies.
   end
   
   properties (Transient,SetAccess=private,Hidden)
      VideoReader_                             % Array of video objects interface (c++ mex function)
      TS_                   double = [];    % Hidden, readonly property with the original video timebased in [ms] (untransformed by VideoOffset and VideoStretch).
   end
   
   % TRANSIENT
   properties (Transient,SetAccess=?nigeLab.nigelObj)
      Parent                        % Parent nigeLab.Block object 
   end
      
   properties(Dependent,SetAccess=private)
       Time                                                                 % This frame's time
       Name                                                                 % camera name
       FrameIdx                                                             %This frame index
       Paths                                                                % All videos paths
   end

      properties(Dependent,SetAccess=private,Hidden)
       VideoReader                                                          % Pointer pointing to c++ obj
       TS                                                                   % Returning the video TimeBase
   end
   
   properties(GetAccess=public,SetAccess=private,Hidden)
      Time_ (1,1) double = 0        % Current "Series Time"
      TimeIdx_ (1,1) double = 1
      Name_
   end
   % % % % % % % % % % END PROPERTIES %
   
   events
      timeChanged                   % Event fired whenever the Time property is set
      streamAdded                   % Event fired whenever a new stream is added
   end
   
   % % % METHODS% % % % % % % % % % % %
   methods
      % % % (DEPENDENT) GET/SET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT]  .Time references .Time_. Also takes care of conversion
      % of video time to the world.
      function value = get.Time(obj)
         %GET.TIME  Returns .Time (references .Time_)
         value = obj.getSynchedTime(...
             obj.Time_,...
             'video2ext');
      end
      function set.Time(obj,value)
         %SET.TIME  Assign new .Time (updates .Index based on .Time_)
         
         idx = find(obj.TS == value);
         if isempty(idx) % Returns empty if "out of bounds"
           idx = round(value/1000/obj.Meta(1).frameRate);
         end
         obj.Time_ = value;
         
         % Set Index (dependent property that updates the rest)
         obj.TimeIdx_ = idx;
         
         % notify time changed
         notify(obj,'timeChanged');
      end
      
      function idx = get.FrameIdx(obj)
         %GET.TIME  Returns .Time (references .SeriesTime_)
         [~,idx] = min(abs( obj.Time_ - obj.TS));
      end
      function set.FrameIdx(~,~)
      end
      
      % [DEPENDENT]  .Name references Name_. First time it is called it
      % parses the information from Meta.CameraID
      function set.Name(~,~)
      end
      function value = get.Name(obj)
          if isempty(obj.Name_)
              if isfield(obj.Meta,'CameraID')
                  obj.Name_ = obj.Meta(1).CameraID;
              end
          end
          value = obj.Name_;
      end
      
      % [DEPENDENT]  .Paths references VideoPaths. Just a proxy for
      % convenience.
      function set.Paths(~,~)
      end
      function value = get.Paths(obj)
          value = obj.VideoPaths;
      end

       % [DEPENDENT]  .VideoReader references VideoReader_. Takes care of
       % reinitializing the c++ object if it's invalid
      function set.VideoReader(~,~)
      end
      function value = get.VideoReader(obj)
            if isempty(obj.VideoReader_)
                obj.addVideos();
            end
            value = obj.VideoReader_;
      end

      % [DEPENDENT]  .VideoReader references VideoReader_. Takes care of
       % reinitializing the c++ object if it's invalid
      function set.TS(~,~)
      end
      function value = get.TS(obj)
          if isempty(obj.TS_)
              nFrames = cumsum([0 obj.Meta.nFrames]);
              tt = arrayfun(@(idx) (nFrames(idx):nFrames(idx+1)-1) .* (1000./obj.Meta(idx).frameRate)  ,1:numel(nFrames)-1 ,'UniformOutput' ,false);
              obj.TS_ = [tt{:}];
          end

          value = obj.TS_;
      end
      % % % % % % % % % % END (DEPENDENT) GET/SET.PROPERTY METHODS % % %
end
   
methods
    % Class constructor
    function obj = nigelCamera(blockObj,Paths,varargin)
        %NIGELCAMERA  Constructor for object to reference video series
        %
        %  cameraObj = nigeLab.libs.nigelCamera(blockObj,Paths,varargin);
        %  Paths can either be a path to a folder containing videos or a
        %  cell array to paths for videos.
        %  If the path points to a folder, naming parsing needs to be
        %  done. In order to do so the correspoding default file will be
        %  called.
        %
        if isa(blockObj,'nigeLab.Block')
            obj.Parent = blockObj;
        else
            error(['nigeLab:' mfilename ':BadClass'],...
                ['\t\t->\t<strong>[BLOCKOBJ]</strong>: ' ...
                'First input needs to be `nigeLab.Block`\n']);
        end
        Pars = blockObj.Pars.Video;
        % Error checking on Paths
        if ~iscell(Paths)
            if ischar(Paths) && exist(Paths,'dir')
                vFiles = cellfun(@(ext)...
                    dir(sprintf('%s%c%s',Paths,filesep,ext)),...
                    Pars.ValidVidExtensions(:,1),'UniformOutput',false);
                vFiles = cat(1,vFiles{:});

                if isempty(vFiles) && Pars.UseVideoPromptOnEmpty
                    Paths = uigetdir(Pars.DefaultSearchPath,'Please, select the video folder.');
                    vFiles = cellfun(@(ext)...
                        dir(sprintf('%s%c*%s',Paths,filesep,ext)),...
                        Pars.ValidVidExtensions);
                end

                Paths = arrayfun(@(f) fullfile(f.folder,f.name),vFiles,'UniformOutput',false);
            elseif ischar(Paths) && exist(Paths,'file')
                Paths = {Paths};
            else
                error(['nigeLab:' mfilename ':BadInArg'],...
                    ['\t\t->\t<strong>[Paths]</strong>: ' ...
                    'Second input needs to be a path to a video file or directory oa a cell array of paths\n']);
            end

        end
        % No error-checking here
        for iV = 1:2:numel(varargin)
            obj.(varargin{iV}) = varargin{iV+1};
        end
        obj.VideoPaths = [];
        obj.addVideos(Paths);

        obj.Meta = simpleVideoReader('getMeta',obj.VideoReader);
        obj.getTimeSeries();
    end

    % Class destructor
    function delete(obj)
        %DELETE  Destructor for object. Also takes care of destroying video
        %objects.
        if ~isempty(obj.VideoReader_)
            simpleVideoReader('closeFig', obj.VideoReader);
            simpleVideoReader('delete', obj.VideoReader);
        end
        obj.VideoReader_ = [];
    end

    % Class loader
    function a = loadobj(a)
    %LOAD override function. Takes care of reinitializing all c++
    %videoreader objects
        if isa(a, 'nigeLab.libs.nigelCamera')
...
        end
    end
end
   
   % PRIVATE
   methods (Access=private)
      function parseTime(obj)
         %PARSETIME   Parses concatenated vector for .Time_ property
         %
         %  parseTime(obj);
         
         % Do not update if .Series is empty
         if isempty(obj.Series)
            return;
         end
         
         obj.Time_ = zeros(numel(obj.Series),3);
         for i = 1:numel(obj.Series)
            t = obj.Series(i).tVid;
            obj.Time_(i,:) = [obj.Series(i).Masked, min(t), max(t)];
         end
      end
   end
   
   
   methods (Access=public)
       
       function addVideos(obj,Paths)
          % Add videoFiles to the Videos field using paths 
          % Videos is popoulated by istances of the c++ class
          % simpleVideoreader
          
          if nargin<2
              Paths = obj.VideoPaths;
          else
             Paths = [obj.VideoPaths;Paths]; 
          end
          
          if ~iscell(Paths)
              error('Paths should be a cell array.\n');
          end
          
          %% TODO embed sort in nigelCamera
          Paths = Paths(obj.Parent.Pars.Video.CustomSort(Paths));

          obj.VideoPaths = nigeLab.utils.getUNCPath(Paths);
          obj.VideoReader_ = simpleVideoReader('new',Paths);
          thisMeta = simpleVideoReader('getMeta',obj.VideoReader);
          obj.Meta = nigeLab.utils.add2struct(obj.Meta,thisMeta);
          obj.getTimeSeries;
%           obj.Lags = cumsum([obj.Meta.duration]);
       end
       
       function TS = getTimeSeries(obj)
           TS = obj.TS  -  obj.VideoOffset - (1:numel(obj.TS)).* obj.VideoStretch;
       end
       
       function addStream(obj,PathToFile,varname)
          if nargin < 2
              % no path provided, extract signal from Video
              varname = inputdlg('Signal name:');
              if isempty(varname)
                 return; 
              end
              [sig,t] = obj.extractSignal;
              t(t==0) = nan;
              nigelSig = nigeLab.utils.signal('vid',numel(sig),'VidStreams','Streams');
              thisStream = struct('name',varname,'signal',nigelSig,'Key',nigeLab.utils.makeHash,'fs',mean([obj.Meta.frameRate]));
              thisPath = fullfile(sprintf(obj.Parent.Paths.VidStreams.file,obj.Name,thisStream.name,'mat'));
              thisStream.data = nigeLab.libs.DiskData('Hybrid',thisPath,sig,'overwrite', true);
              
              thisPath = fullfile(sprintf(obj.Parent.Paths.VidStreams.file,obj.Name,[thisStream.name '_Time'],'mat'));
              thisStream.time = nigeLab.libs.DiskData('Hybrid',thisPath,t,'overwrite', true);
          else
              [path,name,ext] = fileparts(PathToFile);
              if nargin < 3
                  varname = '';
              end
              switch ext
                  case '.mat'
                      variables = who('-file', PathToFile);
                       t_varname = variables(cellfun( @(s)any( strcmp(s,{'t','time'}) ),variables ));
                      if ~isempty(t_varname) && ~strcmp(t_varname,varname)
                          t_varname = variables{cellfun( @(s)any( strcmp(s,{'t','time'}) ),variables )};
                          t = load(PathToFile,t_varname);
                          t = t.(t_varname);
                      else
                          quest = 'No Time vector detected!\nDo you have a time vector stored somewhere for this signal?\n(Time has to be expressed in ms.)';
                          answer = questdlg(sprintf(quest),'Where is time?','Yes!','No...','Yes!');
                          if strcmp(answer,'Yes!')
                              [Tfile,Tpath] = uigetfile(fullfile(obj.Parent.Out.Folder,'*.*'),'Select the Time vector.');
                              t_varname = who('-file', PathToFile);
                              if numel(t_varname) ~= 1
                                  error('Variable to load is unclear.\n Please provide a time matfile with only one variable in it.\n');
                              end
                              t_varname = t_varname{1};
                              t = load(fullfile(Tpath,Tfile),t_varname);
                              t = t.(t_varname);
                              t_varname = {'t','time'};
                          elseif strcmp(answer,'No...')
                              f = msgbox(sprintf('No problem, Nigel will create one for you!\n(Time basis will be the same as video.)')...
                                  ,'Fine.');
                              t = obj.TS;
                          else
                              return;
                          end
                      end

                      variables = setdiff(variables,t_varname);

                      if strcmp(varname,'') && numel(variables) == 1
                         varname = variables{1};
                      elseif ~strcmp(varname,'')
                         varname = variables{strcmpi(variables, varname)};
                      end

                      if strcmp(varname,'')
                          error(sprintf('Variable to load is unclear.\n Please specify as third input which variable in the provided file you want to add as a Stream.\n'));
                      end

                      sig = load(PathToFile,varname);
                      sig = sig.(varname);
                  otherwise
                      error('Unknow file format. File format %s not yet supported.\n',ext);
              end
              if numel(sig) ~= numel(t)
                error('Dimension mismatch between %s and %s',varname,t_varname);
              end
              nigelSig = nigeLab.utils.signal('vid',numel(sig),'VidStreams','Streams');
              thisStream = struct('name',varname,'signal',nigelSig,'Key',nigeLab.utils.makeHash,'fs',mean([obj.Meta.frameRate]));
              thisPath = fullfile(sprintf(obj.Parent.Paths.VidStreams.file,obj.Name,thisStream.name,'mat'));
              thisStream.data = nigeLab.libs.DiskData('Hybrid',thisPath,sig(:)','overwrite', true);
              
              thisPath = fullfile(sprintf(obj.Parent.Paths.VidStreams.file,obj.Name,[thisStream.name '_Time'],'mat'));
              thisStream.time = nigeLab.libs.DiskData('Hybrid',thisPath,t,'overwrite', true);
          end
          obj.Streams = [obj.Streams thisStream];
          
          evtData = nigeLab.evt.vidstreamAdded(thisStream);
          notify(obj,'streamAdded',evtData);
       end

       function setActive(obj,val)
           % SETACTIVE(obj,val) sets Active (private) property to <strong>val</strong>. 
           % 
           % If Active is false the video does not  respond to the mex 
           % interface commands.
           % See also PLAY, PAUSE, FRAMEF, FRAMEB, SEEK, CROP, EXPORTFRAME,
           % SHOWTHUMB.

           obj.Active = val;
           if val
               obj.startBuffer;
               obj.showThumb;
           else
               obj.stopBuffer;
               obj.closeFig;
           end
       end

       function [tt, tt_idx] = getSynchedTime(obj,t,direction)
           % TT = GETSYNCHEDTIME(obj,t,direction)
            % When VideoOffset and VideoStretch are set returns input <strong>t</strong>
            % properly transformed to reflect <strong>direction</strong>. This method is
            % also called when <a href="matlab:help('nigeLab.libs.nigelCamera.Time')">Time</a> property is returned assuming it is
            % preferible to keep that varible synched with the outside
            % world.
            % <strong>direction</strong> can be:
            % <strong>video2ext</strong> - converts t from video time to world time
            % <strong>ext2video</strong> - converts t from world time to video time
            if diff(size(t))>0,t = t';end
            tt = nan(size(t));
            tt_idx = tt;
            for ii=1:size(t,2)
                switch direction
                    case 'video2ext'
                        [~,idx] = min( abs(obj.TS - t));
                        tt = obj.TS(idx) -  obj.VideoOffset - idx.* obj.VideoStretch;
                    case 'ext2video'
                        trueVideoTime = obj.TS;
                        [~,idx] = min( abs( trueVideoTime - obj.VideoOffset-(1:numel(obj.TS)).*obj.VideoStretch...
                            - t(:,ii)),[],2);
                        tt(:,ii) = trueVideoTime(idx);
                        tt_idx(:,ii) = idx;
                end
            end%ii
       end
   end % methods public
   
   % Mex interface methods. Methods in this section are used to comunicate
   % with the c++ class
   methods (Access=public)
       function startBuffer(obj)
%        Starts video buffering. Automatically called upon PLAY    
           simpleVideoReader('startBuffer',obj.VideoReader);
       end

       function stopBuffer(obj)
%        Stops video buffering. Automatically called upon DELETE
           simpleVideoReader('stopBuffer',obj.VideoReader);
       end

       function play(obj)
           % If Active, plays video
           if ~obj.Active
               return;
           end
           if ~obj.WindowOpened
               showThumb(obj);
           end
           simpleVideoReader('play',obj.VideoReader);
       end

       function showThumb(obj)
           % If Active, opens a window for video reproduction
            if ~obj.Active
               return;
           end
           nn = obj.Name;
           if isempty(nn)
               nn = 'Video';
           end
           simpleVideoReader('showThumb',obj.VideoReader,nn);
           obj.Active = true;
           obj.WindowOpened = true;
       end

       function pause(obj)
           % If Active, pauses video reproduction
            if ~obj.Active
               return;
           end
           obj.Time = simpleVideoReader('pause',obj.VideoReader);
       end

       function seek(obj,t)
           % If Active, seeks to a specified time (input t)
           if ~obj.Active
               return;
           end

           t = obj.getSynchedTime(t,'ext2video');
           obj.Time = simpleVideoReader('seek',obj.VideoReader,t);
       end

       function frameF(obj)
           % If Active, advances one frame
           if ~obj.Active
               return;
           end
           obj.Time = simpleVideoReader('frameF',obj.VideoReader);
       end

       function frameB(obj)
           % If Active, backs one frame
           if ~obj.Active
               return;
           end
           obj.Time = simpleVideoReader('frameB',obj.VideoReader);
       end

       function setSpeed(obj,s)
           % SETSPEED(obj,s)
           % Sets video reproduction speed to <strong>s</strong>. No limit is set but for
           % reproduction speeds higher than 30 fps frame skipping is
           % implemented (which is fine - it is done only during play,
           % frameF/B always show all frames) and for reproduction speeds
           % higher than 240 fps there are usually buffering problems (i.e.
           % the video stops to replenish the buffer, like YT in the 90's).
           if ~obj.Active
               return;
           end
           simpleVideoReader('setSpeed',obj.VideoReader,s);
       end

       function setBufferSize(obj,N)
           % SETBUFFERSIZE(obj,N)
           % Sets video buffer size to <strong>N</strong> frames. Keep in mind that no
           % checks are done on memory. If N is too big, it will saturate
           % your RAM and matlab will become unresponsive. Default value is
           % usually way more than it's needed and is set to 600.
           simpleVideoReader('setBufferSize', obj.VideoReader,N);
       end

       function crop(obj)
           % Opens a dialog to crop video visualization. No changes are
           % done to the actual video.
            if ~obj.Active
               return;
           end
           simpleVideoReader('drawROI',obj.VideoReader);
       end

       function exportFrame(obj,thisPath)
           % Exports current frame as jpeg. Path of export is defined in
           % obj.Parent.Paths.Video.dir and the jpeg name will be
           % [obj.Name]Frame[n+1].jpg where n is the number of files that
           % follow this naming scheme in the folder. Starts at 0;
           
           % thisPsth is an optional argoument. If not provided it defaults
           % to the VidStreams folder in the Paths struct.
            if ~obj.Active
               return;
            end
           if nargin < 2
               thisPath = obj.Parent.Paths.VidStreams.dir;
           elseif ~exist(thisPath,'dir')
               mkdir(thisPath);
           end
           NFrames = numel(dir(fullfile(thisPath,sprintf('%sFrame*.jpg',obj.Name))));
           savePath = fullfile(thisPath,sprintf('%sFrame%.4d.jpg',obj.Name,NFrames));
           simpleVideoReader('exportF',obj.VideoReader,savePath);
       end

       function [sig,t] = extractSignal(obj)
           % EXTRACTSIGNAL prompts the suer to select a roi on the video thumbanail.
           % It later proceeds to compute the maximum brightness of the
           % selected ROI throughout the video and returns the computed
           % value. This is useful when LED are used for synchronization
           % purposes.
           %
           % To abort the operation keep pressed the ESC button for a
           % couple of seconds
%             if ~obj.Active
%                 sig=[];t=[];
%                return;
%            end
           [sig,t] =  simpleVideoReader('getMeanVal',obj.VideoReader);
           if any(isnan(t))
               t = obj.TS;
               if numel(sig)~=numel(t)
                   error('nigeLab:nigelCam:signalDimensionMismatch','Something went wrong. Extracted time and signal lenghts do not match.');
               end
           end

       end

       function closeFig(obj)
           % Closes the video reproduction window.
           simpleVideoReader('closeFig', obj.VideoReader);
       end

   end % methods public - c++ interface
   
 
   % Hidden function to manually adjust offset & stretch
   methods (Access=public,Hidden)
       function flag = setOffset(obj,offs)
            flag = false;
           try
               obj.VideoOffset = offs;
               flag = true;
           catch er
               %TODO unify error handling
               warning(er.identifier,'%s\n\nError in %s (%s) (line %d)\n', ...
                   er.message, er.stack(1).('name'), er.stack(1).('file'), ...
                   er.stack(1).('line'));
           end
       end

       function flag = setStretch(obj,strtc)
           flag = false;
           try
               obj.VideoStretch = strtc;
               flag = true;
           catch er
               %TODO unify error handling
               warning(er.identifier,'%s\n\nError in %s (%s) (line %d)\n', ...
                   er.message, er.stack(1).('name'), er.stack(1).('file'), ...
                   er.stack(1).('line'));
           end
       end

   end
   % % % % % % % % % % END METHODS% % %
end

