classdef Tank < handle
% TANK  Construct Tank Class object
%
%  tankObj = nigeLab.Tank();
%     --> prompts for locations using UI
%
%  tankObj = nigeLab.Tank(tankRecPath);
%     --> tankRecPath can be [] or char array with full path to
%         original TANK FOLDER (e.g. the folder that has ANIMAL
%         folders in it; either for recordings, or the saved
%         location of a previously-extracted nigeLab.Tank).
%
%  tankObj = nigeLab.Tank(tankRecPath,tankSavePath);
%     --> tankSavePath can be [] or char array with location where
%         TANK FOLDER will be saved (folder that contains the
%         output nigeLab TANK)
%
%  tankObj = nigeLab.Tank(__,'PropName',propValue,...);
%     --> specify property name, value pairs on construction
%
%  ex: 
%  tankObj = nigeLab.Tank('R:\My\Tank','P:\My\Tank');
%  --> RecDir is in a different location than SaveLoc (for
%      example, if data was just collected but not extracted)
%
%  tankObj = nigeLab.Tank('P:\My\Tank','P:\My');
%  --> RecDir == SaveLoc (for example, if data was previously
%      extracted, but saved Tank wasn't kept or something. Note
%      that SaveLoc is the "parent" folder of RecDir in this case)
%         
%  TANK Properties:
%     Name - Name of experimental TANK.
%     
%     Animals - Array of handles to "Children" nigeLab.Animals objects
%
%     Paths - Struct with detailed path specifications of saved files
%
%     RecDir - Path to the TANK (file hierarchy; char array)
%
%     SaveLoc - Top-level folder of the TANK (file hierarchy; char array)
%
%     Pars - Parameters struct
%
%     BlockNameVars - Metadata varaibles parsed from BLOCK names
%
%  TANK Methods:
%     Tank - TANK Class object constructor.
%
%     list - List Block objects in the TANK.
%
%     Empty - Create an Empty TANK object or array

   %% PROPERTIES
   % Public get & set, SetObservable as well
   properties (GetAccess=public, SetAccess=public, SetObservable=true)
      Name        char               % Name of experiment (TANK)
      Animals     nigeLab.Animal     % Handle array to Children
      AnimalMask  logical            % Logical array for masking child animals
   end

   % Has to be set by method of Tank, but can be accessed publically
   properties (SetAccess=private, GetAccess=public)
      Fields         cell      % Specific things to record
      FieldType      cell      % "Types" corresponding to Fields elements
      HasParsFile    logical=false  % Flag --> True if _Pars.mat exists
      IDFile         char      % .nigelTank file name
      IDInfo         struct    % Struct parsed from .nigelTank ID file
      Paths          struct    % Detailed paths specifications for all the saved files
      ParamsExpr     char = '%s_Pars.mat'  % Expression for parameters file
      UseParallel    logical   % Flag indicating if parallel processing can be done on this machine
   end
   
   % Get/Set observable User property
   properties (SetAccess=private,GetAccess=public,SetObservable,GetObservable)
      User           char      % Name of current user of nigeLab
   end
   
   % Various parameters that may be useful to access publically but cannot
   % be set externally and don't populate the normal list of properties
   properties (GetAccess=public, SetAccess=private, Hidden=true) %debugging purposes, is private
      Pars                    struct   % Parameters struct
      RecDir                  char     % Directory of the TANK
      SaveLoc                 char     % Top folder
   end
   
   % Private - Listeners & Flags
   properties (SetAccess=public, GetAccess=private, Hidden=true)
      % Listeners
      AnimalListener  event.listener  % Array of handles that listen for ANIMAL event changes
      PropListener    event.listener  % Array of handles that listen for key event changes
      
      % Flags
      IsEmpty = true  % Is this an empty tank
   end
   
   events (ListenAccess=public, NotifyAccess=public)
      StatusChanged  % Issued any time a "child" ANIMAL responds to BLOCK status change
   end

  
   %% METHODS
   % PUBLIC
   % Class constructor and overloaded methods
   methods (Access = public)
      % Class constructor
      function tankObj = Tank(tankRecPath,tankSavePath,varargin)
         % TANK  Construct Tank Class object
         %
         %  tankObj = nigeLab.Tank();
         %     --> prompts for locations using UI
         %
         %  tankObj = nigeLab.Tank(tankRecPath);
         %     --> tankRecPath can be [] or char array with full path to
         %         original TANK FOLDER (e.g. the folder that has ANIMAL
         %         folders in it; either for recordings, or the saved
         %         location of a previously-extracted nigeLab.Tank).
         %
         %  tankObj = nigeLab.Tank(tankRecPath,tankSavePath);
         %     --> tankSavePath can be [] or char array with location where
         %         TANK FOLDER will be saved (folder that contains the
         %         output nigeLab TANK)
         %
         %  tankObj = nigeLab.Tank(__,'PropName',propValue,...);
         %     --> specify property name, value pairs on construction
         %
         %  ex: 
         %  tankObj = nigeLab.Tank('R:\My\Tank','P:\My\Tank');
         %  --> RecDir is in a different location than SaveLoc (for
         %      example, if data was just collected but not extracted)
         %
         %  tankObj = nigeLab.Tank('P:\My\Tank','P:\My');
         %  --> RecDir == SaveLoc (for example, if data was previously
         %      extracted, but saved Tank wasn't kept or something. Note
         %      that SaveLoc is the "parent" folder of RecDir in this case)
         
         if nargin < 1
            tankObj.RecDir = [];
         else
            if isempty(tankRecPath) || ischar(tankRecPath)
               tankObj.RecDir = tankRecPath;
            elseif isnumeric(tankRecPath)
               dims = tankRecPath;
               tankObj = repmat(tankObj,dims);
               for i = 1:dims(1)
                  for k = 1:dims(2)
                     % Ensure not just all the same handle
                     tankObj(i,k) = copy(tankObj(1,1));
                  end
               end
               return;
            else
               error(['nigeLab:' mfilename ':badInputType1'],...
                  'Bad tankRecPath input type: %s',class(tankRecPath));
            end
         end
         
         % At this point it will be initialized "normally"
         tankObj.IsEmpty = false;
         if nargin < 2
            tankObj.SaveLoc = [];
         else
            tankObj.SaveLoc = nigeLab.utils.getUNCPath(tankSavePath);
         end
         
         % Load default settings
         tankObj.updateParams('Tank'); % old maybe
         tankObj.updateParams('all');
         tankObj.updateParams('init');
         tankObj.addPropListeners();
         
         % Can specify properties on construct
         for iV = 1:2:numel(varargin) 
            if ~ischar(varargin{iV})
               continue
            end
            p = findprop(tankObj,varargin{iV});
            if isempty(p)
               continue
            end
            tankObj.(varargin{iV}) = varargin{iV+1};
         end
         
         % Look for TANK directory
         if isempty(tankObj.RecDir)
            tankObj.RecDir = uigetdir(tankObj.Pars.DefaultTankLoc,...
                                   'Select TANK folder');
            if tankObj.RecDir == 0
               error(['nigeLab:' mfilename ':selectionCanceled'],...
                  'No TANK input path selected. Object not created.');
            end
         else
            if exist(tankObj.RecDir,'dir')==0
               error(['nigeLab:' mfilename ':invalidPath'],...
                  '%s is not a valid TANK directory.',tankObj.RecDir);
            end
         end
         tankObj.RecDir = nigeLab.utils.getUNCPath(tankObj.RecDir);
         if ~tankObj.init
            error(['nigeLab:' mfilename ':initFailed'],...
               'Could not initialize TANK object.');
         end
         
      end
      
      % Make sure listeners are deleted when tankObj is destroyed
      function delete(tankObj)
         % DELETE  Ensures listener handles are properly destroyed
         %
         %  delete(tankObj);
         
         if numel(tankObj) > 1
            for i = 1:numel(tankObj)
               delete(tankObj(i));
            end
            return;
         end
         
         % Delete "property listener" object array
         if ~isempty(tankObj.PropListener)
            for lh = tankObj.PropListener
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
         
         % Delete "animal listener" object array
         if ~isempty(tankObj.AnimalListener)
            for lh = tankObj.AnimalListener
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
         
         delete(tankObj.Animals);
      end
      
      % Overload to 'end' indexing operator
      function ind = end(tankObj,k,~)
         % END  Operator to index end of tankObj.Animals or
         %      tankObj.Animals.Blocks
         
         switch k
            case 1
               ind = numel(tankObj.Animals);
            case 2
               ind = getNumBlocks(tankObj.Animals);
            otherwise
               error(['nigeLab:' mfilename ':badReference'],...
                  'Invalid subscript: end cannot be index %g',k);
         end
      end
      
      % Return a parameter (making sure Pars fields exist)
      function s = getParams(tankObj,parsField,varargin)
         %GETPARAMS  Return a parameter (making sure Pars fields exist)
         %
         %  s = tankObj.getParams('Sort','Debug');
         %  --> Returns value of tankObj.Pars.Sort.Debug
         %  --> If field doesn't exist, returns []
         
         if ~isscalar(tankObj)
            error(['nigeLab:' mfilename ':InvalidArrayInput'],...
               'nigeLab.Tank/getParams expects a scalar Tank');
         end
         
         if ~isfield(tankObj.Pars,parsField)
            varargout = {[]};
            return;
         end
         s = tankObj.Pars.(parsField);
         
         for i = 1:numel(varargin)
            if ~isfield(s,varargin{i})
               s = [];
               break;
            else
               s = s.(varargin{i});
            end            
         end
      end
      
      % Returns the status of a operation/animal for each unique pairing
      function Status = getStatus(tankObj,operation)
         % GETSTATUS  Return the status for each Animal for a given
         %            operation. If anything is missing for that
         %            Animal/Operation pairing, then the corresponding
         %            status element (for that animal) is returned as
         %            false.
         %
         %  Status = tankObj.getStatus();
         %  --> Return list of status that have been completed for each
         %      ANIMAL
         %
         %  Status = tankObj.getStatus([]);
         %  --> Return matrix of logical values for ALL fields
         %
         %  Status = tankObj.getStatus(operation); Returns specific
         %                                         operation status
         
         if nargin <2
            tmp = tankObj.list;
            Status = tmp.Status;
         elseif isempty(operation)
            operation = tankObj.Pars.Block.Fields;
            Status = getStatus(tankObj,operation);
            return;
         else
            % Ensure operation is a cell
            if ~iscell(operation)
               operation={operation};
            end
            % Check status from each animal
            Status = false(numel(tankObj.Animals),numel(operation));
            for aa =1:numel(tankObj.Animals)
               tmp =  tankObj.Animals(aa).getStatus(operation);
               if numel(operation)==1
                  tmp=all(tmp,2); 
               end
               Status(aa,:) = all(tmp,1);
            end
         end
      end
      
      % Overload to 'isempty' 
      function tf = isempty(tankObj)
         % ISEMPTY  Returns true if .IsEmpty is true or if builtin isempty
         %          returns true. If tankObj is array, then returns an
         %          array of true or false for each element of tankObj.
         
         if numel(tankObj) == 0
            tf = true;
            return;
         end
         
         if ~isscalar(tankObj)
            tf = false(size(tankObj));
            for i = 1:numel(tankObj)
               tf(i) = isempty(tankObj(i));
            end
            return;
         end
         
         tf = tankObj.IsEmpty || builtin('isempty',tankObj);
      end
      
      % Load .Pars from _Pars.mat or load a sub-field .Pars.(parsField)
      function flag = loadParams(tankObj,parsField)
         %LOADPARAMS   Load .Pars or .Pars.(parsField) from (user) file
         %
         %  tankObj.loadParams();  Load all of tankObj.Pars from file
         %  tankObj.loadParams(parsField); Load just that field of .Pars
         
         flag = false;
         if ~isscalar(tankObj)
            error(['nigeLab:' mfilename ':InvalidArrayInput'],...
               'nigeLab.Tank/loadParams expects scalar Tank input');
         end
         
         if nargin < 2
            if ~tankObj.HasParsFile
               if ~tankObj.checkParsFile()
                  warning('No _Pars file for %s (.User: %s)',...
                     tankObj.Name,tankObj.User);
                  return;
               end
            end
         else
            if ~tankObj.checkParsFile(parsField)
               warning('User (%s) not recognized in _Pars file for %s',...
                     tankObj.User,tankObj.Name);
               return;
            end
         end
         fname_params = tankObj.getParsFilename();
         in = load(fname_params);
         if isempty(tankObj.Pars)
            tankObj.Pars = struct;
         end
         if nargin < 2
            tankObj.Pars = in.(tankObj.User);
         else
            tankObj.Pars.(parsField) = in.(tankObj.User).(parsField);
         end
         flag = true;
      end
      
      % Method used for saving TANK object
      function save(tankObj)
         % SAVE  Method to save a nigeLab.Tank class object
         % 
         %  tankObj.save;  Saves 'tankObj' in [TankName]_Tank.mat
         
         % Make sure multiple tanks not saved to same file
         if numel(tankObj) > 1
            for i = 1:numel(tankObj)
               tankObj(i).save;
            end
            return;
         end

         % Save all Animals associated with tank
         A = tankObj.Animals; % Since tankObj.Animals(:) = []; in saveobj
         pL = tankObj.PropListener;
         aL = tankObj.AnimalListener;
         for a = tankObj.Animals
            a.save;
         end
         
         % Save tankObj
         tankObj.updateParams('Tank');
         tankFile = nigeLab.utils.getUNCPath(...
                     fullfile([tankObj.Paths.SaveLoc '_Tank.mat']));
         save(tankFile,'tankObj','-v7');
         % so pointers are still good after saving: 
         tankObj.Animals = A;         
         tankObj.PropListener = pL;
         tankObj.AnimalListener = aL;
         
         tankObj.saveIDFile(); % .nigelTank folder ID saver         
      end
      
      % Overloaded method that is called when TANK is saved
      function tankObj = saveobj(tankObj)
         % SAVEOBJ  Method that is called when TANK is saved. Writes the 
         %          returned value to the matfile. We do it this way so
         %          that tankObj.Animals does not save Animal objects
         %          redundantly.
         
         tankObj.Animals(:) = [];       
         tankObj.PropListener(:) = [];
         tankObj.AnimalListener(:) = [];
      end
      
      % Method to save any parameters as a .mat file for a given User 
      function saveParams(tankObj,userName,parsField)
         %SAVEPARAMS  Method to save tankObj.Pars, given tankObj.User
         %
         %  tankObj.saveParams();  Uses .Pars and .User fields to save
         %  tankObj.saveParams('user'); Assigns current parameters to
         %     username 'user' and updates tankObj.User to 'user'.
         %  tankObj.saveParams('user','Sort'); Only saves 'Sort'
         %     parameters under the variable 'user' in the _Pars.mat file
         
         if nargin < 2
            userName = tankObj.User;
         end
         
         % tankObj should be scalar (no iteration on tankObj array)
         if ~isscalar(tankObj)
            error(['nigeLab:' mfilename ':InvalidArrayInput'],...
               'nigeLab.Tank/saveParams expects scalar input');
         end
         
         fname_params = tankObj.getParsFilename();

         if exist(fname_params,'file')==0 % If absent, make new file
            % Do this way to avoid 'eval' for weird names in workspace
            out = struct;
         else % otherwise, load old file and save as struct
            out = load(fname_params);
         end
         
         if nargin < 3
            out.(userName) = tankObj.Pars; 
         else
            out.(userName).(parsField)=tankObj.getParams(parsField);
         end
         save(fname_params,'-struct','out');
         tankObj.HasParsFile = true;
         
         if ~isempty(tankObj.Animals)
            if nargin < 3
               saveParams(tankObj.Animals,userName);
            else
               a = tankObj.Animals(1);
               if ismember(parsField,fieldnames(a.Pars))
                  saveParams(tankObj.Animals,userName,parsField);
               end               
            end
         end
      end
      
      % Method to SET PARAMETERS (e.g. for updating saved parameters)
      function setParams(tankObj,parsField,varargin)
         % SETPARAMS  "Set" a parameter so that it is updated in diskfile
         %
         %  parsField : Char array; member of fieldnames(tankObj.Pars)
         %
         %  varargin : Intermediate fields; last element is always value.
         %
         %  value = tankObj.Pars.Sort;
         %  tankObj.setParams('Sort',value);
         %  --> First input is always name of .Pars field
         %     --> This call would just update tankObj.Pars.Sort to
         %         whatever is currently in tankObj.Pars.Sort (and
         %         overwrite that in the corresponding 'User' variable of
         %         the _Pars.mat file)
         %
         %  value = tankObj.Pars.Video.CameraKey.Index;
         %  tankObj.setParams('Video','CameraKey','Index',value);
         %  --> Updates specific field of CameraKey Video param (Index)
         
         if numel(varargin) > 5
            error(['nigeLab:' mfilename ':TooManyStructFields'],...
               ['Not currently configured for more than 4 fields deep.\n'...
                'Add to switch ... case']);
         end
         
         if ~isscalar(tankObj)
            error(['nigeLab:' mfilename ':InvalidArrayInput'],...
               'nigeLab.Tank/setParams expects scalar Tank input');
         end
         
         val = varargin{end};
         f = varargin(1:(end-1));
         if ~isfield(tankObj.Pars,parsField)
            tankObj.updateParams(parsField);
         end
         s = tankObj.Pars.(parsField);
         
         % Do error check
         for i = 1:f
            if ~isfield(s,f{i})
               error(['nigeLab:' mfilename ':MissingField'],...
                  'Missing field (''%s'') of (tankObj.Pars.%s...)\n',...
                     f{i},parsField);
            end
         end
         
         % If good, then make dynamic struct expression. Don't expect more
         % than "4 fields deep" on a struct
         switch numel(f)
            case 0
               tankObj.Pars.(parsField) = val;
            case 1
               tankObj.Pars.(parsField).(f{1}) = val;
            case 2
               tankObj.Pars.(parsField).(f{1}).(f{2}) = val;
            case 3
               tankObj.Pars.(parsField).(f{1}).(f{2}).(f{3}) = val;
            case 4
               tankObj.Pars.(parsField).(f{1}).(f{2}).(f{3}).(f{4}) = val;
            otherwise
               error(['nigeLab:' mfilename ':TooManyStructFields'],...
                ['Not currently configured for more than 4 fields deep.\n'...
                 'Add to switch ... case']);
               
         end
         
         tankObj.saveParams(tankObj.User,parsField);
         if ~isempty(tankObj.Animals)
            a = tankObj.Animals(1);
            if isfield(a.Pars,parsField)
               setParams(tankObj.Animals,parsField,varargin{:});
            end
         end
            
      end
      
      % Method to set username
      function setUser(tankObj,username)
         %SETUSER  Method to set user currently working on tank
         %
         %  tankObj.setUser();      Sets User to tankObj.Pars.User
         %                            (if it exists) or else random hash
         %  tankObj.setUser('MM');  Sets User property to 'MM'
         
         if ~isscalar(tankObj)
            error(['nigeLab:' mfilename ':InvalidArrayInput'],...
               'nigeLab.Tank/setUser expects scalar Tank input');
         end
         
         if nargin < 2
            if isstruct(tankObj.Pars) && ~isempty(tankObj.Pars)
               if isfield(tankObj.Pars,'User')
                  username = tankObj.Pars.User;
               else
                  username = nigeLab.utils.makeHash();
                  username = username{:}; % Should be char array
               end
            end
         end
         
         tankObj.User = username; % Assignment
         tankObj.checkParsFile();
         if ~isempty(tankObj.Animals)
            setUser(tankObj.Animals,username);
         end
      end
      
      % PROPERTY LISTENER CALLBACK: Username string validation
      function validateUserString(tankObj,eventName)
         %VALIDATEUSERSTRING  Check tankObj.User is set to valid chars
         %
         % addlistener(tankObj,'User','PostSet',...
         %     @(~,evt)tankObj.ValidateUserString(evt.EventName));
         % addlistener(tankObj,'User','PreGet',...
         %     @(~,evt)tankObj.ValidateUserString(evt.EventName));
         
         switch eventName
            case 'PostSet'
               tankObj.User = strrep(tankObj.User,' ','_');
               tankObj.User = strrep(tankObj.User,'-','_');
               tankObj.User = strrep(tankObj.User,'.','_');
               if regexp(tankObj.User(1),'\d')
                  error(['nigeLab:' mfilename ':InvalidUsername'],...
                     'tankObj.User must start with alphabetical element.');
               end
               
            case 'PreGet'
               if isempty(tankObj.User)
                  tankObj.setUser();
               end
            otherwise
               % does nothing
         end
      end
      
   end   
   
   % PUBLIC
   % Methods (to be catalogued using contents.m)
   methods (Access = public)
      setProp(tankObj,varargin) % Set property for Tank
      addAnimal(tankObj,animalPath,idx) % Add child Animals to Tank
      
      flag = checkParallelCompatibility(tankObj); 
      
      flag = doRawExtraction(tankObj)  % Extract raw data from all Animals/Blocks
      flag = doReReference(tankObj)    % Do CAR on all Animals/Blocks
      flag = doLFPExtraction(tankObj)  % Do LFP extraction on all Animals/Blocks
      flag = doSD(tankObj)             % Do spike detection on all Animals/Blocks
      
      flag = linkToData(tankObj)           % Link TANK to data files on DISK
      blockList = list(tankObj)     % List Blocks in TANK    
      flag = updatePaths(tankObj,SaveLoc)    % Update PATHS to files
      flag = updateParams(tankObj,paramType) % Update TANK parameters
      N = getNumBlocks(tankObj) % Get total number of blocks in TANK
      runFun(tankObj,f) % Run function f on all child blocks in tank
      
   end
   
   % PRIVATE
   % To be added to 'Contents.m'
   methods (Access = public, Hidden = true)
      flag = init(tankObj)                 % Initializes the TANK object.
      flag = genPaths(tankObj,tankPath) % Generate paths property struct
      flag = findCorrectPath(tankObj,paths)   % Find correct Animal path
      flag = getSaveLocation(tankObj,saveLoc) % Prompt to set save dir

%       ClusterConvert(tankObj)
%       LocalConvert(tankObj)
%       SlowConvert(tankObj)
      clearSpace(tankObj,ask)   % Clear space in all Animals/Blocks
      
      removeAnimal(tankObj,ind) % remove the animalObj at index ind
   end
   
   % PRIVATE
   % Used during initialization or internally
   methods (Access = private)
      % Add property listeners to 'Animals' 
      function addPropListeners(tankObj)
         % ADDPROPLISTENERS  Adds property listeners to tankObj on init
         %
         %  tankObj.addPropListeners();
         
         tankObj.PropListener = ...
            [addlistener(tankObj,'Animals','PostSet',...
               @(~,~)tankObj.CheckAnimalsForClones),...
             addlistener(tankObj,'User','PostSet',...
               @(~,evt)tankObj.validateUserString(evt.EventName)),...
             addlistener(tankObj,'User','PreGet',...
               @(~,evt)tankObj.validateUserString(evt.EventName))];
            
      end
      
      % Check parameters file to set `HasParsFile` flag for this `User`
      function flag = checkParsFile(tankObj,parsField)
         %CHECKPARSFILE  Sets .HasParsFile for current .User
         %
         %  tankObj.checkParsFile();
         %  flag = tankObj.checkParsFile(parsField); Returns flag
         %     indicating whether 'parsField' is a field of .('user')
         
         params_fname = tankObj.getParsFilename();
         if exist(params_fname,'file')==0
            tankObj.HasParsFile = false;
            return;
         end
         
         userName = tankObj.User;
         try
            m = matfile(params_fname);
         catch
            warning('%s may be corrupt',params_fname);
            tankObj.HasParsFile = false;
            return;
         end
         allUsers = who(m);
         tankObj.HasParsFile = ismember(userName,allUsers);
         if nargin > 1
            if tankObj.HasParsFile
               flag = isfield(m.(userName),parsField);
            else
               flag = false;
            end
         else
            flag = tankObj.HasParsFile;
         end
      end
      
      % Return full filename to parameters file
      function f = getParsFilename(tankObj,useUNC)
         %GETPARSFILENAME  Returns full (UNC) filename to parameters file
         %
         %  f = tankObj.getParsFilename(); Return UNC path (def)
         %  f = tankObj.getParsFilename(false); Return `fullfile` version
         
         if nargin < 2
            useUNC = true;
         end
         
         if useUNC
            f = nigeLab.utils.getUNCPath(tankObj.Paths.SaveLoc,...
                   sprintf(tankObj.ParamsExpr,tankObj.Name));
         else
            f = fullfile(tankObj.Paths.SaveLoc,...
               sprintf(tankObj.ParamsExpr,tankObj.Name));
         end
      end
      
      % Load/parse ID file and associated parameters
      function loadIDFile(tankObj)
         %LOADIDFILE Load and parse .nigelTank file into .IDInfo property
         %
         %  tankObj.loadIDFile();
         
         if isempty(tankObj.IDFile)
            tankObj.IDFile = nigeLab.utils.getUNCPath(...
               tankObj.Paths.SaveLoc,tankObj.FolderIdentifier);
         end
         
         fid = fopen(tankObj.IDFile,'r+');
         if fid < 0
            % "ID" file doesn't exist; make it using current properties
            tankObj.saveIDFile();
            return;
         end
         C = textscan(fid,'%q %q','Delimiter','|');
         fclose(fid);
         propName = C{1};
         propVal = C{2};
         if ~strcmpi(propName{1},'TANK')
            error(['nigeLab:' mfilename ':BadFolderHierarchy'],...
               'Attempt to load non-Tank from Tank folder.');
         end
         
         mc = metaclass(tankObj);
         mcp = {mc.PropertyList.Name};
         tankObj.IDInfo = struct;
         tankObj.IDInfo.TANK = propVal{1};
         for i = 2:numel(propName)
            if ~contains(propName{i},'.')
               tankObj.IDInfo.(propName{i}) = propVal{i};
            end
            if isempty(propVal{i})
               warning('%s .nigelTank value missing.\n',propName{i});
               continue;
            end
            setProp(tankObj,propName{i},propVal{i});
         end
         
         if isempty(tankObj.User)
            tankObj.saveIDFile(); % Make sure correct file is saved
         end
         
      end
      
      % Save small folder identifier file
      function saveIDFile(tankObj)
         %SAVEIDFILE  Save small folder identifier file
         %
         %  tankObj.saveIDFile();
         
         % Save tank "ID" for convenience of identifying this folder as a
         % "nigelTank" in the future.
         if isempty(tankObj.IDFile)
            tankObj.IDFile = nigeLab.utils.getUNCPath(...
               tankObj.Paths.SaveLoc,tankObj.Pars.FolderIdentifier);
         end

         fid = fopen(tankObj.IDFile,'w');
         if fid > 0
            fprintf(fid,'TANK|%s\n',tankObj.Name);
            fprintf(fid,'User|%s',tankObj.User);
            fclose(fid);
         else
            warning('Could not write .nigelTank (%s)',tankObj.IDFile);
         end
      end
      
   end
   
   % PRIVATE
   % Listener callbacks
   methods (Access = private, Hidden = true)
      % Remove Animals from the array at a given index (event listener) if
      % that animal object is destroyed for some reason.
      function AssignNULL(tankObj)
         % ASSIGNNULL  Remove assignment of a given Animal from
         %             tankObj.Animals, so we don't keep handles to deleted
         %             objects in that array. Event listener for
         %             'ObjectDestroyed' event of nigeLab.Animal.
         
         tankObj.Animals(~isvalid(tankObj.Animals)) = [];
      end
      
      % Event listener callback to make sure that duplicate Animals are not
      % added and if they are duplicated, that upon removal there are not
      % "lost" Child Blocks.
      function CheckAnimalsForClones(tankObj)
         % CHECKANIMALSFORCLONES  Event listener callback invoked when a
         %                        new Animal is added to tankObj.Animals.
         %
         %  tankObj.CheckAnimalsForClones;  Ensure no redundancies in
         %                                   tankObj.Animals.
         
         % If no animals or only 1 animal, no need to check
         a = tankObj.Animals;
         if sum(isempty(a)) == 1
            return;
         else
            idx = ~isempty(a);
            a = a(idx);
         end
         % Get names for comparison
         cname = {a.Name};
         % look for animals with the same name
         comparisons_cell = cellfun(@(s) strcmp(s,cname),...
            cname,...
            'UniformOutput',false);
         comparisons_mat = logical(triu(cat(1,comparisons_cell{:}) - ...
                                    eye(numel(cname))));
         rmvec = any(comparisons_mat,1);
         if ~any(rmvec)
            return;
         end
         
         % cycle through each animal, removing animals and adding any
         % associated blocks to the "kept" animal Blocks property
         ii=1;
         while ~isempty(comparisons_mat)
            % Current row contains all comparisons to other Animals in
            % tankObj.Animals
            animalIsSame = comparisons_mat(1,:);
            comparisons_mat(1,:) = []; % ensure this row is dropped
            
            % ii indexes current "good" Animal
            animalObj = a(ii); 
            ii = ii + 1; % ensure it is incremented
            
            % If no redundancies, then continue. 
            if ~any(animalIsSame)
               continue;
            end
            
            % To prevent weird case where you have a 1x0 array
            if isempty(animalIsSame)
               continue;
            end
            
            % Add child blocks from removed animals to this animal to
            % ensure they aren't accidentally discarded
            aidx = find(animalIsSame);
            B = a{aidx,:}; %#ok<*FNDSB>
            addChildBlock(animalObj,B); 
            
            % Now, remove redundant animals from array and also remove them
            % from the comparisons matrix since we don't need to redo them
            mask = find(idx);
            tankObj.Animals(mask(animalIsSame)) = []; % Remove from property
            a(animalIsSame) = []; % Remove them from consideration in the array
            idx(animalIsSame) = []; % Remove corresponding indexes
            
            % Lastly, update the comparisons matrices
            iRow = animalIsSame(2:end); % To account for previously-removed row of comparisons
            comparisons_mat(iRow,:) = [];
            % Columns are not removed, since the original animal is kept in
            % the array and we should account for its index.
            comparisons_mat(:,animalIsSame) = []; 
         end
      end
   end

   % STATIC
   methods (Static)
      % Method to create Empty TANK object or array
      function tankObj = Empty(n)
         % EMPTY  Creates "empty" block or block array
         %
         %  tankObj = nigeLab.Tank.Empty();  % Makes a scalar Tank object
         %  tankObj = nigeLab.Tank.Empty(n); % Make n-element array Tank
         
         if nargin < 1
            n = [0, 0];
         else
            n = nanmax(n,0);
            if isscalar(n)
               n = [0, n];
            end
         end
         
         tankObj = nigeLab.Tank(n);
      end
      
      % Method that is called when loading a TANK
      function b = loadobj(a)
         % LOADOBJ  Overloaded method called when loading a TANK
         %
         %  tankObj = loadObj(tankObj);
         
         a.addPropListeners();
         a.loadIDFile();
         a.checkParsFile();
         
         if ~isfield(a.Paths,'SaveLoc')
            a.checkParallelCompatibility();
            b = a;
            return;
         end
         
         a.PropListener(1).Enabled = false; % .Animal listener
         if isempty(a.Animals)
            % Have to re-load all the child animals/blocks since they were
            % removed in order to save it properly (during MultiAnimals
            % methods)
            A = dir(fullfile(a.Paths.SaveLoc,'*_Animal.mat'));
            a.Animals = nigeLab.Animal.Empty([1,numel(A)]);
            for ii=1:numel(A)
               try
                  in = load(fullfile(A(ii).folder,A(ii).name));
                  a.addAnimal(in.animalObj,ii);
               catch
                  warning('Failed to load %s',A(ii).name);
               end
            end
         else
            % Do not expect this to be the case.
            warning('Tank (%s) was loaded with non-empty Animals',a.Name);
         end
         a.PropListener(1).Enabled = true;
         a.checkParallelCompatibility();
         % Check if AnimalMask is initialized; if it is not, set it
         if isempty(a.AnimalMask)
            a.AnimalMask = true(size(a.Animals)); % init all to true
         end
         b = a;
         
      end
      
      
   end
   
end
