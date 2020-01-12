classdef nigelObj < matlab.mixin.Copyable & ...
                    matlab.mixin.SetGet & ...
                    matlab.mixin.CustomDisplay
   %NIGELOBJ    Superclass of nigeLab data access objects
   %
   %  NIGELOBJ Properties:
   %     ChildMask - Logical array for masking .Children
   %
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
      Fields            cell = nigeLab.nigelObj.Default('Fields')     % Specific things to record
      FieldType         cell = nigeLab.nigelObj.Default('FieldType')  % "Types" corresponding to Fields elements
      FolderIdentifier  char                    % '.nigelBlock', '.nigelAnimal', or '.nigelTank'
      IDInfo      (1,1) struct                  % Struct parsed from ID file
      HasParsFile (1,1) logical=false           % Flag --> True if _Pars.mat exists
      HasParsInit       struct                  % Flag struct --> .param is True if obj.updateParams('param') has been run
      UseParallel       logical                 % Flag indicating parallel processing compatible
   end

   % CONSTANT,PROTECTED
   properties (Constant,Access=protected)
      FileExpr         char = '_%s.mat'     % Expression for _Block or _Animal or _Tank file
      ParamsExpr       char = '%s_Pars.mat' % Expression for parameters file
      ViableFieldTypes cell = nigeLab.nigelObj.Default('ViableFieldTypes') % Valid entries for 'Fields'
   end
   
   % DEPENDENT,PUBLIC
   properties (Dependent,Access=public)
      File        char        % Full file of _Block.mat, _Animal.mat, or _Tank.mat file
      GUI                     % Handle to nigeLab.libs.DashBoard GUI (nigelObj.nigelDash method)
      Input       char        % Path to input file or folder
      Name        char        % Name of the obj (char array)
      OnRemote   (1,1)logical = false  % Is this object running a job on remote worker?
      Output      char        % Path to output folder (same as .Paths.SaveLoc)
      Pars   (1,1)struct      % Parameters struct
      Paths  (1,1)struct      % Detailed paths specifications
      ShortFile   char        % Shortened filename
      SortGUI                 % Handle to nigeLab.Sort GUI (nigelObj.Sort method)
      Type        char        %'Block', 'Animal' or 'Tank'
   end
   
   % DEPENDENT,PUBLIC/PROTECTED
   properties (Dependent,GetAccess=public,SetAccess=protected)
      Duration    char   % Duration (%02g hours, %02g mins, %02g sec)
   end
   
   % DEPENDENT,HIDDEN,PROTECTED (Old properties go here)
   properties (Dependent,Hidden,Access=protected)
      AnimalLoc  char                     % Saving path of extracted/processed animal
      Animals                             % (nigeLab.Animal)  "Child" Animal objects
      Blocks                              % (nigeLab.Block)   "Child" Block objects
      FileExt    char                     % .rhd, .rhs, or other (for this recording) -- Block only
      RecType    char                     % Intan / TDT / other
      KeyPair                             % (struct) .Public, .Private random alphanumeric id
      RecDir     char                     % Tank or Animal INPUT folder
      RecFile    char                     % Full filename of raw binary recording file
      RecSystem                           % (nigeLab.utils.AcqSystem) 'RHS', 'RHD', or 'TDT' (must be one of those)
      SaveLoc    char                     % Top-level OUTPUT folder
      TankLoc    char                     % directory for saving Animal
   end
   
   % DEPENDENT,HIDDEN,PUBLIC
   properties (Dependent,Hidden,Access=public)
      IDFile      char        % .nigelType folder ID file name
      InDef       char        % Default input location
      InPrompt    char        % To print for input path prompts
      OutDef      char        % Default output location
      OutPrompt   char        % To print for output path prompts
   end
   
   % DEPENDENT,SETOBSERVABLE,PUBLIC (Children Objects)
   properties (Dependent,SetObservable,Access=public)
      Children                % Array of "child" objects
   end
   
   % HIDDEN,ABORTSET,SETOBSERVABLE,PUBLIC (Flags)
   properties (Hidden,AbortSet,SetObservable,Access=public)
      InBlindMode(1,1)logical = false  % True if "blind mode" is activated
      IsEmpty    (1,1)logical = false  % True if no data in this (e.g. Empty() method used)
      IsDashOpen (1,1)logical = false  % Is nigeLab.libs.DashBoard GUI open?
      IsMasked   (1,1)logical = true   % true --> obj is "enabled"
      Verbose    (1,1)logical = true   % Display debug output?
   end
   
   % HIDDEN,TRANSIENT,PUBLIC (Listeners and Object "Containers")
   properties (Hidden,Transient,Access=public)
      ChildContainer                            % Container for .Children Dependent property
      ChildListener     event.listener          % Listens for changes in object Children
      GUIContainer                              % Container for handle to GUI (nigeLab.libs.DashBoard)
      ParentListener    event.listener          % Listens for changes in object Parent
      PropListener      event.listener          % Listens for changes in properties of this object
      SortGUIContainer                          % Container for handle to Spike Sorting GUI (nigeLab.Sort)
   end
   
   % HIDDEN,PUBLIC (Index)
   properties (Hidden,GetAccess=public,SetAccess=public)
      Index                            % [a] or [a,b] --> tankObj.Children(a).Children(b)
   end

   % HIDDEN,PROTECTED
   properties (Hidden,Access=protected)
      AcqSystem    nigeLab.utils.AcqSystem % 'RHS', 'RHD', or 'TDT' (must be one of those)
      In     (1,1) struct                  % Input  (folder tree or recording file/dir) paths
      Out    (1,1) struct                  % Output (folder tree) paths      
      Key    (1,1) struct = nigeLab.nigelObj.InitKey()   % Fields are "public" and "private" (reserved for later)
      Params (1,1) struct = struct('Pars',struct,'Paths',struct,'Type','') % Holds dependent properties
   end
   
   % OBSERVABLE,PUBLIC/PROTECTED
   properties (GetObservable,SetObservable,GetAccess=public,SetAccess=protected)
      User  char  = nigeLab.nigelObj.Default('User','Experiment')  % Name of current User
   end
   
   % SETOBSERVABLE,PUBLIC
   properties (SetObservable,Access=public)
      ChildMask   logical     % Logical array for masking .Children
   end   
   % % % % % % % % % % END PROPERTIES %
   
   % % % EVENTS % % % % % % % % % % % %
   % PUBLIC
   events (ListenAccess=public,NotifyAccess=public)
      DashChanged      % Interactions with nigeLab.libs.DashBoard
      ProgressChanged  % Issued as `doMethod` proceeds
      StatusChanged    % Issued when a Field is updated
   end
   % % % % % % % % % % END EVENTS % % %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded methods)
   methods
      % nigeLab.nigelObj Superclass Constructor
      function obj = nigelObj(Type,inPath,outPath,varargin)
         %NIGELOBJ  Superclass constructor to point to files
         %
         %  obj = nigeLab.nigelObj(Type);
         %  --> At minimum, superclass constructor must be given .Type
         %
         %  obj = nigeLab.nigelObj(Type,inPath);
         %  --> Specifies the folder or filename of input data
         %
         %  obj = nigeLab.nigelObj(Type,inPath,outPath);
         %  --> Specifies the folder tree location of output data. This is
         %      a folder that will contain the _Block or _Animal or _Tank
         %      matfile, which is one level above the actual "Block" or
         %      "Animal" or "Tank" folder (which contains the .nigelBlock,
         %      .nigelAnimal, or .nigelTank file respectively).
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
            outPath = '';
         end
         
         obj.Type = Type;
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
         
         % Set these after parsing <'Name',value> so they cannot be
         % overwritten manually by accident, or set to different values. 
         obj.FolderIdentifier = sprintf('.nigel%s',obj.Type);
         
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
               obj.Paths.Name = obj_.Name;
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
            if ~isempty(outPath)
               obj.Output = outPath;
            end
            return; % Skip .updateParams('init')
         elseif ~(ischar(inPath) && ischar(outPath))
            error(['nigeLab:' mfilename ':BadClass'],...
               'Both inPath and outPath must be `char`');
         end
         
         % Assign input and output paths (handled in property set/get)
         if ~isempty(inPath)
            obj.Input  = inPath;                 
         end
         
         if isempty(outPath)
            obj.getSaveLocation();
         else
            obj.Output = outPath;
         end
         
         % Initialize parameters
         if any(~obj.updateParams('init'))
            error(['nigeLab:' mfilename ':BadInit'],...
               'Could not properly initialize parameters.');
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
         
         tf = obj.IsEmpty || builtin('isempty',obj);
      end
      
      % % % GET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT] Get method for .AnimalLoc (backwards compatibility)
      function value = get.AnimalLoc(obj)
         %GET.ANIMALLOC  Dependent property for backwards compatibility
         %
         %  value = get(obj,'AnimalLoc');
         %  --> Returns value of obj.Out.Animal instead
         
         value = nigeLab.utils.getUNCPath(obj.Out.Animal);
         value = strrep(value,'\','/');
      end
      
      % [DEPENDENT] Get method for .Animals (backwards compatibility)
      function value = get.Animals(obj)
         %GET.ANIMALS  Returns .Children of Tank (backwards compatibility)
         %
         %  value = get(obj,'Animals');
         %  --> Returns obj.Children
         
         if numel(obj) > 1
            value = nigeLab.Animal.Empty();
            for i = 1:numel(obj)
               value = [value, obj(i).Children];
            end
         else
            if all(isempty(obj.Children))
               value = nigeLab.Animal.Empty();
            else
               value = obj.Children;
            end
         end
      end
      
      % [DEPENDENT] Get method for .Blocks (backwards compatibility)
      function value = get.Blocks(obj)
         %GET.BLOCKS  Returns .Children of Animal (backwards compatibility)
         %
         %  value = get(obj,'Blocks');
         %  --> Returns obj.Children
         
         if numel(obj) > 1
            value = nigeLab.Block.Empty();
            for i = 1:numel(obj)
               if ~isempty(obj(i).Children)
                  value = [value, obj(i).Children];
               end
            end
         else
            if all(isempty(obj.Children))
               value = nigeLab.Block.Empty();
            else
               value = obj.Children;
            end
         end
      end
      
      % [DEPENDENT] Get method for .Children (handles Empty case)
      function value = get.Children(obj)
         %GET.CHILDREN Get method for .Children (handles Empty case)
         %
         %  value = get(obj,'Children');
         %  --> Returns appropriate Empty array of correct subclass if no 
         %      Children in obj.C container array
         
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
      
      % [DEPENDENT] Get method for .Duration
      function value = get.Duration(obj)
         %GET.DURATION  Returns a time string of the duration of recording
         %
         %  value = get(obj,'Duration');
         
         if ~isempty(obj.SampleRate) && ~isempty(obj.Samples)
            nSec = obj.Samples / obj.SampleRate;
            [~,~,value] = nigeLab.utils.sec2time(nSec);
         else
            value = 'Unknown';
         end
      end
      
      % [DEPENDENT] Get method for .File (_Obj.mat)
      function value = get.File(obj)
         %GET.FILE  Returns _Obj.mat file as char array
         %
         %  value = get(obj,'File');
         %  e.g '/c/path/tank/.nigelTank'
         
         value = obj.getObjfname();
      end
      
      % [DEPENDENT] Get method for .FileExt (recording file type)
      function value = get.FileExt(obj)
         %GET.FILEEXT  Returns char array of file extension
         %
         %  >> value = get(obj,'FileExt');
         %  --> assign obj.In.FileExt to value
         
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
            obj.updateParams('Experiment',true);
            p = obj.getParams('Experiment');
         end
         
         if ismember(obj.In.FileExt,p.SupportedFormats)
            value = obj.In.FileExt;
         else
            if isfield(obj.IDInfo,'FileExt')
               obj.In.FileExt = obj.IDInfo.FileExt;
               value = obj.In.FileExt;
            else
               obj.loadIDFile();
               if isfield(obj.IDInfo,'FileExt')
                  obj.In.FileExt = obj.IDInfo.FileExt;
                  value = obj.In.FileExt;
               end
            end
         end
         
      end
      
      % [DEPENDENT] Get method for .GUI (handle to nigelDash)
      function value = get.GUI(obj)
         %GET.GUI  Returns handle to nigeLab.libs.DashBoard object
         %
         %  value = get(obj,'GUI');
         
         if isempty(obj.GUIContainer)
            value = [];
         else
            value = obj.GUIContainer;
         end
      end
      
      % [DEPENDENT] Get method for .IDFile
      function value = get.IDFile(obj)
         %GET.IDFile  Make sure it exists first, then return it
         %
         %  value = get(obj,'IDFile');
         
         if isempty(obj.FolderIdentifier)
            fname = ['.nigel' obj.Type];
            obj.FolderIdentifier = fname;
         else
            fname = obj.FolderIdentifier;
         end
         
         value = nigeLab.utils.getUNCPath(obj.Output,fname);
      end
      
      % [DEPENDENT] Get method for .InDef (default input location)
      function value = get.InDef(obj)
         %GET.INDEF  Default input location (char array)
         %
         %  value = get(obj,'InDef');
         
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
      
      % [DEPENDENT] Get method for .Input
      function value = get.Input(obj)
         %GET.INPUT  Input file or folder location
         %
         %  value = get(obj,'Input');
         
         if ~isfield(obj.In,obj.Type)
            value = '';
            return;
         end
         value = nigeLab.utils.getUNCPath(obj.In.(obj.Type));
         value = strrep(value,'\','/');
      end
      
      % [DEPENDENT] Get method for .InPrompt
      function value = get.InPrompt(obj)
         %GET.INPROMPT  Header prompt for input file or folder selection
         %
         %  value = get(obj,'InPrompt');
         
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
      
      % [DEPENDENT] Get method for .KeyPair (backwards compatibility)
      function value = get.KeyPair(obj)
         %GET.KEYPAIR  Dependent property for backwards compatibility
         %
         %  value = get(obj,'KeyPair');
         %  --> Returns value of obj.Key instead
         
         value = obj.Key;
      end
      
      % [DEPENDENT] Get method for .Name
      function value = get.Name(obj)
         %GET.Name  Property Get method for .Name
         %
         %  value = get(obj,'Name');

         if ~isfield(obj.Paths,'Name')
            if ~isfield(obj.Pars,obj.Type)
               [~,obj.Pars.(obj.Type)] = obj.updateParams(obj.Type,true);
            end
            obj.Paths.Name = obj.parseNamingMetadata();
         end
         % Just in case something went wrong with parsing:
         if isempty(obj.Paths.Name) 
            switch obj.Type
               case 'Tank'
                  if isfield(obj.Out,'TankName')
                     obj.Paths.Name = obj.Out.TankName;
                  else
                     obj.Paths.Name = obj.parseNamingMetadata();
                  end
               case 'Animal'
                  if isfield(obj.Out,'AnimalName')
                     obj.Paths.Name = obj.Out.TankName;
                  else
                     obj.Paths.Name = obj.parseNamingMetadata();
                  end
               case 'Block'
                  if isfield(obj.Out,'BlockName')
                     obj.Paths.Name = obj.Out.TankName;
                  else
                     obj.Paths.Name = obj.parseNamingMetadata();
                  end
            end
         end
         value = obj.Paths.Name;
      end
      
      % [DEPENDENT] Get method for .OnRemote (running remote job if true)
      function value = get.OnRemote(obj)
         %GET.ONREMOTE  Returns value of OnRemote flag
         %
         %  value = get(obj,'OnRemote');
         
         if isfield(obj.Paths,'OnRemote')
            value = obj.Paths.OnRemote;
            return;
         else
            value = false; % It is always set in qWrapper
         end
      end
      
      % [DEPENDENT] Get method for .Output
      function value = get.Output(obj)
         %GET.OUTPUT  Return output folder tree container folder
         %
         %  value = get(obj,'Output');         

         if isfield(obj.Out,obj.Type)
            value = nigeLab.utils.getUNCPath(obj.Out.(obj.Type));
            value = strrep(value,'\','/');
            return;
         end

         p = obj.SaveLoc;
         if isempty(p)
            if ~obj.getSaveLocation
               value = ''; % Could not return correctly
               warning('Save location (%s) is not set.',obj.Type);
               return;
            else
               p = strrep(obj.Paths.SaveLoc,'\','/');
            end
         end
         F = dir(fullfile(p,obj.Name,'.nigel*'));
         if numel(F) > 1
            % If too many FolderIdentifier files, there is a problem.
            obj.PlayAlertPing(4,0.66);
            error(['nigeLab:' mfilename ':BadFolderTree'],...
               ['Check folder tree; too much Nigel!\n'...
                'Multiple FolderIdentifier files at same tree level.\n' ...
                'A given folder should only contain one .nigelFile!']);
         elseif numel(F) < 1
            % If no FolderIdentifier file yet, then put one there
            obj.saveIDFile();
            nigeLab.utils.cprintf('Comments',...
               'Saved %s (%s) %s file.\n',obj.In.(obj.Type),obj.Type,...
               obj.FolderIdentifier);
            value = p;
            return;
         end
         % If we find the correct FolderIdentifier, return the value
         if strcmp(F.name,obj.FolderIdentifier)
            value = nigeLab.utils.getUNCPath(p);
            value = strrep(value,'\','/');
         else
            obj.PlayAlertPing(4,0.66,1.5,0.75,-1);
            error(['nigeLab:' mfilename ':BadFolderTree'],...
               ['Check folder tree; Nigel is confused!\n'...
                'Unexpected FolderIdentifier files at %s level.\n' ...
                '-->\t(Found %s, but was looking for %s)'],...
                obj.Type,F.name,obj.FolderIdentifier);
         end

      end
      
      % [DEPENDENT] Get method for .OutDef (default output location)
      function value = get.OutDef(obj)
         %GET.OUTDEF  Default output location (char array)
         %
         %  value = get(obj,'OutDef');
         
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
         obj.updateParams(obj.Type,true);
         value = obj.getParams(obj.Type,'SaveLocDefault');
         if ~ischar(obj.Out.Default)
            obj.Out.Default = 'R:\Rat\Intan';
         else
            value = strrep(value,'\','/');
            obj.Out.Default = value;
         end
      end
      
      % [DEPENDENT] Get method for .OutPrompt
      function value = get.OutPrompt(obj)
         %GET.OUTPROMPT   Header prompt for output folder tree location
         %
         %  value = get(obj,'OutPrompt');

         switch obj.Type
            case 'Block'
               value = '[output] BLOCK container folder (Animal)'; 
            case 'Animal'
               value = '[output] ANIMAL container folder (Tank)';
            case 'Tank'
               value = '[output] TANK container folder (Experiment)';
         end
      end
      
      % [DEPENDENT] Get method for 'Pars' property
      function value = get.Pars(obj)
         %GET.PARS  Gets .Pars property of nigelObj
         %
         %  value = get(obj,'Pars',pathStruct);
         %  --> Returns value held in .Params.Pars
         
         value = obj.Params.Pars;
      end
      
      % [DEPENDENT] Get method for 'Paths' property
      function value = get.Paths(obj)
         %GET.PATHS  Gets .Paths property of nigelObj
         %
         %  value = get(obj,'Paths',pathStruct);
         %  --> Returns value held in .Params.Paths
         
         value = obj.Params.Paths;
      end
      
      % [DEPENDENT] Get method for .RecDir (backwards compatibility)
      function value = get.RecDir(obj)
         %GET.RECDIR  Dependent property for backwards compatibility
         %
         %  value = get(obj,'RecDir');
         %  --> Returns value of obj.Paths.RecDir; if empty prompts user to
         %      input this value.

         value = obj.Input;
         if isempty(value)
            f = uigetdir(obj.InDef,obj.InPrompt);
            obj.Input = nigeLab.utils.getUNCPath(f);
         end
         value = nigeLab.utils.getUNCPath(obj.Input);
         value = strrep(value,'\','/');
      end
      
      % [DEPENDENT] Get method for .RecFile (backwards compatibility)
      function value = get.RecFile(obj)
         %GET.RECFILE  Dependent property for backwards compatibility
         %
         %  value = get(obj,'RecFile');
         %  --> Returns value of obj.In.Block instead
         
         value = obj.Input;
         if isempty(value)
            [f,p] = uigetfile(...
               {'*.rhd;*.rhs', 'Intan (*.rhd,*.rhs)'; ...
               '*.Tbk,*.Tdx,*.tev,*.tnt,*.tsq', ...
               'TDT (*.Tbk,*.Tdx,*.tev,*.tnt,*.tsq)'; ...
               '*.mat', 'MATLAB (*.mat)'; ...
               '*.nigelBlock', 'nigelBlock (*.nigelBlock)'; ...
               '*.*', 'All Files (*.*)'},obj.InPrompt,obj.InDef);
            if f == 0
               value = '';
               return;
            end
            obj.Input = nigeLab.utils.getUNCPath(p,f);
         else
            return;
         end
         value = nigeLab.utils.getUNCPath(obj.Input);
         value = strrep(value,'\','/');
      end
      
      % [DEPENDENT] Get method for .RecSystem
      function value = get.RecSystem(obj)
         %GET.RECSYSTEM  Returns value .RecSystem property
         %
         %  value = get(obj,'RecSystem');
         %  --> Depends upon value of obj.AcqSystem
         
         if isempty(obj.AcqSystem)
            value = nigeLab.utils.AcqSystem('UNKNOWN');
            return;
         end
         
         value = obj.AcqSystem;
      end
      
      % [DEPENDENT] Get method for .RecType
      function value = get.RecType(obj)
         %GET.RECTYPE  Returns value .RecType property
         %
         %  value = get(obj,'RecType');
         %  --> Depends upon value of obj.FileExt
         
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
      
      % [DEPENDENT] Get method for .SaveLoc (backwards compatibility)
      function value = get.SaveLoc(obj)
         %GET.SAVELOC  Dependent property for backwards compatibility
         %
         %  NOTE: .SaveLoc should ALWAYS be the folder that CONTAINS the
         %        Output folder tree. Therefore it is always one level
         %        "higher" than nigeLab.nigelObj.Output.
         %
         %  value = get(obj,'SaveLoc');
         %  --> Returns value of obj.Out.Animal if obj is Block
         %  --> Returns value of obj.Out.Tank if obj is Animal
         %  --> Returns value of obj.Out.Experiment if obj is Tank

         value = '';
         switch obj.Type
            case 'Block'
               if isfield(obj.Out,'Animal')
                  value = obj.Out.Animal;
               end
            case 'Animal'
               if isfield(obj.Out,'Tank')
                  value = obj.Out.Tank;
               end
            case 'Tank'
               if isfield(obj.Out,'Experiment')
                  value = obj.Out.Experiment;
               end
         end

         if isempty(value)
            if ~isfield(obj.Paths,'SaveLoc')
               value = '';
            else
               value = obj.Paths.SaveLoc;
               if isstruct(value)
                  value = value.dir;
               end
            end
         end
         value = nigeLab.utils.getUNCPath(value);
         value = strrep(value,'\','/');
      end
      
      % [DEPENDENT] Get method for .ShortFile (for printing names)
      function value = get.ShortFile(obj)
         %GET.SHORTFILE  Get shortened _Obj.mat file name
         %
         %  value = get(obj,'ShortFile');

         value = obj.File;
         [p,f,e] = fileparts(value);
         name = [f e];
         if numel(name) > 16
            nameParts = strsplit(name,'_');
            if numel(nameParts) > 1
               name = [nameParts{1} '_..._' nameParts{end}];
            end
         end
         fParts = strsplit(p,'/');
         if numel(fParts) > 1
            switch numel(fParts) 
               case 2
                  value = ['//' fParts{2} '/' name];
               otherwise
                  value = ['//' fParts{2} '/' fParts{3}  '/.../' name];
            end
         else
            value = ['~/' name];
         end
      end

      % [DEPENDENT] Get method for .SortGUI (handle to nigeLab.Sort)
      function value = get.SortGUI(obj)
         %GET.SORTGUI  Returns handle to nigeLab.Sort object
         %
         %  value = get(obj,'SortGUI');
         
         if isempty(obj.SortGUIContainer)
            value = [];
         else
            value = obj.SortGUIContainer;
         end
      end
      
      % [DEPENDENT] Get method for .TankLoc (backwards compatibility)
      function value = get.TankLoc(obj)
         %GET.TANKLOC  Dependent property for backwards compatibility
         %
         %  value = get(obj,'TankLoc');
         %  --> Returns value of obj.Out.Tank instead
         
         value = nigeLab.utils.getUNCPath(obj.Out.Tank);
         value = strrep(value,'\','/');
      end
      
      % [DEPENDENT] Get method for .Type (ensure returns good .Type)
      function value = get.Type(obj)
         %GET.TYPE  Returns obj.Type ('Block', 'Animal', or 'Tank')
         %
         %  value= get(obj,'Type');
         %  --> Returns value in obj.Params.Type if it is non-empty,
         %      otherwise attempts to parse value from object class.
         
         value = obj.Params.Type; % A default field of obj.Params         
         if isempty(value)
            c = class(obj);
            value = strrep(c,'nigeLab.','');
         end
      end
      
      % Get method for .User
      function value = get.User(obj)
         %GET.User  Property Get method for .User
         %
         %  value = get(obj,'User');
         
         if numel(obj) > 1
            value = cell(size(obj));
            for i = 1:numel(obj)
               if isempty(obj(i).User)
                  setUser(obj(i));
               end
               value{i} = obj.User;
            end
         else
            if isempty(obj.User)
               setUser(obj);
            end
            value = obj.User;
         end
         
      end
      % % % % % % % % % % END GET.PROPERTY METHODS % % %
      
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
         
         if all(isempty(obj))
            return;
         end
         
         % Make sure array isn't saved to same file
         if numel(obj) > 1
            flag = false(size(obj));
            for i = 1:numel(obj)
               if isvalid(obj(i))
                  flag(i) = obj(i).save;
               end
            end
            return;
         end
         
         flag = false;         
         obj.updateParams(obj.Type);
         
         % Do all Dependent variable 'gets' prior to try in case that is
         % where an error occurs:
         [fmt,idt,type] = obj.getDescriptiveFormatting();
         fname = obj.File;
         name = obj.ShortFile;
         
         % Save obj. No longer needs to drop and re-add handles, due
         % to use of `Transient` property attribute         
         varName = [lower(type) 'Obj'];
         out = struct;
         out.(varName) = obj;
         try % The only thing here that can go wrong is something with save
            save(fname,'-struct','out');
            flag = true;
            nigeLab.utils.cprintf(fmt,...
               '%s[%s]: %s saved successfully!\n',idt,type,name);
         catch
            nigeLab.utils.cprintf('Errors*',...
               'Failed to save [%s]: %s\n',type,name);
            return;
         end
         flag = flag && obj.saveIDFile(); % .nigelBlock file saver

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
         
         if ~all(isempty(obj.Children))
            flag = flag && all(save(obj.Children));
         end
         
      end
      
      % [DEPENDENT] Set method for .AnimalLoc (backwards compatibility)
      function set.AnimalLoc(obj,value)
         %SET.ANIMALLOC  Dependent property for backwards compatibility
         %
         %  set(obj,'AnimalLoc',value);
         %  --> Sets value of obj.Out.Animal instead
         
         if isempty(value)
            return;
         end
         if ~ischar(value)
            return;
         end
         obj.Out.Animal = value;
      end
      
      % [DEPENDENT] Set method for .Animals (backwards compatibility)
      function set.Animals(obj,value)
         %SET.ANIMALS  Sets .Children of Tank (backwards compatibility)
         %
         %  set(obj,'Animals',animalObj);
         %  --> Sets (Tank) obj.Children to elements of animalObj array
         
         if numel(obj) > 1
            error(['nigeLab:' mfilename ':BadSize'],...
               'Cannot set .Animals of multiple tankObj simultaneously.');
         end
         
         % Make sure obj.Children is nigeLab.Animal object
         if all(isempty(value))
            obj.Children = nigeLab.Animal.Empty();
         else
            obj.Children = value;
         end
      end
      
      % [DEPENDENT] Set method for .Blocks (backwards compatibility)
      function set.Blocks(obj,value)
         %SET.BLOCKS  Sets .Children of Animal (backwards compatibility)
         %
         %  set(obj,'Blocks',blockObj);
         %  --> Sets (Animal) obj.Children to elements of blockObj array
         
         if numel(obj) > 1
            error(['nigeLab:' mfilename ':BadSize'],...
               'Cannot set .Blocks of multiple animalObj simultaneously.');
         end
         
         % Make sure .Children is nigeLab.Block object
         if all(isempty(value))
            obj.Children = nigeLab.Block.Empty();
         else
            obj.Children = value;
         end
      end
      
      % [DEPENDENT] Set method for .Children property (updates Index)
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
      
      % [DEPENDENT] Set method for .Duration property (does nothing)
      function set.Duration(~,~)
         %SET.DURATION  Duration is only set by .Samples and .SampleRate
      end
      
      % [DEPENDENT] Set method for .File (_Obj.mat)
      function set.File(obj,value)
         %SET.FILE  Sets _Obj.mat file info
         %
         %  set(obj,'File','/c/path/tank/.nigelTank');
         %  --> obj.FolderIdentifier is now set as '.nigelTank'
         %  --> obj.Output is now set as '/c/path/tank'
         
         if isempty(value)
            return;
         end
         if ~ischar(value)
            return;
         end
         [obj.Output,~,obj.FolderIdentifier]=fileparts(value);
      end
      
      % [DEPENDENT] Set method for .FileExt (recording binary)
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
      
      % [DEPENDENT] Set method for .GUI (handle to nigelDash)
      function set.GUI(obj,value)
         %SET.GUI  Sets handle to nigeLab.libs.DashBoard object
         %
         %  set(obj,'GUI',value);
         
         if isempty(value)
            obj.GUIContainer(:) = []; % Remove handle association
            obj.IsDashOpen = false;   % Set flag to false
         else
            obj.GUIContainer = value; % Store association to handle object
            obj.IsDashOpen = true;    % Set flag to true
         end
         
         setChildProp(obj,'GUI',value);
      end
      
      % [DEPENDENT] Set method for .IDFile DEPENDENT property
      function set.IDFile(obj,value)
         %SET.IDFile  Set method for .IDFile DEPENDENT property
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
      
      % Set method for .InBlindMode property
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
                  obj(i).Key.Name = parseNamingMetadata(obj(i));
               end
               obj(i).Name = getKey(obj(i),'Public');
            else
               if isempty(obj(i).Key.Name)
                  obj(i).Key.Name = parseNamingMetadata(obj(i));
               end
               obj(i).Name = getKey(obj(i),'Name');
            end
         end
      end
      
      % [DEPENDENT] Set method for .InDef (default input location)
      function set.InDef(obj,value)
         %SET.INDEF  Default output location (char array)
         %
         %  set(obj,'InDef',value);
         
         obj.In.Default = value;
      end
      
      % [DEPENDENT] Set method for .Index property (to assign all children)
      function set.Index(obj,value)
         %SET.INDEX  Set method for .Index 
         %
         %  set(obj,'Index',3);
         %  --> Would update all obj.Children(i).Index to
         %      [3 i]
         
         obj.Index = value;
         obj.setChildIndex();
      end
      
      % [DEPENDENT] Set method for .InPrompt
      function set.InPrompt(~,~)
         %SET.INPROMPT  Does nothing probably
         %
         %  set(obj,'InPrompt',value);
         
         warning('Cannot set `.InPrompt` (Dependent) property');
      end
      
      % [DEPENDENT] Set method for .Input (recording file or folder)
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
               obj.In.Block = value;
               [a,b,ext] = fileparts(value);
               if strcmp(ext,obj.FolderIdentifier)
                  obj.In.Block = a;
                  [a,b,~] = fileparts(obj.In.Block);
               elseif ~isempty(ext)
                  obj.In.FileExt = ext;
                  obj.RecFile = value;
                  obj.RecDir = a;
               end
               obj.In.Animal = a;
               obj.In.BlockName = b;
               [obj.In.Tank,obj.In.AnimalName,~] = fileparts(obj.In.Animal);
               [obj.In.Experiment,obj.In.TankName,~] = fileparts(obj.In.Tank);
               obj.In.Name = obj.In.BlockName;
            case 'Animal'
               % obj.In.Animal = value;
               obj.RecDir = value;
               [obj.In.Tank,obj.In.AnimalName,~] = fileparts(value);
               [obj.In.Experiment,obj.In.TankName,~] = fileparts(obj.In.Tank);
               obj.In.Name = obj.In.AnimalName;
            case 'Tank'
               % obj.In.Tank = value;
               obj.RecDir = value;
               [obj.In.Experiment,obj.In.TankName,~] = fileparts(value);
               obj.In.Name = obj.In.TankName;
            otherwise
               error(['nigeLab:' mfilename ':BadType'],...
                  'nigelObj has bad Type (%s)',obj.Type);
         end
         
      end
      
      % [DEPENDENT] Set method for .IsDashOpen (flag true if GUI is open)
      function set.IsDashOpen(obj,value)
         %SET.ISDASHOPEN  Set method for .IsDashOpen (flag for GUI)
         %
         %  set(obj,'IsDashOpen',value);
         %  --> value can be true or false
         %  --> Update all Children to take same value
         
         obj.IsDashOpen = value;
         obj.toggleChildDashStatus(value);
      end
      
      % [DEPENDENT] Set method for .KeyPair (now, .Key) to maintain compatibility
      function set.KeyPair(obj,value)
         if isempty(value)
            return;
         end
         obj.Key = value;
      end
      
      % [DEPENDENT] Set method for 'Name' property
      function set.Name(obj,value)
         %SET.Name   Set method for 'Name' property assignments
         
         if isempty(value)
            return;
         end
         if iscell(value)
            if numel(value)==1
               value = repmat(value,1,numel(obj));
            end
            if numel(value) ~= numel(obj)
               error(['nigeLab:' mfilename ':InputSizeMismatch'],...
                  'If using cell, must have same number of elements.');
            else
               for i = 1:numel(obj)
                  switch class(obj)
                     case 'nigeLab.Tank'
                        if ~all(isempty(obj(i).Children))
                           for child = obj(i).Children
                              if isvalid(child)
                                 child.Meta.TankID = value;
                              end
                           end
                        end
                     case 'nigeLab.Animal'
                        if ~all(isempty(obj(i).Children))
                           for child = obj(i).Children
                              if isvalid(child)
                                 child.Meta.AnimalID = value;
                              end
                           end
                        end
                  end
                  obj(i).Paths.Name = value{i};
               end
            end
         elseif ischar(value)
            obj.Paths.Name = value;
            switch class(obj)
               case 'nigeLab.Tank'
                  if ~all(isempty(obj.Children))
                     for child = obj.Children
                        if isvalid(child)
                           child.Meta.TankID = value;
                        end
                     end
                  end
               case 'nigeLab.Animal'
                  if ~all(isempty(obj.Children))
                     for child = obj.Children
                        if isvalid(child)
                           child.Meta.AnimalID = value;
                        end
                     end
                  end
            end
         else
            error(['nigeLab:' mfilename ':BadClass'],...
               'value is %s, but should be cell or char',class(value));
         end
      end
      
      % [DEPENDENT] Set method for 'Pars' property
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
      
      % [DEPENDENT] Set method for 'Paths' property
      function set.Paths(obj,value)
         %SET.PATHS  Sets .Paths property of nigelObj
         %
         %  set(obj,'Paths',pathStruct);
         %  --> If 'Paths' already exists with fields not included in
         %      pathStruct, keep those fields from the old pathStruct
         
         if isempty(value)
            return;
         end
         
         obj.Params.Paths = obj.MergeStructs(obj.Params.Paths,value);
         
      end
      
      % [DEPENDENT] Set method for .OnRemote (running remote job if true)
      function set.OnRemote(obj,value)
         %SET.ONREMOTE  Sets value of OnRemote flag
         %
         %  set(obj,'OnRemote',value);
         %  --> Toggles leading string to .Input and .Output property to
         %        properly reflect the configured path on local or remote
         %        machine.
         
         obj.Paths.OnRemote = value;
         if ~isfield(obj.Pars,'Queue')
            obj.updateParams('Queue',true);
         end
         out = obj.Output;
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
      
      % [DEPENDENT] Set method for .OutDef (default output location)
      function set.OutDef(obj,value)
         %SET.OUTDEF  Default output location (char array)
         %
         %  set(obj,'OutDef',value);
         
         obj.Out.Default = value;
         
      end
      
      % [DEPENDENT] Set method for .Output
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
         
         value = strrep(value,'\','/');         
         % Assign this to the "container" folder
         switch obj.Type
            case 'Block'
               if exist(fullfile(value,'.nigelAnimal'),'file')~=0
                  if ~isempty(obj.Name)
                     value = fullfile(value,obj.Name);
                  else
                     return;
                  end
               end
               obj.Out.Block = value;
               [obj.Out.Animal,obj.Out.BlockName,~] = fileparts(value);
               obj.SaveLoc = obj.Out.Animal;
               [obj.Out.Tank,obj.Out.AnimalName,~] = fileparts(obj.Out.Animal);
               [obj.Out.Experiment,obj.Out.TankName,~] = fileparts(obj.Out.Tank);
            case 'Animal'
               if exist(fullfile(value,'.nigelTank'),'file')~=0
                  if ~isempty(obj.Name)
                     value = fullfile(value,obj.Name);
                  else
                     return;
                  end
               end
               obj.Out.Animal = value;
               [obj.Out.Tank,obj.Out.AnimalName,~] = fileparts(value);
               obj.SaveLoc = obj.Out.Tank;
               [obj.Out.Experiment,obj.Out.TankName,~] = fileparts(obj.Out.Tank);
            case 'Tank'
               obj.Out.Tank = value;
               [obj.Out.Experiment,obj.Out.TankName,~] = fileparts(value);
               obj.SaveLoc = obj.Out.Experiment;
            otherwise
               error(['nigeLab:' mfilename ':BadType'],...
                  'nigelObj has bad Type (%s)',obj.Type);
         end
         obj.saveIDFile();
         
      end
      
      % [DEPENDENT] Set method for .OutPrompt
      function set.OutPrompt(~,~)
         %SET.OUTPROMPT  Does nothing probably
         %
         %  set(obj,'OutPrompt',value);
         
         warning('Cannot set `.OutPrompt` (Dependent) property');
      end
      
      % [DEPENDENT] Set method for .RecDir (backwards compatibility)
      function set.RecDir(obj,value)
         %GET.RECDIR  Dependent property for backwards compatibility
         %
         %  set(obj,'RecDir',value);
         %  --> Sets value of obj.In.Animal if obj is Block
         %  --> Sets value of obj.In.Tank if obj is Animal
         %  --> Sets value of obj.In.Experiment if obj is Tank
         
         if isempty(value)
            return;
         end
         if ~ischar(value)
            return;
         end
         switch obj.Type
            case 'Block'
               obj.In.Animal = value;
            otherwise
               obj.In.(obj.Type) = value;
         end
         obj.Paths.RecDir = value;
      end
      
      % [DEPENDENT] Set method for .RecFile (backwards compatibility)
      function set.RecFile(obj,value)
         %SET.RECFILE  Dependent property for backwards compatibility
         %
         %  set(obj,'RecFile',value);
         %  --> Sets value of obj.In.Block instead
         if isempty(value)
            return;
         end
         if ~ischar(value)
            return;
         end
         obj.Paths.RecFile = value;
      end
      
      % [DEPENDENT] Set method for .RecSystem
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
      
      % [DEPENDENT] Set method for .RecType
      function set.RecType(obj,value)
         %SET.RECTYPE  Sets value .RecType property
         %
         %  set(obj,'RecType',value);
         %  --> Depends upon value of obj.FileExt
         
         obj.In.RecType = value;
      end
      
      % [DEPENDENT] Set method for .SaveLoc (backwards compatibility)
      function set.SaveLoc(obj,value)
         %SET.SAVELOC  Dependent property for backwards compatibility
         %
         %  set(obj,'SaveLoc',value);
         %  --> Sets value of obj.Out.Animal if obj is Block
         %  --> Sets value of obj.Out.Tank if obj is Animal
         %  --> Sets value of obj.Out.Experiment if obj is Tank
         if isempty(value)
            return;
         end
         if ~ischar(value)
            return;
         end
         obj.Paths.SaveLoc = value;
      end
      
      % [DEPENDENT] Set method for .ShortFile (for printing names)
      function set.ShortFile(~,~)
         %SET.SHORTFILE  No set method for this property
      end
      
      % [DEPENDENT] Set method for .SortGUI (handle to nigeLab.Sort object)
      function set.SortGUI(obj,value)
         %SET.SortGUI  Sets handle to nigeLab.Sort object
         %
         %  set(obj,'SortGUI',value);

         for i = 1:numel(obj)
            if isempty(value)
               obj(i).SortGUIContainer(:) = []; % Remove handle association
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

      % [DEPENDENT] Set method for .TankLoc (backwards compatibility)
      function set.TankLoc(obj,value)
         %SET.TANKLOC  Dependent property for backwards compatibility
         %
         %  set(obj,'TankLoc',value);
         %  --> Sets value of obj.Out.Tank instead
         if isempty(value)
            return;
         end
         if ~ischar(value)
            return;
         end
         obj.Out.Tank = value;
      end
      
      % [DEPENDENT] Set method for .Type (ensure returns good .Type)
      function set.Type(obj,value)
         %SET.TYPE  Sets obj.Type ('Block', 'Animal', or 'Tank')
         %
         %  set(obj,'Type',value);
         %  --> Sets value in obj.Params.Type, checking that .Type is
         %      actually a valid value.
         
         if ~ischar(value)
            error(['nigeLab:' mfilename ':BadClass'],...
               'nigelObj.Type must be char');
         end
         
         if ~ismember(value,{'Block','Animal','Tank'})
            value = strrep(value,'.nigel','');
            if ~ismember(value,{'Block','Animal','Tank'})
               value = strrep(class(obj),'nigeLab.','');
               if ~ismember(value,{'Block','Animal','Tank','nigelObj'})
                  error(['nigeLab:' mfilename ':BadType'],...
                     ['Unexpected Type: %s\n' ...
                     '\t-->\tMust be: ''Block,'' ''Animal,'' or ''Tank'''],...
                     value);
               end
            end
         end
         obj.Params.Type = value;
      end
      
      % Set method for 'User' property (validation)
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
            obj(i).User = value;
         end
      end
   end
  
   % PUBLIC
   methods (Access = public)      
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
                        childObj = nigeLab.Block(childData,obj.Output);
                     case 'Tank'
                        childObj = nigeLab.Animal(childData,obj.Output);
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
                  childObj = nigeLab.Animal([],obj.Output,...
                     'InDef',obj.Input);
               case 'Animal'
                  childObj = nigeLab.Block([],obj.Output,...
                     'InDef',obj.Input);
            end % switch obj.Type
         end % if isempty
         
         if nargin < 3
            obj.Children = [obj.Children childObj];
         else
            if numel(size(idx)) == 1
               S = substruct('()',{1,idx});
            else
               S = substruct('()',{idx});
            end
            obj.Children = builtin('subsasgn',obj.Children,...
               S,childObj);
         end % if nargin < 3
         
         % Initialize mask to true if we are adding NEW blocks. 
         % If they have already been added and this is invoked by loadobj,
         % the mask will be bigger than obj.Children
         maskDiff = sum(~isempty(obj.Children)) - numel(obj.ChildMask);
         if maskDiff > 0
            obj.ChildMask = [obj.ChildMask, true(1,maskDiff)];
         end
         for i = 1:numel(childObj)
            
            obj.ChildListener = [obj.ChildListener, ...
               addlistener(childObj(i),'ObjectBeingDestroyed',...
               @(~,evt)obj.assignNULL(evt.AffectedObject)), ...
               addlistener(childObj(i),'StatusChanged',...
               @(~,evt)notify(obj,'StatusChanged',evt)), ...
               addlistener(childObj(i),'IsMasked','PostSet',...
               @(~,propEvt)obj.updateChildMask(propEvt.AffectedObject)),...
               addlistener(childObj(i),'DashChanged',...
                  @(~,evt)obj.requestDash(evt))];
         end % i
         if strcmp(obj.Type,'Animal')
            if maskDiff >= 0
               obj.parseProbes();
            end
         end
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
         %  NIGELAB.BLOCK/CHECKPARALLELCOMPATIBILITY
         
         % Could add parsing here to allow requiredFields to be a 'config' class or
         % something like that, or whatever, that allows it to load in a set of
         % fields from a saved matfile to do the comparison against, as well.
         
         if isempty(requiredFields)
            warning('obj.checkCompatibility was called on empty requiredFields, suggesting something is wrong.');
            fieldIdx = [];
            return;
         end
         
         if numel(obj) > 1
            fieldIdx = cell(size(obj));
            for i = 1:numel(obj)
               fieldIdx{i} = obj(i).checkCompatibility(requiredFields);
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
         error('Missing required Fields. Check nigeLab.defaults.Block');
         
         
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
         uFlag = pFlag && rFlag;
         
         lFlag = license('test','Distrib_Computing_Toolbox'); % Check if toolbox is licensed
         dFlag = ~isempty(ver('distcomp'));  % Check if distributed-computing toolkit is installed
         
         if (pFlag || rFlag) && ~(dFlag && lFlag) % If user indicates they want to run parallel or remote
            str = nigeLab.utils.getNigeLink('nigeLab.defaults.Queue',14,'configured');
            fprintf(1,['nigeLab is %s to use parallel or remote processing, '...
               'but encountered the following issue(s):\n'],str);
            if ~lFlag
               nigeLab.utils.cprintf('SystemCommands',['This machine does not '...
                  'have the Parallel Computing Toolbox license.\n']);
            end
            
            if ~dFlag
               nigeLab.utils.cprintf('SystemCommands',['This machine does not '...
                  'have the Distributed Computing Toolbox installed.\n']);
            end
         end
         
         flag = uFlag && lFlag && dFlag;
         
         obj.UseParallel = flag;
         
         if (nargout < 1) && (~obj.OnRemote)
            nigeLab.utils.cprintf('Comments',...
               '%s (%s) flagged for ',class(obj),obj.Name);
            if flag
               nigeLab.utils.cprintf('*Strings','Parallel Processing\n');
            else
               
               nigeLab.utils.cprintf('*Strings','Serial Processing\n');
            end
         end
         
         if ~isempty(obj.Children)
            setProp(obj.Children,'UseParallel',flag);
         end
         
      end
      
      function [a,idx] = findByKey(objArray,keyStr,keyType)
         %FINDBYKEY  Returns the animal corresponding to keyStr from array
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
               'Need to provide animal array and hash key at least.');
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
         [~,~,allProps] = obj.listInitializedParams();
         for i = 1:numel(allProps)
            thisProp = allProps{i};
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
            if all(s(:,iF))
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
      
      % Returns `paths` struct from folder tree heirarchy
      function paths = getFolderTree(obj,paths)
         %GETFOLDERTREE  Returns paths struct that parses folder names
         %
         %  paths = GETFOLDERTREE(obj);
         %  paths = GETFOLDERTREE(obj,paths);
         %  paths = GETFOLDERTREE(obj,paths,useRemote);
         %
         %  --------
         %   INPUTS
         %  --------
         %  obj       : nigeLab.Block class object
         %
         %    paths        : (optional) struct similar to output from this
         %                   function. This should be passed if paths has
         %                   already been extracted, to preserve paths that
         %                   are not extrapolated directly from
         %                   GETFOLDERTREE.
         
         if ~isa(obj,'nigeLab.Block')
            error(['nigeLab:' mfilename ':BadClass'],...
               'nigeLab.obj/getFolderTree expects BLOCK input.');
         end
         
         if nargin < 2
            paths = struct();
         end
         
         F = fieldnames(obj.Pars.Block.PathExpr);
         del = obj.Pars.Block.Delimiter;
         
         for iF = 1:numel(F) % For each field, update field type
            p = obj.Pars.Block.PathExpr.(F{iF});
            
            if contains(p.Folder,'%s') % Parse for spikes stuff
               % Get the current "Spike Detection method," which gets
               % added onto the front part of the _Spikes and related
               % folders
               p.Folder = sprintf(strrep(p.Folder,'\','/'),...
                  obj.Pars.SD.ID.(F{iF}));
            end
            
            % Set folder name for this particular Field
            paths.(F{iF}).dir = nigeLab.utils.getUNCPath(...
               paths.SaveLoc,[p.Folder]);
            
            % Parse for both old and new versions of file naming convention
            paths.(F{iF}).file = nigeLab.utils.getUNCPath(...
               paths.(F{iF}).dir,[p.File]);
            paths.(F{iF}).f_expr = p.File;
            paths.(F{iF}).old = getOldFiles(p,paths.(F{iF}),'dir');
            paths.(F{iF}).info = nigeLab.utils.getUNCPath(...
               paths.(F{iF}).dir,[p.Info]);
            
         end
         
         function old = getOldFiles(p,fieldPath,type)
            %GETOLDFILES Get struct with file info for possible old files
            old = struct;
            for iO = 1:numel(p.OldFile)
               f = strsplit(p.OldFile{iO},'.');
               f = deblank(strrep(f{1},'*',''));
               if isempty(f)
                  continue;
               end
               O = dir(fullfile(fieldPath.(type),p.OldFile{iO}));
               if isempty(O)
                  old.(f) = O;
               else
                  if O(1).isdir
                     old.(f) = dir(fullfile(O(1).folder,O(1).name,...
                        p.OldFile{iO}));
                  else
                     old.(f) = O;
                  end
               end
            end
         end
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
                        obj(i).getLink([],obj(i).Name) ...
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
         
         if nargin < 2
            pathString = strrep(obj.Output,'\','/');
         elseif isempty(field)
            pathString = strrep(obj.Output,'\','/');
         else
            if ~isfield(obj.Paths,field)
               error(['nigeLab:' mfilename ':UnexpectedString'],...
                  '%s is not a field of obj.Paths',field);
            end
            pathString = strrep(obj.Paths.(field).dir,'\','/');
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
            varargout{1} = [];
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
      
      % Set the save location for
      function flag = getSaveLocation(obj,saveLoc)
         % GETSAVELOCATION   Set the save location for container folder
         %                   that holds the file hierarchy referenced by
         %                   nigelObj.
         %
         %  flag = obj.GETSAVELOCATION; --> Prompts for NIGELOBJ location
         %  from a user interface (UI)
         %
         %  flag = obj.GETSAVELOCATION('save/path/here'); --> Skips the
         %  selection interface
         
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
            if ~obj.genPaths(tmp)
               mkdir(obj.SaveLoc);
               if ~obj.genPaths(tmp)
                  warning('Still no valid save location.');
               else
                  obj.Output = tmp;
                  flag = true;
               end
            else
               obj.Output = tmp;
               flag = true;
            end
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
         
         % DEFAULTS
         flag = false;
         
         if ismember(obj.Type,{'Animal','Tank'})
            flag = true;
            for child = obj.Children
               flag = flag && child.linkToData;
            end
            flag = flag && obj.save();
            return;
         end
         
         % If not otherwise specified, assume extraction has not been done.
         if nargin < 2
            suppressWarning = false;
            field = obj.Fields;
         else
            switch class(suppressWarning)
               case 'char'
                  field = {suppressWarning};
                  f = intersect(field,obj.Fields);
                  if isempty(f)
                     error(['nigeLab:' mfilename ':BadInputChar'],...
                        'Invalid field: %s (%s)',field{:},obj.Name);
                  end
                  field = f;
                  suppressWarning = true;
               case 'cell'
                  field = suppressWarning;
                  f = intersect(field,obj.Fields);
                  if isempty(f)
                     error(['nigeLab:' mfilename ':BadInputChar'],...
                        'Invalid field: %s (%s)',field{:},obj.Name);
                  end
                  field = f;
                  suppressWarning = true;
               case 'logical'
                  field = obj.Fields;
               otherwise
                  error(['nigeLab:' mfilename ':BadInputClass'],...
                     'Unexpected class for ''suppressWarning'': %s',...
                     class(suppressWarning));
            end
         end
         
         % ITERATE ON EACH FIELD AND LINK THE CORRECT DATA TYPE
         N = numel(field);
         warningRef = false(1,N);
         warningFold = false(1,N);
         for ii = 1:N
            fieldIndex = find(ismember(obj.Fields,field{ii}),1,'first');
            if isempty(fieldIndex)
               error(['nigeLab:' mfilename ':BadField'],...
                  'Invalid field: %s (%s)',field{ii},obj.Name);
            end
            pcur = parseFolder(obj,fieldIndex);
            if exist(pcur,'dir')==0
               warningFold(ii) = true;
            elseif isempty(dir([pcur filesep '*.mat']))
               warningRef(ii) = true;
            else
               warningRef(ii) = obj.linkField(fieldIndex);
            end
         end
         
         % GIVE USER WARNINGS
         % Notify user about potential missing folders:
         if any(warningFold)
            warningIdx = find(warningFold);
            nigeLab.utils.cprintf('UnterminatedStrings',...
               'Some folders are missing. \n');
            nigeLab.utils.cprintf('text',...
               '\t-> Rebuilding folder tree ... %.3d%%',0);
            for ii = 1:numel(warningIdx)
               fieldIndex = find(ismember(obj.Fields,field{warningIdx(ii)}),...
                  1,'first');
               pcur = parseFolder(obj,fieldIndex);
               [~,~,~] = mkdir(pcur);
               fprintf(1,'\b\b\b\b%.3d%%',round(100*ii/sum(warningFold)));
            end
            fprintf(1,'\n');
         end
         
         % If any element of a given "Field" is missing, warn user that there is a
         % missing data file for that particular "Field":
         if any(warningRef) && ~suppressWarning
            warningIdx = find(warningRef);
            nigeLab.utils.cprintf('UnterminatedStrings',...
               ['Double-check that data files are present. \n' ...
               'Consider re-running doExtraction.\n']);
            for ii = 1:numel(warningIdx)
               nigeLab.utils.cprintf('text',...
                  '\t%s\t-> Could not find all %s data files.\n',...
                  obj.Name,field{warningIdx(ii)});
            end
         end
         obj.updateStatus('notify'); % Just emits the event in case listeners
         obj.save;
         flag = true;
         
         % Local function to return folder path
         function [pcur,p] = parseFolder(obj,idx)
            % PARSEFOLDER  Local function to return correct folder location
            %
            %  [pcur,p] = parseFolder(obj,fieldIndex);
            
            % Existing name of folder, from "Paths:"
            p = obj.Paths.(obj.Fields{idx}).dir;
            % Current path, depending on local or remote status:
            pcur = nigeLab.utils.getUNCPath(p);
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
         if nargin < 2
            if ~obj.HasParsFile
               if ~obj.checkParsFile()
                  nigeLab.utils.cprintf(fmt,...
                     '%sNo [%s_Pars] file for %s (.User: %s)',...
                     idt,type,obj.Name,obj.User);
                  % Flag returns false
                  return;
               end
            end
         else
            if ~obj.checkParsFile(parsField)
               nigeLab.utils.cprintf(fmt,...
                  '%sNo Pars.%s field saved in [%s_Pars] file for %s (.User: %s)',...
                  idt,parsField,type,obj.Name,obj.User);
               % Flag returns false
               return;
            end
         end
         [~,~,s_all] = listInitializedParams(obj);
         
         fname_params = obj.getParsFilename();
         try
            in = load(fname_params);
            flag = true;
         catch
            nigeLab.utils.cprintf('Errors*',...
               '%sFailed to load [%s_Pars] %s\n',idt,type,fname_params);
            % Flag returns false
            return;
         end
         if isempty(obj.Pars)
            obj.Pars = struct;
         end
         if nargin < 2
            obj.Pars = in.(obj.User);
            F = fieldnames(obj.Pars);
            for iF = 1:numel(F)
               f = F{iF};
               if ismember(f,s_all)
                  obj.HasParsInit.(f) = true;
               end
            end
         else
            obj.Pars.(parsField) = in.(obj.User).(parsField);
            obj.HasParsInit.(parsField) = true;
            nigeLab.utils.cprintf(fmt,...
                  '%sPars.%s loaded from [%s_Pars] file for %s (.User: %s)\n',...
                  idt,parsField,type,obj.Name,obj.User);
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
         ind = sort(ind,'descend');
         ind = reshape(ind,1,numel(ind)); % Make sure it is correctly oriented
         for ii = ind
            p = obj.Children(ii).Paths.SaveLoc;
            if exist(p,'dir')
               rmdir(p,'s');
            end
            fname = obj.getObjfname(p);
            if exist(fname,'file')~=0
               delete(fname);
            end
            delete(obj.Children(ii));
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
         
         varName = sprintf('%sObj',lower(obj.Type));
         new = load(obj.File,varName);
         ff=fieldnames(new.obj);
         if strcmpi(field,'all')
            field = ff;
         end
         indx = find(ismember(ff,field))';
         for f=indx
            obj.(ff{f}) = new.obj.(ff{f});
         end
      end
      
      % Method to save any parameters as a .mat file for a given User
      function flag = saveParams(obj,userName,parsField)
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
         
         if numel(obj) > 1
            flag = true;
            for i = 1:numel(obj)
               flag = flag && obj(i).saveParams(userName,parsField);
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
         
         [~,~,s_all] = listInitializedParams(obj);
         [fmt,idt,type] = obj.getDescriptiveFormatting();
         
         if exist(fname_params,'file')==0
            out = struct;
            out.(userName) = obj.Pars;
            nigeLab.utils.cprintf(fmt,...
               '%sCreating new [%s_Pars] file: %s\n',...
               idt,type,fname_params);
         else
            out = load(fname_params);
            nigeLab.utils.cprintf(fmt(1:(end-1)),...
               '%sMerging [%s_Pars] for : %s\n',idt,type,obj.Name);
            switch parsField
               case 'all'
                  for i = 1:numel(s_all)
                     if isfield(obj.Pars,s_all{i})
                        out.(userName).(s_all{i})=obj.Pars.(s_all{i});
                     end
                  end
               case 'reset'
                  out.(userName)=struct;
               otherwise
                  out.(userName).(parsField)=obj.getParams(parsField);
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
                  'Missing field (''%s'') of (obj.Pars.%s...)\n',...
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
            nigeLab.utils.cprintf('Comments','No %s property: %s',...
               class(obj),propName);
            return;
         elseif sum(idx) > 1
            idx = ismember(propList,propName);
            if sum(idx) < 1
               nigeLab.utils.cprintf('Comments','No %s property: %s',...
                  class(obj),propName);
               return;
            elseif sum(idx) > 1
               error(['nigeLab:' mfilename ':AmbiguousPropertyName'],...
                  ['Bad obj Property naming convention.\n'...
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
                  ['Too many ''.'' delimited fields.\n' ...
                  'Max 2 ''.'' for struct Properties.']);
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
         
         if nargin < 2
            if isstruct(obj.Pars) && ~isempty(obj.Pars)
               if isfield(obj.Pars,'Video')
                  if isfield(obj.Pars.Video,'User')
                     userName = obj.Pars.Video.User;
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
         
         obj.User = userName; % Assignment
         obj.checkParsFile();
      end
      
      % Invokes the spike-sorting interface
      function Sort(obj)
         %SORT  Invoke the spike-sorting interface
         %
         %  Sort(obj);
         %  --> Sets obj.SortGUI to nigeLab.Sort class object
         
         set(obj,'SortGUI',nigeLab.Sort(obj));
      end
      
      % Set ChildMask flag (.IsMasked) for this block
      function updateMaskFlag(obj,childObj)
         %UPDATEMASKFLAG  Sets the ChildMask flag (.IsMasked)
         %
         %  addlistener(obj,'ChildMask','PostSet',...
         %     @obj.updateMaskFlag);
         
         [~,idx] = findByKey(obj.Children,childObj);
         childObj.IsMasked = obj.ChildMask(idx);
      end
      
      % Update .Pars property
      function [flag,p] = updateParams(obj,paramType,forceFromDefaults)
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
         %  forceFromDefaults : [default - false]; if set to true,
         %                       automatically loads `paramType` from 
         %                       `nigelab.defaults.(paramType)`
         %
         %  --------
         %   OUTPUT
         %  --------
         %    flag      :     Flag indicating if setting new path was
         %                    successful.
         
         % PARSE INPUT
         flag = false;
         p = [];
         if isempty(obj)
            return;
         end
         
         if isempty(obj.HasParsInit)
            obj.HasParsInit = struct;
         end
         
         [fmt,idt,type] = obj.getDescriptiveFormatting(); % For saves
         if nargin < 3
            forceFromDefaults = false;
            directParsFlag = false;
         elseif isstruct(forceFromDefaults)
            p = forceFromDefaults; % Pars struct given directly
            forceFromDefaults = false;
            directParsFlag = true;
         else
            directParsFlag = false;
         end
         
         %
         ConstructProps = {'Block','Shortcuts','Animal','Tank'};
         [~,nonInitProps,allProps] = obj.listInitializedParams();
         
         if nargin < 2 % if not supplied then it is 'loadParams: all'
            if obj.HasParsFile
               flag = loadParams(obj);
               if ~flag
                  flag = obj.updateParams('all'); % Then set from +defaults
               end
            end
            return;
         end
         
         if iscell(paramType) % Use recursion to run if cell array is given
            N = numel(paramType);
            if N==0
               flag = true;
               return;
            end % ends recursion
            paramType = paramType(:); % just in case it wasn't a vector for some reason;
            flag = obj.updateParams(paramType{1}) &&...
               obj.updateParams(paramType(2:N));
            return;
         elseif ~ischar(paramType)
            error(['nigeLab:' mfilename ':BadInputClass'],...
               ['nigeLab.%s/updateParams expects paramType ' ...
               'to be cell or char'],class(obj));
         end

         switch lower(paramType)
            case 'all'
               paramType = allProps;
               flag = obj.updateParams(paramType);
               return;
            case 'init'
                for i = 1:numel(nonInitProps)
                  obj.HasParsInit.(nonInitProps{i}) = false;
               end
               flag = obj.updateParams('all',true);
               return;
            case 'check'
               % Checked for "non-initialized" props
               flag = isempty(nonInitProps); 
               p = reshape(nonInitProps,1,numel(nonInitProps));
               return;
            case {'fullcheck','checkfull','full'}
               % Double-check that they have the correct fields
               initProps = setdiff(allProps,nonInitProps);
               for i = 1:numel(initProps)
                  if obj.HasParsInit.(initProps{i})
                     p = nigeLab.defaults.(initProps{i});
                     fcur = fieldnames(obj.Pars.(initProps{i}));
                     fdef = fieldnames(p);
                     fmiss = setdiff(fdef,fcur);
                     if ~isempty(fmiss)
                        obj.updateParams(initProps{i},true);
                     end
                  end
               end
               % Checked for "non-initialized" props
               flag = isempty(nonInitProps); 
               p = reshape(nonInitProps,1,numel(nonInitProps));
               return;

            case 'reset'
               obj.Params.Pars = struct;
               flag = obj.saveParams(obj.User,'reset');
               if ~isempty(obj.HasParsInit)
                  f = fieldnames(obj.HasParsInit);
                  for iF = 1:numel(f)
                     obj.HasParsInit.(f{iF}) = false;
                  end
               end
               flag = flag && obj.updateParams('all',true);
%                if numel(obj.Children) > 0
%                   for i = 1:numel(obj.Children)
%                      flag = flag && obj.Children(i).updateParams('reset');
%                   end
%                end
               return;

            otherwise
               % otherwise, check if not an appropriate member
               idx = find(strcmpi(allProps,paramType),1,'first');
               if isempty(idx)
                  error(['nigeLab:' mfilename ':BadParamsField'],...
                     'Bad obj.Pars field name (''%s'')\n',paramType);
               else % even if it does, make sure it has correct syntax...
                  paramType = allProps{idx};
               end
         end
         
         % LOAD CORRECT CORRESPONDING PARAMETERS
         loadExisting = obj.HasParsFile && ...
            obj.HasParsInit.(paramType) && ...
            ~forceFromDefaults && ~directParsFlag;
         if directParsFlag
            % Then p was already given via `forceFromDefaults` arg
         else
            p = nigeLab.defaults.(paramType)(); % Load parameter defaults
         end
         if loadExisting
            flag = loadParams(obj,paramType); % First, try to LOAD file
            if flag % Then we loaded successfully
               fcur = fieldnames(obj.Pars.(paramType));
               fdef = fieldnames(p);
               fmiss = setdiff(fdef,fcur);
               if ~isempty(fmiss)
                  % Then our loaded params are missing parameters
                  for i = 1:numel(fmiss)
                     obj.Params.Pars.(paramType).(fmiss{i}) = p.(fmiss{i}); % So add
                  end
                  if isempty(obj.HasParsInit)
                     obj.HasParsInit = struct;
                  end
                  obj.HasParsInit.(paramType) = true;
                  nigeLab.utils.cprintf(fmt,...
                     '%s%s.Pars.%s was missing these fields:\n',...
                     idt,obj.Name,paramType);
                  for i = 1:numel(fmiss)
                     nigeLab.utils.cprintf(fmt(1:end-1),...
                        '\t%s<strong>%s</strong>\n',idt,fmiss{i});
                  end
                  nigeLab.utils.cprintf(fmt,...
                     '\n%sLoaded other parameters successfully\n\n',idt);
                  nigeLab.utils.cprintf(fmt,...
                     '\n%sSaving UPDATED %s params for %s (Name: ''%s'' || User: ''%s'')\n',...
                     idt,paramType,upper(type),obj.Name,obj.User);
                  flag = obj.saveParams(obj.User,paramType);
                  updateChildrenFlag = true;
               else
                  nigeLab.utils.cprintf(fmt(1:end-1),...
                     '%s%s parameters [%s] up-to-date\n',...
                     idt,paramType,type);
                  updateChildrenFlag = false;
               end
            else % Otherwise, couldn't load params from User file
               updateChildrenFlag = true;
               obj.Params.Pars.(paramType) = p;
               nigeLab.utils.cprintf(fmt,...
                  '\n%sCould not load saved parameters.\n',idt);
               nigeLab.utils.cprintf(fmt,...
                  '%sSaving NEW %s params for %s (Name: ''%s'' || User: ''%s'')\n',...
                  idt,paramType,upper(type),obj.Name,obj.User);
               if isempty(obj.HasParsInit)
                  obj.HasParsInit = struct;
               end
               obj.HasParsInit.(paramType) = true;
               flag = obj.saveParams(obj.User,paramType);
            end
         else            
            % Parameters were loaded directly from defaults
            if directParsFlag
               updateChildrenFlag = isequal(p,obj.Params.Pars.(paramType));
               if updateChildrenFlag
                  obj.Params.Pars.(paramType) = p;
                  if isempty(obj.HasParsInit)
                     obj.HasParsInit = struct;
                  end
                  obj.HasParsInit.(paramType) = true;
                  if ~isempty(obj.User)
                     nigeLab.utils.cprintf(fmt,...
                        '\n%sSaving PARENT %s params for %s (Name: ''%s'' || User: ''%s'')\n',...
                        idt,paramType,upper(type),obj.Name,obj.User);
                     flag = obj.saveParams(obj.User,paramType);
                  else
                     flag = true;
                  end
               else
                  nigeLab.utils.cprintf(fmt,...
                        '\n%s%s params for %s are CURRENT\n',...
                        idt,paramType,upper(type));
                  obj.HasParsInit.(paramType) = true;
                  flag = true;
               end
            else
               updateChildrenFlag = true;
               obj.Params.Pars.(paramType) = p;
               if isempty(obj.HasParsInit)
                  obj.HasParsInit = struct;
               end
               obj.HasParsInit.(paramType) = true;
               if ~isempty(obj.User)
                  nigeLab.utils.cprintf(fmt,...
                     '\n%sSaving DEFAULT %s params for %s (Name: ''%s'' || User: ''%s'')\n',...
                     idt,paramType,upper(type),obj.Name,obj.User);
                  flag = obj.saveParams(obj.User,paramType);
               else
                  flag = true;
               end
            end
         end
         
         if updateChildrenFlag
            p = obj.Pars.(paramType);
            for i = 1:numel(obj.Children)
               if isvalid(obj.Children(i))
                  flag = flag && obj.Children(i).updateParams(paramType,p);
               end
            end
         end
         
      end
      
      % Update Paths
      function flag = updatePaths(obj,saveLoc)
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
         
         flag = false;
         switch obj.Type
            case 'Animal'
               if nargin ==2
                  obj.Params.Paths.SaveLoc = saveLoc;
               end
               for child = obj.Children
                  p.dir = fullfile(obj.Params.Paths.SaveLoc,child.Name);
                  flag = flag && child.updatePaths(p);
               end
               flag = flag && obj.save;
               return;
            case 'Tank'
               if nargin ==2
                  obj.Params.Paths.SaveLoc = saveLoc;
               else
                  obj.Params.Paths.SaveLoc = fullfile(...
                     fileparts(obj.Paths.SaveLoc),obj.Name);
               end
               for a = obj.Animals
                  p = fullfile(obj.Paths.SaveLoc,a.Name);
                  flag = flag &&a.updatePaths(p);
               end
               flag = flag && obj.save;
               return;
         end
         % Otherwise, obj is nigeLab.Block class
         
         % remove old block matfile
         blockFile = obj.File;
         if exist(blockFile,'file')
            delete(blockFile);
         end
         
         if nargin == 2
            obj.Params.Paths.SaveLoc = saveLoc;
         end
         
         % Get old paths, removing 'SaveLoc' from the list of Fields
         %  that need Paths found for them.
         OldP = obj.Paths;
         OldFN_ = fieldnames(OldP);
         OldFN_(strcmp(OldFN_,'SaveLoc'))=[];
         OldFN = [];
         
         % generate new obj.Paths
         obj.genPaths(fileparts(obj.Paths.SaveLoc));
         P = obj.Paths;
         
         uniqueTypes = unique(obj.FieldType);
         
         % look for old data to move
         filePaths = [];
         for jj=1:numel(uniqueTypes)
            if ~isempty(obj.(uniqueTypes{jj}))
               ff = fieldnames(obj.(uniqueTypes{jj})(1));
               
               fieldsToMove = ff(cellfun(@(x) ~isempty(regexp(class(x),...
                  'DiskData.\w', 'once')),...
                  struct2cell(obj.(uniqueTypes{jj})(1))));
               OldFN = [OldFN;OldFN_(ismember(OldFN_,fieldsToMove))]; %#ok<*AGROW>
               for hh=1:numel(fieldsToMove)
                  if all(obj.getStatus(fieldsToMove{hh}))
                     filePaths = [filePaths; ...
                        cellfun(@(x)x.getPath,...
                        {obj.(uniqueTypes{jj}).(fieldsToMove{hh})},...
                        'UniformOutput',false)'];
                  end %fi
               end %hh
            end %fi
         end %jj
         
         % moves all the files from folder to folder
         for ii=1:numel(filePaths)
            source = filePaths{ii};
            [~,target] = strsplit(source,'\\\w*\\\w*.mat',...
               'DelimiterType', 'RegularExpression');
            target = fullfile(P.SaveLoc,target{1});
            [~,~] = nigeLab.utils.FileRename.FileRename(source,target);
         end
         
         % copy all the info files from one folder to the new one
         for jj = 1:numel(OldFN)
            %     moveFiles(OldP.(OldFN{jj}).file, P.(OldFN{jj}).file);
            moveFilesAround(OldP.(OldFN{jj}).info,P.(OldFN{jj}).info,'mv');
            d = dir(OldP.(OldFN{jj}).dir);d=d(~ismember({d.name},...
               {'.','..'}));
            if isempty(d)
               rmdir(OldP.(OldFN{jj}).dir);
            end
         end
         flag = flag && obj.linkToData;
         flag = flag && obj.save;
         
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
      
   end
   
   % PROTECTED
   methods (Access = protected)
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
               end
            end
         end
         obj.ChildListener = [];
         
         if nargin < 2
            C = obj.Children;
         end
         
         for child = C
            if ~strcmp(child.User,obj.User)
               child.setUser(obj.User);
            end
            
            child.ParentListener =  addlistener(obj,...
               'ChildMask','PostSet',...
               @(~,propEvt)childObj.updateMaskFlag(propEvt.AffectedObject));
            
            obj.ChildListener = [obj.ChildListener, ...
               addlistener(child,'ObjectBeingDestroyed',...
                  @(src,~)obj.assignNULL(src)), ...
               addlistener(child,'StatusChanged',...
                  @(~,evt)notify(obj,'StatusChanged',evt)), ...
               addlistener(child,'DashChanged',...
                  @(~,evt)obj.requestDash(evt))];
            if strcmp(obj.Type,'Animal')
               obj.ChildListener = [obj.ChildListener, ...
                  addlistener(child,'IsMasked','PostSet',...
                     @(~,evt)obj.updateChildMask(evt.AffectedObject))];
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
               obj.PropListener = [obj.PropListener, ...
                  addlistener(obj,'Children','PostSet',...
                     @(~,~)obj.checkBlocksForClones()), ...
                  addlistener(obj,'ChildMask','PostSet',...
                     @(~,~)obj.parseProbes())];
            case 'Tank'
               obj.PropListener = [obj.PropListener,...
                  addlistener(obj,'Children','PostSet',...
                     @(~,~)obj.checkAnimalsForClones)];
               
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
            nigeLab.utils.cprintf('Errors',...
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
      function checkAnimalsForClones(obj)
         % CHECKANIMALSFORCLONES  Event listener callback invoked when a
         %                        new Animal is added to obj.Children.
         %
         %  obj.checkAnimalsForClones;  Ensure no redundancies in
         %                                   obj.Children.
         
         % If no animals or only 1 animal, no need to check
         C = obj.Children;
         if sum(isempty(C)) == 1
            return;
         else
            idx = ~isempty(C);
            C = C(idx);
         end
         % Get names for comparison
         cname = {C.Name};
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
            % obj.Children
            animalIsSame = comparisons_mat(1,:);
            comparisons_mat(1,:) = []; % ensure this row is dropped
            
            % ii indexes current "good" Animal
            child = C(ii);
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
            B = C{aidx,:}; %#ok<*FNDSB>
            addChild(child,B);
            
            % Now, remove redundant animals from array and also remove them
            % from the comparisons matrix since we don't need to redo them
            mask = find(idx);
            obj.Children(mask(animalIsSame)) = []; % Remove from property
            C(animalIsSame) = []; % Remove them from consideration in the array
            idx(animalIsSame) = []; % Remove corresponding indexes
            
            % Lastly, update the comparisons matrices
            iRow = animalIsSame(2:end); % To account for previously-removed row of comparisons
            comparisons_mat(iRow,:) = [];
            % Columns are not removed, since the original animal is kept in
            % the array and we should account for its index.
            comparisons_mat(:,animalIsSame) = [];
         end
      end
      
      % Ensure that there are not redundant Blocks in obj.Children
      % based on the .Name property of each member Block object
      function checkBlocksForClones(obj)
         % CHECKBLOCKSFORCLONES  Creates an nBlock x nBlock logical matrix
         %                       comparing each Block in obj.Children
         %                       to the Name of every other such Block.
         %                       After subtracting the main diagonal of
         %                       this matrix, any row with redundant
         
         % If no Blocks (or only 1 "non-empty" block) then there are no
         % clones in the array.
         b = obj.Children;
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
            warning('%s load issue: file may be corrupt.\n',params_fname);
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
      function flag = checkParsInit(obj,parsField)
         %CHECKPARSINIT  Check parameters to make sure they are initialized
         %                 and if not, then do so.
         %
         %  flag = obj.checkParsInit(); Check all parameters
         %  flag = obj.checkParsInit(parsField);  Just parsField
         %
         %  flag  --  Return true if completed successfully
         
         flag = false;
         if isempty(obj.HasParsInit)
            obj.updateParams('init');
         else
            parsAllReady=obj.updateParams('check');
            if ~parsAllReady % If some weren't initialized
               if nargin < 2
                  F = fieldnames(obj.HasParsInit).';
               else
                  parsField = reshape(parsField,1,numel(parsField));
                  F = intersect(parsField,fieldnames(obj.HasParsInit));
                  f_miss = setdiff(parsField,fieldnames(obj.HasParsInit));
                  for f = f_miss
                     obj.updateParams(f_miss,true);
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
                           obj.updateParams(parsField,true);
                     end
                  end
               end
            end
         end
         flag = true;
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
         
         footer = getFooter;
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
         
         header = getHeader(obj);
         disp(header);
         
         groups = getPropertyGroups(obj,'scalar');
         switch lower(displayType)
            case 'simple'
               % Reduce groups to first array element
               groups = groups(1);
               
            case 'detailed'
               % Don't reduce groups
         end
         matlab.mixin.CustomDisplay.displayPropertyGroups(obj,groups);
         
         footer = getFooter(obj,displayType);
         disp(footer);         
      end
      
      % Overload for matlab.mixin.CustomDisplay.getPropertyGroups
      function groups = getPropertyGroups(obj,displayType)
         %GETPROPERTYGROUPS  Overload for returning properties to display
         %
         %  Overload of matlab.mixin.CustomDisplay.getPropertyGroups to
         %  change default output in Command Window for a scalar nigelObj
         
         if nargin < 2
            displayType = 'default';
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
                        name = strrep(obj.Children(i).Name,'-','_');
                        name = strrep(name,' ','_');
                        if ~regexpi(name,'[a-z]')
                           name = ['Block_' name];
                        end
                        data_out.(name) = getLink(obj.Children(i),[],'Link');
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
                        if ~regexpi(name,'[a-z]')
                           name = ['Animal_' name];
                        end
                        data_out.(name) = getLink(obj.Children(i),[],'Link');
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
      
      % Return full filename to parameters file
      function fname = getParsFilename(obj,useUNC)
         %GETPARSFILENAME  Returns full (UNC) filename to parameters file
         %
         %  f = obj.getParsFilename(); Return UNC path (def)
         %  f = obj.getParsFilename(false); Return `fullfile` version
         
         fname = '';
         if isempty(obj.Name)
            return;
         end
         
         if nargin < 2
            useUNC = true;
         end
         
         if useUNC
            fname = nigeLab.utils.getUNCPath(obj.SaveLoc,...
               sprintf(obj.ParamsExpr,obj.Name));
         else
            fname = fullfile(obj.SaveLoc,...
               sprintf(obj.ParamsExpr,obj.Name));
         end
      end
      
      % Returns the "_Object.mat" file name as char array
      function fname = getObjfname(obj,pname)
         %GETOBJFNAME  Return the "_Object.mat" file name as char array
         %
         %  fname = getObjfname(obj);  Return default file
         %  fname = getObjfname(obj,pname);
         %     --> For example, use this to express pname as
         %        obj.Children(i).Paths.SaveLoc
         
         % Do it this way so that if creating filename for "child" with
         % "parent" .nigelFolderIdentifier (such as during splitting
         % animals), the path to use in combination with id_ext can be
         % changed.
         if nargin < 2
            pname = obj.SaveLoc;
         end
         
         id_ext = sprintf(obj.FileExpr,obj.Type);
         fname = strrep(...
            nigeLab.utils.getUNCPath(pname,[obj.Name id_ext]),...
            '\','/');
      end
      
      % Set some useful path variables to file locations
      function flag = genPaths(obj,SaveLoc)
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
         if nargin < 2
            switch obj.Type
               case 'Tank'
                  SaveLoc = obj.SaveLoc;
               case 'Animal'
                  SaveLoc = obj.TankLoc;
               case 'Block'
                  SaveLoc = obj.AnimalLoc;
            end
         end
         paths.SaveLoc = nigeLab.utils.getUNCPath(SaveLoc,obj.Name);
         
         if strcmp(obj.Type,'Block')
            paths = obj.getFolderTree(paths);
            % Iterate on all the fieldnames, making the folder if it doesn't exist yet
            F = fieldnames(paths);
            F = setdiff(F,'SaveLoc');
            for ff=1:numel(F)
               if exist(paths.(F{ff}).dir,'dir')==0
                  mkdir(paths.(F{ff}).dir);
               end
            end
         else % 'Animal', 'Tank'
            if exist(paths.SaveLoc,'dir')==0
               mkdir(paths.SaveLoc);
            end
         end
         
         obj.Params.Paths = paths;
         flag = true;
      end
      
      % Overloaded method from CustomDisplay superclass
      function s = getFooter(obj,displayType)
         %GETFOOTER  Method overload from CustomDisplay superclass
         %
         %  s = obj.getFooter();
         %  --> Returns custom footer string that links object to
         %      immediately pull up "nigelDash" GUI
         %
         %  s = obj.getFooter('simple'); 
         %  --> Returns footer string for link to "expand" view

         if nargin < 2
            displayType = 'detailed';
         end
         
         if isempty(obj)
            s = '';
            return;
         end
         
         if ~isvalid(obj)
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
               switch inputname(1)
                  case {'obj',''}
                     if isempty(obj(1).Index)
                        guiLinkStr = [guiLinkStr, ...
                           sprintf('nigelDash(blockObj);">%s</a>',...
                              promptStr)];
                        dLink = [dLink, ...
                           sprintf(...
                           ['nigeLab.nigelObj.DisplayCurrent(blockObj); ' ...
                           '">More Details</a>)'])];
                     else
                        guiLinkStr = [guiLinkStr, ...
                           sprintf('nigelDash(tankObj.Children(%g).Children(%g));">%s</a>',...
                              obj(1).Index(1),obj(1).Index(2),promptStr)];
                        dLink = [dLink, ...
                           sprintf(...
                           ['nigeLab.nigelObj.DisplayCurrent(tankObj.Children(%g).Children(%g)); ' ...
                           '">More Details</a>)'],obj(1).Index(1),obj(1).Index(2))];
                     end
                  otherwise
                     guiLinkStr = [guiLinkStr, ...
                        sprintf('nigelDash(%s);">%s</a>',...
                           inputname(1),promptStr)]; 
                     dLink = [dLink, ...
                        sprintf(...
                        ['nigeLab.nigelObj.DisplayCurrent(%s); ' ...
                        '">More Details</a>)'],inputname(1))];
               end
            case 'Animal'
               switch inputname(1)
                  case {'obj',''}
                     if isempty(obj(1).Index)
                        guiLinkStr = [guiLinkStr, ...
                           sprintf('nigelDash(animalObj);">%s</a>',...
                              promptStr)];
                        dLink = [dLink, ...
                           sprintf(...
                           ['nigeLab.nigelObj.DisplayCurrent(animalObj); ' ...
                           '">More Details</a>)'])];
                     else
                        guiLinkStr = [guiLinkStr, ...
                           sprintf('nigelDash(tankObj.Children(%g));">%s</a>',...
                              obj(1).Index,promptStr)];
                        dLink = [dLink, ...
                           sprintf(...
                           ['nigeLab.nigelObj.DisplayCurrent(tankObj.Children(%g)); ' ...
                           '">More Details</a>)'],obj(1).Index)];
                     end
                  otherwise
                     guiLinkStr = [guiLinkStr, ...
                        sprintf('nigelDash(%s));">%s</a>',...
                           inputname(1),promptStr)];
                     dLink = [dLink, ...
                        sprintf(...
                        ['nigeLab.nigelObj.DisplayCurrent(%s); ' ...
                        '">More Details</a>)'],inputname(1))];
               end
            case 'Tank'
               switch inputname(1)
                  case {'obj',''}
                     guiLinkStr = [guiLinkStr, ...
                        sprintf('nigelDash(tankObj);">%s</a>',promptStr)];
                     dLink = [dLink, ...
                        'nigeLab.nigelObj.DisplayCurrent(tankObj); ' ...
                        '">More Details</a>)'];
                  otherwise
                     guiLinkStr = [guiLinkStr, ...
                        sprintf('nigelDash(%s);">%s</a>',...
                        inputname(1),promptStr)];
                     dLink = [dLink, ...
                        sprintf(...
                        ['nigeLab.nigelObj.DisplayCurrent(%s); ' ...
                        '">More Details</a>)'],inputname(1))];
               end
            otherwise
               error(['nigeLab:' mfilename ':BadType'],...
                     'nigelObj has bad Type (%s)',obj(1).Type);   
         end
         
         switch lower(displayType)
            case 'detailed'
               s = sprintf('%s\n%s\n',getLink(obj),guiLinkStr);
            case 'simple'
               s = sprintf('%s\n%s\n%s\n',getLink(obj),guiLinkStr,dLink);
         end

      end

      % Return list of initialized parameters
      function [s_init,s_miss,s_all] = listInitializedParams(obj)
         %LISTINITIALIZEDPARAMS  Return list of initialized parameters
         %
         %  s = obj.listInitializedParams();
         
         curPars = fieldnames(obj.HasParsInit);
         s_init = [];
         for i = 1:numel(curPars)
            if obj.HasParsInit.(curPars{i})
               s_init = [s_init, curPars{i}];
            end
         end
         
         % Get a list of all properties
         PropsToSkip ={'nigelColors','Tempdir'};
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
         
         fid = fopen(obj.IDFile,'r+');
         if (fid < 0)
            if ~isempty(obj.Name)
               % "ID" file doesn't exist; make it using current properties
               obj.saveIDFile();
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
               'Attempt to load non-%s from %s folder.',obj.Type,...
               obj.Type);
         end
         
         mc = metaclass(obj);
         mcp = {mc.PropertyList.Name};
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
                        warning('Bad %s file. Retry load once.\n',...
                            obj.FolderIdentifier);
                        obj.saveIDFile;
                        obj.loadIDFile(false);
                     end
                     return;                     
                  otherwise
                     warning('%s %s value missing.\n',propName{i},...
                        obj.FolderIdentifier);
                     continue;
               end
            end
            setProp(obj,propName{i},propVal{i});
         end         
      end
      
      % Parse metadata from file or folder name of INPUT
      function [name,meta] = parseNamingMetadata(obj,fName,pars)
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
            'VarExprDelimiter','',...
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
               nigeLab.utils.cprintf('Comments',...
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
                  case 'VarExprDelimiter'
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
         nameParts=strsplit(fName,[pars.VarExprDelimiter, '.']);
         
         % Parse variables from defaults.Block "template," which match
         % delimited elements of block recording name:
         regExpStr = sprintf('\\%c\\w*|\\%c\\w*',...
            pars.IncludeChar,pars.DiscardChar);
         splitStr = regexp(pars.DynamicVarExp,regExpStr,'match');
         splitStr = [splitStr{:}];
         
         % Find which delimited elements correspond to variables that
         % should be included by looking at the leading character from the
         % defaults.Block template string:
         incVarIdx = find(cellfun(@(x) x(1)==pars.IncludeChar,splitStr));
         incVarIdx = reshape(incVarIdx,1,numel(incVarIdx));
         
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
            splitStrIdx = incVarIdx(ii);
            varName = deblank( splitStr{splitStrIdx}(2:end));
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
                  warning(['No <strong>%s</strong> "SpecialMeta" configured\n' ...
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
         
         % Last, concatenate parsed (included) variables to get .Name
         str = [];
         nameCon = pars.NamingConvention;
         for ii = 1:numel(nameCon)
            if isfield(meta,nameCon{ii})
               str = [str,meta.(nameCon{ii}),pars.Concatenater];
            end
         end
         name = str(1:(end-numel(pars.Concatenater)));
         
         % Make assignments
         obj.Name = name;
         obj.Meta = meta; 
         obj.Pars.(obj.Type).Parsing = pars;
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
               
            case {'.Tbk', '.Tdx', '.tev', '.tnt', '.tsq'}
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
               
            case ''
               files = dir(nigeLab.utils.getUNCPath(obj.RecFile));
               files = files(~[files.isdir]);
               if isempty(files)
                  recType = 'nigelBlock';
                  obj.RecType = recType;
                  return;
               end
               [~,~,ext] = fileparts(files(1).name);
               switch ext
                  case {'.Tbk', '.Tdx', '.tev', '.tnt', '.tsq'}
                     recType = 'TDT';
                     obj.RecType=recType;
                     obj.FileExt = ext;
                     
                  case '.nigelBlock'
                     recType = 'nigelBlock';
                     obj.RecType=recType;
                     obj.FileExt = ext;
                     
                  case '.mat'
                     recType = 'Matfile';
                     obj.RecType=recType;
                     obj.FileExt = '.mat';
                     
                  otherwise
                     recType = 'other';
                     obj.RecType=recType;
                     obj.FileExt = ext;
                     nigeLab.utils.cprintf('Errors*',...
                        'Not a recognized file extension: %s\n',ext);
                     
               end
               % Ensure that RecFile is a file, not a folder
               obj.RecFile = fullfile(files(1).folder,files(1).name);
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
      
      % Request that DashBoard opens
      function requestDash(obj,evt)
         %REQUESTDASH  Request to open the GUI
         %
         %  addlistener(child,'DashChanged',@(~,evt)obj.requestDash(evt));
         
         if nargin < 2
            evt = nigeLab.evt.dashChanged('Requested');
         end
         doRequest = strcmpi(evt.Type,'Requested') && ~obj.IsDashOpen;
         if ~doRequest
            return;
         end
         switch obj.Type % Since source is child object, cannot be Block
            case 'Block'
               % "Pass the notification up the chain"
               notify(obj,'DashChanged',evt);        
            case 'Animal'
               % "Pass the notification up the chain"
               notify(obj,'DashChanged',evt);
            case 'Tank'
               % Note that nigeLab.libs.DashBoard constructor is only
               % available from tankObj method nigeLab.nigelObj/nigelDash.
               obj.GUI = nigeLab.libs.DashBoard(obj);
               % --> This is INTENTIONAL, so that the object corresponding
               %     to the figure is always "cleaned up" from the base
               %     workspace upon DashBoard destruction.
            otherwise
               error(['nigeLab:' mfilename ':BadType'],...
                     'nigelObj has bad Type (%s)',obj.Type);
         end
            
      end
      
      % Save small folder identifier file
      function flag = saveIDFile(obj)
         %SAVEIDFILE  Save small folder identifier file
         %
         %  flag = obj.saveIDFile();
         %  --> Returns true if save was successful
         
         % Save .nigel___ file to identify this "Type" of folder     
         fid = fopen(obj.IDFile,'w');
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
            if strcmp(obj.Type,'Block')
               fprintf(fid,'FileExt|%s\n',obj.FileExt);
               fprintf(fid,'RecType|%s\n',obj.RecType);
               fprintf(fid,'RecFile|%s\n',obj.RecFile);
            end
            fprintf(fid,'RecDir|%s\n',obj.RecDir);
            fprintf(fid,'User|%s', obj.User);
            fclose(fid);
            flag = true;
         else
            warning('Could not write FolderIdentifier (%s)',obj.IDFile);
            flag = false;
         end
         
         flag = flag && obj.saveParams();
         
      end
      
      % Search for Children "_Obj.mat" files in SaveLoc path
      function C = searchForChildren(obj)
         %SEARCHFORCHILDREN  Returns `dir` file struct for potential
         %                    .Children array members
         %
         %  C = obj.searchForChildren();
         
         switch obj.Type
            case 'Animal'
               C = dir(nigeLab.utils.getUNCPath(...
                        obj.Output,'*_Block.mat'));
               if isempty(C)
                  return;
               end
               obj.Children = nigeLab.Block.Empty([1,numel(C)]);
               varName = 'blockObj';
            case 'Tank'
               C = dir(nigeLab.utils.getUNCPath(...
                        obj.Output,'*_Animal.mat'));
               if isempty(C)
                  return;
               end
               obj.Children = nigeLab.Animal.Empty([1,numel(C)]);
               varName = 'animalObj';
            otherwise % i.e. 'Block'
               C = [];
               return;
         end
         
         for ii=1:numel(C)
            in = load(fullfile(C(ii).folder,C(ii).name),varName);
            obj.addChild(in.(varName),ii);
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
      
      % Toggle .IsDashOpen of all Children
      function toggleChildDashStatus(obj,value)
         %TOGGLECHILDDASHSTATUS  Toggles all Child object dash status
         %
         %  obj.toggleChildDashStatus(); --> Uses obj.IsDashOpen
         %  obj.toggleChildDashStatus(value);
         
         if nargin < 2
            value = obj.IsDashOpen;
         end
         for child = obj.Children
            if isvalid(child)
               child.IsDashOpen = value;
            end
         end
      end
      
      % LISTENER CALLBACK: Updates .ChildMask
      function updateChildMask(obj,childObj)
         %UPDATECHILDMASK  Updates .ChildMask based on childObj.IsMasked
         %
         %  addlistener(childObj,'IsMasked','PostSet',...
         %     @obj.updateChildMask);
         
         [~,idx] = findByKey(obj.Children,childObj);
         if obj.ChildMask(idx)~=childObj.IsMasked
            obj.ChildMask(idx) = childObj.IsMasked;
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
            if ~isfield(a,'Type')
               type = strsplit(a.IDFile,'.');
               type = type{end};
            elseif isempty(a.Type)
               type = strsplit(a.IDFile,'.');
               type = type{end};
            else
               type = a.Type;
            end
            switch type
               case {'Block','nigelBlock'}
                  a = nigeLab.Block(a);
               case {'Animal','nigelAnimal'}
                  a = nigeLab.Animal(a);
               case {'Tank','nigelTank'}
                  a = nigeLab.Tank(a);
               otherwise
                  error(['nigeLab:' mfilename ':BadLoad'],...
                     'Could not load object due to unknown Type');
            end
         end
         
         a.addPropListeners();
         a.loadIDFile();
         a.checkParsInit();
         
         switch a.Type
            case 'Block'
               % So we are allowing Block Object to be saved as a property
               % in this case?
               if a.MultiAnimals > 0
                  for bl=a.MultiAnimalsLinkedBlocks
                     bl.reload();
                  end
               end
            case {'Animal','Tank'}
               a.PropListener(1).Enabled = false;
               % Adds Children if it finds them
               a.searchForChildren();
               a.PropListener(1).Enabled = true;
         end
         b = a;
      end
      
      % Print detailed description to Command Window
      function DisplayCurrent(obj)
         %DISPLAYCURRENT  Print detailed description to Command Window
         %
         %  nigeLab.nigelObj.DisplayCurrent(tankObj);
         
         if isscalar(obj) && isvalid(obj)
            obj.displayScalarObject('detailed');
         else
            disp(obj);
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
      function newStruct = MergeStructs(oldStruct,newStruct)
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
         
         missingFields = setdiff(fieldnames(oldStruct),...
                                 fieldnames(newStruct));

         if ~isempty(missingFields)
            for i = 1:numel(missingFields)
               newStruct.(missingFields{i}) = oldStruct.(missingFields{i});
            end
         end
         
      end
   end
   % % % % % % % % % % END METHODS% % %
end