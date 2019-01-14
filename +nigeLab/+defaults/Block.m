function [pars,Fields] = Block()
%% defaults.Block  Sets default parameters for BLOCK object
%
%  [pars,Fields] = nigeLab.defaults.Block();
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% Modify all properties here
% Define general values used when parsing metadata from file name and
% structure:
pars             = struct;

pars.RecLocDefault  = 'R:/Rat';

pars.SaveFormat  = 'Hybrid'; % refers to save/load format
pars.AnimalLocDefault = 'P:/Rat';
pars.ForceSaveLoc = true; % create directory if save location doesn't exist

pars.Delimiter   = '_'; % delimiter for variables in BLOCK name

% Bookkeeping for tags to be appended to different FieldTypes. The total
% number of fields of TAG determines the valid entries for FieldTypes.
TAG = struct;
TAG.Channels = ... % Channels: neurophysiological recording channels
   [pars.Delimiter 'P%s',...
   pars.Delimiter 'Ch',...
   pars.Delimiter '%s.mat'];
TAG.Events = ... % Events: asynchronous events with associated values
   [pars.Delimiter '%s', ...
   pars.Delimiter 'Events.mat'];
TAG.Meta = ... % Meta: generic recording metadata (notes, probe configs)
   [pars.Delimiter '%s', ...
   pars.Delimiter 'Meta.mat'];
TAG.Streams = ... % Streams: for example, stream of zeros/ones for event
   [pars.Delimiter '%s', ...
   pars.Delimiter '%s', ...
   pars.Delimiter 'Stream.mat'];


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

% pars.DynamicVarExp='$Animal_ID $Year $Month $Day $Rec_ID $Rec_date $Rec_time';
pars.DynamicVarExp='&Tag $Animal_ID $Rec_ID';
pars.IncludeChar='$';
pars.DiscardChar='&';
pars.NamingConvention={'Animal_ID','Rec_ID'};

%%
Fields =  ...
   {'Raw';
   'Filt';
   'CAR';
   'LFP';
   'Spikes';
   'SpikeFeatures';
   'Clusters';
   'Sorted';
   'DigIO';
   'AnalogIO';
   'DigEvents';
   'Video';
   'Stim';
   'DC';
   'Time';
   'Probes';
   'Notes'};

FieldType = { ...
   'Channels';
   'Channels';
   'Channels';
   'Channels';
   'Channels';
   'Channels';
   'Channels';
   'Channels';
   'Streams';
   'Streams';
   'Events';
   'Streams';
   'Events';
   'Channels';
   'Streams';
   'Meta';
   'Meta'};
   

OldNames       =   ...
   {{'*Raw*'};
   {'*Filt*'};
   {'*FiltCAR*'};
   {'*LFP*'};
   {'*ptrain*'};
   {'*SpikeFeatures*'};
   {'*clus*'};
   {'*sort*'};
   {'*DIG*'};
   {'*ANA*'};
   {'*Scoring.mat'};
   {'*Paw.mat';'*Kinematics.mat'};
   {'*STIM*'};
   {'*DC*'};
   {'*Time*'};
   {'*probes.xlsx'};
   {'*experiment.txt'}};

FolderNames     =   ...
   {'RawData';
   'Filtered';
   'FilteredCAR';
   'LFPData';
   '%s_Spikes';
   '%s_SpikeFeatures';
   '%s_Clusters';
   '%s_Sorted';
   'Digital';
   'Digital';
   'Video';
   'StimData';
   'StimData';
   'Digital';
   'Metadata';
   'Metadata'};

%% DO ERROR PARSING
% Check that all have correct number of elements
N = numel(Fields);
if numel(FieldType)~=N
   error('FieldType (%d) must have same # elements as Fields (%d).',...
      numel(FieldType),N);
elseif numel(OldNames)~=N
   error('OldNames (%d) must have same # elements as Fields (%d).',...
      numel(OldNames),N);
elseif numel(FolderNames)~=N
   error('FolderNames (%d) must have same # elements as Fields (%d).',...
      numel(FolderNames),N);
end

% Check that FieldType is viable
VIABLE_FIELDS = fieldnames(TAG);
idx = ~cellfun(@(x)ismember(x,VIABLE_FIELDS),FieldType);
if sum(idx)>0
   idx = find(idx);
   warning('\nInvalid: FieldType{%d} (%s)\n',idx,FieldType{idx});
   pars = [];
   Fields = [];
   return;
end

%% MAKE DIRECTORY PARAMETERS STRUCT
% Concatenate identifier for each file-type:
Del = pars.Delimiter;
pars.BlockPars = struct;
for ii=1:numel(Fields)
   pars.BlockPars.(Fields{ii}).Folder     = FolderNames{ii};
   pars.BlockPars.(Fields{ii}).OldFile    = OldNames{ii};
   pars.BlockPars.(Fields{ii}).File = [Del Fields{ii} TAG.(FieldType{ii})];
   pars.BlockPars.(Fields{ii}).Info = [Del Fields{ii} '-Info.mat'];
end

end