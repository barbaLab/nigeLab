function pars = LFP()
%% LFP      Template for initializing parameters related to LFP analysis
%
%   pars = nigeLab.defaults.LFP;

%% CAN CHANGE
pars = struct;
pars.DecimateCascadeM=[5 3 2]; % Decimation factor
pars.DecimateCascadeN=[3 5 5]; % Chebyshev LPF order

%% DO NOT CHANGE
pars.DecimationFactor=prod(pars.DecimateCascadeM);

end

