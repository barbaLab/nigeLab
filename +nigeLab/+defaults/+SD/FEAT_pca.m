function pars = FEAT_pca()
%% function defining defualt parameters for PCA based feature extraction
pars.ExplVar        = .95;      % Explained Variance to retain durin PCA 
                                % decomposition.
                                % Takes precedence over NOut. Set to Inf to
                                % use NOut.
                                
pars.NOut           = 12;       % Number of feature inputs for clustering.            

end