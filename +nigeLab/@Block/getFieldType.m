function [fieldType,n] = getFieldType(blockObj,field)
%GETFIELDTYPE       Return field type corresponding to a field
%
%  fieldType = blockObj.getFieldType(field);
%  [fieldType,n] = blockObj.getFieldType(field);
%
%  --------
%   INPUTS
%  --------
%  blockObj       :     nigeLab.Block class object.
%
%    field        :     String corresponding element of Fields property in
%                          blockObj.
%
%  --------
%   OUTPUT
%  --------
%  fieldType      :     Field type {'Channels';'Streams';'Events';'Videos'}
%                          corresponding to that field.
%
%     n           %     Total number of fields of that type

% Simple code but for readability
idx = strcmpi(blockObj(1).Fields,field);
if sum(idx) == 0
   error('No matching field type: %s',field);
end
fieldType = blockObj(1).FieldType{idx};
if nargout > 1
   idx = ismember(blockObj(1).FieldType,fieldType);
   n = sum(idx);
end

end