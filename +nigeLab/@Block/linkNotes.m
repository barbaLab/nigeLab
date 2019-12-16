function flag = linkNotes(blockObj,addNotes)
% LINKNOTES   Connect notes metadata saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = linkNotes(b);
%
%  flag = linkNotes(b,true); Force the save dialog open
%
% flag returns true if "Notes" were saved or already exist in that location

%% PARSE EXPERIMENT METADATA
if nargin < 2
   addNotes = false;
end

blockObj.checkCompatibility({'Notes'});

flag = false;
blockObj.updateParams('Experiment');
blockObj.Paths.Notes.name = nigeLab.utils.getUNCPath(...
   fullfile(sprintf(strrep(...
      blockObj.Paths.Notes.file,'\','/'),...
      blockObj.Pars.Experiment.File)));

nigeLab.utils.printLinkFieldString(blockObj.getFieldType('Notes'),'Notes');
if (exist(blockObj.Paths.Notes.name,'file')==0)
   copyfile(nigeLab.utils.getUNCPath(...
      fullfile(blockObj.Pars.Experiment.Folder,...
               blockObj.Pars.Experiment.File)),...
      blockObj.Paths.Notes.name,'f');
   addNotes = true;
end

if addNotes
   handles = nigeLab.utils.uiHandle('flag',flag);
   h = blockObj.takeNotes;
   lh = event.listener(h.UIFigure,'ObjectBeingDestroyed',...
      @(s,e)setFlagValue(s,e,handles));
   waitfor(h);
   delete(lh);
   updateFlag = get(handles,'flag');
   delete(handles);
else
   updateFlag = blockObj.Status.Notes;
end
blockObj.updateStatus('Notes',updateFlag);
flag = ~updateFlag;

fprintf(1,'\b\b\b\b\b%.3d%%\n',100);

   function setFlagValue(src,~,handles)
      % SETFLAGVALUE  Callback to update the 'flag' value depending on
      %               whether the user actually saves the notes.
      %
      %  src  --  nigeLab.libs.NotesUI object
      %  handles  -- nigeLab.utils.uiHandle with 'flag' data
      
      set(handles,'flag',src.UserData);
   end


end