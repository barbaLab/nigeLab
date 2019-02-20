function SetCurrentCluster(obj,~,evt)
%% SETCURRENTCLUSTER  Function to set current cluster on event

%%
obj.CurClass = evt.class;
obj.isVisible = evt.visible;

end