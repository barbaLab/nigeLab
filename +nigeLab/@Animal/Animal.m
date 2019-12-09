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
      MultiAnimals = false                      % flag to signal if it's a single animal or a joined animal recording
      MultiAnimalsLinkedAnimals  nigeLab.Block  % Array of "linked" blocks
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
         addlistener(animalObj,'Blocks','PostSet',@(~,~) ...
            CheckBlocksForClones(animalObj));
       
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
         
         addlistener(blockObj,'ObjectBeingDestroyed',@(h,~) ...
           AssignNULL(animalObj,find(animalObj.Blocks == h)));
         
         if nargin < 3
            animalObj.Blocks = [animalObj.Blocks blockObj];
         else
            S = substruct('()',{1,idx});
            animalObj.Blocks = builtin('subsasgn',animalObj.Blocks,...
                                          S,blockObj);
         end                  
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
         B = animalObj.Blocks; % Since animalObj.Blocks(:) = [] in saveobj
         for b = animalObj.Blocks
            b.save;
         end
         
         % Save animalObj
         animalObj.updateParams('Animal');
         animalFile = nigeLab.utils.getUNCPath(...
                     fullfile([animalObj.Paths.SaveLoc '_Animal.mat']));
         save(animalFile,'animalObj','-v7');
         animalObj.Blocks = B; % Reassign after save, so pointer is valid
         
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
         animalObj.Tank(:) = [];
      end
      
      % Overloaded function for referencing BLOCK of a given ANIMAL
      function varargout = subsref(animalObj,S)
         % SUBSREF  Overloaded function modified so that BLOCK can be
         %          referenced by indexing from ANIMAL using {} operator.
         %
         %  childBlockArray = animalObjArray{[2,1;1,4;3,1]}
         %  --> childBlockArray is the 1st Child Block of 2nd Animal in
         %     array, 4th Block of 1st Animal, and 1st Block of 3rd Animal,
         %     concatenated into a horizontal array [b21, b14, b31]
         %
         %  --> equivalent to calling animalObjArray{[2,1,3],[1,4,1]};
         %
         %  ** NOTE ** that calling
         %  animalObjArray{[2,1,3],[1,2,4,5]} would only return a single
         %  element for each animalObj [b21, b12, b34], NOT the 1st, 2nd,
         %  4th, and 5th block from each animal.
         %
         %  childBlock = animalObjArray{1,1}
         %  --> returns 1st child of 1st animal in array
         %
         %  childBlockArray = animalObjArray{1}
         %  --> Returns all children of the 1st animal in array
         %
         %  childBlock = animalObj{1}
         %  --> Returns 1st block of that animal
         %
         %  childBlockArray = animalObj{:}
         %  --> Returns all children of that animal object
         %
         %  childBlockArray = animalObjArray{:}
         %  --> Returns all children of all animals in array
         %
         %  childBlockArray = animalObjArray{2,:}
         %  --> Returns all children of 2nd animal in array
         %
         %  childBlockArray = animalObjArray{:,1}
         %  --> Returns first child of all animals in array
         
         subs = S(1).subs;
         switch S(1).type
            case '{}'
               % If referencing a single animal, the behavior is different
               % if a single vector of subscripts is given.
               if isscalar(animalObj)
                  
                  % If only one argument given to subscripts (e.g. no ',')
                  if numel(subs) == 1
                     subs = subs{:};
                     
                     % If only referencing child objects using a vector
                     % (not referencing animalObj, since animalObj is
                     %  already a scalar!)
                     if size(subs,2) == 1
                        S = substruct('{}',{1, subs});
                        varargout = {subsref(animalObj,S)};
                        return;
                        
                     % Otherwise, if using a matrix to reference   
                     elseif size(subs,2) == 2 
                        S = substruct('{}',{subs(:,1),subs(:,2)});
                        varargout = {subsref(animalObj,S)};
                        return;
                        
                     % Otherwise, could be using 'end'
                     else
                        if ~ischar(subs)
                           error(['nigeLab:' mfilename ':badReference'],...
                              'Matrix references should be nChild x 2');
                        end
                        if strcmpi(subs,'end')
                           varargout = {animalObj.Block(...
                              animalObj.getNumBlocks)};
                           return;
                        else
                           error(['nigeLab:' mfilename ':badReference'],...
                              'Unrecognized index: %s',subs);
                        end
                     end
                     
                  % Otherwise, subscript for Animal and Block both given
                  elseif numel(subs) == 2
                     if ~ischar(subs{1})
                        if any(subs{1} > 1) % since this is a scalar animalObj
                           error(['nigeLab:' mfilename ':indexOutOfBounds'],...
                              'Bad indexing expression, animalObj is scalar.');
                        end
                     end
                     S = substruct('()',{ones(size(subs,1),1),subs{2}});
                     varargout = {subsref(animalObj.Blocks,S)};
                     return;
                     
                  % Otherwise, too many subscript args were given
                  else
                     error(['nigeLab:' mfilename ':tooManyInputs'],...
                        'Too many subscript indexing args (%g) given.',...
                        numel(subs));
                  end
                  
               % If more than one animalObj in array
               else
                  switch numel(subs)
                     case 1
                        subs = subs{:};
                        
                        % If only character input is given, it references
                        % either all of the blocks or all blocks of the
                        % last animal.
                        if ischar(subs)
                           switch subs                                 
                              % Return all children of all animals
                              case ':'
                                 varargout = cell(1,nargout);
                                 for i = 1:numel(animalObj)
                                    varargout{1} = [varargout{1},...
                                       animalObj(i).Blocks];
                                 end
                              otherwise
                                 error(['nigeLab:' mfilename ':badReference'],...
                                    'Unrecognized index keyword: %s',subs);
                           end
                           return;
                        end
                        % Otherwise, the input is numeric
                        % If it is a vector, then get all blocks of the
                        % corresponding animals.
                        if size(subs,2) == 1
                           varargout = {[]};
                           for i = 1:numel(subs)
                              varargout{1} = [varargout{1},...
                                 animalObj(subs(i)).Blocks];
                           end
                           return;
                           
                        % If it is a matrix, reformat and make call back to
                        % subsref
                        elseif size(subs,2) == 2
                           S = substruct('{}',{subs(:,1),subs(:,2)});
                           varargout = {subsref(animalObj,S)};
                           return;
                           
                        % Otherwise, it's a bad expression
                        else
                           error(['nigeLab:' mfilename ':badReference'],...
                              'Matrix references should be nChild x 2');
                        end
                        
                     % If there are two input arguments given to animalObj
                     % array for subscripting
                     case 2
                        
                        % If the first indexing element is a character,
                        % then get the corresponding ANIMAL according to
                        % that character index
                        if ischar(subs{1})
                           switch lower(subs{1})
                              % For each animalObj in array, return the
                              % corresponding blocks.
                              case ':'
                                 varargout = cell(1,nargout);
                                 for i = 1:numel(animalObj)
                                    if ischar(subs{2})
                                       switch lower(subs{2})
                                          case ':'
                                             idx2 = 1:getNumBlocks(animalObj(i));
                                          otherwise
                                             error(['nigeLab:' mfilename ':badReference'],...
                                                'Unrecognized index keyword: %s',subs);
                                       end
                                    else
                                       idx2 = subs{2}(i);
                                    end
                                    varargout{1} = [varargout{1},...
                                       animalObj(i).Blocks(idx2)];
                                 end
                                 
                              otherwise
                                 error(['nigeLab:' mfilename ':badReference'],...
                                    'Unrecognized index keyword: %s',subs);
                           end
                           return;                           
                        end
                        
                        % For an animalObj array, this means the indexing
                        % inputs must be numeric and of the form
                        % {animalObjIndex,blockObjIndex}
                        idx1 = subs{1};
                        varargout = cell(1,numel(idx1));
                        
                        for i = 1:numel(idx1)
                           if ischar(subs{2})
                              switch lower(subs{2})
                                 case ':'
                                    idx2 = 1:getNumBlocks(animalObj(i));
                                 otherwise
                                    error(['nigeLab:' mfilename ':badReference'],...
                                       'Unrecognized index keyword: %s',subs);
                              end
                           else
                              idx2 = subs{2}(i);
                           end
                           varargout{1} = [varargout{1},...
                              animalObj(idx1(i)).Blocks(idx2)];
                        end
                        return;
                        
                     % Otherwise too many input arguments given to
                     % animalObj array
                     otherwise
                        error(['nigeLab:' mfilename ':tooManyInputs'],...
                           'Too many subscript indexing args (%g) given.',...
                           numel(subs));
                  end                  
               end
            otherwise
               [varargout{1:nargout}] = builtin('subsref',animalObj,S);
         end
      end
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
   end
   
   methods (Access = 'private') 
      % Callback for when a "child" Block is moved or otherwise destroyed
      function AssignNULL(animalObj,ind)
         % ASSIGNNULL  Does null assignment to remove a block of a
         %             corresponding index from the animalObj.Blocks
         %             property array, for example, if that Block is
         %             destroyed or moved to a different animalObj. Useful
         %             as a callback for an event listener handle.
         %
         %  animalObj.AssignNULL(ind);  Sets animalObj.Blocks(ind) = [];
         
         animalObj.Blocks(ind) = [];
      end
      
      % Ensure that there are not redundant Blocks in animalObj.Blocks
      % based on the .Name property of each member Block object
      function CheckBlocksForClones(animalObj)
         % CHECKBLOCKSFORCLONES  Creates an nBlock x nBlock logical matrix
         %                       comparing each Block in animalObj.Blocks
         %                       to the Name of every other such Block.
         %                       After subtracting the main diagonal of
         %                       this matrix, any row with redundant
         
         % If no Blocks, can't have clones
         if isempty(animalObj.Blocks)
            return;
         end
         
         % look for animals with the same name
         comparisons_cell = cellfun(... % check each element name against 
            @(s) strcmp(s,{animalObj.Blocks.Name}),... 
            {animalObj.Blocks.Name},... % all other elements
            'UniformOutput',false);     % return result in cells
         
         % Use upper triangle portion only, so that at least 1 member is
         % kept from any matched pair
         comparisons_mat = triu(cat(1,comparisons_cell{:}));
         rmvec = any(comparisons_mat,1);

         animalObj.Blocks(rmvec)=[];

      end
      
      % Callback for when the Animal name is changed, to update all "child"
      % block objects.
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
      % Static method to construct empty Animal object
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
      
      % Method invoked any time animalObj is loaded
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