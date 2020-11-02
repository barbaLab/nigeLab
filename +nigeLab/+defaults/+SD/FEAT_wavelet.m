function pars = FEAT_wavelet()
%% function defining defualt parameters for wavelet feature extraction

pars.WaveName       = 'bior1.3';                % 'haar' 'bior1.3' 'db4' 'sym8' all examples
[pars.LoD,pars.HiD] = wfilters(pars.WaveName);  % get wavelet decomposition parameters
pars.NOut           = 12;                       % Number of feature inputs for clustering
pars.NScales        = 3;                        % Number of scales for wavelet decomposition
% 

end