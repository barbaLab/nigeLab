function p = setParamField(p,name,val)
% SETPARAMFIELD  p = utils.setParamField(p,'paramName',paramValue);
%
%  Helper function to set field value 
%     (if matched string-insensitive field exists)
%
% By: Max Murphy  v1.0  2019-11-12

%% SET FIELD IF EXACT MATCH
if isfield(p,name)
   p.(name) = val;
   return;
end

%% SEARCH AND SET FIELD IF CASE-INSENSITIVE MATCH
fnames = fieldnames(p);
idx = ismember(lower(name),lower(fnames));
if any(idx)
   name = fnames(idx);
   p = utils.setParamField(p,name,val);
   return;
end

%% OTHERWISE NOTIFY USER
fprintf(1,'Unmatched field of input struct ''%s'': %s\n',inputname(1),name);

end