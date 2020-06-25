function pars = SD_HardThresh()
%% function defining defualt parameters for HARD THRESHOLD spike detection algorithm

pars.Polarity   = -1;   % polarity of the detection. If positive looks for positive crossings. Negative otherwise. 
pars.Thresh     = 50;   % [uV] Fixed voltage threshold for detection;
pars.RefrTime   = 0.5;  % [ms] Refractory time. 
pars.PeakDur    =  1;   % [ms] Peak duration or pulse lifetime period
pars.NSaround   = 7;
end