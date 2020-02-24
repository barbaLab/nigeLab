classdef DashBoard < handle & matlab.mixin.SetGet
   %DASHBOARD  Class constructor for "DashBoard" UI that provides
   %            visual indicator of processing status for Tank,
   %            Animal, and Block objects, as well as a graphical
   %            interface to run extraction methods and visualize
   %            their current progress during remote execution.
   %
   %  tankObj = nigeLab.Tank();
   %  nigelDash = nigeLab.libs.DashBoard(tankObj);
   
   % % % PROPERTIES % % % % % % % % % %   
   % DEPENDENT,PUBLIC/PROTECTED
   properties(Dependent,GetAccess=public,SetAccess=protected)
      ParametersPanel         % table with tabs for .Pars fields; .Children{4}
      QueuePanel              % container for visual progress bars; .Children{3}
      StatsPanel              % current Status & brief description; .Children{2}
      TreePanel               % nodes are: Tank > Animal > Block; .Children{1}
      TitleBar                % Title Bar with "Home" and "Visualization Tools" buttons; .Children{5}
      Visible                 % (Default: 'on') Can be 'off' for figure visibility
   end
   
   % DEPENDENT,HIDDEN,PROTECTED
   properties (Dependent,Hidden,GetAccess=protected)
      Fields         cell        % Array of fields for this tank
      FieldType      cell        % Array of field type for this tank
   end
   
   % IMMUTABLE
   properties(SetAccess=immutable,GetAccess=public)
      RollOver  % Highlights nigelButtons on mouse hover
   end
   
   % PUBLIC/PROTECTED
   properties(GetAccess=public,SetAccess=protected)
      Tank                                              % Tank associated with this DashBoard
      B_split                                           % Blocks with MultiAnimals flag on
      Children       (5,1)  cell                        % Cell array of nigelPanels
      Listener              event.listener              % Array of event listeners to delete on destruction
      RemoteMonitor
      VarName               char                        % Name of this object in base workspace
   end
   
   % PUBLIC/RESTRICTED:NIGELBUTTON
   properties(GetAccess=public,SetAccess=?nigeLab.libs.nigelButton)
      Tree                % widget graphic for datasets as "nodes"
   end   
   
   % PROTECTED
   properties(Access=protected)
      nigelButtons         (1,1) struct = struct('Tree',[],'TitleBar',[])   % Each field is an array of nigelButtons
      RecapAxes                              % "Recap" circles container
      RecapBackground                        % Background "cover" that screens axes lines
      RecapBubble                            % Indicators of "completed" status on RecapAxes
      RecapTable                             % "Recap" table
      Mask                                   % "Mask" indexing vector
      Status                                 % Logical status matrix represented by RecapAxes rectangles
      splitMultiAnimalsUI  nigeLab.libs.splitMultiAnimalsUI      % interface to split multiple animals
      
      
      Tree_ContextMenu     matlab.ui.container.ContextMenu       % UI context menu for launching "do" actions
      Mask_MenuItem        matlab.ui.container.Menu       % Context menu item for .IsMasked property
      DoMethod_MenuItem    matlab.ui.container.Menu       % Context menu item array for 'do' methods
      Sort_MenuItem        matlab.ui.container.Menu       % Context menu item for 'Sort' interface
   end
   
   % SETOBSERVABLE,PUBLIC/PROTECTED
   properties(SetObservable,GetAccess=public,SetAccess=protected)
      nigelGUI             matlab.ui.Figure     % matlab.ui.Figure handle to user interface figure
      Color                struct               % Struct referencing colors
      SelectionIndex double = [1 0 0]           % indexing of currently-selected items
   end
   
   % SETOBSERVABLE,RESTRICTED:SPLITMULTIANIMALSUI
   properties (SetObservable,Access=?nigeLab.libs.splitMultiAnimalsUI)
      toSplit   % Struct array of Block and corresponding Animal to split
      toAdd     % Struct array of Block and corresponding Animal to add
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % EVENTS % % % % % % % % % % % %
   % PUBLIC
   events (ListenAccess=public,NotifyAccess=public)
      TreeSelectionChanged  % Event issued when new node on Tree is clicked
      % --> Has `nigeLab.evt.treeSelectionChanged` event.EventData
   end
   % % % % % % % % % % END EVENTS % % %
   
   % % % METHODS% % % % % % % % % % % %
   % CONSTRUCTOR (RESTRICTED:nigeLab.Tank)
   methods (Access={?nigeLab.Tank,?nigeLab.nigelObj})
      % Class constructor for nigeLab.libs.DashBoard
      function obj = DashBoard(tankObj)
         % DASHBOARD  Class constructor for "DashBoard" UI that provides
         %            visual indicator of processing status for Tank,
         %            Animal, and Block objects, as well as a graphical
         %            interface to run extraction methods and visualize
         %            their current progress during remote execution.
         %
         %  tankObj = nigeLab.Tank();
         %  tankObj.nigelDash(); --> Public method to call from Tank
         %  --> Sets the tankObj.GUI property to DashBoard(tankObj);
         %
         %  Note that .nigelDash() method can be called from any nigelObj,
         %  but that it will only construct the DashBoard if the nigelObj
         %  is a "member" of a Tank hierarchy. Block and Animal objects can
         %  be created separate from a Tank, but in order to use this
         %  interface, you must have a Tank object.
         
         % Check input
         if nargin < 1
            obj = nigeLab.libs.DashBoard.empty(); % Empty DashBoard
            return; % Should always be called from tankObj anyways
         elseif isnumeric(tankObj)
            dims = tankObj;
            if numel(dims) == 1
               dims = [0,dims];
            end
%             delete(obj.nigelGUI); %Just in case a figure is opened
            obj = repmat(obj,dims);
            return;
         end
         
         % Add current path and initialize properties
         addpath(pwd); % (In case path is changed while GUI is open)
         obj.Tank = tankObj;
         obj.Color = nigeLab.libs.DashBoard.initColors();
         
         % Init B_split
         An = obj.Tank.Animals;
         obj.B_split = [An([An.MultiAnimals]).Blocks];
         
         % Build figure and all container panels 
         obj.nigelGUI = buildGUI(obj);
         
         % Add nigelObj hierarchy as a uiw.widget.Tree to "Tree" panel
         pTree = getChild(obj,'TreePanel');
         obj.Tree = buildTree(obj,pTree);
         
         % Add the remote monitor to the "Queue" panel
         pQueue = obj.getChild('QueuePanel');
         obj.RemoteMonitor=nigeLab.libs.remoteMonitor(tankObj,pQueue);
         obj.buildJavaObjs();
         
         % Nest the buttons in the "Tree" panel
         obj.buildButtons(pTree);
         
         % Create recap Table and container for "recap circles"
         obj.buildRecapObjects(tankObj.Fields);
         
         % Build title bar that has "buttons" for visual methods etc.
         obj.buildTitleBar();
         
         % Build parameters UItabGroup
         h=uitabgroup();
         pParam = getChild(obj,'ParametersPanel');
         pParam.nestObj(h,'TabGroup');
         
         % Initialize the current selected node as "root"
         obj.Tree.SelectedNodes = obj.Tree.Root;
         Nodes.Nodes = obj.Tree.Root;
         Nodes.AddedNodes = obj.Tree.Root;
         treeSelectionFcn(obj,obj.Tree,Nodes)
         
         % Initialize the context menu
         obj.Tree_ContextMenu = obj.initUICMenu();
         
         % Add event listeners
         obj.addAllListeners();
         
         % Add "rollover" interaction mediator for nigelButtons
         obj.RollOver = nigeLab.utils.Mouse.rollover(...
            obj.nigelGUI,[obj.nigelButtons.Tree,obj.nigelButtons.TitleBar]);
      end
   end
   
   % NO ATTRIBUTES (overloaded methods)
   methods
      % Overloaded `delete` method to handle child objects
      function delete(obj)
         % DELETE  Overloaded delete function to handle child objects
         %
         %  delete(obj);
         
         % Delete all listener handles
         obj.deleteListeners();
         
         % Delete anything associated with multianimals UI
         if ~isempty(obj.splitMultiAnimalsUI)
            if isvalid(obj.splitMultiAnimalsUI)
               delete(obj.splitMultiAnimalsUI);
            end
         end
         
         % Delete buttons
         if ~isempty(obj.nigelButtons)
            F = fieldnames(obj.nigelButtons);
            for iF = 1:numel(F)
               for b = obj.nigelButtons.(F{iF})
                  if isvalid(b)
                     delete(b);
                  end
               end
            end
         end
         
         % Delete remote monitor
         if ~isempty(obj.RemoteMonitor)
            if isvalid(obj.RemoteMonitor)
               delete(obj.RemoteMonitor);
            end
         end
         
         % Delete "rollover" object
         if ~isempty(obj.RollOver)
            if isvalid(obj.RollOver)
               delete(obj.RollOver);
            end
         end
         
         % Delete nigelGUI figure (if it exists)
         if ~isempty(obj.nigelGUI)
            if isvalid(obj.nigelGUI)
               delete(obj.nigelGUI);
            end
         end
         
         % Finally, notify the TANK that GUI is closed (if it exists)
         if ~isempty(obj.Tank)
            if isvalid(obj.Tank)
               set(obj.Tank,'GUI',nigeLab.libs.DashBoard.empty);
            end
         end
      end     
      
      % % % GET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT] Return .Fields property
      function value = get.Fields(obj)
         if isempty(obj.Tank)
            value = {};
            return;
         end
         value = obj.Tank.Fields;
      end
      
      % [DEPENDENT] Return .FieldType property
      function value = get.FieldType(obj)
         if isempty(obj.Tank)
            value = {};
            return;
         end
         value = obj.Tank.FieldType;
      end
      
      % [DEPENDENT] Return .ParametersPanel property
      function value = get.ParametersPanel(obj)
         value = [];
         if isempty(obj.Children)
            return;
         elseif numel(obj.Children) < 4
            return;
         elseif ~iscell(obj.Children)
            return;
         elseif ~isvalid(obj.Children{4})
            return;
         end  
         value = obj.Children{4};
      end
      
      % [DEPENDENT] Return .QueuePanel property
      function value = get.QueuePanel(obj)
         value = [];
         if isempty(obj.Children)
            return;
         elseif numel(obj.Children) < 3
            return;
         elseif ~iscell(obj.Children)
            return;
         elseif ~isvalid(obj.Children{3})
            return;
         end  
         value = obj.Children{3};
      end
      
      % [DEPENDENT] Return .StatsPanel property
      function value = get.StatsPanel(obj)
         value = [];
         if isempty(obj.Children)
            return;
         elseif numel(obj.Children) < 2
            return;
         elseif ~iscell(obj.Children)
            return;
         elseif ~isvalid(obj.Children{2})
            return;
         end  
         value = obj.Children{2};
      end
      
      % [DEPENDENT] Return .TreePanel property
      function value = get.TreePanel(obj)
         value = [];
         if isempty(obj.Children)
            return;
         elseif numel(obj.Children) < 1
            return;
         elseif ~iscell(obj.Children)
            return;
         elseif ~isvalid(obj.Children{1})
            return;
         end  
         value = obj.Children{1};
      end
      
      % [DEPENDENT] Return .QueuePanel property
      function value = get.TitleBar(obj)
         value = [];
         if isempty(obj.Children)
            return;
         elseif numel(obj.Children) < 5
            return;
         elseif ~iscell(obj.Children)
            return;
         elseif ~isvalid(obj.Children{5})
            return;
         end   
         value = obj.Children{5};
      end
      
      % [DEPENDENT] Return .Visible property
      function value = get.Visible(obj)
         if isempty(obj.nigelGUI)
            value = 'invalid';
            return;
         end
         if isvalid(obj.nigelGUI)
            value = obj.nigelGUI.Visible;
         else
            value = 'invalid';
         end
      end
      % % % % % % % % % % END GET.PROPERTY METHODS % % %
      
      % Hide the GUI figure
      function Hide(obj)
         %HIDE  Hide the GUI figure
         %
         %  obj.Hide();  Makes figure disappear
         %  --> Called after invoking the 'Spike Detection' menu item
         
         for i = 1:numel(obj.Listener)
            obj.Listener(i).Enabled = false;
         end
         
         obj.Visible = 'off';
      end
      
      % Show the GUI figure
      function Show(obj)
         %SHOW  Show the GUI figure
         %
         %  obj.Show();  Makes figure visible
         %  --> Used to restore obj.nigelGUI after obj.Hide() method
         
         obj.Visible = 'on';
         for i = 1:numel(obj.Listener)
            obj.Listener(i).Enabled = true;
         end
      end
      
      % % % SET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT] Set .Fields property
      function set.Fields(~,~)
         % Does nothing (Dependent requires set and get methods)
      end
      
      % [DEPENDENT] Set .FieldType property
      function set.FieldType(~,~)
         % Does nothing (Dependent requires set and get methods)
      end
      
      % [DEPENDENT] Set .ParametersPanel property
      function set.ParametersPanel(obj,value)
         obj.Children{4} = value;
      end
      
      % [DEPENDENT] Set .QueuePanel property
      function set.QueuePanel(obj,value)
         obj.Children{3} = value;
      end
      
      % [DEPENDENT] Set .StatsPanel property
      function set.StatsPanel(obj,value)
         obj.Children{2} = value;
      end
      
      % [DEPENDENT] Set .TreePanel property
      function set.TreePanel(obj,value)
         obj.Children{1} = value;
      end
      
      % [DEPENDENT] Set .QueuePanel property
      function set.TitleBar(obj,value)
         obj.Children{5} = value;
      end
      
      % [DEPENDENT] Set .Visible property
      function set.Visible(obj,value)
         if ~isempty(obj.nigelGUI)
            if isvalid(obj.nigelGUI)
               obj.nigelGUI.Visible = value;
            end
         end
      end
      % % % % % % % % % % END SET.PROPERTY METHODS % % %
   end
   
   % PUBLIC
   methods(Access=public)
      % Return the panel corresponding to a given tag
      % (e.g. getChild('TreePanel'))
      function panelHandle = getChild(obj,tagString)
         % GETCHILDPANEL  Return panel handle that corresponds to tagString
         %
         %  panelHandle = obj.getChild('nigels favorite panel');
         %  --> panelHandle returns handle to nigelPanel with Tag property
         %      of 'nigels favorite panel'
         %
         %  Options:
         %     Children{1}  <--> 'TreePanel'
         %     Children{2}  <--> 'StatsPanel'
         %     Children{3}  <--> 'QueuePanel'
         %     Children{4}  <--> 'ParametersPanel'
         %     Children{5}  <--> 'TitleBar'
         
         idx = 0;
         panelHandle = [];
         while idx < numel(obj.Children)
            idx = idx + 1;
            if isprop(obj.Children{idx},'Tag')
               if strcmpi(obj.Children{idx}.Tag,tagString)
                  panelHandle = obj.Children{idx};
                  break;
               end
            end
         end
         if isempty(panelHandle)
            help('nigeLab.libs.DashBoard/getChild');
            error(['nigeLab:' mfilename ':badPropertyName'],...
               'Could not match nigelPanel Tag (%s).',tagString);
         end
      end
      
      % Returns the "highest-level" nigel object that is currently selected
      function nigelObj = getHighestLevelNigelObj(obj)
         %GETHIGHESTLEVELNIGELOBJ  Return "highest-level" nigel object that
         %                          is currently selected. If it is Block
         %                          or Animal, can return Array.
         %
         %  nigelObj = obj.getHighestLevelNigelObj(); Result depends on
         %     current selection highlight on uiw.widget.Tree (obj.Tree)
         
         if isempty(obj.SelectionIndex)
            nigelObj = [];
            return;
         end
         
         if obj.SelectionIndex(1,2)==0
            nigelObj = obj.Tank;
            return;
         end
         
         tankObj = obj.Tank;
         if obj.SelectionIndex(1,3)==0
            Index = unique(obj.SelectionIndex(:,2));
            nigelObj = tankObj.Children(Index);
            return;
         else
            Index = obj.SelectionIndex(:,[2,3]);
         end
         
         nigelObj = tankObj{Index(:,1),Index(:,2)};
         
      end
      
      % Return the current item selection
      function [block,animal] = getSelectedItems(obj,mode)
         % GETSELECTEDITEMS  Returns the currently-selected items from the
         %                   tree.
         %
         %  [block,animal] = obj.getSelectedItems(mode);
         %
         %  mode: default -- 'obj'
         %        * Can be 'index'
         %        * Can be 'name'
         %
         %  Returns Block and Animal objects corresponding to the selected
         %  Nodes (default). If a different mode is specified, such as
         %  'index' or 'name' then those corresponding properties are
         %  returned instead of the object handle arrays.
         
         if nargin < 2
            mode = 'obj';
         end
         switch lower(mode)
            case 'obj'
               block = [];
               animal = [];
               % SelectedItems will always have consistent # columns, since
               % "unlike" nodes are de-selected during treeSelectionFcn
               SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
               nCol = size(SelectedItems,2);
               switch  nCol
                  case 0  % tank
                     animal = obj.Tank{:};
                     block = obj.Tank{:,:};
                     
                  case 1  % animal
                     animal = obj.Tank.Children.findByKey(SelectedItems);
                     block = [animal.Children];
                     
                  case 2  % block
                     animalIdx = unique(SelectedItems(:,1));
                     animal = obj.Tank.Children.findByKey(animalIdx);
                     block = findByKey([animal.Children],SelectedItems(:,2));
               end
            case 'index'
               SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
               
            case 'name'
               [B,A] = obj.getSelectedItems('obj');
               for i = 1:numel(B)
                  if isfield(B(i).Meta,'AnimalID') && ...
                        isfield(B(i).Meta,'RecID')
                     blockName = sprintf('%s.%s',...
                        B(i).Meta.AnimalID,...
                        B(i).Meta.RecID);
                  else
                     warning(['Missing AnimalID or RecID Meta fields. ' ...
                        'Using Block.Name instead.']);
                     blockName = strrep(B(i).Name,'_','.');
                  end
                  % target is nigelab.Block
                  blockName = blockName(1:min(end,...
                     B(i).Pars.Notifications.NMaxNameChars));
               end
               animal = {A.Name};
            otherwise
               error(['nigeLab:' mfilename ':badInputType3'],...
                  ['Unexpected "mode" value: ''%s''\n' ...
                  '(should be ''obj'', ''index'', or ''name'')'],mode);
         end % case
      end % getSelectedItems
      
      % Update the status table for TANK, ANIMAL, or BLOCK
      function updateStatusTable(obj,~,~)
         %UPDATESTATUSTABLE  Update status table for TANK, ANIMAL, or BLOCK
         %
         %
         
         nigelObj = obj.getHighestLevelNigelObj();
         if isempty(nigelObj)
            return;
         end
         SelectedItems = cat(1,nigelObj.Index);
         switch  nigelObj(1).Type
            case 'Tank'  % tank
               setTankTable(obj);
            case 'Animal'  % animal
               setAnimalTable(obj,SelectedItems);
            case 'Block'  % block
               setBlockTable(obj,SelectedItems);
         end
         
      end
   end
   
   % PROTECTED (in separate files)
   methods (Access = {?nigeLab.libs.splitMultiAnimalsUI,?nigeLab.libs.DashBoard})
     bar = qOperations(obj,operation,target,sel) % Wraps "do" methods of Block
   end
   
   % PROTECTED
   methods(Access=protected)
      % Method to add all listeners
      function addAllListeners(obj)
         % ADDALLLISTENERS  Add all the listeners and contain them in a
         %                  handle array that can be deleted on object
         %                  destruction.
         
         % Add listeners for 'Completed' or 'Changed' events
         obj.Listener = [...
            addlistener(obj,'SelectionIndex','PostSet',...
               @(~,~)obj.toggleSplitUIMenuEnable), ...
            addlistener(obj.Tank,'StatusChanged',...
               @obj.updateStatusTable), ...
            addlistener(obj.RemoteMonitor,'JobCompleted',...
               @obj.refreshStats)];
         
         % Add listeners for Multi-Animals UI tree "pruning"
         for a = obj.Tank.Children
            obj.Listener = [obj.Listener,...
               addlistener(a,'ObjectBeingDestroyed',...
                  @obj.removeFromTree)];
            for b = a.Children
               obj.Listener = [obj.Listener, ...
                  addlistener(b,'ObjectBeingDestroyed',...
                     @obj.removeFromTree)];
            end
         end
         obj.Listener = [obj.Listener, ...
            addlistener(obj.Tank,'ObjectBeingDestroyed',...
               @obj.removeFromTree)];
         
         % Add listeners for uiContextMenu items so that they are
         % appropriately enabled or disabled according to the selection
         obj.Listener = [obj.Listener, ...
            addlistener(obj,'TreeSelectionChanged',...
               @(~,evt)obj.uiCMenu_updateEnable(evt))];
         
      end
      
      % Add a nigelObj to the tree
      function addToTree(obj,nigelObj,addToTank)
         % ADDTOTREE  Add a nigelObj to the tree, for example after
         %            splitting multiple animals.
         %            if addToTank is true, also attaches the nigelobj to
         %            the tank in memory
         %
         %  Typical syntax:
         %  lh = addlistener(obj.splitMultiAnimalsUI,...
         %                    'splitCompleted',...
         %                    @(~,e)obj.addToTree(e.nigelObj));
         
         if nargin < 3
             addToTank = false;
         end
         
         switch class(nigelObj)
            case 'nigeLab.Tank'
               ...
            case 'nigeLab.Animal'
               numAnimals = numel(obj.Tank.Children);
               AnNames = {nigelObj.Name};
               for ii =1:numel(AnNames)
                  indx = strcmp({obj.Tree.Root.Children.Name},AnNames{ii});
                  if any(indx)
                     AnNode = obj.Tree.Root.Children(indx);
                  else
                     AnNode = uiw.widget.CheckboxTreeNode(...
                        'Name',AnNames{ii},...
                        'Parent',obj.Tree.Root);
                     set(AnNode,'UserData',{nigelObj.Key.Public});
                     obj.Listener = [obj.Listener, ...
                         addlistener(nigelObj(ii),'ObjectBeingDestroyed',...
                         @obj.removeFromTree)];                     
                  end

                  Metas = [nigelObj(ii).Children.Meta];
                  BlNames = {Metas.RecID};
                  for jj=1:numel(BlNames)
                     BlNode = uiw.widget.CheckboxTreeNode(...
                        'Name',BlNames{jj},'Parent',AnNode);
                    obj.Listener = [obj.Listener, ...
                        addlistener(nigelObj(ii).Children(jj),'ObjectBeingDestroyed',...
                        @obj.removeFromTree)];
                     set(BlNode,'UserData',...
                         {nigelObj(ii).Key.Public,nigelObj(ii).Children(jj).Key.Public});
                  end
                  if addToTank
                      % Add animal to the block
                      addChild(obj.Tank,nigelObj(ii));
                  end
               end
            case 'nigeLab.Block'
               Metas = [nigelObj.Meta];
               AnNames = {Meta.AnimalID};
               for ii =1:numel(AnNames)
                  AnIndx = strcmp({obj.Tree.Root.Children.Name},AnNames(ii));
                  AnNode = obj.Tree.Root.Children(AnIndx);
                  BlNames = {Metas.RecID};
                  for jj=1:numel(BlNames)
                     BlNode = uiw.widget.CheckboxTreeNode('Name',BlNames{jj},'Parent',AnNode);                     
                     set(BlNode,'UserData',{AnNode.UserData,nigelObj.Key.Public});
                     obj.Listener = [obj.Listener, ...
                         addlistener(nigelObj(jj),'ObjectBeingDestroyed',...
                         @obj.removeFromTree)];  
                  end
                  if addToTank
                      % actually add animals to block
                      obj.Tank.Children(AnIndx).Children = [obj.Tank.Children(AnIndx).Children, nigelObj];
                  end
               end
            otherwise
               error(['nigeLab:' mfilename ':unrecognizedClass'],...
                  'Unexpected class: %s',class(nigelObj));
         end
         
      end
      
      % Add buttons to interface
      function buildButtons(obj,nigelPanelObj)
         % BUILDBUTTONS  Initialize/built buttons on interface panel
         
         if nargin < 2
            nigelPanelObj = obj.getChild('TreePanel');
         end
         
         % Make button axes for this nigelPanelObj (Tree panel)
         pos = nigelPanelObj.InnerPosition;
         pos = [pos(1) + pos(3) / 2, ...
            pos(2) + 0.05, ...
            pos(3) / 2, ...
            pos(4) * 0.15];
         ax = axes('Units','normalized', ...
            'Tag','ButtonAxes',...
            'Position', pos,...
            'Color',obj.Color.panel,...
            'XColor','none',...
            'YColor','none',...
            'NextPlot','add',...
            'XLimMode','manual',...
            'XLim',[0 1],...
            'YLimMode','manual',...
            'YLim',[0 1],...
            'FontName',nigelPanelObj.FontName);
         nigelPanelObj.nestObj(ax,'ButtonAxes');
         p = nigelPanelObj; % For shorter reference
         
         % Create array of nigelButtons
         obj.nigelButtons.Tree = [obj.nigelButtons.Tree, ...
            nigeLab.libs.nigelButton(p, [0.15 0.10 0.70 0.275],'Add',...
            @obj.addNigelObj), ...
            nigeLab.libs.nigelButton(p, [0.15 0.40 0.70 0.275],'Link Data',...
            @obj.linkToData), ...
            nigeLab.libs.nigelButton(p, [0.15 0.70 0.70 0.275],'Save',...
            @obj.saveData),...
            nigeLab.libs.nigelButton(p, [0.15 1.00 0.70 0.275],'Split',...
            @obj.toggleSplitMultiAnimalsUI,'start')];
         
         % By default, buttons are enabled
         if obj.SelectionIndex(1,2) == 0
            setButton(obj.nigelButtons.Tree,'Split','Enable','off');
         end
         
         obj.Listener = [obj.Listener, ...
            addlistener(obj,'SelectionIndex','PostSet',...
            @(~,~)obj.toggleSplitUIMenuEnable)];
         
      end
      
      % Returns figure handle, with layout mediated by core nigelPanels
      function fig = buildGUI(obj)
         % LOADPANELS  Method to create all custom uipanels (nigelPanels)
         %             that populate most of the GUI interface.
         %
         %  obj = nigeLab.libs.Dashboard(tankObj);
         %  obj.buildGUI;   (From method of obj; make appropriate panels)
         %  obj.buildGUI(fig);  Optional: fig allows pre-specification of
         %                                figure handle
         %
         %  obj.Children{1} <--> 'TreePanel'
         %  obj.Children{2} <--> 'StatsPanel'
         %  obj.Children{3} <--> 'QueuePanel'
         %  obj.Children{4} <--> 'ParametersPanel'
         

         fig = figure('Name','nigelDash Interface',...
            'Units','Normalized',...
            'Position',[0.1 0.1 0.8 0.8],...
            'Color',obj.Color.fig,...
            'ToolBar','none',...
            'MenuBar','none',...
            'NumberTitle','off',...
            'DeleteFcn',@(~,~)obj.delete);

         obj.nigelGUI = fig;
         % Create "Tree" panel (nodes are: Tank > Animal > Block)
         str    = {'TreePanel'};
         strSub = {''};
         Tag      = 'TreePanel';
         Position = [.01,.01,.23,.91];
         %[left bottom width height] (normalized [0 to 1])
         obj.Children{1} = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',obj.Color.panel,...
            'TitleBarColor',obj.Color.primary,...
            'TitleColor',obj.Color.onprimary,...
            'TitleBarPosition',[0.000 0.9725 1.000 0.0275]);
         
         % Create "Stats" panel (current Status & brief description)
         str    = {'StatsPanel'};
         strSub = {''};
         Tag      = 'StatsPanel';
         Position = [.25, .45, .53 ,.47];
         obj.Children{2} = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',obj.Color.panel,...
            'TitleBarColor',obj.Color.primary,...
            'TitleColor',obj.Color.onprimary);
         
         % Create "Queue" Panel (container for visual progress bars)
         str    = {'QueuePanel'};
         strSub = {''};
         Tag      = 'QueuePanel';
         Position = [.25, .01, .53 , .43];
         obj.Children{3} = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',obj.Color.panel,...
            'TitleBarColor',obj.Color.primary,...
            'TitleColor',obj.Color.onprimary,...
            'Scrollable','on');
         
         % Create "Parameters" Panel (table with tabs for .Pars fields)
         str    = {'ParametersPanel'};
         strSub = {''};
         Tag      = 'ParametersPanel';
         Position = [.79 , .01, .2, 0.91];
         obj.Children{4} = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',obj.Color.panel,...
            'TitleBarColor',obj.Color.primary,...
            'TitleColor',obj.Color.onprimary,...
            'TitleBarPosition',[0.000 0.9725 1.000 0.0275]);
         
      end
      
      % Build Java objects associated with Tree object
      function buildJavaObjs(obj)
         % BUILDJAVAOBJS  Builds the Java objects associated with Tree
         %
         %  obj.buildJavaObjs(); Should just be called in constructor
         
         % Cosmetic adjustments
         Jobjs = obj.Tree.getJavaObjects;
         Jobjs.JScrollPane.setBorder(...
            javax.swing.BorderFactory.createEmptyBorder)
         Jobjs.JScrollPane.setComponentOrientation(...
            java.awt.ComponentOrientation.RIGHT_TO_LEFT);
      end
      
      % Construct recap table for recording
      function buildRecapObjects(obj,Fields)
         % BUILDRECAPOBJECTS  Construct "recap table" for displaying basic
         %                    info about the recording, and "recap axes"
         %                    for containing PLOTRECAPBUBBLES
         %
         %  obj.buildRecapTable(nFields);
         %  --> nFields: number of fields (# columns in table)
         

         vOff = .025;
         hOff = .025;
         nigelPanelObj = obj.getChild('StatsPanel');
         nField = numel(Fields);         
         ppos = nigelPanelObj.InnerPosition;
         tab_pos = ppos .* [1 1 1 .5] + [hOff vOff+.7 -hOff*2 -vOff*10];
         obj.RecapTable = uiw.widget.Table(...
            'Parent',nigelPanelObj.Panel,...
            'CellEditCallback',[],...
            'CellSelectionCallback',[],...
            'Units','normalized', ...
            'Position',tab_pos,...
            'BackgroundColor',obj.Color.panel,...
            'FontName','Droid Sans');
         nigelPanelObj.nestObj(obj.RecapTable);
         RecapTableMJScrollPane = obj.RecapTable.JControl.getParent.getParent;
         RecapTableMJScrollPane.setBorder(...
            javax.swing.BorderFactory.createEmptyBorder);
         
         ax_pos = ppos .* [1 1 1 .5] + [hOff vOff -hOff*2 -vOff*4];
         obj.RecapAxes = axes(nigelPanelObj.Panel,...
            'Units','normalized', ...
            'Position', ax_pos,...
            'Tag','RecapAxes',...
            'Color','none',...
            'TickLength',[0 0],...
            'XAxisLocation','top',...
            'XLimMode','manual',...
            'XLim',[1 nField+1],...
            'LineWidth',0.005,...
            'GridColor','none',...
            'XColor',obj.Color.onPanel,...
            'YColor',obj.Color.onPanel,...
            'NextPlot','add',...
            'YDir','reverse',...
            'YLimMode','manual',...
            'YLim',[0 1],...
            'Box','off',...
            'Clipping','off',...
            'FontName','Droid Sans',...
            'FontSize',13,...
            'FontWeight','bold');
         % axes cosmetic adjustment:
         obj.RecapAxes.XAxis.TickLabelRotation = 75;
         obj.RecapAxes.XAxis.TickLabel = Fields;
         obj.RecapAxes.XAxis.TickValues = 1.5:(nField+0.5);
         % This removes the X- and Y- borders (crazy to have to do that
         % kind of workaround but oh well):
         obj.RecapBackground =  ...
            rectangle(obj.RecapAxes,...
               'Position',[0.95 -0.05 (nField+0.60) 1.1],...
               'Clipping','off',...
               'EdgeColor','none',...
               'FaceColor',obj.Color.panel);
            
         nigelPanelObj.nestObj(obj.RecapAxes,'RecapAxes');
         drawnow;
      end
      
      % Build the "Title Bar" with HOME & VISUALIZATION TOOLS buttons
      function buildTitleBar(obj,Position,LButtons,RButtons)
         %BUILDTITLEBAR  Creates the Title Bar with a few more buttons
         %
         %  obj.buildTitleBar();
         %  --> Uses default Position and Buttons
         %
         %  obj.buildTitleBar(Position,Buttons);
         %  --> Position: Normalized position of title bar (in Figure)
         %  --> Buttons: Array struct with fields .String (button string)
         %               and .Callback (button callbacks). See
         %               nigeLab.libs.nigelBar and nigeLab.libs.nigelButton
         %               for more details.
         
         if nargin < 2
            Position = [.01,.93,.98,.06];
         end
         if nargin < 3
            LButtons = struct('String',  {'Home','Visualization Tools'},...
               'Callback',{''    ,''}); % ADD HOME / VISUAL CB HERE
         end
         if nargin < 4
            RButtons = struct('String', {'Video Tools'},...
               'Callback',{''});
         end
         p = nigeLab.libs.nigelPanel(obj.nigelGUI,'Tag','TitlePanel',...
            'Position',Position,...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'),...
            'TitleBarPosition',[0 0.61 1 0.38],...
            'String','nigelDash',...
            'PanelColor',obj.Color.fig);
         bar = nigeLab.libs.nigelBar(p,'Tag','TitleBar');
         addButton(bar,'left',LButtons);
         addButton(bar,'right',RButtons);
         obj.Children{5} = bar;
      end
      
      % Initializes the graphics tree widget
      function Tree = buildTree(obj,nigelPanelObj)
         % BUILDTREE  Method to initialize tree
         %
         %  Tree = obj.buildTree(); Automatically puts Tree in "Tree" panel
         %  Tree = obj.buildTree(nigelPanelObj); Puts tree in assigned
         %                                       nigelPanelObj.
         
         if nargin < 2
            nigelPanelObj = obj.TreePanel;
         end
         
         pos = nigelPanelObj.InnerPosition;
         pos(3) = pos(3)/2;
         if ~isempty(obj.Tree)
            if isvalid(obj.Tree)
               delete(obj.Tree);
            end
         end
         Tree = uiw.widget.Tree(...
            'SelectionChangeFcn',@obj.treeSelectionFcn,...
            'Units', 'normalized', ...
            'Position',pos,...
            'FontName','Droid Sans',...
            'FontSize',15,...
            'Tag','Tree',...
            'ForegroundColor',obj.Color.onPanel,...
            'TreePaneBackgroundColor',obj.Color.panel,...
            'SelectionBackgroundColor',obj.Color.enabled_selection,...
            'BackgroundColor',obj.Color.panel,...
            'TreeBackgroundColor',obj.Color.panel,...
            'Units','normalized',...
            'SelectionType','discontiguous');
         
         Tree.Root.Name = obj.Tank.Name;
         obj.Tree = Tree;
         % Add animals to tank Tree
         animalObj = obj.Tank.Children;
         for ii = 1:numel(animalObj)
             obj.addToTree(animalObj(ii));
%             animalNode = uiw.widget.CheckboxTreeNode(...
%                'Name',animalObj(ii).Name,...
%                'Parent',Tree.Root,...
%                'UserData',ii);
%             
%             names = obj.getName(animalObj(ii),'Block');
%             nigeLab.libs.DashBoard.addToNode(animalNode,names);
         end
         
         nigelPanelObj.nestObj(Tree,Tree.Tag);
      end
      
      % LISTENER CALLBACK: Issued as obj.nigelGUI `CloseRequestFcn`
      function deleteDashBoard(obj)
         % DELETEDASHBOARD  CloseRequestFcn assigned property to ensure
         %                  that things get deleted properly.
         %
         %  fig.CloseRequestFcn = @obj.deleteDashBoard;  Just deletes obj
         
         obj.nigelGUI(:) = []; % Remove object so not deleted twice
         delete(obj);
      end
      
      % Delete all current event.listener object handles
      function deleteListeners(obj)
         % DELETELISTENERS  Deletes all current listener handles
         %
         %  obj.deleteListeners();
         
         for lh = obj.Listener
            delete(lh);
         end
         obj.Listener(:) = [];
      end
      
      % Initialize UI context menu for tree click interactions
      function treeContextMenu = initUICMenu(obj)
         % INITUICMENU  Initialize UI Context menu. Adds all 'do' methods
         %              to the context options list.
         %
         %  obj.initUICMenu();
         
         treeContextMenu = uicontextmenu('Parent',obj.nigelGUI);
         obj.Mask_MenuItem = uimenu(treeContextMenu,...
            'Label','Enable',...
            'Checked','on',...
            'Enable','on',...
            'Callback',@obj.uiCMenuClick_toggleIsMasked);
         
         m = methods('nigeLab.Block');
         m = m(startsWith(m,'do'));
         m = setdiff(m,'doMethod');
         for ii=1:numel(m)
            obj.DoMethod_MenuItem(ii) = uimenu(treeContextMenu,...
               'Label',m{ii},...
               'Callback',@obj.uiCMenuClick_doAction);
            if obj.Tank.Pars.doActions.(m{ii}).enabled
               obj.DoMethod_MenuItem(ii).Enable = 'on';
            else
               obj.DoMethod_MenuItem(ii).Enable = 'off';
            end
         end
         obj.DoMethod_MenuItem(1).Separator = 'on';
         obj.Sort_MenuItem = uimenu(treeContextMenu,...
            'Label','Spike Sorting',...
            'Separator','on',...
            'Callback',@(~,~)obj.uiCMenuClick_Sort);
         
         set(obj.Tree,'UIContextMenu',treeContextMenu);
      end
      
      % Adds "recap circles" (rounded rectangles) to "Status" panel child
      function plotRecapBubbles(obj)
         % PLOTRECAPBUBBLES  Plot overview of operations performed within the
         %                  "Stats" panel.
         %
         %   obj --  nigeLab.libs.DashBoard object
         
         if ~isempty(obj.RecapBubble)
            if isvalid(obj.RecapBubble)
               delete(obj.RecapBubble);
               obj.RecapBubble(:) = [];
            end
         end
         S = obj.Status;
         nField = numel(obj.Fields);
         mask = obj.Mask;
         
         h = obj.getHighestLevelNigelObj();
         switch class(S)
            case 'cell'
               
               % If it's a cell, this was a single block
               obj.RecapAxes.YAxis.FontSize = 16;
               obj.RecapAxes.YAxis.TickLabel = {'1'};
               obj.RecapAxes.YAxis.TickValues = 0.5; % In the middle
               for ii=1:nField
                  switch numel(S{ii})
                     case 1 % Case: single large block represents this Field
                        if S{ii}
                           if any(mask)
                              % Complete/Enabled
                              % (mask is all set to false if enable=false)
                              obj.RecapBubble = [obj.RecapBubble, ...
                                 rectangle(obj.RecapAxes,'Position',[ii 0 .97 1],...
                                 'Curvature',[0.3 0.6],...
                                 'FaceColor',obj.Color.enabled_selection,...
                                 'LineWidth',1.5,...
                                 'EdgeColor',[.2 .2 .2])];
                           else
                              % Complete/Not Enabled
                              obj.RecapBubble = [obj.RecapBubble, ...
                                 rectangle(obj.RecapAxes,'Position',[ii 0 .97 1],...
                                 'Curvature',[0.3 0.6],...
                                 'FaceColor',obj.Color.enabled_selection*0.5,...
                                 'LineWidth',1.5,...
                                 'EdgeColor',[.2 .2 .2])];
                           end
                        else
                           if mask
                              % Incomplete/Enabled
                              obj.RecapBubble = [obj.RecapBubble, ...
                                 rectangle(obj.RecapAxes,'Position',[ii 0 1 1],...
                                 'Curvature',[0.3 0.6],...
                                 'FaceColor',obj.Color.button,...
                                 'EdgeColor','none')];
                           else
                              % Incomplete/Not Enabled
                              obj.RecapBubble = [obj.RecapBubble, ...
                                 rectangle(obj.RecapAxes,'Position',[ii 0 1 1],...
                                 'Curvature',[0.3 0.6],...
                                 'FaceColor',obj.Color.button*0.5,...
                                 'EdgeColor','none')];
                           end
                        end
                     otherwise % Case: multiple smaller blocks represent progress
                        for jj = 1:numel(S{ii}) % jj is height (channel)
                           hh = 0.97/numel(S{ii}); % portion of height
                           ht = 1/numel(S{ii}); % total height
                           y = (jj-1)*ht;
                           ft = getFieldType(obj.Tank,obj.Fields{ii});
                           if strcmpi(ft,'Channels')
                              mask = obj.Mask;
                           else
                              % "always good" if non-Channels
                              mask = true(1,numel(S{ii})); 
                           end
                           if S{ii}(jj)
                              if mask(jj)
                                 % Complete/Enabled
                                 obj.RecapBubble = [obj.RecapBubble, ...
                                    rectangle(obj.RecapAxes,'Position',[ii y .97 hh],...
                                    'Curvature',[0.3 0.6],...
                                    'FaceColor',obj.Color.enabled_selection,...
                                    'LineWidth',1.5,...
                                    'EdgeColor',[.2 .2 .2])];
                              else
                                 % Complete/Enabled
                                 obj.RecapBubble = [obj.RecapBubble, ...
                                    rectangle(obj.RecapAxes,'Position',[ii y .97 hh],...
                                    'Curvature',[0.3 0.6],...
                                    'FaceColor',obj.Color.enabled_selection*0.5,...
                                    'LineWidth',1.5,...
                                    'EdgeColor',[.2 .2 .2])];
                              end
                           else
                              if mask(jj)
                                 % Incomplete/Enabled
                                 obj.RecapBubble = [obj.RecapBubble, ...
                                    rectangle(obj.RecapAxes,'Position',[ii y 1 ht],...
                                    'Curvature',[0.3 0.6],...
                                    'FaceColor',obj.Color.button,...
                                    'EdgeColor','none')];
                              else
                                 % Incomplete/Not Enabled
                                 obj.RecapBubble = [obj.RecapBubble, ...
                                    rectangle(obj.RecapAxes,'Position',[ii y 1 ht],...
                                    'Curvature',[0.3 0.6],...
                                    'FaceColor',obj.Color.button*0.5,...
                                    'EdgeColor','none')];
                              end
                           end % if
                        end % jj
                  end % case
               end % ii
               
            case 'logical'
               % Then "channels" are condensed (multi-block, animal, or
               % tank selection)
               N = size(S,1);
               obj.RecapAxes.YAxis.FontSize = max(5,16-N);
               obj.RecapAxes.YAxis.TickLabel = ...
                  cellstr( num2str((1:N)'));
               hOff = (0.985/N)/2; % Average "mid-height"
               obj.RecapAxes.YAxis.TickValues = linspace(hOff,1-hOff,N);
               
               hh = 0.97/N; % Fraction of height
               ht = 1/N; % Total height
               for jj=1:N % jj is height (N is total number of rows always)
                  y = (jj-1)*ht;
                  for ii=1:nField % ii is horizontal (field)
                     
                     if S(jj,ii)
                        if mask(jj)
                           
                           % Complete/Enable
                           obj.RecapBubble = [obj.RecapBubble, ...
                                 rectangle(obj.RecapAxes,'Position',[ii y .97 hh],...
                                 'Curvature',[0.3 0.6],...
                                 'FaceColor',obj.Color.enabled_selection,...
                                 'LineWidth',1.5,...
                                 'EdgeColor',[.2 .2 .2])];
                        else
                           % Complete/Not Enable
                           obj.RecapBubble = [obj.RecapBubble, ...
                                 rectangle(obj.RecapAxes,'Position',[ii y .97 hh],...
                                 'Curvature',[0.3 0.6],...
                                 'FaceColor',obj.Color.enabled_selection*0.5,...
                                 'LineWidth',1.5,...
                                 'EdgeColor',[.2 .2 .2])];
                        end
                     else
                        if mask(jj)
                           % Incomplete/Enabled
                           obj.RecapBubble = [obj.RecapBubble, ...
                              rectangle(obj.RecapAxes,'Position',[ii y 1 ht],...
                              'Curvature',[0.3 0.6],...
                              'FaceColor',obj.Color.button,...
                              'EdgeColor','none')];
                        else
                           % Incomplete/Not Enabled
                           obj.RecapBubble = [obj.RecapBubble, ...
                              rectangle(obj.RecapAxes,'Position',[ii y 1 ht],...
                              'Curvature',[0.3 0.6],...
                              'FaceColor',obj.Color.button*0.5,...
                              'EdgeColor','none')];
                        end
                     end % if
                  end % ii
               end % jj
            case 'double'
               obj.Status = logical(S);
               obj.plotRecapBubbles();
               return;
            otherwise
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Unexpected obj.Status class: %s',class(S));
         end
      end
      
      % Refresh the "Stats" table when a stage is updated
      function refreshStats(obj,~,evt)
         % REFRESHSTATS  Callback to refresh the "stats" table when a stage
         %               is updated.
         %
         %  Example usage:
         %  rm = nigeLab.libs.remoteMonitor;
         %  lh = addlistener(rm,'JobCompleted',@obj.refreshStats);
         %
         %  obj  --  nigeLab.libs.DashBoard object
         %  ~  --  "Source"  (unused; nigeLab.libs.remoteMonitor object)
         %  evt  --  "EventData" associated with the remoteMonitor
         %           'JobCompleted' event, which is a
         %           nigeLab.evt.jobCompleted custom event
         
         idx = evt.BlockSelectionIndex;
         b = obj.Tank.Children(idx(1)).Children(idx(2));
         reload(b);
         b.GUI = obj; % Store association to GUI
         
         h = obj.getHighestLevelNigelObj();
         switch h.Type
            case 'Tank'
               [~,a] = getSelectedItems('obj');
               a_all = h.Children;
               idx = ismember(a_all,a);
               status = getStatus(h,[]);
               obj.Status = status(idx,:);
               obj.Mask = nigeLab.libs.DashBoard.animal2info(h);
            case 'Animal'
               b_all = getSelectedItems('obj');
               idx = find(b==b_all,1,'first');
               obj.Status(idx,:) = getStatus(b,[]);
               obj.Mask = nigeLab.libs.DashBoard.animal2info(h);
            case 'Block' % Make sure current block is in selection
               allAnimalNodes = get(obj.Tree.Root,'Children');
               if iscell(allAnimalNodes)
                  allAnimalNodes = horzcat(allAnimalNodes{:});
               end
               allBlockNodes = get(allAnimalNodes,'Children');
               if iscell(allBlockNodes)
                  allBlockNodes = horzcat(allBlockNodes{:});
               end
               block2update = findobj(allBlockNodes,'UserData',idx);
               selEvt = struct(...
                  'Nodes',cat(1,obj.Tree.SelectedNodes,block2update),...
                  'AddedNodes',block2update);
               obj.treeSelectionFcn([],selEvt);
               if numel(obj.Tree.SelectedNodes)==1
                  obj.Status = cell(1,numel(b.Fields));
                  for i = 1:numel(b.Fields)
                     obj.Status{i} = getStatus(b,b.Fields{i});
                  end
               else
                  idx = find(obj.Tree.SelectedNodes==block2update,1,'first');
                  obj.Status(idx,:) = getStatus(b,[]);
               end
               obj.Mask = nigeLab.libs.DashBoard.block2info(b);
         end
         obj.plotRecapBubbles();
         
      end
      
      % "Reload" the tank (likely multi-animal-related)
      function reloadTank(obj)
         % RELOADTANK  "Reload" the tank object (probably for multi-animals
         %              stuff)
         %
         %  obj.reloadTank();
         
         in = load([obj.Tank.Paths.SaveLoc '_tank.mat'],'tankObj');
         obj.Tank = in.tankObj;
         obj.Tank.IsDashOpen = true;
         pTree = obj.getChild('TreePanel');
         obj.Tree = obj.buildTree(pTree);
      end
      
      % LISTENER CALLBACK: Method to remove an object from the tree
      function Tree = removeFromTree(obj,src,~)
         % REMOVEFROMTREE  Method to remove a deleted nigelObj from tree.
         %
         %  addlistener(nigelObj,...
         %     'ObjectBeingDestroyed',@obj.removeFromTree);
         
         Tree = obj.Tree;
         switch class(src)
            case 'nigeLab.Tank'
               ...
            case 'nigeLab.Animal'
            A=obj.Tank.Children;
            indx = (src == A);
            
            obj2del = obj.Tree.Root.Children(indx);
            if strcmp(obj2del.Name,src.Name) % useless check  but just to be sure
               delete(obj2del);
            else
               nigeLab.utils.cprintf('SystemCommands*',...
                  ['There is mimatch between the Tank loaded ' ...
                  'in nigelDash and the one in memory.\n ' ...
                  'Try to reload it!'],obj.Tank.Verbose);
            end
            
            case 'nigeLab.Block'
               A=obj.Tank.Children;
               indx = cellfun(@(x,idx)[idx*logical(find(src==x)) find(src==x)],{A.Children},num2cell(1:numel(A)),'UniformOutput',false);
               indx = [indx{cellfun(@(x) ~isempty(x),indx)}];
               obj2del = obj.Tree.Root.Children(indx(1)).Children(min(indx(2),end));
               if obj2del.Name == src.Meta.RecID % useless check  but just to be sure
                  delete(obj2del);
               else
                  nigeLab.utils.cprintf('SystemCommands*',...
                  ['There is mimatch between the Tank loaded ' ...
                  'in nigelDash and the one in memory.\n ' ...
                  'Try to reload it!'],obj.Tank.Verbose);
               end
         end
         
         
      end
      
      % Set the "TANK" table -- the display showing processing status
      function setTankTable(obj,~)
         % SETTANKTABLE    Creates "TANK" table for currently-selected
         %                 NODE, indicating the current state of processing
         %                 for a given nigeLab.Animal object.
         %
         %  obj.setTankTable();
         
         tt = obj.Tank.list;
         tCell = table2cell(tt);
         [obj.Mask,obj.Status] = nigeLab.libs.DashBoard.tank2info(obj.Tank);
         StatusIndx = strcmp(tt.Properties.VariableNames,'Status');
         tCell = tCell(:,not(StatusIndx));
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
         dates_idx = strcmp(columnFormatsAndData,'datetime');
         recDates = tCell(:,dates_idx);
         recmonths = cellfun(@(x) month(x,'shortname'),recDates,'UniformOutput',false);
         tmp = cellfun(@(x) {strjoin(unique(x),',')},recmonths,'UniformOutput',false);
         tCell(:,strcmp(columnFormatsAndData,'datetime')) = tmp;
         columnFormatsAndData{strcmp(columnFormatsAndData,'datetime')} = 'cell';
         [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell,'Tank');
         
         w = obj.RecapTable;
         w.ColumnName = tt.Properties.VariableNames(not(StatusIndx)); %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;
         
         plotRecapBubbles(obj);
      end
      
      % Set the "ANIMAL" table -- the display showing processing status
      function setAnimalTable(obj)
         % SETANIMALTABLE  Creates "ANIMAL" table for currently-selected
         %                 NODE, indicating the current state of processing
         %                 for a given nigeLab.Animal object.
         %
         %  obj.setAnimalTable(SelectedItems);
         %
         %  SelectedItems  --  Subset of nodes corresponding to
         %                     currently-selected nigeLab.Animal objects.
         %                    --> This is an indexing array
          [~,A] = obj.getSelectedItems('obj');
         f = A(1).Children(1).Fields;
         tCell = [];
         for ii=1:numel(A)
            tt = A(ii).list;
            tCell = [tCell; table2cell(tt)];
         end
         [obj.Mask,obj.Status] = nigeLab.libs.DashBoard.animal2info(A);
         nonStatusCols = ~strcmp(tt.Properties.VariableNames,'Status');
         tCell = tCell(:,nonStatusCols);
         header = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
         
         % Put "non-Status" elements of list into table format for Recap
         [tCell, header] = uxTableFormat(header(nonStatusCols),tCell,'Animal');
         
         w = obj.RecapTable;
         w.ColumnName = tt.Properties.VariableNames(nonStatusCols);
         w.ColumnFormat = header(:,1);
         w.ColumnFormatData = header(:,2);
         w.Data = tCell;
         N = numel(A);
         plotRecapBubbles(obj);
      end
      
      % Set the "BLOCK" table -- the display showing processing status
      function setBlockTable(obj)
         % SETBLOCKTABLE  Creates the "BLOCK" table for currently-selected
         %                NODE, indicating the current state of processing
         %                for a given nigeLab.Block object.
         %
         %  obj.setBlockTable(SelectedItems);
         %
         %  SelectedItems  --  Subset of nodes corresponding to
         %                     currently-selected nigeLab.Block objects.
         %                    --> This is an indexing matrix, where the
         %                        first column indexes Animals and the
         %                        second column indexes Block.
                     B = obj.getSelectedItems('obj');

         
         if nargin < 2
            B = obj.getSelectedItems('obj');
         else
            B = obj.Tank{SelectedItems(:,1),SelectedItems(:,2)};
         end
         tt = list(B);
         if isempty(tt)
            return;
         end
         tCell = table2cell(tt);
         [obj.Mask,obj.Status] = nigeLab.libs.DashBoard.block2info(B);
         StatusIndx = strcmp(tt.Properties.VariableNames,'Status');
         tCell = tCell(:,not(StatusIndx));
         columnFormatsAndData = cellfun(@(x) class(x), tCell(1,:),'UniformOutput',false);
         [tCell, columnFormatsAndData] = uxTableFormat(columnFormatsAndData(not(StatusIndx)),tCell,'Block');
         
         w = obj.RecapTable;
         w.ColumnName = tt.Properties.VariableNames(not(StatusIndx)); %Just to show the name of each format
         w.ColumnFormat = columnFormatsAndData(:,1);
         w.ColumnFormatData = columnFormatsAndData(:,2);
         w.Data = tCell;
         plotRecapBubbles(obj);
         
      end
      
      % Updates the 'ParametersPanel' panel with current BLOCK parameters
      function setParamsTable(obj,nigelObj)
         % SETBLOCKTABLEPARS  Display the parameters for selected BLOCK(s)
         %
         %  obj.setParamsTable(SelectedItems);
         %
         %  nigelObj  :  Array of currently-selected nigelObj objects

         if isempty(nigelObj)
            return;
         end
         pars = nigelObj(1).Pars;
         Fnames = fieldnames(pars);
         Pan = getChild(obj,'ParametersPanel');
         h =  Pan.Children{1};
         delete(h.Children);
         for ii=1:numel(Fnames)
            ActPars = pars.(Fnames{ii});
            
            dd=struct2cell(ActPars);
            inx=cellfun(@(x) (isnumeric(x) && isscalar(x))||islogical(x)||ischar(x), dd);
            
            ff =fieldnames(ActPars);
            if any(inx)
               tab1 = uitab(h,'Title',Fnames{ii});
               uit = uitable(tab1,'Units','normalized',...
                  'ColumnName',{'--','Parameter','Value','--'},...
                  'Position',[0 0 1 1],...
                  'Data',[cell(sum(inx),1),ff(inx),dd(inx),cell(sum(inx),1)],...
                  'RowName',[],'ColumnWidth',{2,'auto','auto',2});
            end
            pos = getpixelposition(uit);
            width = pos(3) - 4;
            
            uit.ColumnWidth{2} = width*0.2;
            uit.ColumnWidth{3} = width*0.725;
         end
      end
      
      % Toggles the split UI menu button depending on nodes that are click
      function toggleSplitUIMenuEnable(obj)
         % TOGGLESPLITUIMENUENABLE  Toggles the split UI menu depending on
         %                          what is clicked.
         %
         %  Syntax:
         %  addlistener(obj,'SelectionIndex','PostSet',...
         %                 @(~,~)obj.toggleSplitUIMenuEnable);
         
         % If TANK is clicked, disable
         if obj.SelectionIndex(1,2) == 0
            setButton(obj.nigelButtons.Tree,'Split','Enable','off');
            return;
         end
         
         A = obj.Tank.Children;
         if all([A(obj.SelectionIndex(:,2)).MultiAnimals])
            % Only enable the button if ALL are multi-animals
            setButton(obj.nigelButtons.Tree,'Split','Enable','on');
         else
            setButton(obj.nigelButtons.Tree,'Split','Enable','off');
         end
      end
      
      % Function for interfacing with the tree based on current selection
      function treeSelectionFcn(obj,Tree,nodeEvent)
         % TREESELECTIONFCN  Interfaces with the Tree based on the current
         %                   selection. Used as SELECTIONCHANGEDFCN for
         %                   uiw.widget.Tree 'SelectionChanged' event
         %
         %  node = uiw.widget.Tree('Parent',obj.Tree);
         %  node.SelectionChangedFcn = @obj.treeSelectionFcn;
         %
         %  obj  --  nigeLab.libs.DashBoard class object
         %  Tree  --  "Source" object
         %  nodeEvent  --  "EventData" that has field .AddedNodes, which 
         %                 can be used in combination with .UserData to 
         %                 figure out which Animal and Block combinations 
         %                 were selected.
         %
         %     --> nodeEvent.Nodes      :  Currently-selected nodes
         %     --> nodeEvent.AddedNodes :  New nodes
         
         if isempty(Tree)
            Tree = obj.Tree;
         end
         
         NumNewNodes = numel(nodeEvent.AddedNodes);
         % Get UserData indexing all OLD nodes (from previous selection)
         OldNodeType = min( cellfun(@(x) numel(x), ...
            {nodeEvent.Nodes(1:(end-NumNewNodes)).UserData}));
         % Get UserData indexing ALL nodes
         AllNodeType =  cellfun(@(x) numel(x), {nodeEvent.Nodes.UserData});
         
         % Prevent bad concatenation things
         NodesToRemove = not(AllNodeType==OldNodeType);
         Tree.SelectedNodes(NodesToRemove) = [];
         
         SelectedItems = cat(1,Tree.SelectedNodes.UserData);
         obj.SelectionIndex = obj.selectedItems2Index(SelectedItems,obj.Tank);
         [blockObj,animalObj] = obj.getSelectedItems('obj');

         switch  size(SelectedItems,2) % After cat they will have same #
            case 0  % tank
               setTankTable(obj);
               setParamsTable(obj,obj.Tank);
            case 1  % animal
               if numel(animalObj) > 1
                  Tree.SelectedNodes = Tree.SelectedNodes([animalObj.IsMasked]);
                  SelectedItems = cat(1,Tree.SelectedNodes.UserData);
                  animalObj = animalObj([animalObj.IsMasked]);
                  obj.SelectionIndex = obj.selectedItems2Index(SelectedItems,obj.Tank);
               end
               evt = nigeLab.evt.treeSelectionChanged(...
                  obj.Tank,obj.SelectionIndex,'Animal');
               notify(obj,'TreeSelectionChanged',evt);
               setAnimalTable(obj);
               setParamsTable(obj,animalObj);
            case 2  % block
               if numel(blockObj) > 1
                  Tree.SelectedNodes = Tree.SelectedNodes([blockObj.IsMasked]);
                  SelectedItems = cat(1,Tree.SelectedNodes.UserData);
                  blockObj = blockObj([blockObj.IsMasked]);
                  obj.SelectionIndex = obj.selectedItems2Index(SelectedItems,obj.Tank);
               else
                  vec = 1:blockObj.NumChannels;
                  obj.Mask = ismember(vec,blockObj.Mask); 
               end
               evt = nigeLab.evt.treeSelectionChanged(...
                  obj.Tank,obj.SelectionIndex,'Block');
               notify(obj,'TreeSelectionChanged',evt);
               setBlockTable(obj);
               setParamsTable(obj,blockObj);
         end
      end
      
      % LISTENER CALLBACK: Any `doMethod` menu item click
      function uiCMenuClick_doAction(obj,m,~)
         % UICMENUCLICK_DOACTION  Callback for clicks on tree interface
         %                        context menu.
         %
         %  m.Callback = @obj.uiCMenuClick_doAction;
         %
         %  obj  --  nigeLab.libs.DashBoard handle
         %
         %  m  --  "Source" is matlab.ui.container.Menu object handle from
         %           parent matlab.ui.container.ContextMenu
         %           'treeContextMenu' that is a child of obj.nigelGUI
         %
         %  ~  -- "EventData" is currently unused
         %
         %  Key fields of m:
         %  --> 'Label' :: Char array for the current 'do' method to run
         
         % Make a column vector of Animal Indices from any selected
         % (highlighted) animal node
         SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
         
         % Depending on what is in this array, we will run our extraction
         % methods at different levels (e.g. Tank vs Animal vs Block). We
         % can figure out what level was selected based on the number of
         % unique "counts" of UserData
         tankObj = obj.Tank;
         switch  unique(cellfun(@(x) numel(x), ...
               {obj.Tree.SelectedNodes.UserData}))
            case 0  % tank
               [fmt,idt,type] = tankObj.getDescriptiveFormatting();
               nigeLab.utils.cprintf(fmt,...
                  '%s[%s]: Submitting batch job for %s (%s)\n',...
                  idt,upper(m.Label),type,tankObj.Name);
               for ii = 1:numel(tankObj.Children)
               	A = tankObj.Children(ii);
                  if A.IsMasked
                     obj.qOperations(m.Label,A,getKey(A));
                  else
                     [fmt,idt,type] = A.getDescriptiveFormatting();
                     nigeLab.utils.cprintf(fmt,...
                        '%s[%s]: Masked %s (%s) not queued\n',...
                        idt,upper(m.Label),type,A.Name);
                  end
               end
            case 1  % animal
               for ii=1:size(SelectedItems,1)
                  A = tankObj{SelectedItems(ii)};
                  if A.IsMasked
                     obj.qOperations(m.Label,A,SelectedItems(ii));
                  else
                     [fmt,idt,type] = A.getDescriptiveFormatting();
                     nigeLab.utils.cprintf(fmt,...
                        '%s[%s]: Masked %s (%s) not queued\n',...
                        idt,upper(m.Label),type,A.Name);
                  end
               end
            case 2  % block
               for ii = 1:size(SelectedItems,1)
                  B = tankObj{SelectedItems(ii,1),SelectedItems(ii,2)};
                  if B.IsMasked
                     obj.qOperations(m.Label,B,SelectedItems(ii,:));
                  else
                     [fmt,idt,type] = B.getDescriptiveFormatting();
                     nigeLab.utils.cprintf(fmt,...
                        '%s[%s]: Masked %s (%s) not queued\n',...
                        idt,upper(m.Label),type,B.Name);
                  end
               end
         end
      end
      
      % LISTENER CALLBACK: Menu item click "Sort Spikes"
      function uiCMenuClick_Sort(obj,~,~)
         %UICMENUCLICK_SORT  Context-menu callback to run SORT interface
         %
         %  mitem.Callback = @(~,~)obj.uiCMenuClick_Sort;
         %
         %  Runs the spike sorting interface.
         
         blockObj = obj.getSelectedItems('obj');
         Sort(blockObj); % Invoke sorting interface
      end
      
      % LISTENER CALLBACK: Menu item toggle child mask on "Enable" click
      function uiCMenuClick_toggleIsMasked(obj,src,~)
         %UICMENUCLICK_TOGGLECHILDMASK  Toggle Block 'enabled' status
         %
         %  mitem.Callback = @obj.uiCMenuClick_toggleIsMasked;
         %
         %  Set the IsMasked property of Block or Animal to true (enabled) 
         %  or false (disabled) for one or more Block or Animals
         
         nigelObj = obj.getHighestLevelNigelObj();
         evt = nigeLab.evt.treeSelectionChanged(...
            obj.Tank,obj.SelectionIndex,nigelObj(1).Type);
         if strcmp(src.Checked,'on') % If it is enabled, then disable
            set(src,'Checked','off');
            setProp(nigelObj,'IsMasked',false);
            obj.uiCMenu_updateEnable(evt);
         else % otherwise, enable
            set(src,'Checked','on');
            setProp(nigelObj,'IsMasked',true);
            obj.uiCMenu_updateEnable(evt);
         end
      end
      
      % LISTENER CALLBACK: Toggles menu items on or off depend on select
      function uiCMenu_updateEnable(obj,evt)
         %UICMENU_UPDATEENABLE  Toggles 'enabled' for menu items depending
         %                       on the current selection from obj.Tree
         %
         %  addlistener(obj,'TreeSelectionChanged',...
         %     @obj.uiCMenu_updateEnable);
         
         switch evt.SourceType
            case 'Animal'
               noneEnabled = all(~[evt.Animal.IsMasked]);
            case 'Block'
               noneEnabled = all(~[evt.Block.IsMasked]);
            otherwise % e.g. if evt.SourceType was never set (use Block)
               noneEnabled = all(~[evt.Block.IsMasked]);
         end
         
         if noneEnabled
            set(obj.Mask_MenuItem,'Checked','off');
            set(obj.DoMethod_MenuItem,'Enable','off');
            set(obj.Sort_MenuItem,'Enable','off');
            set(obj.Tree,'SelectionBackgroundColor',obj.Color.disabled_selection);
         else
            set(obj.Mask_MenuItem,'Checked','on');
            set(obj.Tree,'SelectionBackgroundColor',obj.Color.enabled_selection);
            for i = 1:numel(obj.DoMethod_MenuItem)
               if obj.Tank.Pars.doActions.(obj.DoMethod_MenuItem(i).Label).enabled
                  obj.DoMethod_MenuItem(i).Enable = 'on';
               end
            end
            if any(~getStatus(evt.Block,{'Spikes'}))
               set(obj.Sort_MenuItem,'Enable','off');
            else
               if numel(evt.Animal) > 1
                  set(obj.Sort_MenuItem,'Enable','off');
               else
                  set(obj.Sort_MenuItem,'Enable','on');
               end
            end
         end
      end
      
   end
   
   % RESTRICTED: nigeLab.libs.splitMultiAnimalsUI
   methods (Access=?nigeLab.libs.splitMultiAnimalsUI)
      % Callback that toggles the split multi animals UI on or off
      function toggleSplitMultiAnimalsUI(obj,mode)
         % TOGGLESPLITMULTIANIMALSUI  Toggle the split multi animals UI on
         %                            or off.
         %
         %  Assignment syntax:
         %  b.ButtonDownFcn = ...
         %     {@(~,~,str) obj.toggleSplitMultiAnimalsUI(str),'start'};
         %
         %  Where 'start' corresponds to a fixed instantiation of "mode"
         %  input, as desired for the application.
         
         switch mode
            case 'start'
               bl = obj.getSelectedItems;
               % if more than one block is selected, select the first
               % one with a multiAnimal
               indx = find([bl.MultiAnimals],1);
               if isempty(indx)
                   errordlg('This is not a multiAnimal!');
                   return;
               end % if ~MultiAnimals
               bl = bl(indx);
               Index = obj.selectedItems2Index(bl,obj.Tank);
               obj.Tree.SelectedNodes = obj.Tree.Root.Children(Index(2)).Children(Index(3));
               
               
               % Ensure that only 1 "child" object is selected at a time
               obj.getChild('TreePanel').getChild('Tree').SelectionType = 'single';
               if isvalid(obj.splitMultiAnimalsUI)
                  obj.splitMultiAnimalsUI.toggleVisibility;
                  return;
               else
                  % 'start' is only entered via button-click
                  toggleSplitMultiAnimalsUI(obj,'init');
                  drawnow;
                  toggleSplitMultiAnimalsUI(obj,'start');
                  return;
               end % if isvalid
               
               % TODO disable nodes without multiAnimal flag!
               %                    [obj.Tree.Root.Children(find([obj.Tank.Children.MultiAnimals])).Enable] = deal('off');
            case 'stop'
               obj.getChild('TreePanel').getChild('Tree').SelectionType = ...
                  'discontiguous';
               % TODO reenable nodes without multiAnimal flag!
               if any([obj.Tank.Children.MultiAnimals])
                  obj.splitMultiAnimalsUI.toggleVisibility;
               else
                  delete( obj.splitMultiAnimalsUI.Fig);
                  delete(obj.splitMultiAnimalsUI);
                  listenerIndex = strcmp({obj.Listener.eventName},'SplitCompleted');
                  delete(obj.Listener(listenerIndex));
                  obj.Listener(listenerIndex) = [];
               end
               
            case 'init'
               % First, make sure the selection is valid
               
               % The multiAnimalsUI must be opened
               SelectedItems = cat(1,obj.Tree.SelectedNodes.UserData);
               % Note that SelectedItems only contains nodes of a specific
               % type, based on exclusion done in `treeSelectionFcn`.
               % Therefore the vertical concatenation above is always valid
               nCol = size(SelectedItems,2);
               switch  nCol
                  case 0  % tank
                     % Cannot be invoked at "TANK" level
                     error(['nigeLab:' mfilename ':badCase'],...
                        'Should not be able to enter split UI from TANK level.');
                  case 1  % animal
                     % Gets all blocks of selected animals
                     B = obj.Tank{SelectedItems(1),:};
                     A = repmat(obj.Tank{SelectedItems(1)},1,numel(B));
                     for i = 1:numel(SelectedItems)
                        b = obj.Tank{SelectedItems(i),:};
                        B = [B, b];
                        A = [A, ...
                           repmat(obj.Tank{SelectedItems(i)},1,numel(b))];
                     end
                     
                  case 2  % block
                     % Get specific subset of block or blocks
                     A = obj.Tank{SelectedItems(:,1)};
                     B = obj.Tank{SelectedItems};
               end % switch nCol
               
               if ~all([A.MultiAnimals])
                  return;
               end
               
               if ~all([B.MultiAnimals])
                  return;
               end
               
               obj.toSplit = struct('Animal',cell(numel(A),1),...
                  'Block',cell(numel(B),1));
               for i = 1:numel(obj.toSplit)
                  obj.toSplit(i).Animal = A(i);
                  obj.toSplit(i).Block = B(i);
               end
               obj.toAdd = struct('Animal',{},'Block',{});
               
               obj.splitMultiAnimalsUI = ...
                  nigeLab.libs.splitMultiAnimalsUI(obj);
               
              obj.Listener = [obj.Listener,...
            addlistener(obj.splitMultiAnimalsUI,'SplitCompleted',...
               @(~,e)obj.addToTree(e.nigelObj))];
         end % switch mode
      end
      
   end
   
   % RESTRICTED: nigeLab.libs.nigelButton
   methods (Access=?nigeLab.libs.nigelButton)
      % LISTENER Callback: Add ANIMAL or BLOCK
      function addNigelObj(obj,~,~)
         %ADDNIGELOBJ  Adds animal or block depending on what is selected
         %
         %  nigelButton(p, position,'Add',@obj.addNigelObj);
         
         nigelObj = getHighestLevelNigelObj(obj);
         try
            switch class(nigelObj)
               case {'nigeLab.Tank','nigeLab.Animal'}
                  %% Add nigeLab.Animal
                  obj.Tank.addChild([]); % Empty -> prompt for selection
               case 'nigeLab.Block'
                  %% Add nigeLab.Block
                  [~,a] = obj.getSelectedItems('obj');
                  if numel(a) > 1
                     [~,idx]=nigeLab.utils.uidropdownbox('Animal Selector',...
                        'Select "parent" Animal',...
                        {a.Name},true);
                     if isnan(idx)
                        error(['nigeLab:' mfilename ':NoSelection'],...
                           'Multiple Animals for adding Block; must choose.');
                     else
                        a = a(idx);
                     end
                  end
                  a.addChild([]); % Empty -> prompt for selection
               otherwise
                  error(['nigeLab:' mfilename ':InvalidNigelObj'],...
                     'Bad nigelObj class name: %s',class(nigelObj));
            end
         catch me
            strInfo = strsplit(me.identifier,':');
            if ~strcmpi(strInfo{end},'NoSelection')
               rethrow(me);
            else
               nigeLab.utils.cprintf('Comments','Selection canceled.\n');
            end
         end
         
      end
      
      % LISTENER Callback: Link to data from button press
      function linkToData(obj,~,~)
         %LINKTODATA  Links the data to existing disk files
         %
         %  nigelButton(p,position,'Link Data',@obj.linkToData);
         
         nigelObj = getHighestLevelNigelObj(obj);
         for i = 1:numel(nigelObj)
            linkToData(nigelObj(i));
         end
      end
      
      % LISTENER Callback: Save data from button press
      function saveData(obj,~,~)
         %SAVEDATA  Saves the data to existing disk files
         %
         %  nigelButton(p,position,'Link Data',@obj.saveData);
         
         nigelObj = getHighestLevelNigelObj(obj);
         for i = 1:numel(nigelObj)
            try
               save(nigelObj(i));
               nigeLab.utils.cprintf('Comments',...
                  'Saved %s successfully!\n',nigelObj(i).Name);
            catch me
               nigeLab.utils.cprintf('Errors',...
                  'Could not save %s.\n',nigelObj(i).Name);
               disp(me);
               for k = 1:numel(me.stack)
                  disp(me.stack(k));
               end
            end
         end
      end
   end

   % STATIC,PROTECTED
   methods (Static,Access=protected)
      % Method to add nodes to a given node
      function addToNode(nodeObj,name)
         % ADDTONODE  Adds nodes based on provided names to another node
         %
         %  nigeLab.libs.DashBoard.addToNode(nodeObj,name);
         %
         %  nodeObj  --  uiw.widget.CheckboxTreeNode handle object (an
         %                 existing node on a graphical tree)
         %
         %  name  --  char array or cell array of char arrays, defining the
         %              names of children nodes to add to nodeObj.
         
         % Check input
         switch class(nodeObj)
            case {'uiw.widget.Tree',...
                  'uiw.widget.CheckboxTree'}
               nodeObj = nodeObj.Root;
               
            case {'uiw.widget.TreeNode',...
                  'uiw.widget.CheckboxTreeNode'}
               % do nothing
               
            otherwise
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Unexpected nodeObj input type: %s',class(nodeObj));
         end
         
         if ~iscell(name)
            name = {name};
         end
         
         % Add each block of a given animal. UserData can be used to index
         % nodes according to some larger hierarchy.
         if isnumeric(nodeObj.UserData)
            parentIndex = nodeObj.UserData;
         else
            parentIndex = [];
         end
         
         for jj=1:numel(name)
            uiw.widget.CheckboxTreeNode(...
               'Name',name{jj},...
               'Parent',nodeObj,...
               'UserData',[parentIndex, jj]);
         end
      end
      
      % Helper method to return name or array of name at a given level
      function name = getName(nigelObj,level)
         % GETNAME  Returns name of a nigelObj based on organization level
         %
         %  name = nigeLab.libs.DashBoard.getName(nigelObj);
         %  name = nigeLab.libs.DashBoard.getName(nigelObj,level);
         %
         %  nigelObj  --  Tank, Animal or Block object
         %  level  --  'Tank', 'Animal' or 'Block' level to return names
         
         if nargin < 2
            level = class(nigelObj(1));
            level = strsplit(level,'.');
            level = level{2};
         end
         
         switch class(nigelObj)
            case 'nigeLab.Block'
               switch lower(level)
                  case 'tank'
                     error(['nigeLab:' mfilename ':badInputType1'],...
                        '%s is a higher level than %s',level,class(nigelObj));
                  case 'animal'
                     error(['nigeLab:' mfilename ':badInputType1'],...
                        '%s is a higher level than %s',level,class(nigelObj));
                  case 'block'
                     Metas = [nigelObj.Meta];
                     if isfield(Metas(1),'AnimalID') && isfield(Metas(1),'RecID')
                        name = {Metas.RecID};
                     else
                        name = {nigelObj.Name};
                     end
               end
            case 'nigeLab.Animal'
               switch lower(level)
                  case 'tank'
                     error(['nigeLab:' mfilename ':badInputType1'],...
                        '%s is a higher level than %s',level,class(nigelObj));
                  case 'animal'
                     name = {nigelObj.Name};
                  case 'block'
                     name = [];
                     for i = 1:numel(nigelObj)
                        b = nigelObj(i).Children;
                        Metas = [b.Meta];
                        if isempty(Metas)
                           name = [name, {b.Name}];
                        else
                           if isfield(Metas(1),'AnimalID') && isfield(Metas(1),'RecID')
                              name = [name, {Metas.RecID}];
                           else
                              name = [name, {b.Name}];
                           end
                        end
                     end
               end
               
            case 'nigeLab.Tank'
               switch lower(level)
                  case 'tank'
                     name = {nigelObj.Name};
                  case 'animal'
                     a = nigelObj.Children;
                     name = {a.name};
                  case 'block'
                     name = [];
                     a = nigelObj.Children;
                     for i = 1:numel(a)
                        b = a(i).Children;
                        Metas = [b.Meta];
                        if isfield(Metas(1),'AnimalID') && isfield(Metas(1),'RecID')
                           name = [name, {Metas.RecID}];
                        else
                           name = [name, {b.Name}];  %#ok<*AGROW>
                        end
                     end
               end
            otherwise
               error(['nigeLab:' mfilename ':badInputType2'],...
                  'Unexpected input class: %s',class(nigelObj));
         end
      end
      
      % Initialize Colors struct with default values
      function col = initColors(figCol,panelCol,onPanelCol,buttonCol,onButtonCol,enabledSelCol,disabledSelCol)
         % INITCOLORS  Initialize colors struct for panel colors
         %
         %  col has three fields: 'fig', 'panel', 'onPanel', 'button', and
         %  'onButton'. They correspond to optional inputs 'figCol',
         %  'panelCol','onPanelCol','buttonCol', and 'onButtonCol'.
         %
         %  col = nigeLab.libs.initColors();
         %  col = nigeLab.libs.initColors(bg,surf,onsurf);
         
         col = struct;
         
         if nargin < 1
            % Nearly black
            col.fig = nigeLab.defaults.nigelColors('background');
            col.onprimary = col.fig;
         else
            col.fig = figCol;
            col.onprimary = figCol;
         end
         
         if nargin < 2
            % Dark gray
            col.panel = nigeLab.defaults.nigelColors('surface');
         else
            col.panel = panelCol;
         end
         
         if nargin < 3
            % White
            col.onPanel = nigeLab.defaults.nigelColors('onsurface');
         else
            col.onPanel = onPanelCol;
         end
         
         if nargin < 4
            % Dark green
            col.button = nigeLab.defaults.nigelColors('button');
            col.incomplete = nigeLab.defaults.nigelColors('secondary');
         else
            col.button = buttonCol;
            col.incomplete = buttonCol;
         end
         
         if nargin < 5
            % White
            col.onButton = nigeLab.defaults.nigelColors('onbutton');
         else
            col.onButton = onButtonCol;
         end
         
         if nargin < 6
            % Primary green
            col.enabled_selection = nigeLab.defaults.nigelColors('goodobj');
            col.primary = nigeLab.defaults.nigelColors('primary');
         else
            col.enabled_selection = enabledSelCol;
            col.primary = enabledSelCol;
         end
         
         if nargin < 7
            % Red
            col.disabled_selection = nigeLab.defaults.nigelColors('badobj');
         else
            col.disabled_selection = disabledSelCol;
         end
      end
      
   end
   
   % STATIC,PUBLIC
   methods (Static,Access=public)
      % Convert animal object or array into corresonding mask & status
      function [mask,status] = animal2info(A)
         %ANIMAL2INFO  Convert animal object array to mask & status
         %
         %  [mask,status] = nigeLab.libs.DashBoard.animal2info(A)
         
         status = [];
         for ii = 1:numel(A)
            status = [status; A(ii).getStatus(A(ii).Fields)];
         end
         if numel(A) > 1
            tmp_mask = [A.IsMasked];
            mask = [];
            for i = 1:numel(A)
               b = A(i).Children;
               mask = [mask, [b.IsMasked] & repmat(tmp_mask(i),1,numel(b))];
            end
         else
            b = [A.Children];
            mask = [b.IsMasked];
         end
      end
      
      % Convert block object or array into corresponding mask & status
      function [mask,status] = block2info(B)
         %BLOCK2INFO  Convert block object array to corresponding mask vec
         %
         %  mask = nigeLab.libs.DashBoard.block2mask(B);
         %
         %  B: nigeLab.Block scalar object or array
         
         if numel(B) == 1
            status = cell(1,numel(B.Fields));
            for i = 1:numel(status)
               status{i} = B.getStatus(B.Fields{i});
            end
            nCh = B.NumChannels;
            vec = 1:nCh;
            if B.IsMasked
               mask = ismember(vec,B.Mask);
            else
               mask = false(size(vec));
            end
         else
            status = getStatus(B,[]);
            nCh = 1;
            mask = [B.IsMasked];
         end
      end
      
      % Convert tank object to corresponding mask & status
      function [mask,status] = tank2info(T)
         %TANK2INFO  Convert tank object array to mask & status
         %
         %  [mask,status] = nigeLab.libs.DashBoard.tank2info(tankObj);
         
         status = T.getStatus(T.Fields);
         a = [T.Children];
         mask = [a.IsMasked];
      end
      
      function obj = empty()
         %EMPTY  Returns empty object
         %
         %  obj = nigeLab.libs.DashBoard.empty();
         
         obj = nigeLab.libs.DashBoard([0 0]);
      end
      
      % Translates "SelectedItems" (nodes UserData) to "selection index"
      function sel = selectedItems2Index(items,tank)
          % SELECTEDITEMS2INDEX  Returns the "indexing" for SelectedItems
          %                       from UserData of nodes on obj.Tree
          %
          %  sel = obj.selectedItems2Index(items);
          %
          %  >> obj.SelectionIndex = selectedItems2Index(items);
          %
          %  sel : [tankIndex animalIndex blockIndex];
          %     --> If tank only, always is [1 0 0];
          %     --> If animal or block, then is [1 iAk iBkj]
          %        Where iAk is the k-th animal's index, and iBkj is the
          %        j-th block of the k-th animal. If only animals are
          %        selected, then it will create rows for all block
          %        "children" of the animal.
          if nargin<2
             tank = []; 
          end
          switch class(items)
              case 'double'
                  % tankObj
                  if isempty(items)
                      sel = [1 0 0];
                      return;
                  end
                  
                  % animalObj
                  if size(items,2) == 1
                      sel = [ones(numel(items),1), items, zeros(numel(items),1)];
                      return;
                  end
                  
                  % blockObj
                  if size(items,2) == 2
                      sel = ones(size(items,1),3);
                      sel(:,[2,3]) = items;
                      return;
                  end
              case 'cell'
                  if isempty(items)
                      sel = [1 0 0];
                      return;
                  elseif size(items,2) == 1
                      %animals
                      an = tank.Children.findByKey(items);
                      sel = [ones(numel(items),1), find(ismember(tank.Children,an))', zeros(numel(items),1)];
                  elseif size(items,2) == 2
                      %                       blocks
                      sel = [ones(size(items,1),1) zeros(size(items,1),2)];
                      an = tank.Children.findByKey(items(:,1));
                      count = 1;
                      anIdx = arrayfun(@(AA) find(AA == tank.Children,1),an);
                      Blocks = {an.Children};
                      blIdx = cellfun(@(BB,bl) find(ismember(BB,bl)), Blocks,...
                          arrayfun(@(x) x, an{items(:,2)},'UniformOutput',false) );
                      sel(:,2) = anIdx;
                      sel(:,3) = blIdx;
                      
%                       for ii=1:numel(an)
%                           anIdx = find(an(ii)== tank.Children,1);
%                           bl = an(ii).Children.findByKey(items(:,2));
%                           nBl = numel(bl);
%                           blIdx = find(ismember(an.Children,bl));
%                           sel(count:(count+nBl-1),2:3)=[ones(numel(nBl),1)*anIdx blIdx(:)];
%                       end
%                       
                  else
                  end
              case 'nigeLab.Tank'
                  sel = [1 0 0];
              case 'nigeLab.Animal'
                  sel = [ones(numel(items),1), find(ismember(tank.Children,items))', zeros(numel(items),1)];
                  
              case 'nigeLab.Block'
                  % cycle through the blocks
                  sel = zeros(numel(items),3);
                  count = 1;
                  An = tank.Children;
                  for aa = 1:numel(An)
                      Bl = An(aa).Children;
                      Idx = find(ismember(Bl,items));
                      numMatches = numel(Idx);
                      sel(count:count+numMatches-1,:) = [ones(numMatches,1) aa*ones(numMatches,1) Idx];
                      count = count+numMatches;
                      items(ismember(items,Bl)) = [];
                      if isempty(items)
                          sel(~any(sel,2),:)=[];
                          return;
                      end
                      
                  end
          end
      end
      
      % Update status
      function updateStatus(bar,str)
         % UPDATESTATUS  Update status string
         %
         %  bar.updateStatus('statusText');
         
         bar.updateStatus(str);
      end
   end
   % % % % % % % % % % END METHODS% % %
end

