function pars = SD_TIFCO()
%% function defining defualt parameters for TIFCO spike detection algorithm
pars.fMin = 300;               % [Hz] lower bound for the gabor based time frequency decomposition
pars.fMax = 3500;               % [Hz] higher bound for the gabor based time frequency decomposition

pars.winType    = @hamming;        % function handle for the smoothing window type; This is fed to window function
pars.winL       = 1;              % [s] Length for the time-frequency window decomposition
pars.winPars    = {'symmetric'};    % Optional parameters for the smoothing window

pars.RefrTime  = 1;                 % [ms] refractory time
pars.MultCoeff  = 4.5;  % Multiplication coefficient for noise
pars.Polarity   = -1;   % Detection polarity (look for positive or negative peaks)
pars.PeakDur    =  1;   % [ms] Peak duration or pulse lifetime period

end