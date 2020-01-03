function pars = Tank()
%TANK  Template for initializing parameters for nigeLab.Tank class
%
%   pars = nigeLab.defaults.Tank;

pars = struct;
pars.BlockNameVars = {'Animal_ID'; ...
                         'Year'; ...
                         'Month'; ...
                         'Day'; ...
                         'Block_ID'};
pars.CheckBeforeConversion = true;
pars.DefaultSaveLoc = 'C:\Users\Fede\Documents\Eperiments\Alberto\Extracted_Data_To_Move';
pars.DefaultTankLoc = 'C:\Users\Fede\Documents\Eperiments\Alberto\RAW';
pars.Delimiter = '_';
pars.RecType = 'Intan';
pars.ParallelFlag = 'Local pool';
pars.SupportedFormats = {'rhs','rhd','tdt'};
pars.FolderIdentifier = '.nigelTank';

end

