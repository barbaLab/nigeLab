classdef nigelObj < handle & ...
                    matlab.mixin.Copyable & ...
                    matlab.mixin.SetGet & ...
                    matlab.mixin.CustomDisplay
   %NIGELOBJ    Superclass of nigeLab data access objects
   %
   %  NIGELOBJ Properties:
   %     Status - Stores status of a given processing step.
   %     --> Struct with fields corresponding to
   %         <strong>obj.Fields</strong>.
   %     --> Number of elements of each field depends on the corresponding
   %         <strong>obj.FieldType</strong>.
   %     --> Fields that have had an extraction step completed are updated
   %         to true; `checkActionIsValid` makes use of this and
   %         pre-defined relationships between the `doMethods` in the
   %         processing pipeline to ensure that invalid processing steps
   %         are not performed.
   %
   %     IsMasked - Logical flag: true == "enabled"
   %
   %     Name - Name of obj (char array)
   %
   %     FieldType - Categorizes each 'Fields' element as one of the following
   %        * 'Channels'  --  Fields belong to each Recording Channel
   %        * 'Streams'  --  Data is streamed independently of recording chans
   %        * 'Events'  --  Parsed events independent of recording channels
   %        * 'Videos'  --  Array of objects for associated videos
   %        * 'Meta'  --  Metadata about the recording, such as Header info
   %
   %     Fields - Specific elements, such as 'Raw Data' (Raw) to be collected
   %
   %     Pars - Parameters struct
   %
   %     Status - Processing "progress" of each Fields (true: completed)
   %
   %     UserData - Property to store user-defined data
   %
   %  NIGELOBJ Methods:
   %     nigelObj - Class constructor
   %        --> nigelObj is derived from the following superclasses:
   %           * handle
   %           * matlab.mixin.Copyable
   %           * matlab.mixin.CustomDisplay
   %           * matlab.mixin.SetGet
   %
   %     Empty - Create an Empty NIGELOBJ object or array
   
   % % % PROPERTIES % % % % % % % % % %
   % PUBLIC
   properties (Access=public)
      Meta     (1,1)   struct      % Metadata struct
      UserData                     % Allow UserData property to exist
   end

   % PUBLIC/PROTECTED
   properties (GetAccess=public,SetAccess=protected)
      Fields            cell                    % Specific things to record
      FieldType         cell                    % "Types" corresponding to Fields elements
      Name              char           % Name of the obj (char array)
      ViableFieldTypes  cell
      IDInfo      (1,1) struct                  % Struct parsed from ID file
      HasParsFile (1,1) logical=false           % Flag --> True if _Pars.mat exists
      HasParsInit (1,1) struct                  % Flag struct --> .param is True if obj.updateParams('param') has been run
      HasParsSaved(1,1) struct                  % Flag struct --> .Param is True if that field has been saved to pars file since load
      UseParallel       logical                 % Flag indicating parallel processing compatible
   end

   % CONSTANT,PROTECTED
   properties (Constant,Access=protected)
      FileExpr         char = '_%s.mat'     % Expression for _Block or _Animal or _Tank file
      ParamsExpr       char = '%s_Pars.mat' % Expression for parameters file
        % Valid entries for 'Fields'
   end
   
   % DEPENDENT,PUBLIC
   properties (Dependent,Access=public)
      File              char           % Full file of _Block.mat, _Animal.mat, or _Tank.mat file
      FolderIdentifier  char           % '.nigelBlock', '.nigelAnimal', or '.nigelTank'
      Input             char           % Path to input file or folder
      OnRemote    (1,1) logical        % Is this object running a job on remote worker?
      Output            char           % Path to output folder (same as .Paths.SaveLoc)
      Pars        (1,1) struct         % Parameters struct
      %Paths       (1,1) struct         % Detailed paths specifications
      ShortFile         char           % Shortened filename
      Type              char           % 'Block', 'Animal' or 'Tank'
      User              char           % Current user
      Version           char='unknown' % Version of most-recent release.
   end
   
   % DEPENDENT,PUBLIC/PROTECTED
   properties (Dependent,GetAccess=public,SetAccess=protected)
      Duration    char   % Duration (%02g hours, %02g mins, %02g sec)
   end
   
   % DEPENDENT,HIDDEN,PROTECTED (Old properties go here)
   properties (Dependent,Hidden,Access=protected)
      FileExt    char                     % .rhd, .rhs, or other (for this recording) -- Block only
      RecType    char                     % Intan / TDT / other
      KeyPair                             % (struct) .Public, .Private random alphanumeric id
      RecSystem                           % (nigeLab.utils.AcqSystem) 'RHS', 'RHD', or 'TDT' (must be one of those)
end
   
   % DEPENDENT,HIDDEN,PUBLIC
   properties (Dependent,Hidden,Access=public)
      IDFile      char        % .nigelType folder ID file name
      InDef       char        % Default input location
      InPrompt    char        % To print for input path prompts
      OutDef      char        % Default output location
      OutPrompt   char        % To print for output path prompts
   end
   
   % DEPENDENT,TRANSIENT,PUBLIC (GUI)
   properties (Dependent,Hidden,Transient,Access=public)
      GUI         nigeLab.libs.DashBoard   % Handle to nigeLab.libs.DashBoard GUI (nigelObj.nigelDash method)
      SortGUI     nigeLab.Sort   % Handle to nigeLab.Sort GUI (nigelObj.Sort method)
   end
   
   % DEPENDENT,TRANSIENT,SETOBSERVABLE,PUBLIC (Children Objects)
   properties (Dependent,Transient,SetObservable,Access=public)
      Children                % Array of "child" objects
      Parent
   end
   
   % HIDDEN,ABORTSET,SETOBSERVABLE,PUBLIC (Flags)
   properties (Hidden,AbortSet,SetObservable,Access=public)
      InBlindMode(1,1)logical = false  % True if "blind mode" is activated
      IsEmpty    (1,1)logical = false  % True if no data in this (e.g. Empty() method used)
      IsMasked   (1,1)logical = true   % true --> obj is "enabled"
   end
   
   % HIDDEN,TRANSIENT,ABORTSET,PUBLIC (Flags)
   properties (Hidden,Transient,AbortSet,Access=public)
      IsDashOpen (1,1)logical         % Is nigeLab.libs.DashBoard GUI open?
      PathIsSet  (1,1)logical = false % Has temporary environment path been set?
      RemoteFlag (1,1)logical = false % "Container" for .OnRemote prop
      Verbose    (1,1)logical = false % Display debug output?
   end
   
   % HIDDEN,TRANSIENT,PUBLIC (Listeners and Object "Containers")
   properties (Hidden,Transient,Access=public)
      ParentContainer                           % Container for .Parent Dependent property
      ChildContainer                            % Container for .Children Dependent property
      ChildListener     event.listener          % Listens for changes in object Children
      GUIContainer      nigeLab.libs.DashBoard  % Container for handle to GUI (nigeLab.libs.DashBoard)
      TreeNodeContainer                         % Container for handle to Tree nodes in the nigelTree obj
      ParentListener    event.listener          % Listens for changes in object Parent
      PropListener      event.listener          % Listens for changes in properties of this object
      SortGUIContainer  nigeLab.Sort            % Container for handle to Spike Sorting GUI (nigeLab.Sort)
   end
   
   % HIDDEN,PUBLIC (Index)
   properties (Hidden,GetAccess=public,SetAccess=public)
      Index                            % [a] or [a,b] --> tankObj.Children(a).Children(b)
   end

   % HIDDEN,PROTECTED
   properties (Hidden,Access=protected)
      AcqSystem    nigeLab.utils.AcqSystem % 'RHS', 'RHD', or 'TDT' (must be one of those)
      In     (1,1) struct                  % Input  (folder tree or recording file/dir) paths
      Out    (1,1) struct = struct('SaveLoc',[],'Folder',[],'File',[],'Pars',[],'NigelFile',[]);                 % Output (folder tree) paths      
      Key    (1,1) struct = nigeLab.nigelObj.InitKey()   % Fields are "public" and "private" (reserved for later)
      Params (1,1) struct = struct('Pars',struct,'Paths',struct,'Type','') % Holds dependent properties
      UserContainer char                   % "Container" for username
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % EVENTS % % % % % % % % % % % %
   % PUBLIC
   events (ListenAccess=public,NotifyAccess=public)
      DashChanged      % Interactions with nigeLab.libs.DashBoard
      ProgressChanged  % Issued as `doMethod` proceeds
      StatusChanged    % Issued when a Field is updated
      ChildAdded       % Issued when a child is added through the addchild method
   end
   % % % % % % % % % % END EVENTS % % %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded methods)
   methods
      % nigeLab.nigelObj Superclass Constructor
      function obj = nigelObj(Type,inPath,savePath,varargin)
         %NIGELOBJ  Superclass constructor to point to files
         %
         %  obj = nigeLab.nigelObj(Type);
         %  --> At minimum, superclass constructor must be given .Type
         %
         %  obj = nigeLab.nigelObj(Type,inPath);
         %  --> Specifies the folder or filename of input data
         %
         %  obj = nigeLab.nigelObj(Type,inPath,savePath);
         %  --> Specifies the folder tree location of output data. This is
         %      a folder that will contain the _Block or _Animal or _Tank
         %      matfile, which is one level above the actual "Block" or
         %      "Animal" or "Tank" folders (which contain the .nigelBlock,
         %      .nigelAnimal, or .nigelTank file respectively).
         %
         % # Usage #
         %
         % ## Example 1: For a tank 'myTank' ##
         %
         % >> inPath = '//kumc.edu/recorded/myTank;'
         % >> savePath = '//kumc.edu/processed/myData';
         % >> myTank = nigeLab.Tank(inPath,savePath);
         %
         % ### Output ###
         %
         % --> myTank.IDFile:
         %     * '//kumc.edu/processed/myData/myTank/.nigelTank'
         % --> myTank.SaveLoc:
         %     * '//kumc.edu/processed/myData'
         % --> myTank.Input == myTank.RecDir:
         %     * '//kumc.edu/recorded/myTank'
         % --> myTank.Output:
         %     * '//kumc.edu/processed/myData/myTank'
         %
         % ## Example 2: For a block 'myBlock' ##
         %
         % >> blockPath = ...
         %    '//kumc.edu/recorded/myTank/R20-001/R20-001_data-A_0.rhd';
         % >> blockSavePath = ...
         %    '//kumc.edu/processed/myData/myTank/R20-001;
         % >> myBlock = nigeLab.Block(blockPath,blockSavePath);
         %  
         % ### Output ###
         %  
         % --> myBlock.IDFile:
         %     * '//kumc.edu/processed/myData/myTank/R20-001/.nigelBlock'
         % --> myBlock.SaveLoc:
         %     * '//kumc.edu/processed/myData/myTank/R20-001'
         % --> myBlock.Input == myBlock.RecFile:
         %     * '//kumc.edu/processed/myData/myTank/R20-001_data-A_0.rhd'
         % _Note: myBlock.Output depends upon how name parsing is
         %  set up in +nigeLab/+defaults/Block.m_
         %
         % --> myBlock.Output:
         %     * '//kumc.edu/processed/myData/myTank/R20-001/R20-001_0'
         %       + Note that '_data-A' is dropped from .Output
         %       + This would be the case given the following setup:
         %        >> pars.DynamicVarExp = ...
         %           {'$SurgYear','$SurgID','~Const','$Tag','$RecID'}
         %        >> pars.VarExprDelimiter = {'-','_'};
         %        >> pars.Concatenater = '_';
         %        >> pars.IncludeChar = '$';
         %        >> pars.DiscardChar = '~';
         %        >> pars.SpecialMeta.SpecialVars = {'AnimalID'};
         %        >> pars.SpecialMeta.AnimalID.vars = {'SurgYear','SurgID'}
         %        >> pars.SpecialMeta.AnimalID.cat = '-';
         %        >> pars.NamingConvention = {'AnimalID', 'RecID'};
         %  
         %        + blockObj.parseNamingMetadata will make extract a name:
         %           1. Name will be parsed from the filename part of
         %              myBlock.RecFile, resulting in:
         %              >> 'R20-001_data-A_0'
         %              
         %           2. Name is split into tokens using
         %              pars.VarExprDelimiter, resulting in 4 "variables":
         %              >> {'R20','001','data','A','0'}
         %
         %           3. Variable data is assigned to fields using
         %              pars.DynamicVarExp, resulting in a metadata struct:
         %              >> meta.SurgYear = 'R20' [kept due to '$' char]
         %              >> meta.SurgID = '001' [kept due to '$' char]
         %              >> x meta.Const = 'data' [removed due to '~' char]
         %              >> meta.Tag = 'A' [kept due to '$' char]
         %              >> meta.RecID = '0' [kept due to '$' char]
         %
         %           4. From this expression, using pars.SpecialMeta,
         %              'AnimalID' field of meta struct is parsed also
         %              >> meta.AnimalID = 'R20-001'
         %
         %              _note that pars.SpecialMeta.AnimalID.cat = '-',
         %                 which sticks together the variables listed in
         %                 pars.SpecialMeta.AnimalID.vars ('SurgYear' and
         %                 'SurgID')_
         %
         %              _note that no other SpecialMeta is formed this way,
         %                 as only the only pars.SpecialMeta.SpecialVars
         %                 element is 'AnimalID'_
         %
         %           5. Finally, myBlock.Name is parsed using
         %              pars.NamingConvention ({'AnimalID', 'RecID'}) and
         %              pars.Concatenater
         %              >> myBlock.Name = 'R20-001_0'
         %
         %           6. Thus, myBlock.Output is the combination:
         %              >> myBlock.Output = ...
         %                    fullfile(myBlock.SaveLoc,myBlock.Name);
         %
         %           7. Because we specified '$Tag' and not '~Tag', our
         %              metadata struct (myBlock.Meta) still has 
         %              >> myBlock.Meta.Tag = 'A'
         %              It is just not used due 'Tag' not being in the
         %              variables listed for pars.NamingConvention
         %  ---
         %
         %  # <Name, value> Syntax #
         %
         %  <'Name',value> input pair lists are accepted if all other
         %  inputs are given (to skip, specify an input as []). To set a
         %  particular .Pars property field, specify 'Name' using the
         %  syntax:
         %
         %  >> '$ParsField.ParamName'  
         %  e.g. For obj.Pars.Block.NamingConvention, use
         %  >> '$Block.NamingConvention'
         %
         %  obj = nigeLab.nigelObj(___,'PropName1',PropVal1,...);
         %  --> allows specification of properties in constructor
         %
         %  obj = nigeLab.nigelObj(__,'$ParsField.ParamName',paramVal);
         %  --> sets value of obj.Pars.(ParsField).(ParamName) to paramVal
         
         % Add nigeLab to search path
         if isunix
            if ~contains(path,nigeLab.utils.getNigelPath('UNC'))
               addpath(nigeLab.utils.getNigelPath('UNC'));
            end
         else
            if ~contains(path,nigeLab.utils.getNigelPath)
               addpath(nigeLab.utils.getNigelPath);
            end
         end
         
         % Check inputs
         if nargin < 1 % Must include Type
            error(['nigeLab:' mfilename ':TooFewInputs'],...
               'nigelObj superclass constructor requires at least Type');
         elseif ~ismember(Type,{'Block','Animal','Tank'}) % Must be Valid
            error(['nigeLab:' mfilename ':BadString'],...
             ['''%s'' is not an expected value of .Type \n'...
             '\t(Should be: ''Block'' or ''Animal'' or ''Tank'')\n'],Type);
         end
         
         if nargin < 2
            inPath = '';
         end
         
         if nargin < 3
            savePath = '';
         end
         
         obj.Type = Type;
         obj.ViableFieldTypes = nigeLab.nigelObj.Default('ViableFieldTypes');
         obj.FieldType        = nigeLab.nigelObj.Default('FieldType');
         obj.Fields           = nigeLab.nigelObj.Default('Fields');
         % Construct Empty output
         if isnumeric(inPath)
            dims = inPath;
            if isempty(dims)
               dims = [0 0];
            end
            obj.IsEmpty = true;
            obj = repmat(obj,dims);
            for i = 1:dims(1)
               for k = 1:dims(2)
                  % Make sure they aren't just all the same handle
                  obj(i,k) = copy(obj(1,1));
               end
            end
            if all(inPath ~= 0) && any(~obj.updateParams('init'))
                error(['nigeLab:' mfilename ':BadInit'],...
                    'Could not properly initialize parameters.');
            end
            return;
         end
         
         % Deal with parsing <'Name',value> pairs
         for iV = 1:2:numel(varargin) 
            if ~ischar(varargin{iV})
               continue;
            end
            if strcmp(varargin{iV}(1),'$')
               obj.assignPars(varargin{iV}(2:end),varargin{iV+1});
            else
               % Check to see if it matches any of the listed properties
               set(obj,varargin{iV},varargin{iV+1});
            end
         end
         
         % Check for input passed via subclass constructor
         if isstruct(inPath) % Then this came from loadobj
            obj_ = inPath;
            inPath = '';
            
            % Convert struct to correct class
            f = fieldnames(obj_);
            mc = metaclass(obj);
            p = mc.PropertyList;
            mcp = {p.Name};
            props2set = intersect(f,mcp);
            if ismember('Name',props2set) % Make sure this is added first
               obj.Name = obj_.Name;
               props2set = setdiff(props2set,'Name');
            end
            if ismember('Pars',props2set)
               initPars = obj.listInitializedParams();
               f = fieldnames(obj_.Pars);
               wrongInit = setdiff(initPars,f);
               for iW = 1:numel(wrongInit)
                  obj.HasParsInit.(wrongInit{iW}) = false;
               end
            end
            for i = 1:numel(props2set)
               thisProp = props2set{i};
               idx = ismember(mcp,thisProp);
               if ~p(idx).Constant
                  obj.(props2set{i}) = obj_.(props2set{i});
               end
            end
            switch obj.Type
               case 'Block'
                  if isfield(obj.Paths,'RecFile')
                     obj.Input = obj.Paths.RecFile;
                  end
               case {'Animal','Tank'}
                  if isfield(obj.Paths,'RecDir')
                     obj.Input = obj.Paths.RecDir;
                  end
            end
            return; % Skip .updateParams('init')
         elseif ~(ischar(inPath) && ischar(savePath))
            error(['nigeLab:' mfilename ':BadClass'],...
               'Both inPath and savePath must be `char`');
         end
         
         % Initialize parameters
         if any(~obj.updateParams('init'))
            error(['nigeLab:' mfilename ':BadInit'],...
               'Could not properly initialize parameters.');
         end
         % Handle I/O path specifications
         if ~obj.parseInputPath(inPath)
            nigeLab.utils.cprintf('Errors*',...
               '[constructor canceled]: Input file/folder not given\n');
            return;
         end
         if ~obj.parseSavePath(savePath)
            nigeLab.utils.cprintf('Errors*',...
               '[constructor canceled]: Output file/folder not given\n');
            return;
         end
      end
      
      % Make sure listeners are deleted when obj is destroyed
      function delete(obj)
         % DELETE  Ensures listener handles are properly destroyed
         %
         %  delete(obj);
         
         if isempty(obj)
            return;
         end
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               delete(obj(i));
            end
            return;
         end
         
         % Destroy any associated "property listener" handles
         if ~all(isempty(obj.PropListener))
            for i = 1:numel(obj.PropListener)
               if isvalid(obj.PropListener(i))
                  delete(obj.PropListener(i));
               end
            end
         end
         
         % Destroy any associated Listener handles
         if ~all(isempty(obj.ParentListener))
            for lh = obj.ParentListener
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
         
         % Destroy any associated Block Listener handles
         if ~all(isempty(obj.ChildListener))
            for lh = obj.ChildListener
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
         
         % Destroy all child objects
         if ~all(isempty(obj.ChildContainer))
            for i = 1:numel(obj.ChildContainer)
               if isvalid(obj.ChildContainer(i))
                  delete(obj.ChildContainer(i));
               end
            end
         end
         
         if ~isempty(obj.TreeNodeContainer)
             delete(obj.TreeNodeContainer);
         end
         
         if ~isempty(obj.GUI)
            if isvalid(obj.GUI)
               delete(obj.GUI);
            end
         end
      end
      
      % Overload to 'isempty'
      function tf = isempty(obj)
         % ISEMPTY  Returns true if .IsEmpty is true or if builtin isempty
         %          returns true. If obj is array, then returns an
         %          array of true or false for each element of obj.
         %
         %  tf = isempty(obj);
         
         if numel(obj) == 0
            tf = true;
            return;
         end
         
         if ~isscalar(obj)
            tf = false(size(obj));
            for i = 1:numel(obj)
               tf(i) = isempty(obj(i));
            end
            return;
         end
         if isvalid(obj)
            tf = obj.IsEmpty || builtin('isempty',obj);
         else
            tf = false;
         end
      end
      
      function n = numArgumentsFromSubscript(nigelObj,s,indexingContext)
          % NUMARGUMENTSFROMSUBSCRIPT  Parse # args based on subscript type
          %
          %  n = blockObj.numArgumentsFromSubscript(s,indexingContext);
          %
          %  s  --  struct from SUBSTRUCT method for indexing
          %  indexingContext  --  matlab.mixin.util.IndexingContext Context
          %                       in which the result applies.
          
          switch s(1).type
              case '{}'
                  switch class(nigelObj)
                      case {'nigeLab.Tank','nigeLab.Animal'}
                          n = 1;
                      case 'nigeLab.Block'
                          n = numel(nigelObj);
                      otherwise
                          n = builtin('numArgumentsFromSubscript',nigelObj,s,indexingContext);
                  end
              case '.'
                  meta = metaclass(nigelObj);
                  methods = meta.MethodList;
                  methodIdx = strcmp({methods.Name},s(1).subs);
                  if any(methodIdx)
                      thisMethod = methods(methodIdx);
                      n = numel(thisMethod.OutputNames);
                  else
                      switch class(nigelObj)
                          case 'nigeLab.Block'
                              if ~isempty(nigelObj(1).Pars)
                                  Ffields = nigelObj(1).Pars.Block.Fields;
                                  idx = strcmpi(Ffields,s(1).subs);
                                  if any(idx)
                                      n = numel(nigelObj);
                                  else
                                      n = builtin('numArgumentsFromSubscript',nigelObj,s,indexingContext);
                                  end
                              else
                                  n = builtin('numArgumentsFromSubscript',nigelObj,s,indexingContext);
                              end
                          otherwise
                              n = builtin('numArgumentsFromSubscript',nigelObj,s,indexingContext);
                      end
                  end
              otherwise
                  n = builtin('numArgumentsFromSubscript',nigelObj,s,indexingContext);
          end
      end
      
      % % % (DEPENDENT) GET/SET.PROPERTY METHODS % % % % % % % % % % % %
           
      % [DEPENDENT]  .Children (handles Empty case)
      function value = get.Children(obj)
         %GET.CHILDREN Get method for .Children (handles Empty case)
         %
         %  value = get(obj,'Children');
         %  --> Returns appropriate Empty array of correct subclass if no 
         %      Children in obj.C container array
         
         value = [];
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         value = obj.ChildContainer;
         if all(isempty(value))
            switch obj.Type
               case 'Block'
                  value = [];
               case 'Animal'
                  value = nigeLab.Block.Empty();
               case 'Tank'
                  value = nigeLab.Animal.Empty();
               otherwise
                  warning('Unrecognized obj.Type: ''%s''\n',obj.Type);
                  value = []; 
            end
         end
      end
      function set.Children(obj,value)
         %SET.CHILDREN  Set method for .Children property (Index)
         %
         %  set(obj,'Children',value);
         %  --> Updates value.Index for each handle in value
         
         if all(isempty(value))
            obj.ChildContainer(:) = [];
            return;
         end
         obj.ChildContainer = value;
         obj.setChildIndex; % Sets Index based on Parent Index
      end
      
            % [DEPENDENT]  .Children (handles Empty case)
      function value = get.Parent(obj)
         %GET.PARENT Get method for .Parent (handles Empty case)
         %
         %  value = get(obj,'Parent');
         %  --> Returns appropriate Empty array of correct subclass if no 
         %      Children in obj.C container array
         
         value = [];
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         value = obj.ParentContainer;
         if all(isempty(value))
            switch obj.Type
               case 'Block'
                  value = nigeLab.Animal.Empty();
               case 'Animal'
                  value = nigeLab.Tank.Empty();
               case 'Tank'
                  value = [];
               otherwise
                  warning('Unrecognized obj.Type: ''%s''\n',obj.Type);
                  value = []; 
            end
         end
      end
      function set.Parent(obj,value)
         %SET.CHILDREN  Set method for .Children property (Index)
         %
         %  set(obj,'Children',value);
         %  --> Updates value.Index for each handle in value
         
         if all(isempty(value))
            obj.ParentContainer(:) = [];
            return;
         end
         obj.ParentContainer = value;
      end
      
      
      % [DEPENDENT]  .Duration
      function value = get.Duration(obj)
         %GET.DURATION  Returns a time string of the duration of recording
         %
         %  value = get(obj,'Duration');
         
         value = 'Empty';
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         
         if ~isempty(obj.SampleRate) && ~isempty(obj.Samples)
            nSec = obj.Samples / obj.SampleRate;
            [~,~,value] = nigeLab.utils.sec2time(nSec);
         else
            value = 'Unknown';
         end
      end
      function set.Duration(~,~)
         %SET.DURATION  Duration is only set by .Samples and .SampleRate
      end
      
      % [DEPENDENT]  .File (_Obj.mat)
      function value = get.File(obj)
         %GET.FILE  Returns _Obj.mat file as char array
         %
         %  value = get(obj,'File');
         %  e.g '/c/path/tank/.nigelTank'
         
         value = 'Empty';
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         value = obj.Out.File;
         if isempty(value)
            dbstack;
            [fmt,idt,type] = obj.getDescriptiveFormatting();
            if isempty(obj.Name)
               nigeLab.utils.cprintf(fmt,...
                  '%s[GET.FILE]: Unknown %s .File is missing\n',...
                  idt,type);
               nigeLab.utils.cprintf(fmt(1:(end-1)),...
                  '\t%s(Could not parse .Name property)\n',idt);
            else
               nigeLab.utils.cprintf(fmt,...
                  '%s[GET.FILE]: %s (%s) .File is missing\n',...
                  idt,obj.Name,type);
               nigeLab.utils.cprintf(fmt(1:(end-1)),...
                  '\t%s(Could not get .SaveLoc path)\n',idt);
            end
         end
      end
      function set.File(obj,value)
         %SET.FILE  Sets _Obj.mat file info
         %
         %  set(obj,'File','/c/path/tank/.nigelTank');
         %  --> obj.FolderIdentifier is now set as '.nigelTank'
         %  --> obj.Output is now set as '/c/path/tank'
%          
%          if isempty(value)
%             return;
%          end
%          if ~ischar(value)
%             return;
%          end
%          [path,f,e]=fileparts(value);
%          fparts = strsplit(f,'_');
%          
%          if ismember(fparts{end},{'Block','Animal','Tank'})
%             obj.Type = fparts{end};
%             obj.Output = path;
%          else
%             p = nigeLab.utils.shortenedPath(path);
%             nigeLab.utils.cprintf('Errors*',...
%                '[SET.FILE]: Bad File name (%s%s)\n',p,[f e]);
%             return;
%          end
         
      end
      
      % [DEPENDENT]  .FolderIdentifier (.nigelFile file name (no path))
      function value = get.FolderIdentifier(obj)
         %GET.FOLDERIDENTIFIER  Returns .nigel[Type] char array
         %
         %  value = get(obj,'FolderIdentifier');
         %  --> value is either '.nigelBlock', '.nigelAnimal', or
         %                      '.nigelTank'
         
         if isempty(obj.Type)
            value = '.nigelFile';
            return;
         end
         value = sprintf('.nigel%s',obj.Type);
      end
      function set.FolderIdentifier(obj,value)
         %SET.FOLDERIDENTIFIER  Sets .nigelFile char array
         %
         %  set(obj,'FolderIdentifier','.nigelTank');
         %  --> Set folder identifier for 'Tank' type nigelObj
         
         if isempty(value)
            return;
         elseif ~ischar(value)
            return;
         end
         value = strrep(value,'.nigel','');
         if ismember(value,{'Block','Animal','Tank'})
            set(obj,'Type',value);
         end
      end
      
      % [DEPENDENT]  .FileExt (recording file type)
      function value = get.FileExt(obj)
         %GET.FILEEXT  Returns char array of file extension
         %
         %  >> value = get(obj,'FileExt');
         %  --> assign obj.In.FileExt to value
         
         value = 'Unknown';
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         
         if ismember(obj.Type,{'Tank','Animal'})
            value = '';
            return;
         end
         
         if ~isfield(obj.In,'FileExt')
            if isfield(obj.In,'Block')
               [~,~,obj.In.FileExt] = fileparts(obj.In.Block);
            else
               value = '';
               return;
            end
         end
         
         p = obj.getParams('Experiment');
         if isempty(p)
            obj.updateParams('Experiment');
            p = obj.getParams('Experiment');
            if isempty(p)
               value = '';
               return;
            end
         end
         
         if ~isfield(p,'SupportedFormats')
            obj.updateParams('Experiment','Direct');
            p = obj.getParams('Experiment');
         end
         
         if ismember(obj.In.FileExt,p.SupportedFormats)
            value = obj.In.FileExt;
         else
            if isfield(obj.IDInfo,'FileExt')
               obj.In.FileExt = obj.IDInfo.FileExt;
               value = obj.In.FileExt;
            else
               loadIDFile(obj);
               if isfield(obj.IDInfo,'FileExt')
                  obj.In.FileExt = obj.IDInfo.FileExt;
                  value = obj.In.FileExt;
               end
            end
         end
         
      end
      function set.FileExt(obj,value)
         %SET.FILEEXT  Sets _Obj.mat file info
         %
         %  >> set(obj,'FileExt','.rhs');
         %  --> obj.In.FileExt = '.rhs'
         
         if ismember(obj.Type,{'Tank','Animal'})
            return;
         end
         if isempty(value)
            return;
         end
         if ~ischar(value)
            return;
         end
         obj.In.FileExt = value;
      end
      
      % [DEPENDENT]  .GUI (handle to nigelDash)
      function value = get.GUI(obj)
         %GET.GUI  Returns handle to nigeLab.libs.DashBoard object
         %
         %  value = get(obj,'GUI');
         
         value = [];
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         
         if ~isempty(obj.GUIContainer)
            if isvalid(obj.GUIContainer)
               value = obj.GUIContainer;
            end
         end
      end
      function set.GUI(obj,value)
         %SET.GUI  Sets handle to nigeLab.libs.DashBoard object
         %
         %  set(obj,'GUI',value);
         
         if isempty(value)
            if ~isempty(obj.GUIContainer)
               obj.GUIContainer = nigeLab.libs.DashBoard.empty();
            end
            obj.IsDashOpen = false;   % Set flag to false
         else
            if obj.IsDashOpen % It is already open; no need to assign
               if isvalid(value)
                  if isprop(value,'nigelGUI')
                     figure(value.nigelGUI); % Make sure figure is focused
                     obj.GUIContainer = value; % Store association to handle object
                  else
                     [fmt,idt,type] = obj.getDescriptiveFormatting();
                     nigeLab.utils.cprintf(fmt,'%s[NIGELOBJ/SET.GUI]: ',...
                        idt);
                     nigeLab.utils.cprintf(fmt(1:(end-1)),...
                        'Invalid GUI assignment (%s %s)\n',type,obj.Name);
                  end
               end
            else % Otherwise it is not open
               flag = isvalid(value);
               if ~flag
                  value = nigeLab.libs.DashBoard.empty();
               end
               % Store association to handle object
               obj.GUIContainer = value; 
               % Set .IsDashOpen AFTER setting obj.GUIContainer
               obj.IsDashOpen = flag;
%                return;
            end
         end
         
         setChildProp(obj,'GUI',value);
      end
      
      % [DEPENDENT]  .IDFile (full .nigelFile name depends on .Type)
      function value = get.IDFile(obj)
         %GET.IDFile  Make sure it exists first, then return it
         %
         %  value = get(obj,'IDFile');
         
         value = '';
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         if isempty(obj.FolderIdentifier)
            fname = ['.nigel' obj.Type];
            obj.FolderIdentifier = fname;
         else
            fname = obj.FolderIdentifier;
         end
         if isempty(fname)
            return;
         end
         
         if isempty(obj.Output)
            if ~isempty(obj.Name) && isfield(obj.Out,'SaveLoc')
               if ~isempty(obj.Out.SaveLoc)
                  outPath = fullfile(obj.Paths.SaveLoc,obj.Name);
                  obj.setOutputPath(outPath,true); % "Force" set
                  value = fullfile(outPath,fname);
               end
            end
         else
            value = fullfile(obj.Out.Folder,fname);
         end
      end
      function set.IDFile(obj,value)
         %SET.IDFile  Set method for .IDFile READ-ONLY property
         %
         %  >> set(obj,'IDFile',fullfile(pwd,'.nigelAnimal'));
         
         if isempty(value)
            return;
         end
         if ~ischar(value)
            return;
         end
         [obj.Output,~,obj.FolderIdentifier] ...
            = fileparts(value);
         type = strrep(obj.FolderIdentifier,'.nigel','');
         obj.Type = type;        
         
      end
      
      % [DEPENDENT]  .InDef (default input location)
      function value = get.InDef(obj)
         %GET.INDEF  Default input location (char array)
         %
         %  value = get(obj,'InDef');
         
         value = pwd;
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         if isfield(obj.In,'Default')
            value = obj.In.Default;
            return;
         end
         
         value = obj.getParams(obj.Type,'DefaultRecLoc');
         if ~isempty(value)
            obj.In.Default = value;
            return;
         end
         obj.updateParams(obj.Type);
         value = obj.getParams(obj.Type,'DefaultRecLoc');
         obj.In.Default = value;
      end
      function set.InDef(obj,value)
         %SET.INDEF  Default output location (char array)
         %
         %  set(obj,'InDef',value);
         
         obj.In.Default = value;
      end
      
      % [DEPENDENT]  .InPrompt (prompt for input file or folder)
      function value = get.InPrompt(obj)
         %GET.INPROMPT  Header prompt for input file or folder selection
         %
         %  value = get(obj,'InPrompt');
         
         value = 'Select INPUT folder';
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         switch obj.Type
            case 'Block'
               value = '[input] BLOCK file or indicator'; 
            case 'Animal'
               value = '[input] ANIMAL folder that contains BLOCKS';
            case 'Tank'
               value = '[input] TANK folder that contains ANIMALS';
            otherwise
               error(['nigeLab:' mfilename ':BadType'],...
                  'nigelObj has bad Type (%s)',obj.Type);
         end
      end
      function set.InPrompt(~,~)
         %SET.INPROMPT  Does nothing probably
         %
         %  set(obj,'InPrompt',value);
         
         warning('Cannot set `.InPrompt` (Dependent) property');
      end
      
      % [DEPENDENT]  .Input (input data file or folder depends on .Type)
      function value = get.Input(obj)
         %GET.INPUT  Input file or folder location
         %
         %  value = get(obj,'Input');
         
         value = '';
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         if ~isfield(obj.In,obj.Type)
            return;
         end
         value = nigeLab.utils.getUNCPath(obj.In.(obj.Type));
         value = strrep(value,'\','/');
      end
      function set.Input(obj,value)
         %SET.INPUT  Sets .Input property (recording file or folder)
         %
         %  set(obj,'Input',value);
         
         if isempty(value)
            return;
         end
         if ~ischar(value)
            return;
         end
         value = strrep(value,'\','/');
         
         % Assign this to the "container" folder
         switch obj.Type
            case 'Block'
               [a,b,ext] = fileparts(value);
               if strcmp(ext,obj.FolderIdentifier)
                  obj.Output = a;
                  obj.loadIDFile();
                  if isfield(obj.IDInfo,'RecFile')
                     obj.In.Block = obj.IDInfo.RecFile;
                  else
                     error(['nigeLab:' mfilename ':BadNigelFile'],...
                        ['Missing line: RecFile|%s in .nigelBlock\n' ...
                         '->\tEither add manually or init from recording']);
                  end
                  if isfield(obj.IDInfo,'RecDir')
                     obj.In.Animal = obj.IDInfo.RecDir;
                  else
                     error(['nigeLab:' mfilename ':BadNigelFile'],...
                        ['Missing line: RecDir|%s in .nigelBlock\n' ...
                         '->\tEither add manually or init from recording']);
                  end
                  if isfield(obj.IDInfo,'FileExt')
                     obj.In.FileExt = obj.IDInfo.FileExt;
                  else
                     error(['nigeLab:' mfilename ':BadNigelFile'],...
                        ['Missing line: FileExt|%s in .nigelBlock\n' ...
                         '->\tEither add manually or init from recording']);
                  end
                  [~,obj.In.BlockName,~] = fileparts(obj.In.Block);
               elseif ~isempty(ext)
                  obj.In.Block = value; % same as line below
%                   obj.RecFile = value;
                  obj.In.FileExt = ext;
                  obj.In.Animal = a; % same as line below
%                   obj.RecDir = a;
                  obj.In.BlockName = b;
               end               
               [obj.In.Tank,obj.In.AnimalName,~] = fileparts(obj.In.Animal);
               [obj.In.Experiment,obj.In.TankName,~] = fileparts(obj.In.Tank);
               obj.In.Name = obj.In.BlockName;
            case 'Animal'
               obj.In.Animal = value; % same as line below
%                obj.RecDir = value;
               [obj.In.Tank,obj.In.AnimalName,~] = fileparts(value);
               [obj.In.Experiment,obj.In.TankName,~] = fileparts(obj.In.Tank);
               obj.In.Name = obj.In.AnimalName;
            case 'Tank'
               obj.In.Tank = value; % same as line below
               [obj.In.Experiment,obj.In.TankName,~] = fileparts(value);
               obj.In.Name = obj.In.TankName;
            otherwise
               error(['nigeLab:' mfilename ':BadType'],...
                  'nigelObj has bad Type (%s)',obj.Type);
         end
         obj.Name = obj.genName();
      end
      
      % [DEPENDENT]  .KeyPair (backwards compatible)
      function value = get.KeyPair(obj)
         %GET.KEYPAIR  Dependent property for backwards compatibility
         %
         %  value = get(obj,'KeyPair');
         %  --> Returns value of obj.Key instead
         
         value = nigeLab.nigelObj.InitKey();
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         value = obj.Key;
      end
      function set.KeyPair(obj,value)
         %SET.KEYPAIR  Assigns .KeyPair (as .Key, backwards-compatible)
         if isempty(value)
            return;
         end
         obj.Key = value;
      end
  
      % [DEPENDENT]  .OnRemote (running remote job if true)
      function value = get.OnRemote(obj)
         %GET.ONREMOTE  Returns value of OnRemote flag
         %
         %  value = get(obj,'OnRemote');
         
         value = false;
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         value = obj.RemoteFlag;
      end
      function set.OnRemote(obj,value)
         %SET.ONREMOTE  Sets value of OnRemote flag
         %
         %  set(obj,'OnRemote',value);
         %  --> Toggles leading string to .Input and .Output property to
         %        properly reflect the configured path on local or remote
         %        machine.
         
         if obj.RemoteFlag == value
             return;
         else
             obj.RemoteFlag = value;
         end
         if ~isfield(obj.Pars,'Queue')
            obj.updateParams('Queue');
         end
         % Toggle "path root" based on remote flag value
         out = obj.Out.SaveLoc;
         in = obj.Input;
         if value
            in = strrep(in,obj.Pars.Queue.Remote.SaveRoot,...
               obj.Pars.Queue.Local.SaveRoot);
            obj.Input = in;
            out = strrep(out,obj.Pars.Queue.Remote.SaveRoot,...
               obj.Pars.Queue.Local.SaveRoot);
            obj.Output = out;
         else
            in = strrep(in,obj.Pars.Queue.Local.SaveRoot,...
               obj.Pars.Queue.Remote.SaveRoot);
            obj.Input = in;
            out = strrep(out,obj.Pars.Queue.Local.SaveRoot,...
               obj.Pars.Queue.Remote.SaveRoot);
            obj.Output = out;
         end
      end
      
      % [DEPENDENT]  .Output (saved output location depends on .Type)
      function value = get.Output(obj)
         %GET.OUTPUT  Return output folder tree container folder
         %
         %  value = get(obj,'Output');         

         value = '';
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         if ~isempty(obj.Out.Folder)
            value = obj.Out.SaveLoc;
            value = strrep(value,'\','/');
            return;
         elseif isempty(obj.Out.SaveLoc)
             value = '';            
         end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % from here probably unnecessary 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%          p = obj.Out.SaveLoc;
%          if isempty(p)
%             if ~obj.getSaveLocation
%                value = ''; % Could not return correctly
%                warning('Save location (%s) is not set.',obj.Type);
%                return;
%             else
%                p = obj.Paths.SaveLoc;
%             end
%          end
%          
%          value = nigeLab.utils.getUNCPath(p,obj.Name);
%          F = dir(fullfile(value,'.nigel*'));
%          if numel(F) > 1
%             % If too many FolderIdentifier files, there is a problem.
%             obj.PlayAlertPing(4,0.66);
%             error(['nigeLab:' mfilename ':BadFolderTree'],...
%                ['Check folder tree; too much Nigel!\n'...
%                 'Multiple FolderIdentifier files at same tree level.\n' ...
%                 'A given folder should only contain one .nigelFile!']);
%          elseif numel(F) < 1
%             [fmt,idt,type] = obj.getDescriptiveFormatting();
%             nigeLab.utils.cprintf(fmt,...
%                '%s[%s]: Could not find .nigelFile at %s\n',...
%                idt,type,nigeLab.utils.shortenedPath(value));
%             value = '';            
%             return;
%          end
%          % If we find the correct FolderIdentifier, return the value
%          if strcmp(F.name,obj.FolderIdentifier)
%             value = strrep(value,'\','/');
%             obj.setOutputPath(value);
%          else
%             obj.PlayAlertPing(4,0.66,1.5,0.75,-1);
%             error(['nigeLab:' mfilename ':BadFolderTree'],...
%                ['Check folder tree; Nigel is confused!\n'...
%                 'Unexpected FolderIdentifier files at %s level.\n' ...
%                 '-->\t(Found %s, but was looking for %s)'],...
%                 obj.Type,F.name,obj.FolderIdentifier);
%          end

      end
      function set.Output(obj,value)
         %SET.OUTPUT  Sets .Output property (.Paths.SaveLoc)
         %
         %  set(obj,'Output',value);
         
         if isempty(value)
            return;
         end
         if ~ischar(value)
            return;
         end
         
         fix = @(x)strrep(x,'\','/');
         % Assign this to the "container" folder
         obj.Out.SaveLoc = fix(value);
         obj.Out.Folder =  fix(fullfile(value, obj.Name));
         obj.Out.File =    fix(fullfile(value, sprintf('%s_%s.mat',obj.Name,obj.Type)));
         obj.Out.Pars =    fix(fullfile(value, sprintf(obj.ParamsExpr,obj.Name)));
         obj.Out.NigelFile = fix(fullfile(obj.Out.Folder,sprintf('.nigel%s',obj.Type)));
         flags = arrayfun(@(x)set(x,'Output',obj.Out.Folder),obj.Children,'UniformOutput',false);
         obj.genPaths();
         obj.saveIDFile();
         
      end
      
      % [DEPENDENT]  .OutDef (default output location depends on .Type)
      function value = get.OutDef(obj)
         %GET.OUTDEF  Default output location (char array)
         %
         %  value = get(obj,'OutDef');

         value = pwd;
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         if isfield(obj.Out,'Default')
            value = strrep(obj.Out.Default,'\','/');
            return;
         end
         
         value = obj.getParams(obj.Type,'SaveLocDefault');
         if ~isempty(value)
            obj.Out.Default = strrep(value,'\','/');
            return;
         end
         % Otherwise, update and save for later
         obj.updateParams(obj.Type);
         value = obj.getParams(obj.Type,'SaveLocDefault');
         if ~ischar(value)
            obj.Out.Default = 'P:\Rat\Intan';
         else
            value = strrep(value,'\','/');
            obj.Out.Default = value;
         end
      end
      function set.OutDef(obj,value)
         %SET.OUTDEF  Default output location (char array)
         %
         %  set(obj,'OutDef',value);
         
         obj.Out.Default = value;
         
      end
      
      % [DEPENDENT]  .OutPrompt (prompt for selecting output location)
      function value = get.OutPrompt(obj)
         %GET.OUTPROMPT   Header prompt for output folder tree location
         %
         %  value = get(obj,'OutPrompt');

         value = 'Select OUTPUT folder';
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         switch obj.Type
            case 'Block'
               value = '[output] BLOCK container folder (Animal)'; 
            case 'Animal'
               value = '[output] ANIMAL container folder (Tank)';
            case 'Tank'
               value = '[output] TANK container folder (Experiment)';
         end
      end
      function set.OutPrompt(~,~)
         %SET.OUTPROMPT  Does nothing probably
         %
         %  set(obj,'OutPrompt',value);
         
         warning('Cannot set `.OutPrompt` (Dependent) property');
      end
      
      % [DEPENDENT]  .Pars parameter info struct
      function value = get.Pars(obj)
         %GET.PARS  Gets .Pars property of nigelObj
         %
         %  value = get(obj,'Pars',pathStruct);
         %  --> Returns value held in .Params.Pars
         
         value = obj.Params.Pars;

      end
      function set.Pars(obj,value)
         %SET.PARS  Sets .Pars property of nigelObj
         %
         %  set(obj,'Pars',pathStruct);
         %  --> If 'Pars' already exists with fields not included in
         %      pathStruct, keep those fields from the old pathStruct
         
         if isempty(value)
            return;
         end
         obj.Params.Pars = obj.MergeStructs(obj.Params.Pars,value);
      end
      
      % [DEPENDENT]  .RecSystem
      function value = get.RecSystem(obj)
         %GET.RECSYSTEM  Returns value .RecSystem property
         %
         %  value = get(obj,'RecSystem');
         %  --> Depends upon value of obj.AcqSystem
         
         value = nigeLab.utils.AcqSystem('UNKNOWN');
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         if isempty(obj.AcqSystem)
            return;
         end
         
         value = obj.AcqSystem;
      end
      function set.RecSystem(obj,value)
         %SET.RECSYSTEM  Sets value .RecSystem property
         %
         %  set(obj,'RecSystem',value);
         
         % Block can only have one Acquisition system; 
         % Similarly, if property is empty, then just make assignment
         if isempty(obj.AcqSystem) || strcmp(obj.Type,'Block')
            obj.AcqSystem = value;
            return;
         end
         
         % Otherwise, include any unique acquisition systems used
         obj.AcqSystem = unique([obj.AcqSystem, value]);
      end
      
      % [DEPENDENT]  .RecType
      function value = get.RecType(obj)
         %GET.RECTYPE  Returns value .RecType property
         %
         %  value = get(obj,'RecType');
         %  --> Depends upon value of obj.FileExt
         
         value = '';
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         
         if isfield(obj.In,'RecType')
            value = obj.In.RecType;
            return;
         end
         
         if ismember(obj.Type,{'Animal','Tank'})
            value = '';
            return;
         end
         
         if isempty(obj.FileExt)
            value = 'Other';
            return;
         end
         
         value = obj.parseRecType();
      end
      function set.RecType(obj,value)
         %SET.RECTYPE  Sets value .RecType property
         %
         %  set(obj,'RecType',value);
         %  --> Depends upon value of obj.FileExt
         
         obj.In.RecType = value;
      end
      
      % [DEPENDENT]  .ShortFile (short char array for printing names)
      function value = get.ShortFile(obj)
         %GET.SHORTFILE  Get shortened _Obj.mat file name
         %
         %  value = get(obj,'ShortFile');

         value = '';
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         if isempty(obj.Out.File)
            return;
         end
         
         [p,f,e] = fileparts(obj.Out.File);
         short_name = nigeLab.utils.shortenedName([f e]);
         short_path = nigeLab.utils.shortenedPath(p);
         value = [short_path short_name];
      end
      function set.ShortFile(~,~)
         %SET.SHORTFILE  No set method for this property
      end
      
      % [DEPENDENT]  .SortGUI (nigeLab.Sort depends if .GUI is open)
      function value = get.SortGUI(obj)
         %GET.SORTGUI  Returns handle to nigeLab.Sort object
         %
         %  value = get(obj,'SortGUI');
         
         value = [];
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         if ~isempty(obj.SortGUIContainer)
            value = obj.SortGUIContainer;
         end
      end
      function set.SortGUI(obj,value)
         %SET.SortGUI  Sets handle to nigeLab.Sort object
         %
         %  set(obj,'SortGUI',value);

         for i = 1:numel(obj)
            if isempty(value)
               obj(i).SortGUIContainer = nigeLab.Sort.empty(); % Remove handle association
               if obj(i).IsDashOpen             % Make sure Dash is un-hidden
                  visible = obj(i).GUI.Visible;
                  if strcmpi(visible,'off')
                     Show(obj(i).GUI);
                  end
               end
            else
               obj(i).SortGUIContainer = value; % Store association to handle object
               if obj(i).IsDashOpen         % Make sure Dash is hidden
                  visible = obj(i).GUI.Visible;
                  if strcmpi(visible,'on')
                     Hide(obj(i).GUI);
                  end
               end
            end

            obj.setChildProp('SortGUI',value);
         end
      end  
      
      % [DEPENDENT]  .Type (ensure returns good .Type)
      function value = get.Type(obj)
         %GET.TYPE  Returns obj.Type ('Block', 'Animal', or 'Tank')
         %
         %  value= get(obj,'Type');
         %  --> Returns value in obj.Params.Type if it is non-empty,
         %      otherwise attempts to parse value from object class.
         
         c = class(obj);
         value = strrep(c,'nigeLab.','');
         if isempty(obj)
            return;
         end
         if ~isvalid(obj)
            return;
         end
         % Only access this if it is set and valid
         if isfield(obj.Params,'Type')
            if ~isempty(obj.Params.Type)
               value = obj.Params.Type; % A default field of obj.Params     
            end
         end
      end
      function set.Type(obj,value)
         %SET.TYPE  Sets obj.Type ('Block', 'Animal', or 'Tank')
         %
         %  set(obj,'Type',value);
         %  --> Sets value in obj.Params.Type, checking that .Type is
         %      actually a valid value.
         
         if ~ischar(value)
            error(['nigeLab:' mfilename ':BadClass'],...
               '[SET.TYPE]: nigelObj.Type must be char');
         end
         
         if ~ismember(value,{'Block','Animal','Tank'})
            value = strrep(value,'.nigel','');
            if ~ismember(value,{'Block','Animal','Tank'})
               value = strrep(class(obj),'nigeLab.','');
               if ~ismember(value,{'Block','Animal','Tank','nigelObj'})
                  error(['nigeLab:' mfilename ':BadType'],...
                     ['[SET.TYPE]: Unexpected Type: %s\n' ...
                     '\t-->\tMust be: ''Block,'' ''Animal,'' or ''Tank'''],...
                     value);
               end
            end
         end
         obj.Params.Type = value;
      end
      
      % Get method for .User
      function value = get.User(obj)
         %GET.User  Property Get method for .User
         %
         %  value = get(obj,'User');

         if isunix % On MAC/UNIX, use 'UNC' to set GIT_DIR environment var
            p = nigeLab.utils.getNigelPath('UNC');
            setenv('GIT_DIR',p);
            [status,tmp] = system('who');
            if status == 0 % Try to parse it from User list
               tmp = textscan(tmp,'%s');
               def = tmp{1}{1};
            else % Otherwise try to parse from .git info
               gitInfo = nigeLab.utils.Git.getGitInfo();
               def = gitInfo.user;
            end
         else % Otherwise for Windows use windows convention
            p = nigeLab.utils.getNigelPath();
            setenv('GIT_DIR',p);
            % whoami returns list of logged-in users
           def = [getenv('userdomain') '_' getenv('username')];
         end
         
         % Make sure it can be set as a field name
         try
            test = struct(def,'name'); % To test it
         catch
            def = regexprep(def,'[+-\\/ ]','_');
            try
               test = struct(def,'name'); % Test again
            catch
               def = 'anon';
            end
         end
         
         if numel(obj) > 1
            value = cell(size(obj));
            for i = 1:numel(obj)
               value{i} = def;
               if isempty(obj(i))
                  continue;
               end
               if ~isvalid(obj(i))
                  continue;
               end
               if isempty(obj(i).UserContainer)
                  setUser(obj(i),def);
               end
               value{i} = obj(i).UserContainer;
            end
         else
            value = def;
            if isempty(obj)
               return;
            end
            if ~isvalid(obj)
               return;
            end
            if isempty(obj.UserContainer)
               setUser(obj,def);
            end
            value = obj.UserContainer;
         end
      end
      function set.User(obj,value)
         %SET.User   Set method for 'User' property assignments
         
         value = strrep(value,' ','_');
         value = strrep(value,'-','_');
         value = strrep(value,'.','_');
         if ~regexpi(value(1),'[a-z]')
            error(['nigeLab:' mfilename ':InvalidUser'],...
               'obj.User must start with alphabetical element.');
         end
         
         for i = 1:numel(obj)
            obj(i).UserContainer = value;
         end
      end
      
      % Get method for .Version (most-recent release version tag)
      function value = get.Version(~)
         %GET.VERSION  Returns the git .Version
         %
         %  value = get(obj,'Version');
         %  --> Does not depend upon `nigelObj`
         
         value = 'unknown';     
         if isunix
            nigelPath = nigeLab.utils.getNigelPath('UNC');
            nigelPath = [nigelPath '/.git'];
            setenv('GIT_DIR',nigelPath);
         else
            nigelPath = nigeLab.utils.getNigelPath();
            nigelPath = strrep(nigelPath,'\','/');
            nigelPath = [nigelPath '/.git'];
            setenv('GIT_DIR',nigelPath);
         end
         syscmdstr = sprintf(...
               'git describe --abbrev=0 --tags --candidates=1');
         [status,cmdout] = system(syscmdstr);
         if status ~= 0
            return;
         end
         s = textscan(cmdout,'%s');
         value = s{1}{1};
      end
      function set.Version(obj,~)
         %SET.VERSION  Does nothing
         %
         %  set(obj,'Version',value);
         %  --> Does not depend upon `nigelObj`
         
         if obj.Verbose
            nigeLab.sounds.play('pop',2.7);
            dbstack();
            [fmt,idt,type] = getDescriptiveFormatting(obj);
            nigeLab.utils.cprintf('Errors*','%s[%s/SET]: ',idt,type);
            nigeLab.utils.cprintf(fmt,...
               'Failed attempt to set READ-ONLY property: Version\n');
            fprintf(1,'\n');
         end
      end
      % % % % % % % % % % END (DEPENDENT) GET/SET.PROPERTY METHODS % % %
      
      % Overloaded `getdisp` method just uses `list`
      function getdisp(obj)
         %GETDISP  Overloaded `getdisp` method just calls obj.list()
         %
         %  >> get(obj)
         %  --> Display something in Command Window <--
         
         if obj.OnRemote
            % Don't do anything if on remote
            return;
         end
         
         list(obj);
      end
      
      % Overloaded save method
      function flag = save(obj)
         % SAVE  Overloaded SAVE method for BLOCK
         %
         %  obj.save;          This works
         %  flag = save(obj);  This also works
         %
         %  flag returns true if the save did not throw an error.
         
         % Make sure array isn't saved to same file
         if numel(obj) > 1
            flag = true(size(obj));
            for i = 1:numel(obj)
               if ~isempty(obj(i))
                  if isvalid(obj(i))
                     flag(i) = obj(i).save;
                  end
               end
            end
            return;
         else
            flag = true;
         end
         
         for i = 1:numel(obj.Children)
            if ~isempty(obj.Children(i))
               if isvalid(obj.Children(i))
                  flag = flag && save(obj.Children(i));
               end
            end
         end
         
         flag = false;
         if ~isfield(obj.HasParsInit,obj.Type)
            obj.updateParams(obj.Type);
         elseif ~obj.HasParsInit.(obj.Type)
            obj.updateParams(obj.Type);
         end
         % Detach unwanted properties
         isDashOpen = obj.IsDashOpen;
         obj.IsDashOpen = false;
         onRemote = obj.OnRemote;
         obj.OnRemote = false;
         C = obj.Children;
         obj.Children(:) = [];
         
         % Do all Dependent variable 'gets' prior to try in case that is
         % where an error occurs:
         [fmt,idt,type] = obj.getDescriptiveFormatting();
         fname = obj.Out.File;
         name = obj.ShortFile;
         
         % Save obj. No longer needs to drop and re-add handles, due
         % to use of `Transient` property attribute         
         varName = [lower(type) 'Obj'];
         out = struct;
         out.(varName) = obj;
         try % The only thing here that can go wrong is something with save
            save(fname,'-struct','out');
            flag = true;
            nigeLab.utils.cprintf(fmt,obj.Verbose,...
               '%s[SAVE]: %s saved successfully!\n',idt,name);
         catch er
            nigeLab.utils.cprintf('Errors*',...
               'Failed to save [%s]: %s\n',type,name);
            obj.OnRemote = onRemote;
            obj.IsDashOpen = isDashOpen;
            return;
         end
         obj.OnRemote = onRemote;
         obj.IsDashOpen = isDashOpen;
         obj.Children = C;
         flag = flag && saveIDFile(obj); % .nigelBlock file saver
         F = fieldnames(obj.HasParsInit);
         for iF = 1:numel(F)
            f = F{iF};
            if isfield(obj.HasParsSaved,f)
               if ~obj.HasParsSaved.(f)
                  flag = flag && saveParams(obj,obj.User,f);
               end
            end
         end
         
         % save multianimals if present
         if strcmp(obj.Type,'Block')
            if obj.MultiAnimals
               for bl = obj.MultiAnimalsLinkedBlocks
                  bl.MultiAnimalsLinkedBlocks(:) = [];
                  bl.MultiAnimals = 0;
                  flag = flag && bl.save();
               end
            end
         end
         
      end
      
      % % % (NON-DEPENDENT) SET.PROPERTY METHODS % % % % % % % % % % % %      
      % [FLAG] Set method for .InBlindMode property
      function set.InBlindMode(obj,value)
         %SET.InBlindMode  Set method for .InBlindMode property
         %
         %  set(obj,'InBlindMode',tf);
         %  tf --> If true, turns on "Blinded Mode" and removes direct
         %           links to the animal names. Otherwise, displays names.
         
         if ~isscalar(value)
            error(['nigeLab:' mfilename ':BadInputSize'],...
               'Logical input to `.InBlindMode` should be a scalar.');
         end
         
         for i = 1:numel(obj)
            obj(i).InBlindMode = value;
            if value
               if isempty(obj(i).Key.Name)
                  obj(i).Key.Name = genName(obj(i));
               end
               obj(i).Name = getKey(obj(i),'Public');
            else
               if isempty(obj(i).Key.Name)
                  obj(i).Key.Name = genName(obj(i));
               end
               obj(i).Name = getKey(obj(i),'Name');
            end
            [obj(i).Children.InBlindMode] = deal(value);
         end

      end

      % [ASSIGN CHILDREN] Sets .Index property (to assign all children)
      function set.Index(obj,value)
         %SET.INDEX  Set method for .Index 
         %
         %  set(obj,'Index',3);
         %  --> Would update all obj.Children(i).Index to
         %      [3 i]
         
         obj.Index = value;
         obj.setChildIndex();
      end

      % [FLAG] Set method for .IsDashOpen (flag true if GUI is open)
      function set.IsDashOpen(obj,value)
         %SET.ISDASHOPEN  Set method for .IsDashOpen (flag for GUI)
         %
         %  set(obj,'IsDashOpen',value);
         %  --> value can be true or false
         %  --> Update all Children to take same value
         
         obj.IsDashOpen = value;
         obj.toggleChildDashStatus(value);
      end
      % % % % % % % % % % END (NON-DEPENDENT) SET.PROPERTY METHODS % % %
   end
  
   % PUBLIC
   methods (Access=public)      
      % Add a child object to parent obj.Children array
      function addChild(obj,childData,idx)
         % ADDCHILD  Add to .Children property
         %
         %  obj.addChildBlock('childData');
         %  --> Adds block located at 'childData'
         %
         %  obj.addChildBlock(childObj);
         %  --> Adds the block directly to 'Blocks'
         %
         %  obj.addChildBlock(childObj,idx);
         %  --> Adds the block to the array element indexed by idx
         
         if nargin < 2
            childData = [];
         end
         
         if nargin < 3
            idx = [];
         end
         
         if ischar(idx)
             error(['nigeLab:' mfilename ':BadInputValue'],...
                 'idx must be numeric.');
         end

         if ~isscalar(obj) % Require that Parent is scalar
            error(['nigeLab:' mfilename ':BadInputSize'],...
               'obj must be scalar.');
         end
         
         if ~isempty(childData)
            switch class(childData)
               case 'char'
                  % Create the Children Block objects
                  switch obj.Type
                     case 'Animal'
                        childObj = nigeLab.Block(childData,obj.Out.Folder);
                     case 'Tank'
                        childObj = nigeLab.Animal(childData,obj.Out.Folder);
                  end

               case {'nigeLab.Block', 'nigeLab.Animal'}
                  % Load them directly as Children
                  if numel(childData) > 1
                     childObj = reshape(childData,1,numel(childData));
                  else
                     childObj = childData;
                  end

               otherwise
                  error(['nigeLab:' mfilename ':BadInputClass'],...
                     'Bad childData input type: %s',class(childData));
            end % switch class(childData)
         else
            switch obj.Type
               case 'Tank'
                  childObj = nigeLab.Animal('',obj.Out.Folder,...
                     'InDef',obj.Input,...
                     '$Animal',obj.Pars.Animal,...
                     '$Block',obj.Pars.Block,...
                     'Parent',obj);
               case 'Animal'
                   childObj = nigeLab.Block('',obj.Out.Folder,...
                       'InDef',obj.Input,...
                       '$Block',obj.Pars.Block,...
                       'Parent',obj);
            end % switch obj.Type
         end % if isempty
         
         RmIdx = false(1,numel(childObj));
         if any(strcmp(class(obj),{'nigeLab.Tank','Tank'}))
             RmIdx = ismember({childObj.Name},{obj.Children.Name});
         end
         
         
         % assign parent to childObj
         [childObj.Parent] = deal(obj);
         
         addPropListeners(childObj);
         if isempty(idx)
            obj.Children = [obj.Children childObj];
         else
             % we need to explicitly handle the assignement of empty elements 
             % ie when idx = [2 4]; obj.Children(3) needs to be empty;
             % the same goes for the case numel(obj.Children) = n; and
             % min(idx) > n
             
             NChildren = numel(obj.Children);
             fullIdx = (NChildren+1):max(idx);
             nullIdx = ~ismember(fullIdx,idx);
             newChildObj = nigeLab.(childObj.Type).Empty([1 numel(fullIdx)]);
             newChildObj(~nullIdx) = childObj;
             S = substruct('()',{1,fullIdx});
             obj.Children = builtin('subsasgn',obj.Children,...
               S,newChildObj);
             
         end % if isempty(idx)
         

         
         
         for i = 1:numel(childObj)
            obj.ChildListener = [obj.ChildListener, ...
               addlistener(childObj(i),'ObjectBeingDestroyed',...
               @(src,evt)obj.assignNULL(src)), ...
               addlistener(childObj(i),'StatusChanged',...
               @(~,evt)notify(obj,'StatusChanged',evt)), ...,...
               addlistener(childObj(i),'DashChanged',...
                  @(~,evt)obj.requestDash(evt))];
            if strcmp(obj.Type,'Animal')
               obj.ChildListener = [obj.ChildListener, ...
                  addlistener(childObj(i),'IsMasked','PostSet',...
                     @(~,~)obj.parseProbes)];
            end
         end % i
         if strcmp(obj.Type,'Animal') && ~obj.MultiAnimals
            obj.parseProbes();
         end
         
         
         % check if any clones were found
         childObj = childObj(~RmIdx);
         if isempty(childObj)
             return;
         end
         evt = nigeLab.evt.childAdded(childObj);
         notify(obj,'ChildAdded',evt);
         
      end
      
      % Check compatibility with current `.Fields` configuration
      function fieldIdx = checkCompatibility(obj,requiredFields)
         % CHECKCOMPATIBILITY  Checks if Block is compatible with "required fields"
         %
         %  obj = nigeLab.Block;
         %  fieldIdx = obj.CHECKCOMPATIBILITY('FieldName');
         %  fieldIdx = obj.CHECKCOMPATIBILITY({'FieldName1','FieldName2',...,'FieldNameK'});
         %
         %  A way to add a hard-coded check for compatibility
         %  (for example, for ad hoc functions such as those in nigeLab.workflow)
         %  that will throw an error pointing to the missing fields. This can be
         %  added to an ad hoc function to make it easier to fix configurations for
         %  that particular ad hoc function.
         %
         %  Returns fieldIdx, the index into obj.Fields for each element of
         %  requiredFields (if no error is thrown).
         %
         %  See Also:
         %  NIGELAB.BLOCK/CHECKACTIONISVALID,
         %  NIGELAB.NIGELOBJ/CHECKPARALLELCOMPATIBILITY
         
         % Could add parsing here to allow requiredFields to be a 'config' class or
         % something like that, or whatever, that allows it to load in a set of
         % fields from a saved matfile to do the comparison against, as well.
         
         if isempty(requiredFields)
            fieldIdx = [];
            return;
         end
         
         if numel(obj) > 1
            fieldIdx = cell(size(obj));
            for i = 1:numel(obj)
               fieldIdx{i} = checkCompatibility(obj(i),requiredFields);
            end
            return;
         end
         idx = find(~ismember(requiredFields,obj.Fields));
         if isempty(idx)
            if ischar(requiredFields)
               fieldIdx = find(ismember(obj.Fields,requiredFields),1,'first');
            elseif iscell(requiredFields)
               fieldIdx = nan(size(requiredFields));
               for i = 1:numel(fieldIdx)
                  fieldIdx(i) = ...
                     find(ismember(obj.Fields,requiredFields{i}),1,'first');
               end
            end
            return;
         end
         
         nigeLab.utils.cprintf('UnterminatedStrings',...
            '%s: missing following Fields...',...
            obj.Name);
         for i = 1:numel(idx)
            nigeLab.utils.cprintf('Strings',...
               '-->\t%s\n',...
               requiredFields{idx(i)});
         end
         error(['nigeLab:' mfilename ':BadConfig'],...
            ['[%s/CHECKCOMPATIBILITY]: Missing required Fields. '...
            'Check nigeLab.defaults.Block'],upper(obj.Type));
      end
      
      % Check compatibility for Remote/Parallel execution
      function flag = checkParallelCompatibility(obj,isUpdated)
         %CHECKPARALLELCOMPATIBILITY  Checks based on user preference and
         %    license/installation, whether the user can use parallel tools
         %    or not
         %
         %  flag = obj.checkParallelCompatibility();
         %
         %  flag = obj.checkParallelCompatibility(true);
         %  --> Skips `updateParams('Queue')` call
         
         if isempty(obj)
             flag = false;
            return;
         end
         
         if nargin < 2
            isUpdated = false;
         end
         
         % Check combination of user preference and installed toolkit/license
         if ~isUpdated
            obj.updateParams('Queue');
         end
         qPars = obj.Pars.Queue;
         
         pFlag = qPars.UseParallel; % Check user preference for using Parallel
         rFlag = qPars.UseRemote;   % Check user preference for using Remote
%          uFlag = pFlag && rFlag;
         
         lFlag = license('test','Distrib_Computing_Toolbox'); % Check if toolbox is licensed
         if verLessThan('matlab','9.7')
             dFlag = ~isempty(ver('distcomp'));  % Check if distributed-computing toolkit is installed
         else
             dFlag = ~isempty(ver('parallel'));
         end
         if obj.Verbose
            [fmt,idt,type] = getDescriptiveFormatting(obj);
            if (pFlag || rFlag) && ~(dFlag && lFlag) % If user indicates they want to run parallel or remote
               str = nigeLab.utils.getNigeLink('nigeLab.defaults.Queue',14,'configured');
               fprintf(1,['nigeLab is %s to use parallel or remote processing, '...
                  'but encountered the following issue(s):\n'],str);
               if ~lFlag
                  nigeLab.utils.cprintf('SystemCommands*',...
                     '%s[%s/CHECKPARALLEL]: ',idt,upper(type));
                  nigeLab.utils.cprintf(fmt,...
                     ['This machine does not have the ' ...
                      'Parallel Computing Toolbox license.\n']);
               end

               if ~dFlag
                  nigeLab.utils.cprintf('SystemCommands*',...
                     '%s[%s/CHECKPARALLEL]: ',idt,upper(type));
                  nigeLab.utils.cprintf(fmt,...
                     ['This machine does not have the ' ...
                     'Distributed Computing Toolbox installed.\n']);
               end
            end
         end
         
         flag = pFlag && lFlag && dFlag;
         
         obj.UseParallel = flag;
         
         if obj.Verbose
            if (nargout < 1) && (~obj.OnRemote)
               nigeLab.utils.cprintf('Comments*','\n-----%s',idt);
               nigeLab.utils.cprintf(fmt(1:(end-1)),...
                  '[%s/CHECKPARALLEL]: %s (%s) flagged for ',...
                  upper(type),obj.Name);
               if flag
                  nigeLab.utils.cprintf('Keywords*','Parallel');
               else
                  nigeLab.utils.cprintf('Keywords*','Serial');
               end
               nigeLab.utils.cprintf(fmt(1:(end-1)),' Processing -----\n');
            end
         end
         
         if ~isempty(obj.Children)
            setProp(obj.Children,'UseParallel',flag);
         end
         
      end
      
      % % % "DO" METHODS % % % % % % % % % % % % % % % %
      % Does automated clustering of spikes based on waveform features
      function flag = doAutoClustering(obj)
         %DOAUTOCLUSTERING  Generate automatic spike clusters from features
         %
         %  flag = doAutoClustering(obj);
         %  --> Full method implemented at `nigeLab.Block` level
         
         flag = nigeLab.nigelObj.doMethod(obj,@doAutoClustering);
      end
      
      % Decimate and lowpass filter slow LFP signals
      function flag = doLFPExtraction(obj)
         %DOLFPEXTRACTION  Decimates and lowpass filters slow LFP signals
         %
         %  flag = doLFPExtraction(obj);
         %  --> Full method implemented at `nigeLab.Block` level
         
         flag = nigeLab.nigelObj.doMethod(obj,@doLFPExtraction);
      end
      
      % Convert raw data files to nigeLab format
      function flag = doRawExtraction(obj)
         %DORAWEXTRACTION  Convert raw data files to nigeLab format
         %
         %  flag = doRawExtraction(obj);
         %  --> Full method implemented at `nigeLab.Block` level
         
         flag = nigeLab.nigelObj.doMethod(obj,@doRawExtraction);
      end
      
      % Extract filtered streams with common noise removed
      function flag = doReReference(obj)
         %DOREREFERENCE  Does "virtual common-mode" noise rejection
         %
         %  flag = doReReference(obj);
         %  --> Full method implemented at `nigeLab.Block` level
         
         flag = nigeLab.nigelObj.doMethod(obj,@doReReference);
      end
      
      % Does spike-detection on bandpass-filtered and referenced signals
      function flag = doSD(obj)
         %DOSD  Do spike detection
         %
         %  flag = doSD(obj);
         %  --> Full method implemented at `nigeLab.Block` level
         
         flag = nigeLab.nigelObj.doMethod(obj,@doSD);
      end
      
      % Does trial video extraction
      function flag = doTrialVidExtraction(obj)
         flag = nigeLab.nigelObj.doMethod(obj,@doTrialVidExtraction);
      end
      
      % Apply spike unit bandpass (300 - 5000 Hz) filter
      function flag = doUnitFilter(obj)
         %DOSD  Apply spike unit bandpass (300 to 5000 Hz) filter
         %
         %  flag = doUnitFilter(obj);
         %  --> Full method implemented at `nigeLab.Block` level
         
         flag = nigeLab.nigelObj.doMethod(obj,@doUnitFilter);
      end
      
      % Extract video metadata if videos are present
      function flag = doVidInfoExtraction(obj)
         %DOVIDINFOEXTRACTION  Extract video metadata if videos present
         %
         %  flag = doVidInfoExtraction(obj);
         %  --> Full method implemented at `nigeLab.Block` level
         
         flag = nigeLab.nigelObj.doMethod(obj,@doVidInfoExtraction);
      end
      % % % % % % % % % % END "DO" METHODS % % % % % % %
      
      % Returns nigelObj or key depending if keyStr is key or obj.
      function [a,idx] = findByKey(objArray,keyStr,keyType)
         %FINDBYKEY  Returns nigelObj corresponding to keyStr from array
         %
         %  example:
         %  animalObjArray = tankObj{:}; % Get all animals from tank
         %  a = findByKey(animalObjArray,keyStr); % Find specific animal
         %  [a,idx] = findByKey(animalObjArray,keyStr); % Return index into
         %                                   animal array as well
         %
         %  a = findByKey(animalObjArray,privateKey,'Private');
         %  --> By default, uses 'Public' key to find the Block; this would
         %      find the associated 'Private' key that matches the contents
         %      of privateKey.
         %
         %  keyStr : Can be char array or cell array. If it's a cell array,
         %           then b is returned as a row vector with number of
         %           elements corresponding to number of cell elements.
         %
         %  keyType : (optional) Char array. Should be 'Private' or
         %                          'Public' (default if not specified)

         if nargin < 2
            error(['nigeLab:' mfilename ':tooFewInputs'],...
               '[FINDBYKEY]: Need to provide %s array and `.Key` at least.',...
               objArray(1).Type);
         else
            if isa(keyStr,'nigeLab.nigelObj') || ...
               isa(keyStr,'nigeLab.Tank') || ...
               isa(keyStr,'nigeLab.Animal') || ...
               isa(keyStr,'nigeLab.Block')
               keyStr = getKey(keyStr);
            end

            if ~iscell(keyStr)
               keyStr = {keyStr};
            end
         end

         if nargin < 3
            keyType = 'Public';
         else
            if ~ischar(keyType)
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Unexpected class for ''keyType'' (%s): should be char.',...
                  class(keyType));
            end
            % Ensure it is the correct capitalization
            keyType = lower(keyType);
            keyType(1) = upper(keyType(1));
            if ~ismember(keyType,{'Public','Private'})
               error(['nigeLab:' mfilename ':badKeyType'],...
                  'keyType must be ''Public'' or ''Private''');
            end
         end

         a = nigeLab.(objArray(1).Type).Empty(); % Initialize empty array
         idx = [];

         % Loop through array of animals, breaking the loop if an actual
         % animal is found. If animal index is greater than the size of
         % array, then returns an empty double ( [] )
         nKeys = numel(keyStr);
         if nKeys > 1
            cur = 0;
            while ((numel(a) < numel(keyStr)) && (cur < nKeys))
               cur = cur + 1;
               [a_tmp,idx_tmp] = findByKey(objArray,keyStr(cur),keyType);
               a = [a,a_tmp];%#ok<*AGROW>
               idx = [idx, idx_tmp];
            end
            return;
         end

         % If any of the keys match, return the corresponding block.
         thisKey = getKey(objArray,keyType);
         idx = find(ismember(thisKey,keyStr),1,'first');
         if ~isempty(idx)
            a = objArray(idx);
         end

      end
      
      % Returns descriptive status for all fields in nigelObj
      function pars_status_struct = getDescriptivePars(obj)
         %GETDESCRIPTIVEPARS  Returns descriptive status for all pars
         %
         %  pars_status_struct = obj.getDescriptivePars();
         %  --> pars_status_struct : struct with fieldnames equal to pars
         %     --> Each field element has a qualitative status descriptor
         %           (char array) that depends on the processing status of
         %           that particular field. Returned value can be:
         %           * 'Complete' (all [masked] elements return true)
         %           * 'Incomplete' (some [masked] elements return true)
         %           * 'Missing'  (no [masked] elements return true)
         
         s = getStatus(obj,[]);
         status_struct = struct;
         [~,~,s_all] = obj.listInitializedParams();
         for i = 1:numel(s_all)
            thisProp = s_all{i};
            if isfield(obj.HasParsInit,thisProp)
               if obj.HasParsInit.(thisProp)
                  pars_status_struct.(thisProp) = 'Initialized';
               else
                  pars_status_struct.(thisProp) = ...
                     '<strong>Not Initialized</strong>';
               end
            else
               pars_status_struct.(thisProp) = 'Missing';
            end
            if ~obj.HasParsFile
               pars_status_struct.HasParsFile = '<strong>No</strong>';
            else
               pars_status_struct.HasParsFile = 'Yes';
            end
         end
         
      end
      
      % Returns descriptive status for all fields in nigelObj
      function status_struct = getDescriptiveStatus(obj)
         %GETDESCRIPTIVESTATUS  Returns descriptive status for all fields
         %
         %  status_struct = obj.getDescriptiveStatus();
         %  --> status_struct : struct with fieldnames equal to fields
         %     --> Each field element has a qualitative status descriptor
         %           (char array) that depends on the processing status of
         %           that particular field. Returned value can be:
         %           * 'Complete' (all [masked] elements return true)
         %           * 'Incomplete' (some [masked] elements return true)
         %           * 'Missing'  (no [masked] elements return true)
         
         s = getStatus(obj,[]);
         status_struct = struct;
         for iF = 1:numel(obj.Fields)
            field = obj.Fields{iF};
            if isempty(s)
               status_struct.(field) = 'Empty';
            elseif all(s(:,iF))
               status_struct.(field) = 'Complete';
            elseif sum(s(:,iF) > 1)
               status_struct.(field) = 'Incomplete';
            else
               status_struct.(field) = 'Missing';
            end
         end         
      end
      
      % Returns descriptive formatting metacharacters
      function [fmt,idt,type] = getDescriptiveFormatting(obj)
         %GETDESCRIPTIVEFORMATTING  Return descriptive formatting
         %                          metacharacters
         %
         %  [fmt,idt,type] = obj.getDescriptiveFormatting();
         %  fmt : First argument to nigeLab.utils.cprintf
         %  --> e.g. 'Comments*'
         %
         %  idt : Indentation formatted sprintf corresponding to level of
         %        folder hierarchy (e.g. Block gets 2 indents; tank only
         %        the arrow, etc...)
         %  --> e.g. sprintf('-->\t');    [tank]
         %        vs sprintf('\t\t-->\t') [block]
         %
         %  type : Equivalent to obj.Type (just not Dependent, so it isn't
         %                                   a "get" call)
         
         type = obj.Type;
         switch type
            case 'Block'
               fmt = 'Text*';
               idt = sprintf('\t\t->\t');
            case 'Animal'
               fmt = 'Strings*';
               idt = sprintf('\t->\t');
            case 'Tank'
               fmt = 'Comments*';
               idt = sprintf('->\t');
            otherwise
               fmt = 'Cyan*';
               idt = '?? ';
         end
      end
      
      % Returns info cell array with struct arrays for each field requested
      function info = getFieldInfo(obj,field)
         %GETFIELDINFO  Returns info cell array about requested fields
         %
         %  info = obj.getFieldInfo(); 
         %  --> Returns cell array with same number elements as .Fields;
         %      each cell contains struct array of info
         %     --> info : .Label  -- Summary; .Print   -- Longer
         %
         %  info = obj.getFieldInfo('fieldName');
         % --> Returns struct array for 'fieldName'
         
         thisObj = nigeLab.nigelObj.getValidObj(obj,1);
         if isempty(thisObj)
            info = {};
            return;
         end
         if nargin < 2
            field = obj.Fields;
         end
         if iscell(field)
            info = cell(1,numel(field));
            for i = 1:numel(field)
               info{i} = getFieldInfo(obj,field{i});
            end
            return;
         end
         S = getStatus(obj,field);
         N = numel(S);
         info = struct(...
            'Label',cell(1,N),...
            'Print',cell(1,N),...
            'status',cell(1,N),...
            'mask',cell(1,N));
         for i = 1:N
            info(i).Label = '';
            info(i).Status = S(i);
         end
         [~,idt] = obj.getDescriptiveFormatting();
         if numel(obj)==1
            for i = 1:N
               info(i).mask = true;
            end
            switch thisObj.Type
               case 'Block'
                  switch obj.getFieldType(field)
                     case 'Channels'
                        for i = 1:N
                           info(i).mask = ismember(i,obj.Mask);
                           info(i).Print = sprintf('%s[%s]::(%s): P%g%s\n',...
                              idt,obj.Name,field,obj.Channels(i).probe,...
                              obj.Channels(i).chStr);
                        end
                     case 'Streams'
                        for i = 1:N
                           info(i).Label = obj.Streams.(field)(i).name;
                           info(i).Print = sprintf('%s[%s]::(%s): P%g%s\n',...
                              idt,obj.Name,field,obj.Channels(i).probe,...
                              obj.Channels(i).chStr);
                        end
                     otherwise
                        for i = 1:N
                           if info(i).status
                              str = 'Complete';
                           else
                              str = 'Incomplete';
                           end
                           info(i).Print = sprintf('%s[%s]::(%s): %s\n',...
                                 idt,obj.Name,field,str);
                           if strcmp(field,'Video') && ...
                                 isfield(obj.Meta,'Video')
                              if isfield(obj.Meta.Video,'View') && ...
                                    isfield(obj.Meta.Video,'MovieID')
                                 info(i).Label = sprintf(...
                                    '%s-%s',obj.Meta.Video.View{i},...
                                    obj.Meta.Video.MovieID{i});
                              end
                           end
                        end
                  end    
               case {'Animal','Tank'}
                  c = [obj.Children];
                  for i = 1:N
                     info(i).mask = c(i).IsMasked;
                  end
                  
            end
         else % Array -> only Block or Animal
            for i = 1:N
               info(i).mask = obj(i).IsMasked;
            end
         end
         
      end
      
      % Returns fieldtype corresponding to a particular field
      function [fieldType,n] = getFieldType(obj,field)
         %GETFIELDTYPE       Return field type corresponding to a field
         %
         %  fieldType = obj.getFieldType(field);
         %  [fieldType,n] = obj.getFieldType(field);
         %
         %  --------
         %   INPUTS
         %  --------
         %    obj          :     nigeLab.nigelObj class object.
         %
         %    field        :     Char array corresponding element of Fields 
         %                       property in nigelObj
         %
         %  --------
         %   OUTPUT
         %  --------
         %  fieldType      :     Field type corresponding to "field"
         %                    --> {'Channels';'Streams';'Events';'Videos'}      
         %
         %     n           :     Total number of fields of that type
         
         % Simple code but for readability
         thisObj = nigeLab.nigelObj.getValidObj(obj,1);
         
         if isempty(thisObj)
             if obj.Verbose
                 nigeLab.utils.cprintf('Errors*',...
                     '\t->\t[GETFIELDTYPE]: No valid nigelObj\n');
             end
            fieldType = '';
            n = 0;
            return;
         end
         
         idx = ismember(thisObj.Fields,field);
         if sum(idx) == 0
            error(['nigeLab:' mfilename ':BadField'],...
               '[GETFIELDTYPE]: No matching field type: %s',field);
         end
         fieldType = thisObj.FieldType{idx};
         if nargout > 1
            idx = ismember(thisObj.FieldType,fieldType);
            n = sum(idx);
         end
      end
      
      % Returns indices to all fields of a given type
      function [fieldIdx,n] = getFieldTypeIndex(obj,fieldType)
         %GETFIELDTYPEINDEX    Returns indices to all fields of "fieldType"
         %
         %  fieldIdx = getFieldTypeIndex(obj,fieldType)
         %  [fieldIdx,n] = getFieldTypeIndex(obj,fieldType)
         %
         %  --------
         %   INPUTS
         %  --------
         %  obj         :     nigeLab.nigelObj class object
         %
         %  fieldType   :     Member of 
         %          --> {'Channels','Streams','Events','Meta','Videos'}
         %
         %  --------
         %   OUTPUT
         %  --------
         %  fieldIdx     :     Indexing array for all fields of 'fieldType'
         %
         %     n         :     Total number of fields of type 'fieldType'

         % Check input
         thisObj = nigeLab.nigelObj.getValidObj(obj,1);
         
         if isempty(thisObj)
             if obj.Verbose
                 nigeLab.utils.cprintf('Errors*',...
                     '\t->\t[GETFIELDTYPEINDEX]: No valid nigelObj\n');
             end
            fieldIdx = [];
            n = 0;
            return;
         end

         fieldIdx = ismember(thisObj.FieldType,fieldType);
         if nargout > 1
            n = sum(fieldIdx);
         end
      end
      
      % Returns fileType corresponding to a particular field
      function fileType = getFileType(obj,field)
         %GETFILETYPE       Return file type corresponding to that field
         %
         %  fileType = nigelObj.getFileType(field);
         %
         %  --------
         %   INPUTS
         %  --------
         %     obj         :     nigeLab.nigelObj class object.
         %
         %    field        :     String corresponding element of Fields 
         %                       property in nigelObj
         %
         %  --------
         %   OUTPUT
         %  --------
         %   fileType         :     File type {'Hybrid';'MatFile';'Event'}
         %                          corresponding to files associated with 
         %                          that field.
         
         thisObj = nigeLab.nigelObj.getValidObj(obj,1);
         if isempty(thisObj)
             if obj.Verbose
                 nigeLab.utils.cprintf('Errors*',...
                     '\t->\t[GETFILETYPE]: No valid nigelObj\n');
             end
            fileType = '';
            return;
         end
         
         %Simple code but for readability
         idx = strcmpi(thisObj.Fields,field);
         if sum(idx) == 0
            error(['nigeLab:' mfilename ':BadField'],...
               '[GETFILETYPE]: No matching field type: %s',field);
         end
         fileType = thisObj.FileType{idx};
      end
            
      % Returns the public hash key for this obj
      function key = getKey(obj,keyType)
         %GETKEY  Return the public hash key for this obj
         %
         %  publicKey = obj.getKey('Public');
         %  privateKey = obj.getKey('Private'); Really not useful but
         %                                            there for future
         %                                            expansion.
         %
         %  key --  .Public field of obj.Key
         %
         %  If obj is array, then publicKey is returned as cell array
         %  of dimensions equivalent to obj.
         
         if nargin < 2
            keyType = 'Public';
         end
         if ~ismember(keyType,{'Public','Private','Name'})
            error(['nigeLab:' mfilename ':BadKeyType'],...
               'keyType must be ''Public'' or ''Private''');
         end
         
         n = numel(obj);
         if n > 1
            key = cell(size(obj));
            for i = 1:n
               key{i} = obj(i).getKey();
            end
            return;
         end
         
         if isempty(obj.Key)
            obj.Key = obj.InitKey();
         elseif ~isfield(obj.Key,keyType)
            obj.Key = obj.InitKey();
         end
         key = obj.Key.(keyType);
         
      end
      
      % Returns a formatted string that prints a link to browse files
      function linkStr = getLink(obj,field,promptString)
         %GETLINK  Returns formatted string for link to Block in cmd window
         %
         %  linkStr = obj.getLink();  
         %  --> Returns link to Output location
         %
         %  linkStr = obj.getLink('fieldName');  
         %  --> Returns link to 'fieldName' (if it exists). Otherwise, 
         %      throws an error.
         %        
         %      >> linkStr = obj.getLink('Raw');
         %
         %  <strong>NOTE:</strong> `field` is case-sensitive
         %
         %  linkStr = getLink(objArray); 
         %  --> Returns Output link for all elements of array 
         %  --> String corresponding to each array element is separated by
         %      newline metacharacter ('\n')
         %
         %  linkStr = getLink(obj,'field','Prompt');
         %  --> Replaces the default promptString (which depends upon the
         %      operating system of machine in use) with 'Prompt'
         %
         %  <strong>UNIX links:</strong>
         %     1) add nigeLab to current Matlab path
         %     2) play "pop" noise
         %     3) change current folder to linked folder
         %
         %  <strong>WINDOWS links:</strong>
         %     1) play "pop" noise
         %     2) open linked folder in system file browser (explorer.exe)
         
         if numel(obj) > 1
            linkStr = newline;
            for i = 1:numel(obj)
               switch nargin
                  case 1
                     linkStr = [linkStr ...
                        obj(i).getLink('',obj(i).Name) ...
                        newline];
                  case 2
                     linkStr = [linkStr ...
                        obj(i).getLink(field,obj(i).Name) ...
                        newline];
                  case 3
                     linkStr = [linkStr ...
                        obj(i).getLink(field,promptString) ...
                        newline];
                  otherwise
                     error(['nigeLab:' mfilename ':InvalidNumInputs'],...
                        'nigeLab.nigelObj/getLink takes 1, 2, or 3 inputs.');
               end
            end
            return;
         end
         
         pathString = strrep(obj.Out.Folder,'\','/');
         if (nargin > 1) && strcmp(obj.Type,'Block')
            switch field
               case 'Video'
                  if isfield(obj.Paths,'V')
                     if isfield(obj.Paths.V,'Root') && ...
                        isfield(obj.Paths.V,'Folder')
                        pathString = fullfile(obj.Paths.V.Root,...
                           obj.Paths.V.Folder);
                        pathString = strrep(pathString,'\','/');
                     end
                  end
               otherwise
                  if isfield(obj.Paths,field)
                     pathString = strrep(obj.Paths.(field).dir,'\','/');
                  end
            end
         end
         
         if nargin < 3
            if isunix % Unix OS
               promptString = 'Jump to File Location';
            else % Windows OS
               promptString = 'View Files in Explorer';
            end            
         end

         freqScalePop = 1.0; % Multiplier for 'pop' sample frequency
         if isunix % Unix OS
            linkStr = sprintf(...
               ['\t-->\t'...
               '<a href="matlab: addpath(nigeLab.utils.getNigelPath()); ' ...
               'nigeLab.sounds.play(''pop'',%g); ' ...
               'cd(''%s'');">%s</a>'],...
               freqScalePop,pathString,promptString);
            return;
         else % Windows OS
            linkStr = sprintf(...
               ['\t-->\t'...
               '<a href="matlab: nigeLab.sounds.play(''pop'',%g); ' ...
               'winopen(''%s'');">%s</a>'],...
               freqScalePop,pathString,promptString);
            
         end
      end
      
      % Returns name of object (variable)
      function s = getObjName(obj) %#ok<MANU>
         %GETOBJNAME  Returns name of object (variable) as char array
         %
         %  s = obj.getObjName();
         %  --> Sometimes "obj" may be passed to protected methods where it
         %      is referenced as "obj" instead of "tankObj" or "blockObj"
         %      or whatever; this allows consistency in case that actual
         %      variable name is needed.
         
         s = inputname(1);
      end
      
      % Return a parameter (making sure Pars fields exist)
      function varargout = getParams(obj,parsField,varargin)
         %GETPARAMS  Return a parameter (making sure Pars fields exist)
         %
         %  val = obj.getParams('Sort','Debug');
         %  --> Returns value of obj.Pars.Sort.Debug
         %  --> If field doesn't exist, returns []
         %
         %  [val] = getParams(objArray,'Sort','Debug');
         %  --> Returns array for entire objArray
         
         varargout = cell(1,nargout);
         if numel(obj) > 1
            for i = 1:numel(obj)
               if numel(varargin) > 0
                  varargout{i} = obj(i).getParams(parsField,varargin{:});
               else
                  varargout{i} = obj(i).getParams(parsField);
               end
            end
            return;
         end
         
         if ~isfield(obj.Pars,parsField)
            varargout{1} = struct.empty;
            return;
         end
         s = obj.Pars.(parsField);
         
         for i = 1:numel(varargin)
            if ~isfield(s,varargin{i})
               obj.updateParams(parsField);
               s = getParams(obj,parsField);
               return;
            else
               s = s.(varargin{i});
            end
         end
         varargout{1} = s;
      end
      
      % Returns the recording location for nigelobj
      function [p,f] = getRecLocation(obj,inputType)
         %GETRECLOCATION  Returns path to recording file or folder
         %
         %  [p,f] = obj.getRecLocation('File');
         %  --> Prompts for file selection (Block)
         %  p: path to file
         %  f: filename (no path)
         %
         %  p = obj.getRecLocation('Folder');
         %  --> Prompts for folder selection (Animal, Tank)
         %  p: path to folder
         
         if nargin < 2
            error(['nigeLab:' mfilename ':TooFewInputs'],...
               ['Must specify ''inputType'' with getRecLocation\n',...
                '->\t (Must be ''File'' or ''Folder'')\n']);
         end
         
         switch lower(inputType)
            case 'file'
               [f,p] = uigetfile(...
                  {'*.rhd;*.rhs', 'Intan (*.rhd,*.rhs)'; ...
                  '*.Tbk,*.Tdx,*.tev,*.tnt,*.tsq', ...
                  'TDT (*.Tbk,*.Tdx,*.tev,*.tnt,*.tsq)'; ...
                  '*.mat', 'MATLAB (*.mat)'; ...
                  '*.nigelBlock', 'nigelBlock (*.nigelBlock)'; ...
                  '*.*', 'All Files (*.*)'},obj.InPrompt,obj.InDef);
               if f == 0
                  p = '';
                  f = '';
                  return;
               end
            case 'folder'
               f = '';
               p = uigetdir(obj.InDef,obj.InPrompt);
               if p == 0
                  p = '';
               end
            otherwise
               error(['nigeLab:' mfilename ':BadString'],...
               '"InputType" must be ''File'' or ''Folder''');
         end
         
      end
      
      % Set the save location for nigelobj
      function flag = getSaveLocation(obj,saveLoc)
         % GETSAVELOCATION   Set obj.SaveLoc for container folder
         %                   that holds the file hierarchy referenced by
         %                   nigelObj.
         %
         %  flag = obj.GETSAVELOCATION; 
         %  --> Prompts for NIGELOBJ location from a user interface (UI)
         %
         %  flag = obj.GETSAVELOCATION('save/path/here'); 
         %  --> Skips the selection interface
         
         % Reporter flag for whether this was executed properly
         flag = false;
         if ~isscalar(obj)
            error(['nigeLab:' mfilename ':BadInputSize'],...
               'nigeLab.obj/getSaveLocation only works for scalar inputs.');
         end
         
         % Prompt for location using previously set location
         if nargin < 2
            tmp = uigetdir(obj.OutDef,obj.OutPrompt);
         elseif isempty(saveLoc) % if nargin is < 2, will throw error if above
            tmp = uigetdir(obj.OutDef,obj.OutPrompt); 
         else
            tmp = saveLoc;
         end
         
         % Abort if cancel was clicked, otherwise set it
         if tmp == 0
            error(['nigeLab:' mfilename ':selectionCanceled'],...
               'No selection while setting save path for %s (%s)',...
               obj.Name,obj.Type);
         else
            % Make sure it's a valid directory, as it could be provided through
            % second input argument:
            obj.Output = tmp;
            if ~obj.genPaths
               mkdir(obj.Out.SaveLoc);
               if ~obj.genPaths
                  error(['nigeLab:' mfilename ':badFileLocation'],...
                      'Invalid savelocation detected\n.');
               end             
            end
            
               
               flag = true;
            
         end
      end
      
      % Connect data saved diskfile to the obj
      function flag = linkToData(obj,suppressWarning)
         %LINKTODATA  Connect the data saved on the disk to the structure
         %
         %  b = nigeLab.Block;
         %  flag = linkToData(b);
         %  linkToData(b,true) % suppress warnings
         %
         %  linkToData(b,'Raw');   % only link 'Raw' field
         %
         %  linkToData(b,{'Raw','Filt','AnalogIO'}); % only link 'Raw','Filt',and
         %                                           % 'AnalogIO' fields
         %
         % flag returns true if something was not "linked" correctly. Using the flag
         % returned by nigeLab.Block.linkField, this method issues warnings if not
         % all the files are found during the "link" process.
         
         % If not otherwise specified, assume extraction has not been done.
         if nargin < 2
            suppressWarning = false;
         end           

         if numel(obj) > 1
            flag = true;
            for i = 1:numel(obj)
               flag = flag && linkToData(obj(i),suppressWarning);
            end
            return;
         end
         
         if ismember(obj.Type,{'Animal','Tank'})
            flag = true;
            for i = 1:numel(obj.Children)
               if ~isempty(obj.Children(i))
                  c = obj.Children(i);
                  if isvalid(c)
                     flag = flag && linkToData(c,suppressWarning);
                  end
               end
            end
            flag = flag && obj.save();
            return;
         end
         
      end
      
      % Load .Pars from _Pars.mat or load a sub-field .Pars.(parsField)
      function flag = loadParams(obj,parsField)
         %LOADPARAMS   Load .Pars or .Pars.(parsField) from (user) file
         %
         %  obj.loadParams();  Load all of obj.Pars from file
         %  obj.loadParams(parsField); Load just that field of .Pars
         
         if numel(obj) > 1
            flag = true;
            for i = 1:numel(obj)
               if nargin < 2
                  flag = flag && obj(i).loadParams();
               else
                  flag = flag && obj(i).loadParams(parsField);
               end
            end
            return;
         else
            flag = false;
         end
         [fmt,idt,type] = obj.getDescriptiveFormatting();
         nigeLab.utils.cprintf(fmt,'%s[LOADPARAMS]: ',idt);
         fmt = fmt(1:(end-1));
         if nargin < 2
            if ~obj.HasParsFile
               if ~obj.checkParsFile()
                  nigeLab.utils.cprintf(fmt,...
                     'No %sObj.Pars file for %s (.User: %s)\n',...
                     lower(type),obj.Name,obj.User);
                  % Flag returns false
                  return;
               end
            end
         else
            if ~obj.checkParsFile(parsField)
               nigeLab.utils.cprintf(fmt,...
                  'No Pars.%s field saved for %s (.User: %s)\n',...
                  parsField,obj.Name,obj.User);
               % Flag returns false
               return;
            end
         end
         [~,~,s_all] = listInitializedParams(obj);
         
         fname_params = obj.getParsFilename();
         try
            in = load(fname_params);
         catch
            nigeLab.utils.cprintf('Errors*',...
               'Failed to load %sObj.Pars (file: %s)\n',...
               lower(type),fname_params);
            % Flag returns false
            flag = false;
            return;
         end
         if isempty(obj.Pars)
            obj.Pars = struct;
         end
         if nargin < 2
            obj.Pars = in.(obj.User);
            F = fieldnames(obj.Pars);
            flag = false(size(s_all));
            for iF = 1:numel(F)
               f = F{iF};
               idx = ismember(s_all,f);
               if sum(idx)==1
                  obj.HasParsInit.(f) = true;
                  obj.HasParsSaved.(f) = true;
                  flag(idx) = true;
               end
            end
            nigeLab.utils.cprintf(fmt,...
                  '%sObj.Pars.(ALL) loaded for %s (.User: %s)\n',...
                  lower(type),obj.Name,obj.User);
         else
            obj.Pars.(parsField) = in.(obj.User).(parsField);
            obj.HasParsInit.(parsField) = true;
            obj.HasParsSaved.(parsField) = true;
            nigeLab.utils.cprintf(fmt,...
                  '%sObj.Pars.%s loaded for %s (.User: %s)\n',...
                  lower(type),parsField,obj.Name,obj.User);
            flag = true; % Only 1 field: it was loaded, so returns true
         end
      end
      
      % Marks all files as complete
      function markFilesAsComplete(obj,field)
         %MARKFILESASCOMPLETE  Mark all files as complete
         %
         %  markFilesAsComplete(obj);
         %  --> Iterates on all fields of nigelObj
         %
         %  markFilesAsComplete(obj,field);
         %  --> Specify a specific field
         
         if nargin < 2
            field = obj.Fields;
         elseif isempty(field)
            fprintf(1,...
               ['\t\t->\t<strong>[MARKFILESASCOMPLETE]:</strong>\n' ...
               '\t\t--\t\t(No fields to mark)\t\t--\n']);
            return;
         end
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               if obj(i).Verbose && strcmp(obj(i).Type,'Block')
                  fprintf(1,...
                        '\t\t->\t<strong>[MARKFILESASCOMPLETE]::</strong>%s\n', ...
                        obj(i).Name);
                  if iscell(field)
                     fprintf(1,...
                        '\t\t\t->\tMarking <strong>%s</strong> as Complete.\n',...
                        field{end:-1:1});
                  else
                     fprintf(1,...
                        '\t\t\t->\tMarking <strong>%s</strong> as Complete.\n',...
                        field);
                  end
               end
               markFilesAsComplete(obj(i),field);
               if obj(i).Verbose && strcmp(obj(i).Type,'Block')
                  fprintf(1,'\b:<strong>complete</strong>\n');
               end
            end
            return;
         end
         
         if ismember(obj.Type,{'Tank','Animal'})
            markFilesAsComplete(obj.Children,field);
            return;
         end
         
         if iscell(field)
            for i = 1:numel(field)
               markFilesAsComplete(obj,field{i});
            end
            return;
         end
         
         if ismember(field,obj.Fields)
            ft = getFieldType(obj,field);
            if isfield(obj.(ft),field)
               for iCh = 1:numel(obj.(ft))
                  if isa(obj.(ft)(iCh).(field),'nigeLab.libs.DiskData')
                     obj.(ft)(iCh).(field).Complete = ones(1,1,'int8');
                     continue;
                  end

                  if isfield(obj.(ft)(iCh).(field),'data')
                     for ii = 1:numel(obj.(ft)(iCh).(field))
                        if isa(obj.(ft)(iCh).(field)(ii).data,'nigeLab.libs.DiskData')
                           obj.(ft)(iCh).(field)(ii).data.Complete = ones(1,1,'int8');
                        end
                     end
                  end
               end
            end
         end
         if obj.Verbose
            nBackSpace = 28 + numel(field);
            fprintf(1,repmat('\b',1,nBackSpace));
         end
      end
      
      % Method to MOVE files to new location
      function Move(obj,newLocation)
         %MOVE  Moves files to new location and updates paths
         %
         %  obj.Move();  
         %  --> Brings up UI to select "move to" location
         %
         %  obj.Move(newLocation);
         %  --> Similar to calling "updatePaths(newLocation)"
         
         if nargin < 2
            newLocation = uigetdir(obj.Out.Folder,obj.OutPrompt);
            if newLocation == 0
               nigeLab.utils.cprintf('Errors','No selection\n');
               return;
            end
         end
         new = nigeLab.utils.getUNCPath(newLocation);
         old = nigeLab.utils.getUNCPath(obj.Out.SaveLoc);
         if ~strcmp(new,old)
            choice = questdlg(...
               sprintf('Move %s files?\n-> %s\n to\n-> %s',...
               obj.Type,nigeLab.utils.shortenedPath(old),...
               nigeLab.utils.shortenedPath(new)),...
               'Confirm File Move','Yes','No','Yes');
            if strcmp(choice,'No')
               nigeLab.utils.cprintf('Errors','Move canceled\n');
               return;
            end
         end
         if ~obj.updatePaths(new)
            [~,idt,type] = obj.getDescriptiveFormatting();
            error(['nigeLab:' mfilename ':BadFileMove'],...
               '%sFile move unsuccessful for [%s]: %s\n',idt,type,...
               obj.Name);
         end
      end
      
      % Method to request nigeLab.libs.DashBoard constructor
      function nigelDash(obj)
         %NIGELDASH  Method to request nigeLab.libs.DashBoard GUI
         %
         %  obj.nigelDash();
         %  --> This is the ONLY way to construct DashBoard from base
         %      workspace:
         %        >> nigeLab.libs.DashBoard(tankObj) --> Must run fron tank
         %
         %  Note: I don't see a need to attach an output to this. I can't
         %        think of a reason that we would want the
         %        nigeLab.libs.DashBoard object in the base workspace.
         
         
         
         requestDash(obj);         
      end
      
      % Remove a child object from parent obj
      function removeChild(obj,ind)
         %REMOVECHILD  Removes the Child object specified by index `ind`
         %
         %  Removes .Children element from obj and deletes
         %     any associated files.
         %
         %  obj.removeChild(1:10); Deletes children indexed 1 to 10
         
         if nargin<2
            error(['nigeLab:' mfilename ':TooFewInputs'],...
               'Not enough input args, no Child objects removed.');
         end
         switch class(ind)
             case 'double'
                 ...Nothing really to do here
             case {'nigeLab.Block','nigeLab.Animal','nigeLab.nigelObj'}
                    ind = find(ismember( obj.Children,ind,"legacy"));
             otherwise
         end
         ind = sort(ind,'descend');
         ind = reshape(ind,1,numel(ind)); % Make sure it is correctly oriented
         for ii = ind
            p = obj.Children(ii).Out.Folder;
            if exist(p,'dir')
               rmdir(p,'s');
            end
            fname = obj.Children(ii).Out.File;
            if exist(fname,'file')~=0
               delete(fname);
            end
            pname = obj.Children(ii).Out.Pars;
            if exist(pname,'file')~=0
               delete(pname);
            end
            delete(obj.Children(ii).TreeNodeContainer);
            delete(obj.Children(ii));
            % After this it should automagically remove it from the
            % Children array thanks to some listener
         end
         
      end
      
      % Reload a specific field from _Obj.mat file
      function reload(obj,field)
         % RELOAD  Reload a specific field of obj
         %
         %  reload(obj,'Status');
         %  --> Would reload the 'Status' from _Obj.mat file; for example,
         %      after a 'Splitting' was completed or a remote queue job is
         %      finished.
         
         if nargin < 2
            field = 'all';
         end
         
         switch class(obj)
             % nigelObj specific operations
             case 'nigeLab.Tank'
                 MetaProperties = ?nigeLab.Tank;
                 animals = obj.Children;
                 for ii=1:numel(animals)
                     an = obj.Children(ii);
                     an.reload;
                     an.Parent = obj;
                 end
                 
             case 'nigeLab.Animal'
                 MetaProperties = ?nigeLab.Animal;
                 blocks = obj.Children;
                 for ii=1:numel(blocks)
                     bl = obj.Children(ii);
                     bl.reload;
                     bl.Parent = obj;
                 end
             case 'nigeLab.Block'
                 MetaProperties = ?nigeLab.Block;
         end
         transientIdx = [MetaProperties.PropertyList.Transient];
         transientList = {MetaProperties.PropertyList(transientIdx).Name};
         varName = sprintf('%sObj',lower(obj.Type));
         new = load(obj.Out.File,varName);
         ff=fieldnames(new.(varName));
         if strcmpi(field,'all')
             field = ff;
         end
         field = setdiff(field,transientList);
         indx = find(ismember(ff,field))';
         for f=indx
             obj.(ff{f}) = new.(varName).(ff{f});
         end
         
      end
      
      % Method to save any parameters as a .mat file for a given User
      function flag = saveParams(obj,userName,parsField,forceSave)
         %SAVEPARAMS  Method to save obj.Pars, given obj.User
         %
         %  obj.saveParams();  
         %  --> Uses .Pars and .User fields to save
         %
         %  obj.saveParams('user'); 
         %  --> Assigns current parameters to username 'user' and updates 
         %      obj.User to 'user'.
         %
         %  obj.saveParams('user','Sort'); 
         %  --> Only saves 'Sort' parameters under the variable 'user' in 
         %      the _Pars.mat file
         %
         %  obj.saveParams(___,forceSave);
         %  --> Optional flag that if set true forces all .Pars fields to
         %        be saved in file regardless of their .HasParsSaved status
         %
         %  flag = obj.saveParams(__);
         %  --> Returns true if save was successful
         
         flag = false;
         if isempty(obj)
            % Then this is in the constructor or the block has otherwise
            % not yet been initialized. So we did not yet save the params
            % file since User probably is not yet set (.HasParsFile =
            % false)
            flag = true;
            return;
         end
         
         if nargin < 2
            userName = obj.User;
         elseif isempty(userName)
            userName = obj.User;
         end
         
         if nargin < 3
            parsField = 'all';
         elseif isempty(parsField)
            parsField = 'all';
         end
         
         if nargin < 4
            forceSave = false;
         end
         
         if numel(obj) > 1
            flag = true;
            for i = 1:numel(obj)
               flag = flag && obj(i).saveParams(userName,parsField,forceSave);
            end
            return;
         end
         
         fname_params = obj.getParsFilename();
         if isempty(fname_params)
            % Then this is in the constructor or otherwise the block has
            % not yet been initialized
            flag = true;
            return;
         end
         [pname,fname,ext] = fileparts(fname_params);
         pname = nigeLab.utils.shortenedPath(strrep(pname,'\','/'));
         fname = nigeLab.utils.shortenedName([fname ext]);
         
         [fmt,idt,type] = obj.getDescriptiveFormatting();
         nigeLab.utils.cprintf(fmt,'%s[SAVEPARAMS]: ',idt);
         fmt = fmt(1:(end-1));
         if ~ismember(lower(parsField),{'all','reset'})
            if ~isfield(obj.HasParsSaved,parsField)
               obj.HasParsSaved.(parsField) = false;
            elseif obj.HasParsSaved.(parsField) && ~forceSave
               flag = true;
               dbstack();
               nigeLab.utils.cprintf(fmt,...
                  '%s is up-to-date for Pars.%s\n',...
                  fname_params,parsField);
               return;
            end
         end
         
         if exist(fname_params,'file')==0
            out = struct;
            out.(userName) = obj.Pars;
            nigeLab.utils.cprintf(fmt,...
               'Creating new %sObj.Pars file: %s%s (User: %s)\n',...
               lower(type),pname,fname,userName);
            f = fieldnames(obj.Pars);
            for i = 1:numel(f)
               obj.HasParsSaved.(f{i}) = true;
            end
         else
            % Don't just load single-user, load all uesrs, then select.
            out = load(fname_params);
            if ~isfield(out,userName)
               out.userName = struct;
            end
            switch parsField
               case 'all'
                  [~,~,s_all] = listInitializedParams(obj);
                  nigeLab.utils.cprintf(fmt,...
                     'Merging %sObj.Pars into %s%s (User: %s)\n',...
                     lower(type),pname,fname,userName);
                  for i = 1:numel(s_all)
                     if isfield(obj.Pars,s_all{i})
                        out.(userName).(s_all{i})=obj.Pars.(s_all{i});
                        obj.HasParsSaved.(s_all{i}) = true;
                     end
                  end
               case 'reset'
                  nigeLab.utils.cprintf(fmt,...
                     'Clearing %s%s (User: %s)\n',...
                     type,pname,fname,userName);
                  out.(userName)=struct;
               otherwise
                  nigeLab.utils.cprintf(fmt,...
                     'Overwriting Pars.%s in %s%s (User: %s)\n',...
                     parsField,pname,fname,userName);
                  out.(userName).(parsField)=obj.getParams(parsField);
                  obj.HasParsSaved.(parsField) = true;
            end
         end
         save(fname_params,'-struct','out');
         obj.HasParsFile = true;
         flag = true;
      end
      
      % Method to SET PARAMETERS (e.g. for updating saved parameters)
      function flag = setParams(obj,parsField,varargin)
         % SETPARAMS  "Set" a parameter so that it is updated in diskfile
         %
         %  parsField : Char array; member of fieldnames(obj.Pars)
         %
         %  varargin : Intermediate fields; last element is always value.
         %
         %  value = obj.Pars.Sort;
         %  obj.setParams('Sort',value);
         %  --> First input is always name of .Pars field
         %     --> This call would just update obj.Pars.Sort to
         %         whatever is currently in obj.Pars.Sort (and
         %         overwrite that in the corresponding 'User' variable of
         %         the _Pars.mat file)
         %
         %  value = obj.Pars.Video.CameraKey.Index;
         %  obj.setParams('Video','CameraKey','Index',value);
         %  --> Updates specific field of CameraKey Video param (Index)
         %
         %  flag = obj.setParams(___);
         %  --> Returns true if set was completed correctly
         
         flag = false;
         
         if numel(obj) > 1
            flag = true;
            for i = 1:numel(obj)
               flag = flag && obj(i).setParams(parsField,varargin{:});
            end
            return;
         end
         
         val = varargin{end};
         f = varargin(1:(end-1));
         if ~isfield(obj.Pars,parsField)
            obj.updateParams(parsField);
         end
         s = obj.Pars.(parsField);
         
         % Do error check
         for i = 1:numel(f)
            if ~isfield(s,f{i})
               error(['nigeLab:' mfilename ':MissingField'],...
                  '[SETPARAMS]: Missing field (''%s'') of (obj.Pars.%s...)\n',...
                  f{i},parsField);
            end
         end
         
         % Check to see if there are any assigned differences
         if numel(f) > 0
            p = s.(f{i});
            % Do assignment using substruct and subsasgn
            types_and_subs = [repmat({'.'},1,numel(varargin)); ...
                              parsField, f];
            S = substruct(types_and_subs{:});
            obj.Params.Pars = builtin('subsasgn',obj.Params.Pars,S,val);
         else
            p = s;
            obj.Params.Pars.(parsField) = val;
         end
         isDifferent = ~isequal(p,val);

         flag = true;
         % Save that field after assignment
         if isDifferent
            % Only overwrite params if it's a new set of params
            flag = flag && obj.saveParams(obj.User,parsField);
         end
         
      end
      
      % Method to set Property with some checking if it exists
      function setProp(obj,varargin)
         % SETPROP  Sets property of all blocks in array to a value
         %
         %  Uses <'Name', value> pairs to identify the property name.
         %
         %  setProp(obj,'prname',PrVal);
         %  --> Set the name of a property without matching case
         %
         %  setProp(obj,'PrNameStruct.Field1.Field2',PrVal);
         %  --> Set individual struct field property without resetting the
         %        whole struct.
         %     (Up to 2 fields "deep" max., to avoid using eval syntax)
         %
         %  obj.setProp('PrName1',PrVal1,'PrName2',PrVal2,...);
         %  --> Set multiple property values at once
         %
         %  setProp(objArray,'PrName1',PrVal1,'PrName2',PrVal2,...);
         %  --> Set multiple properties of multiple blocks at once
         
         if isempty(obj)
            return;
         end
         
         % Allow multiple properties to be set at once, for multiple blocks
         if numel(varargin) > 2
            for iV = 1:2:numel(varargin)
               setProp(obj,varargin{iV},varargin{iV+1});
            end
            return;
         elseif numel(varargin) < 2
            error(['nigeLab:' mfilename ':TooFewInputs'],...
               'Not enough inputs to `setProp` (gave %g, need 3)',nargin);
         else % numel(varargin) == 2
            if numel(obj) > 1
               for i = 1:numel(obj)
                  setProp(obj(i),varargin{1},varargin{2});
               end
               return;
            end
            
            if ~ischar(varargin{1})
               error(['nigeLab:' mfilename ':BadInputType'],...
                  'Expected input 2 to be char but got %s instead.',...
                  class(varargin{1}));
            end
            propVal = varargin{2};
            propField = strsplit(varargin{1},'.');
            propName = propField{1};
            propField(1) = []; % Drop the first cell in array
            % If it is now empty, we were not trying to set a struct field
         end
         
         % Parse case-sensitivity on property
         mc = metaclass(obj);
         propList = {mc.PropertyList.Name};
         idx = ismember(lower(propList),lower(propName));
         if sum(idx) < 1
            nigeLab.utils.cprintf('Comments',obj.Verbose,...
               'No %s property: %s',...
               class(obj),propName);
            return;
         elseif sum(idx) > 1
            idx = ismember(propList,propName);
            if sum(idx) < 1
               nigeLab.utils.cprintf('Comments',obj.Verbose,...
                  'No %s property: %s',...
                  class(obj),propName);
               return;
            elseif sum(idx) > 1
               error(['nigeLab:' mfilename ':AmbiguousPropertyName'],...
                  ['[SETPROP]: Bad obj Property naming convention.\n'...
                  'Avoid Property names that have case-sensitivity.\n'...
                  '->\tIn this case ''%s'' vs ''%s'' <-\n'],propList{idx});
            end
         end
         thisProp = propList{idx};
         
         % Last, assignment depends on if 'field' values were requested
         switch numel(propField)
            case 0
               % Does some validation, in case properties were read
               % directly from a text file for example; but not an
               % extensive amount.
               if isnumeric(obj.(thisProp)) && ischar(propVal)
                  obj.(thisProp) = str2double(propVal);
               elseif islogical(obj.(thisProp)) && ischar(propVal)
                  obj.(thisProp) = logical(str2double(propVal));
               elseif iscell(obj.(thisProp)) && ischar(propVal)
                  obj.(thisProp) = {propVal};
               else
                  obj.(thisProp) = propVal;
               end
               
            case 1
               a = propField{1};
               if isfield(obj.(thisProp),a)
                  if isnumeric(obj.(thisProp).(a)) && ischar(propVal)
                     obj.(thisProp).(a) = str2double(propVal);
                  elseif islogical(obj.(thisProp).(a)) && ischar(propVal)
                     obj.(thisProp).(a) = logical(str2double(propVal));
                  elseif iscell(obj.(thisProp).(a)) && ischar(propVal)
                     obj.(thisProp).(a) = {propVal};
                  else
                     obj.(thisProp).(a) = propVal;
                  end
               else
                  obj.(thisProp).(a) = propVal;
               end
               
            case 2
               a = propField{1};
               b = propField{2};
               if isfield(obj.(thisProp),a)
                  if isfield(obj.(thisProp).(a),b)
                     if isnumeric(obj.(thisProp).(a).(b)) && ischar(propVal)
                        obj.(thisProp).(a).(b) = str2double(propVal);
                     elseif islogical(obj.(thisProp).(a).(b)) && ischar(propVal)
                        obj.(thisProp).(a).(b) = logical(str2double(propVal));
                     elseif iscell(obj.(thisProp).(a).(b)) && ischar(propVal)
                        obj.(thisProp).(a).(b) = {propVal};
                     else
                        obj.(thisProp).(a).(b) = propVal;
                     end
                  else
                     obj.(thisProp).(a).(b) = propVal;
                  end
               else
                  obj.(thisProp).(a).(b) = propVal;
               end
               
            otherwise
               % Shouldn't have more than 3 fields (could use eval here,
               % but prefer to avoid eval whenever possible).
               error(['nigeLab:' mfilename ':TooManyStructFields'],...
                  ['[%s/SETPROP]: Too many ''.'' delimited fields.\n' ...
                  'Max 2 ''.'' for struct Properties.'],upper(obj.Type));
         end
      end
      
      % Method to set username
      function setUser(obj,userName)
         %SETUSER  Method to set user currently working on block
         %
         %  obj.setUser();       Sets User to obj.Pars.Video.User
         %                             (if it exists) or else random hash
         %  obj.setUser('MM');   Sets User property to 'MM'
         
         if numel(obj) > 1
            for i = 1:numel(obj)
               if nargin < 2
                  setUser(obj(i));
               else
                  setUser(obj(i),userName);
               end
            end
            return;
         end
         
         if nargin < 2 || isempty(userName)
            if isstruct(obj.Pars) && ~isempty(obj.Pars)
               if isfield(obj.Pars,'Experiment')
                  if isfield(obj.Pars.Experiment,'User')
                     userName = obj.Pars.Experiment.User;
                  else
                     userName = nigeLab.utils.makeHash();
                     userName = userName{:}; % Should be char array
                  end
               else
                  userName = nigeLab.utils.makeHash();
                  userName = userName{:};
               end
            else
               userName = nigeLab.utils.makeHash();
               userName = userName{:};
            end
         end
         
         obj.UserContainer = userName; % Assignment
         obj.checkParsFile();
      end
      
      % Invokes the spike-sorting interface
      function Sort(obj)
         %SORT  Invoke the spike-sorting interface
         %
         %  Sort(obj);
         %  --> Sets obj.SortGUI to nigeLab.Sort class object
         
         % Make sure that parameters have been set
         parsIdx = arrayfun(@(o) isfield(o.HasParsInit,'Sort'),obj);
         if any(~parsIdx)
            obj(~parsIdx).updateParams('Sort','Direct');
         end
        initParsIdx= arrayfun(@(o) getfield(o.HasParsInit,'Sort'),obj);
         if any(~initParsIdx)
            obj(~initParsIdx).updateParams('Sort','KeepPars');
         end
         % Update the `SortGUI` property
         set(obj,'SortGUI',nigeLab.Sort(obj));
      end
      
      % Update .Pars property
      function [flag,p] = updateParams(obj,paramType,method,p)
         % UPDATEPARAMS   Update the parameters struct property for
         % paramType
         %
         %  flag = updateParams(obj); flag = updateParams(obj,paramType);
         %  flag = updateParams(obj,paramType,forceFromDefaults); 
         %  [flag,p] = udpdateParams(__); Returns updated parameters
         %
         %  --------
         %   INPUTS
         %  -------- 
         %     obj      :     nigeLab.obj class object.
         %
         %  paramType   :     (optional; char array) Name of param
         %                    -> Can be passed as cell array to update
         %                          multiple parameters.
         %                    -> If specified as 'all', then initializes
         %                       all parameters fields except for `Tempdir`
         %                       and `nigelColors`
         %
         %                    -> Can be following "special" cases:
         %                       * 'all' -- update ALL parameters fields
         %                       * 'init' -- Initialize parameters fields
         %                       * 'check'  -- Only checks fields of
         %                                      HasParsInit
         %                      --> Returns true if all pars are
         %                          initialized --> 2nd output is list of
         %                          non-initialized params
         %                       * 'fullcheck'  -- Same as 'check', but:
         %                      --> Checks that pars have correct
         %                             fields in them, if they already have
         %                             'init' flag
         %
         %                       * 'reset' -- wipe current parameters and
         %                                   reset using defaults
         %
         %  method  :            * Can be: 
         %                          + 'Direct'
         %                          --> Auto-loads from +defaults file
         %
         %                          + 'LoadOnly'
         %                          --> Auto-loads from _Pars.mat ONLY (no
         %                                comparisons made)
         %
         %                          + 'KeepPars'
         %                          --> Tries to load from _Pars file
         %                          --> If fields of +defaults are missing,
         %                              uses values from +defaults to fill
         %                              in missing fields.
         %                          --> Checks for conflicts in
         %                              "non-missing" fields (from loaded
         %                              pars struct); if they are
         %                              different, keeps values from _pars
         %                              file.
         %
         %                          + 'KeepDefs'
         %                          --> Tries to load from _Pars file
         %                          --> If fields of +defaults are missing,
         %                              uses values from +defaults to fill
         %                              in missing fields.
         %                          --> Checks for conflicts in
         %                              "non-missing" fields (from loaded
         %                              pars struct); if they are
         %                              different, overwrites .Pars using
         %                              values from +defaults file.
         %
         %                          + 'InitOnly' (default)
         %                          --> Only checks for pars.HasParsInit; 
         %                              if field is present and true, then
         %                              no load occurs.
         %
         %                          + 'Inherit'
         %                          --> Automatically inherit whatever
         %                              value is contained in the struct p
         %
         %     p        :           Optional parameters passed directly to
         %                          update. Should be given as a struct
         %                          with fields corresponding to
         %                          obj.Pars.(paramType)
         %
         %  --------
         %   OUTPUT
         %  --------
         %    flag      :     Flag indicating if setting new path was
         %                    successful.
         
         % If no "pass-down" params struct, leave p as empty struct     
         if nargin < 4
            p = struct.empty;
         end
         
         % Default "method" behavior is check .HasParsInit.(paramType)
         if nargin < 3
            method = 'InitOnly';
         end
         
         % If no arguments specified, then update all parameters
         if nargin < 2
            paramType = 'all';
         end
         
         % Iterate if given array input
         if numel(obj) > 1
            flag = true;
            for i = 1:numel(obj)
               flag = flag && obj(i).updateParams(paramType,method,p);
            end
            return;
         else
            flag = false;
         end
         
         % Handle empty or invalid objects
         if ~isvalid(obj)
            flag = true;
            return;
         end         
       
         % If multiple paramType given as a cell, iterate on cell elements
         if iscell(paramType)
            % Changing this, the other way is less efficient
            flag = true;
            for i = 1:numel(paramType)
               flag = flag && obj.updateParams(paramType{i},method,p);
            end
            return;
            % Otherwise, paramType must be a char array
         elseif ~ischar(paramType)
            error(['nigeLab:' mfilename ':BadInputClass'],...
               ['[%s/UPDATEPARAMS]: nigeLab.%s/updateParams expects ' ...
               'paramType to be cell or char'],upper(obj.Type),obj.Type);
         end % iscell(paramType)

         % Handle the behavior for "special" non-paramType commands
         [~,p_miss,p_all] = obj.listInitializedParams();
         switch lower(paramType)
            case 'all' %Update all parameters using "method" method
               flag = obj.updateParams(p_all,method);
               return;
            case 'init' %Initialize "HasParsInit" struct
               for i = 1:numel(p_all)
                  obj.HasParsInit.(p_all{i}) = false;
                  obj.HasParsSaved.(p_all{i}) = false;
               end
               flag = obj.updateParams('all','Direct');
               return;
            case 'check' %Checked for "non-initialized" props
               flag = isempty(p_miss); 
               p = reshape(p_miss,1,numel(p_miss));
               return;
            case {'fullcheck','checkfull','full'} %Double-check all fields
               flag = true;
               for i = 1:numel(p_all)
                  if isfield(obj.HasParsInit,p_all{i})
                     if obj.HasParsInit.(p_all{i})
                        p = nigeLab.defaults.(p_all{i});
                        fcur = fieldnames(obj.Pars.(p_all{i}));
                        fdef = fieldnames(p); %fields in def. file params
                        fmiss = setdiff(fdef,fcur);
                        % If any params from defaults file are missing,
                        % then update using those params.
                        if ~isempty(fmiss)
                           flag = flag && ...
                              obj.updateParams(p_all{i},'KeepPars');
                        end
                     end
                  else
                     flag = flag && obj.updateParams(p_all{i},'Direct');
                  end
               end
               % Double-check for "non-initialized" props
               if flag
                  p = [];
               else
                  [~,p,~] = obj.listInitializedParams();
               end
               return;
            case 'reset' %Remove existing .Pars and load from +defaults
               obj.Params.Pars = struct;
               obj.HasParsInit = struct;
               obj.HasParsSaved = struct;
               % Reset saved params file and re-initialize from defaults
               flag = obj.saveParams(obj.User,'reset');
               flag = flag && obj.updateParams('init');
               return;
            otherwise %Anything else might be actual "paramType" of `.Pars`
               idx = find(strcmpi(p_all,paramType),1,'first');
               if isempty(idx)
                  [fmt,idt] = obj.getDescriptiveFormatting(); % For cmd win
                  nigeLab.utils.cprintf('Errors*',obj.Verbose,...
                     '%s[UPDATEPARAMS]: ',idt);
                  nigeLab.utils.cprintf(fmt,obj.Verbose,...
                     'Bad .Pars fieldname (''%s'')\n',paramType);
                  flag = false;
                  return;
               else % If there is a match, ensure correct capitalization
                  field = p_all{idx};
               end
         end % switch lower(paramType)
         
         % Format initial part of command window output
         [fmt,idt,type] = obj.getDescriptiveFormatting(); % For cmd window
         nigeLab.utils.cprintf(fmt,obj.Verbose,'%s[UPDATEPARAMS]: ',idt);
         fmt = fmt(1:(end-1)); % Rest is not bold
         
         % Handle behavior for known "good" (existing) paramType
         doComparison = false; % By default, skip comparison
         switch lower(method)
            case {'keepdefs'}% Check both, keep +defaults over _Pars file
               doComparison = true; 
               p = nigeLab.defaults.(field)(); % Load parameter defaults
            case {'inherit'} % "Inherit" from extra input 'p'
               flag = true;
               obj.HasParsInit.(field) = true;
               if ~isfield(obj.Pars,field)
                  obj.Pars.(field) = p;
                  obj.HasParsSaved.(field) = false;
               else
                  obj.HasParsSaved.(field) = isequal(obj.Pars.(field),p);
               end
               
               if obj.HasParsSaved.(field)
                  if obj.Verbose
                     dbstack();
                     nigeLab.utils.cprintf('[0.35 0.35 0.35]',...
                        '%sObj.Pars.%s (%s_Pars.mat) is up-to-date\n',...
                        lower(type),field,obj.Name);
                  end
                  return;
               end 
               obj.Pars.(field) = p;
               nigeLab.utils.cprintf('[0.35 0.35 0.35]',obj.Verbose,...
                  '%s Pars.%s inherited from Parent\n',...
                  obj.Name,field);
            case {'initonly','init'} % Load only if .HasParsInit is false
               if isfield(obj.HasParsInit,field)
                  obj.HasParsInit.(field) = ...
                     obj.HasParsInit.(field) && ...
                     isfield(obj.Pars,field);
               else
                  obj.HasParsInit.(field) = false;
                  obj.HasParsSaved.(field) = false;
               end
               if obj.HasParsInit.(field)
                  flag = true;
                  obj.HasParsSaved.(field) = true;
                  if obj.Verbose
                     dbstack();
                     nigeLab.utils.cprintf('[0.35 0.35 0.35]',...
                        '%sObj.Pars.%s (%s_Pars.mat) is up-to-date\n',...
                        lower(type),field,obj.Name);
                  end
               else
                  flag = obj.updateParams(field,'Direct');
                  nigeLab.utils.cprintf(fmt,obj.Verbose,...
                     '%sObj.Pars.%s must be initialized\n\t',...
                     lower(type),field);
                  flag = obj.updateParams(field,'Direct');
               end
               p = obj.Pars.(field);
               return;
            case {'keeppars'} % Keep params over +defaults
               doComparison = true;
               p = nigeLab.defaults.(field)(); % Load parameter defaults
            case {'loadonly'} % Load direct from _Pars.mat
               nigeLab.utils.cprintf(fmt,obj.Verbose,...
                  'Loading %sObj.Pars.%s directly from %s_Pars.mat\n\t',...
                  lower(type),field,obj.Name);
               flag = loadParams(obj,field);
               if flag
                  p = obj.Pars.(field);
                  obj.HasParsInit.(field) = true;
                  obj.HasParsSaved.(field) = true;
               else % By default p is struct.empty
                  return;
               end
            case {'direct'}  % Load direct from +defaults
               p = nigeLab.defaults.(field)(); % Load parameter defaults
               flag = true;
               obj.HasParsInit.(field) = true;
               if ~isfield(obj.Pars,field)
                  obj.HasParsSaved.(field) = false;
               else
                  obj.HasParsSaved.(field) = ~isequal(obj.Pars.(field),p);
               end
               obj.Pars.(field) = p;
               nigeLab.utils.cprintf(fmt,obj.Verbose,...
                  'Loaded directly from +defaults/%s.m file\n',...
                  field);
            otherwise % Otherwise, it is not recognized
               nigeLab.utils.cprintf('Errors*',obj.Verbose,...
                  'Unrecognized "method" behavior: %s\n',method);
               flag = false;
               return;
         end % switch lower(method)
         
         % If necessary, try to load (and compare) _Pars.mat
         if doComparison
            if loadParams(obj,field) % If successful load:
               if isequal(obj.Pars.(field),p)
                  if obj.Verbose
                     dbstack();
                     nigeLab.utils.cprintf([0.35 0.35 0.35],...
                        '%sObj.%s (%s_Pars.mat) parameters up-to-date\n',...
                        lower(type),field,obj.Name);
                  end
                  return; % No need to update anything else
               end
               % Otherwise, figure out what fields are missing or inequal
               fcur = fieldnames(obj.Pars.(field));
               fdef = fieldnames(p); % Default fieldnames (from file)
               fmiss = setdiff(fdef,fcur);
               if ~isempty(fmiss)
                  % Then our loaded params are missing parameter variables
                  for i = 1:numel(fmiss)
                     obj.Params.Pars.(field).(fmiss{i}) = p.(fmiss{i}); % So add
                  end
                  obj.HasParsInit.(field) = true;
                  if obj.Verbose
                     dbstack();
                     nigeLab.utils.cprintf(fmt,...
                        '%sObj.Pars.%s (%s_Pars.mat) was missing:\n',...
                        lower(type),field,obj.Name);
                     for i = 1:numel(fmiss)
                        nigeLab.utils.cprintf('[0.25 0.25 0.25]*',...
                           '\t%s<strong>%s</strong>\n',idt,fmiss{i});
                     end
                     nigeLab.utils.cprintf(fmt,...
                        '\n%s[UPDATEPARAMS]: ',idt);
                     nigeLab.utils.cprintf(fmt,...
                        ['Saving UPDATED %sObj.%s ' ...
                        '(Name: ''%s'' || User: ''%s'')\n'],...
                        lower(type),field,obj.Name,obj.User);
                  end
                  obj.HasParsSaved.(field) = false;
                  flag = obj.saveParams(obj.User,field);
                  p = obj.Params.Pars.(field);
                  
               else % Otherwise, have all vars, but values are different
                  switch lower(method)
                     case 'keepdefs' % Keep values from defaults file
                        flag = true;
                        obj.Params.Pars.(field) = p;
                        obj.HasParsSaved.(field) = false;
                        obj.HasParsInit.(field) = true;
                     case 'keeppars' % Keep values from pars file
                        flag = true;
                        p = obj.Params.Pars.(field); % For Children
                        obj.HasParsSaved.(field) = true;
                        obj.HasParsInit.(field) = true;
                     otherwise
                        error(['nigeLab:' mfilename ':BadCase'],...
                           ['[UPDATEPARAMS]: Unexpected case: ' ...
                           '(%s); check code.\n'],method);
                  end
               end
            else % Otherwise, couldn't load params from User file
               if obj.Verbose
                  dbstack();
                  nigeLab.utils.cprintf('Errors*',...
                     '%sObj.Pars.%s (%s_Pars.mat) failed to load.\n',...
                     lower(type),field,obj.Name);
                  obj.Params.Pars.(field) = p;
                  nigeLab.utils.cprintf(fmt,...
                     '\t%s(Loaded from +defaults/%s.m)\n',idt,field);
               end
               obj.HasParsInit.(field) = true;
               obj.HasParsSaved.(field) = false;
               flag = true;
            end
         end
         
         % Pass parameters to children
         for i = 1:numel(obj.Children)
            if ~isempty(obj.Children(i))
               if isvalid(obj.Children(i))
                  flag = flag && obj.Children(i).updateParams(...
                     field,'Inherit',obj.Pars.(field));
               end
            end
         end         
      end
      
       % Method to export data subset from nigeLab
       % TODO add other export formats (as kilosort)
      function flag = exportFiles(obj,SaveFolder,Fields)

          % Argin validation
          if isempty(obj)
            flag = true;
            return;
          end
          flag = false;
          if nargin < 2
              SaveFolder = fullfile(obj.Output,'Exported');
          elseif nargin <3
              Fields = obj.Fields';
          end

          if ~exist(SaveFolder,'dir')
              mkdir(SaveFolder);
          end

          % Main part: go down the tree and export Fields ince it gets to
          % block level.
          try
              
              oldPath = obj.Output;
              obj.Output = SaveFolder;
              obj.save;

              if strcmp(obj.Type,'Block')
                  % if it's block export the files
                      for ff = Fields
                          try
                              thisP = arrayfun(@(x)x.(ff{1}).getPath,bb.Channels,'UniformOutput',false);
                              for jj=1:numel(thisP)
                                  source = thisP{jj};
                                  target = fullfile(bb.Paths.(ff{1}).dir);
                                  copyfile(source,target);
                              end
                          catch
                              nigeLab.utils.cprintf('Errors','No field %s detected in block %s.%s\n',ff{1},aa.Name,bb.Name)
                          end%try
                      end%ff
              else
                  % Otherwise go down one level
                  objChl = obj.Children;
                  flag = true & exportFiles(objChl,SaveFolder,Fields);
              end
              
              obj.Output = oldPath;

          catch er
              nigeLab.utils.cprintf('Error',[er.message newline])
          end
      end

   end
   
   % HIDDEN,PUBLIC
   methods (Hidden,Access=public)
      % Check that `Key` is correctly formatted for shortcut indexing
      function value = IsRightKeyFormat(obj,subs)
         %ISRIGHTKEYFORMAT  True if `subs` is key or cell array of keys
         %
         %  value = IsRightKeyFormat(obj,subs);
         %
         %  obj   : nigeLab.nigelObj object or subclass
         %     --> If given as an array, uses getKey(obj(1),'Public') 
         %        (does not check key length against rest of object array)
         %  subs  : (cell array) input subscript args for shortcut indexing
         %
         %  value : (logical scalar) -- `true` if this is a valid key
         %
         %  Note: `value` is returned as `false` if:
         %     --> `obj` is empty, returns false
         %     --> `subs` is empty
         %     --> there is only one input argument

         value = false;
         if isempty(obj)
            return;
         end

         if nargin < 2
            return;
         elseif isempty(subs)
            return;
         end

         % Only returns Key of first element in array to check against
         key = getKey(obj(1),'Public');
         % Compares number of characters in Key
         KeyLength = numel(key);
         if ischar(subs) % If == # characters it is a Key
            value = numel(subs) == KeyLength;
         elseif iscell(subs) % If all cells have == # characters, then Key
            value = all( cellfun( @(x) ischar(x) && numel(x) == KeyLength,subs) );
         else % It is not a `.Key` format index
            value = false; 
         end
      end
      
      % Set some useful path variables to file locations
      function flag = genPaths(obj)
         %GENPATHS    Set some useful path variables to file locations
         %
         %  flag = GENPATHS(obj);
         %  flag = GENPATHS(obj,SaveLoc);
         %
         %     Defines all the paths where data will be saved.
         %     The folder tree is also created (if it doesn't exist)
         %
         %  obj.Paths is updated in this method.
         
         flag = false;
         
         SaveLoc = obj.Out.SaveLoc;
         if isempty(SaveLoc)
             [fmt,idt,type] = obj.getDescriptiveFormatting();
             dbstack;
             nigeLab.utils.cprintf('Errors*',obj.Verbose,...
                 '%s[GENPATHS]: ',idt);
             nigeLab.utils.cprintf(fmt,obj.Verbose,...
                 'Tried to build [%s].Paths using empty base\n',type);
             return;
         end
         
         
         if exist(obj.Out.Folder,'dir')==0
            mkdir(obj.Out.Folder);
         end
         flags = arrayfun(@(x)genPaths(x),obj.Children);
         flag = all(flags);
      end
      
      % Request that DashBoard opens
      function requestDash(obj,~,evt)
         %REQUESTDASH  Request to open the GUI
         %
         %  addlistener(child,'DashChanged',@obj.requestDash);
         
         if nargin < 3
            evt = nigeLab.evt.dashChanged('Requested');
         end
         doRequest = strcmpi(evt.Type,'Requested');
         if ~doRequest
            return;
         end
         if numel(obj) < 1
            return;
         end
         switch obj(1).Type % Since source is child object, cannot be Block
            case 'Block'
               % "Pass the notification up the chain"
               notify(obj,'DashChanged',evt);        
            case 'Animal'
               % "Pass the notification up the chain"
               notify(obj,'DashChanged',evt);
            case 'Tank'
               % Note that nigeLab.libs.DashBoard constructor is only
               % available from tankObj method nigeLab.nigelObj/nigelDash.
               if ~obj.IsDashOpen || isempty(obj.GUI)
                  obj.GUI = nigeLab.libs.DashBoard(obj);
               else
                  if isvalid(obj.GUI)
                     if isprop(obj.GUI,'nigelGUI')
                        figure(obj.GUI.nigelGUI);
                     else
                        obj.GUI = nigeLab.libs.DashBoard(obj);
                     end
                  else
                     obj.GUI = nigeLab.libs.DashBoard(obj);
                  end
               end
               % --> This is INTENTIONAL, so that the object corresponding
               %     to the figure is always "cleaned up" from the base
               %     workspace upon DashBoard destruction.
            otherwise
               error(['nigeLab:' mfilename ':BadType'],...
                     'nigelObj has bad Type (%s)',obj.Type);
         end
            
      end
   
      % filters obj based on Meta values
      function val = checkMeta(nigelObj,varargin)
%           CheckMETA return true if the values in varargin are present in
%           MEta property. Varargin needs to be even and takes struct-field
%           values pairs.           
%  example
%  checkMeta(nigelObj,'RecData','010121')
% 
%       This function is used in combination with subsref to implement the
%       metadata indexing
          if ~isQuery(varargin)
              error(['nigeLab:' mfilename ':badSubscriptReference'],...
                  'Wrong input format for queries.');
          end
          if numel(varargin) == 2
              val = compare(nigelObj.Meta.(varargin{1}), varargin{2});
              return
          end

          val = checkMeta(nigelObj,varargin{1:2}) & checkMeta(nigelObj,varargin{3:end});
      end

      function val = isQuery(subs)
          val = ~mod(numel(subs),2);
          val = val & all(cellfun(@ischar,subs(1:2:end)));
      end

      function val = compare(val1,val2)
          if isnumeric(val1) && isnumeric(val2)
              val = all(val1 == val2);
          elseif (ischar(val1) || isstring(val1)) && (ischar(val2) || isstring(val2))
              val = strcmpi(val1,val2);
          end
end

   end
   
   % PROTECTED
   methods (Access=protected)
      % Re-adds all child listeners to obj
      function addChildListeners(obj,C)
         %ADDCHILDLISTENERS  Re-adds all child listeners to obj
         %
         %  obj.addChildListeners(); Add listeners to all children
         %  obj.addChildListeners(childObj); Only adds to childObj
         
         if isa(obj,'nigeLab.Block')
            return; % Nothing to add
         end
         
         if ~isempty(obj.ChildListener)
            for lh = obj.ChildListener
               if isvalid(lh)
                  delete(lh);
                  obj.ChildListener(1) = [];
               end
            end
         end
         
         if nargin < 2
            C = obj.Children;
         end
         
         for i = 1:numel(C)
            if isempty(C(i))
               continue;
            else
               c = C(i);
               if ~isvalid(c)
                  continue;
               end
            end
            if ~strcmp(c.User,obj.User)
               c.setUser(obj.User);
            end            
            obj.ChildListener = [obj.ChildListener, ...
               addlistener(c,'ObjectBeingDestroyed',...
                  @(src,~)obj.assignNULL(src)), ...
               addlistener(c,'StatusChanged',...
                  @(~,evt)notify(obj,'StatusChanged',evt)), ...
               addlistener(c,'DashChanged',...
                  @obj.requestDash)];
            if strcmp(obj.Type,'Animal')
               obj.ChildListener = [obj.ChildListener, ...
                  addlistener(c,'IsMasked','PostSet',...
                     @(~,~)obj.parseProbes)];
            end
         end
      end
      
      % Adds listener handles to array property of obj
      function addPropListeners(obj)
         % ADDPROPLISTENERS  Called on initialization to build PropListener
         %                    property array.
         %
         %  obj.addPropListeners();
         %
         %  --> Creates 2-element vector of property listeners
         
         if isempty(obj)
            return;
         elseif numel(obj) > 1
            for i = 1:numel(obj)
               addPropListeners(obj(i));
            end
            return;
         end
         switch obj.Type
             case 'Block'
                 % Does not currently have PropListeners
             case 'Animal'
                 if ~checkForExistingListener(obj.PropListener,'PostSet',@obj.checkBlocksForClones)
                     obj.PropListener = [obj.PropListener, ...
                         addlistener(obj,'Children','PostSet',...
                         @obj.checkBlocksForClones)];
                 end
             case 'Tank'
                 if ~checkForExistingListener(obj.PropListener,'PostSet',@obj.checkAnimalsForClones)
                     obj.PropListener = [obj.PropListener,...
                         addlistener(obj,'Children','PostSet',...
                         @obj.checkAnimalsForClones)];
                 end
         end
         
          function flag = checkForExistingListener(listeners,EventName,Callback)
              if isempty(listeners) || all(~isvalid(listeners))
                 flag = false;
                 return;
              end
              flag = ismember({listeners.EventName},EventName) & ...
                  ismember({func2str(listeners.Callback)},func2str(Callback));
          end
      end
      
      % Assign default .Pars values (for use in constructor)
      function flag = assignDefaultPars(obj,str,val)
         %ASSIGNDEFAULTPARS  Assign default .Pars values
         %
         %  flag = obj.assignDefaultPars(str,val);
         %
         %  str  -- e.g. 'Block.NamingConvention'
         %  val  -- value to assign
         %
         %  Returns true if assignment was successful
         
         flag = false;
         f = strsplit(str,'.');
         f = reshape(f,1,numel(f));
         f = [repmat({'.'},1,numel(f)); f];

         S = substruct(f{:}); % Indexing struct array
         try
            obj.Pars = builtin('subsasgn',obj.Pars,S,val);
            flag = true;
         catch
            nigeLab.utils.cprintf('Errors',obj.Verbose,...
               'Could not assign Pars.%s value (%s)',str,val);
         end
      end
      
      % Remove Child from .Children array after deletion
      function assignNULL(obj,childObj)
         % ASSIGNNULL  Does null assignment to remove a block of a
         %             corresponding index from the obj.Children
         %             property array, for example, if that Block is
         %             destroyed or moved to a different obj. Useful
         %             as a callback for an event listener handle.
         
         idx = ~isvalid(obj.Children);
         if sum(idx) >= 1
            obj.Children(idx) = [];
         else
            [~,idx] = findByKey(obj.Children,childObj);
            if sum(idx) >= 1
               obj.Children(idx) = [];
            end
         end
         
         obj.addChildListeners();
         
      end
      
      % Event listener callback to make sure that duplicate Animals are not
      % added and if they are duplicated, that upon removal there are not
      % "lost" Child Blocks.
      function checkAnimalsForClones(obj,~,~)
         % CHECKANIMALSFORCLONES  Event listener callback invoked when a
         %                        new Animal is added to obj.Children.
         %
         %  obj.checkAnimalsForClones;  Ensure no redundancies in
         %                                   obj.Children.
         
         % If no animals or only 1 animal, no need to check
         A = obj.Children;
         if sum(isempty(A)) == 1
            return;
         else
            idx = ~isempty(A);
            A = A(idx);
         end
         % Get names for comparison
         cname = {A.Name};
         % look for animals with the same name
         comparisons_cell = cellfun(@(s) strcmp(s,cname),...
            cname,...
            'UniformOutput',false);
         comparisons_mat = logical(triu(cat(1,comparisons_cell{:}) - ...
            eye(numel(cname))));
         rmvec = any(comparisons_mat,1);
         correspondanceVec = any(comparisons_mat,2);
         if ~any(rmvec)
            return;
         end

         % cycle through each animal, removing animals and adding any
         % associated blocks to the "kept" animal Blocks property
         ii=1;
         while any(rmvec)             
             idxToRemove = find(rmvec,1);
             idxToKeep = find(correspondanceVec,1);
             a = A(idxToKeep);
             B = [A(idxToRemove).Children]; %#ok<*FNDSB>
             addChild(a,B);
             obj.Children(idxToRemove) = []; % Remove from property
             rmvec(idxToRemove) = [];
             correspondanceVec(idxToKeep) = [];
         end
      end
      
      % Ensure that there are not redundant Blocks in obj.Children
      % based on the .Name property of each member Block object
      function checkBlocksForClones(obj,~,~)
         % CHECKBLOCKSFORCLONES  Creates an nBlock x nBlock logical matrix
         %                       comparing each Block in obj.Children
         %                       to the Name of every other such Block.
         %                       After subtracting the main diagonal of
         %                       this matrix, any row with redundant
         
         % If no Blocks (or only 1 "non-empty" block) then there are no
         % clones in the array.
         b = obj.Children;
         if sum(~isempty(b)) <= 1
            return;
         else
            idx = find(~isempty(b));
            b = b(idx);
         end
         
         cname = b.getKey;
%          cname = {b.Name};
         
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
         obj.Children(idx(rmvec))=[];
         
      end
      
      % Check parameters file to set `HasParsFile` flag for this `User`
      function flag = checkParsFile(obj,parsField)
         %CHECKPARSFILE  Sets .HasParsFile for current .User
         %
         %  flag = obj.checkParsFile();
         %  flag = obj.checkParsFile(parsField);
         %     --> Returns flag indicating if that field is present
         %        --> If file does not exist, flag returns as true.
         
         flag = false;
         params_fname = obj.getParsFilename();
         if exist(params_fname,'file')==0
            obj.HasParsFile = false;
            flag = true;
            return;
         end
         
         userName = obj.User;
         try
            m = matfile(params_fname);
         catch
            warning(['nigeLab:' mfilename ':CHECKPARSFILE'],...
               '%s load issue: file may be corrupt.\n',params_fname);
            obj.HasParsFile = false;
            return;
         end
         allUsers = who(m);
         obj.HasParsFile = ismember(userName,allUsers);
         if nargin > 1
            if obj.HasParsFile
               flag = isfield(m.(userName),parsField);
            else
               flag = false;
            end
         else
            flag = obj.HasParsFile;
         end
      end
      
      % Check params to make sure they're initialized
      function parsAllReady = checkParsInit(obj,parsField)
         %CHECKPARSINIT  Check parameters to make sure they are initialized
         %                 and if not, then do so.
         %
         %  parsAllReady = obj.checkParsInit(); Check all parameters
         %  --> Equivalent to parsField = [];
         %  parsAllReady = obj.checkParsInit(parsField);  Just parsField
         %
         %  parsAllReady  --  Return true if parameters are ready to use
         %  --> If object is empty, this will return true as well
         
         if nargin < 2
            parsField = [];
         end
         
         if numel(obj) > 1
            parsAllReady = true;
            for i = 1:numel(obj)
               parsAllReady = parsAllReady && ...
                  checkParsInit(obj,parsField);
            end
            return;
         end
         
         if isempty(obj) % Skip it if it is empty, but don't fail check
            parsAllReady = true;
            return;
         end
         
         if isempty(obj.HasParsInit)
            parsAllReady = obj.updateParams('init');
         else
            parsAllReady = obj.updateParams('check');
            if ~parsAllReady % If some weren't initialized
               if isempty(parsField)
                  F = fieldnames(obj.HasParsInit).';
               else
                  parsField = reshape(parsField,1,numel(parsField));
                  F = intersect(parsField,fieldnames(obj.HasParsInit));
                  f_miss = setdiff(parsField,fieldnames(obj.HasParsInit));
                  parsAllReady = true;
                  for i = 1:numel(f_miss)
                     parsAllReady = parsAllReady && ...
                        obj.updateParams(f_miss{i},'Direct');
                  end
                  F = intersect(parsField,fieldnames(obj.HasParsInit));
                  if ~parsAllReady
                     f_miss = setdiff(parsField,F);
                     [fmt,idt,type] = obj.getDescriptiveFormatting();
                     nigeLab.utils.cprintf(fmt,obj.Verbose,...
                        ['%s[CHECKPARSINIT]: %s (%s) ' ...
                         'failed to initialize these parameters-\n'],...
                         idt,obj.Name,type);
                     for i = 1:numel(f_miss)
                        nigeLab.utils.cprintf('[0.40 0.40 0.40]*',...
                           obj.Verbose,'\t%s%s\n',idt,f_miss{i});
                     end
                     return;
                  else
                     % Make sure it is saved in case this is during check
                     % prior to sending to remote workers
                     save(obj);
                  end
               end
               for f = F
                  parsField = f{:};
                  % Remove potentially invalid fields
                  if ismember(parsField,{'Tempdir','nigelColors'})
                     obj.HasParsInit = rmfield(obj.HasParsInit,parsField);
                  else
                     if ~obj.HasParsInit.(parsField)
                        obj.HasParsInit.(parsField) = ...
                           obj.updateParams(parsField,'Direct');
                     end
                  end
               end
            end
         end
      end
      
      % Overload for matlab.mixin.CustomDisplay.displayNonscalarObject
      function displayNonscalarObject(obj)
         %DISPLAYNONSCALAROBJECT  Overload for displaying nigelObj array
         %
         % Overload of matlab.mixin.CustomDisplay.displayNonScalarObject to
         % change default output in Command Window for non-scalar nigelObj
         %
         % Note: reserved for future use; currently does same as built-in
         
         header = getHeader(obj);
         disp(header);
         
         groups = getPropertyGroups(obj,'nonscalar');
         matlab.mixin.CustomDisplay.displayPropertyGroups(obj,groups);
         
         footer = getFooter(obj,'simple');
         disp(footer);
      end
      
      % Overload for matlab.mixin.CustomDisplay.displayScalarObject
      function displayScalarObject(obj,displayType)
         %DISPLAYSCALAROBJECT  Overload for displaying nigelObj scalar
         %
         %  Overload of matlab.mixin.CustomDisplay.displayScalarObject to
         %  change default output in Command Window for a scalar nigelObj
         %
         %  obj.displayScalarObject(); Uses default
         %
         %  obj.displayScalarObject('detailed'); Shows more info
         
         if nargin < 2
            displayType = 'simple';
         end
         
         BaseVars = evalin('base','whos');
         TankIdx = strcmp({BaseVars.class},'nigeLab.Tank');
         if ~any(TankIdx)
             TankName = 'NaN';
         else
             TankName = BaseVars(TankIdx).name;
         end
         header = getHeader(obj);
         header = strrep(header,sprintf('>%s</a>',obj.Type),sprintf('>%s</a> %s',obj.Type,obj.Name));
         disp(header);
         
         groups = getPropertyGroups(obj,'scalar',TankName);
         switch lower(displayType)
            case 'simple'
               % Reduce groups to first array element
               groups = groups(1);
               
            case 'detailed'
               % Don't reduce groups
         end
         matlab.mixin.CustomDisplay.displayPropertyGroups(obj,groups);
         
         footer = getFooter(obj,displayType);
         footer = strrep(footer,'(PLACEHOLDER',sprintf('(%s',TankName));
         if ~isempty(obj.Parent)
         footer = strrep(footer,'NAMEPLACEHOLDER',obj.Parent.Name);
         end

         disp(footer);         
      end
      
      % Return `Substruct` array indices to "Methods" subscripts
      function [methodSubs,methodName,methodOutputs,methodInputs] = findMethodSubsIndices(obj,S)
         %FINDMETHODSUBSINDICES  Return array indices to methods subscripts
         %
         %  [methodSubs,methodName,methodOutputs,methodInputs] = ...
         %     obj.findMethodSubsIndices(S);
         %  methodSubs : Indices to substruct S that are methods
         %  methodName : Corresponding method name in metaclass method list
         %  methodOutputs : Number of outputs for corresponding method
         %  methodInputs : Number of inputs for corresponding method
         
         mc = metaclass(obj);
         m = {mc.MethodList.Name};
         methodSubs = [];
         methodName = [];
         methodOutputs = [];
         methodInputs = [];
         for i = 1:numel(S)
            if iscell(S(i).subs)
               if isempty(S(i).subs)
                  continue;
               elseif ischar(S(i).subs{1})
                  idx = ismember(m,S(i).subs{1});
                  if sum(idx) == 1
                     methodSubs = [methodSubs,i];
                     methodName = [methodName,m(idx)]; %#ok<*AGROW>
                     methodOutputs = [methodOutputs, ...
                        numel(mc.MethodList(idx).OutputNames)];
                     methodInputs = [methodInputs, ...
                        numel(mc.MethodList(idx).InputNames)];
                  end
               end
            elseif ischar(S(i).subs)
               idx = ismember(m,S(i).subs);
               if sum(idx) == 1
                  methodSubs = [methodSubs, i];
                  methodName = [methodName,m(idx)];
                  methodOutputs = [methodOutputs, ...
                        numel(mc.MethodList(idx).OutputNames)];
                  methodInputs = [methodInputs, ...
                        numel(mc.MethodList(idx).InputNames)];
               end
            end
         end
      end
      
      % Overloaded method from CustomDisplay superclass
      function s = getFooter(obj,displayType,tankName)
         %GETFOOTER  Method overload from CustomDisplay superclass
         %
         %  s = obj.getFooter();
         %  --> Returns custom footer string that links object to
         %      immediately pull up "nigelDash" GUI
         %
         %  s = obj.getFooter('simple'); 
         %  --> Returns footer string for link to "condensed" view

         if nargin < 2
            displayType = 'detailed';
            tankName = 'tankObj';
         end
         
         if nargin < 3
             tankName = 'tankObj';
         end
         
         if isempty(obj)
            s = '';
            return;
         elseif ~isvalid(obj)
            s = '';
            return;
         end
         guiLinkStr = ...
            [sprintf('\t-->\t'), ...
            '<a href="matlab: addpath(nigeLab.utils.getNigelPath()); ' ...
            'nigeLab.sounds.play(''pop'',2); '];
         promptStr = 'View in nigelDash GUI';
         dLink = [sprintf('\t-->\t'), ...
            '(<a href="matlab: nigeLab.sounds.play(''pop'',1.5); '];
         switch obj(1).Type
            case 'Block'
               if isempty(obj(1).Index)
                  pLinkStr = '';
               else
                  idx = cat(1,obj.Index);
                  idx = unique(idx(:,1));
                  if numel(idx) > 1
                     s_str = 's';
                  else
                     s_str = '';
                  end
                  pLinkStr = [sprintf(...
                     '\t-->\tView <strong>Parent</strong> '),...
                     '<a href="matlab: nigeLab.sounds.play(''pop'',1.5); '...
                     'nigeLab.nigelObj.DisplayCurrent('...
                     sprintf('%s.Children([',tankName) ...
                     sprintf('%g ',idx),']),''simple'');">', ...
                     sprintf('(Animal) %s %s',obj(1).Parent.Name, s_str) '</a>'];
               end
               switch inputname(1)
                  case {'obj',''}
                     if isempty(obj(1).Index)
                        guiLinkStr = [guiLinkStr, ...
                           sprintf('nigelDash(%s);">%s</a>',...
                              tankName,promptStr)];
                        dLink = [dLink, ...
                           sprintf(...
                           ['nigeLab.nigelObj.DisplayCurrent' ...
                           '(%s,''detailed''); ' ...
                           '">More Details</a>)'],tankName)];
                     else
                        guiLinkStr = [guiLinkStr, ...
                           sprintf('nigelDash(%s.Children(%g).Children(%g));">%s</a>',...
                              tankName,obj(1).Index(1),obj(1).Index(2),promptStr)];
                        dLink = [dLink, ...
                           sprintf(...
                           ['nigeLab.nigelObj.DisplayCurrent'...
                           '(%s.Children(%g).Children(%g),''detailed''); ' ...
                           '">More Details</a>)'],tankName,obj(1).Index(1),obj(1).Index(2))];
                     end
                  otherwise
                     guiLinkStr = [guiLinkStr, ...
                        sprintf('nigelDash(%s);">%s</a>',...
                           inputname(1),promptStr)]; 
                     dLink = [dLink, ...
                        sprintf(...
                        ['nigeLab.nigelObj.DisplayCurrent'...
                        '(%s,''detailed''); ' ...
                        '">More Details</a>)'],inputname(1))];
               end
            case 'Animal'
               if isempty(obj(1).Index)
                  pLinkStr = '';
               else
                  AllParents = [obj.Parent];
                  uParents = unique({AllParents.Name});
                  pLinkStr = [sprintf(...
                     '\t-->\tView <strong>Parent</strong> '),...
                     '<a href="matlab: nigeLab.sounds.play(''pop'',1.5); '...
                     sprintf('nigeLab.nigelObj.DisplayCurrent(%s,''simple'');">',tankName) ...
                     sprintf('(Tank) %s</a>',uParents{:})];
               end
               switch inputname(1)
                  case {'obj',''}
                     if isempty(obj(1).Index)
                        guiLinkStr = [guiLinkStr, ...
                           sprintf('nigelDash(animalObj);">%s</a>',...
                              promptStr)];
                        dLink = [dLink, ...
                           sprintf(...
                           ['nigeLab.nigelObj.DisplayCurrent'...
                           '(animalObj,''detailed''); ' ...
                           '">More Details</a>)'])];
                     else
                        guiLinkStr = [guiLinkStr, ...
                           sprintf('nigelDash(%s.Children(%g));">%s</a>',...
                              tankName,obj(1).Index,promptStr)];
                        dLink = [dLink, ...
                           sprintf(...
                           ['nigeLab.nigelObj.DisplayCurrent' ...
                           '(%s.Children(%g),''detailed''); ' ...
                           '">More Details</a>)'],tankName,obj(1).Index)];
                     end
                  otherwise
                     guiLinkStr = [guiLinkStr, ...
                        sprintf('nigelDash(%s));">%s</a>',...
                           inputname(1),promptStr)];
                     dLink = [dLink, ...
                        sprintf(...
                        ['nigeLab.nigelObj.DisplayCurrent'...
                        '(%s,''detailed''); ' ...
                        '">More Details</a>)'],inputname(1))];
               end
            case 'Tank'
               pLinkStr = '';
               switch inputname(1)
                  case {'obj',''}
                     guiLinkStr = [guiLinkStr, ...
                        sprintf('nigelDash(%s);">%s</a>',tankName,promptStr)];
                     dLink = [dLink, ...
                        'nigeLab.nigelObj.DisplayCurrent' ...
                        sprintf('%s,''detailed''); ',tankName) ...
                        '">More Details</a>)'];
                  otherwise
                     guiLinkStr = [guiLinkStr, ...
                        sprintf('nigelDash(%s);">%s</a>',...
                        inputname(1),promptStr)];
                     dLink = [dLink, ...
                        sprintf(...
                        ['nigeLab.nigelObj.DisplayCurrent'...
                        '(%s,''detailed''); ' ...
                        '">More Details</a>)'],inputname(1))];
               end
            otherwise
               error(['nigeLab:' mfilename ':BadType'],...
                     'nigelObj has bad Type (%s)',obj(1).Type);   
         end
         
         switch lower(displayType)
            case 'detailed'
               s = sprintf('%s\n%s\n%s\n',pLinkStr,getLink(obj),...
                  guiLinkStr);
            case 'simple'
               s = sprintf('%s\n%s\n%s\n%s\n',pLinkStr,getLink(obj),...
                  guiLinkStr,dLink);
         end

      end
      
      % Return full filename to parameters file
      function fname = getParsFilename(obj)
         %GETPARSFILENAME  Returns full (UNC) filename to parameters file
         %
         %  f = obj.getParsFilename(); 
         
         fname = nigeLab.utils.getUNCPath(obj.Out.Pars);
         fname = strrep(fname,'\','/');
      end
      
      % Overload for matlab.mixin.CustomDisplay.getPropertyGroups
      function groups = getPropertyGroups(obj,displayType,tankName)
         %GETPROPERTYGROUPS  Overload for returning properties to display
         %
         %  Overload of matlab.mixin.CustomDisplay.getPropertyGroups to
         %  change default output in Command Window for a scalar nigelObj
         
         if nargin < 2
            displayType = 'default';
            tankName = 'tankObj';
         end
         
          if nargin < 3
            tankName = 'tankObj';
         end
         
         switch lower(displayType)
            case {'default','nonscalar'}
               groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            case 'scalar'
               status_out = obj.getDescriptiveStatus();
               pars_out = obj.getDescriptivePars();
               switch obj.Type
                  case 'Block'                     
                     data_out = struct(...
                        'Name',obj.Name,...
                        'Duration',obj.Duration,...
                        'NumChannels',obj.NumChannels,...
                        'NumProbes',obj.NumProbes,...
                        'SampleRate',obj.SampleRate,...
                        'RecSystem',obj.RecSystem.Name,...
                        'User',obj.User);                       
                     
                     groups = [...
                        matlab.mixin.util.PropertyGroup(data_out,...
                           '<strong>Data</strong>')...
                        matlab.mixin.util.PropertyGroup(obj.Meta,...
                           '<strong>Meta</strong>')...
                        matlab.mixin.util.PropertyGroup(pars_out,...
                           '<strong>Parameters</strong>')...
                        matlab.mixin.util.PropertyGroup(status_out,...
                           '<strong>Status</strong>')...
                           ];
                  case 'Animal'               
                     data_out = struct;
                     for i = 1:numel(obj.Children)
                        % Get rid of any "weird" characters
                        name = strrep(obj.Children(i).Name,'-','_');
                        name = strrep(name,' ','_');
                        name = strrep(name,'+','_');
                        name = strrep(name,'&','_');
                        name = strrep(name,'|','_');
                        if ~regexpi(name,'[a-z]')
                           name = ['Block_' name];
                        end
                        str_view = ...
                           ['<a href="matlab: ' ...
                           'nigeLab.sounds.play(''pop'',1.5);' ...
                           'nigeLab.nigelObj.DisplayCurrent(' ...
                           tankName ...
                           sprintf(['.Children(%g).Children(%g),'...
                            '''simple'');"'], obj.Index,i) '>View</a>'];
                        
                        data_out.(name) = str_view;
                     end
                     groups = [...
                        matlab.mixin.util.PropertyGroup(data_out,...
                           '<strong>Data</strong>')...
                        matlab.mixin.util.PropertyGroup(obj.Meta,...
                           '<strong>Meta</strong>')...
                        matlab.mixin.util.PropertyGroup(pars_out,...
                           '<strong>Parameters</strong>')...
                        matlab.mixin.util.PropertyGroup(status_out,...
                           '<strong>Status</strong>')
                        ];
                  case 'Tank'
                     data_out = struct;
                     for i = 1:numel(obj.Children)
                        name = strrep(obj.Children(i).Name,'-','_');
                        name = strrep(name,' ','_');
                        name = strrep(name,'+','_');
                        name = strrep(name,'&','_');
                        name = strrep(name,'|','_');
                        if ~regexpi(name,'[a-z]')
                           name = ['Animal_' name];
                        end
                        str_view = ...
                           ['<a href="matlab: ' ...
                           'nigeLab.sounds.play(''pop'',1.5);' ...
                           'nigeLab.nigelObj.DisplayCurrent(' ...
                           tankName ...
                           sprintf('.Children(%g),''simple'');"',i) ...
                           '>View</a>'];
                        data_out.(name) = str_view;
                     end
                     groups = [...
                        matlab.mixin.util.PropertyGroup(data_out,...
                           '<strong>Data</strong>')...
                        matlab.mixin.util.PropertyGroup(obj.Meta,...
                           '<strong>Meta</strong>')...
                        matlab.mixin.util.PropertyGroup(pars_out,...
                           '<strong>Parameters</strong>')...
                        matlab.mixin.util.PropertyGroup(status_out,...
                           '<strong>Status</strong>')
                        ];
                  otherwise
                     groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
               end
               
            otherwise
               error(['nigeLab:' mfilename ':BadType'],...
                  'Unexpected case: %s',displayType);
         end
      end
      
      % Return list of initialized parameters
      function [s_init,s_miss,s_all] = listInitializedParams(obj)
         %LISTINITIALIZEDPARAMS  Return list of initialized parameters
         %
         %  s = obj.listInitializedParams();
         
         curPars = fieldnames(obj.HasParsInit);
         s_init = {};
         for i = 1:numel(curPars)
            if obj.HasParsInit.(curPars{i})
               s_init = [s_init, curPars{i}];
            end
         end
         
         % Get a list of all properties
         PropsToSkip ={'nigelColors','Tempdir','Contents'};
         tmp = dir(fullfile(nigeLab.utils.getNigelPath('UNC'),...
            '+nigeLab','+defaults','*.m'));
         s_all = cellfun(@(x)x(1:(end-2)),{tmp.name},...
            'UniformOutput',false);
         s_all = setdiff(s_all,PropsToSkip);
         
         
         s_miss = setdiff(s_all,s_init);
      end
      
      % Load/parse ID file and associated parameters
      function loadIDFile(obj,recursionFlag)
         %LOADIDFILE  Load and parse .nigelBlock file into .IDInfo property
         %
         %  obj.loadIDFile();
         %  --> update obj.IDInfo
         %
         %  obj.loadIDFile(false);  Disable recursive calls from method
         
         if isempty(obj)
            return;
         end
         
         if nargin < 2
            recursionFlag = true;
         end
         
         fid = fopen(obj.Out.NigelFile,'r+');
         if (fid < 0)
            if ~isempty(obj.Name)
               % "ID" file doesn't exist; make it using current properties
               flag = obj.saveIDFile();
               return;
            else
               return;
            end
         end
         C = textscan(fid,'%q %q','Delimiter','|');
         fclose(fid);
         propName = C{1};
         propVal = C{2};
         if ~strcmpi(propName{1},obj.Type)
            error(['nigeLab:' mfilename ':BadFolderHierarchy'],...
               '[%s/LOADIDFILE]: Attempt to load non-%s from %s folder.',...
               upper(obj.Type),obj.Type,obj.Type);
         end

         obj.IDInfo = struct;
         obj.IDInfo.(upper(propName{1})) = propVal{1};
         for i = 2:numel(propName)
            if ~contains(propName{i},'.')
               obj.IDInfo.(propName{i}) = propVal{i};
            end
            if isempty(propVal{i})
               switch propVal{i}
                  case 'User' % Special case
                     if recursionFlag
                        warning(['nigeLab:' mfilename ':LOADIDFILE'],...
                           'Bad %s file. Retry load once.\n',...
                            obj.FolderIdentifier);
                        saveIDFile(obj);
                        loadIDFile(obj,false);
                     end
                     return;                     
                  otherwise
                     warning(['nigeLab:' mfilename ':LOADIDFILE'],...
                        '%s %s value missing.\n',propName{i},...
                        obj.FolderIdentifier);
                     continue;
               end
            end
            setProp(obj,propName{i},propVal{i});
         end         
      end
      
      % Parse input path (constructor probably always)
      function flag = parseInputPath(obj,inPath)
         %PARSEINPUTPATH  Parses an input path `inPath`
         %
         %  flag = obj.parseInputPath(inPath);
         %  --> Returns true if parsing was completed without cancellation
         
         flag = false;
         if isempty(inPath)
            if isempty(obj.Input)
               switch obj.Type
                  case 'Block'
                     [p,f] = obj.getRecLocation('File');
                     if isempty(f)
                        nigeLab.utils.cprintf('Errors*','No selection\n');
                        return;
                     else
                        obj.Input = fullfile(p,f);
                     end
                  case {'Animal','Tank'}
                     p = obj.getRecLocation('Folder');
                     if isempty(p)
                        nigeLab.utils.cprintf('Errors*','No selection\n');
                        return;
                     else
                        obj.Input = p;
                     end %if isempty p
               end % switch
            end %fi isempty(obj.Input)
         else% fi isempty(inPath)
            obj.Input  = inPath;                 
         end
         flag = true;
      end
      
      % Parse metadata from file or folder name of INPUT
      function [meta] = parseNamingMetadata(obj,fName,pars)
         %PARSENAMINGMETADATA  Parse metadata from file or folder name
         %
         %  name = PARSENAMINGMETADATA(obj);
         %
         %  --------
         %   INPUTS
         %  --------
         %     obj      :     nigeLab.Block, Animal, or Tank class object
         %
         %   fName      :     (char array) Full filename of Input
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
         %                    --> 'DiscardChar' (char indicating to discard
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
         
         if isempty(obj)
            name = '';
            meta = struct;
            return;
         end
         
         reqPars = struct(...
            'Delimiter','',...
            'DynamicVarExp','',...
            'IncludeChar','',...
            'DiscardChar','',...
            'SpecialMeta','',...
            'NamingConvention','',...
            'Concatenater','');
         
         if nargin < 3
            if isfield(obj.Pars,obj.Type)
               if isfield(obj.Pars.(obj.Type),'Parsing')
                  pars = obj.Pars.Parsing.(obj.Type);
               else
                  pars = obj.Pars.(obj.Type);
               end
            else
               pars = struct;
               nigeLab.utils.cprintf('Comments',obj.Verbose,...
                  ['\nNo parsing parameters detected.\n' ...
                   '-->\tUsing values in ~/+nigeLab/+defaults/%s.m'],...
                   obj.Type);
            end
         end
         
         % Load any missing parameters
         if isempty(pars)
            missingReqs = reqPars;
         else
            missingReqs = setdiff(fieldnames(reqPars),fieldnames(pars));
         end
         if ~isempty(missingReqs)
            for i = 1:numel(missingReqs)
               f_miss = missingReqs{i};
               pars.(f_miss) = getParams(obj,obj.Type,f_miss);
               % Validate properties
               switch f_miss
                  case 'Concatenater'
                     isInvalid = ~ischar(pars.(f_miss));
                  case 'Delimiter'
                     isInvalid = ~iscell(pars.(f_miss));
                  case 'DynamicVarExp'
                     isInvalid = ~iscell(pars.(f_miss));
                  case 'NamingConvention'
                     isInvalid = ~iscell(pars.(f_miss));
                  case 'SpecialMeta'
                     isInvalid = ~isstruct(pars.(f_miss));
                  case 'DiscardChar'
                     isInvalid = ~ischar(pars.(f_miss));
                  case 'IncludeChar'
                     isInvalid = ~ischar(pars.(f_miss));
               end
               if isInvalid
                  pars.(f_miss) = nigeLab.defaults.(obj.Type)(f_miss);
               end
            end
         end
         
         meta = struct;
         if nargin < 2
            [p,fName,meta.FileExt] = fileparts(obj.Input);
         else
            [p,fName,meta.FileExt] = fileparts(fName);           
         end
         
         meta.OrigName = fName;
         meta.OrigPath = strrep(p,'\','/');
            
         [~,meta.ParentID,~] = fileparts(p);
         
         % Parse name and extension. "nameParts" contains parsed variable
         % strings:      
         if ~iscell(pars.Delimiter)
             pars.Delimiter = {pars.Delimiter};
         end
         nameParts=strsplit(fName,[pars.Delimiter(:); {'.'}]);
         
         % Parse variables from defaults.Block "template," which match
         % delimited elements of block recording name:
%          regExpStr = sprintf('\\%c\\w*|\\%c\\w*',...
%             pars.IncludeChar,pars.DiscardChar);

         regExpStr = sprintf('\\%c\\w*',...
            pars.IncludeChar);
         splitStr = regexp(pars.NamingConvention,regExpStr,'match');
         
         
         % Find which delimited elements correspond to variables that
         % should be included by looking at the leading character from the
         % defaults.Block template string:
         incVarIdx = find(~cellfun(@isempty,splitStr));
         exclVarIdx = find(cellfun(@isempty,splitStr));
         splitStr = [splitStr{:}];
         
         if (numel(incVarIdx) + numel(exclVarIdx)) ~= numel(nameParts)
                namingInterface = nigeLab.libs.namingConfigurator(obj,meta.OrigName);
                waitfor(namingInterface);
                meta = parseNamingMetadata(obj,fName);
                return
         end
         
         
         % Find which set of variables (the total number available from the
         % name, or the number set to be read dynamically from the naming
         % convention) has fewer elements, and use that to determine how
         % many loop iterations there are:
         nMin = min(numel(incVarIdx),numel(nameParts));
         
         % Create a struct to allow creation of dynamic variable name
         % dictionary. Make sure to iterate on 'splitStr', and not
         % 'nameParts,' because variable assignment should be decided by
         % the string in namingConvention property.
         for ii=1:nMin
            varName = deblank( splitStr{ii}(2:end));
            meta.(varName) = nameParts{incVarIdx(ii)};
         end
         f = fieldnames(meta);
         
         % For each "special" field, use combinations of variables to
         % produce other metadata tags. See '~/+nigeLab/+defaults/Block.m`
         % for more details
         for ii = 1:numel(pars.SpecialMeta.SpecialVars)
            f = pars.SpecialMeta.SpecialVars{ii};
            if ~isfield(meta,f)
               if ~isfield(pars.SpecialMeta,f)
                  link_str = sprintf('nigeLab.defaults.%s',obj.Type);
                  error(['nigeLab:' mfilename ':BadConfig'],...
                     ['%s is configured to use %s as a "special field,"\n' ...
                     'but it is not configured in %s.'],...
                     nigeLab.utils.getNigeLink(...
                     'nigeLab.nigelObj','parseNamingMetadata'),...
                     f,nigeLab.utils.getNigeLink(link_str));
               end
               if isempty(pars.SpecialMeta.(f).vars)
                  warning(['nigeLab:' mfilename ':PARSE'],...
                     ['No <strong>%s</strong> "SpecialMeta" configured\n' ...
                           '-->\t Making random "%s"'],f,f);
                  meta.(f) = nigeLab.utils.makeHash();
                  meta.(f) = meta.(f){:};
               else
                  tmp = cell(size(pars.SpecialMeta.(f).vars));
                  for i = 1:numel(pars.SpecialMeta.(f).vars)
                     tmp{i} = meta.(pars.SpecialMeta.(f).vars{i});
                  end
                  meta.(f) = strjoin(tmp,pars.SpecialMeta.(f).cat);
               end
            end
         end         
         
         if isempty(obj.Meta)
            obj.Meta = struct;
         end
         obj.Meta = nigeLab.utils.add2struct(obj.Meta,meta); 
         obj.Pars.(obj.Type).Parsing = pars;
       end
      
      function name = genName(obj)
          if ~isfield( obj.Pars.(obj.Type),'Parsing')
                    obj.Meta = obj.parseNamingMetadata;
          end
        name = obj.Meta.(sprintf('%sID',obj.Type));
      end
      
      % Parse output path (constructor probably always)
      function flag = parseSavePath(obj,savePath)
         %PARSESAVEPATH  Parses an output path `savePath`
         %
         %  flag = obj.parseSavePath(savePath);
         %  --> Returns true if parsing was completed without cancellation
         
         flag = false;
         if isempty(savePath)
            if isempty(obj.Output)
               if ~obj.getSaveLocation()
                  nigeLab.utils.cprintf('Errors*','No selection\n');
                  return;
               end
            end
         else
            obj.Output = savePath;
         end
         flag = true;
      end
      
      % Parse recording type based on file extension
      function recType = parseRecType(obj)
         %PARSERECTYPE   Figure out what kind of recording this is
         %
         %  recType = nigelObj.parseRecType();
         %
         %  Sets the 'RecType' property of nigelObj

         switch obj.FileExt
            case '.rhd'
               recType = 'Intan';
               obj.RecType=recType;
               obj.RecSystem = nigeLab.utils.AcqSystem('RHD');
               return;
               
            case '.rhs'
               recType = 'Intan';
               obj.RecType=recType;
               obj.RecSystem = nigeLab.utils.AcqSystem('RHS');
               return;
               
            case {'.Tbk', '.Tdx', '.tev', '.tnt', '.tsq','.tdt'}
               recType = 'TDT';
               obj.RecType=recType;
               obj.RecSystem = nigeLab.utils.AcqSystem('TDT');
               return;
               
            case '.mat'
               recType = 'Matfile';
               obj.RecType=recType;
               return;
               
            case '.nigelBlock'
               recType = 'nigelBlock';
               obj.RecType=recType;
               return;
               
            case {'','Unknown'}
               files = dir(nigeLab.utils.getUNCPath(obj.Paths.RecFile));
               files = files(~[files.isdir]);
               if isempty(files)
                  recType = 'nigelBlock';
                  obj.RecType = recType;
                  return;
               end
               [~,~,ext] = fileparts(files(1).name);
               switch ext
                  case {'.Tbk', '.Tdx', '.tev', '.tnt', '.tsq','.tdt'}
                      recType = 'TDT';
                      obj.RecType=recType;
                      obj.RecSystem = nigeLab.utils.AcqSystem('TDT');
                      obj.FileExt = ext;
                      
                  case '.nigelBlock'
                     recType = 'nigelBlock';
                     obj.RecType=recType;
                     obj.FileExt = ext;
                     
                  case '.mat'
                     recType = 'Matfile';
                     obj.RecType=recType;
                     obj.FileExt = ext;
                     
                   case '.rhd'
                       recType = 'Intan';
                       obj.RecType=recType;
                       obj.RecSystem = nigeLab.utils.AcqSystem('RHD');
                       obj.FileExt = ext;

                   case '.rhs'
                       recType = 'Intan';
                       obj.RecType=recType;
                       obj.RecSystem = nigeLab.utils.AcqSystem('RHS');
                       obj.FileExt = ext;

                  otherwise
                     recType = 'other';
                     obj.RecType=recType;
                     obj.FileExt = ext;
                     nigeLab.utils.cprintf('Errors*',...
                        'Not a recognized file extension: %s\n',ext);
                     
               end
               % Ensure that RecFile is a file, not a folder
%                obj.RecFile = fullfile(files(1).folder,files(1).name);
               return;
               
            otherwise
               recType = 'other';
               obj.RecType=recType;
               nigeLab.utils.cprintf('Errors*',...
                        'Not a recognized file extension: %s\n',...
                        obj.FileExt);
               return;
         end
         
      end
      
      % Save small folder identifier file
      function flag = saveIDFile(obj,propList)
         %SAVEIDFILE  Save small folder identifier file
         %
         %  flag = obj.saveIDFile();
         %  --> Returns true if save was successful
         %  * Default "propList" depends on .Type
         %
         %  flag = obj.saveIDFile(propList);
         %  --> Adds properties in `propList` to the defaults saved:
         %     * 'Key.Public'
         %     * All fields of 'Out'
         %     * 'RecDir'
         %     * 'User'
         %
         %  propList : Cell array of char vectors that are names of
         %             properties of nigelObj to save in .nigelFile
         
         
         %%%%%To be removed, just for debug!!!!
%          flag = true;
%          return
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
         
         
         
         
         
         
         flag = false;
         if nargin < 2
            propList = {};
         end
         
         if strcmp(obj.Type,'Block')
            if isempty(obj.Input)
               return;
            end
         end
         
         % Save .nigel___ file to identify this "Type" of folder
         if isempty(obj.Out.NigelFile)
            if obj.Verbose
               [fmt,idt,type] = obj.getDescriptiveFormatting();
               dbstack;
               if isempty(obj.Name)
                  nigeLab.utils.cprintf(fmt,...
                     '%s[SAVEIDFILE]: %s cannot save .nigelFile\n',...
                     idt,type);
                  nigeLab.utils.cprintf(fmt(1:(end-1)),...
                     '\t%s(Missing parsed .Name of %s)\n',idt,type);
               else
                  nigeLab.utils.cprintf(fmt,...
                     '%s[SAVEIDFILE]: %s (%s) cannot save .nigelFile\n',...
                     idt,obj.Name,type);
                  nigeLab.utils.cprintf(fmt(1:(end-1)),...
                     '\t%s(Output path location data is missing.)\n',idt);
               end
            end
            return;
         else
            [outPath,~,~] = fileparts(obj.Out.NigelFile);
         end
         if exist(outPath,'dir')==0
            [SUCCESS,MESSAGE,MESSAGEID] = mkdir(outPath); % Make sure the output folder exists
            if ~SUCCESS
                return;
            end
         end
         fid = fopen(obj.Out.NigelFile,'w');
         if fid > 0
            fprintf(fid,'%s|%s\n',upper(obj.Type),obj.Name);
            fprintf(fid,'Key.Public|%s\n',obj.Key.Public);
            if ~isempty(obj.Out)
               f = fieldnames(obj.Out);
               for iF = 1:numel(f)
                  fprintf(fid,'Out.%s|%s\n',f{iF},...
                     strrep(obj.Out.(f{iF}),'\','/'));
               end               
            end
            fprintf(fid,'RecDir|%s\n',obj.Input);
            fprintf(fid,'User|%s\n', obj.User);
            for i = 1:numel(propList)
               fprintf(fid,'%s|%s\n',...
                  propList{i},num2str(obj.(propList{i})));
            end
            fclose(fid);
            flag = true;
         else
            warning(['nigeLab:' mfilename ':SAVEIDFILE'],...
               'Could not write FolderIdentifier (%s)',obj.Out.NigelFile);
            flag = false;
         end         
      end
      
      % Search for Children "_Obj.mat" files in SaveLoc path
      function [C,varName] = searchForChildren(obj)
         %SEARCHFORCHILDREN  Returns `dir` file struct for potential
         %                    .Children array members
         %
         %  C = obj.searchForChildren();
         
         switch obj.Type
            case 'Animal'
                varName = 'blockObj';
               C = dir(nigeLab.utils.getUNCPath(...
                        obj.Out.Folder,'*_Block.mat'));
               if isempty(C)
                  return;
               end
               
            case 'Tank'
                varName = 'animalObj';
               C = dir(nigeLab.utils.getUNCPath(...
                        obj.Out.Folder,'*_Animal.mat'));
               if isempty(C)
                  return;
               end
               
            otherwise % i.e. 'Block'
               C = [];
               varName = '';
               return;
         end
      end
      
      % Set property for all Child objects
      function setChildProp(obj,propName,value)
         %SETCHILDPROP  Set property for all Child objects
         %
         %  obj.setChildProp('propName',value);
         %  --> Useful for updating all child objects to take the Parent
         %      state for a Dependent property on the "set.property" method
         
         if ~all(isempty(obj.Children))
            for i = 1:numel(obj.Children)
               if isvalid(obj.Children(i))
                  set(obj.Children(i),propName,value);
               end
            end
         end
      end
      
      % Set index of all child objects
      function setChildIndex(obj,childObjArray)
         %SETCHILDINDEX  Sets .Index property of all Child objects
         %
         %  obj.setChildIndex();
         %  --> Sets for all
         %  obj.setChildIndex(childObjArray);
         %  --> Sets for elements of childObjArray
         
         if nargin < 2
            childObjArray = obj.Children;
         end
         if isempty(childObjArray)
            return;
         end
         for i = 1:numel(childObjArray)
            if isvalid(childObjArray(i))
               childObjArray(i).Index = [obj.Index i];
            end
         end
      end
      
      % Sets .Output path
      function setOutputPath(obj,outPath,forceSet)
         %SETOUTPUTPATH  Sets .Output path
         %
         %  obj.setOutputPath(outPath);
         %  --> Will not set if .nigelFile is not present
         %
         %  obj.setOutputPath(outPath,true);
         %  --> Forces Output location regardless of .nigelFile presence
         %
         %  outPath : The output location that conatins the
         %              obj.FolderIdentifier for this nigelObj
         
         if nargin < 3
            forceSet = false;
         end
         
         f = obj.FolderIdentifier;
         if (exist(fullfile(outPath,f),'file')~=0) || forceSet
            obj.Output = outPath;
            return;
         end
         if obj.Verbose
            [fmt,idt,type] = obj.getDescriptiveFormatting();
            dbstack;
            nigeLab.utils.cprintf('Errors*','%s[INVALID]: ',idt);
            nigeLab.utils.cprintf(fmt,...
               'Tried to set unknown [%s] .Output path\n',type)
            nigeLab.utils.cprintf(fmt,...
               '\t%sAssigned ''%s'' (but %s was missing)\n',...
               idt,nigeLab.utils.shortenedPath(outPath),f);
         end
      end
      
      % Toggle .IsDashOpen of all Children
      function toggleChildDashStatus(obj,value)
         %TOGGLECHILDDASHSTATUS  Toggles all Child object dash status
         %
         %  obj.toggleChildDashStatus(); --> Uses obj.IsDashOpen
         %  obj.toggleChildDashStatus(value);
         
         if nargin < 2
            value = obj.IsDashOpen;
         end
         for i = 1:numel(obj.Children)
            if ~isempty(obj.Children(i))
               c = obj.Children(i);
               if isvalid(c)
                  c.IsDashOpen = value;
               end
            end
         end
      end
      
      % Update Paths
      function flag = updatePaths(obj,saveLoc,removeOld)
         %UPDATEPATHS  Update the path tree of the Block object
         %
         %  flag = obj.updatePaths();
         %  flag = obj.updatePaths(SaveLoc);
         %
         % Generates a new path tree starting from the SaveLoc input and
         %  moves any files found in the old path to the new one.
         %
         % In order to match the old path with the new one the Paths struct
         %  in object is used.
         %
         % The script detects <strong> any variable part </strong> of the
         %  name (eg %s) and replicates it in the new file.
         %
         % This means that if the old file had two variable parts,
         %  typically probe and channels, the new one must have two varible
         %  parts as well.
         %
         % This is a problem only when changing the naming in the
         %  defaults params.
         % TODO move to block
         flag = false;
         if nargin < 2
            saveLoc = obj.Out.SaveLoc;
            removeOld = false;
         elseif nargin < 3
             removeOld = false;
         end
         
         if isempty(saveLoc)
            if obj.Verbose
               [fmt,idt,type] = obj.getDescriptiveFormatting();
               dbstack;
               nigeLab.utils.cprintf('Errors*','%s[UPDATEPATHS]: ',idt);
               nigeLab.utils.cprintf(fmt,...
                  'Tried to update [%s].Paths using empty base\n',type);
            end
            return;
         end
         
         % Assign .Paths save location (container of object folder tree)
         OldOut = obj.Out;
         obj.Output = saveLoc;
         % Update all files for Animal, Tank
         if ismember(obj.Type,{'Animal','Tank'})
            p = obj.Out.Folder;
            flag = true;
            for i = 1:numel(obj.Children)
               if ~isempty(obj.Children(i))
                  c = obj.Children(i);
                  if isvalid(c)
                     flag = flag && c.updatePaths(p,removeOld);
                  end
               end
            end
            flag = flag && obj.save;
            flag = flag && obj.saveParams;
            return;
         end
         
         % remove old block matfile
         objFile = obj.Out.File;
         parsFile =  obj.getParsFilename();
         IDfile = obj.Out.NigelFile;
         if removeOld
             mode = 'mv';
             
         else
             mode = 'cp';
         end
         % Get old paths, removing 'SaveLoc' from the list of Fields
         %  that need Paths found for them.
         OldP = obj.Paths;
         OldP.Folder = OldOut.Folder;
         OldFN_ = fieldnames(OldP);
         OldFN_(strcmp(OldFN_,'SaveLoc'))=[];
         OldFN = [];
         
         % generate new obj.Paths
         obj.genPaths;
         P = obj.Paths;
         
         uniqueTypes = unique(obj.FieldType);
         
         % look for old data to move
         filePaths = cell(1);
         for jj=1:numel(uniqueTypes)
            if ~isempty(obj.(uniqueTypes{jj}))
               
               fieldsToMove{jj} = findDiskData(obj.(uniqueTypes{jj}));
               fieldsToMoveShort{jj} = regexprep(fieldsToMove{jj},'[.]\w+','');
               OldFN = [OldFN;OldFN_(ismember(OldFN_,fieldsToMoveShort{jj}))]; %#ok<*AGROW>
               for hh=1:numel(fieldsToMove{jj})
                  if ~isempty(fieldsToMoveShort{jj}{hh})
                     filePaths{jj}{hh} = cellfun(@(x)x.getPath,...
                        eval(sprintf('{obj.%s.%s}',uniqueTypes{jj},fieldsToMove{jj}{hh})),...
                        'UniformOutput',false)';
                  end %fi
               end %hh
            end %fi
         end %jj
         
         % moves all the files from folder to folder
         for jj=1:numel(filePaths)
             for hh=1:numel(filePaths{jj})
                 for ii =1:numel(filePaths{jj}{hh})
                     source = fullfile(filePaths{jj}{hh}{ii});
                     [~,target] = strsplit(source,'[^\\]*\\[^\\]*.mat',...
                         'DelimiterType', 'RegularExpression');
                     target = fullfile(obj.Out.Folder,target{1});
                     pct = ii/numel(filePaths{jj}{hh})*100;
                     switch mode
                         case 'mv'
                             target = nigeLab.utils.getUNCPath(target);
                             source = nigeLab.utils.getUNCPath(source);
                             [~,~] = nigeLab.utils.FileRename.FileRename(source,target);
                             str = strrep(nigeLab.utils.printLinkFieldString(uniqueTypes{jj},fieldsToMove{jj}{hh},false),'Linking','Moving');
                             reportProgress(obj,str,pct,'toWindow','Moving-Channels');
                         case 'cp'
                             [~,~] = copyfile(source,target);
                             str = strrep(nigeLab.utils.printLinkFieldString(uniqueTypes{jj},fieldsToMove{jj}{hh},false),'Linking','Copying');
                             reportProgress(obj,str,pct,'toWindow','Copying-Channels');
                     end
                 end
             end
         end
         
         % copy all the info files from one folder to the new one
         for jj = 1:numel(OldFN)
            %     moveFiles(OldP.(OldFN{jj}).file, P.(OldFN{jj}).file);
            moveFilesAround(OldP.(OldFN{jj}).info,P.(OldFN{jj}).info,mode);
            d = dir(OldP.(OldFN{jj}).dir);
            d = d(~ismember({d.name},{'.','..'}));
            if isempty(d) && exist(OldP.(OldFN{jj}).dir,'dir')
               rmdir(OldP.(OldFN{jj}).dir);
            end
         end
         
         if removeOld
             if exist(objFile,'file')
                 delete(objFile);
             end
             if exist(parsFile,'file')
                 delete(parsFile);
             end
             if exist(IDfile,'file')
                 delete(IDfile);
             end
             DD = dir(fullfile(OldP.Folder,'**'));
             DD = DD(~arrayfun(@(x) x.name(1)=='.',DD));
             if  exist(OldP.Folder,'dir') && isempty(DD)
                 rmdir(OldP.Folder);
             end
         end
         flag = true;
         for jj = 1:numel(OldFN)
             obj.linkField(OldFN{jj});
         end
%          flag = flag && obj.linkToData;
         flag = flag && obj.save;
         flag = flag && obj.saveParams;
         
         
          function name = findDiskData(p,prefix)
              if nargin == 1
                  prefix = '';
              else
                  prefix = [prefix '.'];
              end
              p = p(1);
              ff = cellfun(@(f) [prefix f],fieldnames(p),'UniformOutput',false);
              pcell = struct2cell(p);
              clss = cellfun(@class,pcell,'UniformOutput',false);
              name = [ff(cellfun(@(x) ~isempty(regexp(x,...
                  'DiskData.\w', 'once')),...
                  clss))];
              strIdx = strcmp(clss,'struct') & ~structfun(@isempty,p);
              name = [name; arrayfun(@(idx)findDiskData(pcell{idx},ff{idx}),find(strIdx),'UniformOutput',true)];
              if isempty(name)
                  name = {''};
              end
          end
         
         function moveFilesAround(oldPath,NewPath,str)
            %MOVEFILESAROUND  Actually moves the files after they are split
            %
            %  moveFilesAround(oldPath,NewPath,str);
            %  --> For example, after splitting MultiAnimalsLinkedBlocks,
            %      you need to also move the diskfile locations to reflect
            %      the splitting.
            
            oldPathSplit = regexpi(oldPath,'%[\w\W]*?[diuoxfegcs]','split');
            newPathSplit = regexpi(NewPath,'%[\w\W]*?[diuoxfegcs]','split');
            source_ = dir([oldPathSplit{1} '*']);
            numVarParts = numel(strfind(oldPath,'%'));
            for kk = 1:numel(source_)
               src = fullfile(source_(kk).folder,source_(kk).name);
               offs=1;
               ind=[];VarParts={};
               for iV=1:numVarParts
                  tmp = strfind(src(offs:end),oldPathSplit{iV}) + ...
                     length(oldPathSplit{iV});
                  ind(1,iV) = offs -1 + tmp(1);
                  offs = ind(1,iV);
                  tmp = strfind(src(offs:end),oldPathSplit{iV+1})-1;
                  if isempty(tmp),tmp=length(src(offs:end));end
                  ind(2,iV) = offs -1 + tmp(1);
                  offs = ind(2,iV);
                  VarParts{iV} = src(ind(1,iV):ind(2,iV));
               end % iV
               tgt = fullfile( sprintf(strrep(strjoin(newPathSplit, ...
                  '%s'),'\','/'),  VarParts{:}));
               
               switch str
                  case 'mv'
                     [~,~] = nigeLab.utils.FileRename.FileRename(src,tgt);
                  case 'cp'
                     [~,~] = copyfile(src,tgt);
               end %str
            end %kk
         end
      end
      
      % Prompt the user with a dialog to look for the data
      function flag = lookForData(obj)
          %LOOKFORDATA  Prompt user with a dialog to look for missing data
          %
          % flag = lookForData(obj);
          % --> Called if an identifier file is not present in the expected location.
          
          quest = sprintf('Looks like Nigel cannot find some data.\nDid you move your stuff recently?');
          btn1 = sprintf('Yes! Let me show you where it is.');
          btn2 = sprintf('No. Leave me alone I know what I''m doing.');
          dlgtitle = 'I''m confused';
          answer = questdlg(quest,dlgtitle,btn1,btn2,btn1);
          
          switch answer
              case btn1
                  path = uigetdir(obj.Out.SaveLoc);
                  dd = dir(fullfile(fileparts(path),'**','*_Tank.mat'));
                  path = dd.folder;
                  obj.Output = path;
%                   obj.updatePaths(path);
                  flag = true;
              case btn2
                  flag = false;
              otherwise
                  flag = false;
          end
      end
   end
   
   % STATIC,PUBLIC
   methods (Static,Access=public)
      % Overloaded method for loading objects (for "multi-blocks" case)
      function b = loadobj(a)
         % LOADOBJ  Overloaded method called when loading BLOCK.
         %
         %  Has to be called when there MultiAnimals is true because the
         %  BLOCKS are removed from parent objects in that case during
         %  saving.
         %
         %  obj = loadobj(obj);
         
         % Check if it is empty first
          if isempty(a)
            b = a;
            return;
         end
         
         % If changes to Class cause incompatibilities with an "old" saved
         % Block, and it is loaded, this makes sure it handles the
         % differences (otherwise it is just a struct obj at this point):
         if isstruct(a)
            type = nigeLab.nigelObj.ParseType(a);
            if isfield(a,'Children')
               a = rmfield(a,'Children');
            end
            if isfield(a,'ChildContainer')
               a = rmfield(a,'ChildContainer');
            end
            switch type
               case {'Block','nigelBlock'}
                  b = nigeLab.Block(a);
               case {'Animal','nigelAnimal'}
                  b = nigeLab.Animal(a);
               case {'Tank','nigelTank'}
                  b = nigeLab.Tank(a);
               otherwise
                  nigeLab.utils.cprintf('Errors*',...
                     ['[LOADOBJ]: Could not load object due ' ...
                     'to unknown Type (''%s'')'],type);
                  b = nigeLab.nigelObj.Empty();
                  return;
            end
         else
            b = a;
         end
         
         b.addPropListeners();
         b.loadIDFile();
         b.checkParsInit();
         
         % global variable to inform children if they need to refresh their
         % paths
         global DataMoved;
                  
         switch b.Type
            case 'Block'
%                % Be sure to re-assign transient .Block property to Videos
               if ~isempty(b.Cameras)
                    [b.Cameras.Parent] = deal(b);
%                     arrayfun(@addVideos,b.Cameras);
               end
               
               if DataMoved
                   % This means the load process deteermined the data was
                   % moved from the saved path. Needs to update path using
                   % Parent directory. If DataMoved is true, the loadfunc
                   % was called during the loading process of animal.
                   animalObj = evalin('caller','b'); % evaluates the variable b in the caller workspace
                   path = animalObj.Out.Folder;
                   b.Output = path;
                   b.genPaths;
               end

             case {'Animal'}
                 b.PropListener(1).Enabled = false;
                 % Adds Children if it finds them
                 [C,varName] = b.searchForChildren();
                 if isempty(C)
                     st = dbstack;
                     % here we use dbstack to determine if the fucntion was called by the top
                     % workspace or by the tankObj loading function. In the forst case we prompt
                     % the user to select the correct path, otherwise we use the tankObj path
                     if length(st) == 2
                         tankObj = evalin('caller','b');
                         path = tankObj.Out.Folder;
                         b.Output = path;
                         flag = true;
                     else
                         flag = b.lookForData;
                     end
                     if flag
                         [C,varName] = b.searchForChildren();
                         DataMoved = true;
                     end
                 end
                 for ii=1:numel(C)
                     in = load(fullfile(C(ii).folder,C(ii).name),varName);
                     b.addChild(in.(varName));
                 end
                 b.PropListener(1).Enabled = true;
                 
             case{'Tank'}
                 b.PropListener(1).Enabled = false;
                 % Adds Children if it finds them
                 [C,varName] = b.searchForChildren();
                 DataMoved = false;
               if isempty(C)                                      
                   flag = b.lookForData;
                   if flag
                       [C,varName] = b.searchForChildren();                       
                       DataMoved = true;
                   end                       
               end
               for ii=1:numel(C)
                  in = load(fullfile(C(ii).folder,C(ii).name),varName);
                  b.addChild(in.(varName));
               end
               b.PropListener(1).Enabled = true;
         end
         if DataMoved
             b.loadIDFile();
         end
         [fmt,idt,type] = b.getDescriptiveFormatting();
         nigeLab.utils.cprintf(fmt,b.Verbose,...
            '%s\b\b\b[LOAD]: %s (%s) loaded successfully!\n',...
            idt,b.Name,type);
      end
           
      % Print detailed description to Command Window
      function DisplayCurrent(obj,displayStyle)
         %DISPLAYCURRENT  Print detailed description to Command Window
         %
         %  nigeLab.nigelObj.DisplayCurrent(tankObj);
         %
         %  nigeLab.nigelObj.DisplayCurrent(tankObj,'detailed'); 
         %  --> Forces "detailed" display instead of "simple"
         
         if nargin < 2
            displayStyle = 'simple';
         else
            displayStyle = lower(displayStyle);
            if ~ismember(displayStyle,{'simple','detailed'})
               displayStyle = 'simple';
            end
         end
         
         if isscalar(obj) && isvalid(obj)
            obj.displayScalarObject(displayStyle);
         else
            disp(obj);
         end
      end
      
      % Method to iterate "operation" on obj array and children
      function flag = doMethod(obj,fcn_handle,varargin)
         %DOMETHOD  Iterates fcn_handle on obj and obj children
         %
         %  flag = nigeLab.nigelObj.doMethod(obj,fcn_handle);
         %
         %  flag = nigeLab.nigelObj.doMethod(__,arg1,arg2,...);
         %
         %  e.g. 
         %  flag = nigeLab.nigelObj.doMethod(obj,@doRawExtraction);
         %
         %  --> feval must return a scalar logical "flag"
         %
         %  Note that this is only valid for Tank and Animal objects
         
         flag = true;
         if numel(obj) > 1
            for i = 1:numel(obj)
               flag = flag && feval(fcn_handle,obj(i),varargin{:});
            end
            return;
         end
         
         if isempty(obj)
            return;
         end
         
         if ~isvalid(obj)
            return;
         end
         
         if ~ismember(obj.Type,{'Tank','Animal'})
            error(['nigeLab:' mfilename ':BadClass'],...
               'nigelObj.%s should only iterate on Tank and Animal\n',...
               char(fcn_handle));
         end
         
         if numel(obj.Children) > 0
            c = obj.Children;
            mask = find([c.IsMasked]);
            if isempty(mask)
               flag = true;
            else
               flag = flag && feval(fcn_handle,c(mask),varargin{:});
            end
         else
            flag = true;
         end
      end
      
      % Method to create Empty scalar NIGELOBJ object or NIGELOBJ array
      function obj = Empty(n)
         % EMPTY  Creates "empty" block or block array
         %
         %  obj = nigeLab.nigelObj.Empty();  
         %  --> Make a scalar nigelObj object
         %
         %  obj = nigeLab.nigelObj.Empty(n);
         %  --> Make n-element empty nigelObj array
         
         if nargin < 1
            n = [0, 0];
         else
            n = nanmax(n,0);
            if isscalar(n)
               n = [0, n];
            end
         end
         
         obj = nigeLab.nigelObj(n);
      end
      
      % Returns valid/non-empty object from array
      function thisObj = getValidObj(objArray,n)
         %GETVALIDOBJ  Returns valid/non-empty object(s) from array
         %
         %  thisObj = nigeLab.nigelObj.getValidObj(objArray);
         %  --> Returns first non-empty & valid object
         %     --> Will return an empty double if no such object exists
         %
         %  thisObj = nigeLab.nigelObj.getValidObj(objArray,n);
         %  --> Returns first n valid elements from array
         %     --> Will return an empty double if no such object exists
         
         if nargin < 2
            n = 1;
         else 
            n = min(n,numel(objArray));
         end
         
         thisObj = [];
         i = 0;
         while (i < numel(objArray)) && (numel(thisObj) < n)
            i = i + 1;
            if ~isempty(objArray(i))
               if isvalid(objArray(i))
                  thisObj = [thisObj,objArray(i)];
               end
            end
         end
         if numel(thisObj) < n
            thisObj = [];
            if any([objArray.Verbose])
                nigeLab.utils.cprintf('Errors*',...
                    ['\t->\t[GETVALIDOBJ]: Could not find (%g) valid ' ...
                    'nigelObj in (%g object) array\n'],...
                    n,numel(objArray));
            end
         end
      end
      
      % Plays "Alert Ping" nPing times, with nSec between pings
      function PlayAlertPing(nPing,nSec,fmax,fmin,fdir)
         %PLAYALERTPING  Alert user nPing times, with nSec between pings
         %
         %  nigeLab.nigelObj.PlayAlertPing(); Default: 3 pings @ 1-Hz
         %
         %  nigeLab.nigelObj.PlayAlertPing(nPing,nSec,fmax,fmin,fdir);
         %
         %  nPing : # pings
         %  nSec  : approx # sec between pings
         %  fmax  : "max" frequency multiplier (default, high --> low freq)
         %  fmin  : "min" frequency multiplier
         %  fdir  : 1 (set -1 to get low --> high freq) 
         
         if nargin < 1
            nPing = 3;
         end
         
         if nargin < 2
            nSec = 1;
         end
         
         if nargin < 3
            fmax = 1;    % Max. freq multiplier
         end
         
         if nargin < 4
            fmin = 0.5; % Min. freq multiplier
         end
         
         if nargin < 5
            fdir = 1; % "Direction" of sweep
         end
         fscl_mult = fmin / (nPing-1);
         fdir = sign(fdir);
         for i = 1:nPing
            fscl = fmax + fdir*(nPing-i) * fscl_mult;
            nigeLab.sounds.play('alert',fscl);
            pause(nSec);
         end
      end
   end
   
   % STATIC,PROTECTED
   methods (Static,Access=protected)            
      function def = Default(propName,propField)
         %DEFAULTS  Return some default from nigeLab.defaults.Block
         %
         %  def = obj.Defaults('propName');
         
         if nargin < 2
            propField = 'Block';
         end
         def = nigeLab.defaults.(propField)(propName);
      end
      
      % Initialize .Key property
      function key = InitKey
         %INITKEY  Initialize obj.Key for use with unique ID later
         %
         %  keyPair = obj.InitKey();
         
         randomAlphaNumeric = nigeLab.utils.makeHash(3);
         key = struct('Public',randomAlphaNumeric(1),...     % Typically this is used
            'Private',randomAlphaNumeric(2),...% Reserved, basically
            'Name','');
         
       
      end
      
      % Merge structs while retaining old struct fields
      function newStruct_out = MergeStructs(oldStruct,newStruct_in)
         %MERGESTRUCTS  Merges `newStruct` with `oldStruct` while keeping
         %              unique fields of `oldStruct` but replacing
         %              redundant fields with values of `newStruct`
         %
         %  newStruct_Merged = ...
         %     nigeLab.nigelObj.MergeStructs(oldStruct,newStruct);
         %
         %  >> fieldnames(oldStruct) % Returns 'a','b'
         %  >> fieldnames(newStruct) % Returns 'b','c'
         %  >> fieldnames(newStruct_Merged) % Returns 'a','b','c'
         
         fOld = fieldnames(oldStruct);
         fNew = fieldnames(newStruct_in);
         missingFields = setdiff(fOld,fNew);
         commonFields = intersect(fNew,fOld);
                  
         newStruct_out = newStruct_in; % Make copy
         for i = 1:numel(missingFields)
            newStruct_out.(missingFields{i}) = oldStruct.(missingFields{i});
         end
      end
      
      % Parse (important) '.Type' property on load
      function type = ParseType(a)
         %PARSETYPE  Parses .Type property on load
         %
         %  type = nigeLab.nigelObj.ParseType(a);
         %
         %     a : struct (from loadobj)
         
         if ~isfield(a,'Type')
            if isfield(a,'Params')
               type = a.Params.Type;
               return;
            elseif ~isfield(a,'IDFile')
               if ~isfield(a,'FolderIdentifier')
                  type = inputdlg(...
                     ['Please input nigelObj.Type (must be: ' ...
                     'Tank, Animal, or Block)'],...
                     'Insufficient Load Info',...
                     1,{'Tank'});
                  if ~ismember(type,{'Tank','Animal','Block'})
                     error(['nigeLab:' mfilename ':BadType'],...
                        'Invalid .Type: %s\n',type);
                  end
                  type = type{:};
               else
                  type = strsplit(a.FolderIdentifier,'.nigel');
                  type = type{end};
               end
            else
               type = strsplit(a.IDFile,'.nigel');
               type = type{end};
            end
         elseif isempty(a.Type)
            if isfield(a,'Params')
               type = a.Params.Type;
            elseif ~isfield(a,'IDFile')
               if ~isfield(a,'FolderIdentifier')
                  type = inputdlg(...
                     ['Please input nigelObj.Type (must be: ' ...
                     'Tank, Animal, or Block)'],...
                     'Insufficient Load Info',...
                     1,{'Tank'});
                  if ~ismember(type,{'Tank','Animal','Block'})
                     error(['nigeLab:' mfilename ':BadType'],...
                        'Invalid .Type: %s\n',type);
                  end
                  type = type{:};
               else
                  type = strsplit(a.FolderIdentifier,'.nigel');
                  type = type{end};
               end
            else
               type = strsplit(a.IDFile,'.nigel');
               type = type{end};
            end
         else
            type = a.Type;
         end
      end
   end
   % % % % % % % % % % END METHODS% % %
end
