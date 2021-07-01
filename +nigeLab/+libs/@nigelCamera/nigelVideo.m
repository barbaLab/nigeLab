classdef nigelVideo < handle ...
                           & matlab.mixin.Copyable ...
                           & matlab.mixin.CustomDisplay ...
                           & matlab.mixin.SetGet
% VIDEOSFIELDTYPE  Constructor for class to track video file info
%
%  obj = nigeLab.libs.VideosFieldType(blockObj);
%  --> Initialize 'Videos' property (FieldType) of blockObj
%
%  obj = nigeLab.libs.VideosFieldType(n); 
%  --> Creates an "empty" row vector with n VideosFieldType object
   
   % % % PROPERTIES % % % % % % % % % %   
   % DEPENDENT,TRANSIENT,PUBLIC (no default values)
   properties (Access=private)
      Duration          double   % Duration of video (seconds)      
      GrossOffset (1,1) double   % Start-time with respect to neural data
      Height            double   % Height of video frame (pixels)
      Index             char     % Index of this video (for GoPro multi-videos)
      Key               char     % "Key" that corresponds to Block object
      Masked      (1,1)          % Is this video "masked" (true: enabled)?
      Name              char     % Name of video file
      NeuOffset   (1,1) double   % Generic start-time offset beyond the Video offset
      NumFrames         double   % Total number of frames
      ROI               cell     % Region of interest ({iRow, iCol})
      Source            char     % Camera "view" (e.g. Door, Top, etc...)
%       TrialOffset (1,1) double   % Trial/camera-specific offset
      Width             double   % Width of video frame (pixels)
      VarType           double   % 'Type' for each metadata variable
%       VideoIndex  (1,1) double   % Index of this video within array
      fs                double   % Sample rate
   end
   
   % HIDDEN,DEPENDENT,TRANSIENT,PUBLIC
   properties (Hidden,Transient,Access=public)
%       IsIdle   logical     % Returns flag indicating whether object is Idle
      HasVideoTrials (1,1) logical = false
      Meta       table     % Row of Block.Meta.Video corresponding to this video
      Parent               % Handle to "parent" nigeLab.Block object
      Pars      struct     % Parameters struct
%       StreamNames cell     % Cell array of unique child stream names
      V                    % VideoReader object
      fname_t     char     % Full filename of "time" file
      tNeu      double     % Time vector relative to Neural data
      tVid      double     % Time vector relative to Video
   end
   
%    % HIDDEN,TRANSIENT,PROTECTED
%    properties (Hidden,Transient,Access=protected)
%       HasVideoTrials_   logical
%       TrialIndex_       double       % Trial index
%       ScoringField_     char 
%       V_                             % VideoReader object
%       VideoIndex_       double       % Stored index
%       store_   (1,1)    struct = nigeLab.libs.VideosFieldType.initStore(); % struct to store parsed properties
%    end
   
   % HIDDEN,PUBLIC/PROTECTED
   properties (Hidden,GetAccess=public,SetAccess=?nigeLab.libs.nigelCamera)
      Streams           nigeLab.libs.VidStreamsType % nigeLab.libs.VidStreamsType video parsed streams
      VideoOffset (1,1) double = 0   % Start-time with respect to full video
   end
   
   % HIDDEN,PUBLIC
   properties (Hidden,Access=public)
      Exported    (1,1) logical = false  % Has it been exported to Trials?
      
   end
   
   % HIDDEN,PROTECTED
   properties (Hidden,Access=protected)
%       ROI_           cell = {}
      Time           nigeLab.libs.DiskData % disk-file for actual `Time` data
%       fname          char                  % Full filename of video
      mIndex         double                % Index into Block.Meta.Videos table for this object
   end
  
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % RESTRICTED:{nigeLab.Block,nigeLab.nigelObj}
   methods (Access={?nigeLab.Block,?nigeLab.nigelObj})
      % Class constructor
      function obj = nigelVideo(blockObj,F)
         % NIGELVIDEO  Constructor for class to handle video files
         %
         %  obj = nigeLab.libs.nigelVideo(blockObj);
         %  --> Initialize 'Videos' property (FieldType) of blockObj
         %
         %  obj = nigeLab.libs.VideosFieldType(n); 
         %  --> Creates an "empty" row vector with n VideosFieldType object
         %
         %  obj = nigeLab.libs.VideosFieldType(blockObj,F);
         %  --> Uses file struct 'F' (as returned by `dir`) to associate
         %        the videos in 'F' with nigeLab.Block object 'blockObj'
         
         if nargin < 1
            obj = nigeLab.libs.VideosFieldType.empty();
         elseif nargin == 1 && isnumeric(blockObj)
            dims = blockObj;
            if numel(dims) < 1
               dims = [0, 0];
            else
               dims = [0, max(dims)];
            end
            obj = repmat(obj,dims);
            return;
         end
         
         if nargin < 2
            F = [];
         end
         
         if numel(blockObj) > 1
            obj = nigeLab.libs.VideosFieldType.empty();
            for i = 1:numel(blockObj)
               obj = [obj, ...
                  nigeLab.libs.VideosFieldType(blockObj(i),F)]; %#ok<AGROW>
            end
            return;               
         end
         
         
         
      end

      % Initialize RELATIVE times for array of VideosFieldType objects
      function initRelativeTimes(obj,viewToInit)
         %INITRELATIVETIMES  Initialize relative times of consecutive
         %                    movies from a series, relative to one another
         %
         %  initRelativeTimes(obj,viewToInit);
         %
         %  viewToInit : Char array or cell array of char arrays containing
         %                 the 'View' to initialize (assumes that each
         %                 camera has a unique "View" label)
         
         if iscell(viewToInit)
            for i = 1:numel(viewToInit)
               initRelativeTimes(obj,viewToInit{i});
            end
            return;
         end
         
         if numel(obj)<=1
            return; % Nothing to set
         elseif ~isvalid(obj)
            return;
         elseif any(cellfun(@isempty,{obj.Source}))
            return;
         end
         
         h = findobj(obj,'Source',viewToInit);
         o = 0; % No video-related Offset initially
         for i = 1:numel(h)
            thisIndex = num2str(i-1); % zero-indexed
            hh = findobj(h,'Index',thisIndex);
            hh.VideoOffset = o;
            tt = get(hh,'tVid');
            o = max(tt) + (1/hh.fs); % offset by 1 frame from end of record
         end
      end
   end
   
   % NO ATTRIBUTES (Constructor)
   methods
      % % % (DEPENDENT) GET/SET.PROPERTY METHODS % % % % % % % % % % % %
      
      % [DEPENDENT]  Returns .GrossOffset property
      function value = get.GrossOffset(obj)
         %GET.GROSSOFFSET  Returns .GrossOffset property
         %
         % Returns scalar offset for this video relative to neural data 
         
         if obj.Block.HasVideoTrials
            value = obj.TrialOffset;
         else
            value = getEventData(obj.Block,obj.ScoringField_,...
               'ts','Header');
            value = value(obj.VideoIndex);
         end
      end
      function set.GrossOffset(obj,value)
         %SET.GROSSOFFSET  Assigns .GrossOffset property (to 'Header' diskdata)
         %
         %  set(obj,'GrossOffset',value);
         %  --> Assigns "Gross" offset that encompasses the VideoOffset as
         %  well as any additional generic offset between the video series
         %  and the neural data. Does not include the "trial-specific"
         %  offset component that can be set based on individual trial
         %  jitter.

         if obj.Block.HasVideoTrials
            obj.TrialOffset = value;
         else
            setEventData(obj.Block,obj.ScoringField_,...
               'ts','Header',value,obj.VideoIndex);
         end
      end
      
      % [DEPENDENT]  Returns .NeuOffset property
      function value = get.NeuOffset(obj)
         %GET.NEUOFFSET  Returns .NeuOffset property
         %
         %  value = get(obj,'NeuOffset');
         %  --> Returns the offset that is obj.GrossOffset -
         %  obj.VideoOffset
         
         if obj.Block.HasVideoTrials
            value = obj.GrossOffset;
         else
            value = obj.GrossOffset - obj.VideoOffset;
         end
      end
      function set.NeuOffset(obj,value)
         %SET.NEUOFFSET  Assign corresponding video of linked Block   
         %
         %  set(obj,'NeuOffset',value);
         %  --> value should be:
         %  value = (tNeu - tEvent) - tSpecific;
         %  Where tSpecific is the "Trial-Specific" and "Camera-Specific"
         %  offset.
         
         if obj.Block.HasVideoTrials
            obj.GrossOffset = value;
         else
            obj.GrossOffset = value + obj.VideoOffset;
         end
%          % Since times are relative to the VIDEO record, any time a NEURAL
%          % or TRIAL offset is changed, then change the event times
%          obj.Block.Trial = obj.Block.Trial - value;
%          obj.Block.EventTimes = obj.Block.EventTimes - value;
      end
           
      % [DEPENDENT]  Returns .V property (VideoReader object)
      function value = get.V(obj)
         %GET.PARS  Returns .V property
         %
         % Returns VideoReader
         
         value = [];
         if ~isempty(obj.V_)
            if isvalid(obj.V_)
               value = obj.V_;
               return;
            end
         end
         
         if isempty(obj.fname)
            return;
         elseif exist(obj.fname,'file')==0
            [p,f,e] = fileparts(obj.fname);
            p = nigeLab.utils.shortenedPath(p);
            f = nigeLab.utils.shortenedName([f e]);
            dbstack();
            nigeLab.utils.cprintf('Errors*',...
               '\t\t->\t[VIDEOSFIELDTYPE.GET.V]: ');
            fprintf(1,'Reference to invalid or deleted file: %s/%s\n',p,f);
            return;
         end
         
         value = VideoReader(obj.fname);
         obj.V_ = value;
      end
      function set.V(obj,value)
         %SET.V  Can delete value of obj.V_ (stored VideoReader)
         if isempty(value)
            if ~isempty(obj.V_)
               if isvalid(obj.V_)
                  delete(obj.V_);
                  obj.V_(:) = [];
               end
            end
         end
      end
           
      % [DEPENDENT]  Returns .fname_t property
      function value = get.fname_t(obj)
         %GET.FNAME_T  Return .fname_t property (.Time filename)
         %
         %  value = get(obj,'fname_t');
         %  --> Returns char array to .Time filename
         %     --> Requires .Block to be set
         
         value = '';
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.Block)
            return;
         elseif ~isvalid(obj.Block)
            return;
         end
         expr = strrep(obj.Block.Paths.Video.file,'\','/');
         if obj.HasVideoTrials
            [p,tmp,~] = fileparts(obj.fname);
            value = fullfile(p,sprintf('%s.mat',tmp));
         else
            sName = sprintf('Time-%s',obj.Index);
            value = sprintf(expr,obj.Source,sName,'mat');
         end
      end
      function value = get.HasVideoTrials(obj)
         value = false;
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif ~isempty(obj.HasVideoTrials_)
            value = obj.HasVideoTrials_;
            return;
         elseif isempty(obj.Block)
            return;
         end
         if isfield(obj.Block.IDInfo,'HasVideoTrials')
            value = logical(str2double(obj.Block.IDInfo.HasVideoTrials));
         else
            value = obj.Block.HasVideoTrials;
         end
         obj.HasVideoTrials_ = value;
      end
            
      % [DEPENDENT]  Returns .tNeu property
      function value = get.tNeu(obj)
         %GET.tNeu  Returns .tNeu property
         %
         % Returns time vector associated with each frame of the video
         %  --> This is in the "same time-alignment" as neural data (as
         %        long as obj.Offset has been set correctly)
         
         value = [];
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.Time)
            initTimeFile(obj); % Try "re-init"
            if ~checkSize(obj.Time)
               error(['nigeLab:' mfilename ':BadInit'],...
                  '[VIDEOSFIELDTYPE]: Bad time file initialization');
            end
         elseif ~checkSize(obj.Time)
            if ~checkSize(obj.Time)
               error(['nigeLab:' mfilename ':BadInit'],...
                  '[VIDEOSFIELDTYPE]: Bad time file initialization');
            end
         elseif isnan(obj.GrossOffset)
            return;
         end
         
         tmp = obj.Time.data(:);
         value = tmp+obj.GrossOffset;
      end
      function set.tNeu(obj,~)
         %SET.TNEU  Assigns .tNeu property (cannot)
         
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: tNeu\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .tVid property
      function value = get.tVid(obj)
         %GET.tVid  Returns .tVid property
         %
         % Returns time vector associated with each frame of the video
         %  --> This is without respect to the neural data
         
         value = [];
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.Time)
            initTimeFile(obj); % Try "re-init"
            if ~checkSize(obj.Time)
               error(['nigeLab:' mfilename ':BadInit'],...
                  '[VIDEOSFIELDTYPE]: Bad time file initialization');
            end
         elseif ~checkSize(obj.Time)
            initTimeFile(obj); % Try "re-init"
            if ~checkSize(obj.Time)
               error(['nigeLab:' mfilename ':BadInit'],...
                  '[VIDEOSFIELDTYPE]: Bad time file initialization');
            end
         end
         
         tmp = obj.Time(:);
         % Value returned only reflects start Offset (obj.VideoOffset) within
         % series of videos related to each other
         value = tmp + obj.VideoOffset;
         
      end
      function set.tVid(obj,~)
         %SET.TVID  Assigns .tVid property (cannot)
         
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: tVid\n');
            fprintf(1,'\n');
         end
      end
      % % % % % % % % % % END (DEPENDENT) GET/SET.PROPERTY METHODS % % %
   end
   
   % PUBLIC
   % Common methods
   methods (Access=public)   
      % Return all videos from the same "Source"
      function obj = FromSame(objArray,sourceName)
         %FROMSAME  Return all videos from the same "source"
         %
         %  obj = FromSame(objArray,'Left-A');
         %  --> Returns all VideosFieldType objects from an array that have
         %      .Source of 'Left-A'
         
         if nargin < 2
            sourceName = objArray.Source;
            objArray = objArray.Block.Videos;
         end
         
         if isa(sourceName,'nigeLab.libs.VideosFieldType')
            obj = objArray(strcmpi({objArray.Source},sourceName.Source));
         elseif ischar(sourceName)
            obj = objArray(strcmpi({objArray.Source},sourceName));
         else
            error(['nigeLab:' mfilename ':BadClass'],...
               ['\t\t->\t[VIDEOSFIELDTYPE]: ' ...
               'Invalid sourceName class (''%s'')\n'],...
               class(sourceName));
         end
      end
      
      % "Idles" the VideosFieldType object (removes VideoReader)
      function Idle(obj)
         %IDLE  "Idles" the VideosFieldType object to reduce memory usage
         %
         %  Idle(obj);
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               Idle(obj(i));
            end
            return;
         end
         
         obj.V = []; % This deletes obj.V_ due to [Dependent] property .V
      end
      
      % Returns Max timestamp from videos in objArray
      function tMax = Max(objArray)
         %MAX  Return maximum timestamp value from videos in objArray
         %
         %  tMax = Max(objArray);
         
         tMax = -inf;
         for i = 1:numel(objArray)
            tMax = max(tMax,max(objArray(i).tVid));
         end
      end
      
      % Find video from parent object array of videos
      function idx = findVideo(obj,objArray)
         %FINDVIDEO  Returns index to object from parent object array
         %
         %  idx = findVideo(obj);
         %  --> Return idx as element of parent .Block.Videos array
         %
         %  idx = findVideo(obj,objArray);
         %  --> Return idx as element of objArray
         %
         %  idx = findVideo(obj,objArray);
         %  --> if no elements of objArray match obj, then the index is
         %        equal to the number of elements in objArray + 1
         
         if nargin < 2
            objArray = obj.Block.Videos;
         end
         
         if numel(obj) > 1
            idx = ones(size(obj));
            for i = 1:numel(obj)
               idx(i) = findVideo(obj(i));
            end
            return;
         end
         idx = find(objArray == obj,1,'first');
         if isempty(idx)
            if isempty(obj.mIndex)
               idx = numel(objArray)+1;
            else
               idx = obj.mIndex;
            end
         end
      end
      
      % Returns the VidStream corresponding to streamName & source
      function stream = getStream(obj,streamName,source,scaleOpts,stream)
         % GETSTREAM  Return a struct with the fields 'name', 'data' and
         %              'fs' that corresponds to the video stream named
         %              'streamName'. If obj is an array, then 'data' is
         %              concatenated by info.Source so that a single 'data'
         %              field represents the full recording session (if
         %              there are multiple videos from same Source).
         %
         %  stream = obj.getStream(streamName,source);
         %
         %  streamName  --  Name of stream
         %  source  --  Signal "source" (camera angle)
         %  scaleOpts  --  Struct with scaling options for stream
         %  stream  --  Typically not specified; provided by recursive
         %                 method call so that streams can be concatenated
         %                 together.  
         
         if nargin < 5
            stream = nigeLab.utils.initChannelStruct('SubStreams',0);
         end
         
         if nargin < 4
            scaleOpts = nigeLab.utils.initScaleOpts();
         end
         
         if nargin < 3
            error(['nigeLab:' mfilename ':TooFewInputs'],...
               '[VIDEOSFIELDTYPE]: Must provide 3 input arguments.');
         end
         
         idx = findIndex(obj,{streamName; source},{'Name','Source'});
         if all(isnan(idx))
            stream = [];
            return;
         else
            vec = find(~isnan(idx));
            vec = reshape(vec,1,numel(vec));
         end
         stream.name = streamName;
         for i = vec
            stream.data = [stream.data, ...
               obj(i).Streams.at(idx(i)).diskdata.data];
         end
         stream.fs = obj.at(idx).fs;
         stream.t  = obj.tNeu;
         stream.data = nigeLab.utils.applyScaleOpts(stream.data,scaleOpts);
         
      end
      
      % Assign video offsets to array of videosfieldtype objects
      function setVideoOffsets(objArray,vidOffsets)
         if numel(objArray) ~= numel(vidOffsets)
            error(['nigeLab:' mfilename ':BadSize'],...
               ['\t\t->\t<strong>[VIDEOSFIELDTYPE/SETVIDEOOOFFSETS]: ' ...
               'Video array and offset array must be same size\n']);
         end
         
         if numel(objArray) > 1
            for i = 1:numel(objArray)
               setVideoOffsets(objArray(i),vidOffsets(i));
            end
            return;
         end
         
         objArray.VideoOffset = vidOffsets;         
      end
      
      % Updates .fname by replacing the "path" portion of the file name
      function updateVideoFileLocation(obj,newFolderPath)
         %UPDATEVIDEOFILELOCATION  Updates .fname by replacing "path"
         %
         %  updateVideoFileLocation(obj,newFolderPath);
         %  
         %  obj : nigeLab.libs.VideosFieldType object or array
         %  newFolderPath : New path to video files
         
         if nargin < 2
            error(['nigeLab:' mfilename ':TooFewInputs'],...
               ['\t\t->\t<strong>[VIDEOSFIELDTYPE]:</strong> ' ...
               '`updateVideoFileLocation` requires 2 inputs.\n']);
         end
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               updateVideoFileLocation(obj(i),newFolderPath);
            end
            return;
         end
         
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         end
         
         [~,f,e] = fileparts(obj.fname);
         obj.fname = strrep(fullfile(newFolderPath,[f e]),'\','/');
         
      end
   end
   
   % HIDDEN,PUBLIC
   methods (Hidden,Access=public)
      function updateScoringField(obj)
         %UPDATESCORINGFIELD  To update .ScoringField_ on Block change
         %
         %  updateScoringField(obj);
         for i = 1:numel(obj)
            obj(i).ScoringField_ = obj(i).Block.ScoringField;
         end
      end
   end
   
   % PROTECTED
   methods (Access=protected)
      % Overloaded method from CustomDisplay superclass
      function displayScalarObject(obj)
         %DISPLAYSCALAROBJECT  Modified subclass method to display scalar
         %
         %  displayScalarObject(obj);
         %  --> Ensures that simply displaying the object does not cause a
         %      VideoReader object to sit in memory taking up space.
         

         header = getHeader(obj);
         disp(header);
         
         groups = getPropertyGroups(obj);
         matlab.mixin.CustomDisplay.displayPropertyGroups(obj,groups);
         
         footer = getFooter(obj,'detailed');
         disp(footer);
      end
      
      % Overloaded method from CustomDisplay superclass
      function s = getFooter(obj,displayType)
         %GETFOOTER  Method overload from CustomDisplay superclass
         %
         %  s = obj.getFooter();
         %  --> Returns custom footer string that links object to
         %      immediately pull up "nigelDash" GUI
         %
         %  s = obj.getFooter('simple'); 
         %  --> Returns footer string for link to "condensed" view
         
         if nargin < 2
            displayType = 'detailed';
         end
         
         s = '';
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         end
         s = [obj(1).Block.getLink('Video') newline];
         if strcmpi(displayType,'simple') || numel(obj) > 1
            return;
         end
         
         if isunix
            return; % I don't know the "winopen" equivalent here
         else
            s = ...
               [s, ...
               sprintf('\t-->\t'), ...
               sprintf('<a href="matlab: winopen(''%s'');">%s</a>\n',...
                  obj.fname,'View in Media Player')];
         end
      end
      
      % Overloaded method from CustomDisplay superclass
      function groups = getPropertyGroups(obj)
         %GETPROPERTYGROUPS  Modified subclass method to correctly display
         %                    "idle" status
         %
         %  groups = getPropertyGroups(obj);
         %  --> Called via `displayScalarObject`
         
         if isempty(obj)
            groups = matlab.mixin.util.PropertyGroup.empty();
            return;
         elseif ~isvalid(obj)
            groups = matlab.mixin.util.PropertyGroup.empty();
            return;
         elseif ~isscalar(obj)
            groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            return;
         end
         flag = obj.IsIdle;
         groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
         if flag
            groups.Title = '<strong>Current Status: Idle</strong>';
            Idle(obj); % Make sure it actually is idle
         else
            groups.Title = '<strong>Current Status: Ready</strong>';
         end
      end
      
      % Find videos manually (if `findVideos` fails to find anything)
      function F = getVidFileUI(obj,validExt,selTitle,defSearchPath)
         % GETVIDFILEUI  Open selection UI to allow (manual) video select
         %
         %  F = obj.getVidFileUI();
         
         if nargin < 2
            validExt = obj.Pars.ValidVidExtensions;
         end
         
         if nargin < 3
            nigeLab.sounds.play('pop',2.5);
            selTitle = sprintf('[%s] Auto-Find failed: Select Videos',...
               obj.Block.Name);
         end
         
         if nargin < 4
            defSearchPath = obj.Pars.DefaultSearchPath;
         end
         
         [fileName,pathName] = uigetfile(validExt,selTitle,defSearchPath);

         if fileName == 0
            nigeLab.utils.cprintf('Errors*','/t/t->/t[VIDEOSFIELDTYPE]: ');
            fprintf(1,'No file selected\n');
            F = struct.empty;
            return;
         end
         
         % Use static method of nigeLab.libs.VideosFieldType class
         bMeta = obj.Block.Meta;
         ext = obj.Paths.V.FileExt;
         pars = obj.Pars;
         if obj.Block.HasVideoTrials
            pars.DynamicVars = pars.DynamicVarsTrials;
         end
         matchStr = nigeLab.libs.VideosFieldType.parse(bMeta,pars,ext);
         F = dir(nigeLab.getUNCPath(pathName,matchStr));
         
      end
      
       % Add video streams to this object based on 'signals'
      function initStreams(obj,forceOverwrite)
         % ADDSTREAMS  Add video streams to this object based on 'signals'
         %
         %  initStreams(obj);
         
         if nargin < 2
            forceOverwrite = false;
         end
         
         % Iterate on array
         if numel(obj) > 1
            for i = 1:numel(obj)
               initStreams(obj(i));
            end
            return;
         end
         
         % Make sure obj.store_ is initialized
         obj.store_ = obj.initSecondaryTempProps();
         
         % Check to see if .Streams was saved (if it already exists)
         if ~isempty(obj.Streams) && initTimeFile(obj) && (~forceOverwrite)
            % If .Streams already exist, then just re-load the pointer to
            % this "parent" object on "child" objects
            obj.Streams=nigeLab.libs.VidStreamsType(obj,obj.Streams);
            return;
         end
         
         % Find the .Source
         if isempty(obj.Pars.VidStream)
            sourceList = {obj.Pars.CameraKey.Source};
            iSource = find(ismember(sourceList,obj.Source),1,'first');
            if isempty(iSource)
               linkStr = [...
                  '<a href="matlab:opentoline(' ...
                  '''+nigeLab/+defaults/Video.m'',146);">' ...
                  'nigeLab.defaults.Videos</a>'];
               error(['nigeLab:' mfilename ':BadConfig'],...
                  'Bad (or unconfigured) camera source: %s (check %s)',...
                  obj.Source,...
                  linkStr);
            end
            signalIndex = obj.Pars.CameraKey(iSource).Index;
            source = repmat({obj.Source},1,...
               numel(obj.Pars.VidStreamGroup{signalIndex}));
            vidSig = nigeLab.utils.signal(...
                  obj.Pars.VidStreamGroup{signalIndex},...
                  obj.NumFrames,...
                  obj.Pars.VidStreamField{signalIndex},...
                  obj.Pars.VidStreamFieldType{signalIndex},...
                  source,...
                  obj.Pars.VidStreamName{signalIndex},...
                  obj.Pars.VidStreamSubGroup{signalIndex});
         else
            vidSig = obj.Pars.VidStream;
         end
         obj.Streams = nigeLab.libs.VidStreamsType(obj,vidSig); 
      end

      % Initialize "primary" temporary properties in storage struct
      function sto_ = initPrimaryTempProps(obj)
         %INITPRIMARYTEMPPROPS
         
         % obj.store_ is initialized to have the correct fields
         sto_ = obj.store_;
         
         % Derived from `Block` --> `Meta`/`Pars`
         if isempty(obj.Block)
            return; % Nothing goes without obj.Block
         elseif isempty(obj.Meta)
            return; % Then "meta" index is missing
         elseif ~isfield(obj.Block.Pars,'Video')
            return; % Then .Pars doesn't work
         end
         sto_.Key = obj.Meta.Key{:};
         sto_.Index = obj.Meta.(obj.Pars.MovieIndexVar){:};
         sto_.Source = obj.Meta.(obj.Pars.CameraSourceVar){:};
         
         % Name is derived from obj.fname (cannot do props below otherwise)
         if ~isempty(obj.fname)
            [~,sto_.Name,~] = fileparts(obj.fname);
         else
            return; % Then .VideoReader does not work either.
         end
      end
      
      % Initialize "secondary" temp properties storage struct
      function sto_ = initSecondaryTempProps(obj)
         %INITSECONARYTEMPPROPS  Initialize "secondary" temp props struct
         %
         %  sto_ = initSecondaryTempProps(obj);
         %  --> Returns copy of struct that is stored in obj.store_, which
         %      is used to temporarily hold in memory values parsed from
         %      larger VideoReader object etc to avoid reading into and out
         %      of memory too frequently if you are just referencing
         %      smaller values like the framerate or something.
         
         flag = obj.IsIdle;
         
         sto_ = initPrimaryTempProps(obj);
         if isempty(sto_.Name)
            return;
         end
         
         % Since obj.fname is not empty, only need to check that it points
         % to a valid file
         if exist(obj.fname,'file')==0
            return;
         elseif isempty(obj.V) % This constructs obj.V if it does not exist
            return; % But if it is not a video file it will be empty
         end
         sto_.Duration = obj.V.Duration;
         sto_.Height = obj.V.Height;
         sto_.fs = obj.V.FrameRate;
         sto_.NumFrames = floor(sto_.Duration*sto_.fs);
         sto_.Width = obj.V.Width;
         
         % If the VideoReader object was constructed to parse these
         % properties, close it.
         if flag
            Idle(obj);
         end
      end
      
      % Initialize Video_[view]_[index].mat file that keeps track of time
      function flag = initTimeFile(obj)
         %INITTIMEFILE  Initialize diskfile for indexing time
         %
         %  flag = obj.initTimeFile(fname)
         %  --> Returns true if .Time file already existed
         
         % Before initializing .Streams, need to initialize .Time as well
         flag = exist(obj.fname_t,'file')~=0;
         if flag % If it exists, link them up
            obj.Time = nigeLab.libs.DiskData('MatFile',obj.fname_t);
         else % Otherwise, create the file
            data = linspace(0,obj.Duration,obj.NumFrames);
            obj.Time = nigeLab.libs.DiskData('MatFile',obj.fname_t,data,...
               'access','w','size',size(data),'class',class(data),...
               'overwrite',true);
         end
         if isempty(obj.Time.Complete)  % If `Complete` not initialized
            if obj.Time.Locked
               unlockData(obj.Time); % Make sure it is accessible
            end
            SetCompletedStatus(obj.Time,true);
         end
      end
      
      % Convert '.Key' ending to index from overall list of videos
      function idx = keyToIndex(obj)
         %KEYTOINDEX  Convert 'Key' to Index in overall list of videos
         %
         %  idx = keyToIndex(obj);
         
         idx = strsplit(obj.Key,'-');
         idx = str2double(idx{2}) + 1;
      end
   end
   
   % STATIC,PUBLIC (empty)
   methods (Static,Access=public)
      % Create "Empty" object or object array
      function obj =  empty(n)
         %EMPTY  Return empty nigeLab.libs.VideosFieldType object or array
         %
         %  obj = nigeLab.libs.VideosFieldType.empty();
         %  --> Return scalar (0 x 0) object
         %
         %  obj = nigeLab.libs.VideosFieldType.empty(n);
         %  --> Specify number of empty objects
         
         if nargin < 1
            dims = [0, 0];
         else
            if ~isscalar(n)
               error(['nigeLab:' mfilename ':invalidEmptyDims'],...
                  'Input to nigeLab.libs.VideosFieldType.empty should be scalar.');
            end
            dims = [0, n];
         end
         
         obj = nigeLab.libs.nigelVideo(dims);
      end
      
      % Return "name-matching" string for finding videos associated with a
      % block
      function s = parse(meta,pars,ext)
         % PARSEVIDMATCHSTRING  Return "name-matching" string for vids
         %
         %  s = nigeLab.libs.VideosFieldType.parse(meta,pars);
         %  --> Returns char array s, for example if name of Block is
         %  'R19-162_2019_09_18_1' would return 'R19-162*2019*09*18*1.MP4'
         %  (depending on how pars.DynamicVars is configured). 
         %
         %  s = nigeLab.libs.VideosFieldType.parse(meta,pars,ext);
         %  --> Appends the extension in `ext` to returned char array
         %     --> If ext is '.avi' then previous example might return: 
         %     'R19-162*2019*09*18*1.avi'
         %
         %  meta : nigeLab.Block.Meta equivalent struct
         %  pars : nigeLab.Block.Pars.Video equivalent struct
         %  ext  : char array [e.g. '.MP4' (typical default) or '.avi' etc]
         
         if nargin < 2
            error(['nigeLab:' mfilename ':TooFewInputs'],...
               '[PARSEVIDMATCHSTRING]: Must provide `meta` and `pars` args');
         end
         
         if nargin < 3
            ext = pars.FileExt; % Uses default value (typically '.MP4')
         end
        

         dynamicVars = cellfun(@(x)x(2:end),...
            pars.DynamicVars,...
            'UniformOutput',false);
         toMatch = ismember(dynamicVars,pars.RecTag);
         inMeta = ismember(pars.RecTag,fieldnames(meta));
         if ~any(inMeta)
            fD =fieldnames(pars.DynamicVars);
            fM = fieldnames(meta);
            if obj.Block.Verbose
               nigeLab.sounds.play('alert',0.8);
               dbstack();
               nigeLab.utils.cprintf('Errors*',...
                  '\t\t->\t[VIDEOSFIELDTYPE/PARSEVIDMATCHSTRING]: ');
               nigeLab.utils.cprintf('Errors',...
                  ['Could not find any metadata fields matching fields ' ...
                   ' of given nigeLab.Block.Pars.Video.DynamicVars: \n']);
               nigeLab.utils.cprintf('[0.5 0.5 0.5]*',...
                  '\t\t\t->\t%s\n',fD{:});
               nigeLab.utils.cprintf('Errors',...
                  'When compared to nigeLab.Block.Meta: \n');
               nigeLab.utils.cprintf('Comments',...
                  '\t\t\t->\t%s\n',fM{:});
               fprintf(1,'\t->\tReturning wildcard matchStr (''*'')\n');
               fprintf(1,'\t\t->\t(Note that this is not intended use; check config)\n');
            end
            s = '*';
            return;
         end
         
         s = repmat({'*'},1,numel(dynamicVars));
         s(toMatch) = cellfun(@(x) meta.(x),...
             dynamicVars(toMatch),...
             'UniformOutput',false);

         s = strjoin(s,pars.Delimiter);
         s = [s, ext];
         
      end
   end
   
   % STATIC,PROTECTED (internal initialization methods)
   methods (Static,Access=protected)
      % Initialize .store (protected) property
      function store_ = initStore()
         %INITSTORE  Initialize nigeLab.libs.VideosFieldType.store property
         %
         %  store_ = nigeLab.libs.VideosFieldType.store();
         %  --> Should just be used to set default struct in property list
         
         store_ = struct(...
            'Duration',[],...      
            'Height',[],...
            'Index',[],...
            'Key',[],...
            'Name',[],...
            'NumFrames',[],...
            'Source',[],...
            'Width',[],...
            'fs',[]);
      end
   end
   % % % % % % % % % % END METHODS% % %
end