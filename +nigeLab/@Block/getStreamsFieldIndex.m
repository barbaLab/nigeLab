function [fieldIdx,n] = getStreamsFieldIndex(blockObj,field,type)
%GETSTREAMSFIELDINDEX   Returns indices for each Streams of a given field
%
%  fieldIdx = getStreamsFieldIndex(blockObj,field,type)
%  [fieldIdx,n] = getStreamsFieldIndex(blockObj,field,type)
%
%  --------
%   INPUTS
%  --------
%  blockObj       :     nigeLab.BLOCK class object
%
%   field         :     Member of blockObj.Streams
%
%   type          :     signal.type (original; e.g. 'DAC' etc..)
%
%  --------
%   OUTPUT
%  --------
%  fieldIdx       :     Index to blockObj.Streams(fieldIdx) for all Streams
%                          of a given field.
%
%     n           :     Total number of Streams for 'field'

% Check input
if ~ismember(field,blockObj.Fields)
   error('%s is not a member of Fields property.',field);
end

% Check Streams
if numel(blockObj.Streams) == 0
   fieldIdx = [];
   n = 0;
   return;
end

if ~isfield(blockObj.Streams,field)
   nigeLab.utils.cprintf('UnterminatedStrings*','\t\t->\t[BLOCK]: ');
   nigeLab.utils.cprintf('UnterminatedStrings',...
      'Missing %s field of Streams property struct array.',field);
   error('Check Block.initStreams; Streams not initialized correctly.');
end

% Match field to signal.type
sig = [blockObj.Streams.(field).signal];
[fieldIdx,n] = ismember(sig,type); % function override on signal class


end