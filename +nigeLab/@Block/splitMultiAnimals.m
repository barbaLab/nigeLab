function Tree = splitMultiAnimals(blockObj,varargin)

if nargin < 2
 f = figure(...
    'Toolbar','none',...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Units','pixels',...
    'Position',[100 100 600 400],...
     'Color',nigeLab.defaults.nigelColors('bg'));
    tabgroup = uitabgroup(f,'Position',[.05 .05 .9 .9]);
    set(tabgroup,'Units','pixels');tabgroup.Position(2) = 30;set(tabgroup,'Units','normalized')
tabpanel = uitab(tabgroup,...
        'Title',blockObj.Name,...
        'UserData',blockObj,...
        'BackgroundColor',nigeLab.defaults.nigelColors('sfc'));

    
elseif nargin == 2
    switch class(varargin{1})
        case 'matlab.ui.container.Tab'
            tabpanel = varargin{1};
            f = tabpanel.Parent.Parent;
        case  'uiw.widget.Tree'
            Tree = varargin{1};
            f = Tree(1).Parent.Parent.Parent;
             btn = findobj(f,'Style','pushbutton','String','Accept');
            ApplyCallback(btn,[],Tree);
            return;
        otherwise
    end
end

if ~(blockObj.ManyAnimals)
    warning('No multi animals recording detected');
    return;
end

if isempty(blockObj.ManyAnimalsLinkedBlocks)
    ff = fieldnames(blockObj.Meta)';
    ff = ff(~strcmp(ff,'Header'));
    for ii = ff
        if contains(blockObj.Meta.(ii{:}),blockObj.ManyAnimalsChar)
            str = strsplit(blockObj.Meta.(ii{:}),blockObj.ManyAnimalsChar);
            if exist('SplittedMeta','var')
                [SplittedMeta.(ii{:})]=deal(str{:});
            else
                SplittedMeta = cell2struct(str,ii{:});
            end
        end
    end
    
    for ii=1:numel(SplittedMeta)
        ff=fields(SplittedMeta);
        bl = copy(blockObj);
        
        for jj=1:numel(ff)
            bl.Meta.(ff{jj}) = SplittedMeta(ii).(ff{jj});
        end %jj
        
        str = [];
        nameCon = bl.NamingConvention;
        for kk = 1:numel(nameCon)
            if isfield(bl.Meta,nameCon{kk})
                str = [str, ...
                    bl.Meta.(nameCon{kk}),...
                    bl.Delimiter]; %#ok<AGROW>
            end
        end %kk
        bl.Name = str(1:(end-1));
        bl.Channels = [];
        bl.initEvents;
        bl.Streams = [];
        bl.NumChannels = 0;
        bl.NumProbes = 0;
        splittedBlocks(ii) = bl;
    end %ii
    
    splittedBlocks(1).Channels = blockObj.Channels;
    splittedBlocks(1).Streams = blockObj.Streams;
    splittedBlocks(1).NumProbes = blockObj.NumProbes;
    splittedBlocks(1).NumChannels = blockObj.NumChannels;

    % save new blocks under the Parent block folder
%     for ii=1:numel(splittedBlocks)
%         newPath = fullfile(fileparts(splittedBlocks(ii).Paths.SaveLoc.dir),splittedBlocks(ii).Name);
%         splittedBlocks(ii).updatePaths(newPath);
%     end
    
    blockObj.ManyAnimalsLinkedBlocks = splittedBlocks;
    
    % Save the blocks in the corresponding Animal folders. 
    for ii =1:numel(blockObj.ManyAnimalsLinkedBlocks)
        animalPath = fullfile(fileparts(fileparts(blockObj.Paths.SaveLoc.dir)),...
            blockObj.ManyAnimalsLinkedBlocks(ii).Meta.AnimalID);
        BlockPath = fullfile(animalPath,blockObj.ManyAnimalsLinkedBlocks(ii).Name);
        blockObj.ManyAnimalsLinkedBlocks(ii).updatePaths(BlockPath);
    end
end
%% gui

for ii=1:numel(blockObj.ManyAnimalsLinkedBlocks)
    Tree(ii)= uiw.widget.Tree(...
        'Parent',tabpanel,...
        'Label', blockObj.ManyAnimalsLinkedBlocks(ii).Meta.AnimalID, ...
        'LabelLocation','top',...
        'LabelHeight',18,...
        'Units', 'normalized', ...
        'Position', [0.01+(ii-1)*0.5 0.01 0.45 0.95],...
        'UserData',blockObj.ManyAnimalsLinkedBlocks(ii),...
        'SelectionType','discontiguous',...
        'ForegroundColor',nigeLab.defaults.nigelColors('onsfc'),...
        'LabelForegroundColor',nigeLab.defaults.nigelColors('onsfc'),...
        'BackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
        'TreePaneBackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
        'TreeBackgroundColor',nigeLab.defaults.nigelColors('sfc'),...
        'SelectionBackgroundColor',nigeLab.defaults.nigelColors('primary'),...
        'SelectionForegroundColor',nigeLab.defaults.nigelColors('onprimary'));
    
    Tree(ii).Units = 'normalized';
    Tree(ii).RootVisible = false;
    Tree(ii).DndEnabled = true;
    Tree(ii).NodeDraggedCallback = @(h,e)dragDropCallback(h,e);
    Tree(ii).NodeDroppedCallback = @(h,e)dragDropCallback(h,e);
end
f.Position(3)=110*(ii-1)+110;
populateTree(Tree);

if nargin < 2
    btn = uicontrol('Style','pushbutton',...
    'Position',[150 5 50 20],'Callback',{@(h,e,x) ApplyCallback(h,e,x),Tree},...
    'String','Accept','Enable','off','Parent',f,...
    'BackgroundColor',nigeLab.defaults.nigelColors('primary'),...
    'ForegroundColor',nigeLab.defaults.nigelColors('onprimary'));
end

end

function ApplyCallback(h,e,Tree)
answer = questdlg('Are you sure?','Confirm Changes','Yes','No','Yes to all','No');
if strcmp(answer,'No'),return;end
set(h,'Enable','off');
for ii=1:numel(Tree)
    T = Tree(ii);
    for jj=1:numel(T.Root.Children) % Channels,Events,Streams
        C = T.Root.Children(jj);
        if ~isempty([C.Children.Children]) %Channels or Streams
            field = C.Name;
            Stff = [C.Children.Children];
        elseif ~isempty([C.Children]) % events
            field = C.Name;
            Stff = [C.Children];
        else % the field is empty, no children here
            continue; 
        end
        index = cat(1,Stff.UserData);
        
        % init target data with the stuff to keep
        trgtBlck = T.UserData;
        trgtStuff = trgtBlck.(field)(index(index(:,1) == ii,2));
        if isprop(trgtBlck,'Mask')&&strcmp(field,'Channels' )
            trgtMask = trgtBlck.Mask(index(index(:,1)==ii,2));
        end
        
        % make sure not to double assign
        allSrcBlck = unique(index(:,1));
        allSrcBlck(allSrcBlck==ii) = [];
        
        % cycle through all the sources and assign all the needed data
        for kk = allSrcBlck
            srcBlck = Tree(kk).UserData;
            srcStuffs = srcBlck.(field)(index(index(:,1)==kk,2));
            trgtStuff = [trgtStuff;srcStuffs];
            if isprop(srcBlck,'Mask')&&strcmp(field,'Channels' )
                srcMask = srcBlck.Mask(index(index(:,1)==kk,2));
                trgtMask = [trgtMask srcMask];
            end
        end
        AllTrgtMask{ii} = trgtMask;
        AllTrgtStuff{ii}.(field) = trgtStuff;
    end
end

% Actually modify the blocks
for ii=1:numel(Tree)
    jointBlock = Tree(ii).Parent.UserData;
    bl = Tree(ii).UserData;
    bl.Mask = AllTrgtMask{ii};
    Stuff = AllTrgtStuff{ii};
    ff = fieldnames(Stuff);
    for jj=1:numel(ff)
        bl.(ff{jj})=Stuff.(ff{jj});
    end
    
    fixPortsAndNumbers(bl);
    bl.ManyAnimals = false;
    bl.ManyAnimalsLinkedBlocks = jointBlock;
end
populateTree(Tree);

end

function fixPortsAndNumbers(bl)
%% port_number
 PN = [bl.Channels.port_number];
 OldPN = unique(PN);
% NewPn = 1:numel(OldPN);
% PN = num2cell((PN'==OldPN)*NewPn');
% [bl.Channels.port_number]=deal(PN{:});
bl.NumProbes = numel(OldPN);
bl.NumChannels = numel(bl.Channels);
end

function dropOk = dragDropCallback(h,e) %#ok<INUSL>

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
        
        btn = findobj(h.Parent.Parent.Parent,'Style','pushbutton','String','Accept');
        set(btn,'Enable','on');
        
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
end %function

function populateTree(Tree)
for tt=1:numel(Tree)
    bl = Tree(tt).UserData;
    if ~isempty(Tree(tt).Root.Children),delete(Tree(tt).Root.Children);end
    %% channels
    Channels_T = uiw.widget.TreeNode('Name','Channels',...
        'Parent',Tree(tt).Root,'UserData',0);
    if numel(bl.Channels)>0
        ProbesNames = unique({bl.Channels.port_name});
        AllProbesNumbers = [bl.Channels.port_number];
        ProbesNumbers = unique(AllProbesNumbers);
        Chans = {bl.Channels.custom_channel_name};
        for ii = 1:bl.NumProbes
            indx = find(AllProbesNumbers == ProbesNumbers(ii));
            Probe_T =  uiw.widget.TreeNode('Name',ProbesNames{ii},...
                'Parent',Channels_T);
            for jj= indx
                chan = uiw.widget.TreeNode('Name',Chans{jj},...
                    'Parent',Probe_T,'UserData',[tt,jj]);
            end
        end
    end
    Channels_T.expand();
    %% events
    Evts_T = uiw.widget.TreeNode('Name','Events',...
        'Parent',Tree(tt).Root,'UserData',0);
    if numel(bl.Events)>0
        for ii=1:numel(bl.Events)
            chan = uiw.widget.TreeNode('Name',bl.Events(ii).name,...
                'Parent',Evts_T,'UserData',[tt,ii]);
        end
    end
    Evts_T.expand();
    %% Streams
    Strms_T = uiw.widget.TreeNode('Name','Streams',...
        'Parent',Tree(tt).Root,'UserData',0);
    if numel(bl.Streams)>0
        allSignalType = {bl.Streams.port_name};
        signalType = unique(allSignalType);
        
        Streams = {bl.Streams.custom_channel_name};
        for ii =1:numel(signalType)
            indx = find(strcmp(allSignalType,signalType{ii}));
            StrmGrp_T =  uiw.widget.TreeNode('Name',signalType{ii},...
                'Parent',Strms_T);
            for jj = indx
                chan = uiw.widget.TreeNode('Name',Streams{jj},...
                    'Parent',StrmGrp_T,'UserData',[tt,jj]);
                
            end
        end
        
    end
    Strms_T.expand();
    
    
    
end
end