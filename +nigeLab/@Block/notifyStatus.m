function notifyStatus(blockObj,field,status,channel)
%NOTIFYSTATUS  Emits the `StatusChanged` event notification to Block
%
%  notifyStatus(blockObj,field,status);
%  notifyStatus(blockObj,field,status,channel);
%
%  channel : (optional) If not specified, then it is assigned the
%                       value 1:numel(status). Otherwise if it is
%                       used, it should be the INDEXING used (not the
%                       channel number e.g. A-022; if A-022 is the
%                       first channel in Channels array, then channel
%                       == 1 is correct).

if nargin < 4
   channel = 1:numel(status);
end

fieldType = blockObj.getFieldType(field);
pubKey = blockObj.getKey();
evt = nigeLab.evt.statusChanged(field,fieldType,pubKey,...
   status,channel);
notify(blockObj,'StatusChanged',evt);
end