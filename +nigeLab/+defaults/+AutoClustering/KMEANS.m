function pars = KMEANS()

pars.UseGPU = true;
pars.MaxNClus = 9;
pars.NClus = 'max';     % 'best','max'. Best looks for the best number of cluaster
                        % using the criterion specified in pars.criterion.
pars.criterion = 'Silhouette';      % 'CalinskiHarabasz', 'GAP', 'Silhouette', 'DaviesBouldin'                  



end