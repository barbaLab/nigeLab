classdef VideosFieldType < handle
% VIDEOSFIELDTYPE  Constructor for class to track video file info
%
%  obj = nigeLab.libs.VideosFieldType(blockObj);
%  --> Initialize 'Videos' property (FieldType) of blockObj
%
%  obj = nigeLab.libs.VideosFieldType(n); 
%  --> Creates an "empty" row vector with n VideosFieldType object
%
%  obj = nigeLab.libs.VideosFieldType(blockObj,F);
%  --> Uses file struct 'F' (as returned by `dir`) to associate
%        the videos in 'F' with nigeLab.Block object 'blockObj'
   
   properties (GetAccess = public, SetAccess = private)
      Streams nigeLab.libs.VidStreamsType    % nigeLab.libs.VidStreamsType video parsed streams
      Duration double   % Duration of video (seconds)      
      FS double         % Sample rate
      Height double     % Height of video frame (pixels)
      Name char         % Name of video file
      NFrames double    % Total number of frames
      Width double      % Width of video frame (pixels)
      Source char       % Camera "view" (e.g. Door, Top, etc...)
      Index  char       % Index of this video 
      
   end
   
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      isConfigured logical % Flag indicating that pars.HasVideo is true or not
      isParsed = false   % Flag indicating that vid metadata has been parsed
      isEmpty  = true    % Flag to indicate that this is an "empty" data object
      meta         % Struct with metadata parsed from name and DynamicVars parameter
      pars         % Parameters struct
   end
   
   properties (Access = public)
      tStart double
      tStop double
      offset double
   end
   
   properties (Access = private)
      fname char      % Full filename of video
   end
   
   properties (SetAccess = immutable, GetAccess = private)
      Block nigeLab.Block  % Internal reference property
   end
   
   % PUBLIC
   % Constructor
   methods (Access = public)
      % Class constructor
      function obj = VideosFieldType(blockObj,F)
         % VIDEOSFIELDTYPE  Constructor for class to track video file info
         %
         %  obj = nigeLab.libs.VideosFieldType(blockObj);
         %  --> Initialize 'Videos' property (FieldType) of blockObj
         %
         %  obj = nigeLab.libs.VideosFieldType(n); 
         %  --> Creates an "empty" row vector with n VideosFieldType object
         %
         %  obj = nigeLab.libs.VideosFieldType(blockObj,F);
         %  --> Uses file struct 'F' (as returned by `dir`) to associate
         %        the videos in 'F' with nigeLab.Block object 'blockObj'
         
         if nargin < 2
            F = [];
         end
         
         if isa(blockObj,'nigeLab.Block')
            if numel(blockObj) > 1
               obj = nigeLab.libs.VideosFieldType(numel(blockObj));
               for i = 1:numel(blockObj)
                  obj(i) = nigeLab.libs.VideosFieldType(blockObj(i));
               end
               return;               
            end
            
            obj.Block = blockObj;            
         else
            if isnumeric(blockObj) % Allows array initialization
               dims = blockObj;
               if numel(dims) < 2 
                  dims = [1,dims];
               end
               obj = repmat(obj,dims);
               return;
            else
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Invalid input type: %s',class(blockObj));
            end
         end

         obj.isEmpty = false; % No longer an empty object
         obj.updateParams();
         
         if isempty(F)
            F = obj.findVideos();
            if isempty(F)
               F = obj.getVidFileUI();
               if isempty(F)
                  error(['nigeLab:' mfilename ':noVideosFound'],...
                     'No video files could be parsed in that location.');
               end
            end
         end
         
         % Handle input array struct (such as returned by 'dir')
         if numel(F) > 1 
            obj = nigeLab.libs.VideosFieldType(numel(F));
            for i = 1:numel(F)
               obj(i) = nigeLab.libs.VideosFieldType(blockObj,F(i));
            end
            return;
         end

         obj.fname = nigeLab.utils.getUNCPath(F.folder,F.name);
         [~,obj.Name,~] = fileparts(obj.fname);
         obj.parseMetaData; % Parse metadata from name
         obj.setVideoInfo;  % Get other video properties from the file
      end
   end
   
   % PUBLIC
   % Common methods
   methods (Access = public, Hidden = false)   
      % Add video streams to this object based on 'signals'
      function addStreams(obj,vidStreamSignals)
         % ADDSTREAMS  Add video streams to this object based on 'signals'
         %
         %  obj.addStreams(vidStreamSignals);
         %
         %  vidStreamSignals -- nigeLab.utils.signal class object (scalar
         %                          or array). This value is set as the
         %                          'obj.at' property for each element of
         %                          the returned obj array. For example, if
         %                          vidStreamSignals is an array, and
         %                          videosFieldObj is an array, then it
         %                          means each returned element of obj
         %                          corresponds to a video with all the
         %                          streams in vidStreamSignals.
         
         % For an array input, initialize the same set of signals for each
         % video in the array, since it will be used the same way for each
         % video in a given recording.
         
         switch nargin
            case 1
               if numel(obj) > 1
                  for i = 1:numel(obj)
                     obj(i).addStreams();
                  end
                  return;
               end
               iSource = find(ismember({obj.pars.CameraKey.Source},obj.Source),1,'first');
               if isempty(iSource)
                  error(['nigeLab:' mfilename ':unrecognizedCameraSource'],...
                     'Bad (or unconfigured) camera source: %s (check %s)',...
                     obj.Source,nigeLab.utils.getNigeLink('nigeLab.defaults.Videos'));
               end
               signalIndex = obj.pars.CameraKey(iSource).Index;
               source = repmat({obj.Source},1,...
                  numel(obj.pars.VidStreamGroup{signalIndex}));
               vidStreamSignals = nigeLab.utils.signal(...
                  obj.pars.VidStreamGroup{signalIndex},...
                  obj.pars.VidStreamField{signalIndex},...
                  obj.pars.VidStreamFieldType{signalIndex},...
                  source,...
                  obj.pars.VidStreamName{signalIndex},...
                  obj.pars.VidStreamSubGroup{signalIndex});
               
            case 2
               if numel(obj) > 1
                  for i = 1:numel(obj)
                     obj(i).addStreams(vidStreamSignals);
                  end
                  return;
               end

               obj.Streams = nigeLab.libs.VidStreamsType(obj,...
                              vidStreamSignals);         
            otherwise
               error(['nigeLab:' mfilename ':invalidNumInputs'],...
                  'addStreams needs at least 1 or 2 inputs.');
         end
      end
      
      % Return the times corresponding to each video frame
      function t = getFrameTimes(obj)
         % GETFRAMETIMES  Return the times corresponding to each video
         %                 frame. These are with respect to the START of
         %                 the NEURAL RECORDING, although the initial state
         %                 will only reference any past videos (e.g. if
         %                 this is the third video from the same camera, on
         %                 the same recording) until the videos are
         %                 aligned.
         %
         %  t = obj.getFrameTimes;
         
         if numel(obj) > 1
            t = cell(numel(obj),1);
            for i = 1:numel(obj)
               t{i} = getFrameTimes(obj(i));
            end
            return;
         end
         t = linspace(0,obj.Duration,obj.NFrames);
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
            error('Must provide 3 input arguments.');
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
         stream.t = (0:(numel(stream.data)-1))/stream.fs;
         stream.data = nigeLab.utils.applyScaleOpts(stream.data,scaleOpts);
         
      end
      
      % Get VideoReader object
      function V = getVideoReader(obj)
         % GETVIDEOREADER  Returns video reader object
         
         V = VideoReader(obj.fname);
      end

      % OVERLOAD: isEmpty
      function tf = isempty(obj)
         % ISEMPTY  Overloaded function to determine if this is empty
         %
         %  tf = isempty(obj);
         
         if numel(obj) > 1
            tf = true(size(obj));
            for i = 1:numel(obj)
               tf(i) = obj(i).isempty;
            end
            return;
         end
         
         if obj.isEmpty
            tf = true;
            return;
         end
         
         if numel(obj) == 0
            tf = true;
            return;
         end
         
      end

   end
   
   % PRIVATE
   % Sets properties for internal reference
   methods (Access = private)      
      % Find videos (for constructor)
      function F = findVideos(obj)
         %FINDVIDEOS Get string for parsing matched video file names
         %
         %  F = obj.findVideos();   
         %
         %  F : File struct as returned by `dir` commmand, where .name
         %        property refers to the video file. This may be a struct
         %        array, in which case each element corresponds to a
         %        different video that is associated with the recording.
         
         % On first pass, use the FileExt parameter
         matchStr = obj.getNameMatchingString(obj.pars.FileExt);

         % Look for video files. Stop after first path where videos are found.
         i = 0;
         while i < numel(obj.pars.VidFilePath)
            i = i + 1;
            F = dir(nigeLab.utils.getUNCPath(obj.pars.VidFilePath{i},matchStr));
            if ~isempty(F)
               break;
            end
         end
         % Throw error if no videos are found
         if isempty(F)
            error(['nigeLab:' mfilename ':noVideosFound'],...
               ['Couldn''t find video files (matchStr: ''%s''). '...
                'Check defaults.Video(''DynamicVars'')'], matchStr);
         end
      end
      
      % Return "name-matching" string for finding associated videos
      function matchStr = getNameMatchingString(obj,ext)
         % GETNAMEMATCHINGSTRING  Return "name-matching" string for vids
         %
         %  matchStr = obj.getNameMatchingString();
         %  --> Does not append an extension to "matcher" string
         %
         %  matchStr = obj.getNameMatchingString(ext);
         %  --> Appends the extension in `ext` to end of `matchStr`
         
         if nargin < 2
            ext = '';
         end
         
         dynamicVars = cellfun(@(x)x(2:end),...
            obj.pars.DynamicVars,...
            'UniformOutput',false);
         idx = find(ismember(dynamicVars,fieldnames(obj.Block.Meta)));
         if isempty(idx)
            error(['nigeLab:' mfilename ':badDynamicVarConfig'],...
               ['Could not find any metadata fields to use for ' ...
                'parsing Video filenames.']);
         end

         matchStr = '*';
         for i = 1:numel(idx)
            matchStr = [matchStr, ...
                     obj.Block.Meta.(dynamicVars{idx(i)}) '*']; %#ok<*AGROW>
         end
         matchStr = [matchStr, ext];
         
      end
      
      % Find videos manually (if `findVideos` fails to find anything)
      function F = getVidFileUI(obj)
         % GETVIDFILEUI  Open selection UI to allow (manual) video select
         %
         %  F = obj.getVidFileUI();
         
         [fileName,pathName,~] = uigetfile(obj.pars.ValidVidExtensions,...
                                     obj.pars.SelectionUITitle,...
                                     obj.pars.DefaultSearchPath);

         if fileName == 0
            error(['nigeLab:' mfilename ':noSelection'],...
                   'No video file selected.');
         end
         matchStr = obj.getNameMatchingString();
         F = dir(nigeLab.getUNCPath(pathName,matchStr));
         
      end
      
      % Parse metadata from .fname property
      function parseMetaData(obj)
         % PARSEMETADATA  Parse name metadata using DynamicVars parameter
         %
         %  obj.parseMetaData();
         
         name_data = strsplit(obj.Name,obj.pars.Delimiter);
         if numel(name_data) ~= numel(obj.pars.DynamicVars)
            error(['nigeLab:' mfilename ':nDynamicVarMismatch'],...
               ['Mismatch between number of parsed name elements (%g)' ...
                ' and number of cell elements in DynamicVars (%g)'],...
               numel(name_data),numel(obj.pars.DynamicVars));
         end
         
         obj.meta = struct;
         for i = 1:numel(name_data)
            if strcmp(obj.pars.DynamicVars{i}(1),obj.pars.IncludeChar)
               obj.meta.(obj.pars.DynamicVars{i}(2:end)) = name_data{i};
            end
         end
         if isfield(obj.meta,obj.pars.MovieIndexVar)
            obj.Index = obj.meta.(obj.pars.MovieIndexVar);
         else
            obj.Index = nan;
         end
         if ~isempty(obj.pars.CameraSourceVar)
            if isfield(obj.meta,obj.pars.CameraSourceVar)
               obj.Source = obj.meta.(obj.pars.CameraSourceVar);
            else
               obj.Source = obj.pars.VidStreamSource;
            end
         else
            obj.Source = obj.pars.VidStreamSource;
         end
         
      end
      
      % Set video-related info properties
      function setVideoInfo(obj,propName,propVal)
         % SETVIDEOINFO  Sets the properties related to video info
         %
         %  obj.SETVIDEOINFO; % Set all properties
         %  obj.SETVIDEOINFO('propName',propVal); % Set a specific
         %                                        % property/value pair
         
         if nargin < 3
            V = getVideoReader(obj);
            obj.Name = V.Name;
            obj.Duration = V.Duration;
            obj.FS = V.FrameRate;
            obj.Height = V.Height;
            obj.Width = V.Width;
            obj.NFrames = round(obj.Duration/obj.FS);
%             obj.NFrames = V.NumberOfFrames; % Holy crap this is slow
            delete(V);
            
         else
            obj.(propName) = propVal;
         end
      end
      
      % Update parameters associated with this object
      function updateParams(obj)
         % UPDATEPARAMS  Update parameters associated with this object
         %
         %  obj.updateParams();   
         
         obj.pars = obj.Block.Pars.Video;
         obj.pars.Vars = obj.Block.Pars.Video.VarsToScore;
      end
   end
   
   % PUBLIC
   % STATIC  -- for making "empty" arrays
   methods (Access = public, Static = true)
      % Create "Empty" object or object array
      function obj = Empty(n)
         % EMPTY  Create "empty" object or object array
         if nargin < 1
            dims = [0, 1];
         else
            if ~isscalar(n)
               error(['nigeLab:' mfilename ':invalidEmptyDims'],...
                  'Input to .Empty method should be scalar.');
            end
            dims = [0, n];
         end
         
         obj = nigeLab.libs.VideosFieldType(dims);
      end
   end
   
end