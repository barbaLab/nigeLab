function flag = initEvents(blockObj)
%% INITEVENTS  Initialize events struct for nigeLab.Block class object
%
%  flag = INITEVENTS(blockObj);
%
% By: Max Murphy  v1.0  2019/01/11  Original version (R2017a)

%%
flag = false;
blockObj.updateParams('Event');
[uF,~,iU] = unique(blockObj.EventPars.Fields);
nEventTypes = numel(uF);
if nEventTypes == 0
   flag = true;
   disp('No EVENTS to initialize.');
   return;
end


blockObj.Events = struct;
for ii = 1:nEventTypes
   
   idx = find(iU == ii);
   n = numel(idx);
   blockObj.Events.(uF{ii}) = nigeLab.utils.initChannelStruct('Events',n);
   for u = 1:n
      blockObj.Events.(uF{ii})(u).name = blockObj.EventPars.Events{idx};
      blockObj.Events.(uF{ii})(u).status = false;
   end
end
flag = true;
end