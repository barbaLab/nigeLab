function pars = Probe()
%% PROBE   Template for initializing parameters for probe data
%
%   pars = nigeLab.defaults.Probe;
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%%
pars = struct;
[pars.Folder,~,~] = fileparts(mfilename('fullpath'));
pars.File = 'Probes.xlsx';
pars.Str = '%s.xlsx';
pars.Delimiter = '_';
pars.ElectrodesFolder = 'K:\Rat\Electrodes';
pars.ProbeIndexParseFcn = @(str)(str2double(str(2))-1);

end