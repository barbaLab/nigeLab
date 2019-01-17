function flag = initEvents(blockObj)
%% INITEVENTS  Initialize events struct for nigeLab.Block class object
%
%  flag = INITEVENTS(blockObj);
%
% By: Max Murphy  v1.0  2019/01/11  Original version (R2017a)

%%
flag = false;
blockObj.updateParams('Event');
nEventTypes = numel(blockObj.EventPars.Events);
if nEventTypes == 0
   flag = true;
   disp('No EVENTS to initialize.');
   return;
end

blockObj.Events = buildEventStruct(nEventTypes);
for ii = 1:nEventTypes
   blockObj.Events(ii).name = blockObj.EventPars.Events{ii};
   blockObj.Events(ii).type = blockObj.EventPars.Type(ii);
   blockObj.Events(ii).status = false;
end
flag = true;

   function evtStruct = buildEventStruct(n)
      
      evtStruct = struct(...
         'name',cell(n,1),...
         'type',cell(n,1),...
         'status',cell(n,1)...
         );
   end

end