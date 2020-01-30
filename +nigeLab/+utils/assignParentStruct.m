function h = assignParentStruct(obj,loadedObj_,parent)
%ASSIGNPARENTSTRUCT  Utility to assign parent when load creates a struct
%
%  h = nigeLab.utils.assignParentStruct(obj,loadedObj_,parent);
%
%  Example use case:
%
%  obj = nigeLab.utils.assignParentStruct(obj,loadedObj_,blockObj);
%
%  --> Taken from the `nigeLab.libs.VideosFieldType` constructor
%
%     obj : The VideosFieldType object under construction (in this example)
%     loadedObj_ : The struct version of loaded VideosFieldType object
%     blockObj : "Parent" object that is `Transient` in VideosFieldType
%  
%  * NOTE * Requires a 'Parent' property (or dependent, `Settable` property
%           named 'Parent' that sets the correct property)

nigeLab.utils.cprintf('Comments*','Loading %s from struct...\n',class(obj));

% This could happen, for example if the VideosFieldType object 
% had an error during loadobj and was returned as a struct
% through loadobj
mc = ?obj;
metaPropList = {mc.PropertyList.Name};
f = setdiff(fieldnames(loadedObj_),'Parent');
h = repmat(obj,size(loadedObj_));
for iIn = 1:numel(loadedObj_)
   h(iIn) = copy(obj(1)); % So they are not the same pointer
   for i = 1:numel(f)
      idx = ismember(metaPropList,f{i});
      if sum(idx)==1
         h(iIn).(metaPropList{idx})=loadedObj_(iIn).(metaPropList{idx});
      end
   end
   h(iIn).Parent = parent;
end

end