function pars = Sync()
%SYNC      Template for initializing parameters related to experiment trigger synchronization
%
%   pars = nigeLab.defaults.Sync;

%%
pars = struct;
pars.DeBounce = 250;    % de-bounce time (milliseconds)
pars.ID = 'sync';       % file identifier (for digital input file)

end

