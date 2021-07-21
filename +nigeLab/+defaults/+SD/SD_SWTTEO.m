function pars = SD_SWTTEO()
%% function defining defualt parameters for SWTTEO spike detection algorithm
pars.wavLevel   = 2;                % Wavelet decomposition level
pars.waveName    = 'sym6';           % wavelet type

pars.winType    = @hamming;        % function handle for the smoothing window type; This is fed to window function
pars.smoothN    = 25;              % Number of samples for the smoothing operator. Set to 0 to turn off smoothing
pars.winPars    = {'symmetric'};    % Optional parameters for the smoothing window

pars.RefrTime   = 1;                 % [ms] refractory time
pars.MultCoeff  = 6;               % Moltiplication coefficient for SWTTEO thresholding
pars.Polarity   = -1;
pars.PeakDur    =  2.5;   % [ms] Peak duration or pulse lifetime period


end