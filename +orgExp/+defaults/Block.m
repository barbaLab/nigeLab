function [Pars,Fields] = Block()
%% defaults.Block  Sets default parameters for BLOCK object
%
%  [Pars,Fields] = defaults.Block();
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)


%% Modify all properties here
%     'CH_ID' : (def: 'Ch') If you have a different file name
%               identifier that precedes the channel number for
%               that particular file, specify this on object
%               construction.
%     'Def' : (def: 'P:/Rat') If you are using the UI selection
%              interface a lot, and typically working with a more
%              specific project directory, you can specify this to
%              change where the default UI selection directory
%              starts. Alternatively, just change the property in
%              the code under private properties.         
         
% Define general values used when parsing metadata from file name and
% structure:
Pars             = struct;
Pars.DEF         = 'R:\Rat';
Pars.SaveFormat  = 'Hybrid'; % refers to save/load format
Pars.Delimiter   = '_';      % delimiter for variables in BLOCK name
CH_ID = 'Ch'; % precedes the channel number delimited variable
Pars.ProbeChannel= [Pars.Delimiter 'P%s_' CH_ID '_%s'];

%% Here You can specify the naming format of your block recording
% The block name will be splitted using Delimiter (defined above) and each
% segment will be assigned to the property definied here. 
% Using namingConvention you can define to what varible each piece of the
% block name should be assigned to. Use the includeChar and discardChar to
% specify if that piece of info should be kept or discarded.
% The word after a discardChar will be ignored.
% e.g. the recording name R18-68_2018_07_24_0_180724_141203
% translates to 
% Pars.namingConvention='$Corresponding_animal &YEAR &MONTH &DAY $Recording_ID $Recording_date $Recording_time';
% Pars.includeChar='$';
% Pars.discardChar='&';

Pars.namingConvention='$Corresponding_animal $YEAR $MONTH $DAY $Recording_ID';
% namingConvention='$Corresponding_animal $Recording_ID $Recording_date$$Recording_time$';

Pars.includeChar='$';
Pars.discardChar='&';

%% 
Fields =  {'Raw';
           'Dig';
           'Filt';
           'CAR';
           'LFP';
           'Spikes';
           'Sorted';
           'Clusters';
           %%%%%%%%%%%%%%%%%%% This names are hardcoded. They are used in
           %%%%%%%%%%%%%%%%%%% the following (Block) functions:
           %%%%%%%%%%%%%%%%%%% convert (and ad hoc functions), extractLFP, 
           %%%%%%%%%%%%%%%%%%% filterData, CAR, spikeDetection, linkToData
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

Pars.Time.File = [Del 'Time'];

end