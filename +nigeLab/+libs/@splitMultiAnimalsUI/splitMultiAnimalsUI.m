classdef splitMultiAnimalsUI < handle
   %SPLITMULTIANIMALSUI Summary of this class goes here
   %   Detailed explanation goes here
   properties (Access = ?nigeLab.libs.DashBoard)
      Fig
   end
   
   properties (Access = private,SetObservable,AbortSet)
      animalObj
   end
   
   properties (Access = private)
      blockObj
      DashObj
      AcceptBtn
      ApplyToAllBtn
      Tree
      panel
      btnPanel
      
      SelectionChangedListener
   end
   
   events
      splitCompleted
   end
   
   methods
      function obj = splitMultiAnimalsUI(DashObj)
         obj.DashObj = DashObj;
         obj.Fig = figure(...
            'Toolbar','none',...
            'MenuBar','none',...
            'NumberTitle','off',...
            'Units','pixels',...
            'Position',[100 100 600 400],...
            'Color',nigeLab.defaults.nigelColors('bg'),...
            'CloseRequestFcn',{@(~,~,str)obj.DashObj.toggleSplitMultiAnimalsUI(str),'stop'},...
            'Visible','off');
         
         obj.panel = uipanel('UserData',obj.blockObj,...
            'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
            'Units','normalized','Position',[.01 .1 .98 .85]);
         jp=nigeLab.utils.findjobj(obj.panel);
         jp.setBorder(javax.swing.BorderFactory.createEmptyBorder)
         
         obj.btnPanel = uipanel('UserData',obj.blockObj,...
            'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
            'Units','normalized','Position',[.01 0 .98 .1]);
         jp=nigeLab.utils.findjobj(obj.btnPanel);
         jp.setBorder(javax.swing.BorderFactory.createEmptyBorder);
         
         
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
         
         % define useful event listeners
         obj.SelectionChangedListener = addlistener(obj.DashObj,'TreeSelectionChanged',@(~,~)obj.changeVisibility);
         obj.SelectionChangedListener.Enabled = false;
         addlistener(obj,'animalObj','PostSet',@(~,~)obj.init);
      end
      
      function toggleVisibility(obj)
         switch obj.Fig.Visible
            case 'on'
               obj.Fig.Visible = 'off';
               obj.SelectionChangedListener.Enabled = false;
            case 'off'
               obj.Fig.Visible = 'on';
               obj.SelectionChangedListener.Enabled = true;
               changeVisibility(obj);
               % toggle figure alway on top. Has to be changed before
               % the visibility property
               %                     drawnow;
               warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
               jFrame = get(handle(obj.Fig),'JavaFrame');
               jFrame_fHGxClient = jFrame.fHG2Client;
               jFrame_fHGxClientW=jFrame_fHGxClient.getWindow;
               while(isempty(jFrame_fHGxClientW)),jFrame_fHGxClientW=jFrame_fHGxClient.getWindow;
               end
               
               jFrame_fHGxClientW.setAlwaysOnTop(true);
               warning('on','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
               
         end
         
      end
      
   end
   
   methods (Access=private)
      function init(obj)
         % TODO case where only blockobj is initialized
         obj.animalObj.splitMultiAnimals('init');
         obj.Tree = obj.buildBlocksTrees();
         obj.AcceptBtn.UserData.reviewedBlocks = false(1,numel(obj.animalObj.Blocks));
         
         
      end
      
      function Tree = buildBlocksTrees(obj)
         for jj = 1:numel(obj.animalObj.Blocks)
            thisBlock = obj.animalObj.Blocks(jj);
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
      
      function ApplyCallback(obj,h,e)
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
      
      function applychanges(obj,Tree_)
         if ~isempty(obj.animalObj)
            obj.animalObj.splitMultiAnimals(Tree_);
            splitCompletedEvt = nigeLab.evt.splitCompleted(obj.animalObj.MultiAnimalsLinkedAnimals);
         else
            obj.blockObj.splitMultiAnimals(Tree_);
            splitCompletedEvt = nigeLab.evt.splitCompleted(obj.blockObj.MultiAnimalsLinkedBlocks);
         end
         populateTree(Tree_);
         obj.animalObj.removeBlocks(find(obj.animalObj.Blocks == obj.blockObj)); %#ok<FNDSB>
         notify(obj,'splitCompleted',splitCompletedEvt);
         % if an animal obj is available, move everything to the correct
         % animal
      end
      
      function copyChangesToAll(obj,h,e)
         obj.Tree;
      end
      
      function dropOk = dragDropCallback(obj,h,e)
         
         % Is this the drag or drop part?
         doDrop = ~(nargout); % The drag callback expects an output, drop does not
         
         for kk = 1:numel(e.Source)
            % Get the source and destination
            srcNode = e.Source(kk);
            dstNode = e.Target;
            
            if ~srcNode.UserData
               dropOk = false;
               continue;
            end
            
            % If drop is allowed
            if ~doDrop
               % Is dstNode a valid drop location?
               
               % For example, assume it always is. Tree will prevent dropping on
               % itself or existing parent.
               dropOk = true;
               
            elseif strcmpi(e.DropAction,'move')
               blockID = (obj.blockObj==obj.animalObj.Blocks);
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
      
      function changeVisibility(obj)
         % CHANGEVISIBILITY  Changes the visibility of a given set of
         %                   blocks/animals.
         %
         %  obj.changeVisibility();
         
         [obj.blockObj,obj.animalObj]= obj.DashObj.getSelectedItems;
         indx = obj.animalObj.Blocks == obj.blockObj;
         
         [obj.Tree(:).Visible] = deal('off');
         [obj.Tree(indx,:).Visible] = deal('on');
         if obj.AcceptBtn.UserData.reviewedBlocks(indx)
            obj.AcceptBtn.Enable = 'on';
         else
            obj.AcceptBtn.Enable = 'off';
         end
      end % changeVisibility
      
   end % methods private
   
   
end

