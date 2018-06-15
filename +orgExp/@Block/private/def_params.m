function blockObj = def_params(blockObj)
%% DEF_PARAMS  Sets default parameters for BLOCK object
%
%  obj = DEF_PARAMS(obj);
%
% By: Max Murphy  v1.0  06/13/2018  Original version (R2017b)

%% Modify all properties here
blockObj.ID = struct;
blockObj.ID.CAR.File = 'FiltCAR';
blockObj.ID.CAR.Folder = 'FilteredCAR';
blockObj.ID.Clusters.File = 'clus';
blockObj.ID.Clusters.Folder = 'wav-sneo_SPC_CAR_Clusters';
blockObj.ID.Delimiter = '_';
blockObj.ID.Digital.File = {'AAUX1';'AAUX2';'AAUX3'; ...
                       'BAUX1';'BAUX2';'BAUX3'; ...
                       'sync';'user'};
blockObj.ID.Digital.Folder = 'Digital';
blockObj.ID.DS.File = 'DS';
blockObj.ID.DS.Folder = 'DS';
blockObj.ID.Filt.File = 'Filt';
blockObj.ID.Filt.Folder = 'Filtered';
blockObj.ID.MEM.File = 'MEM';
blockObj.ID.MEM.Folder = 'MEM';
blockObj.ID.Raw.File = 'Raw_';
blockObj.ID.Raw.Folder = 'RawData';
blockObj.ID.Spikes.File = 'ptrain';
blockObj.ID.Spikes.Folder = 'wav-sneo_CAR_Spikes';
blockObj.ID.Sorted.File = 'sort';
blockObj.ID.Sorted.Folder = 'wav-sneo_SPC_CAR_Sorted';

blockObj.Fields = {'CAR'; ...
              'Clusters'; ...
              'Digital'; ...
              'DS'; ...
              'Filt'; ...
              'MEM'; ...
              'Raw'; ...
              'Sorted'; ...
              'Spikes'};
           
blockObj.Status = false(size(blockObj.Fields));

end