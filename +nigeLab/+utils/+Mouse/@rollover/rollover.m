classdef rollover < matlab.mixin.SetGet
   %ROLLOVER  Monitors "hovered" Controls via Figure.WindowButtonMotionFcn
   %  ** Modified from original FEX version **
   %
   %  ROLLOVER Properties:
   %     Button  --  Set using `hittest`. Current "moused-over" object.
   %
   %     ButtonArray  --  List of "valid" buttons 
   %        * Can be `nigeLab.libs.nigelButton` or
   %          `matlab.ui.control.UIControl`
   %
   %     Default  --  Struct array for "Default" state properties
   %        Fields ['matlab.ui.control.UIControl']
   %        * `String` (contains list of "Default" state strings)
   %        * `CData` (contains list of "Default" state icons)
   %        
   %        Fields ['nigeLab.libs.nigelButton']
   %        * `Hovered` ('off')
   %
   %     Over  --  Struct array for "Over" state properties
   %        Fields ['matlab.ui.control.UIControl']
   %        * `String` (contains list of "Over" state strings)
   %        * `CData` (contains list of "Over" state icons)
   %
   %        Fields ['nigeLab.libs.nigelButton']
   %        * `Hovered` ('on')
   %
   %     Parent  --  Figure that nigeLab.utils.Mouse.rollover "watches"
   %
   %  ROLLOVER Methods:
   %     rollover  --  Class constructor
   %        >> ro = nigeLab.utils.Mouse.rollover(fig,'pName1','pVal1',...);
   %
   %     delete  --  Overloaded to delete "Child" Listener objects
   %        >> delete(ro);
   %
   %     empty  --  Static method creates `empty` [0 x 0] rollover object
   %        >> ro = nigeLab.utils.Mouse.rollover.empty();
   %
   %     getdisp  --  Call `get(ro)` to display property descriptions
   %        >> get(ro);
   %
   %     roll  --  Method assigned to Parent figure WindowButtonMotionFcn
   %        >> ro.Parent.WindowButtonMotionFcn = @ro.roll;
   
   % % % PROPERTIES % % % % % % % % % %
   % PUBLIC
   properties (Access=public)
      Default   struct % Struct for "Default" state with fields: "strings" and "icons"
      Over      struct % Struct for "Over" state with fields: "strings" and "icons"
   end
   
   % DEPENDENT,TRANSIENT,PUBLIC
   properties (Dependent,Transient,Access=public)
      ButtonArray   % Array of "valid" buttons
   end
   
   % DEPENDENT,HIDDEN,TRANSIENT,PUBLIC
   properties (Dependent,Hidden,Transient,Access=public)
      Handles       % Same as `.ButtonArray` (for backwards-compatibility)
      IconsDefault  % 'CData' from PushButton (for backwards-compatibility)
      IconsOver     % 'CData' from PushButton (for backwards-compatibility)
      StringsDefault% 'String' from PushButton (for backwards-compatibility)
      StringsOver   % 'String' from PushButton (for backwards-compatibility)
   end
   
   % ABORTSET,SETOBSERVABLE,TRANSIENT,PUBLIC/PROTECTED
   properties (AbortSet,SetObservable,Transient,GetAccess=public,SetAccess=protected)
      Button   % Pushbutton handle object
   end
   
   % PUBLIC/PROTECTED
   properties (GetAccess=public,SetAccess=protected)
      ButtonClass    char        % 'matlab.ui.control.UIControl' or 'nigeLab.libs.nigelButton'
   end
   
   % TRANSIENT,HIDDEN,PUBLIC/PROTECTED
   properties (Transient,Hidden,GetAccess=public,SetAccess=protected)
      ButtonArray_               % Valid "PushButton" or "NigelButton" handles
      ButtonIndex_   double      % Index of Button into ButtonArray
      ButtonProps_   cell        % Array of Button property names (from Default/Over)
      
   end
   
   % TRANSIENT,PROTECTED
   properties (Transient,Access=protected)
      Listener       % event.listener handle object
   end
   
   % TRANSIENT,PUBLIC/IMMUTABLE
   properties (Transient,GetAccess=public,SetAccess=immutable)
      Parent      matlab.ui.Figure     % matlab.ui.Figure
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % PUBLIC (constructor)
   methods (Access=public)
      % Class constructor
      function ro = rollover(fig,validButtonArray,varargin)
         %ROLLOVER Constructor for ROLLOVER objects
         %
         %  ro = nigeLab.utils.Mouse.rollover(fig,validButtonArray);
         %  ro = nigeLab.utils.Mouse.rollover(__,'Prop1',val1,...);
         %
         %  --> If no `fig` arg, uses gcf
         %  --> If no `validButtonArray` arg, finds any direct "PushButton"
         %       children of the `fig`
         %
         %  Note: ROLLOVER must be assigned to EITHER "listen" for
         %  PushButton or NigelButton hover; it does not track both.
         
         % Check if no inputs are provided
         if nargin < 1 % use current figure for `fig`
            fig = gcf;
         else % Otherwise, `fig` might be numeric if .empty() was used
            % Allow 'empty' object to be constructed (for validation etc)
            if isnumeric(fig)
               dims = fig;
               if numel(dims) < 2
                  dims = [zeros(1,2-numel(dims)),dims];
               end
               ro = repmat(ro,dims);
               return;
            end
            
            if ~isa(fig,'matlab.ui.Figure')
               error(['nigeLab:' mfilename ':BadInputClass'],...
                  '"fig" input must be a figure handle.');
            end
         end
         
         % Check if no `validButtonArray` arg is given
         if nargin < 2
            validButtonArray = findobj(get(fig,'Children'),...
               'Style','pushbutton');
            if isempty(validButtonArray)
               error(['nigeLab:' mfilename ':BadInit'],...
                  ['[ROLLOVER]: nigeLab.utils.Mouse.rollover '...
                  'constructor was called, but no Valid Pushbutton '...
                  'children were found in `fig`.\n'...
                  '\t->\t(Please specify '...
                  'a second input argument with an array of valid '...
                  '''matlab.ui.control.UIControl'' or ' ...
                  '''nigeLab.libs.nigelButton'' child objects to watch)']);
            end
         end
         ro.ButtonArray = validButtonArray;
         
         % Read-only members
         ro.Parent = fig;
         
         % Set figure's WindowButtonMotionFcn to activate rollover effect
         set(fig,'WindowButtonMotionFcn',@(~,~)ro.roll);
         
         % Parse any property-value pairs
         for iV = 1:2:numel(varargin)
            % Minimal error-checking here
            ro.(varargin{iV}) = varargin{iV+1};
         end

         % Add PropertySet Listeners
         ro.Listener = [...
            addlistener(ro,'Button','PreSet',...
            @nigeLab.utils.Mouse.rollover.setDefaultState),...
            addlistener(ro,'Button','PostSet',...
            @nigeLab.utils.Mouse.rollover.setOverState),...
            ];
         
      end
   end
   
   % NO ATTRIBUTES (overloaded methods)
   methods
      % Overloaded delete to take care of Listeners
      function delete(ro)
         %DELETE  Overloaded method to take care of Listeners
         if ~isempty(ro.Listener)
            for i = 1:numel(ro.Listener)
               if isvalid(ro.Listener(i))
                  delete(ro.Listener(i));
               end
            end
         end
      end
      
      % For when `get` is called on object alone
      function getdisp(~)
         %GETDISP  Overloaded method when `get` is called on object alone
         
         % Description of each member of the ROLLOVER object
         description = cell(2,5);
         description{1,1} = 'Button';
         description{2,1} = sprintf(...
            ['Currently "moused-over" object\n'...
            '\t\t\t<strong>*</strong> (Returned by built-in `hittest`)']);
         
         description{1,2} = 'Default';
         description{2,2} = 'Struct with default "watched-object" properties';

         description{1,3} = 'Over';
         description{2,3} = 'Struct with hovered "watched-object" properties';
         
         description{1,4} = 'ButtonArray';
         description{2,4} = sprintf([...
            'Array of "valid" buttons to watch\n' ...
            '\t\t\t<strong>*</strong> ''matlab.ui.control.UIControl'' or \n' ...
            '\t\t\t<strong>*</strong> ''nigeLab.libs.nigelButton''']);
         
         description{1,5} = 'Parent';
         description{2,5} = sprintf(...
            'Handle of figure container.\n\t\t\t<strong>*</strong> READ-ONLY');
         
         % Show class summary
         disp(' ')
         disp('nigeLab.utils.Mouse.<strong>ROLLOVER</strong> properties:')
         disp(' ');
         fprintf(1,'\t->\t<strong>%s</strong>: %s\n',description{:});
      end
      
      % Some property-validation GET/SET methods
      % [DEPENDENT]  Return list of valid Buttons to "watch"
      function value = get.ButtonArray(ro)
         %GET.BUTTONARRAY  Returns list of valid Buttons to "watch"
         %
         %  value = get(ro,'ButtonArray');
         value = ro.ButtonArray_; % Return "stored" value
      end
      % [DEPENDENT]  Assign list of valid Buttons to "watch"
      function set.ButtonArray(ro,value)
         %SET.BUTTONARRAY  Assigns list of valid Buttons to "watch"
         %
         %  set(ro,'ButtonArray',value);
         
         class_ = class(value);
         if isempty(ro.ButtonClass)
            ro.ButtonClass = class_;
         elseif ~strcmp(ro.ButtonClass,class_)
            error(['nigeLab:' mfilename 'BadClass'],...
               '[ROLLOVER]: Already assigned to "watch" %s objects\n',...
               ro.ButtonClass);
         end
         ro.Default = nigeLab.utils.Mouse.rollover.initDefault(value);
         ro.Over = nigeLab.utils.Mouse.rollover.initOver(value);
         ro.ButtonArray_ = value;
         ro.ButtonProps_ = fieldnames(ro.Default); % Set this once
      end
      
      % [DEPENDENT]  Return .Handles (.ButtonArray); (backwards-compatible)
      function value = get.Handles(ro)
         %GET.HANDLES  Returns .Handles (.ButtonArray)
         %
         %  value = get(ro,'Handles');
         value = ro.ButtonArray;
      end
      % [DEPENDENT]  Assign .Handles (.ButtonArray); (backwards-compatible)
      function set.Handles(ro,value)
         %SET.HANDLES  Assign .Handles (.ButtonArray)
         %
         %  set(ro,'Handles',value);
         ro.ButtonArray = value;
      end
      
      % [DEPENDENT]  Return .IconsDefault (backwards-compatible)
      function value = get.IconsDefault(ro)
         %GET.ICONSDEFAULT  Return .IconsDefault (backwards-compatible)
         %
         %  value = get(ro,'IconsDefault');
         if strcmp(ro.ButtonClass,'matlab.ui.control.UIControl')
            value = vertcat(ro.Default.CData);
         else
            value = [];
         end
      end
      % [DEPENDENT]  Assign .IconsDefault  (backwards-compatible)
      function set.IconsDefault(ro,value)
         %SET.ICONSDEFAULT  Assign .IconsDefault  (backwards-compatible)
         %
         %  set(ro,'IconsDefault',value);
         if ~strcmp(ro.ButtonClass,'matlab.ui.control.UIControl')
            return;
         end
         if numel(value) ~= numel(ro.Handles)
            warning(['nigeLab:' mfilename ':BadIconDimensions'],...
               ['[ROLLOVER]: Equal number of icons and buttons needed!\n' ...
               '\t->\t(Defaults were kept)\n']);
            return;
         end
         [ro.Default.CData] = deal(value);
      end
      
      % [DEPENDENT]  Return .IconsOver (backwards-compatible)
      function value = get.IconsOver(ro)
         %GET.ICONSOVER  Return .IconsOver (backwards-compatible)
         %
         %  value = get(ro,'IconsOver');
         if strcmp(ro.ButtonClass,'matlab.ui.control.UIControl')
            value = vertcat(ro.Over.CData);
         else
            value = [];
         end
      end
      % [DEPENDENT]  Assign .IconsOver  (backwards-compatible)
      function set.IconsOver(ro,value)
         %SET.ICONSOVER  Assign .IconsOver  (backwards-compatible)
         %
         %  set(ro,'IconsOver',value);
         if ~strcmp(ro.ButtonClass,'matlab.ui.control.UIControl')
            return;
         end
         if numel(value) ~= numel(ro.Handles)
            warning(['nigeLab:' mfilename ':BadIconDimensions'],...
               ['[ROLLOVER]: Equal number of icons and buttons needed!\n' ...
               '\t->\t(Defaults were kept)\n']);
            return;
         end
         [ro.Over.CData] = deal(value);
      end
      
      % [DEPENDENT]  Return .StringsDefault (backwards-compatible)
      function value = get.StringsDefault(ro)
         %GET.STRINGSDEFAULT  Return .StringsDefault (backwards-compatible)
         %
         %  value = get(ro,'StringsDefault');
         if strcmp(ro.ButtonClass,'matlab.ui.control.UIControl')
            value = vertcat(ro.Default.String);
         else
            value = [];
         end
      end
      % [DEPENDENT]  Assign .StringsDefault  (backwards-compatible)
      function set.StringsDefault(ro,value)
         %SET.STRINGSDEFAULT  Assign .StringsDefault  (backwards-compatible)
         %
         %  set(ro,'StringsDefault',value);
         if ~strcmp(ro.ButtonClass,'matlab.ui.control.UIControl')
            return;
         end
         if numel(value) ~= numel(ro.Handles)
            warning(['nigeLab:' mfilename ':BadStringDimensions'],...
               ['[ROLLOVER]: Equal number of icons and strings needed!\n' ...
               '\t->\t(Defaults were kept)\n']);
            return;
         end
         [ro.Default.String] = deal(value);
      end
      
      % [DEPENDENT]  Return .StringsOver (backwards-compatible)
      function value = get.StringsOver(ro)
         %GET.STRINGSOVER  Return .StringsOver (backwards-compatible)
         %
         %  value = get(ro,'StringsOver');
         if strcmp(ro.ButtonClass,'matlab.ui.control.UIControl')
            value = vertcat(ro.Over.String);
         else
            value = [];
         end
      end
      % [DEPENDENT]  Assign .StringsOver  (backwards-compatible)
      function set.StringsOver(ro,value)
         %SET.STRINGSOVER  Assign .StringsOver  (backwards-compatible)
         %
         %  set(ro,'StringsOver',value);
         if ~strcmp(ro.ButtonClass,'matlab.ui.control.UIControl')
            return;
         end
         if numel(value) ~= numel(ro.Handles)
            warning(['nigeLab:' mfilename ':BadStringDimensions'],...
               ['[ROLLOVER]: Equal number of icons and strings needed!\n' ...
               '\t->\t(Defaults were kept)\n']);
            return;
         end
         [ro.Over.String] = deal(value);
      end
   end
   
   % SEALED,PUBLIC
   methods (Sealed,Access=public)
      % Method assigned to parent figure WindowButtonMotionFcn
      function roll(ro) 
         %ROLL  Assigned to WindowButtonMotionFcn of ro.Parent
         %
         %  ro.Parent.WindowButtonMotionFcn = @ro.roll;
         
         % Return the currently-hovered object
         obj = hittest;
         switch ro.ButtonClass
            case 'nigeLab.libs.nigelButton'
               obj = obj.UserData; % Stored in `Rectangle` object UserData
            case 'matlab.ui.control.UIControl'
               % Do nothing
         end
         ro.Button = obj;
      end
   end
   
   % HIDDEN,STATIC,PUBLIC
   methods (Hidden,Static,Access=public)
      % Method for 'PreSet' .Button Property Set Listener
      function setDefaultState(~,evt)
         %SETDEFAULTSTATE  Return .Button to "default state"
         %
         %  setDefaultState(ro,~,evt);
         %
         %  ro:  Rollover object
         %
         %  Makes assumptions based on .Button being ABORTSET property
         
         ro = evt.AffectedObject;
         if isempty(ro.ButtonIndex_)
            % Then make sure everything is "de-hovered"
            b = ro.ButtonArray;
            idx = 1:numel(b);
         else % Get only the "previous" button
            b = ro.Button;
            idx = ro.ButtonIndex_;
         end
         
         % Set relevant properties (depending on class of button)
         for i = 1:numel(ro.ButtonProps_)
            bp = ro.ButtonProps_{i};
            set(b,bp,ro.Default(idx(i)).(bp));
         end
      end
      
      % Method for 'PostSet' .Button Property Set Listener
      function setOverState(~,evt)
         %SETOVERSTATE  Set .Button to "over state"
         %
         %  setOverState(ro,~,evt);
         %
         %  ro:  Rollover object
         %
         %  Makes assumptions based on .Button being ABORTSET property
         
         ro = evt.AffectedObject;
         if isempty(ro.Button) || isempty(ro.ButtonArray)
            ro.ButtonIndex_ = [];
            return;
         end
         
         ro.ButtonIndex_ = find(ro.ButtonArray==ro.Button(1),1,'first');
         if isempty(ro.ButtonIndex_)
            return;
         end
         b = ro.Button;
         % Set relevant properties (depending on class of button)
         for i = 1:numel(ro.ButtonProps_)
            bp = ro.ButtonProps_{i};
            ro.Button.(bp) = ro.Over(ro.ButtonIndex_).(bp);
         end
      end
   end
   
   % STATIC,PUBLIC
   methods (Static,Access=public)
      % Create "Empty" object
      function ro = empty(~)
         %EMPTY  Return empty nigeLab.libs.behaviorInfo object or array
         %
         %  obj = nigeLab.libs.behaviorInfo.empty();
         %  --> Return scalar (0 x 0) object
         %
         %  obj = nigeLab.libs.behaviorInfo.empty(n);
         %  --> Specify number of empty objects
         
         dims = [0,0];
         ro = nigeLab.utils.Mouse.rollover(dims);
      end
   end
   
   % STATIC,PROTECTED
   methods (Static,Access=protected)
      % Initialize `.Default` property array for n objects by class
      function Default_ = initDefault(obj)
         %INITDEFAULT  Initialize `.Default` property array struct
         %
         %  Default_ = nigeLab.utils.Mouse.rollover.initDefault(n,class_);
         %
         %  obj : Array of buttons 
         %           ('matlab.ui.control.UIControl' or
         %            'nigeLab.libs.nigelButton')
         
         class_ = class(obj);
         switch class_
            case 'matlab.ui.control.UIControl' % Init from obj properties
               Default_ = struct(...
                  'String',get(obj,'String'),...
                  'CData',get(obj,'CData')...
                  );
            case 'nigeLab.libs.nigelButton' % Init as Hovered:'off'
               Default_ = struct(...
                  'Hovered',repmat({'off'},numel(obj),1)...
                  );
            otherwise
               error(['nigeLab:' mfilename ':BadCase'],...
                  '[ROLLOVER]: Unexpected class (''%s'')',class_);
               
         end
      end
      
      % Initialize `.Over` property array for n objects by class
      function Over_ = initOver(obj)
         %INITOVER  Initialize `.Over` property array struct
         %
         %  Default_ = nigeLab.utils.Mouse.rollover.initOver(obj);
         %
         %  obj : Array of buttons 
         %           ('matlab.ui.control.UIControl' or
         %            'nigeLab.libs.nigelButton')
         
         class_ = class(obj);
         switch class_
            case 'matlab.ui.control.UIControl' % Init as `Default`
               Over_ = nigeLab.utils.Mouse.rollover.initDefault(obj);
            case 'nigeLab.libs.nigelButton' % Init as Hovered:'on'
               Over_ = struct(...
                  'Hovered',repmat({'on'},numel(obj),1)...
                  ); 
            otherwise
               error(['nigeLab:' mfilename ':BadCase'],...
                  '[ROLLOVER]: Unexpected class (''%s'')',class_);
         end
      end
   end
   % % % % % % % % % % END PROPERTIES %
   
end