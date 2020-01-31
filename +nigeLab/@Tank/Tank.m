classdef Tank < nigeLab.nigelObj
%TANK  Construct Tank Class object
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
%     Children - Array of handles to "Children" nigeLab.Animal objects
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
  
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES
   methods
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
            tankRecPath = '';
         end
         if nargin < 2
            tankSavePath = '';
         end
         tankObj@nigeLab.nigelObj('Tank',tankRecPath,tankSavePath,varargin{:}); 
         if isempty(tankObj) % Handle Empty case
            return;
         end
         if isstruct(tankRecPath) % Handle loadobj case
            return;
         end
         tankObj.addPropListeners();
         if ~tankObj.init
            error(['nigeLab:' mfilename ':initFailed'],...
               'Could not initialize TANK object.');
         end
         tankObj.Key = nigeLab.nigelObj.InitKey;
      end
      
   end
   
   % HIDDEN,PUBLIC
   methods (Hidden,Access=public)
      flag = init(tankObj)                 % Initializes the TANK object.
%       flag = genPaths(tankObj,tankPath) % Generate paths property struct
%       --> Deprecated (inherited from `nigelObj`)
%       flag = getSaveLocation(tankObj,saveLoc) % Prompt to set save dir
%       --> Deprecated (inherited from `nigelObj`)
%       removeAnimal(tankObj,ind) 
%       --> Deprecated (inherited from nigelObj)
   end

   % PROTECTED
   methods (Access=protected)
      % Modify inherited superclass name parsing method
      function [name,meta] = parseNamingMetadata(tankObj,fName,pars)
         %PARSENAMINGMETADATA  Parse metadata from file or folder name
         %
         %  name = PARSENAMINGMETADATA(animalObj);
         %
         %  --------
         %   INPUTS
         %  --------
         %   tankObj    :     nigeLab.Tank class object
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
            fName = tankObj.Input;
         end
         
         if nargin < 3
            pars = tankObj.getParams('Tank');
            if isempty(pars)
               tankObj.updateParams('Tank');
               pars = tankObj.Pars.Tank;
            end
         end
         
         % % % % Run supermethod@superclass % % % % %
         [name,meta] = parseNamingMetadata@nigeLab.nigelObj(...
            tankObj,fName,pars);
         
         % % % % Parse additional parameters for TANK % % % % 
         % Currently no fixed TANK naming convention.       %
         % % % % % % % % % % % % % % % % % % % % % % % % %  % 
         tankObj.Meta = nigeLab.nigelObj.MergeStructs(tankObj.Meta,meta);
      end
   end
   
   % PUBLIC
   methods (Access=public)
      % Returns the status of a operation/animal for each unique pairing
      function Status = getStatus(tankObj,operation,~)
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
            operation = tankObj.Fields;
            Status = getStatus(tankObj,operation);
            return;
         else
            % Ensure operation is a cell
            if ~iscell(operation)
               operation={operation};
            end
            % Check status from each animal
            Status = false(max(numel(tankObj.Children),1),numel(operation));
            for iAnimal = 1:numel(tankObj.Children)
               A = tankObj.Children(iAnimal);
               tmp =  A.getStatus(operation);
               if numel(operation)==1
                  tmp=all(tmp,2); 
               else
                  B = A.Children;
                  if ~isempty(B)
                      tmp = tmp | ~[B.IsMasked]';
                  end
               end
               Status(iAnimal,:) = all(tmp,1) | ~A.IsMasked;
            end
         end
      end

      % Method in case need to reset flags for GUI
      function resetGUI(tankObj)
         %RESETGUI  Method in case it is necessary to reset flags for GUI
         %
         %  tankObj.resetGUI();
         
         tankObj.GUI = [];
         tankObj.IsDashOpen = false;
         tankObj.SortGUI = [];
         for i = 1:numel(tankObj.Children)
            tankObj.Children(i).IsDashOpen = false;
            tankObj.Children(i).GUI = [];
            tankObj.Children(i).SortGUI = [];
            for k = 1:numel(tankObj.Children(i).Children)
               tankObj.Children(i).Children(k).IsDashOpen = false;
               tankObj.Children(i).Children(k).GUI = [];
               tankObj.Children(i).Children(k).SortGUI = [];
            end
         end
      end
      
      % Method in case need to reset tree paths manually
      function resetTreeManual(tankObj,skipSelection)
         %RESETTREEMANUAL  Brings up UI to manually refresh associated
         %  OUTPUT paths without completely going through the constructor 
         %  etc. This does not change any values of .Input, only values of
         %  .Out (and accordingly, .Output). It also refreshes (overwrites)
         %  existing .nigelObj files at the corresponding defined
         %  locations. Parsing works "down" the tree, starting with the
         %  Tank and then going through each Animal followed by its
         %  Children.
         %
         %  tankObj.resetTreeManual();
         %  --> Prompts selection of tankObj ID file from UI
         %
         %  tankObj.resetTreeManual(true);
         %  --> Use current ID file
         
         if nargin < 2
            skipSelection = false;
         end
         
         if skipSelection
            [p,~,f] = fileparts(tankObj.IDFile);
         else
            [f,p] = uigetfile({'.nigelTank','nigeLab Tank Files (.nigelTank)'},...
               'Select nigeLab Tank file',tankObj.IDFile);
            if f == 0
               nigeLab.sounds.play('pop',0.8);
               nigeLab.utils.cprintf('Comments','Tree reset canceled.\n');
               return;
            end
         end
         
         % This sets .Output:
         tankObj.IDFile = fullfile(p,f);
         tankObj.saveIDFile();
         F_an = dir(tankObj.Output);
         F_an = F_an([F_an.isdir]);
         iRemove = ismember({F_an.name},{'.','..'});
         F_an(iRemove) = [];
         nigeLab.utils.cprintf('Comments','Tank (%s) set.\n',tankObj.Name);
         nigeLab.utils.cprintf('Comments',...
            '->\tDetected %g Child Animals\n',numel(F_an));
         
         A = tankObj.Children;
         
         for i = 1:numel(F_an)
            iA = find(ismember({A.Name},F_an(i).name),1,'first');
            if isempty(iA)
               nigeLab.libs.cprintf('Text*','Could not match: %s\n',...
                  F_an(i).name);
               continue;
            end
            % This sets .Output:
            A(iA).IDFile = fullfile(tankObj.Output,...
               F_an(i).name,'.nigelAnimal');
            A(iA).saveIDFile();
            F_bl = dir(A(iA).Output);
            F_bl = F_bl([F_bl.isdir]);
            iRemove = ismember({F_bl.name},{'.','..'});
            F_bl(iRemove) = [];
            nigeLab.utils.cprintf('Strings','\tAnimal (%s) set.\n',...
               A(iA).Name);
            nigeLab.utils.cprintf('Strings',...
               '\t->\tDetected %g Child Blocks\n',numel(F_bl));
            
            B = A(iA).Children;
            for k = 1:numel(F_bl)
               iB = find(ismember({B.Name},F_bl(k).name),1,'first');
               if isempty(iA)
                  nigeLab.libs.cprintf('Text*','Could not match: %s\n',...
                     F_bl(k).name);
                  continue;
               end
               % This sets .Output:
               B(iB).IDFile = fullfile(A(iA).Output,...
                  F_bl(k).name,'.nigelBlock');
               B(iB).saveIDFile();
               nigeLab.utils.cprintf('Text*','\t\tBlock (%s) set.\n',...
                  B(iB).Name);
            end            
         end
         return;
      end
   end
   
   % STATIC
   methods (Static,Access=public)
      % Overloaded method to create Empty TANK object or array
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
   end
   
   % SEALED,PUBLIC
   methods (Sealed,Access=public)
%       setProp(tankObj,varargin) % Set property for Tank
%        --> Deprecated (inherits from nigelObj)
%       addAnimal(tankObj,animalPath,idx) % Add child Animals to Tank
%        --> Deprecated (inherits `addChild` from nigelObj)
%       flag = checkParallelCompatibility(tankObj);  
%        --> Deprecated (Inherited from nigelObj)
%       flag = linkToData(tankObj)           % Link TANK to data files on DISK
%       --> Deprecated (inherited from nigelObj)      
%       flag = updateParams(tankObj,paramType) % Update TANK parameters
%       --> Deprecated (inherited from nigelObj)
%       flag = updatePaths(tankObj,SaveLoc)    % Update PATHS to files
%       --> Deprecated (inherited from `nigelObj`)
%       flag = doRawExtraction(tankObj)  % Extract raw data from all Animals/Blocks
%       --> Deprecated (inherited from `nigelObj`)
%       flag = doReReference(tankObj)    % Do CAR on all Animals/Blocks
%       --> Deprecated (inherited from `nigelObj`)
%       flag = doLFPExtraction(tankObj)  % Do LFP extraction on all Animals/Blocks
%       --> Deprecated (inherited from `nigelObj`)
%       flag = doSD(tankObj)             % Do spike detection on all Animals/Blocks
%       --> Deprecated (inherited from `nigelObj`)
      blockList = list(tankObj)     % List Blocks in TANK    
      N = getNumBlocks(tankObj) % Get total number of blocks in TANK
      runFun(tankObj,f,varargin) % Run function f on all child blocks in tank
   end
   % % % % % % % % % % END METHODS% % %
end
