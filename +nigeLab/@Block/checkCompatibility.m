function checkCompatibility(blockObj,requiredFields)
%% CHECKCOMPATIBILITY  Checks if Block is compatible with "required fields"
%
%  blockObj = nigeLab.Block;
%  blockObj.CHECKCOMPATIBILITY({'Field1','Field2',...,'FieldK'});
%
%  A way to add a hard-coded check for compatibility 
%  (for example, for ad hoc functions such as those in nigeLab.workflow)
%  that will throw an error pointing to the missing fields. This can be
%  added to an ad hoc function to make it easier to fix configurations for
%  that particular ad hoc function.

%%
% Could add parsing here to allow requiredFields to be a 'config' class or
% something like that, or whatever, that allows it to load in a set of
% fields from a saved matfile to do the comparison against, as well.

if numel(blockObj) > 1
   for i = 1:numel(blockObj)
      blockObj(i).checkCompatibility(requiredFields);
   end
   return;
end

%%
idx = find(~ismember(requiredFields,blockObj.Fields));
if isempty(idx)
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