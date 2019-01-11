function flag = initEvents(blockObj)
%% INITEVENTS  Initialize events struct for nigeLab.Block class object
%
%  flag = INITEVENTS(blockObj);
%
% By: Max Murphy  v1.0  2019/01/11  Original version (R2017a)

%%
flag = false;
blockObj.updateParams('Event');
blockObj.Events = struct;
for ii = 1:numel(blockObj.EventPars.Events)
   blockObj.Events.(blockObj.EventPars.Events{ii}) = struct;
   blockObj.Events.(blockObj.EventPars.Events{ii}).type = ...
      blockObj.EventPars.Type(ii);
   evtFields = blockObj.EventPars.TypeID{blockObj.EventPars.Type(ii)};
   for ik = 1:numel(evtFields)
      blockObj.Events.(blockObj.EventPars.Events{ii}).(evtFields{ik}) = [];
   end
end
flag = true;

end