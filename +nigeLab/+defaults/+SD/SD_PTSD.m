function pars = SD_PTSD()
%% function defining defualt parameters for SNEO spike detection algorithm

pars.MultCoeff  = 5;  % Multiplication coefficient for noise
% pars.Thresh     = 50;
pars.RefrTime   = 0.5;  % [ms] Refractory time. 
pars.PeakDur    =  2;   % [ms] Peak duration or pulse lifetime period
pars.AlignFlag  = 0; 
end