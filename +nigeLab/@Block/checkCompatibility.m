function fieldIdx = checkCompatibility(blockObj,requiredFields)
% CHECKCOMPATIBILITY  Checks if Block is compatible with "required fields"
%
%  blockObj = nigeLab.Block;
%  fieldIdx = blockObj.CHECKCOMPATIBILITY('FieldName');
%  fieldIdx = blockObj.CHECKCOMPATIBILITY({'FieldName1','FieldName2',...,'FieldNameK'});
%
%  A way to add a hard-coded check for compatibility 
%  (for example, for ad hoc functions such as those in nigeLab.workflow)
%  that will throw an error pointing to the missing fields. This can be
%  added to an ad hoc function to make it easier to fix configurations for
%  that particular ad hoc function.
%
%  Returns fieldIdx, the index into blockObj.Fields for each element of
%  requiredFields (if no error is thrown).
%
%  See Also:
%  NIGELAB.BLOCK/CHECKACTIONISVALID,
%  NIGELAB.BLOCK/CHECKPARALLELCOMPATIBILITY

%%
% Could add parsing here to allow requiredFields to be a 'config' class or
% something like that, or whatever, that allows it to load in a set of
% fields from a saved matfile to do the comparison against, as well.

%%
if isempty(requiredFields)
   warning('blockObj.checkCompatibility was called on empty requiredFields, suggesting something is wrong.');
   fieldIdx = [];
   return;
end

if numel(blockObj) > 1
   fieldIdx = cell(size(blockObj));
   for i = 1:numel(blockObj)
      fieldIdx{i} = blockObj(i).checkCompatibility(requiredFields);
   end
   return;
end

%%
idx = find(~ismember(requiredFields,blockObj.Fields));
if isempty(idx)
   if ischar(requiredFields)
      fieldIdx = find(ismember(blockObj.Fields,requiredFields),1,'first');
   elseif iscell(requiredFields)
      fieldIdx = nan(size(requiredFields));
      for i = 1:numel(fieldIdx)
         fieldIdx(i) = ...
            find(ismember(blockObj.Fields,requiredFields{i}),1,'first');
      end
   end
   return;
end

nigeLab.utils.cprintf('UnterminatedStrings',...
   '%s: missing following Fields...',...
   blockObj.Name);
for i = 1:numel(idx)
   nigeLab.utils.cprintf('Strings',...
   '-->\t%s\n',...
   requiredFields{idx(i)});
end
error('Missing required Fields. Check nigeLab.defaults.Block');


end