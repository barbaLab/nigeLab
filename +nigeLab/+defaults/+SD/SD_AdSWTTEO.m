function pars = SD_AdSWTTEO()
%% function defining defualt parameters for AdSWTTEO spike detection algorithm
pars.wavLevel   = 2;                % Wavelet decomposition level
pars.waveName    = 'sym5';           % wavelet type

pars.winType    = @hamming;        % function handle for the smoothing window type; This is fed to window function
pars.smoothN    = 1;              % [ms] for the smoothing operator. Set to 0 to turn off smoothing
pars.winPars    = {'symmetric'};    % Optional parameters for the smoothing window

pars.RefrTime   = 0.5;                 % [ms] refractory time
pars.MultCoeff  = 6;               % Moltiplication coefficient for SWTTEO thresholding
pars.Polarity   = -1;
pars.PeakDur    =  2.3;   % [ms] Max peak duration or pulse lifetime period
pars.medWdw     = 0.003;   % [s] Length of the window to compute the moving quantile
pars.k          = 3;       %number of samples for the TEO
pars.overshoot  = 0.0007;  % [s] length of the secondary window for the boundary control
end