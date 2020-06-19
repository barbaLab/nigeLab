function pars = ART_HardThresh()
%% function defining defualt parameters for HARD THRESHOLD spike detection algorithm

pars.Thresh     = 50;   % [uV] Fixed voltage threshold for detection;
pars.Samples    = 4;    % [ms] Window to ignore around artifact (suggest: 4 ms MIN for stim rebound) 
end