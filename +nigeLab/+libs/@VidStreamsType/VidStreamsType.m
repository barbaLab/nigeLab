classdef VidStreamsType < handle ...
                          & matlab.mixin.Copyable ...
                          & matlab.mixin.CustomDisplay ...
                          & matlab.mixin.SetGet
   % VIDSTREAMSTYPE  Handle class for managing blockObj.Streams.VidStreams
   %
   % VIDSTREAMSTYPE Methods:
   % VidStreamsType - Class constructor
   %
   % GetStream - Returns the SubStream corresponding to 'streamName'
   %     Note that 'substreams' are slightly different than 'vidstream' and
   %     can be thought of as a more general 'stream' type (e.g. the core
   %     data content of both 'VidStreams' and 'Streams' end up being the
   %     same in 'SubStreams').
   % 
   % VIDSTREAMSTYPE Properties:
   % disk - nigeLab.libs.DiskData - Disk-file containing signal data
   %  --> Not initialized until a `doMethod` is run to extract it
   %
   % info - nigeLab.utils.signal - information about .disk
   %  Small value class that contains metadata about this particular
   %  VidStreamsType object (for example, is it a 'Marker' or 'Sync'
   %  (.Group); for a 'Marker' is it 'x' position 'y' position or 'p'
   %  likelihood of the marker being in this frame).
   %
   %  Other properties are parsed from the `VideosFieldType` "parent"

   % % % PROPERTIES % % % % % % % % % %
   % HIDDEN,CONSTANT,PUBLIC
   properties (Hidden,Constant,Access=public)
      Delim char = '::'  % Delimiter metacharacter for .Name property
   end
   
   % HIDDEN,PUBLIC/RESTRICTED:nigeLab.libs.VideosFieldType
   properties (Hidden,GetAccess=public,SetAccess=?nigeLab.libs.VideosFieldType)
      disk     nigeLab.libs.DiskData   % disk-file with signal data
      info     nigeLab.utils.signal    % signal info corresponding to .disk
   end
   
   % DEPENDENT,PUBLIC
   properties (Dependent,Access=public)
      Key      char           % alpha-numeric unique char array identifier
      Name     char           % unique name (from .info properties)
      Type     char           % corresponds to info.Group
      fs       double         % sample rate of this stream
   end
   
   % DEPENDENT,TRANSIENT,PUBLIC
   properties (Dependent,Transient,Access=public)
      Parent                  % Handle to nigeLab.libs.VideosFieldType object
   end
   
   % DEPENDENT,TRANSIENT,PUBLIC
   properties (Hidden,Dependent,Transient,Access=public)
      fname    char           % Full filename of data stream
      pIndex   char           % "Index" from parent video
      pSource  char           % "Source" from parent video
      tNeu     double         % time vector (with respect to start of neural recording) corresponding to stream
      tVid     double         % time vector (of video frames) corresponding to stream
      vidname  char           % char array video name
   end
   
   % HIDDEN,PUBLIC
   properties (Hidden,Access=public)
      index    (1,1) double = nan   % Index of this Stream within parent
   end
   
   % HIDDEN,TRANSIENT,DEPENDENT,PUBLIC
   properties (Hidden,Transient,Dependent,Access=public)
      Block                   % nigeLab.Block "parent" object
   end
   
   % HIDDEN,TRANSIENT,PROTECTED
   properties (Transient,Access=protected)
      videosFieldObj    % nigeLab.libs.VideosFieldType "parent" object
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % RESTRICTED:nigeLab.libs.VideosFieldType (constructor)
   methods (Access=?nigeLab.libs.VideosFieldType)
      % Class constructor
      function obj = VidStreamsType(videosFieldObj,vidSig,index)
         % VIDSTREAMSTYPE Constructor for object to manage VidStreams
         %
         %  obj = ...
         %   nigeLab.libs.VidStreamsType(videosFieldObj,vidStreamSignals);
         %
         %  inputs:
         %  videosFieldObj -- nigeLab.libs.VideosFieldType class object
         %                       + if provided as an array, then
         %                         obj is returned as an array where each
         %                         array element has a 1:1 correspondence
         %                         with an element of videosFieldObj.
         %
         %  vidSig -- nigeLab.utils.signal class object (scalar or array)
         %                 --> If given as array, obj is returned as an
         %                       array of matching size. Each element of
         %                       the array is assigned to the .info
         %                       property of a given VidStreamsType obj
         %
         %  index -- Index into parent array (1, by default for scalar)
         
         % Empty object initialization
         if isnumeric(videosFieldObj) 
            dims = videosFieldObj;
            if numel(dims) < 2
               dims = [0, dims];
            end
            obj = repmat(obj,dims);
            return;
         end
         
         % Check if this was from a "re-load" case
         if isa(vidSig,'nigeLab.libs.VidStreamsType') % Load directly
            obj = vidSig; % Then vidSig is the constructed object
            for i = 1:numel(obj) % For each array element, set "parent"
               obj(i).videosFieldObj = videosFieldObj;
            end
            return; 
         elseif isstruct(vidSig) % If it was loaded as a struct
            obj=nigeLab.utils.assignParentStruct(obj,vidSig,videosFieldObj);
            return;
         end
         
         if nargin < 3
            index = 1;
         end
         
         % Requires scalar videosFieldObj (should never be a problem since
         % this is only called from protected method `initStreams` of
         % `nigeLab.libs.VideosFieldType`, after iterating on any possible
         % videosFieldObj array)
         if ~isscalar(videosFieldObj)
            error(['nigeLab:' mfilename ':BadInputSize'],...
               '[VIDSTREAMSTYPE]: A scalar videosFieldObj is required.');
         end
         
         if ~checkCompatibility(videosFieldObj.Block,'VidStreams')
            error(['nigeLab:' mfilename ':BadInputSize'],...
               '[VIDSTREAMSTYPE]: Block (%s) not configured for VidStreams',...
               videosFieldObj.Block.Name);
         end
         
         % Handle input arrays
         if numel(vidSig) > 1
            obj = nigeLab.libs.VidStreamsType.empty();
            for i = 1:numel(vidSig)
               % All vidStreamSignals associated with each video
               obj = [obj,...
                  nigeLab.libs.VidStreamsType(...
                  videosFieldObj,vidSig(i),i)]; %#ok<AGROW>
            end
            return;
         end

         % Set properties from input arguments
         obj.videosFieldObj = videosFieldObj; % This sets the Block as well
         obj.info = vidSig; % This sets the filename (in combo with Block)
         obj.index = index; % This is referenced in .Key property
         
         % Need to see if `signals` have files
         linkSignals(obj);
      end
   end
   
   % NO ATTRIBUTES (overloaded methods)
   methods
      % % % GET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT]  Returns .Key property
      function value = get.Block(obj)
         
         if isempty(obj)
            value = nigeLab.Block.empty();
            return;
         elseif ~isvalid(obj)
            value = nigeLab.Block.empty();
            return;
         elseif isempty(obj.videosFieldObj)
            value = nigeLab.Block.empty();
            return;
         elseif ~isvalid(obj.videosFieldObj)
            value = nigeLab.Block.empty();
            return;
         else
            value = obj.videosFieldObj.Block;
         end
         
      end
      
      % [DEPENDENT]  Returns .Key property
      function value = get.Key(obj)
         value = '';
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.videosFieldObj)
            return;
         elseif ~isvalid(obj.videosFieldObj)
            return;
         elseif isnan(obj.index)
            return;
         end
         tmp = obj.videosFieldObj.Key;
         value = sprintf('%s-%03g',tmp,obj.index);
      end
      
      % [DEPENDENT]  Returns .Name property
      function value = get.Name(obj)
         %GET.NAME  Returns .Name property (cell array of signal source name)
         
         value = '';
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.info)
            return;
         elseif isempty(obj.videosFieldObj) % for pSource, pIndex
            return;
         elseif ~isvalid(obj.videosFieldObj)
            return;
         end
         expr = sprintf('%%s%s%%s%s%%s',obj.Delim,obj.Delim);
         value = sprintf(expr,...
            obj.pSource,...
            strrep(obj.info.Name,'_','-'),...
            obj.pIndex);
      end
      
      % [DEPENDENT]  Returns .Parent property (.videosFieldObj)
      function value = get.Parent(obj)
         %GET.PARENT  Returns .Parent property (.videosFieldObj)
         value = obj.videosFieldObj;
      end
      
      % [DEPENDENT]  Returns .Type property
      function value = get.Type(obj)
         %GET.TYPE  Returns .Type property (obj.info.Group)
         %
         %  value = get(obj,'Type');
         %  --> Returns char array that is either 
         %        * 'Marker'  (eg Markerless Tracking from DLC)
         %        * 'Sync'    (eg LED stream etc)
         
         value = '';
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.info)
            return;
         end
         value = obj.info.Group;
      end
      
      % [DEPENDENT]  Returns .fname property (full filename)
      function value = get.fname(obj)
         %GET.FNAME  Returns .fname property (full filename)
         %
         %  value = get(obj,'fname');
         %  --> Depends on properties: 
         %        * .Block (.videosFieldObj, from videosFieldObj input arg)
         %        * .info (from vidSig input arg)
         
         value = '';
         if isempty(obj.Block)
            return;
         elseif isempty(obj.info)
            return;
         end
         expr = strrep(obj.Block.Paths.VidStreams.file,'\','/');
         sName = sprintf('%s-%s',strrep(obj.info.Name,'_','-'),obj.pIndex);
         value = sprintf(expr,obj.pSource,sName,'mat');
      end
      
      % [DEPENDENT]  Returns .fs property
      function value = get.fs(obj)
         value = nan;
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         end
         value = obj.videosFieldObj.fs;
      end
      
      % [DEPENDENT]  Returns .pIndex property (parent "Index")
      function value = get.pIndex(obj)
         %GET.PINDEX  Returns .pIndex property (parent "Index")
         %
         %  value = get(obj,'pIndex');
         %  --> Returns value that is (zero-)indexing (char; parsed from
         %        filename) indicating the order of this stream relative to
         %        to other streams from the same series of videos related
         %        to a single compound video (e.g. video-A_0; video-A_1...)
         
         value = '';
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.videosFieldObj)
            return;
         elseif ~isvalid(obj.videosFieldObj)
            return;
         end
         value = obj.videosFieldObj.Index;
      end
      
      % [DEPENDENT]  Returns .pSource property (parent "Source" camera)
      function value = get.pSource(obj)
         %GET.PSOURCE  Returns .pSource property (parent "Source" camera)
         %
         %  value = get(obj,'pSource');
         %  --> Returns char array indicating the view angle of parent
         %        "Source" camera; each camera should have a unique "view"
         %        label. (e.g. 'Left-A', 'Left-B', 'Right-A',...)
         
         value = '';
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.videosFieldObj)
            return;
         elseif ~isvalid(obj.videosFieldObj)
            return;
         end
         value = obj.videosFieldObj.Source;
      end
      
      % [DEPENDENT]  Returns .tNeu property
      function value = get.tNeu(obj)
         value = [];
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.videosFieldObj)
            return;
         elseif ~isvalid(obj.videosFieldObj)
            return;
         end
         value = get(obj.videosFieldObj,'tNeu');
      end
      
      % [DEPENDENT]  Returns .tVid property
      function value = get.tVid(obj)
         value = [];
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.videosFieldObj)
            return;
         elseif ~isvalid(obj.videosFieldObj)
            return;
         end
         value = get(obj.videosFieldObj,'tVid');
      end
      
      % [DEPENDENT]  Returns .vidname property
      function value = get.vidname(obj)
         %GET.VIDNAME  Returns .vidname property (parent Video name)
         
         value = '';
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         elseif isempty(obj.videosFieldObj)
            return;
         elseif ~isvalid(obj.videosFieldObj)
            return;
         end
         value = obj.videosFieldObj.Name;
      end
      % % % % % % % % % % END GET.PROPERTY METHODS % % %
      
      % % % SET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT] Assigns .Block property (cannot)
      function set.Block(obj,~)
         %SET.BLOCK  Does nothing
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDSTREAMSTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Block\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT] Assigns .Key property (cannot)
      function set.Key(obj,~)
         %SET.KEY  Does nothing
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDSTREAMSTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Key\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .Name property (cannot)
      function set.Name(obj,~)
         %SET.NAME  Does not do anything
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDSTREAMSTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Name\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .Parent property
      function set.Parent(obj,value)
         %SET.PARENT  Assigns .Parent property (obj.videosFieldObj)
         %
         %  set(obj,'Parent',value);
         %  --> Assigns `value` to obj.videosFieldObj property 
         %     --> Assign only works if value is
         %           `nigeLab.libs.VideosFieldType` class
         
         if isa(value,'nigeLab.libs.VideosFieldType')
            obj.videosFieldObj = value;
         end
      end
      
      % [DEPENDENT] Assigns .Type property (cannot)
      function set.Type(obj,~)
         %SET.TYPE  Does nothing
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDSTREAMSTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: Type\n');
            fprintf(1,'\n');
         end
      end

      % [DEPENDENT]  Assigns .fname property (cannot)
      function set.fname(obj,~)
         %SET.FNAME  Does not do anything
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDSTREAMSTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: fname\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .fs property (cannot)
      function set.fs(obj,~)
         %SET.FS  Does not do anything
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDSTREAMSTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: fs\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .pIndex property (cannot)
      function set.pIndex(obj,~)
         %SET.PINDEX   Does nothing
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDSTREAMSTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: pIndex\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .pSource property (cannot)
      function set.pSource(obj,~)
         %SET.PSOURCE  Does nothing
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDSTREAMSTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: pSource\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .tNeu property
      function set.tNeu(obj,~)
         %SET.T  Assigns .t property
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDSTREAMSTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: tNeu\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .tVid property
      function set.tVid(obj,~)
         %SET.T  Assigns .t property
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDSTREAMSTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: tVid\n');
            fprintf(1,'\n');
         end
      end
      
      % [DEPENDENT]  Assigns .vidname property (cannot)
      function set.vidname(obj,~)
         %SET.VIDEONAME  Does not do anything
         if obj.Block.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            nigeLab.utils.cprintf('Errors*','[VIDSTREAMSTYPE]: ');
            nigeLab.utils.cprintf('Errors',...
               'Failed attempt to set DEPENDENT property: vidname\n');
            fprintf(1,'\n');
         end
      end
      % % % % % % % % % % END SET.PROPERTY METHODS % % %
   end
   
   % PUBLIC
   methods (Access=public)
      % Link `signals` matfiles (.disk)
      function flag = linkSignals(obj,index)
         %LINKSIGNALS  Initialize `signals` matflies (.disk property)
         %
         %  flag = linkSignals(obj);
         %  flag = linkSignals(obj,index); Specify flag index
         %  --> Returns true if linked successfully
                 
         if nargin < 2
            index = 1;
         end
         
         if numel(obj) > 1
            reportProgress(obj.Block,'Linking-VidStreams',0,'toWin');
            flag = false(1,numel(obj));
            for i = 1:numel(obj)
               flag(i) = linkSignals(obj(i),i);
               pct = round(sum(flag)/numel(obj) * 100);
               reportProgress(obj.Block,'Linking-VidStreams',0,'toWin');
            end
            % Ensures that all are updated at the end
            updateStatus(obj.Block,'VidStreams',flag,1:numel(flag));
            reportProgress(obj.Block,'VidStream-Link-Complete',100,'toWin');
            reportProgress(obj.Block,'VidStream-Link-Complete',100,'toEvent');
            return;
         end
         
         flag = ~(exist(obj.fname,'file')==0);
         if ~flag
            % Could do extraction or initialization check here
         else
            if isempty(obj.disk)
               obj.disk = nigeLab.libs.DiskData('Hybrid',obj.fname);
            end
         end
         
         updateStatus(obj.Block,'VidStreams',flag,index);
      end
   end
   
   % PROTECTED
   methods (Access=protected)  
      % Check to see if data is present and if not, initialize the stream
      function dataIsValid = checkData(obj)
         % CHECKDATA    Check if data is present, if not, make file
         %
         %  dataIsValid = checkData(obj);
         %  --> Returns logical flag or array of flags (if obj is array)
         %     * True indicates that diskfile exists and that it has data
         %        in it.

         if numel(obj) > 1
            dataIsValid = false(size(obj));
            for i = 1:numel(obj)
               dataIsValid(i) = checkData(obj(i));
            end
            return;
         end
         
         dataIsValid = checkSize(obj.disk);
      end
      
      % Overloaded method from CustomDisplay superclass
      function s = getHeader(obj)
         % Returns link to help popup unless object is empty or invalid
         
         s = getHeader@matlab.mixin.CustomDisplay(obj);
%          s = sprintf('Invalid <strong>VidStreamsType</strong> object\n');
%          if isempty(obj)
%             return;
%          elseif ~isvalid(obj)
%             return;
%          end
%          s = sprintf(...
%             ['<a href="matlab:helpPopup nigeLab.libs.VidStreamsType;">'...
%              'VidStreamsType</a> object\n']);
      end
      
      % Overloaded method from CustomDisplay superclass
      function s = getFooter(obj)
         %GETFOOTER  Method overload from CustomDisplay superclass
         
         s = '';
         if isempty(obj)
            return;
         elseif ~isvalid(obj)
            return;
         end
         n = numel(obj);
         if n == 1
            pluStr = '';
         else
            pluStr = 's';
         end
         s = sprintf('--> Contains: <strong>%g</strong> Stream%s\n',...
            numel(obj),pluStr);
         m = {'findIndex','getStream'};
         s = [s, '--> Public methods: ' ...
            sprintf('<strong>%s</strong>, ',m{:}), ...
            sprintf('\b\b\n')];

      end
   end
   
   % STATIC,PUBLIC
   methods (Static,Access=public)
      function obj = empty(n)
         %EMPTY  Return empty nigeLab.libs.VidStreamsType object or array
         %
         %  obj = nigeLab.libs.VidStreamsType.empty();
         %  --> Return scalar (0 x 0) object
         %
         %  obj = nigeLab.libs.VidStreamsType.empty(dims);
         %  --> Specify dimensions
         
         if nargin < 1
            dims = [0, 0];
         else
            if ~isscalar(n)
               error(['nigeLab:' mfilename ':invalidEmptyDims'],...
                  'Input to nigeLab.libs.VidStreamsType.empty should be scalar.');
            end
            dims = [0, n];
         end
         
         obj = nigeLab.libs.VidStreamsType(dims);
      end
   end
   % % % % % % % % % % END METHODS% % %
end