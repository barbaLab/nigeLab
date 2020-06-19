function pars = SD_AdaptThresh()
%% function defining defualt parameters for SNEO spike detection algorithm

pars.FilterLength   = 60;   % [ms] Length of the adaptive filter window
pars.Polarity       = -1;   % polarity of the detection. If positive looks for positive crossings. Negative otherwise. 
pars.MinThresh      = 15;   % [uV] Fixed minimum voltage threshold for detection;
pars.MultCoeff      = 4.5;  % moltiplicative factor for the adaptive threshold (signal absolute median);
pars.RefrTime       = 0.5;  % [ms] Refractory time. 
pars.PeakDur        =  1;   % [ms] Peak duration or pulse lifetime period
end
