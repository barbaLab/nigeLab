function [fieldIdx,n] = getFieldTypeIndex(blockObj,fieldType)
%% GETFIELDTYPEINDEX    Returns indices to all fields of a given type
%
%  fieldIdx = getFieldTypeIndex(blockObj,fieldType)
%  [fieldIdx,n] = getFieldTypeIndex(blockObj,fieldType)
%
%  --------
%   INPUTS
%  --------
%  blockObj       :     nigeLab.BLOCK class object
%
%  fieldType      :     Member of {'Channels','Streams','Events','Meta', or
%                                   'Videos'}.
%
%  --------
%   OUTPUT
%  --------
%  fieldIdx       :     Indexing array for all fields of 'fieldType'
%
%     n           :     Total number of fields of type 'fieldType'

%% Check input
if ~ismember(fieldType,blockObj.Pars.Block.ViableFieldTypes)
   error('%s is not a member of ViableFieldTypes property.',fieldType);
end

%%
fieldIdx = ismember(blockObj.FieldType,fieldType);
n = sum(fieldIdx);


end