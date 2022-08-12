classdef Animal < nigeLab.nigelObj
% ANIMAL  Object that manages recordings from a single animal. These could be from the same session, or across multiple days.
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
%     Children - Array of nigeLab.Block objects
%
%     Probes - Electrode configuration structure
%
%     Mask - Channel "Mask" vector (for all recordings)
%     --> If nigeLab.defaults.Animal('UnifyChildMask') == true, then this
%         is designed to only allow for channels present on ALL recordings
%         (nigeLab.Block) of this animal.
%
%  ANIMAL Methods:
%     Animal - Class constructor
%
%     addChild - Add Blocks to Animal object
%
%     getStatus - Returns status of each Operation/Block pairing
%
%     save - Save 'animalObj' in [Name]_Animal.mat
%
%     Empty - Create an Empty ANIMAL object or array
   
   % % % PROPERTIES % % % % % % % % % %   
   % HIDDEN,PUBLIC/RESTRICTED:nigelObj
   properties (Hidden,GetAccess=public,SetAccess=?nigeLab.nigelObj)
      MultiAnimals logical = false           % flag to signal if it's a single animal or a joined animal recording
   end
   
   % HIDDEN,TRANSIENT,PUBLIC/RESTRICTED:nigelObj
   properties (Hidden,Transient,GetAccess=public,SetAccess=?nigeLab.nigelObj)
      MultiAnimalsLinkedAnimals  nigeLab.Animal % Array of "linked" animals
   end
   
   % SETOBSERVABLE,PUBLIC
   properties (SetObservable,Access=public)
      Probes     struct         % Electrode configuration structure
   end
   
   % SETOBSERVABLE,PUBLIC/RESTRICTED:nigelObj
   properties (SetObservable,GetAccess=public,SetAccess=?nigeLab.nigelObj)
      Mask       double        % Channel "Mask" vector (for all recordings)
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded methods)
   methods
      % Class constructor
      function animalObj = Animal(animalPath,animalSavePath,varargin)
         % ANIMAL  Create an animal object that manages recordings from a
         %           single animal. These could be from the same session,
         %           or across multiple days.
         %
         %  animalObj = nigeLab.Animal();
         %     --> prompts using UI
         %  animalObj = nigeLab.Animal(animalPath);
         %     --> animalPath can be [] or char array of animal location
         %  animalObj = nigeLab.Animal(animalPath,animalSavePath);
         %     --> animalSavePath can be [] or char array of tank location
         %        ( The folder that contains the animal output tree )
         %  animalObj = nigeLab.Animal(__,'PropName',propValue,...);
         %     --> set properties in the constructor
         
         if nargin < 1
            animalPath = '';
         end
         if nargin < 2
            animalSavePath = '';
         end
         animalObj@nigeLab.nigelObj('Animal',animalPath,animalSavePath,varargin{:});
         if isempty(animalObj) % Handle empty init case
            return;
         end
         if isstruct(animalPath) % Handle loadobj case
            return;
         end
         animalObj.addPropListeners();
         if ~animalObj.init()
            error(['nigeLab:' mfilename ':initFailed'],...
               'Could not initialize ANIMAL object.');
         end
         animalObj.Key = nigeLab.nigelObj.InitKey;
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
   end
   
   % PROTECTED
   methods (Access=protected)
      % Modify inherited superclass name parsing method
      function meta = parseNamingMetadata(animalObj,fName,pars)
         %PARSENAMINGMETADATA  Parse metadata from file or folder name
         %
         %  name = PARSENAMINGMETADATA(animalObj);
         %
         %  --------
         %   INPUTS
         %  --------
         %   animalObj    :     nigeLab.Animal class object
         %
         %   fName        :     (char array) Full filename of Input
         %
         %    pars      :     Pars struct with following fields:
         %                    --> 'VarExprDelimiter' (splits fName into 
         %                          chunks used for parsing variables)
         %                    --> 'DynamicVarExp' (char regular expression
         %                          that uses IncludeChar and ExcludeChar
         %                          to get the dynamic variable tokens to
         %                          keep or exclude)
         %                    --> 'IncludeChar' (char indicating you keep
         %                          that dynamically parsed variable)
         %                    --> 'ExcludeChar' (char indicating to discard
         %                          that dynamically parsed variable)
         %                    --> 'SpecialMeta' (struct containing a "list"
         %                          field, 'SpecialVars', which is a cell
         %                          array of other fieldnames. These are
         %                          all structs with the fields 'vars' and
         %                          'cat', which indicate which variables
         %                          should be stuck together and what
         %                          character to stick them together with)
         %                    --> 'NamingConvention' (cell array of char
         %                          arrays indicating how the parsed
         %                          dynamic variables should be stuck back
         %                          together in order to create Block name)
         %                    --> 'Concatenater' char used to concatenate
         %                          elements indicated by NamingConvention
         %
         %  --------
         %   OUTPUT
         %  --------
         %    name         :     Name of the obj
         %
         %    meta         :     Metadata struct parsed from name
         
         if nargin < 2
            fName = animalObj.Input;
         end
         
         if nargin < 3
            pars = animalObj.getParams('Animal');
            if isempty(pars)
               animalObj.updateParams('Animal');
               pars = animalObj.Pars.Animal;
            end
         end
         
         % % % % Run supermethod@superclass % % % % %
         meta = parseNamingMetadata@nigeLab.nigelObj(...
            animalObj,fName,pars);
         
         % % % % Parse additional parameters for ANIMAL % % % % 
         if isfield(meta,'SurgYear')
            % SurgYear -- 'R19' or 'M20' indicates model and year
            meta.ModelID = upper(meta.SurgYear(1));
         else
            meta.ModelID = 'X'; % Unknown
         end
         
         switch meta.ModelID
            case 'M'
               meta.AnimalType = 'Monkey';
            case 'R'   
               meta.AnimalType = 'Rat';
            otherwise
               meta.AnimalType = 'Rat?';
         end
         
         animalObj.Meta=nigeLab.nigelObj.MergeStructs(animalObj.Meta,meta);
      end
   end
   
   % PUBLIC
   methods (Access=public)
      % Returns Status for each Operation/Block pairing
      function flag = getStatus(animalObj,opField,~)
         % GETSTATUS  Returns Status Flag for each Operation/Block pairing
         %
         %  flag = animalObj.getStatus();
         %     --> Return true for any Fields element associated with a 
         %         "doOperation", when that "doOperation" has been
         %         completed for the corresponding element of
         %         animalObj.Children. 
         %        * if animalObj.Children is an array of 4 nigeLab.Block
         %          objects, and there are 9 "doOperation" Fields, then
         %          flag will return as a logical [4 x 9] matrix
         %
         %  flag = animalObj.getStatus(opField);
         %     --> Return status for specific "Operation" Fields (for each
         %         element of animalObj.Children)
         
         if nargin < 2
            opField = [];
         end
         if numel(animalObj) > 1
            flag = [];
            for i = 1:numel(animalObj)
               flag = [flag; getStatus(animalObj(i))]; %#ok<*AGROW>
            end
            return;
         end
         if isempty(animalObj)
            flag = false(1,numel(opField));
            return;
         end
         B = animalObj.Children;
         if numel(B)==0
            if isempty(opField)
               flag = false(1,numel(animalObj.Fields));
            else
               flag = false(1,numel(opField));
            end
         else
            flag = getStatus(B,opField);
         end
      end
   end
   
   % SEALED,PUBLIC
   methods (Sealed,Access=public)
      table = list(animalObj,keyIdx)        % List of recordings currently associated with the animal
      parseProbes(animalObj) % Parse probes from child BLOCKS
      flag = splitMultiAnimals(animalObj,varargin) % Split recordings that have multiple animals to separate recs
   end
   
   % HIDDEN,PUBLIC
   methods (Hidden,Access=public)      
      flag = doAutoClustering(animalObj,chan,multiBlock) % Runs spike autocluster

      N = getNumBlocks(animalObj); % Gets total number of blocks 
      mergeBlocks(animalObj,ind,varargin) % Concatenate two Blocks together  % -- Is it deprecated? (MM to FB 2020-Feb-01)
   end
    
   % PRIVATE 
   methods (Access=private)
      flag = init(animalObj)         % Initializes the ANIMAL object
   end
   
   % STATIC/PUBLIC
   methods (Static,Access=public)
      % Overloaded method to create Empty TANK object or array
      function animalObj = Empty(n)
         % EMPTY  Creates "empty" block or block array
         %
         %  animalObj = nigeLab.Animal.Empty();  % Makes a scalar Tank object
         %  animalObj = nigeLab.Animal.Empty(n); % Make n-element array Tank
         
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
   end
   
   % STATIC/PUBLIC/HIDDEN (testbench)
   methods (Static,Hidden,Access=public)
      % Method to test Protected methods
      function varargout = testbench(obj)
         %TESTBENCH  Static method for testing Protected methods
         
         varargout = cell(1,3);
         [varargout{1},varargout{2}] = obj.parseNamingMetadata();
         [varargout{3},varargout{4}] = obj.updateParams('check');
      end
   end
   % % % % % % % % % % END METHODS% % %
end