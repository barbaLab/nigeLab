function [fieldType,n] = getFieldType(blockObj,field)
%% GETFIELDTYPE       Return field type corresponding to a field
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
%
% By: Max Murphy & Federico Barban MAECI 2019 Collaboration

%% DEFAULTS
N_CHARS_TO_COMPARE = 7;

%% Simple code but for readability
idx = strncmpi(blockObj(1).Fields,field,N_CHARS_TO_COMPARE);
if sum(idx) == 0
   error('No matching field type: %s',field);
end
fieldType = blockObj(1).FieldType{idx};
if nargout > 1
   idx = ismember(blockObj(1).FieldType,fieldType);
   n = sum(idx);
end

end