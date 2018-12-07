function [pars,Fields] = Block()
%% defaults.Block  Sets default parameters for BLOCK object
%
%  [pars,Fields] = orgExp.defaults.Block();
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% Modify all properties here         
% Define general values used when parsing metadata from file name and
% structure:
pars             = struct;

pars.RecLocDefault  = 'R:/Rat';

pars.SaveFormat  = 'Hybrid'; % refers to save/load format
pars.SaveLocDefault = 'P:/Rat';
pars.ForceSaveLoc = true; % create directory if save location doesn't exist

pars.Delimiter   = '_'; % delimiter for variables in BLOCK name
CH_ID = 'Ch';           % precedes the channel number delimited variable
pars.ProbeChannel= [pars.Delimiter 'P%s_' CH_ID '_%s'];

%% Here You can specify the naming format of your block recording
% The block name will be splitted using Delimiter (defined above) and each
% segment will be assigned to the property definied here. 
% Using namingConvention you can define to what varible each piece of the
% block name should be assigned to. Use the includeChar and discardChar to
% specify if that piece of info should be kept or discarded when creating
% the BLOCK name from the RECORDING name.
%
% Example 1
% ---------
% The recording name R18-68_2018_07_24_0_180724_141203.rhd, with dynamic 
% parsing and naming conventions set as:
% 
% pars.DynamicVarExp='$Animal_ID $Year $Month $Day $Rec_ID $Rec_date $Rec_time';
% pars.IncludeChar='$';
% pars.DiscardChar='&';
% pars.NamingConvention={'Animal_ID','Year','Month','Day','Rec_ID'};
%
% Will still extract the Recording_date and Recording_time directly from
% the name (if they are present). However, the block name in the specified
% save location (here, 'path') will be:
%
% ~/path/R18-68_2018_07_24_0
%
% Example 2
% ---------
%
% Alternatively, specifying:
%
% pars.DynamicVarExp='$Animal_ID &Year &Month &Day $Rec_ID $Rec_date $Rec_time';
% pars.IncludeChar='$';
% pars.DischardChar='&';
% pars.NamingConvention={'Animal_ID','Rec_ID','Rec_date','Rec_time'};
%
% Will also extract Recording_date and Recording_time, but will not parse 
% variables for 'Year,' 'Month,' or 'Date.' 
% The BLOCK will be named:
%
% ~/path/R18-68_0_180724_141203

pars.DynamicVarExp='$Animal_ID $Year $Month $Day $Rec_ID $Rec_date $Rec_time';
pars.IncludeChar='$';
pars.DiscardChar='&';
pars.NamingConvention={'Animal_ID','Year','Month','Day','Rec_ID'};

%% 
Fields =  {'Raw';
           'Dig';
           'Filt';
           'CAR';
           'LFP';
           'Spikes';
           'Sorted';
           'Clusters';
           'Meta';
           %%%%%%%%%%%%%%%%%%% These names are hardcoded. They are used in
           %%%%%%%%%%%%%%%%%%% the following (Block) functions:
           %%%%%%%%%%%%%%%%%%% doRawExtraction (and ad hoc functions), 
           %%%%%%%%%%%%%%%%%%% doLFPExtraction, doReReferencing,
           %%%%%%%%%%%%%%%%%%% doSpikeDetection, linkToData
                    };
                
                
FileNames       =   {'Raw';
                     {'AAUX1';'AAUX2';'AAUX3';'BAUX1';'BAUX2';'BAUX3';'sync';'user'};
                     'Filt';
                     'FiltCAR';
                     'LFP';
                     'ptrain';
                     'sort';
                     'clus';
                     {'probes';'experiment';'sync'};
                    };
                
FolderNames     =   {'RawData';
                     'Digital';
                     'Filtered';
                     'FilteredCAR';
                     'LFPData';
                     'wav-sneo_CAR_Spikes';
                     'wav-sneo_SPC_CAR_Sorted';
                     'wav-sneo_SPC_CAR_Clusters';
                     'Metadata';
                    };

% Concatenate identifier for each file-type:
Del = pars.Delimiter;
P_C = pars.ProbeChannel;
for ii=1:numel(Fields)
   if iscell(FileNames{ii}) % If multiple file names for a given type of file
      nFiles = numel(FileNames{ii}); % Make cell array for all of them
      pars.(Fields{ii}).File = cell(nFiles,1);
      for ik = 1:nFiles
         pars.(Fields{ii}).File{ik} = [Del FileNames{ii}{ik} P_C];
      end
   else
      pars.(Fields{ii}).File      = [Del FileNames{ii} P_C];
      
   end
   pars.(Fields{ii}).Tag = FileNames{ii};
   pars.(Fields{ii}).Folder    = FolderNames{ii};
end

pars.Time.File = [Del 'Time'];

end