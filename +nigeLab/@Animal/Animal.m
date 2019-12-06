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
%     addBlock - Add Blocks to Animal object
%
%     getStatus - Returns status of each Operation/Block pairing
%
%     save - Save 'animalObj' in [Name]_Animal.mat
%
%     setTank - Set "Parent" nigeLab.Tank object
%
%     Empty - Create an Empty ANIMAL object or array
   
   %% PUBLIC PROPERTIES
   properties (GetAccess = public, SetAccess = public, SetObservable)
      Name     char          % Animal identification code
      Tank     nigeLab.Tank  % Parent (nigeLab.Tank object)
      Probes   struct        % Electrode configuration structure
      Blocks   nigeLab.Block % Children (nigeLab.Block objects)
   end
   
   properties (GetAccess = public, SetAccess = private, SetObservable)
      Mask     double        % Channel "Mask" vector (for all recordings)
   end
   
   %% HIDDEN OR PRIVATE PROPERTIES
   properties (SetAccess = private, GetAccess = public)
      Paths   struct      % Path to Animal folder
   end
      
   properties (GetAccess = public, SetAccess = private, Hidden = true)
      Pars           struct      % parameters struct for templates from nigeLab.defaults
      
      TankLoc        char        % directory for saving Animal
      RecDir         char        % directory with raw binary data in intan format
      ExtractFlag    logical     % flag status of extraction for each block
   end
   
   properties  (SetAccess = private, GetAccess = private) 
       RecLocDefault    char     % Default location of raw binary recording
       TankLocDefault   char     % Default location of BLOCK
   end
   
   %% PUBLIC METHODS
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
         
         animalObj.updateParams('Animal');
         animalObj.updateParams('all');
         
         addlistener(animalObj,'Name','PostSet',...
            @animalObj.updateAnimalNameInChildBlocks);
         
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
               return;
            elseif ischar(animalPath)
               animalObj.RecDir = animalPath;
            else
               error(['nigeLab:' mfilename ':badInputType1'],...
                  'Bad animalPath input type: %s',class(animalPath));
            end
         end
         
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
      function addBlock(animalObj,blockPath,idx)
         % ADDBLOCK  Add Block "Children" to Blocks property
         %
         %  animalObj.addBlock('blockPath'); 
         %  --> Adds block located at 'BlockPath'
         %
         %  animalObj.addBlock(blockObj);
         %  --> Adds the block directly to 'Blocks'
         %
         %  animalObj.addBlock(blockObj,idx);
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
               blockObj = nigeLab.Block(blockPath);
               
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
         blockObj.setAnimal(animalObj);
         if nargin < 3
            animalObj.Blocks = [animalObj.Blocks blockObj];
         else
            S = substruct('()',{1,idx});
            animalObj.Blocks = builtin('subsasgn',animalObj.Blocks,...
                                          S,blockObj);
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
         
         flag = getStatus(animalObj.Blocks,opField);
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

         for b = animalObj.Blocks
            b.save;
         end
         
         % Save animalObj
         animalObj.updateParams('Animal');
         animalFile = nigeLab.utils.getUNCPath(...
                     fullfile([animalObj.Paths.SaveLoc '_Animal.mat']));
         save(animalFile,'animalObj','-v7');
         
         % Save "nigelAnimal" file for convenience of identifying this
         % folder as an "ANIMAL" folder in the future
         animalIDFile = nigeLab.utils.getUNCPath(...
                     fullfile(animalObj.Paths.SaveLoc,...
                              animalObj.Pars.FolderIdentifier));
         
         fid = fopen(animalIDFile,'w+');
         fwrite(fid,['ANIMAL|' animalObj.Name]);
         fclose(fid);
      end
      
      % Set "Parent" Tank object
      function setTank(animalObj,tankObj)
         % SETTANK  Sets the "parent" Tank object
         %
         %  animalObj.setTank(tankObj);  Sets the 'Tank' property
         
         if ~isa(tankObj,'nigeLab.Tank')
            error(['nigeLab:', mfilename, ':BadTypeInput1'],...
               'tankObj must be nigeLab.Tank, not %s',class(tankObj));
         end
         
         if ~isscalar(tankObj)
            error(['nigeLab:', mfilename, ':BadTypeInput2'],...
               'tankObj must be scalar');
         end
         
         animalObj.Tank = tankObj;
      end
      
%       % Overloaded function that is called when ANIMAL is being saved.
%       function animalobj = saveobj(animalobj)
%          % SAVEOBJ  Used when ANIMAL is being saved. Writes the returned
%          %          value to the matfile.
%          
%          animalobj.Blocks(:) = [];      
%       end
   end
   
   % PUBLIC methods (to go in Contents.m)
   methods (Access = public)
      table = list(animalObj)               % List of recordings currently associated with the animal
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
   
   % "HIDDEN" PUBLIC methods
   methods (Access = public, Hidden = true)
      clearSpace(animalObj,ask,usrchoice) % Remove files from disk
      updateNotes(blockObj,str) % Update notes for a recording
      
      flag = genPaths(animalObj,tankPath) % Generate paths property struct
      flag = findCorrectPath(animalObj,paths)   % Find correct Animal path
      flag = getSaveLocation(animalObj,saveLoc) % Prompt to set save dir
      flag = doAutoClustering(animalObj,chan,unit) % Runs spike autocluster
      
      N = getNumBlocks(animalObj); % Gets total number of blocks 
   end
   
   %% PRIVATE METHODS
   methods (Access = 'private')
      init(animalObj)         % Initializes the ANIMAL object
      def_params(animalObj)   % Default parameters for ANIMAL (deprecated)
      
      function updateAnimalNameInChildBlocks(animalObj,~,~)
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
   
   methods (Static)
      function animalObj = Empty(n)
         % EMPTY  Creates "empty" Animal or Animal array
         %
         %  nigeLab.Animal.Empty();  % Makes a scalar
         %  nigeLab.Animal.Empty(n); % Make n-element array of Animal
         
         if nargin < 1
            n = 1;
         else
            n = nanmax(n,1);
            if isscalar(n)
               n = [1, n];
            end
         end
         
         animalObj = nigeLab.Animal(n);
      end
      
      function b = loadobj(a)
         % LOADOBJ  Method to load ANIMAL objects
         %
         %  b = loadObj(a);
         %
         %  Just makes sure that a is correct, and returns it on loading as
         %  b to avoid infinite recursion.
         
         if ~isfield(a.Paths,'SaveLoc')
            b = a;
            return;
         end
         
         BL = dir(fullfile(a.Paths.SaveLoc,'*_Block.mat'));
         if isempty(a.Blocks)
            a.Blocks = nigeLab.Block.Empty([1,numel(BL)]);

            for ii=1:numel(BL)
               in = load(fullfile(BL(ii).folder,BL(ii).name));
               a.addBlock(in.blockObj,ii);
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