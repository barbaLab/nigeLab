function flag = linkNotes(blockObj)
%% LINKNOTES   Connect notes metadata saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = LINKNOTES(b);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE EXPERIMENT METADATA
flag = false;
notes = nigeLab.defaults.Experiment();
blockObj.updateParams('Experiment');
blockObj.Paths.Notes.name = fullfile(sprintf(strrep(...
   blockObj.Paths.Notes.file,'\','/'),'Experiment.txt'));

nigeLab.utils.printLinkFieldString(blockObj.getFieldType('Notes'),'Notes');
if exist(blockObj.Paths.Notes.name,'file')==0
   copyfile(fullfile(notes.Folder,notes.File),...
      blockObj.Paths.Notes.name,'f');
   flag = true;
end
h = blockObj.takeNotes;
waitfor(h);

fprintf(1,'\b\b\b\b\b%.3d%%\n',100)



end