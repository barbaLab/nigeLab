classdef splitMultiAnimalsUI < handle
% SPLITMULTIANIMALSUI  Class constructor for UI to split
%                       multi-animals recording blocks.
%
%  obj.splitMultiAnimalsUI(DashObj);


   properties (GetAccess = ?nigeLab.libs.DashBoard,SetAccess = immutable)
      Fig                        matlab.ui.Figure
   end
   
   properties (Access = private,SetObservable,AbortSet)
      animalObj                  % nigeLab.Animal object
   end
   
   properties (Access = private)
      blockObj                   % nigeLab.Block object or array
      DashObj                    % nigeLab.libs.DashBoard object
      AcceptBtn                  matlab.ui.control.UIControl % pushbutton
      ApplyToAllBtn              matlab.ui.control.UIControl % pushbutton
      Tree                       % uiw.widget.Tree
      panel                      matlab.ui.container.Panel
      btnPanel                   matlab.ui.container.Panel
      
      PropListener                  event.listener  % Array of listeners
      SelectionChangedListener      event.listener
   end
   
   events
      SplitCompleted   % Fired once the "splitting" has been finished
   end
   
   methods (Access = public)
      % Class constructor for split multi animals UI
      function obj = splitMultiAnimalsUI(DashObj)
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
         elseif isnumeric(DashObj)
            n = DashObj;
            if numel(n) < 2
               n = [zeros(1,2-numel(n)),n];
            else
               n = [0, max(n)];
            end
            obj = repmat(obj,n);
            return;
         end
         
         obj.DashObj = DashObj;
         
         % Build user interface figure and panels
         obj.Fig = obj.buildGUI();
         
         % Create buttons
         obj.addButtons();
         
         % define useful event listeners
         obj.addListeners();
         
         % Assign the close request function since init has worked
         obj.Fig.CloseRequestFcn = ...
            {@(~,~,str)obj.DashObj.toggleSplitMultiAnimalsUI(str),'stop'};
         
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
               case 'on'
                  vis_mode = 'off';
               case 'off'
                  vis_mode = 'on';
            end
         end
         
         % Set visibility of figure
         obj.Fig.Visible = vis_mode;
         
         % Listener only executes callback if figure is visible
         obj.SelectionChangedListener.Enabled = strcmp(vis_mode,'on');
         if ~obj.SelectionChangedListener.Enabled
            return;
         end

         changeVisibility(obj);
         % toggle figure alway on top. Has to be changed before
         % the visibility property
         %                     drawnow;
         warningTag = 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame';
         warning('off',warningTag);
         
         jFrame = get(handle(obj.Fig),'JavaFrame');
         jFrame_fHGxClient = jFrame.fHG2Client;
         jFrame_fHGxClientW=jFrame_fHGxClient.getWindow;
         while(isempty(jFrame_fHGxClientW))
            jFrame_fHGxClientW=jFrame_fHGxClient.getWindow;
         end

         jFrame_fHGxClientW.setAlwaysOnTop(true);
         warning('on',warningTag);
               
      end % function toggleVisibility
      
   end % methods public
   
   methods (Access=private)
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
         
         obj.SelectionChangedListener = addlistener(obj.DashObj,...
            'TreeSelectionChanged',...
            @(~,~)obj.changeVisibility);
         obj.SelectionChangedListener.Enabled = false;
         obj.PropListener = addlistener(obj,'animalObj','PostSet',...
            @(~,~)obj.beginSplit);
      end
      
      % LISTENER CALLBACK: Initialize the splitting process
      function beginSplit(obj)
         % BEGINSPLIT  Initialize the splitting process
         %
         %  obj.beginSplit(); 
         %
         %  Syntax:
         %  obj.PropListener = addlistener(obj,'animalObj','PostSet',...
         %                       @(~,~)obj.beginSplit);
         
         % TODO case where only blockobj is initialized
         obj.Tree = obj.buildBlockTrees();
         obj.AcceptBtn.UserData.reviewedBlocks = false(1,...
            numel(obj.animalObj.Children));
         obj.animalObj.splitMultiAnimals('init');
         
      end
      
      % Build trees for individual block properties to "drag" to each other
      function Tree = buildBlockTrees(obj)
         % BUILDBLOCKTREES  Builds trees for individual block properties to
         %                    "drag" to each other.
         %
         %  Tree = obj.buildBlockTrees();
         
         Tree = gobjects(numel(obj.DashObj.B_split),...
                         numel(obj.blockObj.MultiAnimalsLinkedBlocks));
                      
         for jj = 1:numel(obj.animalObj.Children)
            thisBlock = obj.animalObj.Children(jj);
            if thisBlock == obj.blockObj
               visible = 'on';
            else
               visible = 'off';
            end
            thisBlock.splitMultiAnimals('init');
            for ii=1:numel(obj.blockObj.MultiAnimalsLinkedBlocks)
               Tree(jj,ii)= uiw.widget.Tree(...
                  'Parent',obj.panel,...
                  'Label', thisBlock.MultiAnimalsLinkedBlocks(ii).Meta.AnimalID, ...
                  'LabelLocation','top',...
                  'LabelHeight',18,...
                  'Units', 'normalized', ...
                  'Position', [0.01+(ii-1)*0.5 0.01 0.45 0.95],...
                  'UserData',thisBlock.MultiAnimalsLinkedBlocks(ii),...
                  'SelectionType','discontiguous',...
                  'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'),...
                  'LabelForegroundColor',nigeLab.defaults.nigelColors('onsfc'),...
                  'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                  'TreePaneBackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                  'TreeBackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
                  'SelectionBackgroundColor',nigeLab.defaults.nigelColors('primary'),...
                  'SelectionForegroundColor',nigeLab.defaults.nigelColors('onprimary'));
               
               Tree(jj,ii).Visible = visible;
               Tree(jj,ii).Units = 'normalized';
               Tree(jj,ii).RootVisible = false;
               Tree(jj,ii).DndEnabled = true;
               Tree(jj,ii).NodeDraggedCallback = @(h,e)obj.dragDropCallback(h,e);
               Tree(jj,ii).NodeDroppedCallback = @(h,e)obj.dragDropCallback(h,e);
            end
         end
         populateTree(Tree);
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
         obj.panel = uipanel(fig,...
            'Tag','DataPanel',...
            'UserData',obj.blockObj,...
            'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
            'Units','normalized',...
            'Position',[.01 .1 .98 .85]);
         jp=nigeLab.utils.findjobj(obj.panel);
         jp.setBorder(javax.swing.BorderFactory.createEmptyBorder)
         
         % Add a panel for interface control buttons
         obj.btnPanel = uipanel(fig,...
            'Tag','ButtonPanel',...
            'UserData',obj.blockObj,...
            'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
            'Units','normalized','Position',[.01 0 .98 .1]);
         jp=nigeLab.utils.findjobj(obj.btnPanel);
         jp.setBorder(javax.swing.BorderFactory.createEmptyBorder);
         
      end
      
      % Applies the changes selected by the user to the actual blocks
      function ApplyCallback(obj,h,~)
         % APPLYCALLBACK  Applies the changes selected by the user to the
         %                 actual blocks. This should be done at the very
         %                 end of the user selection stuff.
         %
         %  obj.AcceptBtn.Callback = @ApplyCallback;
         
         if ~h.UserData.yesToAll
            warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
            jFrame = get(handle(obj.Fig),'JavaFrame');
            warning('on','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
            jFrame_fHGxClient = jFrame.fHG2Client;
            jFrame_fHGxClientW=jFrame_fHGxClient.getWindow;
            
            jFrame_fHGxClientW.setAlwaysOnTop(false);
            answer = questdlg('Are you sure?','Confirm Changes','Yes','No','Yes to all','No');
            if strcmp(answer,'No'),return;
            elseif strcmp(answer,'Yes to all')% apllies changes to all blocks
               h.UserData.YesToAll=true;
               indx = h.UserData.reviewedBlocks;
            elseif strcmp(answer,'Yes') % find displayed block
               indx = strcmp({obj.Tree(:,1).Visible},'on');
            end
            jFrame_fHGxClientW.setAlwaysOnTop(true);
         end
         set(h,'Enable','off');
         
         RawFlag = all(obj.blockObj.getStatus('Raw'));
         % TODO, if Raw not extracted yet do extraction.
         if ~RawFlag % if raw not extracted
            if ~isempty(obj.DashObj) % if in the gui mode
               operation = 'doRawExtraction';
               job = obj.DashObj.qOperations(operation,obj.blockObj);
               if ~isempty(job)
                  fcnList = {job.FinishedFcn,{@(~,~)obj.applychanges}};
                  CompletedFun = {@nigeLab.utils.multiCallbackWrap, fcnList};
                  job.FinishedFcn = CompletedFun;
                  return;
               end
               
            else % in  command line mode
               obj.blockObj.doRawExtraction;
            end %fi ~isempty(dashObj)
         end % fi ~RawFlag
         
         % apply changes to blocks
         obj.applychanges(obj.Tree(indx,:));
      end
      
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
         
         if ~isempty(obj.animalObj)
            obj.animalObj.splitMultiAnimals(Tree_);
            splitCompletedEvt = nigeLab.evt.splitCompleted(...
               obj.animalObj.MultiAnimalsLinkedAnimals);
         else
            obj.blockObj.splitMultiAnimals(Tree_);
            splitCompletedEvt = nigeLab.evt.splitCompleted(...
               obj.blockObj.MultiAnimalsLinkedBlocks);
         end
         populateTree(Tree_);
         obj.animalObj.removeChild(find(obj.animalObj.Children == obj.blockObj)); %#ok<FNDSB>
         notify(obj,'SplitCompleted',splitCompletedEvt);
         % if an animal obj is available, move everything to the correct
         % animal
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
         
         % Is this the drag or drop part?
         doDrop = ~(nargout); % The drag callback expects an output, drop does not

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
               dropOk = true;               
               
            elseif strcmpi(e.DropAction,'move')
               blockID = (obj.blockObj==obj.animalObj.Children);
               set(obj.AcceptBtn,'Enable','on');
               obj.AcceptBtn.UserData.reviewedBlocks(blockID) = true;
               
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
               
            end
         end %kk
      end %dragDropCallback
      
      % Changes the visibility of a given set of blocks or animals
      function changeVisibility(obj)
         % CHANGEVISIBILITY  Invoked when `toggleVisibility` is set to 'on'
         %
         %  obj.changeVisibility();
         %
         %  Get all the currently selected animals and blocks from
         %  DashBoard, so that they can be used in the splitting interface.
         
         [obj.blockObj,obj.animalObj]= obj.DashObj.getSelectedItems;
         indx = obj.animalObj.Children == obj.blockObj;
         
         [obj.Tree(:).Visible] = deal('off');
         [obj.Tree(indx,:).Visible] = deal('on');
         if obj.AcceptBtn.UserData.reviewedBlocks(indx)
            obj.AcceptBtn.Enable = 'on';
         else
            obj.AcceptBtn.Enable = 'off';
         end
      end % changeVisibility
      
   end % methods private
   
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
   end
end

