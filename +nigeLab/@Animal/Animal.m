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
      Name     char          % Animal identification code
      Probes   struct        % Electrode configuration structure
      Blocks   nigeLab.Block % Children (nigeLab.Block objects)
   end
   
   % Cannot set but may want to see it publically. SetObservable.
   properties (GetAccess = public, SetAccess = private, SetObservable)
      Mask     double        % Channel "Mask" vector (for all recordings)
   end
   
   % More likely to externally reference
   properties (SetAccess = private, GetAccess = public)
      Paths   struct      % Path to Animal folder
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
      MultiAnimals = false                      % flag to signal if it's a single animal or a joined animal recording
      MultiAnimalsLinkedAnimals  nigeLab.Block  % Array of "linked" blocks
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
      Listener         event.listener  % Scalar event.listener associated with this ANIMAL
      PropListener     event.listener  % Array of handles listening to ANIMAL property changes
      
      % Flags
      IsEmpty = true  % Flag to indicate whether block is EMPTY
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
         animalObj.addListeners();
         
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
               error(['nigeLab:' mfilename ':selectionCanceled'],...
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
       
      end
      
      % Add Blocks to Animal object
      function addChildBlock(animalObj,blockPath,idx)
         % ADDBLOCK  Add Block "Children" to Blocks property
         %
         %  animalObj.addChildBlock('blockPath'); 
         %  --> Adds block located at 'BlockPath'
         %
         %  animalObj.addChildBlock(blockObj);
         %  --> Adds the block directly to 'Blocks'
         %
         %  animalObj.addChildBlock(blockObj,idx);
         %  --> Adds the block to the array element indexed by idx

         if nargin < 2
            blockPath = [];
         end
         
         if ~isscalar(animalObj)
            error(['nigeLab:' mfilename ':badInputType2'],...
               'animalObj must be scalar.');
         end

         switch class(blockPath)
            case 'char'
               % Create the Children Block objects
               blockObj = nigeLab.Block(blockPath,animalObj.Paths.SaveLoc);
               
            case 'nigeLab.Block'
               % Load them directly as Children
               if numel(blockPath) > 1
                  blockObj = reshape(blockPath,1,numel(blockPath));
               else
                  blockObj = blockPath;
               end
               
            case 'double'
               if isempty(blockPath)
                  blockObj = nigeLab.Block([],animalObj.Paths.SaveLoc);
               end

            otherwise
               error(['nigeLab:' mfilename ':badInputType1'],...
                  'Bad blockPath input type: %s',class(blockPath));
         end
         
         
         
         if nargin < 3
            idx = numel(animalObj.Blocks);
            animalObj.Blocks = [animalObj.Blocks blockObj];
            idx = idx:numel(animalObj.Blocks);
         else
            S = substruct('()',{1,idx});
            animalObj.Blocks = builtin('subsasgn',animalObj.Blocks,...
                                          S,blockObj);
         end
         for i = 1:numel(blockObj)
            blockObj(i).Listener = ...
                  addlistener(blockObj(i),...
                     'ObjectBeingDestroyed',...
                     @(~,~)animalObj.AssignNULL);
         end
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
         
         for i = 1:numel(animalObj.PropListener)
            if isvalid(animalObj.PropListener(i))
               delete(animalObj.PropListener(i));
            end
         end
         
         if isvalid(animalObj.Listener)
            delete(animalObj.Listener)
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
         
         % Save "nigelAnimal" file for convenience of identifying this
         % folder as an "ANIMAL" folder in the future
         animalIDFile = nigeLab.utils.getUNCPath(...
                     fullfile(animalObj.Paths.SaveLoc,...
                              animalObj.Pars.FolderIdentifier));
         
         fid = fopen(animalIDFile,'w+');
         fwrite(fid,['ANIMAL|' animalObj.Name]);
         fclose(fid);
      end
      
      % Overloaded function that is called when ANIMAL is being saved.
      function animalObj = saveobj(animalObj)
         % SAVEOBJ  Used when ANIMAL is being saved. Writes the returned
         %          value to the matfile. We do it this way so that
         %          animalObj does not save Block objects redundantly.
         
         animalObj.Blocks(:) = [];     
         animalObj.PropListener(:) = [];
         animalObj.Listener(:) = [];
      end
      
   end
   
   % PUBLIC 
   % Methods that should go in Contents.m eventually
   methods (Access = public)
      table = list(animalObj,keyIdx)        % List of recordings currently associated with the animal
      out = animalGet(animalObj,prop)       % Get a specific BLOCK property
      flag = animalSet(animalObj,prop)      % Set a specific BLOCK property
      
      mergeBlocks(animalObj,ind,varargin) % Concatenate two Blocks together
      removeBlocks(animalObj,ind)         % Disassociate a Block from Animal
      
      flag = doUnitFilter(animalObj)      % Apply Unit Bandpass filter to all raw data in Blocks of Animal
      flag = doReReference(animalObj)     % Re-reference all filtered data in Blocks of Animal
      flag = doRawExtraction(animalObj)   % Extract Raw Data for all Blocks in Animal
      flag = doLFPExtraction(animalObj)   % Extract LFP for all Blocks in Animal
      flag = doSD(animalObj)              % Extract spikes for all Blocks in Animal
      
      flag = updateParams(animalObj,paramType) % Update parameters of Animal and Blocks
      flag = updatePaths(animalObj,SaveLoc)     % Update folder tree of all Blocks
      linkToData(animalObj)                    % Link disk data of all Blocks in Animal
      flag = splitMultiAnimals(blockObj,tabpanel) % Split recordings that have multiple animals to separate recs
   end
   
   % PUBLIC
   % "Hidden" methods that shouldn't typically be used
   methods (Access = public, Hidden = true)
      clearSpace(animalObj,ask,usrchoice) % Remove files from disk
      updateNotes(blockObj,str) % Update notes for a recording
      
      flag = genPaths(animalObj,tankPath) % Generate paths property struct
      flag = findCorrectPath(animalObj,paths)   % Find correct Animal path
      flag = getSaveLocation(animalObj,saveLoc) % Prompt to set save dir
      flag = doAutoClustering(animalObj,chan,unit) % Runs spike autocluster
      
      N = getNumBlocks(animalObj); % Gets total number of blocks 
   end
    
   % PRIVATE 
   % To be catalogued in 'Contents.m'
   methods (Access = private, Hidden = false)
      init(animalObj)         % Initializes the ANIMAL object
   end
   
   % PRIVATE
   % Used during Initialization
   methods (Access = 'private')
      % Adds listener handles to array property of animalObj
      function addListeners(animalObj)
         % ADDLISTENERS  Called on initialization to build PropListener
         %               property array.
         %
         %  animalObj.addListeners();
         %
         %  --> Creates 2-element vector of property listeners
         
         animalObj.PropListener(1) = ...
            addlistener(animalObj,'Name','PostSet',...
            @(~,~)animalObj.updateAnimalNameInChildBlocks);
         
         animalObj.PropListener(2) = ...
            addlistener(animalObj,'Blocks','PostSet',...
            @(~,~)animalObj.CheckBlocksForClones);
      end
   end
   
   % PRIVATE
   % Listener callbacks
   methods (Access = private, Hidden = true) 
      % Callback for when a "child" Block is moved or otherwise destroyed
      function AssignNULL(animalObj)
         % ASSIGNNULL  Does null assignment to remove a block of a
         %             corresponding index from the animalObj.Blocks
         %             property array, for example, if that Block is
         %             destroyed or moved to a different animalObj. Useful
         %             as a callback for an event listener handle.
         
         animalObj.Blocks(~isvalid(animalObj.Blocks)) = [];
      end
      
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
            n = [1, 1];
         else
            n = nanmax(n,1);
            if isscalar(n)
               n = [1, n];
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
         
         
         
         if ~isfield(a.Paths,'SaveLoc')
            a.addListeners();
            b = a;
            return;
         end
         
         BL = dir(fullfile(a.Paths.SaveLoc,'*_Block.mat'));
         if isempty(a.Blocks)
            a.Blocks = nigeLab.Block.Empty([1,numel(BL)]);

            for ii=1:numel(BL)
               in = load(fullfile(BL(ii).folder,BL(ii).name));
               a.addChildBlock(in.blockObj,ii);
            end
            a.addListeners(); % Add listeners after all blocks back in
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