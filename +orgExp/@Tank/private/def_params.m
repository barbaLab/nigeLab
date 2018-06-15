function tankObj = def_params(tankObj)
%% DEF_PARAMS  Sets default parameters for BLOCK object
%
%  tankObj = DEF_PARAMS(tankObj);
%
% By: Max Murphy  v1.0  06/15/2018  Original version (R2017b)

%% Modify default private properties here
tankObj.BlockNameVars = {'Animal_ID'; ...
                         'Year'; ...
                         'Month'; ...
                         'Day'; ...
                         'Block_ID'};
tankObj.CheckBeforeConversion = true;
tankObj.DefaultSaveLoc = 'P:/Extracted_Data_To_Move/Rat';
tankObj.DefaultTankLoc = 'R:/Rat'; 
tankObj.Delimiter = '_';
tankObj.RecType = 'Intan';

end