function pars = Experiment()
%% EXPERIMENT   Template for initializing experimental metadata notes
%
%   pars = nigeLab.defaults.Experiment;
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%%
pars = struct;
[pars.Folder,~,~] = fileparts(mfilename('fullpath'));
pars.File = 'Experiment.txt';
pars.Delimiter = '|';

end