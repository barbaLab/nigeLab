function pars = ART_HardThresh()
%% function defining defualt parameters for HARD THRESHOLD spike detection algorithm

pars.Thresh     = 70;   % [uV] Fixed voltage threshold for detection;
pars.Samples    = 4;    % [ms] Window to ignore around artifact (suggest: 4 ms MIN for stim rebound) 

pars.Polarity   = 1;

end