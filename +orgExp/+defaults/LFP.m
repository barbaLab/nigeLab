function pars = LFP()
%% LFP      Template for initializing parameters related to LFP analysis
%
%   pars = defaults.LFP;
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
pars = struct;
pars.DownSampleFreq=1000;
pars.DecimateCascadeM=[5 3 2];
pars.DecimateCascadeN=[3 5 5];

end

