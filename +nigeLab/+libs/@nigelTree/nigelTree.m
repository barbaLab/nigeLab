classdef nigelTree < handle & matlab.mixin.SetGet
%NIGELTREE Graphical object for representing NIGELAB file heiararchy
%
%    obj = nigeLab.libs.nigelTree(nigelObj,Panel);
%    obj = nigeLab.libs.nigelTree(__,'Name',value,...);
%
%    NIGELTREE Properties
%       tPanel - Graphics container for "tree" nigeLab.libs.nigelPanel
%       Listener - Array of listener handles (to destroy on `delete`)
%       Tank - nigeLab.Tank object related to this `nigelTree` object
%       Tree - uiw.widget Tree object related to this `nigelTree`
%       SelectionBackgroundColor - Background selection color of `Tree`
%       Color - struct referencing colors of different `Tree` elements
%       SelectionIndex - Indexing of currently-selected items
%       SelectedNodes - uiw.widget.TreeNode objects selected on `Tree`
%       SelectedItems - Array of nigeLab.nigelObj corresponding to nodes
%       SelectedItemsType - `.Type` of `nigelObj` of selected nodes
%       SelectedBlocks - Array of all `nigeLab.Block` objects from selected
%
%   NIGELTREE Events
%       TreeSelectionChanged - Event issued when new tree node is clicked
%
%   NIGELTREE Methods
%       nigelTree - Class constructor
%       delete - Overloaded method to handle object and listener destruction
%       buildTree - Makes the graphical parts of the tree
%       addUIContextMenu - Adds UI context menu to Tree
%       changeTreeSelection - Method invoked to change selection as callback
%       addToTree - Method to add nodes to the tree
%       getNodes - Returns currently-selected nodes

    % % % PROPERTIES% % % % % % % % % % %
    properties
        tPanel  nigeLab.libs.nigelPanel % Graphics container for "tree" panel
        Listener  event.listener        % Array of listener handles
        Tank     nigeLab.Tank           % Tank object
        Tree                            % Tree widget
        SelectionBackgroundColor        % Background selection color property
    end
    
    properties(Access=protected)
        nigelButtons         (1,1) struct = struct('Tree',[],'TitleBar',[])   % Each field is an array of nigelButtons
    end
    
    properties(SetObservable,GetAccess = public,SetAccess = protected)
        Color                struct                 % Struct referencing colors
        SelectionIndex       double = [1 0 0]       % indexing of currently-selected items
        SelectedNodes        uiw.widget.TreeNode    % Node objects of tree
        SelectedItems        nigeLab.nigelObj       % Currently-selected nigel objects (nodes)
        SelectedItemsType    char                   % 'Type' corresponding to objects
        SelectedBlocks       nigeLab.Block          % Array of nigeLab.Block corresponding to obj
        Position             double = [.01 .01 .98 .98]  % Normalized position of Tree
        dragCallback                = @(h,e)pause(0.1);
        dropCallback                = @(h,e)pause(0.1);
    end
    % % % % % % % % % % END PROPERTIES %
    
    % % % EVENTS % % % % % % % % % % % %
    % PUBLIC
    events %(ListenAccess=public,NotifyAccess=public)
        TreeSelectionChanged  % Event issued when new node on Tree is clicked
        % --> Has `nigeLab.evt.treeSelectionChanged` event.EventData
    end
    % % % % % % % % % % END EVENTS % % %
    
    % % % METHODS% % % % % % % % % % % %
    methods
        % NIGELTREE Class constructor
        function obj = nigelTree(nigelObj,Panel, varargin)
           %NIGELTREE Graphical object for representing NIGELAB file heiararchy
           %
           %    obj = nigeLab.libs.nigelTree(nigelObj,Panel);
           %    obj = nigeLab.libs.nigelTree(__,'Name',value,...);
           %
           %    -- Inputs --
           %      nigelObj  :   nigeLab.nigelObj
           %       Panel    :   nigeLab.libs.nigelPanel
           %      varargin  :   (Optional) <'Name',value> syntax for setting
           %                        property values in constructor
           %
           %        ## Properties ##
           %            'Parent'   nigelPanel
           %            'Color'    colorStrct
           %            'Position' [1 x 4] double; normalized [0 1] graphical position
           %
           %    -- Output --
           %       obj      :   nigeLab.libs.nigelTree object or array
           %        --> If no input is provided, this is returned as an empty object
           %        --> If input is a numeric scalar, returns an array of NigelTree obj
            
            if nargin < 1
                obj = nigeLab.libs.NigelTree.empty(); % Empty NigelTree
                return; % Should always be called from tankObj anyways
            elseif isnumeric(nigelObj)
                dims = nigelObj;
                if numel(dims) == 1
                    dims = [0,dims];
                end
                obj = repmat(obj,dims);
                return;
            end
            
            obj.tPanel = Panel;
            
            % defaults prop assignement
            obj.Color = nigeLab.libs.nigelTree.initColors();
            obj.Position = obj.tPanel.InnerPosition;
            for jj=1:2:nargin-2
               if isprop(obj,varargin{jj}) 
                   obj.(varargin{jj}) = varargin{jj+1};
               end
            end
            Type = unique({nigelObj.Type});
            switch Type{:} 
               case 'Tank'
                  obj.Tank = nigelObj;
                  animalObjs = obj.Tank.Children;
               case 'Animal'
                  if isempty(nigelObj.Parent)
                  else
                     obj.Tank = nigelObj.Parent;
                  end
                  animalObjs = nigelObj;
            end
            obj.Tree = buildTree(obj,animalObjs);
            
            % Initialize the current selected node as "root"
            obj.Tree.SelectedNodes = obj.Tree.Root;
            Nodes.Nodes = obj.Tree.Root;
            Nodes.AddedNodes = obj.Tree.Root;
            treeSelectionFcn(obj,obj.Tree,Nodes)
            buildJavaObjs(obj);
            
            % Add event listeners
            obj.addAllListeners();
            
            % Add drag and drop
            obj.Tree.NodeDraggedCallback = @(h,e)obj.dragCallback(h,e);
            obj.Tree.NodeDroppedCallback = @(h,e)obj.dropCallback(h,e);
        end
        
        
    end
    
    methods
        function delete(obj)
            % Delete all listener handles
            obj.deleteListeners();
            
            if ~isempty(obj.Tank)
                if isvalid(obj.Tank)
                    set(obj.Tank,'GUI',nigeLab.libs.DashBoard.empty);
                end
            end
        end
    end
    
    
    methods
        % Initializes the graphics tree widget
        function Tree = buildTree(obj,animalObj)
            % BUILDTREE  Method to initialize tree
            %
            %  Tree = obj.buildTree(); Automatically puts Tree in "Tree" panel
            %  Tree = obj.buildTree(nigelPanelObj); Puts tree in assigned
            %                                       nigelPanelObj.
            
            pos = obj.Position;
            nigelPanelObj = obj.tPanel;
            
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
            
            if isempty(obj.Tank)
                Tree.Root.Name = '';
            else
                Tree.Root.Name = obj.Tank.Name;
            end
            obj.Tank.TreeNodeContainer = Tree.Root;
            obj.Tree = Tree;
            
                        
            % Add animals to tank Tree
            for ii = 1:numel(animalObj)
                obj.addToTree(animalObj(ii));
            end
            
            nigelPanelObj.nestObj(Tree,Tree.Tag);
        end
        
        % add Tree UI context menu        
        function addUIContextMenu(obj,menu)
            set(obj.Tree,'UIContextMenu',menu);
        end
        
        function changeTreeSelection(obj,ind)
            switch class(ind)
                case 'double'
                    switch numel(ind)
                        case 0
                            newNode =  obj.Tree.Root;
                        case 1
                            newNode =  obj.Tree.Children(ind(1));
                        case 2
                            newNode =  obj.Tree.Children(ind(1)).Children(ind(2));
                    end
                case  'uiw.widget.CheckboxTreeNode'
                    newNode = ind;
            end
                            %     --> nodeEvent.Nodes      :  Currently-selected nodes
            %     --> nodeEvent.AddedNodes :  New nodes
            obj.Tree.SelectedNodes = newNode(1);
            nodeEvent.Nodes = newNode(1);
            nodeEvent.AddedNodes = newNode(2:end);
            treeSelectionFcn(obj,obj.Tree,nodeEvent);
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
                AnKeys = getKey(nigelObj);
                if ~iscell(AnKeys)
                    AnKeys = {AnKeys};
                end
                UAnKeys = unique(AnKeys);
                for ii = 1:numel(UAnKeys)
                    indx = strcmp([obj.Tree.Root.Children.UserData],UAnKeys{ii});
                    thisAnimal = findByKey(nigelObj,UAnKeys(ii));
                    if ~any(indx)
                        AnNode = uiw.widget.CheckboxTreeNode(...
                            'Name',thisAnimal.Meta.AnimalID,...
                            'Parent',obj.Tree.Root);
                        set(AnNode,'UserData',{thisAnimal.getKey});
                        thisAnimal.TreeNodeContainer = [thisAnimal.TreeNodeContainer, AnNode];
                        %                         obj.Listener = [obj.Listener, ...
                        %                             addlistener(nigelObj(ii),'ObjectBeingDestroyed',...
                        %                             @obj.removeFromTree)];
                    end
                    obj.Listener = [obj.Listener,...
                        addlistener(thisAnimal,'ChildAdded',...
                        @(~,evt)obj.addToTree(evt.nigelObj))];
                    addToTree(obj,thisAnimal.Children,false);
                end
                case 'nigeLab.Block'
                    AnKeys = getKey([nigelObj.Parent]);
                    if ~iscell(AnKeys)
                        AnKeys = {AnKeys};
                    end
                    AllBlocksKeys = nigelObj.getKey;
                    if ~iscell(AllBlocksKeys),AllBlocksKeys={AllBlocksKeys};end
                    UAnKeys = unique(AnKeys);
                    for ii =1:numel(UAnKeys)
                        AnIndx = strcmp([obj.Tree.Root.Children.UserData],UAnKeys(ii));
                        if ~any(AnIndx)
                           % if no animal nodes  are found add the whole
                           % animal
                           Animals = unique([nigelObj.Parent]);
                           addToTree(obj,Animals.findByKey(UAnKeys(ii)),false);
                           return;
                        end
                        AnNode = obj.Tree.Root.Children(AnIndx);
                        BlocksNodesKeys = [AnNode.Children.UserData];
                        
                        % find in the nigelObj array the blocks to add to
                        % this node
                        ThisAnBlocksIdx = strcmp(AnKeys,UAnKeys(ii));
                        
                        % Check for clones. We don't want to add two times
                        % the same block
                        ThisAnBlocksKeys = AllBlocksKeys(ThisAnBlocksIdx);
                        BlocksToAddKeys = setdiff(ThisAnBlocksKeys,BlocksNodesKeys);
                        
                        % finally restrict nigelObj to the blocks to add
                        BlocksToAdd = nigelObj(ismember(AllBlocksKeys,BlocksToAddKeys));
                        
                        for jj=1:numel(BlocksToAdd)
                            thisBlock = BlocksToAdd(jj);
                            BlNode = uiw.widget.CheckboxTreeNode('Name',thisBlock.Meta.BlockID,'Parent',AnNode);
                            set(BlNode,'UserData',{UAnKeys{ii},thisBlock.getKey});
                            thisBlock.TreeNodeContainer = [thisBlock.TreeNodeContainer, BlNode];
%                             obj.Listener = [obj.Listener, ...
%                                 addlistener(thisBlock,'ObjectBeingDestroyed',...
%                                 @obj.removeFromTree)];
                        end
                        
                    end
                otherwise
                    error(['nigeLab:' mfilename ':unrecognizedClass'],...
                        'Unexpected class: %s',class(nigelObj));
            end
            
        end
        
        % function to get tree nodes from keys
        function nodes = getNodes(obj,key)
            % GETNODES returns treenodes based on UserData matching
            % input: key. Keypair for UserData matching. It has to match
            % UserData format ie
            %                                 for blocks  {AnimalKey,BlockKey}
            %                                 for animals {AnimalKey}
            
            %gather all the neeeded nodes
            allAnimalNodes = get(obj.Tree.Root,'Children');
            if iscell(allAnimalNodes)
                allAnimalNodes = horzcat(allAnimalNodes{:});
            end % fi 
            
            switch size(key,2)
                case 1 % animal
                    nodes = array(@(k) findobj(allAnimalNodes,'UserData',k),key,'UniformOutput',false);
                    nodes = cat(1,nodes{:});
                    
                case 2 % blocks
                    allBlockNodes = get(allAnimalNodes,'Children');
                    if iscell(allBlockNodes)
                        allBlockNodes = horzcat(allBlockNodes{:});
                    end %fi
                    nodes = arrayfun(@(k1,k2) findobj(allBlockNodes,'UserData',[k1,k2]),key(:,1),key(:,2),'UniformOutput',false);
                    nodes = cat(1,nodes{:});
                otherwise
                    if size(key,1) == 1 || size(key,1) == 2
                        key = key';
                        nodes = getNodes(obj,key);
                    else
                        error('nigeLab:badInputArgument','Bad input argument''s size.')
                    end
            end % switch

            
        end % function
    end
    
    methods         
        function set.SelectedItems(obj,value)
            obj.SelectedItems = value;
            switch class(value)
                
                case 'nigeLab.Tank'
                    sel = [1 0 0];
                case 'nigeLab.Animal'
                    sel = [ones(numel(value),1), find(ismember(obj.Tank.Children,value,'legacy'))', zeros(numel(value),1)];
                    
                case 'nigeLab.Block'
                    % cycle through the blocks
                    sel = zeros(numel(value),3);
                    count = 1;
                    An = obj.Tank.Children;
                    aa=1;
                    while ~isempty(value)
                        Bl = An(aa).Children;
                        Idx = find(ismember(Bl,value,'legacy'));
                        numMatches = numel(Idx);
                        sel(count:count+numMatches-1,:) = [ones(numMatches,1) aa*ones(numMatches,1) Idx(:)];
                        count = count+numMatches;
                        aa = aa+1;
                        value(ismember(value,Bl,'legacy')) = [];
                        if isempty(value)
                            sel(~any(sel,2),:)=[];
                            
                        end
                        
                    end
            end
            
            set(obj,'SelectionIndex', sel);
            type = unique({ obj.SelectedItems.Type});
            set(obj,'SelectedItemsType',type{:});
        end
               
        
        function set.SelectionBackgroundColor(obj,value)
            obj.SelectionBackgroundColor = value;
            set(obj.Tree,'SelectionBackgroundColor',value);
        end
    end
    
    
    methods (Access=protected)
        
        % Return the current item selection
        function nigelObj = getSelectedItems(obj,mode)
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
                    nigelObj = [];
                    
                    % SelectedItems will always have consistent # columns, since
                    % "unlike" nodes are de-selected during treeSelectionFcn
                    Items = cat(1,obj.Tree.SelectedNodes.UserData);
                    nCol = size(Items,2);
                    switch  nCol
                        case 0  % tank
                            nigelObj = obj.Tank;
                            
                        case 1  % animal
                            nigelObj = obj.Tank.Children.findByKey(Items);
                            
                        case 2  % block
                            animalIdx = unique(Items(:,1));
                            animal = obj.Tank.Children.findByKey(animalIdx);
                            nigelObj = findByKey([animal.Children],Items(:,2));
                    end
                case 'index'
                    % TODO
                    Items = cat(1,obj.Tree.SelectedNodes.UserData);
                    
                case 'name'
                    % TODO
                otherwise
                    error(['nigeLab:' mfilename ':badInputType3'],...
                        ['Unexpected "mode" value: ''%s''\n' ...
                        '(should be ''obj'', ''index'', or ''name'')'],mode);
            end % case
        end % getSelectedItems
        
        % Return all the current selected blocks
        function nigelObj = getSelectedBlocks(obj,mode)
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
                    nigelObj = [];
                    
                    % SelectedItems will always have consistent # columns, since
                    % "unlike" nodes are de-selected during treeSelectionFcn
                    Items = cat(1,obj.Tree.SelectedNodes.UserData);
                    nCol = size(Items,2);
                    switch  nCol
                        case 0  % tank                            
                            nigelObj = obj.Tank{:,:};
                            
                        case 1  % animal
                            animal = obj.Tank.Children.findByKey(Items);
                            nigelObj = [animal.Children];
                            
                        case 2  % block
                            animalIdx = unique(Items(:,1));
                            animal = obj.Tank.Children.findByKey(animalIdx);
                            nigelObj = findByKey([animal.Children],Items(:,2));
                    end
                case 'index'
                    ...%TODO
                    
                case 'name'
                    ...%TODO
                otherwise
                    error(['nigeLab:' mfilename ':badInputType3'],...
                        ['Unexpected "mode" value: ''%s''\n' ...
                        '(should be ''obj'', ''index'', or ''name'')'],mode);
            end % case
        end % getSelectedBlocks
        
        function addAllListeners(obj)
            % ADDALLLISTENERS  Add all the listeners and contain them in a
            %                  handle array that can be deleted on object
            %                  destruction.
            
            % Add listeners for 'ChildAdded'
            
            
            obj.Listener = [obj.Listener,...
                         addlistener(obj.Tank,'ChildAdded',...
                            @(~,evt)obj.addToTree(evt.nigelObj))];
            
%             for a = obj.Tank.Children
%                 obj.Listener = [obj.Listener,...
%                     addlistener(a,'ChildAdded',...
%                     @(~,evt)obj.addToTree(evt.nigelObj))];
%             end
            
            
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
                
                obj2del = findobj(obj.Tree.Root.Children,'UserData',{src.getKey});
                if ~isempty(obj2del) % useless check  but just to be sure
                    delete(obj2del);
                else
                    nigeLab.utils.cprintf('SystemCommands*',...
                        ['There is mimatch between the Tank loaded ' ...
                        'in nigelDash and the one in memory.\n ' ...
                        'Try to reload it!'],obj.Tank.Verbose);
                end
                
                case 'nigeLab.Block'
                    A=obj.Tank.Children;
                    BKey = src.getKey;
                    AnIdx = arrayfun(@(A) ~isempty(A{BKey}),A,'UniformOutput',true);
                    AKey = A(AnIdx).getKey;
                    AnNodeIdx = strcmp([obj.Tree.Root.Children.UserData],AKey);
                    if sum(AnNodeIdx)>1
                        nigeLab.utils.cprintf('SystemCommands*',...
                            ['Something is wrong with the Tank loaded ' ...
                            'in nigelDash.\n ' ...
                            'Try to reopen the dashboad!'],obj.Tank.Verbose);
                        return;
                    end
                    blocksKeys = cat(1,obj.Tree.Root.Children(AnNodeIdx).Children.UserData);
                    if isempty(blocksKeys)
                        return;
                    end
                    BlNodeIdx = strcmp(blocksKeys,{BKey});
                    BlNodeIdx = BlNodeIdx(:,2);
                    obj2del = obj.Tree.Root.Children(AnNodeIdx).Children(BlNodeIdx);
                    if ~isempty(obj2del) % useless check  but just to be sure
                        delete(obj2del);
                    else
                        nigeLab.utils.cprintf('SystemCommands*',...
                            ['There is mimatch between the Tank loaded ' ...
                            'in nigelDash and the one in memory.\n ' ...
                            'Try to reload it!'],obj.Tank.Verbose);
                    end
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
            
            nigelObj = obj.getSelectedItems;
            obj.SelectedItems = nigelObj;
            obj.SelectedBlocks = obj.getSelectedBlocks;
            obj.SelectedNodes = obj.Tree.SelectedNodes;
                        
            switch  class(nigelObj) % After cat they will have same #
                case 'nigeLab.Tank'  % tank
                    Tree.SelectedNodes = Tree.SelectedNodes([nigelObj.IsMasked]);
                        evt = nigeLab.evt.treeSelectionChanged(...
                        obj.Tank,obj.SelectionIndex,'Tank');
                    notify(obj,'TreeSelectionChanged',evt);
                case 'nigeLab.Animal'  % animal
                    if numel(nigelObj) > 1
                        Tree.SelectedNodes = Tree.SelectedNodes([nigelObj.IsMasked]);
                        evt = nigeLab.evt.treeSelectionChanged(...
                        obj.Tank,obj.SelectionIndex,'Animal');
                    notify(obj,'TreeSelectionChanged',evt);
                    end
                    evt = nigeLab.evt.treeSelectionChanged(...
                        obj.Tank,obj.SelectionIndex,'Animal');
                    notify(obj,'TreeSelectionChanged',evt);
                case 'nigeLab.Block'  % block
                    if numel(nigelObj) > 1
                        Tree.SelectedNodes = Tree.SelectedNodes([nigelObj.IsMasked]);
                    end
                    evt = nigeLab.evt.treeSelectionChanged(...
                        obj.Tank,obj.SelectionIndex,'Block');
                    
                    notify(obj,'TreeSelectionChanged',evt);
                    
            end
        end
        
               
    end
    
    methods (Static,Access=public)
        function obj = empty()
           obj = nigeLab.libs.nigelTree([0 0]);
        end
    end
    
    methods (Static,Access=protected)
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
    
end
