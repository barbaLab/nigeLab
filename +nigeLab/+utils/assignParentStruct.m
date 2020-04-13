function obj = assignParentStruct(obj,loadedObj_,parent)
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

if numel(loadedObj_) > 1
   sz_ = size(loadedObj_);
   h = obj(1);
   obj = repmat(h,sz_);
   for iIn = 1:numel(loadedObj_)
      obj(iIn) = copy(h); % So they are not the same pointer
      obj(iIn) = assignParentStruct(obj(iIn),loadedObj_(iIn),parent);
   end
   if isvalid(h)
      delete(h);
   end   
   return;   
end


nigeLab.utils.cprintf('Comments*','Loading %s from struct...\n',class(obj));



% This could happen, for example if the VideosFieldType object 
% had an error during loadobj and was returned as a struct
% through loadobj
mc = ?obj;
metaPropList = {mc.PropertyList.Name};
f = setdiff(fieldnames(loadedObj_),'Parent');

for i = 1:numel(f)
   idx = ismember(metaPropList,f{i});
   if sum(idx)==1
      if strcmp(mc.PropertyList(idx).SetAccess,'public')
         obj.(metaPropList{idx})=loadedObj_.(metaPropList{idx});
      end
   end
end
obj.Parent = parent;


end