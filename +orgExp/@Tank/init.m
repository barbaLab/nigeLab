function init(tankObj)
%% INIT Initialize TANK object
%
%  tankObj.INIT;
%
%  By: Max Murphy v1.0  06/14/2018 Original version (R2017b)
 
%% LOAD DEFAULT SETTINGS

tankObj.Block = [];
tankObj.Name = 'Tank';

% tankObj = def_params(tankObj);
% 
% %% LOOK FOR NOTES
% notes = dir(fullfile(tankObj.DIR,'*Description.txt'));
% if ~isempty(notes)
%    tankObj.Notes.File = fullfile(notes.folder,notes.name);
%    fid = fopen(tankObj.Notes.File,'r');
%    tankObj.Notes.String = textscan(fid,'%s',...
%       'CollectOutput',true,...
%       'Delimiter','\n');
%    fclose(fid);
% else
%    tankObj.Notes.File = [];
%    tankObj.Notes.String = [];
% end
% 
% %% ADD PUBLIC BLOCK PROPERTIES
% path = strsplit(tankObj.DIR,filesep);
% tankObj.Name = path{numel(path)};
% finfo = strsplit(tankObj.Name,tankObj.ID.Delimiter);
% 
% for iL = 1:numel(tankObj.Fields)
%    tankObj.updateContents(tankObj.Fields{iL});
% end
% 
% %% ADD CHANNEL INFORMATION
% if ismember('CAR',tankObj.Fields(tankObj.Status))
%    tankObj.Channels.Board = sort(tankObj.CAR.ch,'ascend');
% elseif ismember('Filt',tankObj.Fields(tankObj.Status))
%    tankObj.Channels.Board = sort(tankObj.Filt.ch,'ascend');
% elseif ismember('Raw',tankObj.Fields(tankObj.Status))
%    tankObj.Channels.Board = sort(tankObj.Raw.ch,'ascend');
% end
% 
% % Check for user-specified MASKING
% if ~isempty(tankObj.MASK)
%    if abs(numel(tankObj.MASK)-numel(tankObj.Channels.Board))<eps
%       tankObj.Channels.Mask = tankObj.MASK;
%    else
%       warning('Wrong # of elements in specified MASK.');
%       fprintf(1,'Using all channels by default.\n');
%       tankObj.Channels.Mask = true(size(tankObj.Channels.Board));
%    end
% else
%    tankObj.Channels.Mask = true(size(tankObj.Channels.Board));
% end
% 
% % Check for user-specified REMAPPING
% if ~isempty(tankObj.REMAP)
%    if abs(numel(tankObj.REMAP)-numel(tankObj.Channels.Board))<eps
%       tankObj.Channels.Probe = tankObj.REMAP;
%    else
%       warning('Wrong # of elements in specified REMAP.');
%       fprintf(1,'Using board channels by default.\n');
%       tankObj.Channels.Probe = tankObj.Channels.Board;
%    end
% else
%    tankObj.Channels.Probe = tankObj.Channels.Board;
% end

end