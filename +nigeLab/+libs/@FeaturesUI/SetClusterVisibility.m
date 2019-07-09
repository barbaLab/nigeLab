function SetClusterVisibility(obj,~,evt)
%% SETCLUSTERVISIBILITY    Set visibility of a specific cluster

%%

if sum(evt.ind2D>0)
   obj.Features2D.Children(evt.ind2D).Visible = evt.state;
   obj.Features3D.Children(evt.ind3D).Visible = evt.state;
   obj.Silhouette.Children(evt.ind2D).Visible = evt.state;
end
obj.VisibleClusters(evt.clus) = evt.val;

obj.isVisible = evt.val;

end