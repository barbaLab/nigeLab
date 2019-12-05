classdef Tank < handle
% TANK  Construct Tank Class object
%
%  tankObj = nigeLab.Tank();
%     --> prompts for locations using UI
%
%  tankObj = nigeLab.Tank(tankSavePath);
%     --> tankPath can be [] or char array with location
%
%  tankObj = nigeLab.Tank(tankSavePath
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
      Name                    % Name of experiment (TANK)
      Animals nigeLab.Animal  % Handle array to Children
   end
   
   properties (SetAccess = private, GetAccess = public)
       Paths  % Detailed paths specifications for all the saved files
   end
   
   %% PRIVATE PROPERTIES
   properties (GetAccess = public, SetAccess = private, Hidden = true) %debugging purposes, is private
      RecDir                  % Directory of the TANK
      SaveLoc                 % Top folder
      Pars                    % Parameters struct
      
      BlockNameVars           % Metadata variables from BLOCK names
      BlockStatusFlag         % Flag to indicate if blocks are at same step
      CheckBeforeConversion   % Flag to ask for confirmation before convert
      DefaultSaveLoc          % Default for save location
      DefaultTankLoc          % Default for UI TANK selection
      Delimiter               % Filename metadata delimiter
      RecType                 % Acquisition system used for this Tank
                              % Currently supported formats
                              % ---------------------------
                              % Intan  ('Intan')
                              % TDT    ('TDT')         
                              
      ExtractFlag             % Flag to indicate if extraction is needed
      ParallelFlag            % Flag to run things via parallel architecture
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
         %  tankObj = nigeLab.Tank(tankSavePath);
         %     --> tankPath can be [] or char array with location
         %
         %  tankObj = nigeLab.Tank(tankSavePath
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
               return;
            else
               error(['nigeLab:' mfilename ':badInputType1'],...
                  'Bad tankRecPath input type: %s',class(tankRecPath));
            end
         end
         
         if nargin < 2
            tankObj.SaveLoc = [];
         else
            tankObj.SaveLoc = tankSavePath;
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
               error('No block selected. Object not created.');
            end
         else
            if exist(tankObj.RecDir,'dir')==0
               error('%s is not a valid block directory.',tankObj.RecDir);
            end
         end
         tankObj.RecDir = nigeLab.utils.getUNCPath(tankObj.RecDir);
         if ~tankObj.init
            error('Could not initialize TANK object.');
         end
         
      end
      
      % Method to add animals to Tank
      function addAnimal(tankObj,animalPath)
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
         
         % Check inputs
         if nargin<2
            animalPath=[];
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
         tankObj.Animals = [tankObj.Animals animalObj];
      end
      
      % Method used for saving TANK object
      function save(tankObj)
         % SAVE  Method to save a nigeLab.Tank class object
         % 
         %  tankObj.save;  Saves 'tankObj' in [TankName]_Tank.mat
         
         A=tankObj.Animals;
         for ii=1:numel(A)
            A(ii).save;
         end
         save(fullfile([tankObj.Paths.SaveLoc '_Tank.mat']),'tankObj','-v7');
         tankObj.Animals = A;
      end
      
      % Overloaded method that is called when TANK is saved
      function tankObj = saveobj(tankObj)
         % SAVEOBJ  Method that is called when TANK is saved
         
         tankObj.Animals = nigeLab.Animal.Empty();         
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
         end
         
         tankObj = nigeLab.Tank(n);
      end
      
      % Method that is called when loading a TANK
      function tankObj = loadobj(tankObj)
         % LOADOBJ  Overloaded method called when loading a TANK
         %
         %  tankObj = loadObj(tankObj);
         
         % Have to re-load all the child animals/blocks since they were
         % removed in order to save it properly (during MultiAnimals
         % methods)
         BL = dir(fullfile(tankObj.Paths.SaveLoc,'*_Animal.mat'));
         load(fullfile(BL(1).folder,BL(1).name),'animalObj');
            tankObj.Animals = animalObj;
         for ii=2:numel(BL)
            load(fullfile(BL(ii).folder,BL(ii).name),'animalObj');
            tankObj.Animals(ii) = animalObj;
         end
      end
      
      
   end
   
end