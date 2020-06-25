function pars = SD_WTEO()
%% function defining defualt parameters for WTEO spike detection algorithm

pars.multcoeff  = 4.5;  % Multiplication coefficient for noise
pars.smoothN    = 5;    % Number of samples to use for smoothed nonlinear energy operator window
pars.nsaround   = 7;    % Number of samples around the peak to "look" for negative peak

end