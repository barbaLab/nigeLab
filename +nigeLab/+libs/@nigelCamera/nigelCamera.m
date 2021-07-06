classdef nigelCamera < matlab.mixin.SetGet
   %NIGELCAMERA  Object with data about all videos from a source camera
   % This object handles passing from a video to the next one and stitching
   % them together
   %   
   %  cameraObj = nigeLab.libs.nigelCamera(timeAxesObj);
   %  * Constructor is restricted to be called from `TimeScrollerAxes`
   
   % % % PROPERTIES % % % % % % % % % %     
   % ABORTSET,DEPENDENT,TRANSIENT,PUBLIC
   properties (Access=public)
      Meta
      Streams        struct;
   end
   
   properties (Access=private)
        VideoPaths = {}                 % cell array of paths to videos.
        WindowOpened = false;
   end
   
   properties (SetAccess=?nigeLab.libs.VidScorer)
        VideoOffset      (1,1)double = 0;
        VideoStretch     (1,1)double = 0;
   end
   
   properties (Transient,GetAccess=private)
      VideoReader                             % Array of video objects interface (c++ mex function)
   end
   
   % DEPENDENT,TRANSIENT,PUBLIC
   properties (Transient,SetAccess=?nigeLab.nigelObj)
      Parent                        % Parent nigeLab.Block object 
   end
   
   % TRANSIENT,HIDDEN,PUBLIC
   properties(Transient,Access=private)
      NeuTime_       (1,1) double = 0  % Current neural time
      TS                   double = [];
   end
   
   
   properties(Dependent)
       Time   
       Name
       FrameIdx
   end
   
   properties(Access=private)
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
   % NO ATTRIBUTES (overloaded)
   methods
      % % % (DEPENDENT) GET/SET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT]  .Time references .SeriesTime_
      function value = get.Time(obj)
         %GET.TIME  Returns .Time (references .SeriesTime_)
         value = obj.Time_;
      end
      function set.Time(obj,value)
         %SET.TIME  Assign new .Time (updates .Index based on .Time_)
         
         idx = find(obj.getTimeSeries() == value);
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
         [~,idx] = min(abs( obj.Time_ - obj.getTimeSeries));
      end
      function set.FrameIdx(obj,value)
      end
      
      function set.Name(obj,value)
      end
      function value = get.Name(obj)
          if isempty(obj.Name_)
              if isfield(obj.Meta,'CameraID')
                  obj.Name_ = obj.Meta(1).CameraID;
              end
          end
          value = obj.Name_;
      end
      % % % % % % % % % % END (DEPENDENT) GET/SET.PROPERTY METHODS % % %
end
   
   % RESTRICTED:nigeLab.libs.TimeScrollerAxes (constructor)
   methods %(Access={?nigeLab.libs.TimeScrollerAxes,?nigeLab.Block,?nigeLab.nigelObj})
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
         obj.VideoPaths = Paths;
         if ~isempty(obj.VideoPaths)
            obj.addVideos(Paths); 
         end
         
         obj.Meta = simpleVideoReader('getMeta',obj.VideoReader);
         
      end
      
       %% Destructor - Destroy the C++ class instance
        function delete(obj)
            if ~isempty(obj.VideoReader)
                simpleVideoReader('closeFig', obj.VideoReader);
                simpleVideoReader('delete', obj.VideoReader);
            end
            obj.VideoReader = [];
        end
        
        
        function obj = loadobj(a)
            if isa(a, 'nigeLab.libs.nigelCamera')
                a.addVideos(a.VideoPaths);
            end
        end
   end
   
   % PROTECTED
   methods (Access=protected)
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
       
       function closeFig(obj)
           simpleVideoReader('closeFig', obj.VideoReader);
       end
       
       function addVideos(obj,Paths)
          % Add videoFiles to the Videos field using paths 
          % Videos is popoulated by istances of the c++ class
          % simpleVideoreader
          
          if nargin<2
              Paths = obj.VideoPaths;
          end
          
          if ~iscell(Paths)
              error('Paths should be a cell array.\n');
          end
          

          obj.VideoPaths = Paths;
          obj.VideoReader = simpleVideoReader('new',Paths);
          obj.Meta = simpleVideoReader('getMeta',obj.VideoReader);
%           obj.Lags = cumsum([obj.Meta.duration]);
       end
       
       function TS = getTimeSeries(obj)
           if isempty(obj.TS)
               nFrames = cumsum([0 obj.Meta.nFrames]);
               TS = arrayfun(@(idx) (nFrames(idx):nFrames(idx+1)-1) .* (1000./obj.Meta(idx).frameRate)  ,1:numel(nFrames)-1 ,'UniformOutput' ,false);
               obj.TS = [TS{:}];
           end
           TS = obj.TS;
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
              switch ext
                  case '.mat'
                      if nargin <3
                            variables = who('-file', PathToFile);
                            if numel(variables) == 1
                                varname = variables{:};
                                quest = 'No Time vector detected!\nDo you have a time vector stored somewhere for this signal?\n(Time has to be expressed in ms.)';
                                answer = questdlg(sprintf(quest),'Where is time?','Yes!','No...','Yes!');
                                if strcmp(answer,'Yes!')
                                    [Tfile,Tpath] = uigetfile(fullfile(obj.Parent.Out.Folder,'*.*'),'Select the Time vector.');
                                    variablesT = who('-file', PathToFile);
                                    if numel(variablesT) ~= 1
                                        error('Variable to load is unclear.\n Please provide a time vector with only one variable in it.\n');
                                    end
                                    t = load(fullfile(Tpath,Tfile),variablesT{1});
                                    t = t.(variablesT{1});
                                elseif strcmp(answer,'No...')
                                    f = msgbox(sprintf('No problem, Nigel will create one for you!\n(Time basis will be the same as video.)')...
                                        ,'Fine.');
                                    t = obj.getTimeSeries;
                                else
                                    return;
                                end
                            elseif any(ismember(variables,{'t','time'}))
                            else
                                error('Variable to load is unclear.\n Please specify as third input which variable in the provided file you want to add as a Stream.\n');
                            end
                      end
                      sig = load(PathToFile,varname);
                      sig = sig.(varname);
                  otherwise
                      error('Unknow file format. File format %s not yet supported.\n',ext);
              end
              nigelSig = nigeLab.utils.signal('vid',numel(sig),'VidStreams','Streams');
              thisStream = struct('name',varname,'signal',nigelSig,'Key',nigeLab.utils.makeHash,'fs',mean([obj.Meta.frameRate]));
              thisPath = fullfile(sprintf(obj.Parent.Paths.VidStreams.file,obj.Name,thisStream.name,'mat'));
              thisStream.data = nigeLab.libs.DiskData('Hybrid',thisPath,sig,'overwrite', true);
              
              thisPath = fullfile(sprintf(obj.Parent.Paths.VidStreams.file,obj.Name,[thisStream.name '_Time'],'mat'));
              thisStream.time = nigeLab.libs.DiskData('Hybrid',thisPath,t,'overwrite', true);
          end
          obj.Streams = [obj.Streams thisStream];
          
          evtData = nigeLab.evt.vidstreamAdded(thisStream);
          notify(obj,'streamAdded',evtData);
       end
   end % methods public
   
   % Mex interface methods. Methods in this section are used to comunicate
   % with the c++ class
   methods (Access=public)
       function startBuffer(obj)
          simpleVideoReader('startBuffer',obj.VideoReader);
       end
       
        function play(obj)
           if ~obj.WindowOpened
               simpleVideoReader('showThumb',obj.VideoReader);
           end
           simpleVideoReader('play',obj.VideoReader);
       end
       
        function showThumb(obj)
           simpleVideoReader('showThumb',obj.VideoReader);
           obj.WindowOpened = true;
       end
       
       function pause(obj)
           obj.Time = simpleVideoReader('pause',obj.VideoReader);
       end
       
       function seek(obj,t)
           obj.Time = simpleVideoReader('seek',obj.VideoReader,t);
       end
       
       function frameF(obj)
          obj.Time = simpleVideoReader('frameF',obj.VideoReader);
       end
       
       function frameB(obj)
          obj.Time = simpleVideoReader('frameB',obj.VideoReader);
       end
       
       function setSpeed(obj,s)
          simpleVideoReader('setSpeed',obj.VideoReader,s);
       end
       
       function crop(obj)
           simpleVideoReader('drawROI',obj.VideoReader);
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
          [sig,t] =  simpleVideoReader('getMeanVal',obj.VideoReader);
          
       
       end
   end
   
   methods (Access=private)
       
   end
   
   % PROTECTED,STATIC
   methods (Static,Access=protected)
      function idx = getSeriesIndex(seriesTime,seriesTimeInfo)
         %GETSERIESINDEX  Returns index based on series start/stop times
         %
         %  idx = nigeLab.libs.nigelCamera(seriesTime,seriesTimeInfo);
         %
         %  seriesTime : Scalar -- time to update series to
         %  seriesTimeInfo : nSeries x 3 matrix
         %     * Column 1 -- "Enabled" (1) or "Disabled" (0)
         %     * Column 2 -- Start times (SERIES) (greater than or equals)
         %     * Column 3 -- Stop times (SERIES)  (less than)
         %
         
         if isempty(seriesTime) || isempty(seriesTimeInfo)
            idx = [];
            return;
         end
         
         % Uses mask:
         % idx = find(seriesTimeInfo(:,1) & ...
         %           (seriesTime >= seriesTimeInfo(:,2)) & ...
         %           (seriesTime <  seriesTimeInfo(:,3)),1,'first');
         
         % Disregards mask:
         idx = find( ...
                   (seriesTimeInfo(:,2) <= seriesTime) & ...
                   (seriesTimeInfo(:,3) > seriesTime),1,'last');
                % Note: in case of overlap in times, use "later" video.
      end
   end
   % % % % % % % % % % END METHODS% % %
end

