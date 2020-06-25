function pars = SD_SWTTEO()
%% function defining defualt parameters for SWTTEO spike detection algorithm
pars.wavLevel   = 2;                % Wavelet decomposition level
pars.waveName    = 'sym5';           % wavelet type

pars.winType    = @hamming;        % function handle for the smoothing window type; This is fed to window function
pars.smoothN    = 40;              % Number of samples for the smoothing operator. Set to 0 to turn off smoothing
pars.winPars    = {'symmetric'};    % Optional parameters for the smoothing window

pars.RefrTime   = 1;                 % [ms] refractory time
pars.MultCoeff  = 3;               % Moltiplication coefficient for SWTTEO thresholding
pars.Polarity   = -1;
pars.PeakDur    =  1;   % [ms] Peak duration or pulse lifetime period


%% Extracting filters from wavelet name
pars.lo_D = wfilters(pars.waveName);
end