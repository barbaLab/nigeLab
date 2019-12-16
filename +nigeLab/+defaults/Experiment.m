function pars = Experiment()
% EXPERIMENT   Template for initializing experimental metadata notes
%              Importantly, the default behavior for choosing an
%              acquisition system is set here, in case one of the standard
%              initializations goes wrong.
%
%   pars = nigeLab.defaults.Experiment;

%%
pars = struct;
[pars.Folder,~,~] = fileparts(mfilename('fullpath'));
pars.File = 'Experiment.txt';
pars.Delimiter = '|';
pars.StandardPortNames = {'A','B','C','D'};
pars.DefaultAcquisitionSystem = 'RHD';  % Important if things go wrong

end