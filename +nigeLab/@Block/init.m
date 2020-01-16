function flag = init(blockObj)
%INIT Initialize BLOCK object
%
%  b = nigeLab.Block();
%
%  Note: INIT is a protected function that is called from the blockObj
%        constructor when the Block is being created (not loaded).

%INITIALIZE PARAMETERS
flag = false;
blockObj.checkParallelCompatibility(true);

%CHECK FOR MULTI-ANIMALS
for ii = fieldnames(blockObj.Meta)'
   if contains(blockObj.Meta.(ii{:}),blockObj.Pars.Block.MultiAnimalsChar)
       blockObj.MultiAnimals = true;
       break;
   end
end

%GET/CREATE SAVE LOCATION FOR BLOCK
% blockObj.AnimalLoc is probably empty [] at this point, which will prompt 
% a UI to point to the block save directory:
if ~isempty(blockObj.SaveLoc)
   outLoc = blockObj.SaveLoc;
else
   outLoc = blockObj.AnimalLoc;
end
   
if ~blockObj.getSaveLocation(outLoc)
   flag = false;
   warning('Save location not set successfully.');
   return;
end

%EXTRACT HEADER INFORMATION
header = blockObj.parseHeader();
if ~blockObj.initChannels(header)
   warning('Could not initialize Channels structure headers properly.');
   return;
end

%INITIALIZE VIDEOS STRUCT
if ~blockObj.initVideos
   warning('Could not initialize Videos structure properly.');
   return;
end

%INITIALIZE STREAMS STRUCT
if ~blockObj.initStreams(header)
   warning('Could not initialize Streams structure headers properly.');
   return;
end

%INITIALIZE EVENTS STRUCT
if ~blockObj.initEvents
   warning('Could not initialize Events structure properly.');
   return;
end

%INITIALIZE STATUS
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