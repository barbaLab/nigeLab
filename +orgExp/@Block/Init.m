function Init(obj)
%% INIT Initialize BLOCK object
%
%  obj.INIT;
%
%  By: Max Murphy v1.0  08/25/2017  Original version (R2017a)

%% LOAD DEFAULT ID SETTINGS
obj = def_params(obj);

%% LOOK FOR NOTES
notes = dir(fullfile(obj.DIR,'*Description.txt'));
if ~isempty(notes)
   obj.Notes.File = fullfile(notes.folder,notes.name);
   fid = fopen(obj.Notes.File,'r');
   obj.Notes.String = textscan(fid,'%s',...
      'CollectOutput',true,...
      'Delimiter','\n');
   fclose(fid);
else
   obj.Notes.File = [];
   obj.Notes.String = [];
end

%% ADD PUBLIC BLOCK PROPERTIES
path = strsplit(obj.DIR,filesep);
obj.Name = path{numel(path)};
finfo = strsplit(obj.Name,obj.ID.Delimiter);

for iL = 1:numel(obj.Fields)
   obj.UpdateContents(obj.Fields{iL});
end

%% ADD CHANNEL INFORMATION
if ismember('CAR',obj.Fields(obj.Status))
   obj.Channels.Board = sort(obj.CAR.ch,'ascend');
elseif ismember('Filt',obj.Fields(obj.Status))
   obj.Channels.Board = sort(obj.Filt.ch,'ascend');
elseif ismember('Raw',obj.Fields(obj.Status))
   obj.Channels.Board = sort(obj.Raw.ch,'ascend');
end

% Check for user-specified MASKING
if ~isempty(obj.MASK)
   if abs(numel(obj.MASK)-numel(obj.Channels.Board))<eps
      obj.Channels.Mask = obj.MASK;
   else
      warning('Wrong # of elements in specified MASK.');
      fprintf(1,'Using all channels by default.\n');
      obj.Channels.Mask = true(size(obj.Channels.Board));
   end
else
   obj.Channels.Mask = true(size(obj.Channels.Board));
end

% Check for user-specified REMAPPING
if ~isempty(obj.REMAP)
   if abs(numel(obj.REMAP)-numel(obj.Channels.Board))<eps
      obj.Channels.Probe = obj.REMAP;
   else
      warning('Wrong # of elements in specified REMAP.');
      fprintf(1,'Using board channels by default.\n');
      obj.Channels.Probe = obj.Channels.Board;
   end
else
   obj.Channels.Probe = obj.Channels.Board;
end

end