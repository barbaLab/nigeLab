classdef (ConstructOnLoad) treeSelectionChanged < event.EventData
%TREESELECTIONCHANGED   Event for notifying listeners that current
%                       selection has changed in Tank/Animal/Block tree of
%                       nigeLab.libs.DashBoard
%
%  This is issued with the `TreeSelectionChanged` notification of
%  `nigeLab.libs.DashBoard` any time the `nigeLab.libs.DashBoard.Tree`
%  uiw.widgets.Tree object is clicked and the selection (highlighted nodes,
%  which correspond to the currently-selected `nigeLab.Block` objects) is
%  changed.
%
%  TREESELECTIONCHANGED Methods:
%     treeSelectionChanged  --  Class constructor
%
%     initAll  --  (Private) helper method to assign ALL blocks in tank
%
%  TREESELECTIONCHANGED Properties:
%     Animal -- nigeLab.Animal scalar or array of animals in this selection
%
%     Block -- nigeLab.Block scalar or array of blocks in this selection
%
%     Tank -- nigeLab.Tank scalar; hierarchical top-level container
%     
%     SelectionIndex - [animalIndex, blockIndex] 2-column matrix that
%        indexes .Tank. i.e. 
%        >> evt.Block = evt.Tank{evt.SelectionIndex}; % or
%        >> evt.Animal = evt.Tank{evt.SelectionIndex(:,1)};

   properties (GetAccess = public, SetAccess = private)
      Animal  nigeLab.Animal % Animal or array of animals in this selection
      Block   nigeLab.Block  % Block or array of blocks in this selection
      Tank    nigeLab.Tank   % Tank associated with this selection
      SelectionIndex  double % [animalIndex, blockIndex]
   end

   methods (Access = public)
      function evt = treeSelectionChanged(tankObj,selectionIndex)
         %TREESELECTIONCHANGED Constructor for tree selection changed event
         %
         %  tankObj = nigeLab.Tank();
         %  evt = nigeLab.evt.treeSelectionChanged(tankObj,selectionIndex);
         %
         %  blockObj = tankObj{selectionIndex};
         %  animalObj = tankObj{unique(selectionIndex(:,1))};
         
         evt.Tank = tankObj;
         switch size(selectionIndex,2)
            case 0
               %% No indexing was given (indexing is from Tank select)
               evt.initAll();
               
            case 1
               %% Only Animals indexing was given
               evt.initAll(selectionIndex);
            case 2
               %% Normal case
               evt.Animal = tankObj.Children(unique(selectionIndex(:,1)));
               evt.Block = tankObj{selectionIndex(:,1),selectionIndex(:,2)};
               evt.SelectionIndex = selectionIndex;
            case 3
               %% nigeLab.libs.DashBoard.SelectionIndex was given
               if selectionIndex(1,2)==0 % Then tank is selected
                  evt.initAll();
                  
               else % Otherwise, relatively normal
                  evt.SelectionIndex = selectionIndex(:,[2,3]);
                  evt.Block = tankObj{evt.SelectionIndex(:,1),...
                                      evt.SelectionIndex(:,2)};
                  iA = unique(evt.SelectionIndex(:,1));
                  evt.Animal = tankObj.Children(iA);
               end
            otherwise
               error(['nigeLab:' mfilename ':InvalidInputSize'],...
                   ['Expected selectionIndex to have between ' ...
                    '0 and 3 columns (it has %g)'],size(selectionIndex,2));
         end
      end
   end
   
   methods (Access = private)
      % Method to initialize ALL Animals/Blocks in Tank
      function initAll(evt,animalIndices)
         %INITALL Initializes evt with ALL animals/blocks in tank
         %
         %  evt.initAll();
         %  evt.initAll(animalIndices);  Init with subset of animals/all
         %                               blocks for those animals
         
         if nargin < 2
            evt.Animal = evt.Tank.Children;
         else
            evt.Animal = evt.Tank.Children(unique(animalIndices));
         end
         selectionIndex = [];
         iA = 0;
         for a = evt.Animal
            iA = iA + 1;
            evt.Block = [evt.Block, a.Children];
            n = numel(a.Children);
            selectionIndex = [selectionIndex; ...
               ones(n,1)*iA, (1:n)']; %#ok<*AGROW>
         end
         evt.SelectionIndex = selectionIndex;
      end
   end
   
end