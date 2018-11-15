function [Pars,Fields] = blockDefaults()
%% DEF_PARAMS  Sets default parameters for BLOCK object
%
%  obj = DEF_PARAMS(obj);
%
% By: Max Murphy  v1.0  06/13/2018  Original version (R2017b)

%% Modify all properties here
Pars             = struct;
Pars.SaveFormat  = 'MatFile';
Pars.Delimiter   = '_';
Pars.ProbeChannel= [Pars.Delimiter 'P%s_Ch_%s'];

Fields =  {'Raw';
           'Digital';
           'Filt';
           'CAR';
           'LFP';
           'Spikes';
           'Sorted';
           'Clusters';
           %%%%%%%%%%%%%%%%%%% This names are hardcoded. They are used in
           %%%%%%%%%%%%%%%%%%% the following (Block) functions:
           %%%%%%%%%%%%%%%%%%% convert, extractLFP, filterData, CAR,
           %%%%%%%%%%%%%%%%%%% spikeDetection
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

Del = Pars.Delimiter;
P_C = Pars.ProbeChannel;
for ii=1:numel(Fields)
   Pars.(Fields{ii}).File      = [Del FileNames{ii} P_C];
   Pars.(Fields{ii}).Folder    = FolderNames{ii};
end

end