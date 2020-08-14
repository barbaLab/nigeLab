function h = takeNotes(blockObj,fname)
%TAKENOTES  View or update notes on current BLOCK.
%
%  h = takeNotes(blockObj);
%  h = takeNotes(blockObj,fname);
%
% Inputs
%  blockObj - nigeLab.Block object
%  fname    - 'notes.txt' (default) | Any char vector filename
%
% Output
%  h        - nigeLab.libs.NotesUI handle (can be used to block advance of
%              script until the notes have been entered)  
%
% See also: nigeLab, nigeLab.libs, nigeLab.libs.NotesUI

if nargin < 2
   fname = 'notes.txt';
end

if numel(blockObj) > 1
   for i = 1:numel(blockObj)
      h = takeNotes(blockObj(i),fname);
      waitfor(h);
   end
   return;
end

filename = fullfile(blockObj.Output,fname);
h = nigeLab.libs.NotesUI(filename,blockObj);

end