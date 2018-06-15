function tankObj = def_params(tankObj)
%% DEF_PARAMS  Sets default parameters for BLOCK object
%
%  tankObj = DEF_PARAMS(tankObj);
%
% By: Max Murphy  v1.0  06/15/2018  Original version (R2017b)

%% Modify all properties here
tankObj.Default_Tank_Loc = 'R:/Rat'; 
tankObj.Delimiter = '_';
tankObj.BlockNameVars = {'Animal_ID'; ...
                         'Year'; ...
                         'Month'; ...
                         'Day'; ...
                         'Block_ID'};
tankObj.RecType = 'Intan';

end