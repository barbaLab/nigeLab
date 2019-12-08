function flag = init(blockObj)
%% INIT Initialize BLOCK object
%
%  b = nigeLab.Block();
%
%  Note: INIT is a protected function and will always be called on
%        construction of BLOCK. Returns a "true" flag if executed
%        successfully.
%
%  By: Max Murphy       v1.0  08/25/2017  Original version (R2017a)
%      Federico Barban  v2.0  07/08/2018
%      MAECI 2018       v3.0  11/28/2018

%% INITIALIZE PARAMETERS
flag = false;
if any(~blockObj.updateParams('all'))
   warning('Could not properly initialize parameters.');
   return;
end
   
%% PARSE NAME INFO
% Set flag for output if something goes wrong
meta = parseNamingMetadata(blockObj);

%% PARSE FILE NAME USING THE NAMING CONVENTION FROM TEMPLATE
str = [];
nameCon = blockObj.NamingConvention;
for ii = 1:numel(nameCon)
   if isfield(meta,nameCon{ii})
      str = [str, ...
         meta.(nameCon{ii}),...
         blockObj.Delimiter]; %#ok<AGROW>
   end
end
blockObj.Name = str(1:(end-1));

%% Check for multiple Animals
for ii = fieldnames(meta)'
   if contains(meta.(ii{:}),blockObj.MultiAnimalsChar)
       blockObj.MultiAnimals = true;
       break;
   end
end

%% GET/CREATE SAVE LOCATION FOR BLOCK
% blockObj.AnimalLoc is probably empty [] at this point, which will prompt 
% a UI to point to the block save directory:
if ~blockObj.getSaveLocation(blockObj.AnimalLoc)
   flag = false;
   warning('Save location not set successfully.');
   return;
end

%% EXTRACT HEADER INFORMATION
if ~blockObj.initChannels
   warning('Could not initialize Channels structure headers properly.');
   return;
end

%% INITIALIZE STREAMS STRUCT
if ~blockObj.initStreams
   warning('Could not initialize Streams structure headers properly.');
   return;
end

%% INITIALIZE EVENTS STRUCT
if ~blockObj.initEvents
   warning('Could not initialize Events structure properly.');
   return;
end
blockObj.updateStatus('init');

% Link to data and save
flag = blockObj.linkToData(true);
if ~flag
   nigeLab.utils.cprintf('UnterminatedStrings','Could not successfully link %s to data.',blockObj.Name);
end
   

end