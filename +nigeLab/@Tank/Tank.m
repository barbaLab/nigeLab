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
   properties (GetAccess = public, SetAccess = public, SetObservable)
      Name    char               % Name of experiment (TANK)
      Animals nigeLab.Animal     % Handle array to Children
   end

   % Has to be set by method of Tank, but can be accessed publically
   properties (SetAccess = private, GetAccess = public)
      Fields         cell      % Specific things to record
      FieldType      cell      % "Types" corresponding to Fields elements
      Paths          struct    % Detailed paths specifications for all the saved files
   end
   
   % Various parameters that may be useful to access publically but cannot
   % be set externally and don't populate the normal list of properties
   properties (GetAccess = public, SetAccess = private, Hidden = true) %debugging purposes, is private
      RecDir                  char     % Directory of the TANK
      SaveLoc                 char     % Top folder
      Pars                    struct   % Parameters struct
   end
   
   % Private - Listeners & Flags
   properties (SetAccess = public, GetAccess = private, Hidden = true)
      % Listeners
      PropListener    event.listener  % Array of handles that listen for key event changes
      
      % Flags
      IsEmpty = true  % Is this an empty tank
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
         tankObj.addListeners();
         
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
         
         for i = 1:numel(tankObj.PropListener)
            if isvalid(tankObj.PropListener(i))
               delete(tankObj.PropListener(i));
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
         tankObj.PropListener(:) = [];
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
   end   
   
   % PUBLIC
   % Methods (to be catalogued using contents.m)
   methods (Access = public)
      addAnimal(tankObj,animalPath,idx) % Add child Animals to Tank
      
      flag = doRawExtraction(tankObj)  % Extract raw data from all Animals/Blocks
      flag = doReReference(tankObj)    % Do CAR on all Animals/Blocks
      flag = doLFPExtraction(tankObj)  % Do LFP extraction on all Animals/Blocks
      flag = doSD(tankObj)             % Do spike detection on all Animals/Blocks
      
      flag = linkToData(tankObj)           % Link TANK to data files on DISK
      blockList = list(tankObj)     % List Blocks in TANK    
      flag = updatePaths(tankObj,SaveLoc)    % Update PATHS to files
      N = getNumBlocks(tankObj) % Get total number of blocks in TANK
      runFun(tankObj,f) % Run function f on all child blocks in tank
      
   end
   
   % PRIVATE
   % To be added to 'Contents.m'
   methods (Access = public, Hidden = true)
      flag = init(tankObj)                 % Initializes the TANK object.
      flag = genPaths(animalObj,tankPath) % Generate paths property struct
      flag = findCorrectPath(animalObj,paths)   % Find correct Animal path
      flag = getSaveLocation(animalObj,saveLoc) % Prompt to set save dir

%       ClusterConvert(tankObj)
%       LocalConvert(tankObj)
%       SlowConvert(tankObj)
      clearSpace(tankObj,ask)   % Clear space in all Animals/Blocks
      
      removeAnimal(tankObj,ind) % remove the animalObj at index ind
   end
   
   % PRIVATE
   % Used during initialization
   methods (Access = private)
      % Add property listeners to 'Animals' 
      function addListeners(tankObj)
         % ADDLISTENERS  Adds property listeners to tankObj on init
         %
         %  tankObj.addListeners();
         
         obj.PropListener(1) = addlistener(tankObj,...
            'Animals','PostSet',...
            @(~,~)tankObj.CheckAnimalsForClones);
            
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
            n = [1, 1];
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
            a.addListeners();
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
            a.addListeners();
            b = a;
            return;
         else
            a.addListeners();
            b = a;
            return;
         end
         
      end
      
      
   end
   
end
