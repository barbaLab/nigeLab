function PlotQuality(obj)
%% PLOTFEATURES  Plot cluster features from SORT UI in 3D and 2D.

set(obj.Figure,'Pointer','watch');
obj.UpdateSil;
indx = obj.QualityIndx.UserData{2};

% Loop through each subset of 3 features
cla(obj.Silhouette);
for ii=1:obj.NCLUS_MAX
   if ii==1
      col = [0.15 0.15 0.15];
   else
      col= obj.COLS{ii};
   end
   I=0.5:1/sum(indx)/2:1.5;
   I=I(2:2:end)+ii-1;
   bar(obj.Silhouette,I,obj.SilScores(indx,ii)',1,'FaceColor',col);
end

ylim(obj.Silhouette,[-.5 .5]);

set(obj.Figure,'Pointer','arrow');

end
