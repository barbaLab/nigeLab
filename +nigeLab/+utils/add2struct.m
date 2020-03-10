function augmentedStruct = add2struct(structToKeep,structToAdd,nameKey)
%ADD2STRUCT  Adds fields of `structToAdd` into `structToKeep`
%
%  augmentedStruct = nigeLab.utils.add2struct(structToKeep,structToAdd);
%  augmentedStruct = nigeLab.utils.add2struct(__,nameKey);
%
%  -- inputs --
%  structToKeep : Struct with fields you want to keep or add to
%  structToAdd  : Struct with fields whose values you want to use to
%                    "expand" or "update" `structToKeep`
%                 --> If a field is already present in `structToKeep`, it
%                       is overwritten.
%  nameKey : Struct that matches fields of `structToAdd` (field names of
%              `nameKey`) into `structToKeep` (field values of `nameKey`)
%           --> If not specified, the fieldnames of `structToAdd` are used
%                 directly
%  
%  -- output --
%  augmentedStruct : `structToKeep` with updated data from `structToAdd`

% If `structToAdd` has nothing to add, then simply return `structToKeep`
augmentedStruct = structToKeep;
f = fieldnames(structToAdd);
if isempty(f)
   return;
end
% If `structToKeep` has nothing in it, return `structToAdd` unless
% `nameKey` is present (in which case we may want to "rename" fields)
g = fieldnames(structToKeep);
if isempty(g)
   if nargin < 3
      augmentedStruct = structToAdd;
      return;
   end
end
% If `nameKey` is not present, then parse struct from fieldnames of
% `structToAdd` only.
if nargin < 3
   f = reshape(f,1,numel(f));
   fieldValuePairs = [f; f];
   nameKey = struct(fieldValuePairs{:});
end

% Iterate on field names of `structToAdd`, using `nameKey` to match the
% appropriate fieldname from `structToAdd` to the desired field of
% `structToKeep`
for i = 1:numel(f)
   augmentedStruct.(nameKey.(f{i})) = structToAdd.(f{i});
end

end