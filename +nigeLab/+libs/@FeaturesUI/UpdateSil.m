function scores = UpdateSil(obj)
curCh = obj.ChannelSelector.Channel;
feat = obj.Data.feat{curCh};
cl = obj.Data.class{curCh};
indx = obj.QualityIndx.UserData{2};
measuretype = obj.QualityIndx.UserData{1};

scores=obj.SilScores;
activeToUpdate = find(~any(scores,2) & indx');             % find selected distance measures to update 
                                                        % ie those selected in the listbox which 
                                                        % are also zero 
sil = zeros(numel(activeToUpdate),length(feat));
for ii=1:numel(activeToUpdate)
   sil(ii,:)=silhouette(feat,cl,measuretype{activeToUpdate(ii)});
end

for jj=1:numel(activeToUpdate)
   for ii=unique(cl)'
      scores(activeToUpdate(jj),ii)=mean(sil(jj,cl==ii));
   end
end
obj.SilScores = scores;