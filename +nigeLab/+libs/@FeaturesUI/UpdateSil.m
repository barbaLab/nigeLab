function scores = UpdateSil(obj)
curCh = obj.ChannelSelector.Channel;
feat = obj.Data.feat{curCh};
cl = obj.Data.class{curCh};
indx = obj.QualityIndx.UserData{2};
measuretype = obj.QualityIndx.UserData{1};


% activeToUpdate = find(~any(scores,2) & indx');             % find selected distance measures to update 
                                                        % ie those selected in the listbox which 
                                                        % are also zero 
% sil = zeros(numel(activeToUpdate),length(feat));
% for ii=1:numel(activeToUpdate)
NNoiseIdx = cl(obj.rsel);
   scores = silhouette(feat(obj.rsel,:),cl(obj.rsel),measuretype{indx});
% end

obj.SilScores = scores;