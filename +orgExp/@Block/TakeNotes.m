function TakeNotes(obj)
%% TAKENOTES   View or update notes on current BLOCK.
%
%  obj.TAKENOTES
%
% By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)

%%
h = orgExp.libs.NotesUI;
if isempty(obj.Notes.File)
   obj.Notes.File = fullfile(obj.DIR,[obj.Name ' Description.txt']);
end
h.addNotes(obj,obj.Notes);

end