function f = getParamField(p,name)
% GETPARAMFIELD  f = utlis.getParamField(p,'paramName');
%
% Helper function to return field value (if matched string-insensitive
% field exists) or else returns empty (if not matched)
%
% By: Max Murphy  v1.0  2019-11-12

%%
f = [];

if isfield(p,name)
   f = p.(name);
   return;
end

fnames = fieldnames(p);
idx = ismember(lower(name),lower(fnames));
if any(idx)
   name = fnames(idx);
   p = utils.setParamField(p,name);
   return;
end
end