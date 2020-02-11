classdef nigelStream < matlab.mixin.SetGet & matlab.mixin.CustomDisplay
   %NIGELSTREAM  Handle class for scaling/converting streams on DiskData
   %   
   %  Example:
   %  blockObj = tankObj{1,2};
   %  stream = getStream(blockObj,'trial-running'); % Return trial-running
   %                                                     data stream
   %  --> stream is a nigelStream object, which applies the scaling
   %        associated with "trial-running" stream type
   %  --> note that this object is not "linked" to the Block structure (so
   %        it will not be saved with Block)
   
   % % % PROPERTIES % % % % % % % % % %
   % PUBLIC/PROTECTED
   properties (GetAccess=public,SetAccess=protected)
      data          double    % Actual data coming out of stream
      t             double    % Time vector for each sample in stream
   end
   
   % HIDDEN,TRANSIENT,PUBLIC
   properties (Hidden,Transient,Access=public)
      Block       % nigeLab.Block "parent" object
   end
   
   % DEPENDENT,PUBLIC
   properties (Dependent,Access=public)
      Index         double    % Index (from .ArrayIndex( .Index_))
      Key           char      % unique "Key" relating it to Block, parent struct
      SubField                % Actual "sub-field" value (indexed from SubFields_)
      name          char                  % Name describing stream
      signal        nigeLab.utils.signal  % Class with properties describing stream
      fs            double                % sample rate
   end
   
   % DEPENDENT,HIDDEN,PUBLIC/PROTECTED
   properties (Dependent,Hidden,GetAccess=public,SetAccess=protected)
      Data_         nigeLab.libs.DiskData      % DiskData 
      File_t        char      % (char) Full filename of 
      SubFields_    cell      % "sub-field" list names of fields for 'Streams' and 'Videos' of associated Block
      Time_         nigeLab.libs.DiskData      % File storing time data
      View          char      % Camera view (if VidStream)
   end
   
   % HIDDEN,PUBLIC/PROTECTED
   properties (Hidden,GetAccess=public,SetAccess=protected)
      FieldType   char   = 'Streams'    % FieldType (e.g. 'Streams' or 'Videos') of stream
      ScaleOpts   (1,1)struct                % Options for scaling stream output
   end
   
   % PROTECTED
   properties (Access=protected)
      ArrayIndex           double      % List of indices addressing streams in arrays of Streams "sub-fields"
      CamOpts      (1,1)   struct      % Struct of camera options for getting VidStream
      Index_               double      % Index of stream with respect to ArrayIndex and SubIndex
      GrossOffset  (1,1)   double = 0  % Scalar offset of stream time-values from start of acquisition (seconds)
      SubIndex             double      % Index from list of stream "sub-fields" back to original field from .Fields list
      Time_File            nigeLab.libs.DiskData
   end
   
   % PROTECTED/IMMUTABLE
   properties (GetAccess=protected,SetAccess=immutable)
      Name_        char      % (char) name of stream
      Source_      char      % (char) For VidStreams, the camera source
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % RESTRICTED:{nigeLab.Block,nigeLab.nigelObj} (constructor)
   methods (Access={?nigeLab.Block,?nigeLab.nigelObj})
      % Constructor for nigelStream object
      function stream = nigelStream(blockObj,streamName,scaleOpts)
         %NIGELSTREAM  Class for scaling/converting streams on DiskData
         %
         %  stream = nigelStream(blockObj,streamName,source,scaleOpts);
         %
         %
         %  stream = blockObj.getStream('streamName'); 
         %
         %  streamName  :  Char array e.g. 'Paw' or 'Beam' etc. that is 
         %                 the name of some Stream.
         %                 --> Set as `camOpts` struct to parse from camera
         %                 instead. See `nigeLab.utils.initCamOpts` for
         %                 details.
         %
         %  scaleOpts   :  (Optional) -- Struct with fields:
         %                --> 'do_scale'  (set false to skip scaling)
         %                --> 'range'     ('normalized' or 'fixed_scale')
         %                --> 'fixed_min' (fixed/known min. value)
         %                --> 'fixed_range' (only used if range is
         %                                   'fixed_scale'; flat value
         %                                    that range should be scaled
         %                                    to)
         
         % Allow empty constructor etc.
         if nargin < 1
            stream = nigeLab.libs.nigelStream.empty();
            return;
         elseif isnumeric(blockObj)
            dims = blockObj;
            if numel(dims) < 2 
               dims = [zeros(1,2-numel(dims)),dims];
            end
            stream = repmat(stream,dims);
            return;
         elseif ismember(class(blockObj),...
               {'nigeLab.Block','nigeLab.nigelObj'})
            stream.Block = blockObj;
         else
            error(['nigeLab:' mfilename ':BadInput'],...
               '[NIGELSTREAM]: Bad class for blockObj (%s)\n',...
               class(blockObj));
         end
         
         if nargin < 2
            error(['nigeLab:' mfilename ':TooFewInputs'],...
               '[NIGELSTREAM]: At least 2 inputs are required.');
         end
         
         if ischar(streamName)
            stream.Name_ = streamName;
            stream.CamOpts = nigeLab.utils.initCamOpts();
         else
            stream.Name_ = streamName.name;
            stream.CamOpts = streamName;
            stream.FieldType = 'Videos'; % Switch
         end
         
         if nargin < 3
            scaleOpts = nigeLab.utils.initScaleOpts();
         end
         stream.ScaleOpts = scaleOpts;
         
         % Parse indexing from .Streams FieldType of Block
         if strcmp(stream.FieldType,'Streams')
            parseStreamsIndex(stream); % Can switch to 'Videos' here
         end
         
         % If `Videos`, parse Index from .CamOpts
         if strcmp(stream.FieldType,'Videos')
            parseVideosIndex(stream);
         end
         
         if isempty(stream.Data_)
            % Return empty stream because can't find anything
            stream.FieldType = 'Empty';
            nigeLab.utils.cprintf('Errors*',blockObj.Verbose,...
               '\t\t->\t[NIGELSTREAM]: ');
            nigeLab.utils.cprintf('Text',blockObj.Verbose,...
               'No stream named %s in %s\n',...
               streamName{1},blockObj.Name);
            return;
         end
         
         % Set .Time or create it if necessary
         if strcmp(stream.FieldType,'Streams')
            if exist(stream.File_t,'file')==0
               nSamples = stream.signal.Samples;
               timeData = (0:(nSamples-1))/stream.fs;
               stream.Time_File = nigeLab.libs.DiskData(...
                  'MatFile',stream.File_t,timeData,'Overwrite',true);
            else
               stream.Time_File = nigeLab.libs.DiskData('MatFile',stream.File_t);
            end
         end
      end
      
      % Parses .SubIndex and .ArrayIndex, as well as .Index using those
      function parseStreamsIndex(stream)
         %PARSESTREAMSINDEX Parse protected .Index and .SubIndex properties
         %
         %  parseStreamsIndex(stream);
         %  --> .Index : 
         %        Index to full list of all stream "sub-field" names that
         %        this stream matches.
         %  --> .SubIndex : 
         %        Index to the original stream field names list (.Fields)
         %        that the "sub-field" index was originally from.
         %  --> .ArrayIndex : 
         %        Matched index element addressing array element of 
         %        "sub-field" from Streams struct to the corresponding 
         %        element of .SubIndex.
         
         % Get total number of fields
         nF = numel(stream.SubFields_);
         
         % Make 3 lists: 
         %  name -- list all streams names from all fields of block.Streams
         %  idx  -- Matched indexing from name into fieldnames of Streams
         %  streamIdx  --  Matched indexing from name into corresponding 
         %                 array element of that fieldtype in Streams
         f = cell(1,nF);
         idx = cell(1,nF);
         streamIdx = cell(1,nF);
         for iF = 1:nF
            f{iF} = {stream.Block.Streams.(stream.SubFields_{iF}).name};
            nFsub = numel(f{iF});
            idx{iF} = ones(1,nFsub)*iF; 
            streamIdx{iF} = 1:nFsub; 
         end
         f = horzcat(f{:});
         stream.SubIndex = horzcat(idx{:});
         stream.ArrayIndex = horzcat(streamIdx{:});
         
         % Match the name. Handle cases where zero or more than one match
         idx = ismember(f,stream.Name_);
         
         if sum(idx) > 1
            error(['nigeLab:' mfilename ':BadName'],...
               '[NIGELSTREAM]: Multiple streams with the same name.');
         elseif sum(idx) < 1
            if isempty(stream.Source_) % if `source` missing then is empty
               stream.FieldType = 'Empty';
               return;
            else % Update to `Videos` FieldType
               stream.FieldType = 'Videos'; 
            end
            
         else
            stream.Index_ = find(idx,1,'first');
         end
      end
      
      % Parses .Index (video) and .SubField (stream index) using .CamOpts
      function parseVideosIndex(stream)
         %PARSEVIDEOSINDEX  Parse .Index based on .CamOpts
         %
         %  parseVideosIndex(stream);
         
         % Parse video index first
         switch lower(stream.CamOpts.camera.csource)
            case {'index','cindex'}
               vidIdx = stream.CamOpts.camera.cindex;
               vview = stream.CamOpts.camera.cview;
               if ~isempty(vview)
                  vViewList = {stream.Block.Videos.Source};
                  tmp = find(strcmp(vViewList,vview));
                  if ~isempty(tmp)
                     vidIdx = tmp(vidIdx);
                  else
                     nigeLab.utils.cprintf('Errors*',stream.Block.Verbose,...
                        '[PARSEVIDEOSINDEX]: No matches for view source ("%s")\n',...
                        vview);
                  end
               end
            case {'key','ckey'}
               vkey = stream.CamOpts.camera.ckey;
               vKeyList = {stream.Block.Videos.Key};
               vidIdx = find(strcmp(vKeyList,vkey),1,'first');
            case {'name','cname'}
               vname = stream.CamOpts.camera.cname;
               vNameList = {stream.Block.Videos.Name};
               vidIdx = find(strcmp(vNameList,vname),1,'first');
            case {'view','cview'}
               vview = stream.CamOpts.camera.cview;
               vViewList = {stream.Block.Videos.Source};
               vidIdx = find(strcmp(vViewList,vview),1,'first');
            otherwise
               error(['nigeLab:' mfilename ':BadCase'],...
                  ['[PARSEVIDEOSINDEX]: stream.CamOpts.camera.csource '...
                  'Should be ''cindex'', ''ckey'', or ''cname'' '...
                  '(not ''%s'')\n'],stream.CamOpts.camera.csource);
         end
         stream.Index = vidIdx;
         
         % Parse stream index next
         switch lower(stream.CamOpts.stream.ssource)
            case {'index','sindex'}
               streamIdx = stream.CamOpts.stream.sindex;
            case {'key','skey'}
               skey = stream.CamOpts.stream.skey;
               sKeyList = {stream.Block.Videos(vidIdx).Streams.Key};
               streamIdx = find(strcmp(sKeyList,skey),1,'first');
            case {'name','sname'}
               sname = stream.CamOpts.stream.sname;
               sNameList = {stream.Block.Videos(vidIdx).Streams.Name};
               streamIdx = find(strcmp(sNameList,sname),1,'first');
            otherwise
               error(['nigeLab:' mfilename ':BadCase'],...
                  ['[PARSEVIDEOSINDEX]: stream.CamOpts.stream.ssource '...
                  'Should be ''sindex'', ''skey'', or ''sname'' '...
                  '(not ''%s'')\n'],stream.CamOpts.stream.ssource);
         end
         stream.SubField = streamIdx;
      end
   end
   
   % SEALED,PUBLIC (main methods)
   methods (Sealed,Access=public)      
      % Set stream.GrossOffset value (some validation)
      function setOffset(stream,value)
         %SETOFFSET  Set offset associated with stream time-series
         %
         %  setOffset(stream,value);
         %
         %  value : Sets stream.GrossOffset (protected) to some value
         
         if isempty(value)
            return;
         elseif ~isnumeric(value)
            return;
         elseif isnan(value)
            return;
         end
         stream.GrossOffset = value;
         
      end
      
      % Set stream.ScaleOpts struct using 'Name',value,... syntax
      function setScaling(stream,varargin)
         %SETSCALING  Use {'name', value} syntax to set scaling options
         %
         %  set using 'Name', value,... format
         %
         %  >> stream = getStream(blockObj,'trial-running');
         %  >> setScaling(stream,'do_scale',false); Turn off scaling
         %
         %  or set using 'struct' format
         %  
         %  >> opts = nigeLab.utils.initScaleOpts();
         %  >> setScaling(stream,opts);
         %
         %  Options:
         %  * 'do_scale' [default: true] Apply scaling?
         %  * 'range' [default: 'normalized'] Scaling range, can be:
         %     -> 'normalized'
         %     -> 'fixed_scale'
         %     -> 'zscore'
         %  * 'fixed_min' [default: 0] Minimum on range scaling
         %  * 'fixed_range' [default: 1] Range (from minimum)
         
         if numel(varargin)==1
            if isstruct(varargin{1})
               stream.ScaleOpts = varargin{1};
               return;
            end
         end
         opts = stream.ScaleOpts;
         stream.ScaleOpts = nigeLab.utils.getopt(opts,varargin{:});
      end
   end
   
   % NO ATTRIBUTES (get/set overloads)
   methods
      % [DEPENDENT]  Return .name property
      function value = get.name(stream)
         %GET.NAME  Returns .name property 
         switch stream.FieldType
            case 'Streams' % Found a match in Streams (default)
               streamName = stream.SubField;
               idx = stream.Index;
               if isempty(streamName) || isempty(idx)
                  return;
               end
               % Return Stream diskfile
               value = stream.Block.Streams.(streamName)(idx).name;
               
            case 'Videos' % No Streams matches, but VidStreams match
               vidIdx = stream.Index;
               streamIdx = stream.SubField;
               if isempty(vidIndex) || isempty(streamIdx)
                  return;
               end
               % Return VidStream diskfile
               value = stream.Block.Videos(vidIdx).Streams(streamIdx).Name;
               
            case 'Empty' % --> No matches for streamName at all
               return;
               % do nothing, return empty (no warning)
            otherwise
               dbstack();
               nigeLab.utils.cprintf('Errors*',...
                  '\t\t->\t[NIGELSTREAM.GET]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Bad FieldType: %s\n',stream.FieldType);
         end
      end
      
      % [DEPENDENT]  Assigns .name property (cannot)
      function set.name(stream,~)
         %SET.NAME  Cannot set
         if ~stream.Block.Verbose
            return;
         end
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[NIGELSTREAM.SET]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set DEPENDENT property: name\n');
         fprintf(1,'\n');
      end
      
      % [DEPENDENT]  Return .fs property
      function value = get.fs(stream)
         %GET.FS  Returns .fs property 
         value = [];
         switch stream.FieldType
            case 'Streams' % Found a match in Streams (default)
               streamName = stream.SubField;
               idx = stream.Index;
               if isempty(streamName) || isempty(idx)
                  return;
               end
               % Return Stream diskfile
               value = stream.Block.Streams.(streamName)(idx).fs;
               
            case 'Videos' % No Streams matches, but VidStreams match
               vidIdx = stream.Index;
               streamIdx = stream.SubField;
               if isempty(vidIndex) || isempty(streamIdx)
                  return;
               end
               % Return VidStream diskfile
               value = stream.Block.Videos(vidIdx).Streams(streamIdx).fs;
               
            case 'Empty' % --> No matches for streamName at all
               return;
               % do nothing, return empty (no warning)
            otherwise
               dbstack();
               nigeLab.utils.cprintf('Errors*',...
                  '\t\t->\t[NIGELSTREAM.GET]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Bad FieldType: %s\n',stream.FieldType);
         end
      end
      
      % [DEPENDENT]  Assigns .fs property (cannot)
      function set.fs(stream,~)
         %SET.FS  Cannot set
         if ~stream.Block.Verbose
            return;
         end
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[NIGELSTREAM.SET]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set DEPENDENT property: fs\n');
         fprintf(1,'\n');
      end
      
      % [DEPENDENT]  Return .signal property
      function value = get.signal(stream)
         %GET.SIGNAL  Returns .signal property 
         
         switch stream.FieldType
            case 'Streams' % Found a match in Streams (default)
               streamName = stream.SubField;
               idx = stream.Index;
               if isempty(streamName) || isempty(idx)
                  return;
               end
               % Return Stream diskfile
               value = stream.Block.Streams.(streamName)(idx).signal;
               
            case 'Videos' % No Streams matches, but VidStreams match
               vidIdx = stream.Index;
               streamIdx = stream.SubField;
               if isempty(vidIndex) || isempty(streamIdx)
                  return;
               end
               % Return VidStream diskfile
               value = stream.Block.Videos(vidIdx).Streams(streamIdx).info;
               
            case 'Empty' % --> No matches for streamName at all
               return;
               % do nothing, return empty (no warning)
            otherwise
               dbstack();
               nigeLab.utils.cprintf('Errors*',...
                  '\t\t->\t[NIGELSTREAM.GET]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Bad FieldType: %s\n',stream.FieldType);
         end
      end
      
      % [DEPENDENT]  Assigns .signal property (cannot)
      function set.signal(stream,~)
         %SET.SIGNAL  Cannot set
         if ~stream.Block.Verbose
            return;
         end
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[NIGELSTREAM.SET]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set DEPENDENT property: signal\n');
         fprintf(1,'\n');
      end
      
      % [DEPENDENT]  Return .Data_ property
      function value = get.Data_(stream)
         %GET.DATA_  Return .Data_ property 
         %
         %  value = get(stream,'data');
         %  --> Returns value as a `double` with scaling from .ScaleOpts
         
         value = nigeLab.libs.DiskData.empty();
         switch stream.FieldType
            case 'Streams' % Found a match in Streams (default)
               streamName = stream.SubField;
               idx = stream.Index;
               if isempty(streamName) || isempty(idx)
                  return;
               end
               % Return Stream diskfile
               value = stream.Block.Streams.(streamName)(idx).data;
               
            case 'Videos' % No Streams matches, but VidStreams match
               vidIdx = stream.Index;
               streamIdx = stream.SubField;
               if isempty(vidIndex) || isempty(streamIdx)
                  return;
               end
               % Return VidStream diskfile
               value = stream.Block.Videos(vidIdx).Streams(streamIdx).disk;
               
            case 'Empty' % --> No matches for streamName at all
               return;
               % do nothing, return empty (no warning)
            otherwise
               dbstack();
               nigeLab.utils.cprintf('Errors*',...
                  '\t\t->\t[NIGELSTREAM.GET]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Bad FieldType: %s\n',stream.FieldType);
         end
      end
      
      % [DEPENDENT]  Assigns .Data_ property (cannot)
      function set.Data_(stream,~)
         %SET.DATA_  Cannot set
         if ~stream.Block.Verbose
            return;
         end
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[NIGELSTREAM.SET]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set DEPENDENT property: Data_\n');
         fprintf(1,'\n');
      end  
      
      % Return .Time_ property
      function value = get.Time_(stream)
         %GET.TIME_  Return .Time_ property
         %
         %  value = get(stream,'t');
         
         value = nigeLab.libs.DiskData.empty();
         switch stream.FieldType
            case 'Streams' % Found a match in Streams (default)
               value = stream.Time_File;
               return;
            case 'Videos' % No Streams matches, but VidStreams match
               vidIdx = stream.Index;
               if isempty(vidIndex)
                  return;
               end
               value = stream.Block.Videos(vidIdx).tNeu;
               
            case 'Empty' % --> No matches for streamName at all
               return;
               
            otherwise
               dbstack();
               nigeLab.utils.cprintf('Errors*',...
                  '\t\t->\t[NIGELSTREAM.GET]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Bad FieldType: %s\n',stream.FieldType);
         end
      end
      
      % [DEPENDENT]  Assigns .Time_ property (cannot)
      function set.Time_(stream,~)
         %SET.Time_  Cannot set
         if ~stream.Block.Verbose
            return;
         end
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[NIGELSTREAM.SET]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set DEPENDENT property: Time_\n');
         fprintf(1,'\n');
      end  
      
      % [DEPENDENT]  Return .File_t (char of "Time" DiskData file)
      function value = get.File_t(stream)
         %GET.FILE_T  Return .File_t (char of "Time" DIskData file)
         %
         %  value = get(stream,'File_t');
         
         value = '';
         if isempty(stream.Block)
            return;
         elseif ~isfield(stream.Block.Paths,'Time')
            nigeLab.utils.cprintf('Errors*',stream.Block.Verbose,...
               '\t\t->\t[NIGELSTREAM.GET]: '); ...
            nigeLab.utils.cprintf('Errors',stream.Block.Verbose,...
               'Bad `Paths` property in Block (%s)\n',stream.Block.Name);
            nigeLab.utils.cprintf('[0.55 0.55 0.55]',stream.Block.Verbose,...
               '\t\t\t->\t(Missing Paths.Time)\n');
            return;
         end
         
         name_ending = horzcat(stream.Name_,'.mat');
         value = sprintf(stream.Block.Paths.Time.file,name_ending);
         
      end
      
      % [DEPENDENT]  Assigns .File_t property (cannot)
      function set.File_t(stream,~)
         %SET.FILE_T  Cannot set
         if ~stream.Block.Verbose
            return;
         end
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[NIGELSTREAM.SET]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set DEPENDENT property: File_t\n');
         fprintf(1,'\n');
      end  
      
      % [DEPENDENT]  Return .Index property (from .ArrayIndex)
      function value = get.Index(stream)
         %GET.INDEX  Return .Index property (from .ArrayIndex)
         %
         %  value = get(stream,'Index');
         %  --> Returns .Index, which is .ArrayIndex(.Index_)
         %  --> Default (unset) value is []
         
         value = [];
         switch stream.FieldType
            case 'Streams' % Found a match in Streams (default)
               if isempty(stream.Index_)
                  return;
               end
               value = stream.ArrayIndex(stream.Index_);
            case 'Videos' % No Streams matches, but VidStreams match
               value = stream.CamOpts.camera.cindex;
            case 'Empty' % --> No matches for streamName at all
               return;
               
            otherwise
               dbstack();
               nigeLab.utils.cprintf('Errors*',...
                  '\t\t->\t[NIGELSTREAM.GET]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Bad FieldType: %s\n',stream.FieldType);
         end
      end
      
      % [DEPENDENT]  Assigns .Index property (only for `Videos` fieldtype)
      function set.Index(stream,value)
         %SET.INDEX  Assigns .Index property (only for `Videos` fieldtype)

         switch stream.FieldType
            case 'Streams' % Do nothing
               if stream.Block.Verbose
                  nigeLab.sounds.play('pop',2.7);
                  dbstack();
                  nigeLab.utils.cprintf('Errors*','[NIGELSTREAM.SET]: ');
                  nigeLab.utils.cprintf('Errors',...
                     'Streams Index is only parsed with protected method.\n');
                  fprintf(1,'\n');
               end
               return;
            case 'Videos' % Update .Index_
               stream.CamOpts.camera.cindex = value;
            case 'Empty' % Do nothing
               return; 
            otherwise % Do nothing
               dbstack();
               nigeLab.utils.cprintf('Errors*',...
                  '\t\t->\t[NIGELSTREAM.SET]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Bad FieldType: %s\n',stream.FieldType);
         end
      end  
      
      % [DEPENDENT]  Return .SubField property (indexed from .SubFields_)
      function value = get.SubField(stream)
         %GET.SUBFIELD  Return .SubField property (from .SubFields_)

         switch stream.FieldType
            case 'Streams' % Found a match in Streams (default)
               if isempty(stream.Index)
                  return;
               end
               value = stream.SubFields_{stream.SubIndex(stream.Index)};
            case 'Videos' % No Streams matches, but VidStreams match
               value = stream.CamOpts.stream.sindex;
               
            case 'Empty' % --> No matches for streamName at all
               value = '';
               return;
               
            otherwise
               value = '';
               dbstack();
               nigeLab.utils.cprintf('Errors*',...
                  '\t\t->\t[NIGELSTREAM.GET]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Bad FieldType: %s\n',stream.FieldType);
         end
      end
      
      % [DEPENDENT]  Assigns .SubField property ('Videos' fieldtype only)
      function set.SubField(stream,value)
         %SET.SUBFIELDS_  Assign .SubField property ('Videos' only)
         switch stream.FieldType
            case 'Streams' % Do nothing
               if stream.Block.Verbose
                  nigeLab.sounds.play('pop',2.7);
                  dbstack();
                  nigeLab.utils.cprintf('Errors*','[NIGELSTREAM.SET]: ');
                  nigeLab.utils.cprintf('Errors',...
                     'Streams SubField is only parsed with protected method.\n');
                  fprintf(1,'\n');
               end
               return;
            case 'Videos' % Update .Index_
               stream.CamOpts.stream.sindex = value;
            case 'Empty' % Do nothing
               return; 
            otherwise % Do nothing
               dbstack();
               nigeLab.utils.cprintf('Errors*',...
                  '\t\t->\t[NIGELSTREAM.SET]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Bad FieldType: %s\n',stream.FieldType);
         end
      end  
      
      % [DEPENDENT]  Return .SubFields_ property (names from 'Block' streams)
      function value = get.SubFields_(stream)
         %GET.SUBFIELDS_  Return .SubFields_ list of field names
         %
         %  value = get(stream,'SubFields_');
         
         value = {};
         if isempty(stream.Block)
            return;
         end
         switch stream.FieldType
            case 'Streams' % Found a match in Streams (default)
               value = fieldnames(stream.Block.Streams);
            case 'Videos' % No Streams matches, but VidStreams match
               
            case 'Empty' % --> No matches for streamName at all
               return;
            otherwise
               dbstack();
               nigeLab.utils.cprintf('Errors*',...
                  '\t\t->\t[NIGELSTREAM.GET]: ');
               nigeLab.utils.cprintf('Errors',...
                  'Bad FieldType: %s\n',stream.FieldType);
         end
      end
      
      % [DEPENDENT]  Assigns .SubFields_ property (cannot)
      function set.SubFields_(stream,~)
         %SET.SUBFIELDS_  Cannot set
         if ~stream.Block.Verbose
            return;
         end
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','[NIGELSTREAM.SET]: ');
         nigeLab.utils.cprintf('Errors',...
            'Failed attempt to set DEPENDENT property: SubFields_\n');
         fprintf(1,'\n');
      end
      
      % [DEPENDENT]  Return .View property (only for VidStreams)
      function value = get.View(stream)
         %GET.VIEW  Return .View property (camera angle for VidStream only)
         value = '';
         if strcmp(stream.FieldType,'Videos')
            value = stream.Block.Videos(stream.Index).Source;
         end
      end
      
      % Cannot save this object
      function save(stream)
         %SAVE  Cannot save this object
         
         if ~stream.Block.Verbose
            return;
         end
         nigeLab.sounds.play('pop',2.7);
         dbstack();
         nigeLab.utils.cprintf('Errors*','\t\t->\t[NIGELSTREAM/SAVE]: ');
         nigeLab.utils.cprintf('Errors',...
            'Cannot save nigeLab.libs.nigelStream object.\n');
      end
   end
   
   % PROTECTED
   methods (Access=protected)
      % Apply data scaling to stream.data subset
      function y = applyDataScaling(stream,x)
         %APPLYDATASCALING  Apply data scaling to some input data stream
         %
         %  y = applyDataScaling(stream,x);
         %
         %  x : Referenced subset of data associated with this object
         %  
         %  y : Same as x, but always `double` and with .ScaleOpts applied
                  
         y = nigeLab.utils.applyScaleOpts(double(x),stream.ScaleOpts);
      end
      
      % Apply time offset to stream.t subset
      function t_off = applyTimeOffset(stream,t_in)
         %APPLYTIMEOFFSET  Apply offset to some time stream
         %
         %  t_off = applyTimeOffset(stream,t_in);
         
         if strcmp(stream.FieldType,'Streams')
            t_off = t_in + stream.GrossOffset;
         else % tNeu from `Videos` already has offset
            t_off = t_in;
         end
      end
      
      % Overloaded method from CustomDisplay superclass
      function groups = getPropertyGroups(stream)
         if isempty(stream)
            groups = matlab.mixin.util.PropertyGroup.empty();
            return;
         elseif ~isvalid(stream)
            groups = matlab.mixin.util.PropertyGroup.empty();
            return;
         end
         titleStr = sprintf('<strong>%s</strong>',stream.name);
         switch stream.FieldType
            case 'Streams'
               outStruct = struct(...
                  'FieldType','Streams',...
                  'Field',stream.SubField,...
                  'StreamIndex',stream.Index,...
                  'data',stream.Data_,...
                  't',stream.Time_,...
                  'fs',stream.fs);
               groups = matlab.mixin.util.PropertyGroup(...
                  outStruct,titleStr);
            case 'Videos'
               outStruct = struct(...
                  'FieldType','Videos',...
                  'Field','VidStreams',...
                  'View',stream.View,...
                  'VideoIndex',stream.Index,...
                  'StreamIndex',stream.SubField,...
                  'data',stream.Data_,...
                  't',stream.Time_,...
                  'fs',stream.fs);
               groups = matlab.mixin.util.PropertyGroup(...
                  outStruct,titleStr);
            otherwise
               groups = matlab.mixin.util.PropertyGroup.empty();
         end
         
      end
   end
   
   % STATIC,PUBLIC (.empty)
   methods
      % Create "Empty" object or object array
      function stream = empty(n)
         %EMPTY  Return empty nigeLab.libs.behaviorInfo object or array
         %
         %  stream = nigeLab.libs.nigelStream.empty();
         %  --> Return scalar (0 x 0) object
         %
         %  stream = nigeLab.libs.nigelStream.empty(n);
         %  --> Specify number of empty objects
         
         if nargin < 1
            dims = [0, 0];
         else
            if ~isscalar(n)
               error(['nigeLab:' mfilename ':invalidEmptyDims'],...
                  'Input to nigeLab.libs.nigelStream.empty should be scalar.');
            end
            dims = [0, n];
         end
         
         stream = nigeLab.libs.nigelStream(dims);
      end
      
      
   end
   % % % % % % % % % % END METHODS% % %
end

