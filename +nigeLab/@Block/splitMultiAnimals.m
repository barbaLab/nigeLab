function Tree = splitMultiAnimals(blockObj,varargin)
% SPLITMULTIANIMALS  Returns a uiw.widget.Tree object with the split
%                    blocks depending on what is contained in the
%                    'MultiAnimalsLinkedBlocks' Property pointer for
%                    splitting recordings (Blocks) that have 2 or more
%                    animals in them.
%
%  Tree = blockObj.splitMultiAnimals();
%  Tree = blockObj.splitMultiAnimals(Tree);
%  Tree = blockObj.splitMultiAnimals('noGui');
%  Tree = blockObj.splitMultiAnimals('Gui');
%  Tree = blockObj.splitMultiAnimals('init');

%% Check inputs
switch nargin
   case 0
      error(['nigeLab:' mfilename ':tooFewInputs'],...
         'Not enough input arguments (0 provided, minimum 1 required)');
      
   case 1
      % Nothing here
      ...
         
   case 2
      % Depends on varargin{1}
      switch class(varargin{1})
         case  'uiw.widget.Tree'
            Tree = varargin{1};
            
            % Makes sure all correct properties are assigned to the first block
            if ~isfield(blockObj.MultiAnimalsLinkedBlocks(1).Channels,'Raw')
               assignPropsToFirstChild(blockObj);
            end
            
            ApplyChanges(Tree);
            return;
         case 'char'
            
            if ~(blockObj.MultiAnimals)
               warning('No multi animals recording detected');
               return;
            end
            
            if strcmpi(varargin{1},'noGui')
               
               if isempty(blockObj.MultiAnimalsLinkedBlocks)
                  CreateChildrenBlocks(blockObj);
               end
               
               RawFlag = all(blockObj.getStatus('Raw'));
               if ~RawFlag
                  blockObj.doRawExtraction;
               end
               
               assignPropsToFirstChild(blockObj)
               
               
            elseif strcmpi(varargin{1},'Gui')
               ...
            elseif strcmpi(varargin{1},'init')
%             if ~isempty(blockObj.MultiAnimalsLinkedBlocks)
%                 return;
%             end
            CreateChildrenBlocks(blockObj);
            assignPropsToFirstChild(blockObj);
            end
         otherwise
            error(['nigeLab:' mfilename ':badInputType2'],...
               'Undefined function ''splitMultiAnimals'' for input arguments of type ''%s'' ',...
               class(varargin{1}));
            
      end % switch
end
end % function

% Helper assignment function
function assignPropsToFirstChild(blockObj)
% ASSIGNPROPSTOFIRSTCHILD   Assign all properties to the first block
%
%  assignPropsToFirstChild(blockObj);  Just a helper function to assign
%                                      hard-coded subset of properties

blockObj.MultiAnimalsLinkedBlocks(1).Mask = blockObj.Mask;
blockObj.MultiAnimalsLinkedBlocks(1).Channels = blockObj.Channels;
blockObj.MultiAnimalsLinkedBlocks(1).Streams = blockObj.Streams;
% blockObj.MultiAnimalsLinkedBlocks(1).NumProbes = blockObj.NumProbes;
% blockObj.MultiAnimalsLinkedBlocks(1).NumChannels = blockObj.NumChannels;
blockObj.MultiAnimalsLinkedBlocks(1).Status = blockObj.Status;

blockObj.MultiAnimalsLinkedBlocks(2).Channels = blockObj.Channels([]);
blockObj.MultiAnimalsLinkedBlocks(2).Status = blockObj.Status;
end

% Creates the new "child" blocks from splitting
function CreateChildrenBlocks(blockObj)
% CREATECHILDRENBLOCKS  Create the new "child" blocks from splitting
%
%  CreateChildrenBlocks(blockObj);

% split meta that contains MultiAnimalsChar
ff = fieldnames(blockObj.Meta)';
ff = setdiff(ff,[{'Header','FileExt','OrigName','OrigPath'} blockObj.Pars.Block.SpecialMeta.SpecialVars]);
types =  structfun(@(x) class(x),blockObj.Meta,'UniformOutput',false);
for ii = ff
   if ~strcmp(types.(ii{:}),'char'),continue;end
   if contains(blockObj.Meta.(ii{:}),blockObj.Pars.Block.MultiAnimalsChar)
      str = strsplit(blockObj.Meta.(ii{:}),blockObj.Pars.Block.MultiAnimalsChar);
      if exist('SplittedMeta','var')
         [SplittedMeta.(ii{:})]=deal(str{:});
      else
         SplittedMeta = cell2struct(str,ii{:});
      end
   end
end

% Main cycle, create all MultiAnimalsLinkedObjects
for ii=1:numel(SplittedMeta)
   ff=fields(SplittedMeta);
   bl = copy(blockObj);
   
   % assign correct meta
   for jj=1:numel(ff)
       bl.Meta.(ff{jj}) = SplittedMeta(ii).(ff{jj});
   end %jj
   
   for kk = 1:numel(bl.Pars.Block.SpecialMeta.SpecialVars)
       f = bl.Pars.Block.SpecialMeta.SpecialVars{kk};
       if ~isfield(bl.Pars.Block.SpecialMeta,f)
           link_str = sprintf('nigeLab.defaults.%s',bl.Type);
           error(['nigeLab:' mfilename ':BadConfig'],...
               ['%s is configured to use %s as a "special field,"\n' ...
               'but it is not configured in %s.'],...
               nigeLab.utils.getNigeLink(...
               'nigeLab.nigelObj','parseNamingMetadata'),...
               f,nigeLab.utils.getNigeLink(link_str));
       end %fi
       if isempty(bl.Pars.Block.SpecialMeta.(f).vars)
           warning(['nigeLab:' mfilename ':PARSE'],...
               ['No <strong>%s</strong> "SpecialMeta" configured\n' ...
               '-->\t Making random "%s"'],f,f);
           bl.Meta.(f) = nigeLab.utils.makeHash();
           bl.Meta.(f) = bl.Meta.(f){:};
       else
           tmp = cell(size(bl.Pars.Block.SpecialMeta.(f).vars));
           for i = 1:numel(bl.Pars.Block.SpecialMeta.(f).vars)
               tmp{i} = bl.Meta.(bl.Pars.Block.SpecialMeta.(f).vars{i});
           end
           bl.Meta.(f) = strjoin(tmp,bl.Pars.Block.SpecialMeta.(f).cat);
       end % fi
   end %kk
   
   % create name from meta
   bl.Name = bl.genName;
   
   % Channels needs to be empty
   bl.Channels = bl.Channels([]);
   
   % Events needs to be empty
   bl.Events = [];
   
   % Streams needs to be empty
   ff = fieldnames(bl.Streams);
   for ss=1:numel(ff)
      Stf = fieldnames(bl.Streams.(ff{ss}))';
      Stf{2,1} = {};
      bl.Streams.(ff{ss}) = struct(Stf{:});
   end
   
%    bl.NumProbes = 0;
   bl.Mask = [];
   bl.Output = fullfile(bl.Out.SaveLoc);
   bl.MultiAnimals = 2;
   bl.MultiAnimalsLinkedBlocks(:) = [];
   bl.Key = bl.InitKey();
   bl.PropListener =  bl.PropListener([]);
   bl.ParentListener = bl.ParentListener([]);
        
        
   splittedBlocks(ii) = bl;
end %ii

blockObj.MultiAnimalsLinkedBlocks = splittedBlocks;

% Save the blocks in the corresponding Animal folders.
end

% Find things to move and move them to correct location
function ApplyChanges(Tree_)
% APPLYCHANGES  Find things to move and move them to correct location
%
%  ApplyChanges(Tree_);

for kk=1:size(Tree_,1)
   % get what needs to be moved and where
   for ii=1:size(Tree_,2)
      T = Tree_(kk,ii);           % one block per tree
      for jj=1:numel(T.Root.Children) % Channels,Events,Streams
         C = T.Root.Children(jj);
         switch C.Name
            case 'Streams'
               Stff = [C.Children];
               if isempty(Stff)
                    Stff.UserData = zeros(0,2);
               end
               field = C.Name;
               [trgtStuff] = getUpdatedStreams(T.UserData,Stff,Tree_(kk,:),ii);
               
            case 'Channels'
               field = C.Name;
               Stff = [C.Children.Children];
               if isempty(Stff)
                    Stff.UserData = zeros(0,2);
               end
               [trgtStuff,trgtMask] = getUpdateChans(T.UserData,Stff,Tree_(kk,:),ii);
            case 'Events'
               field = C.Name;
               Stff = [C.Children];
               %             [trgtStuff] = getUpdatedEvnts(trgtBlck,Stff,Tree_);
               
               continue;
            otherwise % the field is empty, no children here
               continue;
         end
         
         AllTrgtMask{kk,ii} = trgtMask;
         AllTrgtStuff{kk,ii}.(field) = trgtStuff;
      end
   end
end

% Actually modify the blocks
for kk=1:size(Tree_,1)
   for ii=1:size(Tree_,2)
      bl = Tree_(kk,ii).UserData;
      
      Stuff = AllTrgtStuff{kk,ii};
      ff = fieldnames(Stuff);
      for jj=1:numel(ff)
         bl.(ff{jj})=Stuff.(ff{jj});
      end
%       bl.setChannelMask(AllTrgtMask{kk,ii}-min(AllTrgtMask{kk,ii})+1);
      bl.setChannelMask(1:numel(bl.Channels));
      fixPortsAndNumbers(bl);
      bl.MultiAnimals = 0;
%       bl.Move(bl.Paths.SaveLoc);
      bl.updateStatus('init');
      bl.updateStatus('Raw',true(1,bl.NumChannels));
%       bl.linkToData;
      bl.save();
   end
end
end

% Fix ports and numbering that are messed up due to splitting
function fixPortsAndNumbers(bl)
% FIXPORTSANDNUMBERS   Ports and Numbering will be messed up since some may
%                       start with "Port C" but that is actually equivalent
%                       to configuration where "Port A" is plugged in,
%                       since it is just the second rat of the two.
%
%  fixPortsAndNumbers(bl);

% PN = [bl.Channels.port_number];
% OldPN = unique(PN);
% NewPn = 1:numel(OldPN);
% PN = num2cell((PN'==OldPN)*NewPn');
% [bl.Channels.port_number]=deal(PN{:});
% bl.NumProbes = numel(OldPN);
bl.NumChannels = numel(bl.Channels);
if isempty(bl.Mask)
   bl.Mask=1:bl.NumChannels;
else
   bl.Mask = bl.Mask - min(bl.Mask) + 1;
end
end

% Update the channels due to change in masking etc
function [trgtStuff,trgtMask]=getUpdateChans(trgtBlck,Stff,Tree,ii)
% GETUPDATECHANS  Get the updated channels depending on what has been
%                 assigned to which animal, since now the masks will change
%                 (because mask is based on Animal).

index = cat(1,Stff.UserData);

% init target data with the stuff to keep
trgtStuff = trgtBlck.Channels(index(index(:,1) == ii,2));
if isprop(trgtBlck,'Mask')
   [sortedMask,sortIndx] = sort(trgtBlck.Mask);
   newMaskIndex = sortIndx(ismember(sortedMask,index(index(:,1)==ii,2)));
   trgtMask = sortedMask(newMaskIndex);
end

% make sure not to double assign
allSrcBlck = unique(index(:,1));
allSrcBlck(allSrcBlck==ii) = [];

% cycle through all the sources and assign all the needed data
for kk = allSrcBlck
   srcBlck = Tree(kk).UserData;
   srcStuffs = srcBlck.Channels(index(index(:,1)==kk,2));
   
   trgtStuff = [trgtStuff;srcStuffs];
   if isprop(srcBlck,'Mask')
      srcMask = srcBlck.Mask(index(index(:,1)==kk,2));
      trgtMask = [trgtMask srcMask];
   end
end


end

% Updates Events
function [trgtStuff,trgtMask]=getUpdatedEvnts(trgtBlck,Stff,Tree,ii)
% GETUPDATEDEVNTS  Return the updated events (same as Channels)

index = cat(1,Stff.UserData);

% init target data with the stuff to keep
trgtStuff = trgtBlck.Events(index(index(:,1) == ii,2));
if isprop(trgtBlck,'Mask')&&strcmp(field,'Channels' )
   trgtMask = trgtBlck.Mask(index(index(:,1)==ii,2));
end

% make sure not to double assign
allSrcBlck = unique(index(:,1));
allSrcBlck(allSrcBlck==ii) = [];

% cycle through all the sources and assign all the needed data
for kk = allSrcBlck
   srcBlck = Tree(kk).UserData;
   srcStuffs = srcBlck.Events(index(index(:,1)==kk,2));
   trgtStuff = [trgtStuff;srcStuffs];
   if isprop(srcBlck,'Mask')&&strcmp(field,'Channels' )
      srcMask = srcBlck.Mask(index(index(:,1)==kk,2));
      trgtMask = [trgtMask srcMask];
   end
end



end

% Updates Streams
function [trgtStuff] = getUpdatedStreams(trgtBlck,Stff,Tree,ii)
% GETUPDATEDSTREAMS  Return the appropriate Streams since there is a subset
%                    of "sync" behavior streams associated with each box
%                    that should be assigned to each block after splitting.
StreamsTypes = {Stff.Name};
StreamsStruct = cellfun(@(x)  nigeLab.utils.initChannelStruct('Streams',0),...
    StreamsTypes,'UniformOutput',false);
trgtStuff = cell2struct(StreamsStruct,StreamsTypes,2);

for jj=1:numel(StreamsTypes)
   tmp = [Stff(jj).Children.Children];
   if isempty([Stff(jj).Children.Children]),continue;end
   index = cat(1,tmp.UserData);
   % init target data with the stuff to keep
   trgtStuff.(StreamsTypes{jj}) = trgtBlck.Streams.(StreamsTypes{jj})(index(index(:,1) == ii,2));
   
   % make sure not to double assign
   allSrcBlck = unique(index(:,1));
   allSrcBlck(allSrcBlck==ii) = [];
   
   % cycle through all the sources and assign all the needed data
   for kk = allSrcBlck
      srcBlck = Tree(kk).UserData;
      srcStuffs = srcBlck.Streams.(StreamsTypes{jj})(index(index(:,1)==kk,2));
      trgtStuff.(StreamsTypes{jj}) = [trgtStuff.(StreamsTypes{jj});srcStuffs];
   end
end


end