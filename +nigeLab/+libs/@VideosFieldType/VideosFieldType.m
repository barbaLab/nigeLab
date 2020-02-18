classdef VideosFieldType < handle ...
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
   properties (Dependent,Transient,Access=public)
      Duration  double     % Duration of video (seconds)      
      GrossOffset (1,1) double  % Start-time with respect to neural data
      Height    double     % Height of video frame (pixels)
      Index       char     % Index of this video (for GoPro multi-videos)
      Key         char     % "Key" that corresponds to Block object
      Masked      (1,1)    % Is this video "masked" (true: enabled)?
      Name        char     % Name of video file
      NeuOffset   (1,1) double  % Generic start-time offset beyond the Video offset
      NumFrames double     % Total number of frames
      Source      char     % Camera "view" (e.g. Door, Top, etc...)
      TrialOffset (1,1) double  % Trial/camera-specific offset
      Width     double     % Width of video frame (pixels)
      VideoIndex  (1,1) double  % Index of this video within array
      fs        double     % Sample rate
   end
   
   % HIDDEN,DEPENDENT,TRANSIENT,PUBLIC
   properties (Hidden,Dependent,Transient,Access=public)
      IsIdle   logical     % Returns flag indicating whether object is Idle
      Meta       table     % Row of Block.Meta.Video corresponding to this video
      Parent               % Handle to "parent" nigeLab.Block object
      Pars      struct     % Parameters struct
      StreamNames cell     % Cell array of unique child stream names
      V                    % VideoReader object
      fname_t     char     % Full filename of "time" file
      tNeu      double     % Time vector relative to Neural data
      tVid      double     % Time vector relative to Video
   end
   
   % HIDDEN,TRANSIENT,PROTECTED
   properties (Hidden,Transient,Access=protected)
      V_                          % VideoReader object
      VideoIndex_    double       % Stored index
      store_   (1,1) struct = nigeLab.libs.VideosFieldType.initStore(); % struct to store parsed properties
   end
   
   % HIDDEN,PUBLIC/PROTECTED
   properties (Hidden,GetAccess=public,SetAccess=protected)
      Streams           nigeLab.libs.VidStreamsType % nigeLab.libs.VidStreamsType video parsed streams
      VideoOffset (1,1) double = 0   % Start-time with respect to full video
   end
   
   % HIDDEN,PUBLIC
   properties (Hidden,Access=public)
      ROI cell = {}  % Region of interest ({iRow, iCol})
   end
   
   % HIDDEN,PROTECTED
   properties (Hidden,Access=protected)
      Time           nigeLab.libs.DiskData % disk-file for actual `Time` data
      fname          char                  % Full filename of video
      mIndex         double                % Index into Block.Meta.Videos table for this object
   end
   
   % HIDDEN,TRANSIENT,RESTRICTED/IMMUTABLE
   properties (Hidden,Transient,GetAccess=?nigeLab.libs.VidStreamsType,SetAccess=immutable)
      Block                % Internal reference property (nigeLab.Block)
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % RESTRICTED:{nigeLab.Block,nigeLab.nigelObj}
   methods (Access={?nigeLab.Block,?nigeLab.nigelObj})
      % Class constructor
      function obj = VideosFieldType(blockObj,loadedObj_)
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
         
         if nargin < 1
            obj = nigeLab.libs.VideosFieldType.empty();
         elseif isnumeric(blockObj)
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
            loadedObj_ = [];
         end
         
         if numel(blockObj) > 1
            obj = nigeLab.libs.VideosFieldType.empty();
            for i = 1:numel(blockObj)
               obj = [obj, ...
                  nigeLab.libs.VideosFieldType(blockObj(i),loadedObj_)]; %#ok<AGROW>
            end
            return;               
         end
         
         obj.Block = blockObj;  % Make sure to assign the pointer to Block
         fname = ''; % Initialize this as empty, but it may be overwritten:
                     % --> This depends on the class of loadObj_
                     
         % Here, address alternative constructor uses:
         if isa(loadedObj_,'nigeLab.libs.VideosFieldType') % From Load
            obj = loadedObj_; % Then just load it directly
            for i = 1:numel(obj) % In case it is an array
               % .Block is Transient, so must be re-assigned from loadobj
               % method of nigeLab.Block when a _Block.mat file is loaded
               obj(i).Block = blockObj; 
            end
            % Similarly, streams must be re-connected
            initStreams(obj);
            return;
         elseif isstruct(loadedObj_) % Construct from loaded struct
            obj=nigeLab.utils.assignParentStruct(obj,loadedObj_,blockObj);
            initStreams(obj);
            return; 
         elseif ischar(loadedObj_)
            fname = loadedObj_;
         end
         
         if ~isfield(blockObj.Paths,'V') % Need to run init
            error(['nigeLab:' mfilename ':BadInit'],...
               '[VIDEOSFIELDTYPE]: Block.Paths is invalid (%s)\n',...
               blockObj.Name);
         end
         
         F = dir(fullfile(blockObj.Paths.V.Root,...
                          blockObj.Paths.V.Folder,...
                          blockObj.Paths.V.Match));
         if isempty(F) % If no files were found
            % Now, searches for the VideoFiles are handled in .initVideos;
            % should not be done here.
            blockObj.Pars.Video.HasVideo = false;
            blockObj.Pars.Video.HasVidStreams = false;
            saveParams(blockObj,blockObj.User,'Video');
            obj = nigeLab.libs.VideosFieldType.empty();
            return;
         end
         
         % Handle input array struct (such as returned by 'dir'). Each
         % element of a VideosFieldType array should correspond to a single
         % array element of the `dir` struct (one video file).
         if isempty(fname)
            obj = nigeLab.libs.VideosFieldType.empty();
            nameList = {F.name};
            for i = 1:numel(F)
               fname = nigeLab.utils.getUNCPath(F(i).folder,F(i).name);
               fname = strrep(fname,'\','/');
               obj = [obj,...
                  nigeLab.libs.VideosFieldType(blockObj,fname)]; %#ok<AGROW>
            end
            return;
         end
         obj.fname = fname;
         obj.mIndex = parseVidFileName(blockObj,fname);
         initStreams(obj,true); % Specify true for `forceOverwrite` option
         Idle(obj); % Make sure that VideoReader object is not taking up memory
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
      % [DEPENDENT]  Returns .Duration property
      function value = get.Duration(obj)
         %GET.DURATION  Returns .Duration property
         %
         % Returns duration of this video (seconds)
         
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.store_.Duration)
            obj.store_ = initSecondaryTempProps(obj);
         end
         value = obj.store_.Duration;
      end
      function set.Duration(obj,~)
         %SET.DURATION  Assigns .Duration property (cannot)
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Duration\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .GrossOffset property
      function value = get.GrossOffset(obj)
         %GET.GROSSOFFSET  Returns .GrossOffset property
         %
         % Returns scalar offset for this video relative to neural data 
         
         value = getEventData(obj.Block,obj.Block.ScoringField,...
            'ts','Header');
         value = value(obj.VideoIndex);
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

         setEventData(obj.Block,obj.Block.ScoringField,...
            'ts','Header',value,obj.VideoIndex);
      end
      
      % [DEPENDENT]  Returns .Height property
      function value = get.Height(obj)
         %GET.HEIGHT  Returns .Height property
         %
         % Returns height of frames in this video (pixels)
         
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.store_.Height)
            obj.store_ = initSecondaryTempProps(obj);
         end
         value = obj.store_.Height;
      end
      function set.Height(obj,~)
         %SET.HEIGHT  Assigns .Height property (cannot)
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Height\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .Index property (Index from GoPro series)
      function value = get.Index(obj)
         %GET.INDEX  Returns .Index property (Index from GoPro series)
         %
         %  value = get(obj,'Index');
         %  --> Returns character that is zero-indexed. It indexes GoPro
         %        videos taken during the same recording that were chopped
         %        into multiple files due to the limits of file size.
         
         value = '';
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.store_.Index)
            obj.store_ = initPrimaryTempProps(obj);
         end
         value = obj.store_.Index;
      end
      function set.Index(obj,~)
         % Does nothing
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Index\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .IsIdle property flag
      function value = get.IsIdle(obj)
         %GET.IsIdle  Returns .IsIdle property flag
         %
         %  value = get(obj,'IsIdle');
         %  --> Returns value that is true unless VideoReader object has
         %  been intialized
         
         value = true;
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.V_)
            return;
         elseif ~isvalid(obj.V_)
            return;
         else
            value = false; % Then obj.V_ exists and is valid
         end
      end
      function set.IsIdle(obj,~)
         % Does nothing
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: IsIdle\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .Key property
      function value = get.Key(obj)
         %GET.KEY  Returns .Key property
         %
         % Returns unique movie ID that is linked to block
         
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.store_.Key)
            obj.store_ = initPrimaryTempProps(obj);
         end
         value = obj.store_.Key;
      end
      function set.Key(obj,~)
         %SET.KEY  Assigns .Key property (cannot)
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Key\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .Masked property
      function value = get.Masked(obj)
         %GET.MASKED  References "Header" diskfile (column 3: 'Tag')
         value = getEventData(obj.Block,obj.Block.ScoringField,...
            'tag','Header');
         value = logical(value(obj.VideoIndex));
      end
      function set.Masked(obj,value)
         %SET.MASKED  References "Header" diskfile (column 3: 'Tag')
         setEventData(obj.Block,obj.Block.ScoringField,...
            'ts','Header',value,obj.VideoIndex);
      end
      
      % [DEPENDENT]  Returns .Meta property
      function value = get.Meta(obj)
         %GET.METATABLE  Returns .Meta property
         %
         % Returns the correct row of "Block.Meta.Video" for this video
         
         value = table.empty;
         if isempty(obj.Block)
            return;
         elseif ~isvalid(obj.Block)
            return;
         elseif ~isfield(obj.Block.Meta,'Video')
            return;
         elseif isempty(obj.mIndex)
            return;
         end
         
         value = obj.Block.Meta.Video(obj.mIndex,:);
      end
      function set.Meta(obj,~)
         %SET.META  Assigns .Meta property (cannot)
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Meta\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .Name property
      function value = get.Name(obj)
         %GET.NAME  Returns .Name property
         %
         % Returns the name of the video
         
         value = '';
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.store_.Name)
            obj.store_ = initPrimaryTempProps(obj);
         end
         value = obj.store_.Name;
      end
      function set.Name(obj,~)
         %SET.NAME  Assigns .Name property (cannot)
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Name\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .NeuOffset property
      function value = get.NeuOffset(obj)
         %GET.NEUOFFSET  Returns .NeuOffset property
         %
         %  value = get(obj,'NeuOffset');
         %  --> Returns the offset that is obj.GrossOffset -
         %  obj.VideoOffset
         
         value = obj.GrossOffset - obj.VideoOffset;
      end
      function set.NeuOffset(obj,value)
         %SET.NEUOFFSET  Assign corresponding video of linked Block   
         %
         %  set(obj,'NeuOffset',value);
         %  --> value should be:
         %  value = (tNeu - tEvent) - tSpecific;
         %  Where tSpecific is the "Trial-Specific" and "Camera-Specific"
         %  offset.
         
         obj.GrossOffset = value+obj.VideoOffset;
%          % Since times are relative to the VIDEO record, any time a NEURAL
%          % or TRIAL offset is changed, then change the event times
%          obj.Block.Trial = obj.Block.Trial - value;
%          obj.Block.EventTimes = obj.Block.EventTimes - value;
      end
      
      % [DEPENDENT]  Returns .NumFrames property
      function value = get.NumFrames(obj)
         %GET.NUMFRAMES  Returns .NumFrames property
         %
         % Returns # of frames in this video (integer as double)
         
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.store_.NumFrames)
            obj.store_ = initSecondaryTempProps(obj);
         end
         value = obj.store_.NumFrames;
      end
      function set.NumFrames(obj,~)
         %SET.NUMFRAMES  Assigns .NumFrames property (cannot)
         
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: NumFrames\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .Parent property (.Block)
      function value = get.Parent(obj)
         %GET.PARENT  Returns .Parent property (.Block)
         value = obj.Block;
      end
      function set.Parent(obj,value)
         %SET.PARENT  Assigns .Parent property (obj.Block)
         %
         %  set(obj,'Parent',value);
         %  --> Assigns `value` to obj.Block property
         %     --> Assign only works if value is `nigeLab.Block` or
         %           `nigeLab.nigelObj` class
         
         if ismember(class(value),{'nigeLab.Block','nigeLab.nigelObj'})
            obj.Block = value;
         end
      end
      
      % [DEPENDENT]  Returns .Pars property
      function value = get.Pars(obj)
         %GET.PARS  Returns .Pars property
         %
         % Returns nigeLab.Block.Pars.Video for corresponding Block
         
         value = struct.empty;
         if isempty(obj.Block)
            return;
         elseif isempty(obj.Block)
            return;
         end
         value = obj.Block.Pars.Video;
      end
      function set.Pars(obj,~)
         % Does nothing
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Pars\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .Source property (Camera angle or view)
      function value = get.Source(obj)
         %GET.SOURCE Returns .Source property (Cam angle or view)
         %
         %  value = get(obj,'Source');
         %  --> For example, 'Left-A', or 'Front'; typically used when
         %        multiple cameras are used on same experiment
         
         value = '';
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.store_.Source)
            obj.store_ = initPrimaryTempProps(obj);
         end
         
         value = obj.store_.Source;
      end
      function set.Source(obj,~)
         % Does nothing
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Source\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Returns .StreamNames property (from .Streams)
      function value = get.StreamNames(obj)
         %GET.STREAMNAMES  Returns .StreamNames property (from .Streams)
         %
         %  value = get(obj,'StreamNames');
         %  --> Returns cell array for all unique stream names for this
         %      video.
         
         value = {};
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.Streams)
            return;
         end
         
         value = obj.store_.Source;
      end
      
      % [DEPENDENT] Returns .TrialOffset property (from linked Block)
      function value = get.TrialOffset(obj)
         %GET.TRIALOFFSET  Returns .TrialOffset property (from Block)
         %
         %  value = get(obj,'TrialOffset');
         %  --> Returns Trial/Camera-specific offset for current trial
         
         iRow = obj.VideoIndex;
         iCol = obj.Block.TrialIndex;
         value = obj.Block.TrialVideoOffset(iRow,iCol);
      end
      function set.TrialOffset(obj,value)
         %SET.TRIALOFFSET  Assign corresponding video of linked Block   
         %
         %  set(obj,'TrialOffset',value);
         %  --> value should be:
         %  value = (tNeu - tEvent) - GrossOffset;
         %  Where "GrossOffset" is the VideosFieldType.GrossOffset property
         
         if isempty(obj.Block)
            return;
         end
         iRow = keyToIndex(obj);
         iCol = obj.Block.TrialIndex;
         obj.Block.TrialVideoOffset(iRow,iCol) = value;
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
      
      % [DEPENDENT]  Returns .VideoIndex property 
      function value = get.VideoIndex(obj)
         %GET.VIDEOINDEX  Returns .VideoIndex property (index to this obj)
         %
         %  value = get(obj,'VideoIndex');
         %  --> Returns array index to this object within parent array
         
         if ~isempty(obj.VideoIndex_)
            value = obj.VideoIndex_;
            return;
         end
         value = findVideo(obj);
         obj.VideoIndex_ = value;
      end
      function set.VideoIndex(obj,value)
         %SET.VIDEOINDEX  Assign .VideoIndex_ store
         obj.VideoIndex_ = value;
      end
      
      % [DEPENDENT]  Returns .Width property
      function value = get.Width(obj)
         %GET.Width  Returns .Width property
         %
         % Returns width of frames in this video (pixels)
         
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.store_.Width)
            obj.store_ = initSecondaryTempProps(obj);
         end
         value = obj.store_.Width;
      end
      function set.Width(obj,~)
         %SET.WIDTH  Assigns .Width property (cannot)
         
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Width\n');
            fprintf(1,'\n');
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
         sName = sprintf('Time-%s',obj.Index);
         value = sprintf(expr,obj.Source,sName,'mat');
      end
      
      % [DEPENDENT]  Returns .fs property
      function value = get.fs(obj)
         %GET.fs  Returns .fs property
         %
         % Returns number of frames per second in this video (double)
         
         if isempty(obj.store_.fs)
            obj.store_ = initSecondaryTempProps(obj);
         end
         value = obj.store_.fs;
            
      end
      function set.fs(obj,~)
         %SET.FS  Assigns .fs property (cannot)
         
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDEOSFIELDTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: fs\n');
            fprintf(1,'\n');
         end
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
         value = tmp+obj.GrossOffset+obj.TrialOffset;
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
   methods (Access = public)   
      % Return all videos from the same "Source"
      function obj = FromSame(objArray,sourceName)
         %FROMSAME  Return all videos from the same "source"
         %
         %  obj = FromSame(objArray,'Left-A');
         %  --> Returns all VideosFieldType objects from an array that have
         %      .Source of 'Left-A'
         
         obj = objArray(strcmpi({objArray.Source},sourceName));
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
      
      % "Readies" the VideosFieldType object for playing videos
      function v = Ready(obj)
         %READY  "Readies" the VideosFieldType object for playing videos
         %
         %  Ready(obj);
         %  v = Ready(obj);  Return handle to "readied" VideoReader object
         
         if isempty(obj.V_)
            nigeLab.utils.cprintf('[0.45 0.45 0.45]',obj.Block.Verbose,...
               '\t\t->\t[VIDEOS]: Readying %s...',obj.Name);
            obj.V_ = VideoReader(obj.fname);
            nigeLab.utils.cprintf('Keywords*',obj.Block.Verbose,...
               'complete\n');
         elseif ~isvalid(obj.V_)
            nigeLab.utils.cprintf('[0.45 0.45 0.45]',obj.Block.Verbose,...
               '\t\t->\t[VIDEOS]: Readying %s...',obj.Name);
            obj.V_ = VideoReader(obj.fname);
            nigeLab.utils.cprintf('Keywords*',obj.Block.Verbose,...
               'complete\n');
         end
         v = obj.V_;
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
         matchStr = nigeLab.libs.VideosFieldType.parse(bMeta,obj.Pars,ext);
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
         sto = obj.store_;
         
         % Derived from `Block` --> `Meta`/`Pars`
         if isempty(obj.Block)
            return; % Nothing goes without obj.Block
         elseif ~isfield(obj.Block.Meta,'Video')
            return; % Then .Meta doesn't work
         elseif isempty(obj.mIndex)
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
               'access','w','size',size(data),'class',class(data));
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
      function obj = empty(n)
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
         
         obj = nigeLab.libs.VideosFieldType(dims);
      end
      
      % Return "name-matching" string for finding associated videos
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
         
         toMatch = cellfun(@(x)strcmp(x(1),pars.IncludeChar),...
            pars.DynamicVars,...
            'UniformOutput',true);
         dynamicVars = cellfun(@(x)x(2:end),...
            pars.DynamicVars,...
            'UniformOutput',false);
         inMeta = ismember(dynamicVars,fieldnames(meta));
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
         
         s = cell(1,numel(dynamicVars));
         for i = 1:numel(dynamicVars)
            if toMatch(i) && inMeta(i)
               s{i} = meta.(dynamicVars{i});
            else
               s{i} = '*';
            end
         end
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