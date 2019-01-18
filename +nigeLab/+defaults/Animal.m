function pars = Animal()
%% ANIMAL  Template for initializing parameters for nigeLab.Animal class
%
%   pars = nigeLab.defaults.Animal;
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%%
pars = struct;
pars.DefaultRecLoc = 'R:/';
pars.DefaultSaveLoc = 'P:/';
pars.SaveLocPrompt = 'Set Processed Animal Location';
pars.SupportedFormats = {'.rhs','.rhd','tdt'};

end

