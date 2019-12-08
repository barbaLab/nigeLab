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

   %% PUBLIC PROPERTIES
   properties (GetAccess = public, SetAccess = public)
      Name    char               % Name of experiment (TANK)
      Animals nigeLab.Animal     % Handle array to Children
   end

   properties (SetAccess = private, GetAccess = public)
      Paths  struct             % Detailed paths specifications for all the saved files
      
   end
   
   %% PRIVATE PROPERTIES
   properties (GetAccess = public, SetAccess = private, Hidden = true) %debugging purposes, is private
      RecDir                  char     % Directory of the TANK
      SaveLoc                 char     % Top folder
      Pars                    struct   % Parameters struct
      
%       BlockNameVars           % Metadata variables from BLOCK names
%       DefaultSaveLoc          % Default for save location
%       DefaultTankLoc          % Default for UI TANK selection
%       Delimiter               % Filename metadata delimiter
%       RecType                 % Acquisition system used for this Tank
%                               % Currently supported formats
%                               % ---------------------------
%                               % Intan  ('Intan')
%                               % TDT    ('TDT')         
%                               
   end
   
   %% PUBLIC METHODS
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
                     tankObj(i,k) = copy(tankObj(1,1));
                  end
               end
               return;
            else
               error(['nigeLab:' mfilename ':badInputType1'],...
                  'Bad tankRecPath input type: %s',class(tankRecPath));
            end
         end
         
         if nargin < 2
            tankObj.SaveLoc = [];
         else
            tankObj.SaveLoc = nigeLab.utils.getUNCPath(tankSavePath);
         end
         
         % Load default settings
         tankObj.updateParams('Tank');
         tankObj.updateParams('all');
         
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
      
      % Method to add animals to Tank
      function addAnimal(tankObj,animalPath,idx)
         % ADDANIMAL  Method to add animal to nigeLab.Tank Animals property
         %
         %  tankObj.addAnimal();
         %     --> Allows selection of animals from UI
         %  tankObj.addAnimal('AnimalFolder'); 
         %     --> Adds animal corresponding to 'AnimalFolder'
         %  tankObj.addAnimal({'aFolder1','aFolder2',...});
         %     --> Adds multiple animals from cell array of folder chars
         %  tankObj.addAnimal(animalObj);
         %     --> Adds animalObj directly, which could be a scalar
         %         animalObj or an array.
         %  tankObj.addAnimal(animalObj,idx);
         %     --> Specifies the array index to add the animal to
         
         % Check inputs
         if nargin<2
            animalPath = '';
         end
         
         if iscell(animalPath)
            for i = 1:numel(animalPath)
               tankObj.addAnimal(animalPath{i});
            end
            return;
         end
         
         if isa(animalPath,'nigeLab.Animal')
            if numel(animalPath) > 1
               animalObj = reshape(animalPath,1,numel(animalPath));
            else
               animalObj = animalPath;
            end
         else
            % Parse AnimalFolder from UI
            if isempty(animalPath)
               animalPath = uigetdir(tankObj.RecDir,...
                  'Select animal folder');
               if animalPath == 0
                  error(['nigeLab:' mfilename ':NoAnimalSelection'],...
                     'No ANIMAL selected. Object not created.');
               end
            else
               if exist(animalPath,'dir')==0
                  error(['nigeLab:', mfilename ':invalidAnimalPath'],...
                     '%s is not a valid ANIMAL directory.',animalPath);
               end
            end
            animalObj = nigeLab.Animal(animalPath,tankObj.Paths.SaveLoc);
         end
         animalObj.setTank(tankObj); % Set "parent" tank
         if nargin < 3
            tankObj.Animals = [tankObj.Animals animalObj];
         else
            tankObj.Animals(idx) = animalObj;
         end
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
         for a = tankObj.Animals
            a.save;
         end
         
         % Save tankObj
         tankObj.updateParams('Tank');
         tankFile = nigeLab.utils.getUNCPath(...
                     fullfile([tankObj.Paths.SaveLoc '_Tank.mat']));
         save(tankFile,'tankObj','-v7');
         tankObj.Animals = A; % so pointer is still good after saving         
         
         % Save tank "ID" for convenience of identifying this folder as a
         % "nigelTank" in the future.
         tankIDFile = nigeLab.utils.getUNCPath(...
                     fullfile(tankObj.Paths.SaveLoc,...
                              tankObj.Pars.FolderIdentifier));
         
         fid = fopen(tankIDFile,'w+');
         fwrite(fid,['TANK|' tankObj.Name]);
         fclose(fid);
         
      end
      
      % Overloaded method that is called when TANK is saved
      function tankObj = saveobj(tankObj)
         % SAVEOBJ  Method that is called when TANK is saved. Writes the 
         %          returned value to the matfile. We do it this way so
         %          that tankObj.Animals does not save Animal objects
         %          redundantly.
         
         tankObj.Animals(:) = [];         
      end
      
      % Returns the status of a operation/animal for each unique pairing
      function Status = getStatus(tankObj,operation)
         % GETSTATUS  Return the status for each Animal for a given
         %            operation. If anything is missing for that
         %            Animal/Operation pairing, then the corresponding
         %            status element (for that animal) is returned as
         %            false.
         %
         %  Status = tankObj.getStatus(); Returns status for ALL operations
         %  Status = tankObj.getStatus(operation); Returns specific
         %                                         operation status
         
         if nargin <2
            tmp = tankObj.list;
            Status = tmp.Status;
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

      % Overloaded function for referencing ANIMAL/BLOCK using {}
      function varargout = subsref(tankObj,S)
         % SUBSREF  Overloaded function modified so that BLOCK can be
         %          referenced by indexing from ANIMAL using {} operator.
         %          Everything with {} referencing refers to the
         %          tankObj.Animals property.
         %
         %  childBlockArray = tankObj{[2,1;1,4;3,1]}
         %  --> childBlockArray is the 1st Child Block of 2nd Animal in
         %     array, 4th Block of 1st Animal, and 1st Block of 3rd Animal,
         %     concatenated into a horizontal array [b21, b14, b31]
         %
         %  --> equivalent to calling tankObj{[2,1,3],[1,4,1]};
         %
         %  ** NOTE ** that calling
         %  tankObj{[2,1,3],[1,2,4,5]} would only return a single
         %  element for each animalObj [b21, b12, b34], NOT the 1st, 2nd,
         %  4th, and 5th block from each animal.
         %
         %  childBlock = tankObj{1,1}
         %  --> returns 1st child of 1st animal in tankObj.Animals
         %
         %  childBlockArray = tankObj{1}
         %  --> Returns first animal in tankObj.Animals
         %
         %  ** NOTE ** tankObj{end} references the last Animal in
         %             tankObj.Animals.
         %
         %  childBlockArray = tankObj{:}
         %  --> Returns all animals in tankObj.Animals.
         %
         %  childBlockArray = tankObj{2,:}
         %  --> Returns all children of 2nd animal in tankObj.Animals.
         %
         %  childBlockArray = tankObj{:,1}
         %  --> Returns first child Block of each animal in tankObj.Animals
         %
         %  ** NOTE ** tankObj{idx1,end} references the last Block in each
         %             element of tankObj.Animals indexed by idx1.
         
         if isempty(tankObj.Animals)
            error(['nigeLab:' mfilename ':indexOutOfBounds'],...
               'tankObj.Animals is empty');
         end
         
         
         subs = S(1).subs;
         
         switch S(1).type
            case '{}'
               varargout = cell(1,nargout);
               switch numel(subs)
                  % If only 1 subscript, then it indexes Animals
                  case 1
                     s = substruct('()',subs);
                     varargout{1} = subsref(tankObj.Animals,s);
                  case 2
                     s = substruct('{}',subs);
                     varargout{1} = subsref(tankObj.Animals,s);
                     
                  otherwise
                     error(['nigeLab:' mfilename ':tooManyInputs'],...
                        'Too many subscript indexing args (%g) given.',...
                        numel(subs));
               end
               return;
               
            % If not {} index, use normal behavior
            otherwise
               [varargout{1:nargout}] = builtin('subsref',tankObj,S);
         end
      end
   end   
   
   % PUBLIC methods (to be catalogued using contents.m)
   methods (Access = public)
      flag = doRawExtraction(tankObj)  % Extract raw data from all Animals/Blocks
      flag = doReReference(tankObj)    % Do CAR on all Animals/Blocks
      flag = doLFPExtraction(tankObj)  % Do LFP extraction on all Animals/Blocks
      flag = doSD(tankObj)             % Do spike detection on all Animals/Blocks
      
      linkToData(tankObj)           % Link TANK to data files on DISK
      blockList = list(tankObj)     % List Blocks in TANK    
      flag = updatePaths(tankObj,SaveLoc)    % Update PATHS to files
      N = getNumBlocks(tankObj) % Get total number of blocks in TANK
      runFun(tankObj,f) % Run function f on all child blocks in tank
      
   end
   %% PRIVATE METHODS
   methods (Access = public, Hidden = true)
      flag = init(tankObj)                 % Initializes the TANK object.
      flag = genPaths(animalObj,tankPath) % Generate paths property struct
      flag = findCorrectPath(animalObj,paths)   % Find correct Animal path
      flag = getSaveLocation(animalObj,saveLoc) % Prompt to set save dir

%       ClusterConvert(tankObj)
%       LocalConvert(tankObj)
%       SlowConvert(tankObj)
      clearSpace(tankObj,ask)   % Clear space in all Animals/Blocks
   end

   methods (Static)
      % Method to create Empty TANK object or array
      function tankObj = Empty(n)
         % EMPTY  Creates "empty" block or block array
         %
         %  tankObj = nigeLab.Tank.Empty();  % Makes a scalar Tank object
         %  tankObj = nigeLab.Tank.Empty(n); % Make n-element array Tank
         
         if nargin < 1
            n = 1;
         else
            n = nanmax(n,1);
            if isscalar(n)
               n = [1, n];
            end
         end
         
         tankObj = nigeLab.Tank(n);
      end
      
      % Method that is called when loading a TANK
      function b = loadobj(a)
         % LOADOBJ  Overloaded method called when loading a TANK
         %
         %  tankObj = loadObj(tankObj);
         
         if ~isfield(a.Paths,'SaveLoc')
            b = a;
            return;
         end
         
         if isempty(a.Animals)
            % Have to re-load all the child animals/blocks since they were
            % removed in order to save it properly (during MultiAnimals
            % methods)
            A = dir(fullfile(a.Paths.SaveLoc,'*_Animal.mat'));
            a.Animals = nigeLab.Animal.Empty([1,numel(A)]);
            for ii=1:numel(A)
               in = load(fullfile(A(ii).folder,A(ii).name));
               a.addAnimal(in.animalObj,ii);
            end
            b = a;
            return;
         else
            b = a;
            return;
         end
         
      end
      
      
   end
   
end