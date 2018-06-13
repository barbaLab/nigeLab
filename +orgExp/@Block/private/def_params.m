function obj = def_params(obj)
%% DEF_PARAMS  Sets default parameters for BLOCK object
%
%  obj = DEF_PARAMS(obj);
%
% By: Max Murphy  v1.0  06/13/2018  Original version (R2017b)

%% Modify all properties here
obj.ID = struct;
obj.ID.CAR.File = 'FiltCAR';
obj.ID.CAR.Folder = 'FilteredCAR';
obj.ID.Clusters.File = 'clus';
obj.ID.Clusters.Folder = 'wav-sneo_SPC_CAR_Clusters';
obj.ID.Delimiter = '_';
obj.ID.Digital.File = {'AAUX1';'AAUX2';'AAUX3'; ...
                       'BAUX1';'BAUX2';'BAUX3'; ...
                       'sync';'user'};
obj.ID.Digital.Folder = 'Digital';
obj.ID.DS.File = 'DS';
obj.ID.DS.Folder = 'DS';
obj.ID.Filt.File = 'Filt';
obj.ID.Filt.Folder = 'FiltData';
obj.ID.MEM.File = 'MEM';
obj.ID.MEM.Folder = 'MEM';
obj.ID.Raw.File = 'Raw_';
obj.ID.Raw.Folder = 'RawData';
obj.ID.Spikes.File = 'ptrain';
obj.ID.Spikes.Folder = 'wav-sneo_CAR_Spikes';
obj.ID.Sorted.File = 'sort';
obj.ID.Sorted.Folder = 'wav-sneo_SPC_CAR_Sorted';

obj.Fields = {'CAR'; ...
              'Clusters'; ...
              'Digital'; ...
              'DS'; ...
              'Filt'; ...
              'MEM'; ...
              'Raw'; ...
              'Sorted'; ...
              'Spikes'};
           
obj.Status = false(size(obj.Fields));

end