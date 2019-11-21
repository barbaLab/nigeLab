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
   if contains(meta.(ii{:}),blockObj.ManyAnimalsChar)
       blockObj.ManyAnimals = true;
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

% Prior to link to data, check if a function handle for conversion has been
% specified; if so, then do the conversion FIRST, then link it to data.
if ~isempty(blockObj.MatFileWorkflow.ConvertFcn)
   % Give the opportunity to cancel 
   % (function handle can just be configured to [] once Block has been 
   %  "converted" the first time)
   printWarningLoop(3);
   % If not canceled yet, run conversion
   blockObj.MatFileWorkflow.ConvertFcn(blockObj.RecFile,...
      blockObj.AnimalLoc,...
      blockObj.BlockPars);
end


% Link to data and save
flag = blockObj.linkToData(true);
if ~flag
   nigeLab.utils.cprintf('UnterminatedStrings',...
      'Could not successfully link %s to data.',blockObj.Name);
end
   
   function printWarningLoop(nsec)
      % PRINTWARNINGLOOP  Warning function to count down before conversion
      if nargin < 1
         nsec = 10;
      end
      fprintf(1,' \n');
      nigeLab.utils.cprintf('Blue','-->\tRunning CONVERSION in ');
      nigeLab.utils.cprintf('UnterminatedStrings','%02gs\n',nsec);
      pause('on');
      for i = nsec:-1:1
         nigeLab.utils.cprintf('UnterminatedStrings','\b\b\b\b%02gs\n',i);
         pause(1);
      end
   end

end