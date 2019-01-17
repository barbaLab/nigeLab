function h = takeNotes(blockObj)
%% TAKENOTES   View or update notes on current BLOCK.
%
%  h = blockObj.TAKENOTES
%
% By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)
%                 v1.1  12/11/2018  Bugfixes

%%
h = nigeLab.libs.NotesUI(blockObj.Paths.Notes.name,blockObj);

end