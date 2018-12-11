function pars = Probes()
%% PROBES   Template for initializing parameters for probe data
%
%   pars = orgExp.defaults.Probes;
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%%
pars = struct;
[pars.Folder,~,~] = fileparts(mfilename('fullpath'));
pars.File = 'Probes.xlsx';

end