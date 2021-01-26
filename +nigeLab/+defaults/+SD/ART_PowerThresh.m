function pars = ART_PowerThresh()
%% function defining defualt parameters for POWER THRESHOLD artefact rejection algorithm

pars.MultCoeff  = 25;   % [V^2] Fixed power threshold for detection;
pars.Samples    = 1;   % [ms] Window to ignore around artifact 
                       % (suggest: 4 ms MIN for stim rebound) 


pars.winType    = @hamming;        % function handle for the detection 
                                   % window type; This is fed to window 
                                   % function.
pars.winL       = 0.05;   % [s] Length for the window detection.
pars.winPars    = {};    % Optional parameters for the detection window.
pars.Polarity   = 1;     % Sign of the signal to take into account;
                         % If positive it only computes the power of the 
                         % positive part of the signal, if negative of the 
                         % negative part. To use the whole signal, set this
                         % to 0.
end