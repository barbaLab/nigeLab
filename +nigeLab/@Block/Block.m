classdef Block < matlab.mixin.Copyable
   % BLOCK    Creates datastore for an electrophysiology recording.
   %
   %  blockObj = nigeLab.Block();
   %     --> select Block path information from UI
   %  blockObj = nigeLab.Block(blockPath);
   %     --> blockPath can be set as [] or char array with location
   %  blockObj = nigeLab.Block(blockPath,animalPath);
   %     --> animalPath can be [] or char array with location
   %  blockObj = nigeLab.Block(__,'PropName1',propVal1,...);
   %     --> allows specification of properties in constructor
   %
   %  ex:
   %  blockObj = nigeLab.Block([],'P:\Your\Recording\Directory\Here');
   %
   %  BLOCK Properties:
   %     Name - Name of recording BLOCK.
   %
   %     Animal - "Parent" nigeLab.Animal object
   %
   %     Graphics - Struct that contains pointers to graphics files.
   %
   %     Status - Completion status for each element of BLOCK/FIELDS.
   %
   %     Channels - Struct that contains data fields.
   %                 -> blockObj.Channels(7).Raw(1:10) First 10 samples of
   %                                                    channel 7 from the
   %                                                    raw waveform.
   %                 -> blockObj.Channels(1).Spikes.peak_train  Spike
   %                                                           peak_train
   %                                                           for chan 1.
   %
   %     Meta - Struct containing metadata info about recording BLOCK.
   %
   %  BLOCK Methods:
   %     Block - Class constructor. Call as blockObj = BLOCK(varargin)
   %
   %     doRawExtraction - Convert from raw data binaries to BLOCK format.
   %
   %     doUnitFilter - Apply bandpass filter for unit activity.
   %
   %     doReReference - Apply common average re-reference for de-noising.
   %
   %     doSD - Run spike detection and feature extraction.
   %
   %     doLFPExtraction - Use cascaded lowpass filter to decimate raw data
   %                       to a rate more suitable for LFP analyses.
   %
   %     doVidInfoExtraction - Get video metadata if there are related
   %                           behavioral videos associated with a
   %                           recording.
   %
   %     doVidSyncExtraction - Get time-series of "digital HIGH" times
   %                           based on detection of ON/OFF state of a
   %                           video element, such as a flashing LED.
   %
   %     doBehaviorSync - Get synchronization signal from digital inputs.
   %
   %     plotWaves -    Make a preview of the filtered waveform for all
   %                    channels, and include any sorted, clustered, or
   %                    detected spikes for those channels as highlighted
   %                    marks at the appropriate time stamp.
   %
   %     plotSpikes -   Display all spikes for a particular channel as a
   %                    SPIKEIMAGE object.
   %
   %     linkToData - Link block object to existing data structure.
   %
   %     clearSpace - Remove extracted RAW data, and extracted FILTERED
   %                  data if CAR channels are present.
   %
   %     analyzeRMS - Get RMS for all channels of a desired type of stream.
   %
   %     Empty - Create an Empty BLOCK object or array
   
   %% PROPERTIES
   % Public properties that are SetObservable
   properties (Access = public, SetObservable = true)
      Name     char            % Name of the recording block
   end
   
   % Public properties that can be modified externally
   properties (SetAccess = public, GetAccess = public)
      Channels struct                        % Struct array of neurophysiological stream data
      Events   struct                        % Struct array of asynchronous events
      Graphics struct                        % Struct for associated graphics objects
      Meta     struct                        % Metadata struct with info about the recording
      Pars     struct                        % Parameters struct
      Streams  struct                        % Struct array of non-electrode data streams
      Videos   nigeLab.libs.VideosFieldType  % Array of nigeLab.libs.VideosFieldType
   end
   
   % Public properties that can be modified externally but don't show up in
   % the list of fields that you see in the Matlab editor
   properties (SetAccess = public, Hidden = true, GetAccess = public)
      CurrentJob                % parallel.job.MJSCommunicatingJob
      OnRemote logical = false  % Is this block running a job on remote worker?
      UserData                  % Allow UserData property to exist
   end
   
   % Properties that can be obtained externally, but must be set by a
   % method of the class object.
   properties (SetAccess = private, GetAccess = public)
      Fields      cell     % List of property field names
      FileExt     char         % .rhd, .rhs, or other
      HasParsFile  logical=false  % Flag --> True if _Pars.mat exists
      IDFile      char         % full filename of .nigelBlock ID file
      IDInfo      struct       % Struct from .nigelBlock ID file
      Mask        double       % Vector of indices of included elements of Channels
      Notes       struct       % Notes from text file
      NumProbes   double = 0   % Number of electrode arrays
      NumChannels double = 0   % Number of electrodes on all arrays
      Status      struct  % Completion status for each element of BLOCK/FIELDS
      PathExpr    struct  % Path expressions for creating file hierarchy
      Paths       struct  % Detailed paths specifications for all the saved files
      ParamsExpr  char = '%s_Pars.mat'  % Expression for parameters file
      Probes      struct  % Probe configurations associated with saved recording
      RMS         table   % RMS noise table for different waveforms
      RecSystem   nigeLab.utils.AcqSystem  % 'RHS', 'RHD', or 'TDT' (must be one of those)
      RecType     char                     % Intan / TDT / other
      SampleRate  double   % Recording sample rate
      Samples     double   % Total number of samples in original record
      Scoring     struct   % Metadata about any scoring done
      Time        char     % Points to Time File
      UseParallel logical % Flag indicating whether this machine can use parallel processing
   end
   
   % Observable properties for internal use
   properties (SetAccess = private, GetAccess = public, SetObservable = true)
      IsMasked logical = true  % Is this Block enabled (true) or disabled (false)?
   end
   
   % Get/Set observable User property
   properties (SetAccess=private,GetAccess=public,SetObservable,GetObservable)
      User        char         % Name of current User
   end
   
   % Properties that can be obtained externally, but must be set by a
   % method of the class object, and don't populate in the editor window or
   % in the tab-completion window
   properties (SetAccess = private, GetAccess = public, Hidden = true)
      AnimalLoc     % Saving path for extracted/processed data
      FieldType         % Indicates types for each element of Field
      FileType          % Indicates DiskData file type for each Field
      RecFile       % Raw binary recording file
      SaveFormat    % saving format (MatFile,HDF5,dat, current: "Hybrid")
   end
   
   % Properties that must be both set and accessed by methods of the BLOCK
   % class only.
   properties (SetAccess = private, GetAccess = private)
      ForceSaveLoc            logical     % Flag to force make non-existent directory
      RecLocDefault           char        % Default location of raw binary recording
      AnimalLocDefault        char        % Default location of BLOCK
      ChannelID                           % Unique channel ID for BLOCK
      Verbose = true;                     % Whether to report list of files and fields.
      
      FolderIdentifier        char        % ID '.nigelBlock' to denote a folder is a BLOCK
      Delimiter               char        % Delimiter for name metadata for dynamic variables
      DynamicVarExp           cell        % Expression for parsing BLOCK names from raw file
      IncludeChar             char        % Character indicating included name elements
      DiscardChar             char        % Character indicating discarded name elements
      
      MultiAnimalsChar  % Character indicating the presence of many animals in the recording
      MultiAnimals = 0; % flag for many animals contained in one block
      MultiAnimalsLinkedBlocks % Pointer to the splitted blocks.
      %                 In conjuction with the multianimals flag keeps track of
      %                 where the data is temporary saved.
      
      NamingConvention        cell        % How to parse dynamic name variables for Block
      DCAmpDataSaved          logical     % Flag indicating whether DC amplifier data saved
      
      MatFileWorkflow         struct      % Struct with fields below:
      %                            --> ReadFcn     function handle to external
      %                                            matfile header loading function
      %                            --> ConvertFcn  function handle to "convert"
      %                                            old (pre-extracted) blocks to
      %                                            nigeLab format
      %                            --> ExtractFcn  function handle to use for
      %                                            'do' extraction methods
      
      ViableFieldTypes       cell         % List of 'Viable' possible field types
   end
   
   % Private - Listeners & Flags
   properties (SetAccess = public, GetAccess = private, Hidden = true)
      % Listeners
      PropListener  event.listener  % event.listener array for properties of this Block
      Listener  event.listener % event.listener array associated with this Block
      
      % Flags
      IsEmpty logical = true   % True if no data in this (e.g. Empty() method used)
   end
   
   % Key pair for "public" and "private" key identifier
   properties (SetAccess = private, GetAccess = private, Hidden = true)
      KeyPair  struct  % Fields are "public" and "private" (hashes)
   end
   
   %% EVENTS
   events (ListenAccess = public, NotifyAccess = public)
      ProgressChanged  % Issued by nigeLab.Block/reportProgress
      StatusChanged    % Issued by nigeLab.Block/updateStatus
   end
   
   %% METHODS
   % PUBLIC
   % Class constructor and overloaded methods
   methods (Access = public)
      % BLOCK class constructor
      function blockObj = Block(blockPath,animalPath,varargin)
         % BLOCK    Creates datastore for an electrophysiology recording.
         %
         %  blockObj = nigeLab.Block();
         %     --> select Block path information from UI
         %  blockObj = nigeLab.Block(blockPath);
         %     --> blockPath can be set as [] or char array with location
         %  blockObj = nigeLab.Block(blockPath,animalPath);
         %     --> animalPath can be [] or char array with location
         %  blockObj = nigeLab.Block(__,'PropName1',propVal1,...);
         %     --> allows specification of properties in constructor
         %
         %  ex:
         %  blockObj = nigeLab.Block([],'P:\Your\Rec\Directory\Here');
         
         % Parse Inputs
         if nargin < 1
            blockObj.RecFile = [];
         else
            if isempty(blockPath)
               blockObj.RecFile = [];
            elseif isnumeric(blockPath)
               % Create empty object array and return
               dims = blockPath;
               blockObj = repmat(blockObj,dims);
               for i = 1:dims(1)
                  for k = 1:dims(2)
                     % Make sure they aren't just all the same handle
                     blockObj(i,k) = copy(blockObj(1,1));
                  end
               end
               return;
            elseif ischar(blockPath)
               blockObj.RecFile = blockPath;
            else
               error(['nigeLab:' mfilename ':badInputType1'],...
                  'Bad blockPath input type: %s',class(blockPath));
            end
         end
         
         % At this point it will be initialized "normally"
         blockObj.IsEmpty = false;
         if nargin < 2
            blockObj.AnimalLoc = [];
         else
            blockObj.AnimalLoc = animalPath;
         end
         
         % Load default parameters
         [pars,blockObj.Fields] = nigeLab.defaults.Block;
         blockObj.addPropListeners(); % Initialize any listeners
         allNames = fieldnames(pars);
         allNames = reshape(allNames,1,numel(allNames));
         for name_ = allNames
            % Check to see if it matches any of the listed properties
            if isprop(blockObj,name_{:})
               blockObj.(name_{:}) = pars.(name_{:});
            end
         end
         
         % Overwrite default parameters if optional inputs are specified
         if numel(varargin)>1
            mc = metaclass(blockObj);
            mcp = {mc.PropertyList.Name};
         end
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue;
            end
            % Check to see if it matches any of the listed properties
            idx = ismember(lower(mcp),lower(varargin{iV}));
            if sum(idx)==1
               blockObj.(mcp{idx}) = varargin{iV+1};
            end
         end
         
         % Look for "Block" directory
         if isempty(blockObj.RecFile)
            [file,path]= uigetfile(fullfile(blockObj.RecLocDefault,'*.*'),...
               'Select recording BLOCK');
            if file == 0
               error(['nigeLab:' mfilename ':NoSelection'],...
                  'No block selected. Object not created.');
            end
            blockObj.RecFile =(fullfile(path,file));
         else
            if isdir(blockObj.RecFile)
               if isempty(blockObj.AnimalLoc)
                  tmp = strsplit(blockObj.RecFile,filesep);
                  tmp = strjoin(tmp(1:(end-1)),filesep);
                  tmp = nigeLab.utils.getUNCPath(tmp);
                  blockObj.AnimalLoc = tmp;
               end
            elseif exist(blockObj.RecFile,'file')==0
               error(['nigeLab:' mfilename ':invalidBlockFile'],...
                  '%s is not a valid block file.',blockObj.RecFile);
            end
         end
         
         blockObj.RecFile =nigeLab.utils.getUNCPath(blockObj.RecFile);
         if ~blockObj.init()
            error(['nigeLab:' mfilename ':badBlockInit'],...
               'Block object construction unsuccessful.');
         end
      end
      
      % Overloaded DELETE method for BLOCK to ensure listeners are deleted
      % properly.
      function delete(blockObj)
         % DELETE  Delete blockObj.Listener and other objects that we don't
         %           want floating around in the background after the Block
         %           itself is deleted.
         %
         %  delete(blockObj);
         
         if numel(blockObj) > 1
            for i = 1:numel(blockObj)
               delete(blockObj(i));
            end
            return;
         end
         
         % Destroy any listeners associated with this Block
         if ~isempty(blockObj.Listener)
            for lh = blockObj.Listener
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
         
         if ~isempty(blockObj.PropListener)
            for lh = blockObj.PropListener
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
      end
      
      % Returns a formatted string that prints a link to open file browser
      % to block save location when printed in Command Window (on Windows).
      % On Unix, the Matlab Editor working path is changed to show the
      % location of the files corresponding to `field` (or BLOCK if no
      % `field` is specified)
      function linkStr = getLink(blockObj,field)
         %GETLINK  Returns formatted string for link to Block in cmd window
         %
         %  linkStr = blockObj.getLink();  Returns BLOCK link
         %
         %  linkStr = blockObj.getLink('fieldName');  Returns link to
         %                                   'fieldName' (if it exists).
         %                                   Otherwise, throws an error.
         %  --> e.g.
         %  >> linkStr = blockObj.getLink('Raw');
         %
         %  <strong>NOTE:</strong> `field` is case-sensitive
         %
         %  UNIX links:
         %     1) add nigeLab to current Matlab path
         %     2) play "pop" noise
         %     3) change current folder to linked folder
         %
         %  WINDOWS links:
         %     1) play "pop" noise
         %     2) open linked folder in system file browser (explorer.exe)
         
         if nargin < 2
            field = 'SaveLoc';
         end
         
         if ~isfield(blockObj.Paths,field)
            error(['nigeLab:' mfilename ':UnexpectedString'],...
               '%s is not a field of blockObj.Paths',field);
         end
         
         if isunix
            str = strrep(blockObj.Paths.(field).dir,'\','/');
            linkStr = sprintf(...
               ['<a href="matlab: addpath(nigeLab.utils.getNigelPath()); ' ...
               'nigeLab.sounds.play(''pop''); ' ...
               'cd(''%s'');">%s</a>'],...
               str,'Navigate to Files in Current Folder');
            return;
         else
            str = strrep(blockObj.Paths.(field).dir,'\','/');
            linkStr = sprintf(...
               ['<a href="matlab: nigeLab.sounds.play(''pop''); ' ...
               'winopen(''%s'');">%s</a>'],...
               str,'View Files in Explorer');
            
         end
      end
      
      % Returns the public hash key for this block
      function key = getKey(blockObj,keyType)
         %GETKEY  Return the public hash key for this block
         %
         %  publicKey = blockObj.getKey('Public');
         %  privateKey = blockObj.getKey('Private'); Really not useful but
         %                                            there for future
         %                                            expansion.
         %
         %  key --  .Public field of blockObj.KeyPair
         %
         %  If blockObj is array, then publicKey is returned as cell array
         %  of dimensions equivalent to blockObj.
         
         if nargin < 2
            keyType = 'Public';
         end
         if ~ismember(keyType,{'Public','Private'})
            error(['nigeLab:' mfilename ':BadKeyType'],...
               'keyType must be ''Public'' or ''Private''');
         end
         
         n = numel(blockObj);
         if n > 1
            key = cell(size(blockObj));
            for i = 1:n
               key{i} = blockObj(i).getKey();
            end
            return;
         end
         
         if isempty(blockObj.KeyPair)
            blockObj.initKey();
         elseif ~isfield(blockObj.KeyPair,keyType)
            blockObj.initKey();
         end
         key = blockObj.KeyPair.(keyType);
         
      end
      
      % Return a parameter (making sure Pars fields exist)
      function varargout = getParams(blockObj,parsField,varargin)
         %GETPARAMS  Return a parameter (making sure Pars fields exist)
         %
         %  val = blockObj.getParams('Sort','Debug');
         %  --> Returns value of blockObj.Pars.Sort.Debug
         %  --> If field doesn't exist, returns []
         %
         %  [val] = getParams(blockObjArray,'Sort','Debug');
         %  --> Returns array for entire blockObjArray
         
         if numel(blockObj) > 1
            varargout = cell(1,numel(blockObj));
            for i = 1:numel(blockObj)
               if numel(varargin) > 0
                  varargout{i} = blockObj(i).getParams(parsField,varargin{:});
               else
                  varargout{i} = blockObj(i).getParams(parsField);
               end
            end
            return;
         end
         
         if ~isfield(blockObj.Pars,parsField)
            varargout = {[]};
            return;
         end
         s = blockObj.Pars.(parsField);
         
         for i = 1:numel(varargin)
            if ~isfield(s,varargin{i})
               s = [];
               break;
            else
               s = s.(varargin{i});
            end            
         end
         varargout = {s};
      end
      
      % Load .Pars from _Pars.mat or load a sub-field .Pars.(parsField)
      function flag = loadParams(blockObj,parsField)
         %LOADPARAMS   Load .Pars or .Pars.(parsField) from (user) file
         %
         %  blockObj.loadParams();  Load all of blockObj.Pars from file
         %  blockObj.loadParams(parsField); Load just that field of .Pars
         
         if numel(blockObj) > 1
            flag = true;
            for i = 1:numel(blockObj)
               if nargin < 2
                  flag = flag && blockObj(i).loadParams();
               else
                  flag = flag && blockObj(i).loadParams(parsField);
               end
            end
            return;
         else
            flag = false;
         end
         
         if nargin < 2
            if ~blockObj.HasParsFile
               if ~blockObj.checkParsFile()
                  warning('No _Pars file for %s (.User: %s)',...
                     blockObj.Name,blockObj.User);
                  return;
               end
            end
         else
            if ~blockObj.checkParsFile(parsField)
               warning('User (%s) not recognized in _Pars file for %s',...
                     blockObj.User,blockObj.Name);
               return;
            end
         end
         fname_params = blockObj.getParsFilename();
         in = load(fname_params);
         if isempty(blockObj.Pars)
            blockObj.Pars = struct;
         end
         if nargin < 2
            blockObj.Pars = in.(blockObj.User);
         else
            blockObj.Pars.(parsField) = in.(blockObj.User).(parsField);
         end
         flag = true;
      end
      
      % Overload to 'isempty'
      function tf = isempty(blockObj)
         % ISEMPTY  Returns true if .IsEmpty is true or if builtin isempty
         %          returns true. If blockObj is array, then returns an
         %          array of true or false for each element of blockObj.
         
         if numel(blockObj) == 0
            tf = true;
            return;
         end
         
         if ~isscalar(blockObj)
            tf = false(size(blockObj));
            for i = 1:numel(blockObj)
               tf(i) = isempty(blockObj(i));
            end
            return;
         end
         
         tf = blockObj.IsEmpty || builtin('isempty',blockObj);
      end
      
      % Overloaded NUMARGUMENTSFROMSUBSCRIPT method for parsing indexing.
      function n = numArgumentsFromSubscript(blockObj,s,indexingContext)
         % NUMARGUMENTSFROMSUBSCRIPT  Parse # args based on subscript type
         %
         %  n = blockObj.numArgumentsFromSubscript(s,indexingContext);
         %
         %  s  --  struct from SUBSTRUCT method for indexing
         %  indexingContext  --  matlab.mixin.util.IndexingContext Context
         %                       in which the result applies.
         
         dot = strcmp({s(1:min(length(s),2)).type}, '.');
         if sum(dot) < 2
            if indexingContext == matlab.mixin.util.IndexingContext.Statement &&...
                  any(dot) && any(strcmp(s(dot).subs,methods(blockObj)))
               
               mc = metaclass(blockObj);
               calledmethod=(strcmp(s(dot).subs,{mc.MethodList.Name}));
               n = numel(mc.MethodList(calledmethod).OutputNames);
            else
               n = builtin('numArgumentsFromSubscript',...
                  blockObj,s,indexingContext);
            end
         else
            n = builtin('numArgumentsFromSubscript',...
               blockObj,s,indexingContext);
         end
      end
      
      % Overloaded SAVE method for BLOCK to handle child objects such as
      % listener handles, as well as to deal with splitting multi-block
      % cases etc.
      function flag = save(blockObj)
         % SAVE  Overloaded SAVE method for BLOCK
         %
         %  blockObj.save;          This works
         %  flag = save(blockObj);  This also works
         %
         %  flag returns true if the save did not throw an error.
         
         % Make sure array isn't saved to same file
         if numel(blockObj) > 1
            flag = false(size(blockObj));
            for i = 1:numel(blockObj)
               flag(i) = blockObj(i).save;
            end
            return;
         end
         
         flag = false;
         
         blockObj.updateParams('Block');
         % Handles the case of MultiAnimals. Avoids infinite save loop
         
         % Save blockObj
         blockFile = nigeLab.utils.getUNCPath(...
            [blockObj.Paths.SaveLoc.dir '_Block.mat']);
         lh = blockObj.Listener;
         save(blockFile,'blockObj','-v7');
         blockObj.Listener = lh;
         blockObj.saveIDFile(); % .nigelBlock file saver
         
         % save multianimals if present
         if blockObj.MultiAnimals
            for bl = blockObj.MultiAnimalsLinkedBlocks
               bl.MultiAnimalsLinkedBlocks(:) = [];
               bl.MultiAnimals = false;
               bl.save();
            end
         end
         flag = true;
         
      end
      
      % Overloaded SAVE method to ensure that additional object handles
      % don't save with the object
      function blockObj = saveobj(blockObj)
         % SAVEOBJ  Overloaded saveobj method to ensure that additional
         %          object handles do not save with the object
         %
         %  blockObj.saveobj();
         
         blockObj.Listener(:) = [];
         blockObj.PropListener(:) = [];
         blockObj.CurrentJob = [];
      end
      
      % Method to save any parameters as a .mat file for a given User
      function saveParams(blockObj,userName,parsField)
         %SAVEPARAMS  Method to save blockObj.Pars, given blockObj.User
         %
         %  blockObj.saveParams();  Uses .Pars and .User fields to save
         %  blockObj.saveParams('user'); Assigns current parameters to
         %     username 'user' and updates blockObj.User to 'user'.
         %  blockObj.saveParams('user','Sort'); Only saves 'Sort'
         %     parameters under the variable 'user' in the _Pars.mat file
         
         if isempty(blockObj)
            return;
         end
         
         if nargin < 2
            userName = blockObj.User;
         end
         
         if numel(blockObj) > 1
            for i = 1:numel(blockObj)
               if nargin < 3
                  blockObj(i).saveParams(userName);
               else
                  blockObj(i).saveParams(userName,parsField);
               end
            end
            return;
         end
         
         fname_params = blockObj.getParsFilename();
         
         if exist(fname_params,'file')==0 % If absent, make new file
            % Do this way to avoid 'eval' for weird names in workspace
            out = struct;
         else % otherwise, load old file and save as struct
            out = load(fname_params);
         end
         
         if nargin < 3
            out.(userName) = blockObj.Pars;
         else
            out.(userName).(parsField)=blockObj.getParams(parsField);
         end
         save(fname_params,'-struct','out');
         blockObj.HasParsFile = true;
      end
      
      % Overloaded RELOAD method for loading a BLOCK matfile
      function reload(blockObj,field)
         % RELOAD  Load block (related to multi-animal stuff?)
         
         if nargin < 2
            field = 'all';
         end
         
         obj = load(fullfile([blockObj.Paths.SaveLoc.dir '_Block.mat']));
         ff=fieldnames(obj.blockObj);
         if strcmpi(field,'all')
            field = ff;
         end
         indx = find(ismember(ff,field))';
         for f=indx
            blockObj.(ff{f}) = obj.blockObj.(ff{f});
         end
      end      
      
      % Method to set username
      function setUser(blockObj,username)
         %SETUSER  Method to set user currently working on block
         %
         %  blockObj.setUser();       Sets User to blockObj.Pars.Video.User
         %                             (if it exists) or else random hash
         %  blockObj.setUser('MM');   Sets User property to 'MM'
         
         if numel(blockObj) > 1
            for i = 1:numel(blockObj)
               if nargin < 2
                  setUser(blockObj(i));
               else
                  setUser(blockObj(i),username);
               end
            end
            return;
         end
         
         if nargin < 2
            if isstruct(blockObj.Pars) && ~isempty(blockObj.Pars)
               if isfield(blockObj.Pars,'Video')
                  if isfield(blockObj.Pars.Video,'User')
                     username = blockObj.Pars.Video.User;
                  else
                     username = nigeLab.utils.makeHash();
                     username = username{:}; % Should be char array
                  end
               end
            end
         end
         
         blockObj.User = username; % Assignment
         blockObj.checkParsFile();
      end
      
      % Method to SET PARAMETERS (e.g. for updating saved parameters)
      function setParams(blockObj,parsField,varargin)
         % SETPARAMS  "Set" a parameter so that it is updated in diskfile
         %
         %  parsField : Char array; member of fieldnames(blockObj.Pars)
         %
         %  varargin : Intermediate fields; last element is always value.
         %
         %  value = blockObj.Pars.Sort;
         %  blockObj.setParams('Sort',value);
         %  --> First input is always name of .Pars field
         %     --> This call would just update blockObj.Pars.Sort to
         %         whatever is currently in blockObj.Pars.Sort (and
         %         overwrite that in the corresponding 'User' variable of
         %         the _Pars.mat file)
         %
         %  value = blockObj.Pars.Video.CameraKey.Index;
         %  blockObj.setParams('Video','CameraKey','Index',value);
         %  --> Updates specific field of CameraKey Video param (Index)
         
         if numel(varargin) > 5
            error(['nigeLab:' mfilename ':TooManyStructFields'],...
               ['Not currently configured for more than 4 fields deep.\n'...
                'Add to switch ... case']);
         end
         
         if numel(blockObj) > 1
            for i = 1:numel(blockObj)
               blockObj(i).setParams(parsField,varargin{:});
            end
            return;
         end
         
         val = varargin{end};
         f = varargin(1:(end-1));
         if ~isfield(blockObj.Pars,parsField)
            blockObj.updateParams(parsField);
         end
         s = blockObj.Pars.(parsField);
         
         % Do error check
         for i = 1:f
            if ~isfield(s,f{i})
               error(['nigeLab:' mfilename ':MissingField'],...
                  'Missing field (''%s'') of (blockObj.Pars.%s...)\n',...
                     f{i},parsField);
            end
         end
         
         % If good, then make dynamic struct expression. Don't expect more
         % than "4 fields deep" on a struct
         switch numel(f)
            case 0
               blockObj.Pars.(parsField) = val;
            case 1
               blockObj.Pars.(parsField).(f{1}) = val;
            case 2
               blockObj.Pars.(parsField).(f{1}).(f{2}) = val;
            case 3
               blockObj.Pars.(parsField).(f{1}).(f{2}).(f{3}) = val;
            case 4
               blockObj.Pars.(parsField).(f{1}).(f{2}).(f{3}).(f{4}) = val;
            otherwise
               error(['nigeLab:' mfilename ':TooManyStructFields'],...
                ['Not currently configured for more than 4 fields deep.\n'...
                 'Add to switch ... case']);
               
         end
         
         blockObj.saveParams(blockObj.User,parsField);
            
      end
      
      % PROPERTY LISTENER CALLBACK: Username string validation
      function validateUserString(blockObj,eventName)
         %VALIDATEUSERSTRING Check that blockObj.User is set to valid chars
         %
         % addlistener(blockObj,'User','PostSet',...
         %     @(~,evt)blockObj.ValidateUserString(evt.EventName));
         % addlistener(blockObj,'User','PreGet',...
         %     @(~,evt)blockObj.ValidateUserString(evt.EventName));
         
         switch eventName
            case 'PostSet'
               blockObj.User = strrep(blockObj.User,' ','_');
               blockObj.User = strrep(blockObj.User,'-','_');
               blockObj.User = strrep(blockObj.User,'.','_');
               if regexp(blockObj.User(1),'\d')
                  error(['nigeLab:' mfilename ':InvalidUsername'],...
                     'blockObj.User must start with alphabetical element.');
               end
               
            case 'PreGet'
               if isempty(blockObj.User)
                  setUser(blockObj);
               end
            otherwise
               % does nothing
         end
      end
   end
   
   % Methods accessible by "parent" Animal
   methods (Access = ?nigeLab.Animal)
      % Set BlockMask flag (.IsMasked) for this block
      function updateMaskFlag(blockObj,animalObj)
         %UPDATEMASKFLAG  Sets the BlockMask flag (.IsMasked)
         %
         %  addlistener(animalObj,'BlockMask','PostSet',...
         %     @blockObj.updateMaskFlag);
         
         [~,idx] = findByKey(animalObj.Blocks,blockObj);
         blockObj.IsMasked = animalObj.BlockMask(idx);
      end
   end
   
   % Methods to be catalogued in CONTENTS.M
   methods (Access = public)
      setProp(blockObj,varargin) % Set property for all blocks in array
      [blockObj,idx] = findByKey(blockObjArray,keyStr,keyType); % Find block from block array based on public or private hash
      
      % Scoring videos
      fig = scoreVideo(blockObj) % Score videos manually to get behavioral alignment points
      fig = alignVideoManual(blockObj,digStreams,vidStreams); % Manually obtain alignment offset between video and digital records
      fieldIdx = checkCompatibility(blockObj,requiredFields) % Checks if this block is compatible with required field names
      flag = checkParallelCompatibility(blockObj) % Check if parallel can be run
      offset = guessVidStreamAlignment(blockObj,digStreamInfo,vidStreamInfo);
      
      addScoringMetadata(blockObj,fieldName,info); % Add scoring metadata to table for tracking scoring on a video for example
      info = getScoringMetadata(blockObj,fieldName,hashID); % Retrieve row of metadata scoring
      
      % Methods for data extraction:
      checkActionIsValid(blockObj,nDBstackSkip);  % Throw error if appropriate processing not yet complete
      flag = doRawExtraction(blockObj)  % Extract raw data to Matlab BLOCK
      flag = doEventDetection(blockObj,behaviorData,vidOffset) % Detect "Trials" for candidate behavioral Events
      flag = doEventHeaderExtraction(blockObj,behaviorData,vidOffset)  % Create "Header" for behavioral Events
      flag = doUnitFilter(blockObj)     % Apply multi-unit activity bandpass filter
      flag = doReReference(blockObj)    % Do virtual common-average re-reference
      flag = doSD(blockObj)             % Do spike detection for extracellular field
      flag = doLFPExtraction(blockObj)  % Extract LFP decimated streams
      flag = doVidInfoExtraction(blockObj,vidFileName) % Get video information
      flag = doBehaviorSync(blockObj)      % Get sync from neural data for external triggers
      flag = doVidSyncExtraction(blockObj) % Get sync info from video
      flag = doAutoClustering(blockObj,chan,unit) % Do automatic spike clustiring
      
      % Methods for streams info
      stream = getStream(blockObj,streamName,source,scaleOpts); % Returns stream data corresponding to streamName
      
      % Methods for parsing channel info
      flag = parseProbeNumbers(blockObj) % Get numeric probe identifier
      flag = setChannelMask(blockObj,includedChannelIndices) % Set "mask" to look at
      
      % Methods for parsing spike info:
      tagIdx = parseSpikeTagIdx(blockObj,tagArray) % Get tag ID vector
      ts = getSpikeTimes(blockObj,ch,class)    % Get spike times (sec)
      idx = getSpikeTrain(blockObj,ch,class)   % Get spike sample indices
      spikes = getSpikes(blockObj,ch,class,type)   % Get spike waveforms
      features = getSpikeFeatures(blockObj,ch,class) % Get extracted features
      sortIdx = getSort(blockObj,ch,suppress)  % Get spike sorted classes
      clusIdx = getClus(blockObj,ch,suppress)  % Get spike cluster classes
      [tag,str] = getTag(blockObj,ch)          % Get spike sorted tags
      flag = saveChannelSpikingEvents(blockObj,ch,spk,feat,art) % Save spikes for a channel
      flag = checkSpikeFile(blockObj,ch) % Check a spike file for compatibility
      
      % Method for accessing event info:
      idx = getEventsIndex(blockObj,field,eventName);
      [data,blockIdx] = getEventData(blockObj,field,prop,ch,matchValue,matchField) % Retrieve event data
      flag = setEventData(blockObj,fieldName,eventName,propName,value,rowIdx,colIdx);
      
      % Computational methods:
      [tf_map,times_in_ms] = analyzeERS(blockObj,options) % Event-related synchronization (ERS)
      analyzeLFPSyncIndex(blockObj)  % LFP synchronization index
      rms_out = analyzeRMS(blockObj,type,sampleIndices)  % Compute RMS for channels
      
      % Methods for producing graphics:
      flag = plotWaves(blockObj)          % Plot stream snippets
      flag = plotSpikes(blockObj,ch)      % Show spike clusters for a single channel
      flag = plotOverlay(blockObj)        % Plot overlay of values on skull
      
      % Methods for associating/displaying info about blocks:
      L = list(blockObj,keyIdx) % List of current associated files for field or fields
      flag = updateVidInfo(blockObj) % Update video info
      flag = linkToData(blockObj,suppressWarning) % Link to existing data
      flag = linkField(blockObj,fieldIndex)     % Link field to data
      flag = linkChannelsField(blockObj,field,fType)  % Link Channels field data
      flag = linkEventsField(blockObj,field)    % Link Events field data
      flag = linkStreamsField(blockObj,field)   % Link Streams field data
      flag = linkVideosField(blockObj,field)    % Link Videos field data
      flag = linkTime(blockObj)     % Link Time stream
      flag = linkNotes(blockObj)    % Link notes metadata
      flag = linkProbe(blockObj)    % Link probe metadata
      
      % Methods for storing & parsing metadata:
      h = takeNotes(blockObj)             % View or update notes on current recording
      parseNotes(blockObj,str)            % Update notes for a recording
      header = parseHeader(blockObj)      % Parse header depending on structure
      
      % Methods for parsing Fields info:
      fileType = getFileType(blockObj,field) % Get file type corresponding to field
      [fieldType,n] = getFieldType(blockObj,field) % Get type corresponding to field
      [fieldIdx,n] = getFieldTypeIndex(blockObj,fieldType) % Get index of all fields of a given type
      [fieldIdx,n] = getStreamsFieldIndex(blockObj,field,type) % Get index into Streams for a given Field
      notifyStatus(blockObj,field,status,channel) % Triggers event notification to blockObj
      opOut = updateStatus(blockObj,operation,value,channel) % Indicate completion of phase
      flag = updatePaths(blockObj,SaveLoc)     % updates the path tree and moves all the files
      [flag,p] = updateParams(blockObj,paramType) % Update parameters
      status = getStatus(blockObj,operation,channel)  % Retrieve task/phase status
      
      % Miscellaneous utilities:
      N = getNumBlocks(blockObj) % This is just to make it easier to count total # blocks
      notifyUser(blockObj,op,stage,curIdx,totIdx) % Update the user of progress
      str = reportProgress(blockObj,str_expr,pct,notification_mode,tag_str) % Update the user of progress
      checkMask(blockObj) % Just to double-check that empty channels are masked appropriately
      idx = matchProbeChannel(blockObj,channel,probe); % Match Channels struct index to channel/probe combo
   end
   
   % "PRIVATE" methods
   methods (Access = public, Hidden = true) % Can make things PRIVATE later
      flag = intan2Block(blockObj,fields,paths) % Convert Intan to BLOCK
      flag = tdt2Block(blockObj) % Convert TDT to BLOCK
      
      flag = rhd2Block(blockObj,recFile,saveLoc) % Convert *.rhd to BLOCK
      flag = rhs2Block(blockObj,recFile,saveLoc) % Convert *.rhs to BLOCK
      
      flag = genPaths(blockObj,tankPath,useRemote) % Generate paths property struct
      %       flag = findCorrectPath(blockObj,paths)   % (DEPRECATED)
      flag = getSaveLocation(blockObj,saveLoc) % Prompt to set save dir
      paths = getFolderTree(blockObj,paths,useRemote) % returns a populated path struct
      
      clearSpace(blockObj,ask,usrchoice)     % Clear space on disk
      
      flag = init(blockObj) % Initializes the BLOCK object
      flag = initChannels(blockObj,header);   % Initialize Channels property
      flag = initEvents(blockObj);     % Initialize Events property
      flag = initStreams(blockObj);    % Initialize Streams property
      flag = initVideos(blockObj);     % Initialize Videos property
      
      meta = parseNamingMetadata(blockObj); % Get metadata struct from recording name
      channelID = parseChannelID(blockObj); % Get unique ID for a channel
      masterIdx = matchChannelID(blockObj,masterID); % Match unique channel ID
      
      parseRecType(blockObj)              % Parse the recording type
      header = parseHierarchy(blockObj)   % Parse header from file hierarchy
      blocks = splitMultiAnimals(blockObj,varargin)  % splits block with multiple animals in it
   end
   
   methods (Access = private, Hidden = true)
      eventData = getStreamsEventData(blockObj,field,prop,eventName,matchProp,matchValue)
      eventData = getChannelsEventData(blockObj,field,prop,ch,matchProp,matchValue)
   end
   
   % PRIVATE
   methods (Access = private)
      % Initialize property listener array
      function addPropListeners(blockObj)
         %ADDPROPLISTENERS  Initialize .PropListener array
         %
         %  blockObj.addPropListeners();
         %
         %  --> Call during loadobj method, or from object constructor
         
         if isempty(blockObj)
            return;
         end
         
         if numel(blockObj) > 1
            for i = 1:numel(blockObj)
               blockObj(i).addPropListeners();
            end
            return;
         end
         
         blockObj.PropListener = ...
            [addlistener(blockObj,'User','PostSet',...
            @(~,evt)blockObj.validateUserString(evt.EventName)),...
            addlistener(blockObj,'User','PreGet',...
            @(~,evt)blockObj.validateUserString(evt.EventName))];
      end
      
      % Check parameters file to set `HasParsFile` flag for this `User`
      function flag = checkParsFile(blockObj,parsField)
         %CHECKPARSFILE  Sets .HasParsFile for current .User
         %
         %  blockObj.checkParsFile();
         %  blockObj.checkParsFile(parsField); Returns flag indicating if
         %     that field is present
         
         params_fname = blockObj.getParsFilename();
         if exist(params_fname,'file')==0
            blockObj.HasParsFile = false;
            return;
         end
         
         userName = blockObj.User;
         try
            m = matfile(params_fname);
         catch
            warning('%s may be corrupt',params_fname);
            blockObj.HasParsFile = false;
            return;
         end
         allUsers = who(m);
         blockObj.HasParsFile = ismember(userName,allUsers);
         if nargin > 1
            if blockObj.HasParsFile
               flag = isfield(m.(userName),parsField);
            else
               flag = false;
            end
         else
            flag = blockObj.HasParsFile;
         end
      end
      
      % Return full filename to parameters file
      function f = getParsFilename(blockObj,useUNC)
         %GETPARSFILENAME  Returns full (UNC) filename to parameters file
         %
         %  f = blockObj.getParsFilename(); Return UNC path (def)
         %  f = blockObj.getParsFilename(false); Return `fullfile` version
         
         if nargin < 2
            useUNC = true;
         end
         
         if useUNC
            f = nigeLab.utils.getUNCPath(blockObj.Paths.SaveLoc.dir,...
                   sprintf(blockObj.ParamsExpr,blockObj.Name));
         else
            f = fullfile(blockObj.Paths.SaveLoc.dir,...
               sprintf(blockObj.ParamsExpr,blockObj.Name));
         end
      end
      
      % Initialize .KeyPair property
      function flag = initKey(blockObj)
         %INITKEY  Initialize blockObj.KeyPair for use with unique ID later
         %
         %  keyPair = blockObj.initKey();
         
         flag = true;
         if isempty(blockObj)
            return;
         end
         try
            % Ensure it works if input is array object
            n = numel(blockObj);
            if n > 1
               keyPair = struct('Public',cell(1,n),'Private',cell(1,n));
               for i = 1:n
                  keyPair(i) = blockObj(i).initKey();
               end
               return;
            end
            
            hashPair = nigeLab.utils.makeHash(blockObj,2);
            keyPair = struct('Public',hashPair(1),...
               'Private',hashPair(2));
            blockObj.KeyPair = keyPair;
         catch er
            flag = false;
            rethrow(er);
         end
      end
      
      % Load/parse ID file and associated parameters
      function loadIDFile(blockObj)
         %LOADIDFILE  Load and parse .nigelBlock file into .IDInfo property
         %
         %  blockObj.loadIDFile();
         
         if isempty(blockObj)
            return;
         end
         
         if isempty(blockObj.IDFile)
            blockObj.IDFile = nigeLab.utils.getUNCPath(...
               blockObj.Paths.SaveLoc.dir,blockObj.FolderIdentifier);
         end
         
         fid = fopen(blockObj.IDFile,'r+');
         if fid < 0
            % "ID" file doesn't exist; make it using current properties
            blockObj.saveIDFile();
            return;
         end
         C = textscan(fid,'%q %q','Delimiter','|');
         fclose(fid);
         propName = C{1};
         propVal = C{2};
         if ~strcmpi(propName{1},'BLOCK')
            error(['nigeLab:' mfilename ':BadFolderHierarchy'],...
               'Attempt to load non-block from block folder.');
         end
         
         mc = metaclass(blockObj);
         mcp = {mc.PropertyList.Name};
         blockObj.IDInfo = struct;
         blockObj.IDInfo.BLOCK = propVal{1};
         for i = 2:numel(propName)
            if ~contains(propName{i},'.')
               blockObj.IDInfo.(propName{i}) = propVal{i};
            end
            if isempty(propVal{i})
               warning('%s .nigelBlock value missing.\n',propName{i});
               continue;
            end
            setProp(blockObj,propName{i},propVal{i});
         end
         
         if isempty(blockObj.User)
            blockObj.saveIDFile(); % Make sure correct file is saved
         end
         
      end
      
      % Save small folder identifier file
      function saveIDFile(blockObj)
         %SAVEIDFILE  Save small folder identifier file
         %
         %  blockObj.saveIDFile();
         
         % Save .nigelBlock file for convenience of identifying this
         % folder as a "BLOCK" folder in the future
         if isempty(blockObj.IDFile)
            blockObj.IDFile = nigeLab.utils.getUNCPath(...
               blockObj.Paths.SaveLoc.dir,blockObj.FolderIdentifier);
         end
         
         fid = fopen(blockObj.IDFile,'w');
         if fid > 0
            fprintf(fid,'BLOCK|%s\n',blockObj.Name);
            fprintf(fid,'KeyPair.Public|%s\n',blockObj.KeyPair.Public);
            fprintf(fid,'User|%s', blockObj.User);
            fclose(fid);
         else
            warning('Could not write .nigelBlock (%s)',blockObj.IDFile);
         end
         
         blockObj.saveParams();
         
      end
   end
   
   % Static methods to handle "Multi-Blocks" issues
   methods (Static)
      % Method to "cancel" execution of a function evaluation
      function cancelExecution()
         evalin('caller','return;');
      end
      
      % Method to instantiate "Empty" Blocks from constructor
      function blockObj = Empty(n)
         % EMPTY  Creates "empty" block or block array
         %
         %  blockObj = nigeLab.Block.Empty();  % Makes a scalar
         %  blockObj = nigeLab.Block.Empty(n); % Make n-element array Block
         
         if nargin < 1
            n = [0, 0];
         else
            n = nanmax(n,0);
            if isscalar(n)
               n = [0, n];
            end
         end
         
         blockObj = nigeLab.Block(n);
      end
      
      % Overloaded method for loading objects (for "multi-blocks" case)
      function b = loadobj(a)
         % LOADOBJ  Overloaded method called when loading BLOCK.
         %
         %  Has to be called when there MultiAnimals is true because the
         %  BLOCKS are removed from parent objects in that case during
         %  saving.
         %
         %  blockObj = loadobj(blockObj);
         
         % After introducing '.KeyPair' ensure it is backwards-compatible
         if isempty(a.KeyPair)
            a.initKey();
         end
         
         a.addPropListeners();
         a.loadIDFile();
         
         if ~a.MultiAnimals
            b = a;
            return;
         end
         
         % blockObj has "pointer" to 'MultiAnimalsLinkedBlocks' but until
         % they are "reloaded" the "pointer" is bad (references bl in
         % the wrong place, essentially?)
         for bl=a.MultiAnimalsLinkedBlocks
            bl.reload();
         end
         b = a;
      end
   end
   
   % Static enumeration methods
   methods (Static = true, Access = public)
      field = getOperationField(operation); % Get field associated with operation
      blockObj = loadRemote(targetBlockFile); % Load block on remote worker
   end
end