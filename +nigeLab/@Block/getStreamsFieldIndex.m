function [fieldIdx,n] = getStreamsFieldIndex(blockObj,field)
%% GETFIELDTYPEINDEX    Returns indices for each Streams of a given field
%
%  fieldIdx = getStreamsFieldIndex(blockObj,field)
%  [fieldIdx,n] = getStreamsFieldIndex(blockObj,field)
%
%  --------
%   INPUTS
%  --------
%  blockObj       :     nigeLab.BLOCK class object
%
%   field         :     Member of blockObj.Fields
%
%  --------
%   OUTPUT
%  --------
%  fieldIdx       :     Index to blockObj.Streams(fieldIdx) for all Streams
%                          of a given field.
%
%     n           :     Total number of Streams for 'field'

%% Check input
if ~ismember(field,blockObj.Fields)
   error('%s is not a member of ViableFieldTypes property.',field);
end

%% Check Streams
if numel(blockObj.Streams) == 0
   fieldIdx = [];
   n = 0;
   return;
end

%% Match field to Streams.signal_type
streamFields = {blockObj.Streams.signal_type}.';
fieldIdx = ismember(streamFields,field);
n = sum(fieldIdx);


end