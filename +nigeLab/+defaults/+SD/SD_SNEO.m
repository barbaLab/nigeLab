function pars = SD_SNEO()
%% function defining defualt parameters for SNEO spike detection algorithm

pars.MultCoeff  = 4.5;  % Multiplication coefficient for noise
pars.SmoothN    = 5;    % Number of samples to use for smoothed nonlinear energy operator window
pars.NSaround   = 7;    % Number of samples around the peak to "look" for negative peak
pars.RefrTime   = 0.5;  % [ms] Refractory time. 
pars.PeakDur    =  1;   % [ms] Peak duration or pulse lifetime period

end