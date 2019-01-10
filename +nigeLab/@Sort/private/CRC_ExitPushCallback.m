function CRC_ExitPushCallback(~,~,obj)
%% CRC_EXITPUSHCALLBACK  Destroy UI and associated handles.
% Destroy UI-associated data
delete(obj);

delete(gcf);

clear all

end