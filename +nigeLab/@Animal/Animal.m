classdef Animal < matlab.mixin.Copyable
% ANIMAL  Create an animal object that manages recordings from a
%           single animal. These could be from the same session,
%           or across multiple days.
%
%  animalObj = nigeLab.Animal();
%     --> prompts using UI
%  animalObj = nigeLab.Animal(animalPath);
%     --> animalPath can be [] or char array of animal location
%  animalObj = nigeLab.Animal(animalPath,tankPath);
%     --> tankPath can be [] or char array of tank location
%  animalObj = nigeLab.Animal(__,'PropName',propValue,...);
%
%  ANIMAL Properties:
%     Name - Name of Animal (identification code)
%
%     Tank - "Parent" nigeLab.Tank object
%
%     Blocks - "Children"
%
%     Probes - Electrode configuration structure
%
%  ANIMAL Methods:
%     Animal - Class constructor
%
%     addChildBlock - Add Blocks to Animal object
%
%     getStatus - Returns status of each Operation/Block pairing
%
%     save - Save 'animalObj' in [Name]_Animal.mat
%
%     setTank - Set "Parent" nigeLab.Tank object
%
%     Empty - Create an Empty ANIMAL object or array
   
   %% PROPERTIES
   % Can get and set publically; SetObservable is true for these.
   properties (GetAccess = public, SetAccess = public, SetObservable)
      Name     char           % Animal identification code
      Blocks   nigeLab.Block  % Children (nigeLab.Block objects)
      BlockMask  logical      % Block "Mask" logical vector
      Probes   struct         % Electrode configuration structure
   end
   
   % Cannot set but may want to see it publically. SetObservable.
   properties (GetAccess = public, SetAccess = private, SetObservable)
      Mask       double        % Channel "Mask" vector (for all recordings)
   end
   
   % Get/Set observable User property
   properties (SetAccess=private,GetAccess=public,SetObservable,GetObservable)
      User        char         % Name of current User
   end
   
   % More likely to externally reference
   properties (SetAccess = private, GetAccess = public)
      HasParsFile  logical=false  % Flag --> True if _Pars.mat exists
      IDFile       char        % Full filename of .nigelAnimal id file
      IDInfo       struct      % Struct parsed from .nigelAnimal ID file
      Paths        struct      % Path to Animal folder
      ParamsExpr   char = '%s_Pars.mat'  % Expression for parameters file
      UseParallel  logical     % Flag to indicate if parallel/remote processing can be done on this machine
   end
   
   properties (Access = public)
      UserData   % User-defined field
   end
   
   % Less-likely but possible to externally reference
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      Pars                       struct      % parameters struct for templates from nigeLab.defaults
      TankLoc                    char        % directory for saving Animal
      RecDir                     char        % directory with raw binary data in intan format
      ExtractFlag                logical     % flag status of extraction for each block
      MultiAnimals = false                       % flag to signal if it's a single animal or a joined animal recording
      MultiAnimalsLinkedAnimals  nigeLab.Animal  % Array of "linked" animals
   end
   
   % Default parameters
   properties  (SetAccess = private, GetAccess = private)
      Fields           cell     % Specific fields for recording
      FieldType        cell     % "Types" of data corresponding to Fields
      RecLocDefault    char     % Default location of raw binary recording
      TankLocDefault   char     % Default location of BLOCK
   end
   
   % Listeners and Flags
   properties (SetAccess = public, GetAccess = private, Hidden = true)
      % Listeners
      BlockListener    event.listener  % event.listener that listens for any child block changes
      Listener         event.listener  % Scalar event.listener associated with this ANIMAL
      PropListener     event.listener  % Array of handles listening to ANIMAL property changes
      
      % Flags
      IsEmpty = true  % Flag to indicate whether block is EMPTY
   end
   
   % Key pair for "public" and "private" key identifier
   properties (SetAccess = private, GetAccess = private, Hidden = true)
       KeyPair  struct  % Fields are "public" and "private" (hashes)
   end
   
   events (ListenAccess = public, NotifyAccess = public)
      StatusChanged  % Issued any time a "child" BLOCK status is changed  
   end
   
   %% METHODS
   % PUBLIC
   % Class constructor and overloaded methods
   methods (Access = public)
      % Class constructor
      function animalObj = Animal(animalPath,tankPath,varargin)
         % ANIMAL  Create an animal object that manages recordings from a
         %           single animal. These could be from the same session,
         %           or across multiple days.
         %
         %  animalObj = nigeLab.Animal();
         %     --> prompts using UI
         %  animalObj = nigeLab.Animal(animalPath);
         %     --> animalPath can be [] or char array of animal location
         %  animalObj = nigeLab.Animal(animalPath,tankPath);
         %     --> tankPath can be [] or char array of tank location
         %  animalObj = nigeLab.Animal(__,'PropName',propValue,...);
         %     --> set properties in the constructor
         
         animalObj.updateParams('Animal'); % old possibly
         animalObj.updateParams('all');
         animalObj.updateParams('init');
         animalObj.addPropListeners();
         
         % Parse input arguments
         if nargin < 1
            animalObj.RecDir = '';
         else
            if isempty(animalPath)
               animalObj.RecDir = '';
            elseif isnumeric(animalPath)
               % Create empty Animal array and return
               dims = animalPath;
               animalObj = repmat(animalObj,dims);
               for i = 1:dims(1)
                  for k = 1:dims(2)
                     % Make sure they aren't all pointers to the same thing
                     animalObj(i,k) = copy(animalObj(1,1));
                  end
               end
               return;
            elseif ischar(animalPath)
               animalObj.RecDir = animalPath;
            else
               error(['nigeLab:' mfilename ':badInputType1'],...
                  'Bad animalPath input type: %s',class(animalPath));
            end
         end
         
         % At this point it will be initialized "normally"
         animalObj.IsEmpty = false;
         if nargin < 2
            animalObj.TankLoc = '';
         else
            animalObj.TankLoc = nigeLab.utils.getUNCPath(tankPath);
         end
         
         % Can specify properties on construct
         for iV = 1:2:numel(varargin) 
            if ~ischar(varargin{iV})
               continue
            end
            p = findprop(animalObj,varargin{iV});
            if isempty(p)
               continue
            end
            animalObj.(varargin{iV}) = varargin{iV+1};
         end
         
         % Look for Animal directory
         if isempty(animalObj.RecDir)
            animalObj.RecDir = uigetdir(animalObj.Pars.DefaultRecLoc,...
               'Select directory with the recordings (Blocks)');
            if animalObj.RecDir == 0
               error(['nigeLab:' mfilename ':NoSelection'],...
                  'No ANIMAL input path selected. Object not created.');
            end
         else
            if exist(animalObj.RecDir,'dir')==0
               error(['nigeLab:' mfilename ':invalidPath'],...
                  '%s is not a valid ANIMAL directory.',animalObj.RecDir);
            end
         end
         
         animalObj.RecDir = nigeLab.utils.getUNCPath(animalObj.RecDir);
         animalObj.init;
         animalObj.initKey();
      end
      
      % Make sure listeners are deleted when animalObj is destroyed
      function delete(animalObj)
         % DELETE  Ensures listener handles are properly destroyed
         %
         %  delete(animalObj);
         
         if numel(animalObj) > 1
            for i = 1:numel(animalObj)
               delete(animalObj(i));
            end
            return;
         end
         
         % Destroy any associated "property listener" handles
         for i = 1:numel(animalObj.PropListener)
            if isvalid(animalObj.PropListener(i))
               delete(animalObj.PropListener(i));
            end
         end
         
         % Destroy any associated Listener handles
         if ~isempty(animalObj.Listener)
            for lh = animalObj.Listener
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
         
         % Destroy any associated Block Listener handles
         if ~isempty(animalObj.BlockListener)
            for lh = animalObj.BlockListener
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
         
         delete(animalObj.Blocks);
      end
      
      % Modify behavior of 'end' keyword in indexing expressions
      function ind = end(obj,k,~)
         % END  Change so if its the 2nd index argument, references BLOCKS
         
         if k == 2
            ind = obj.getNumBlocks;
         else
            ind = numel(obj);
         end
      end
      
      % Returns the key for this animal object
      function key = getKey(animalObj,keyType)
         %GETKEY  Return the key for this animal object
         %
         %  publicKey = animalObj.getKey();
         %  publicKey = animalObj.getKey('Public');
         %
         %  key --  .(keyType) field of blockObj.KeyPair
         %
         %  If animalObj is array, then key is returned as cell array
         %  of dimensions equivalent to animalObj.
         
         if nargin < 2
            keyType = 'Public';
         end
         if ~ismember(keyType,{'Public','Private'})
            error(['nigeLab:' mfilename ':BadKeyType'],...
               'keyType must be ''Public'' or ''Private''');
         end
         
         n = numel(animalObj);
         if n > 1
            key = cell(size(animalObj));
            for i = 1:n
               key{i} = animalObj(i).getKey();
            end
            return;            
         end
         key = animalObj.KeyPair.(keyType);
      end
      
      % Return a parameter (making sure Pars fields exist)
      function varargout = getParams(animalObj,parsField,varargin)
         %GETPARAMS  Return a parameter (making sure Pars fields exist)
         %
         %  val = animalObj.getParams('Sort','Debug');
         %  --> Returns value of animalObj.Pars.Sort.Debug
         %  --> If field doesn't exist, returns []
         %
         %  [val] = getParams(animalObjArray,'Sort','Debug');
         %  --> Returns array for entire animalObjArray
         
         if numel(animalObj) > 1
            varargout = cell(1,numel(animalObj));
            for i = 1:numel(animalObj)
               if numel(varargin)>0
                  varargout{i} = animalObj(i).getParams(parsField,varargin{:});
               else
                  varargout{i}=animalObj(i).getParams(parsField);
               end
            end
            return;
         end
         
         if ~isfield(animalObj.Pars,parsField)
            varargout = {[]};
            return;
         end
         s = animalObj.Pars.(parsField);
         
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
      
      
      % Returns Status for each Operation/Block pairing
      function flag = getStatus(animalObj,opField)
         % GETSTATUS  Returns Status Flag for each Operation/Block pairing
         %
         %  flag = animalObj.getStatus();
         %     --> Return true for any Fields element associated with a 
         %         "doOperation", when that "doOperation" has been
         %         completed for the corresponding element of
         %         animalObj.Blocks. 
         %        * if animalObj.Blocks is an array of 4 nigeLab.Block
         %          objects, and there are 9 "doOperation" Fields, then
         %          flag will return as a logical [4 x 9] matrix
         %
         %  flag = animalObj.getStatus(opField);
         %     --> Return status for specific "Operation" Fields (for each
         %         element of animalObj.Blocks)
         
         if nargin < 2
            opField = [];
         end
         if numel(animalObj) > 1
            flag = [];
            for i = 1:numel(animalObj)
               flag = [flag; getStatus(animalObj(i).Blocks,opField)]; %#ok<*AGROW>
            end
            return;
         end
         flag = getStatus(animalObj.Blocks,opField);
      end
      
      % Overload to 'isempty' 
      function tf = isempty(animalObj)
         % ISEMPTY  Returns true if .IsEmpty is true or if builtin isempty
         %          returns true. If animalObj is array, then returns an
         %          array of true or false for each element of animalObj.
         
         if numel(animalObj) == 0
            tf = true;
            return;
         end
         
         if ~isscalar(animalObj)
            tf = false(size(animalObj));
            for i = 1:numel(animalObj)
               tf(i) = isempty(animalObj(i));
            end
            return;
         end
         
         tf = animalObj.IsEmpty || builtin('isempty',animalObj);
      end         
         
      % Load .Pars from _Pars.mat or load a sub-field .Pars.(parsField)
      function flag = loadParams(animalObj,parsField)
         %LOADPARAMS   Load .Pars or .Pars.(parsField) from (user) file
         %
         %  animalObj.loadParams();  Load all of animalObj.Pars from file
         %  animalObj.loadParams(parsField); Load just that field of .Pars
         
         if numel(animalObj) > 1
            flag = true;
            for i = 1:numel(animalObj)
               if nargin < 2
                  flag = flag && animalObj(i).loadParams();
               else
                  flag = flag && animalObj(i).loadParams(parsField);
               end
            end
            return;
         else
            flag = false;
         end
         
         if nargin < 2
            if ~animalObj.HasParsFile
               if ~animalObj.checkParsFile()
                  warning('No _Pars file for %s (.User: %s)',...
                     animalObj.Name,animalObj.User);
                  return;
               end
            end
         else
            if ~animalObj.checkParsFile(parsField)
               warning('User (%s) not recognized in _Pars file for %s',...
                     animalObj.User,animalObj.Name);
               return;
            end
         end
         fname_params = animalObj.getParsFilename();
         in = load(fname_params);
         if isempty(animalObj.Pars)
            animalObj.Pars = struct;
         end
         if nargin < 2
            animalObj.Pars = in.(animalObj.User);
         else
            animalObj.Pars.(parsField) = in.(animalObj.User).(parsField);
         end
         flag = true;
      end
      
      % Save Animal object
      function save(animalObj)
         % SAVE  Allows saving of the ANIMAL object
         %
         %  animalObj.save(); Saves 'animalObj' in [AnimalName]_Animal.mat
         
         % Make sure array isn't saved to same file
         if numel(animalObj) > 1
            for i = 1:numel(animalObj)
               animalObj(i).save;
            end
            return;
         end
         
         % Save each BLOCK as well. Create a copy here, since
         % animalObj.Blocks is destroyed when the call to
         % save(..'animalObj'..) is made. If there are multiple animals,
         % this causes the copy to be "updated" and the "correct" copy is
         % then assigned to animalObj.Blocks after the save. 
         B = animalObj.Blocks; % Since animalObj.Blocks(:) = [] in saveobj
         pL = animalObj.PropListener;
         L = animalObj.Listener;
         bL = animalObj.BlockListener;
         for b = animalObj.Blocks
            b.save;
         end
         
         % Save animalObj
         animalObj.updateParams('Animal');
         animalFile = nigeLab.utils.getUNCPath(...
                     fullfile([animalObj.Paths.SaveLoc '_Animal.mat']));
         save(animalFile,'animalObj','-v7');
         
         % Reassign after save, so pointer is valid
         animalObj.Blocks = B; 
         animalObj.PropListener = pL;
         animalObj.Listener = L;
         animalObj.BlockListener = bL;
         
         animalObj.saveIDFile(); % .nigelAnimal file saver

      end
      
      % Overloaded function that is called when ANIMAL is being saved.
      function animalObj = saveobj(animalObj)
         % SAVEOBJ  Used when ANIMAL is being saved. Writes the returned
         %          value to the matfile. We do it this way so that
         %          animalObj does not save Block objects redundantly.
         
         animalObj.Blocks(:) = [];    
         animalObj.BlockListener(:) = [];
         animalObj.PropListener(:) = [];
         animalObj.Listener(:) = [];
      end
      
      % Method to save any parameters as a .mat file for a given User 
      function saveParams(animalObj,userName,parsField)
         %SAVEPARAMS  Method to save animalObj.Pars, given animalObj.User
         %
         %  animalObj.saveParams();  Uses .Pars and .User fields to save
         %  animalObj.saveParams('user'); Assigns current parameters to
         %     username 'user' and updates animalObj.User to 'user'.
         %  animalObj.saveParams('user','Sort'); Only saves 'Sort'
         %     parameters under the variable 'user' in the _Pars.mat file
         
         if isempty(animalObj)
            return;
         end
         
         if nargin < 2
            userName = animalObj.User;
         end
         
         if numel(animalObj) > 1
            for i = 1:numel(animalObj)
               if nargin < 3
                  animalObj(i).saveParams(userName);
               else
                  animalObj(i).saveParams(userName,parsField);
               end
            end
            return;
         end
         
         fname_params = animalObj.getParsFilename();

         if exist(fname_params,'file')==0 % If absent, make new file
            % Do this way to avoid 'eval' for weird names in workspace
            out = struct;
         else % otherwise, load old file and save as struct
            out = load(fname_params);
         end
         
         if nargin < 3
            out.(userName) = animalObj.Pars; 
         else
            out.(userName).(parsField)=animalObj.getParams(parsField);
         end
         save(fname_params,'-struct','out');
         animalObj.HasParsFile = true;
         
         if ~isempty(animalObj.Blocks)
            if nargin < 3
               saveParams(animalObj.Blocks,userName);
            else
               b = animalObj.Blocks(1);
               if ismember(parsField,fieldnames(b.Pars))
                  saveParams(animalObj.Blocks,userName,parsField);
               end
            end
         end
      end
      
      % Method to SET PARAMETERS (e.g. for updating saved parameters)
      function setParams(animalObj,parsField,varargin)
         % SETPARAMS  "Set" a parameter so that it is updated in diskfile
         %
         %  parsField : Char array; member of fieldnames(animalObj.Pars)
         %
         %  varargin : Intermediate fields; last element is always value.
         %
         %  value = animalObj.Pars.Sort;
         %  animalObj.setParams('Sort',value);
         %  --> First input is always name of .Pars field
         %     --> This call would just update animalObj.Pars.Sort to
         %         whatever is currently in animalObj.Pars.Sort (and
         %         overwrite that in the corresponding 'User' variable of
         %         the _Pars.mat file)
         %
         %  value = animalObj.Pars.Video.CameraKey.Index;
         %  animalObj.setParams('Video','CameraKey','Index',value);
         %  --> Updates specific field of CameraKey Video param (Index)
         
         if numel(varargin) > 5
            error(['nigeLab:' mfilename ':TooManyStructFields'],...
               ['Not currently configured for more than 4 fields deep.\n'...
                'Add to switch ... case']);
         end
         
         if numel(animalObj) > 1
            for i = 1:numel(animalObj)
               animalObj(i).setParams(parsField,varargin{:});
            end
            return;
         end
         
         val = varargin{end};
         f = varargin(1:(end-1));
         if ~isfield(animalObj.Pars,parsField)
            animalObj.updateParams(parsField);
         end
         s = animalObj.Pars.(parsField);
         
         % Do error check
         for i = 1:f
            if ~isfield(s,f{i})
               error(['nigeLab:' mfilename ':MissingField'],...
                  'Missing field (''%s'') of (animalObj.Pars.%s...)\n',...
                     f{i},parsField);
            end
         end
         
         % If good, then make dynamic struct expression. Don't expect more
         % than "4 fields deep" on a struct
         switch numel(f)
            case 0
               animalObj.Pars.(parsField) = val;
            case 1
               animalObj.Pars.(parsField).(f{1}) = val;
            case 2
               animalObj.Pars.(parsField).(f{1}).(f{2}) = val;
            case 3
               animalObj.Pars.(parsField).(f{1}).(f{2}).(f{3}) = val;
            case 4
               animalObj.Pars.(parsField).(f{1}).(f{2}).(f{3}).(f{4}) = val;
            otherwise
               error(['nigeLab:' mfilename ':TooManyStructFields'],...
                ['Not currently configured for more than 4 fields deep.\n'...
                 'Add to switch ... case']);
               
         end
         
         animalObj.saveParams(animalObj.User,parsField);
         if ~isempty(animalObj.Blocks)
            b = animalObj.Blocks(1);
            if isfield(b.Pars,parsField)
               setParams(animalObj.Blocks,parsField,varargin{:});
            end
         end
            
      end
      
      % Method to set username
      function setUser(animalObj,username)
         %SETUSER  Method to set user currently working on animal
         %
         %  animalObj.setUser();      Sets User to animalObj.Pars.User
         %                            (if it exists) or else random hash
         %  animalObj.setUser('MM');  Sets User property to 'MM'
         
         if numel(animalObj) > 1
            for i = 1:numel(animalObj)
               if nargin < 2
                  setUser(animalObj(i));
               else
                  setUser(animalObj(i),username);
               end
            end
            return;
         end
         
         if nargin < 2
            if isstruct(animalObj.Pars) && ~isempty(animalObj.Pars)
               if isfield(animalObj.Pars,'User')

                  username = animalObj.Pars.Video.User;
               else
                  username = nigeLab.utils.makeHash();
                  username = username{:}; % Should be char array
               end
            end
         end
         
         animalObj.User = username; % Assignment
         animalObj.checkParsFile();
         if ~isempty(animalObj.Blocks)
            setUser(animalObj.Blocks,username);
         end
      end
      
      % PROPERTY LISTENER CALLBACK: Username string validation
      function validateUserString(animalObj,eventName)
         %VALIDATEUSERSTRING  Check animalObj.User is set to valid chars
         %
         % addlistener(animalObj,'User','PostSet',...
         %     @(~,evt)animalObj.ValidateUserString(evt.EventName));
         % addlistener(animalObj,'User','PreGet',...
         %     @(~,evt)animalObj.ValidateUserString(evt.EventName));
         
         switch eventName
            case 'PostSet'
               animalObj.User = strrep(animalObj.User,' ','_');
               animalObj.User = strrep(animalObj.User,'-','_');
               animalObj.User = strrep(animalObj.User,'.','_');
               if regexp(animalObj.User(1),'\d')
                  error(['nigeLab:' mfilename ':InvalidUsername'],...
                     'animalObj.User must start with alphabetical element.');
               end
               
            case 'PreGet'
               if isempty(animalObj.User)
                  setUser(animalObj);
               end
            otherwise
               % does nothing
         end
      end
   end
   
   % PUBLIC 
   % Methods that should go in Contents.m eventually
   methods (Access = public)
      setProp(animalObj,varargin); % Set property for all Animals in array
      [animalObj,idx] = findByKey(animalObjArray,keyStr,keyType); % Find animal from animal array based on public or private hash
      
      table = list(animalObj,keyIdx)        % List of recordings currently associated with the animal
      out = animalGet(animalObj,prop)       % Get a specific BLOCK property
      flag = animalSet(animalObj,prop)      % Set a specific BLOCK property
      
      parseProbes(animalObj) % Parse probes from child BLOCKS
      addChildBlock(animalObj,blockPath,idx) % Add child BLOCK
      mergeBlocks(animalObj,ind,varargin) % Concatenate two Blocks together
      removeBlocks(animalObj,ind)         % Disassociate a Block from Animal
      
      flag = doUnitFilter(animalObj)      % Apply Unit Bandpass filter to all raw data in Blocks of Animal
      flag = doReReference(animalObj)     % Re-reference all filtered data in Blocks of Animal
      flag = doRawExtraction(animalObj)   % Extract Raw Data for all Blocks in Animal
      flag = doLFPExtraction(animalObj)   % Extract LFP for all Blocks in Animal
      flag = doSD(animalObj)              % Extract spikes for all Blocks in Animal
      
      flag = updateParams(animalObj,paramType) % Update parameters of Animal and Blocks
      flag = updatePaths(animalObj,SaveLoc)     % Update folder tree of all Blocks
      flag = checkParallelCompatibility(animalObj) % Check if parallel can be run
      flag = linkToData(animalObj)                    % Link disk data of all Blocks in Animal
      flag = splitMultiAnimals(animalObj,varargin) % Split recordings that have multiple animals to separate recs
   end
   
   % PUBLIC
   % "Hidden" methods that shouldn't typically be used
   methods (Access = public, Hidden = true, Static = false)
      clearSpace(animalObj,ask,usrchoice) % Remove files from disk
      updateNotes(animalObj,str) % Update notes for a recording
      
      flag = genPaths(animalObj,tankPath) % Generate paths property struct
      flag = findCorrectPath(animalObj,paths)   % Find correct Animal path
      flag = getSaveLocation(animalObj,saveLoc) % Prompt to set save dir
      flag = doAutoClustering(animalObj,chan,unit) % Runs spike autocluster
      
      N = getNumBlocks(animalObj); % Gets total number of blocks 
   end
   
   % PUBLIC
   % "Hidden" for event listener purposes
   methods (Access = public, Hidden = true)
      % Callback for when a "child" Block is moved or otherwise destroyed
      function AssignNULL(animalObj)
         % ASSIGNNULL  Does null assignment to remove a block of a
         %             corresponding index from the animalObj.Blocks
         %             property array, for example, if that Block is
         %             destroyed or moved to a different animalObj. Useful
         %             as a callback for an event listener handle.
         
         idx = ~isvalid(animalObj.Blocks);
         if sum(idx) >= 1
            animalObj.Blocks(idx) = [];
            if numel(idx) == numel(animalObj.BlockListener)
               if isvalid(animalObj.BlockListener(idx))
                  delete(animalObj.BlockListener(idx));
               end
            end
            animalObj.BlockListener(idx) = [];
         end
      end
      
   end
    
   % PRIVATE 
   % To be catalogued in 'Contents.m'
   methods (Access = private, Hidden = false)
      init(animalObj)         % Initializes the ANIMAL object
   end
   
   % PRIVATE
   % Used during Initialization or internally
   methods (Access = private)
      % Adds listener handles to array property of animalObj
      function addPropListeners(animalObj)
         % ADDPROPLISTENERS  Called on initialization to build PropListener
         %                    property array.
         %
         %  animalObj.addPropListeners();
         %
         %  --> Creates 2-element vector of property listeners
         
         if isempty(animalObj)
            return;
         end
         
         animalObj.PropListener = ...
            [addlistener(animalObj,'Name','PostSet',...
               @(~,~)animalObj.updateAnimalNameInChildBlocks()),...
             addlistener(animalObj,'Blocks','PostSet',...
               @(~,~)animalObj.CheckBlocksForClones()),...
             addlistener(animalObj,'BlockMask','PostSet',...
               @(~,~)animalObj.parseProbes()),...
             addlistener(animalObj,'User','PostSet',...
               @(~,evt)animalObj.validateUserString(evt.EventName)),...
             addlistener(animalObj,'User','PreGet',...
               @(~,evt)animalObj.validateUserString(evt.EventName))];
            
      end
      
      % Check parameters file to set `HasParsFile` flag for this `User`
      function flag = checkParsFile(animalObj,parsField)
         %CHECKPARSFILE  Sets .HasParsFile for current .User
         %
         %  animalObj.checkParsFile();
         %  flag = animalObj.checkParsFile(parsField); Returns flag
         %     indicating whether 'parsField' is a field of .('user')
         
         params_fname = animalObj.getParsFilename();
         if exist(params_fname,'file')==0
            animalObj.HasParsFile = false;
            return;
         end
         
         userName = animalObj.User;
         try
            m = matfile(params_fname);
         catch
            warning('%s may be corrupt',params_fname);
            animalObj.HasParsFile = false;
            return;
         end
         allUsers = who(m);
         animalObj.HasParsFile = ismember(userName,allUsers);
         if nargin > 1
            if animalObj.HasParsFile
               flag = isfield(m.(userName),parsField);
            else
               flag = false;
            end
         else
            flag = animalObj.HasParsFile;
         end
      end
      
      % Return full filename to parameters file
      function f = getParsFilename(animalObj,useUNC)
         %GETPARSFILENAME  Returns full (UNC) filename to parameters file
         %
         %  f = animalObj.getParsFilename(); Return UNC path (def)
         %  f = animalObj.getParsFilename(false); Return `fullfile` version
         
         if nargin < 2
            useUNC = true;
         end
         
         if useUNC
            f = nigeLab.utils.getUNCPath(animalObj.Paths.SaveLoc,...
                   sprintf(animalObj.ParamsExpr,animalObj.Name));
         else
            f = fullfile(animalObj.Paths.SaveLoc,...
               sprintf(animalObj.ParamsExpr,animalObj.Name));
         end
      end
      
      % Initialize .KeyPair property
      function flag = initKey(animalObj)
         %INITKEY  Initialize animalObj.KeyPair for use with unique ID later
         %
         %  keyPair = animalObj.initKey();
         
         % Ensure it works if input is array object
         n = numel(animalObj);
         flag = true;
         try
            if n > 1
               keyPair = struct('Public',cell(1,n),'Private',cell(1,n));
               for i = 1:n
                  keyPair(i) = animalObj(i).initKey();
               end
               return;
            end

            hashPair = nigeLab.utils.makeHash(animalObj,2);
            keyPair = struct('Public',hashPair(1),...
                             'Private',hashPair(2));
            animalObj.KeyPair = keyPair;
         catch er
             flag = false;
             rethrow(er);
         end
      end
      
      % Load/parse ID file and associated parameters
      function loadIDFile(animalObj)
         %LOADIDFILE Load and parse .nigelAnimal file into .IDInfo property
         %
         %  animalObj.loadIDFile();
         
         if isempty(animalObj)
            return;
         end
         
         if isempty(animalObj.IDFile)
            animalObj.IDFile = nigeLab.utils.getUNCPath(...
               animalObj.Paths.SaveLoc,animalObj.FolderIdentifier);
         end
         
         fid = fopen(animalObj.IDFile,'r+');
         if fid < 0
            % "ID" file doesn't exist; make it using current properties
            animalObj.saveIDFile();
            return;
         end
         C = textscan(fid,'%q %q','Delimiter','|');
         fclose(fid);
         propName = C{1};
         propVal = C{2};
         if ~strcmpi(propName{1},'ANIMAL')
            error(['nigeLab:' mfilename ':BadFolderHierarchy'],...
               'Attempt to load non-Animal from Animal folder.');
         end
         
         mc = metaclass(animalObj);
         mcp = {mc.PropertyList.Name};
         animalObj.IDInfo = struct;
         animalObj.IDInfo.ANIMAL = propVal{1};
         for i = 2:numel(propName)
            if ~contains(propName{i},'.')
               animalObj.IDInfo.(propName{i}) = propVal{i};
            end
            if isempty(propVal{i})
               warning('%s .nigelAnimal value missing.\n',propName{i});
               continue;
            end
            setProp(animalObj,propName{i},propVal{i});
         end
         
         if isempty(animalObj.User)
            animalObj.saveIDFile(); % Make sure correct file is saved
         end
         
      end
      
      % Save small folder identifier file
      function saveIDFile(animalObj)
         %SAVEIDFILE  Save small folder identifier file
         %
         %  animalObj.saveIDFile();
         
         % Save ".nigelAnimal" file for convenience of identifying this
         % folder as an "ANIMAL" folder in the future
         if isempty(animalObj.IDFile)
            animalObj.IDFile = nigeLab.utils.getUNCPath(...
                 animalObj.Paths.SaveLoc,animalObj.Pars.FolderIdentifier);
         end
         
         fid = fopen(animalObj.IDFile,'w');
         if fid > 0
            fprintf(fid,'ANIMAL|%s\n',animalObj.Name);
            fprintf(fid,'KeyPair.Public|%s\n',animalObj.KeyPair.Public);
            fprintf(fid,'User|%s', animalObj.User);
            fclose(fid);
         else
            warning('Could not write .nigelAnimal (%s)',animalObj.IDFile);
         end
      end
   end
   
   % PRIVATE
   % Listener callbacks
   methods (Access = private, Hidden = true) 
      % Ensure that there are not redundant Blocks in animalObj.Blocks
      % based on the .Name property of each member Block object
      function CheckBlocksForClones(animalObj)
         % CHECKBLOCKSFORCLONES  Creates an nBlock x nBlock logical matrix
         %                       comparing each Block in animalObj.Blocks
         %                       to the Name of every other such Block.
         %                       After subtracting the main diagonal of
         %                       this matrix, any row with redundant
         
         % If no Blocks (or only 1 "non-empty" block) then there are no
         % clones in the array.
         b = animalObj.Blocks;
         if sum(isempty(b)) <= 1
            return;
         else
            idx = find(~isempty(b));
            b = b(idx);
         end
         
         cname = {b.Name};
         
         % look for animals with the same name
         comparisons_cell = cellfun(... % check each element name against 
            @(s) strcmp(s,cname),... 
            cname,... % all other elements
            'UniformOutput',false);     % return result in cells
         
         % Use upper triangle portion only, so that at least 1 member is
         % kept from any matched pair
         comparisons_mat = logical(triu(cat(1,comparisons_cell{:}) - ...
                                   eye(numel(cname))));
         rmvec = any(comparisons_mat,1);
         animalObj.Blocks(idx(rmvec))=[];

      end
      
      % Callback for when the Animal name is changed, to update all "child"
      % block objects.
      function updateAnimalNameInChildBlocks(animalObj)
         % UPDATEANIMALNAMEINCHILDBLOCKS  Updates the animal Name in any
         %                                Children, whenever that property
         %                                is modified. This way, Children
         %                                have the same property as the
         %                                parent.
         %
         %  event.listener.Callback = ...
         %     @animalObj.updateAnimalNameInChildBlocks
         
          for bb=1:numel(animalObj.Blocks)
             animalObj.Blocks(bb).Meta.AnimalID = animalObj.Name;
          end
      end
      
      % LISTENER CALLBACK: Updates .BlockMask
      function updateBlockMask(animalObj,blockObj)
         %UPDATEBLOCKMASK  Updates .BlockMask based on blockObj.IsMasked
         %
         %  addlistener(blockObj,'IsMasked','PostSet',...
         %     @animalObj.updateBlockMask);
         
         [~,idx] = findByKey(animalObj.Blocks,blockObj);
         if animalObj.BlockMask(idx)~=blockObj.IsMasked
            animalObj.BlockMask(idx) = blockObj.IsMasked;
         end
      end
   end
   
   % STATIC
   methods (Static)
      % Static method to construct empty Animal object
      function animalObj = Empty(n)
         % EMPTY  Creates "empty" Animal or Animal array
         %
         %  nigeLab.Animal.Empty();  % Makes a scalar
         %  nigeLab.Animal.Empty(n); % Make n-element array of Animal
         
         if nargin < 1
            n = [0, 0];
         else
            n = nanmax(n,0);
            if isscalar(n)
               n = [0, n];
            end
         end
         
         animalObj = nigeLab.Animal(n);
      end
      
      % Method invoked any time animalObj is loaded
      function b = loadobj(a)
         % LOADOBJ  Method to load ANIMAL objects
         %
         %  b = loadObj(a);
         %
         %  Just makes sure that a is correct, and returns it on loading as
         %  b to avoid infinite recursion.

         if isempty(a.KeyPair)
            a.initKey();
         end
         
         a.addPropListeners();
         a.loadIDFile();
         
         if ~isfield(a.Paths,'SaveLoc')
            a.parseProbes();
            b = a;
            return;
         end
         a.PropListener(2).Enabled = false; % .Blocks listener
         a.PropListener(3).Enabled = false; % .BlockMask listener
         
         BL = dir(fullfile(a.Paths.SaveLoc,'*_Block.mat'));
         if isempty(a.Blocks)
            % Blocks should not be saved with object, they are removed
            % during save method and then re-added.
            a.Blocks = nigeLab.Block.Empty([1,numel(BL)]);
            for ii=1:numel(BL)
               try
                  in = load(fullfile(BL(ii).folder,BL(ii).name));
                  a.addChildBlock(in.blockObj,ii);
               catch
                  warning('Failed to load %s',BL(ii).name);
               end
            end
         else
            % Nothing specific, a.Blocks isempty is typical (expected) case
            warning('Animal (%s) was loaded with non-empty Blocks',a.Name);
         end
         a.PropListener(2).Enabled = true;
         a.PropListener(3).Enabled = true;
         b = a;
      end

   end 
   
end