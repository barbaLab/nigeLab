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

%% PARSE NAME INFO
% Set flag for output if something goes wrong
flag = false; 

% Parse name and extension. "nameParts" contains parsed variable strings:
[dName,fName,blockObj.FileExt] = fileparts(blockObj.RecFile);
nameParts=strsplit(fName,[blockObj.Delimiter {'.'}]);

% Parse variables from defaults.Block "template," which match delimited
% elements of block recording name:
regExpStr = sprintf('\\%c\\w*|\\%c\\w*',...
   blockObj.IncludeChar,...
   blockObj.DiscardChar);
splitStr = regexp(blockObj.DynamicVarExp,regExpStr,'match');

% Find which delimited elements correspond to variables that should be 
% included by looking at the leading character from the defaults.Block
% template string:
incVarIdx = find(cellfun(@(x) x(1)=='$',splitStr));
incVarIdx = reshape(incVarIdx,1,numel(incVarIdx));

% Find which set of variables (the total number available from the name, or
% the number set to be read dynamically from the naming convention) has
% fewer elements, and use that to determine how many loop iterations there
% are:
nMin = min(numel(incVarIdx),numel(nameParts));

% Create a struct to allow creation of dynamic variable name dictionary.
% Make sure to iterate on 'splitStr', and not 'nameParts,' because variable
% assignment should be decided by the string in namingConvention property.
dynamicVars = struct;
for ii=1:nMin 
   splitStrIdx = incVarIdx(ii);
   varName = deblank( splitStr{splitStrIdx}(2:end));
   dynamicVars.(varName) = nameParts{incVarIdx(ii)};
end

% If Recording_date isn't one of the specified "template" variables from
% namingConvention property, then parse it from Year, Month, and Day. This
% will be helpful for handling file names for TDT recording blocks, which
% don't automatically append the Rec_date and Rec_time strings:
f = fieldnames(dynamicVars);
if sum(ismember(f,{'Rec_date'})) < 1
   if isfield(dynamicVars,'Year') && ...
      isfield(dynamicVars,'Month') && ...
      isfield(dynamicVars,'Day')
      YY = dynamicVars.Year((end-1):end);
      MM = dynamicVars.Month;
      DD = sprintf('%.2d',str2double(dynamicVars.Day));
      dynamicVars.RecDate = [YY MM DD];
   else
      dynamicVars.RecDate = 'YYMMDD';
      warning('Unable to parse date from BLOCK name (%s).',fName);
   end
end

% Similarly, if recording_time is empty, still keep it as a field in
% metadata associated with the BLOCK.
if sum(ismember(f,{'Rec_time'})) < 1
   dynamicVars.RecTime = 'hhmmss';
end

blockObj.Meta = dynamicVars;

%% PARSE FILE NAME USING THE NAMING CONVENTION FROM TEMPLATE
str = [];
nameCon = blockObj.NamingConvention;
for ii = 1:numel(nameCon)
   if isfield(dynamicVars,nameCon{ii})
      str = [str, ...
         dynamicVars.(nameCon{ii}),...
         blockObj.Delimiter]; %#ok<AGROW>
   end
end
blockObj.Name = str(1:(end-1));

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
   warning('Could not successfully link %s to data.',blockObj.Name);
end
   

end