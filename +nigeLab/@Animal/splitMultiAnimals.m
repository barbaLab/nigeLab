function flag = splitMultiAnimals(animalObj)

 f = figure(...
    'Toolbar','none',...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Units','pixels',...
    'Position',[100 100 600 400],...
     'Color',nigeLab.defaults.nigelColors('bg'));
    tabgroup = uitabgroup(f,'Position',[.05 .05 .9 .9]);
    set(tabgroup,'Units','pixels');tabgroup.Position(2) = 30;set(tabgroup,'Units','normalized')
Tree = [];
TankPath = fileparts(animalObj.Paths.SaveLoc);
for ii =1 : numel(animalObj.Blocks)
    BB = animalObj.Blocks(ii);
    tabpanel = uitab(tabgroup,...
        'Title',BB.Name,...
        'UserData',BB,...
        'BackgroundColor',nigeLab.defaults.nigelColors('sfc'));
    Tree_ = BB.splitMultiAnimals(tabpanel);
   Tree = [Tree Tree_];
   animalObjPaths{ii} = cellfun(@(x) fullfile(TankPath,x),{Tree_.Label},'UniformOutput',false);
end
uAnimals = unique([animalObjPaths{:}]);
for ii= 1:numel(uAnimals)
   an = copy(animalObj);
   an.Paths.SaveLoc = uAnimals{ii};
   [~,Name]=fileparts(uAnimals{ii});
   an.Name = Name;
   an.save;
end

btn = uicontrol('Style','pushbutton',...
    'Position',[150 5 50 20],'Callback',{@(h,e,x) ApplyCallback(h,e,x),Tree},...
    'String','Accept','Enable','off','Parent',f,...
    'BackgroundColor',nigeLab.defaults.nigelColors('primary'),...
    'ForegroundColor',nigeLab.defaults.nigelColors('onprimary'));
end %function

function ApplyCallback(h,e,Tree)

splitMultiAnimals(Tree(1).UserData,Tree);
% 
% answer = questdlg('Are you sure?','Confirm Changes','Yes','No','Yes to all','No');
% if strcmp(answer,'No'),return;end
% set(h,'Enable','off');
% for ii=1:numel(Tree)
%     T = Tree(ii);
%     for jj=1:numel(T.Root.Children) % Channels,Events,Streams
%         C = T.Root.Children(jj);
%         if ~isempty([C.Children.Children]) %Channels or Streams
%             field = C.Name;
%             Stff = [C.Children.Children];
%         elseif ~isempty([C.Children]) % events
%             field = C.Name;
%             Stff = [C.Children];
%         else % the field is empty, no children here
%             continue; 
%         end
%         index = cat(1,Stff.UserData);
%         
%         % init target data with the stuff to keep
%         trgtBlck = T.UserData;
%         trgtStuff = trgtBlck.(field)(index(index(:,1) == ii,2));
%         if isprop(trgtBlck,'Mask')&&strcmp(field,'Channels' )
%             trgtMask = trgtBlck.Mask(index(index(:,1)==ii,2));
%         end
%         
%         % make sure not to double assign
%         allSrcBlck = unique(index(:,1));
%         allSrcBlck(allSrcBlck==ii) = [];
%         
%         % cycle through all the sources and assign all the needed data
%         for kk = allSrcBlck
%             srcBlck = Tree(kk).UserData;
%             srcStuffs = srcBlck.(field)(index(index(:,1)==kk,2));
%             trgtStuff = [trgtStuff srcStuffs];
%             if isprop(srcBlck,'Mask')&&strcmp(field,'Channels' )
%                 srcMask = srcBlck.Mask(index(index(:,1)==kk,2));
%                 trgtMask = [trgtMask srcMask];
%             end
%         end
%         AllTrgtMask{ii} = trgtMask;
%         AllTrgtStuff{ii}.(field) = trgtStuff;
%     end
% end
% 
% % Actually modify the blocks
% for ii=1:numel(Tree)
%     jointBlock = Tree(ii).Parent.UserData;
%     bl = Tree(ii).UserData;
%     bl.Mask = AllTrgtMask{ii};
%     Stuff = AllTrgtStuff{ii};
%     ff = fieldnames(Stuff);
%     for jj=1:numel(ff)
%         bl.(ff{jj})=Stuff.(ff{jj});
%     end
%     
%     fixPortsAndNumbers(bl);
%     bl.ManyAnimals = false;
%     bl.ManyAnimalsLinkedBlocks = jointBlock;
% end
% populateTree(Tree);

end
