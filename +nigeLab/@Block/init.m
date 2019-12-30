function flag = init(blockObj)
% INIT Initialize BLOCK object
%
%  b = nigeLab.Block();
%
%  Note: INIT is a protected function and will always be called on
%        construction of BLOCK. Returns a "true" flag if executed
%        successfully.

%% INITIALIZE PARAMETERS
flag = false;
if any(~blockObj.updateParams('all'))
   warning('Could not properly initialize parameters.');
   return;
end
blockObj.checkParallelCompatibility();
pars = blockObj.Pars.Block;
   
%% PARSE NAME INFO
% Set flag for output if something goes wrong
meta = parseNamingMetadata(blockObj);

%% PARSE FILE NAME USING THE NAMING CONVENTION FROM TEMPLATE
str = [];
nameCon = blockObj.NamingConvention;
for ii = 1:numel(nameCon)
   if isfield(meta,nameCon{ii})
      str = [str,meta.(nameCon{ii}),pars.Concatenater]; %#ok<AGROW>
   end
end
blockObj.Name = str(1:(end-1));

%% Check for multiple Animals
for ii = fieldnames(meta)'
   if contains(meta.(ii{:}),pars.MultiAnimalsChar)
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
header = blockObj.parseHeader();
if ~blockObj.initChannels(header)
   warning('Could not initialize Channels structure headers properly.');
   return;
end

%% INITIALIZE VIDEOS STRUCT
if ~blockObj.initVideos
   warning('Could not initialize Videos structure properly.');
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

%% INITIALIZE KEYS
if ~blockObj.initKey()
   warning('Could not initialize unque keys for the block.');
   return;
end


blockObj.updateStatus('init');

% Prior to link to data, check if a function handle for conversion has been
% specified; if so, then do the conversion FIRST, then link it to data.
if ~isempty(blockObj.MatFileWorkflow.ConvertFcn)
   % Give the opportunity to cancel 
   % (function handle can just be configured to [] once Block has been 
   %  "converted" the first time)
   warningParams = struct('n',3,...
      'warning_string', '-->\tCONVERSION in ');
   h = nigeLab.utils.printWarningLoop(warningParams);
   waitfor(h);
   % If not canceled yet, run conversion
   blockObj.MatFileWorkflow.ConvertFcn(blockObj);
end


% Link to data and save
flag = blockObj.linkToData(true);
if ~flag
   nigeLab.utils.cprintf('UnterminatedStrings',...
      'Could not successfully link %s to all data.',blockObj.Name);
end

end