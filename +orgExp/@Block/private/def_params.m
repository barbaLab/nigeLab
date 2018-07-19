function blockObj = def_params(blockObj)
%% DEF_PARAMS  Sets default parameters for BLOCK object
%
%  obj = DEF_PARAMS(obj);
%
% By: Max Murphy  v1.0  06/13/2018  Original version (R2017b)

%% Modify all properties here
blockObj.ID             = struct;
blockObj.ID.Delimiter   = '_';
blockObj.ID.ProbeChannel= [blockObj.ID.Delimiter 'P%s_Ch_%s'];

blockObj.Fields =  {'Raw';
                    'Digital';
                    'Filt';
                    'CAR';
                    'LFP';
                    'Spikes';
                    'Sorted';                    
                    'Clusters';
                    };

FileNames       =   {'Raw';
                     '';
                     %{'AAUX1';'AAUX2';'AAUX3';'BAUX1';'BAUX2';'BAUX3';'sync';'user'}
                     'Filt';
                     'FiltCAR';
                     'LFP';
                     'ptrain';
                     'sort';
                     'clus';
                    };
                
FolderNames     =   {'RawData';
                     'Digital';
                     'Filtered';
                     'FilteredCAR';
                     'LFPData';
                     'wav-sneo_CAR_Spikes';
                     'wav-sneo_SPC_CAR_Sorted';
                     'wav-sneo_SPC_CAR_Clusters';
                    };

Del = blockObj.ID.Delimiter;
P_C = blockObj.ID.ProbeChannel;
for ii=1:numel(blockObj.Fields)
   blockObj.ID.(blockObj.Fields{ii}).File      = [Del FileNames{ii} P_C];
   blockObj.ID.(blockObj.Fields{ii}).Folder    = FolderNames{ii};
end

blockObj.Status = false(size(blockObj.Fields));

end