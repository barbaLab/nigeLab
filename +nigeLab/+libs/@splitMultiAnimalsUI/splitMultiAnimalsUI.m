classdef splitMultiAnimalsUI < handle
% SPLITMULTIANIMALSUI  Class constructor for UI to split
%                       multi-animals recording blocks.
%
%  obj.splitMultiAnimalsUI(DashObj);



   properties(SetObservable,GetAccess=public,SetAccess=protected)
       Fig             matlab.ui.Figure     % matlab.ui.Figure handle to user interface figure
       Color                struct               % Struct referencing colors
   end
   
   properties (Access = private,SetObservable,AbortSet)
      allBlocks                 nigeLab.Block
      nigelObj                  nigeLab.nigelObj
      tankObj                   nigeLab.Tank    % original Tank, ie where to add back the splitted animals
      multiTankObj              nigeLab.Tank    % reduced Tank, only conataining the multi objects
      SplittedAnimals
      SplittedBlocks
   end
   
   properties (Access = private)
      toSplit                   nigeLab.Block % object 
      reviedTrees
      thisTree

      AcceptBtn                  matlab.ui.control.UIControl % pushbutton
      ApplyToAllBtn              matlab.ui.control.UIControl % pushbutton
      Tree                       % uiw.widget.Tree
      panel                      nigeLab.libs.nigelPanel
      btnPanel                   matlab.ui.container.Panel
      treePanel                  nigeLab.libs.nigelPanel
      selectionTree
      
      PropListener                  event.listener  % Array of listeners
      SelectionChangedListener      event.listener
      SplitCompletedListener        event.listener
   end
   
   events
      SplitCompleted   % Fired once the "splitting" procedure has been finished
   end
   
   methods (Access = public)
      % Class constructor for split multi animals UI
      function obj = splitMultiAnimalsUI(nigelObj)
         % SPLITMULTIANIMALSUI  Class constructor for UI to split
         %                       multi-animals recording blocks.
         %
         %  obj.splitMultiAnimalsUI(DashObj,animalObj,blockObj);
         %
         %  DashObj  --  nigeLab.libs.DashBoard
         
         % DashObj has special restricted properties: 
         %  --> A_split  :: Animals to split
         %  --> B_split  :: Blocks to split
         if nargin < 1
            obj = nigeLab.libs.splitMultiAnimalsUI.empty([0,0]);
            return;
         elseif isnumeric(nigelObj)
            n = nigelObj;
            if numel(n) < 2
               n = [zeros(1,2-numel(n)),n];
            else
               n = [0, max(n)];
            end
            obj = repmat(obj,n);
            return;
         end
                
         % Build user interface figure and panels
         obj.Fig = obj.buildGUI();
         
         % Create buttons
         obj.addButtons();

         % build the selectionTree. If only a block is passed this is
         % unnecessary
         Type = unique({nigelObj.Type});
         switch Type{:}
             case 'Tank'
                 obj.tankObj = nigelObj;
                 obj.multiTankObj = copy(nigelObj);
                 idx = [nigelObj.Children.MultiAnimals];
                 obj.nigelObj = nigelObj.Children(idx);
                 obj.multiTankObj.Children = obj.nigelObj;
                 obj.allBlocks = obj.multiTankObj{:,:};
             case 'Animal'                 
                 if ~isempty(nigelObj(1).Parent)
                     obj.tankObj = nigelObj(1).Parent;
                     obj.multiTankObj = copy(obj.tankObj);
                 end
                 obj.nigelObj = nigelObj;
                 obj.multiTankObj.Children = obj.nigelObj;
                 obj.allBlocks = obj.multiTankObj{:,:};

             case 'Block'
                 obj.nigelObj = nigelObj;
                 ...
             otherwise
         end
         
         obj.initSplittedObjects();
         for c=obj.nigelObj
             addlistener(c,'ObjectBeingDestroyed',@(src,~)obj.assignNULL(obj.multiTankObj,src));
         end
         obj.selectionTree = nigeLab.libs.nigelTree(obj.multiTankObj,obj.treePanel);
         obj.selectionTree.Tree.SelectionType = 'single';
         idx = ... find all listeners for ChildAdded in the Tank
            strcmp({obj.selectionTree.Listener.EventName},'ChildAdded')...
            & ...
            strcmp(...
                    cellfun(@(source) class(source),...
                        [obj.selectionTree.Listener.Source],...
                        'UniformOutput',false), ...
                    'nigeLab.Tank');
                obj.selectionTree.Listener(idx).Enabled = false;
         % Assign the close request function since init has worked
         obj.Fig.CloseRequestFcn = ...
            @(~,~)toggleVisibility(obj,'off');
         
                 
         % define useful event listeners
         obj.addListeners();
         
        
      end % function splitMultiAnimalsUI
      
      % Overload to ensure figure destruction and listener deletion
      function delete(obj)
         % DELETE  Overloaded delete to destroy listeners and figure
         %
         %  delete(obj); Additional things to clean up when this is called
         
         % Ensure that associated listener is deleted
         if ~isempty(obj.SelectionChangedListener)
            if isvalid(obj.SelectionChangedListener)
               delete(obj.SelectionChangedListener)
            end
         end
         
         % Ensure that property change listener array elements are deleted
         if ~isempty(obj.PropListener)
            for lh = obj.PropListener
               if isvalid(lh)
                  delete(lh);
               end
            end
         end
         
         % Ensure that associated graphics are deleted
         if ~isempty(obj.Fig)
            if isvalid(obj.Fig)
               delete(obj.Fig)
            end
         end
      end
      
      % Toggles visibility of the user interface
      function toggleVisibility(obj,vis_mode)
         % TOGGLEVISIBILITY  Toggles visibility of the user interface.
         %
         %  obj.toggleVisibility();   Switches from 'on' to 'off' or vis
         %                            versa, always switching from the
         %                            previous state.
         %
         %  obj.toggleVisibility(vis_mode);   Forces to one state
         
         if nargin < 2
            switch obj.Fig.Visible         
         % Set visibility of figure
               case 'on'
                  vis_mode = 'off';
                  figAlwaysOnTop(obj,false);
                  obj.Fig.Visible = vis_mode;
               case 'off'
                  vis_mode = 'on';
                  obj.Fig.Visible = vis_mode;
                  drawnow;
                  figAlwaysOnTop(obj,true);
            end
         else
             switch vis_mode  
         % Set visibility of figure
               case 'off'
                  figAlwaysOnTop(obj,false);
                  obj.Fig.Visible = vis_mode;
               case 'on'
                  obj.Fig.Visible = vis_mode;
                  drawnow;
                  figAlwaysOnTop(obj,true);
            end
         end

         
         % Listener only executes callback if figure is visible
         obj.SelectionChangedListener.Enabled = strcmp(vis_mode,'on');
         if ~obj.SelectionChangedListener.Enabled
            return;
         end

         rotateTreeVisibility(obj);
         
               
      end % function toggleVisibility
      
   end % methods public
   
   methods (Access = private)
       function figAlwaysOnTop(obj,mode)
           if nargin < 2
               mode = false;
           end
           % toggle figure alway on top. Has to be changed before
         % the visibility property
         %                     drawnow;
         warningTag = 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame';
         warning('off',warningTag);
         
         jFrame = get(handle(obj.Fig),'JavaFrame');
         jFrame_fHGxClient = jFrame.fHG2Client;
         jFrame_fHGxClientW=jFrame_fHGxClient.getWindow;
         tt = tic;
         while(isempty(jFrame_fHGxClientW))
             if toc > 5
                 % this is not critical, no need to lock everythong here if
                 % it's not working
                 warning('on',warningTag);
                 return;
             end
            jFrame_fHGxClientW=jFrame_fHGxClient.getWindow;
         end

         jFrame_fHGxClientW.setAlwaysOnTop(mode);
         warning('on',warningTag);
       end
       
      % Add buttons to interface
      function addButtons(obj)
         % ADDBUTTONS  Add buttons to user interface
         %
         %  obj.addButtons();   Should be called once in constructor
         
         % creates buttons
         UserdataStruct = struct();
         UserdataStruct.yesToAll = false;
         UserdataStruct.reviewedBlocks = false;
         obj.AcceptBtn = uicontrol('Style','pushbutton',...
            'Position',[450 5 50 20],...
            'Callback',{@(h,e) obj.ApplyCallback(h,e)},...
            'String','Accept','Enable','off',...
            'Parent',obj.btnPanel,...
            'BackgroundColor',nigeLab.defaults.nigelColors('primary'),...
            'ForegroundColor',nigeLab.defaults.nigelColors('onprimary'),...
            'UserData',UserdataStruct);
         
         obj.ApplyToAllBtn = uicontrol('Style','pushbutton',...
            'Position',[380 5 50 20],...
            'Callback',{@(h,e,x) obj.copyChangesToAll(h,e)},...
            'String','Copy to all','Enable','off',...
            'Parent',obj.btnPanel,...
            'BackgroundColor',nigeLab.defaults.nigelColors('primary'),...
            'ForegroundColor',nigeLab.defaults.nigelColors('onprimary'));
      end
      
      % Add listeners to interface
      function addListeners(obj)
         % ADDLISTENERS  Add listeners to interface
         %
         %  obj.addListeners();  Should be called once in constructor
         
         obj.SelectionChangedListener = addlistener(obj.selectionTree,...
            'TreeSelectionChanged',...
            @(~,~)obj.rotateTreeVisibility);

%         obj.SplitCompletedListener = addlistener(obj,'SplitCompleted',...
%             @(~,~)obj.deleteAnimalWhenEmpty());
      end
      
      % LISTENER CALLBACK: Initialize the splitting process
      function initSplittedObjects(obj)
         % BEGINSPLIT  Initialize the splitting process
         %
         %  obj.beginSplit(); 
         %
         %  Syntax:
         %  obj.PropListener = addlistener(obj,'animalObj','PostSet',...
         %                       @(~,~)obj.beginSplit);
         obj.nigelObj.splitMultiAnimals('init');
         
         % Store Splitted Animals and block in the UI properties to assign
         % them correctly later.
         obj.SplittedAnimals = [obj.nigelObj.MultiAnimalsLinkedAnimals];
         obj.SplittedBlocks = [obj.SplittedAnimals.Children];
%          [obj.SplittedAnimals.Children] = deal([]);
         
         % TODO case where only blockobj is initialized
         obj.Tree = obj.buildBlockTrees(obj.nigelObj);
%          obj.AcceptBtn.UserData.reviewedBlocks = false(1,...
%             numel(obj.animalObj.Children));
         populateTree(obj.Tree);

      end
      
      % Build trees for individual block properties to "drag" to each other
      function Tree = buildBlockTrees(obj,nigelObj)
          % BUILDBLOCKTREES  Builds trees for individual block properties to
          %                    "drag" to each other.
          %
          %  Tree = obj.buildBlockTrees();
          Type = unique({nigelObj.Type});
          switch Type{:}
              case 'Animal'
                  if isscalar(nigelObj)
                      % crete tree matrix and incapsulate it in a cell
                      Tree = {buildBlockTrees(obj,nigelObj.Children)};
                      return;
                  else
                      % recursively call the function on all elements
                      Tree = [buildBlockTrees(obj,nigelObj(1:end-1)),...
                          buildBlockTrees(obj,nigelObj(end))];
                      return;
                  end
              case 'Block'
                  if ~isscalar(nigelObj)
                      % the tree matrix has size nBlocks x nMultiAnimals
                      Tree = [buildBlockTrees(obj,nigelObj(1:end-1));...
                          buildBlockTrees(obj,nigelObj(end))];
                      return;
                  elseif ~isempty(nigelObj.MultiAnimalsLinkedBlocks)
                      
                      Tree = arrayfun(@(x)buildBlockTrees(obj,x),nigelObj.MultiAnimalsLinkedBlocks,'UniformOutput',false);
                      Tree = [Tree{:}];
                      return;
                  else
                      % finally build a single tree for each splittedBlock
                      Tree = uiw.widget.Tree(...
                          'Label', nigelObj.Parent.Name, ...
                          'LabelLocation','top',...
                          'LabelHeight',18,...
                          'Units', 'normalized', ...
                          'SelectionType','discontiguous',...
                          'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'),...
                          'LabelForegroundColor',nigeLab.defaults.nigelColors('onsfc'),...
                          'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                          'TreePaneBackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                          'TreeBackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                          'SelectionBackgroundColor',nigeLab.defaults.nigelColors('primary'),...
                          'SelectionForegroundColor',nigeLab.defaults.nigelColors('onprimary'));
                      
                      Tree.UserData = nigelObj;
                      obj.panel.nestObj(Tree);
                      Tree.Visible = 'off';
                      Tree.Units = 'normalized';
                      Tree.RootVisible = false;
                      Tree.DndEnabled = true;
                      
                      Tree.NodeDraggedCallback = @(h,e)obj.dragDropCallback(h,e);
                      Tree.NodeDroppedCallback = @(h,e)obj.dragDropCallback(h,e);
                      return;
                  end
          end
          %                            
          
      end
      
      % Build the graphical interface
      function fig = buildGUI(obj,fig)
         % BUILDGUI  Build the graphical interface
         %
         %  fig = obj.buildGUI(); Constructs new figure and adds panels
         %
         %  fig = obj.buildGUI(fig);  Adds the panels only
         
         if nargin < 2
            fig = figure(...
               'Toolbar','none',...
               'MenuBar','none',...
               'NumberTitle','off',...
               'Units','Normalized',...
               'Position',[0.35 0.35 0.325 0.45],...
               'Color',nigeLab.defaults.nigelColors('bg'),...
               'Visible','off');
         end
         
         % Add a panel that will display the actual block data trees
         str    = {'DataPanels'};
         strSub = {''};
         Tag      = 'DataPanel';
         Position = [.25,.11,.75,.88];
         obj.panel = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('sfc'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'),...
            'TitleBarPosition',[0.000 0.9725 1.000 0.0275]);
%         
%          jp=nigeLab.utils.findjobj(obj.panel);
%          jp.setBorder(javax.swing.BorderFactory.createEmptyBorder)
%          
         % Add a panel for interface control buttons
         obj.btnPanel = uipanel(fig,...
            'Tag','ButtonPanel',...
            'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
            'Units','normalized','Position',[.25 .01 .75 .1]);
         jp=nigeLab.utils.findjobj(obj.btnPanel);
         jp.setBorder(javax.swing.BorderFactory.createEmptyBorder);
         
         % Create "Tree" panel (nodes are: Tank > Animal > Block)
         str    = {'TreePanel'};
         strSub = {''};
         Tag      = 'TreePanel';
         Position = [.01,.01,.23,.98];
         %[left bottom width height] (normalized [0 to 1])
         obj.treePanel = nigeLab.libs.nigelPanel(fig,...
            'String',str,'Tag',Tag,'Position',Position,...
            'PanelColor',nigeLab.defaults.nigelColors('sfc'),...
            'TitleBarColor',nigeLab.defaults.nigelColors('primary'),...
            'TitleColor',nigeLab.defaults.nigelColors('onprimary'),...
            'TitleBarPosition',[0.000 0.9725 1.000 0.0275]);
         
      end
      
      % Applies the changes selected by the user to the actual blocks
      function ApplyCallback(obj,h,~)
         % APPLYCALLBACK  Applies the changes selected by the user to the
         %                 actual blocks. This should be done at the very
         %                 end of the user selection stuff.
         %
         %  obj.AcceptBtn.Callback = @ApplyCallback;
         
         
            jFrame = get(handle(obj.Fig),'JavaFrame');
            jFrame_fHGxClient = jFrame.fHG2Client;
            jFrame_fHGxClientW=jFrame_fHGxClient.getWindow;
            
            jFrame_fHGxClientW.setAlwaysOnTop(false);
            answer = repmat({nan},1,size(obj.reviedTrees,1));
            for ii=1:size(obj.reviedTrees,1)
                answer{ii} = questdlg(sprintf('Confirm Changes for block:\n%s',obj.toSplit(ii).Name),'Are you sure?','Yes','No','Yes to all','No');
                if strcmp(answer(ii),'Yes to all')
                   answer = repmat({'Yes'},1,size(obj.reviedTrees,1));
                   break;
                end
            end
            
            Idx = strcmp(answer,'Yes');
            Tree_ = obj.reviedTrees(Idx,:);
            obj.toSplit = obj.toSplit(Idx);
            
            

         

         DashObj = obj.tankObj.GUI;
         RawFlag = (obj.toSplit.getStatus('Raw'));
         if ~any(RawFlag) % if raw not extracted
            if ~isempty(obj.tankObj) && ~isempty(DashObj) % if in the gui mode
                question = sprintf(['Looks like some of the blocks you want to split were not extracted properly.\n',...
                    'Do you want me to rerun the extraction on those blocks?']);
                title = 'Unextracted blocks';
                answer = questdlg(question,title,'Yes','No','Yes');
                switch answer
                    case 'Yes'
                        operation = 'doRawExtraction';
                        for ii=find(~RawFlag(:))'
                            blockObj = obj.toSplit(ii);
                            bar = DashObj.qOperations(operation,blockObj,{blockObj.Parent.getKey,blockObj.getKey});
   
                        end
                        msgbox('Done. Come back when the extraction is finished.')
                        set(h,'Enable','on');
                        jFrame_fHGxClientW.setAlwaysOnTop(true);
                        obj.toggleVisibility('off');
                    case 'No'
                        uiwait(msgbox('As you wish, human.'));
                        jFrame_fHGxClientW.setAlwaysOnTop(true);
                end %switch
                return;
               
            else % in  command line mode
                for ii=find(~RawFlag(:))'
                    obj.toSplit(ii).doRawExtraction;
                end
                jFrame_fHGxClientW.setAlwaysOnTop(true);
            end %fi ~isempty(dashObj)
         end % fi ~RawFlag
%          
         set(h,'Enable','off');
         % apply changes to blocks
         obj.reviedTrees(Idx,:) = [];
         completeTreeIdx = cellfun(@(x)ismember(x(:,1),Tree_(:,1) ),obj.Tree,'UniformOutput',false);
         for ii=1:numel(obj.Tree)
            obj.Tree{ii}(completeTreeIdx{ii},:)=[]; 
         end
         obj.applychanges(Tree_); 
      end
       
      % Copy changes to everything
      function copyChangesToAll(obj,h,e)
         % COPYCHANGESTOALL   Copy changes to everything?
         %
         %  WIP
         
         obj.Tree;
      end
      
      % Callback for both "Drag" and "Drop" interactions
      function dropOk = dragDropCallback(obj,~,e)
          % DRAGDROPCALLBACK   Callback invoked for both "dragging" or
          %                    "dropping" things onto the tree.
          
          dropOk = false;
          % Is this the drag or drop part?
          doDrop = ~(nargout); % The drag callback expects an output, drop does not
          try
              for kk = 1:numel(e.Source)
                  % Get the source and destination
                  srcNode = e.Source(kk);
                  dstNode = e.Target;
                  
                  % If source is not yet assigned a Block, do not drop
                  if ~srcNode.UserData
                      dropOk = false;
                      continue;
                  end
                  
                  % If drop is allowed
                  if ~doDrop % --> drag part
                      % Is dstNode a valid drop location?
                      
                      % For example, assume it always is.
                      % Tree will prevent dropping on itself or existing parent.
                      dropOk = e.Target.Tree.Parent==e.Source(kk).Tree.Parent;
                      
                  elseif strcmpi(e.DropAction,'move')
                      dropOk = e.Target.Tree.Parent==e.Source(kk).Tree.Parent;
                      set(obj.AcceptBtn,'Enable','on');
                      if ~any(ismember(obj.reviedTrees,obj.thisTree))
                          obj.reviedTrees = [obj.reviedTrees;obj.thisTree];
                          obj.toSplit = [obj.toSplit,obj.selectionTree.SelectedItems];
                      end
                      NewNode = copy(srcNode);
                      Node = srcNode;
                      k=1;
                      while ~any(strcmp(Node.Name,{'Channels','Events','Streams'}))
                          OldNode = NewNode;
                          NewNode=uiw.widget.TreeNode('Name',Node.Parent.Name,...
                              'Parent',[],'UserData',Node.Parent.UserData);
                          OldNode.Parent = NewNode;
                          
                          Node=Node.Parent;
                      end
                      % De-parent
                      srcNode.Parent = [];
                      
                      % Then get index of destination
                      dstLevelNodes = [dstNode.Tree.Root.Children];
                      dstIndex = strcmp(NewNode.Name,{dstLevelNodes.Name});
                      
                      % Re-order children and re-parent
                      targetParent = dstLevelNodes(dstIndex);
                      while  any(ismember({targetParent.Children.Name},{NewNode.Children.Name}))
                          targetIndx = strcmp({targetParent.Children.Name},{NewNode.Children.Name});
                          targetParent = targetParent.Children(targetIndx);
                          NewNode = NewNode.Children;
                      end
                      NewNode.Children.expand();
                      while ~isempty(NewNode.Children)
                          NewNode.Children(end).Parent = targetParent;
                      end
                      dstLevelNodes(dstIndex).expand();
                      
                  end %fi
              end %kk
          catch
              disp('ooops. Try again.')
          end %try
      end %dragDropCallback
      
   end % methods private
   
   methods (Access = ?nigeLab.libs.nigelProgress)
            % Applies changes to the tree
      function applychanges(obj,Tree_)
         % APPLYCHANGES  Applies any changes to the tree, such as dragging
         %                 elements from a branch of one tree to the other.
         %
         %  obj.applychanges(Tree_);
         %
         %  Generates a `nigeLab.evt.splitCompleted` event data and
         %  notifies the `MultiAnimalsUI` property of `DashBoard` of the
         %  'splitCompleted' event associated with it.
         
        while ~isempty(obj.toSplit)
            thisBlock = obj.toSplit(1);
            thisBlock.splitMultiAnimals(Tree_(1,:));
            thisSplittedBlocks = thisBlock.MultiAnimalsLinkedBlocks;
            
            % add the splitted blocks back to the splitted animals
            arrayfun(@(B) B.Parent.addChild(B), thisSplittedBlocks);
            
           an = thisBlock.Parent;
           obj.tankObj.addChild(an.MultiAnimalsLinkedAnimals);
           for ii=1:numel(an.MultiAnimalsLinkedAnimals)
               saveLoc = an.MultiAnimalsLinkedAnimals(ii).SaveLoc;
              an.MultiAnimalsLinkedAnimals(ii).updatePaths(saveLoc,true);        
           end
           
           delete(Tree_(1,:));
           Tree_(1,:) = [];
           an.removeChild(thisBlock);
           obj.toSplit(1) = [];
           obj.deleteAnimalWhenEmpty(an);
           
           if  isempty(obj.multiTankObj.Children)
               evt = nigeLab.evt.splitCompleted();
               notify(obj,'SplitCompleted',evt);
               return;
           end
           
        end
        obj.selectionTree.changeTreeSelection([]);
        
      end
      
   end
   
   methods (Access = protected)
            % Changes the visibility of a given set of blocks or animals
      function rotateTreeVisibility(obj)
         % CHANGEVISIBILITY  Invoked when `toggleVisibility` is set to 'on'
         %
         %  obj.changeVisibility();
         %
         %  Get all the currently selected animals and blocks from
         %  DashBoard, so that they can be used in the splitting interface.
         switch obj.selectionTree.SelectedItemsType
             case {'Tank','Animal'}
                 thisNode = obj.selectionTree.Tree.SelectedNodes;
                 newNode = thisNode.Children(1);
                 obj.selectionTree.changeTreeSelection(newNode)
                 rotateTreeVisibility(obj);
                 return             
             case 'Block'
                 thisNode = obj.selectionTree.Tree.SelectedNodes;
                 keys = thisNode.UserData;
                 blockObj = obj.selectionTree.SelectedItems;
         end 
         cellfun(@(x) arrayfun(@(y) set(y,'Visible','off') ,x) ,obj.Tree);

         Animal = findByKey(obj.nigelObj,keys(1));
         anIdx = obj.nigelObj == Animal;
         blIdx = Animal.Children == blockObj; 
         obj.thisTree = obj.Tree{anIdx}(blIdx,:);
         [obj.thisTree(:).Visible] = deal('on');
%          if obj.AcceptBtn.UserData.reviewedBlocks(indx)
%             obj.AcceptBtn.Enable = 'on';
%          else
%             obj.AcceptBtn.Enable = 'off';
%          end
      end % changeVisibility
       
   end
   
   
   methods (Static,Access=public)
      % Create empty nigeLab.libs.splitMultiAnimalsUI object
      function obj = empty(n)
         %EMPTY  Create empty nigeLab.libs.splitMultiAnimalsUI object
         %
         %  obj = nigeLab.libs.splitMultiAnimalsUI.empty();
         %  --> Empty scalar
         %  obj = nigeLab.libs.splitMultiAnimalsUI.empty(n);
         %  --> Empty array with n elements
         
         if nargin < 1
            n = [0,0];
         else
            n = [0,max(n)];
         end
         obj = nigeLab.libs.splitMultiAnimalsUI(n);         
      end
      
      function assignNULL(Parent,childObj)
         % ASSIGNNULL  Does null assignment to remove a block of a
         %             corresponding index from the obj.Children
         %             property array, for example, if that Block is
         %             destroyed or moved to a different obj. Useful
         %             as a callback for an event listener handle.
         
         idx = ~isvalid(Parent.Children);
         if sum(idx) >= 1
            Parent.Children(idx) = [];
         else
            [~,idx] = findByKey(Parent.Children,childObj);
            if sum(idx) >= 1
               Parent.Children(idx) = [];
            end
         end   
      end
      
      function flag = deleteAnimalWhenEmpty(animalObj)
          flag = false;
         if isvalid(animalObj) && numel(animalObj.Children) == 0
             tankObj = animalObj.Parent;
             if isempty(tankObj)
                 delete(animalObj.File);
                 delete(animalObj);
             else
                 tankObj.removeChild(animalObj);
             end
           
            flag = true;
         end
      end
      
   end
end

