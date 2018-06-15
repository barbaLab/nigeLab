function init(blockObj)
%% INIT Initialize BLOCK object
%
%  blockObj.INIT;
%
%  By: Max Murphy v1.0  08/25/2017  Original version (R2017a)

%% LOOK FOR NOTES
notes = dir(fullfile(blockObj.DIR,'*Description.txt'));
if ~isempty(notes)
   blockObj.Notes.File = fullfile(notes.folder,notes.name);
   fid = fopen(blockObj.Notes.File,'r');
   blockObj.Notes.String = textscan(fid,'%s',...
      'CollectOutput',true,...
      'Delimiter','\n');
   fclose(fid);
else
   blockObj.Notes.File = [];
   blockObj.Notes.String = [];
end

%% ADD PUBLIC BLOCK PROPERTIES
path = strsplit(blockObj.DIR,filesep);
blockObj.Name = path{numel(path)};
finfo = strsplit(blockObj.Name,blockObj.ID.Delimiter);

for iL = 1:numel(blockObj.Fields)
   blockObj.updateContents(blockObj.Fields{iL});
end

%% ADD CHANNEL INFORMATION
if ismember('CAR',blockObj.Fields(blockObj.Status))
   blockObj.Channels.Board = sort(blockObj.CAR.ch,'ascend');
elseif ismember('Filt',blockObj.Fields(blockObj.Status))
   blockObj.Channels.Board = sort(blockObj.Filt.ch,'ascend');
elseif ismember('Raw',blockObj.Fields(blockObj.Status))
   blockObj.Channels.Board = sort(blockObj.Raw.ch,'ascend');
end

% Check for user-specified MASKING
if ~isempty(blockObj.MASK)
   if abs(numel(blockObj.MASK)-numel(blockObj.Channels.Board))<eps
      blockObj.Channels.Mask = blockObj.MASK;
   else
      warning('Wrong # of elements in specified MASK.');
      fprintf(1,'Using all channels by default.\n');
      blockObj.Channels.Mask = true(size(blockObj.Channels.Board));
   end
else
   blockObj.Channels.Mask = true(size(blockObj.Channels.Board));
end

% Check for user-specified REMAPPING
if ~isempty(blockObj.REMAP)
   if abs(numel(blockObj.REMAP)-numel(blockObj.Channels.Board))<eps
      blockObj.Channels.Probe = blockObj.REMAP;
   else
      warning('Wrong # of elements in specified REMAP.');
      fprintf(1,'Using board channels by default.\n');
      blockObj.Channels.Probe = blockObj.Channels.Board;
   end
else
   blockObj.Channels.Probe = blockObj.Channels.Board;
end

end