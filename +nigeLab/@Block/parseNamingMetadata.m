function meta = parseNamingMetadata(blockObj)
% PARSENAMINGMETADATA  Parse metadata from name of block object
%
%  meta = PARSENAMINGMETADATA(blockObj);
%
%  --------
%   INPUTS
%  --------
%  blockObj       :     nigeLab.Block class object.
%
%  --------
%   OUTPUT
%  --------
%    meta         :     Struct containing metadata parsed from name of file
%                          containing the binary data from a given
%                          recording session.
%
%  This method also updates the blockObj.Meta field.

%%
% Parse name and extension. "nameParts" contains parsed variable strings:
[pname,fName,blockObj.FileExt] = fileparts(blockObj.RecFile);
if strcmp(blockObj.FileExt,blockObj.FolderIdentifier)
   [~,fName,~] = fileparts(pname);  % Go back one level
end
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
incVarIdx = find(cellfun(@(x) x(1)==blockObj.IncludeChar,splitStr));
incVarIdx = reshape(incVarIdx,1,numel(incVarIdx));

% Find which set of variables (the total number available from the name, or
% the number set to be read dynamically from the naming convention) has
% fewer elements, and use that to determine how many loop iterations there
% are:
nMin = min(numel(incVarIdx),numel(nameParts));

% Create a struct to allow creation of dynamic variable name dictionary.
% Make sure to iterate on 'splitStr', and not 'nameParts,' because variable
% assignment should be decided by the string in namingConvention property.
meta = struct;
for ii=1:nMin 
   splitStrIdx = incVarIdx(ii);
   varName = deblank( splitStr{splitStrIdx}(2:end));
   meta.(varName) = nameParts{incVarIdx(ii)};
end

% If Recording_date isn't one of the specified "template" variables from
% namingConvention property, then parse it from Year, Month, and Day. This
% will be helpful for handling file names for TDT recording blocks, which
% don't automatically append the Rec_date and Rec_time strings:
f = fieldnames(meta);
if sum(ismember(f,{'RecDate'})) < 1
   if isfield(meta,'Year') && ...
      isfield(meta,'Month') && ...
      isfield(meta,'Day')
      YY = meta.Year((end-1):end);
      MM = meta.Month;
      DD = sprintf('%.2d',str2double(meta.Day));
      meta.RecDate = [YY MM DD];
   else
      meta.RecDate = 'YYMMDD';
      nigeLab.utils.cprintf('UnterminatedStrings','Unable to parse date from BLOCK name (%s).\n',fName);
   end
end

% Similarly, if recording_time is empty, still keep it as a field in
% metadata associated with the BLOCK.
if sum(ismember(f,{'RecTime'})) < 1
   meta.RecTime = 'hhmmss';
end

blockObj.Meta = meta;
end