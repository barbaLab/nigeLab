function varargout = Block(varargin)
% defaults.Block  Sets default parameters for BLOCK object
%
%  pars = nigeLab.defaults.Block();
%  param = nigeLab.defaults.Block('parName');

%% Modify all properties here
% NOTE: Capitalization is important here, as some of the properties are
%        added from this struct to the BLOCK object and will not be
%        correctly incorporated unless the capitalization matches BLOCK
%        property.
% Define general values used when parsing metadata from file name and
% structure:
pars             = struct;

% If you have pre-extracted data, the workflow can be customized here
% pars.MatFileWorkflow.ReadFcn = @nigeLab.workflow.readMatInfo; % Standard (AA - IIT)  
pars.MatFileWorkflow.ReadFcn = @nigeLab.workflow.readMatInfoRC; % RC project (MM - KUMC)
pars.MatFileWorkflow.ConvertFcn = []; % Most cases, this will be blank (AA - IIT)
% pars.MatFileWorkflow.ConvertFcn = @nigeLab.workflow.rc2Block; % RC project (MM - KUMC; only needs to be run once)
% pars.MatFileWorkflow.ExtractFcn = @nigeLab.workflow.mat2Block; % Standard (AA - IIT)
pars.MatFileWorkflow.ExtractFcn = @nigeLab.workflow.mat2BlockRC; % RC project (MM - KUMC)
pars.DefaultRecLoc  = 'R:/Rat';
pars.SaveFormat  = 'Hybrid'; % refers to save/load format
pars.SaveLocDefault = 'P:/Rat';
pars.FolderIdentifier = '.nigelBlock'; % for file "flag" in block folder

%% Explanation of DynamicVarExp and NamingConvention pars fields
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
% pars.DynamicVarExp='$AnimalID $Year $Month $Day $RecID $RecDate $RecTime';
% pars.IncludeChar='$';
% pars.DiscardChar='&';
% pars.NamingConvention={'AnimalID','Year','Month','Day','RecID'};
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
% pars.DynamicVarExp='$AnimalID &Year &Month &Day $RecID $RecDate $RecTime';
% pars.IncludeChar='$';
% pars.DischardChar='&';
% pars.NamingConvention={'AnimalID','RecID','RecDate','RecTime'};
%
% Will also extract Recording_date and Recording_time, but will not parse
% variables for 'Year,' 'Month,' or 'Date.'
% The BLOCK will be named:
%
% ~/path/R18-68_0_180724_141203

%% Common DynamicVarExp values
% pars.NamingConvention={'$SurgYear' '$SurgNumber' '$RecDate' '$RecTime'}; % KUMC R03
% pars.NamingConvention={'$AnimalID','$Year','$Month','$Day','$Phase','$RecDate','$RecTime'}; % demo
pars.NamingConvention={'$AnimalID' '$ExpPhase' '$RecDate' '$RecTime'}; % iit acute

% OPTIONAL: To parse "RecID" from combination of meta vars, specify here
% (otherwise, if RecID is normally present, or if this is empty, it is not
%  used). The same goes for "AnimalID"

pars.SpecialMeta = struct;

% Note that RecTag (if created) replaces 'RecID' in DashBoard
% pars.SpecialMeta.SpecialVars = {'RecTag'};     % FB ~!!
pars.SpecialMeta.SpecialVars = {'BlockID'}; % MM
pars.SpecialMeta.BlockID.cat = '-';
% pars.SpecialMeta.RecID.cat = '-';      % Concatenater (if used) for names
% pars.SpecialMeta.AnimalID.cat = '-';   % Concatenater (if used) for names

% pars.SpecialMeta.SpecialVars = {'AnimalID','RecID'}; % KUMC "RC"

% (All must be included in DynamicVarExp):
% pars.SpecialMeta.RecTag.vars = {'RecID'}; % FB
% pars.SpecialMeta.RecID.vars = {}; % FB/KUMC-R03/MM
% pars.SpecialMeta.RecTag.vars = {'Year','Month','Day'}; % KUMC "RC"
pars.SpecialMeta.BlockID.vars = {'ExpPhase','RecDate','RecTime'}; % KUMC "MM"
% pars.SpecialMeta.AnimalID.vars = {}; % FB/KUMC-R03  Keep commented
% pars.SpecialMeta.AnimalID.vars = {'Project','SurgNumber'}; % KUMC "RC"
% pars.SpecialMeta.AnimalID.vars = {'SurgYear','SurgNumber'};  % MM Audio stuff

pars.Delimiter   = '_'; % delimiter for variables in BLOCK name
pars.Concatenater = '_'; % concatenater for variables INCLUDED in BLOCK name
pars.VarExprDelimiter = {'_'};   % Delimiter for parsing "special" vars   -- (FB)
% pars.VarExprDelimiter = {'_','-'}; % Since these are different for different configs, please keep commented lines instead of changing directly
pars.IncludeChar='$'; % Delimiter for INCLUDING vars in name
pars.DiscardChar='~'; % Delimiter for excluding vars entirely (don't keep in meta either)

%% Many animals in one block 
%
% Modern recording amplifiers usually have the capabilities to record from
% many channels  simultaneously. This can be exploited to record from many
% animals simultaneously and save eveything in only one datafile. 
% You can signal this to nigel by interposing the here defined character
% between different animal names in the AnimalID field of the recording
% file
%
% Example 
% R18-68&&R18-69_180724_141203.rhd
pars.MultiAnimalsChar='&&';

%%
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
   [pars.Delimiter '%s'];
TAG.Streams = ... % Streams: for example, stream of zeros/ones for event
   [pars.Delimiter '%s', ...
   pars.Delimiter '%s', ...
   pars.Delimiter 'Stream.mat'];
TAG.Videos = ... % Videos: behavioral videos
   [pars.Delimiter '%s', ...
    pars.Delimiter '%s.%s']; % "Video_Left-A_0.mp4" "Video_Left-A_1.mp4"

Fields =  { ...
   'Raw';            % 1  - hard-coded for extraction
   'Filt';           % 2
   'CAR';            % 3
   'LFP';            % 4
   'Artifact';       % 5 - hard-coded to match terms from defaults.SD
   'Spikes';         % 6 - hard-coded to match terms from defaults.SD
   'SpikeFeatures';  % 7 - hard-coded to match terms from defaults.SD
   'Clusters';       % 8 - hard-coded to match terms from defaults.SD
   'Sorted';         % 9 - hard-coded to match terms from defaults.SD
   'DigIO';          % 10 - hard-coded for extraction
   'AnalogIO';       % 11 - hard-coded for extraction
   'DigEvents';      % 12
   'VidStreams';     % 13
   'Stim';           % 14 - hard-coded for extraction in RHS
   'DC';             % 15 - hard-coded for extraction in RHS
   'Time';           % 16
%    'Notes'           % 17
   'Probes';         % 18
   'Video';          % 19
   'ScoredEvents';   % 20 - for manually-scored sync and alignment
   };

FieldType = { ...
   'Channels'; % 1
   'Channels'; % 2
   'Channels'; % 3
   'Channels'; % 4
   'Channels'; % 5
   'Channels'; % 6
   'Channels'; % 7
   'Channels'; % 8
   'Channels'; % 9
   'Streams';  % 10
   'Streams';  % 11
   'Events';   % 12
   'Videos';  % 13
   'Events';   % 14
   'Channels'; % 15
   'Meta';     % 16
%    'Meta';     % 17
   'Meta'      % 18
   'Videos';   % 19  -- 2019-11-21 Introduce new FieldType for Videos
   'Events';   % 20
   };

OldNames       =  { ...
   {'*Raw*'};                       % 1
   {'*Filt*'};                      % 2
   {'*FiltCAR*'};                   % 3
   {'*LFP*'};                       % 4
   {'*art*'};                       % 5
   {'*ptrain*'};                    % 6
   {'*SpikeFeatures*'};             % 7
   {'*clus*'};                      % 8
   {'*sort*'};                      % 9
   {'*DIG*'};                       % 10
   {'*ANA*'};                       % 11
   {'*Press.mat';'*Beam.mat'};      % 12
   {'*Paw.mat';'*Kinematics.mat'};  % 13
   {'*STIM*'};                      % 14
   {'*DC*'};                        % 15
   {'*Time*'};                      % 16
%    {'*experiment.txt'};             % 17
   {'*probes.xlsx'};                % 18
   {'*.mp4','*.avi'};               % 19
   {'*Scoring*','*VideoAlignment*'} % 20
   };

FolderNames     = {  ...
   'RawData';           % 1
   'Filtered';          % 2
   'FilteredCAR';       % 3
   'LFPData';           % 4
   '%s_Artifact';       % 5
   '%s_Spikes';         % 6
   '%s_SpikeFeatures';  % 7
   '%s_Clusters';       % 8
   '%s_Sorted';         % 9
   'Digital';           % 10
   'Digital';           % 11
   'Digital';           % 12
   'Video';             % 13 - for streams parsed from Video
   'StimData';          % 14
   'StimData';          % 15
   'Digital';           % 16
%    'Metadata';          % 17
   'Metadata';          % 18
   'Video';             % 19 - for actual Video
   'Video';             % 20 - Events from behavioral scoring
   };

FileNames =  { ...
   'Raw';            % 1  - hard-coded for extraction
   'Filt';           % 2
   'CAR';            % 3
   'LFP';            % 4
   'Artifact';       % 5 - hard-coded to match terms from defaults.SD
   'ptrain';         % 6 - hard-coded to match terms from defaults.SD
   'SpikeFeatures';  % 7 - hard-coded to match terms from defaults.SD
   'Clusters';       % 8 - hard-coded to match terms from defaults.SD
   'Sorted';         % 9 - hard-coded to match terms from defaults.SD
   'DigIO';          % 10 - hard-coded for extraction
   'AnalogIO';       % 11 - hard-coded for extraction
   'DigEvents';      % 12
   'VidStream';          % 13 - for streams parsed from Videos
   'Stim';           % 14 - hard-coded for extraction in RHS
  'DC';             % 15 - hard-coded for extraction in RHS
   'Time';           % 16
%    'Notes'           % 17
   'Probes';         % 18
   'Video';          % 19 - for actual Videos
   'Curated';        % 20 - from behavioral scoring or manual alignment 
   };

FileType = { ...
   'Hybrid';   % 1
   'Hybrid';   % 2
   'Hybrid';   % 3
   'Hybrid';   % 4
   'Event';    % 5
   'Event';    % 6
   'Event';    % 7
   'Event';    % 8
   'Event';    % 9
   'Hybrid';   % 10
   'Hybrid';   % 11
   'Event';    % 12
   'Hybrid';   % 13
   'Event';    % 14
   'Hybrid';   % 15
   'Hybrid';   % 16
%    'Other';    % 17
   'Other';    % 18
   'Other';    % 19
   'Hybrid';   % 20
   };

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
elseif numel(FileType)~=N
   error('FileType (%d) must have same # elements as Fields (%d).',...
      numel(FileType),N);
end
pars.FileType = FileType;
pars.FieldType = FieldType;
pars.Fields = Fields;

iFields = ismember(Fields,fieldnames(pars));
if any(iFields)
   error(['nigeLab:' mfilename ':badFieldsName'],...
      'Bad Fields name: %s\n',Fields{iFields});
end


% Check that FieldType is viable
pars.ViableFieldTypes = fieldnames(TAG);
idx = ~cellfun(@(x)ismember(x,pars.ViableFieldTypes),FieldType);
if sum(idx)>0
   idx = find(idx);
   warning('\nInvalid: FieldType{%d} (%s)\n',idx,FieldType{idx});
   pars = [];
   Fields = [];
   return;
end


% Check that if "HasVideo" and/or "HasVidStreams" are true, the appropriate
% fields and corresponding values are present

%% MAKE DIRECTORY PARAMETERS STRUCT
% Concatenate identifier for each file-type:
Del = pars.Delimiter;
pars.PathExpr = struct;
for ii=1:numel(Fields)
   pars.PathExpr.(Fields{ii}).Folder     = FolderNames{ii};
   pars.PathExpr.(Fields{ii}).OldFile    = OldNames{ii};
   pars.PathExpr.(Fields{ii}).File = [FileNames{ii} TAG.(FieldType{ii})];
   pars.PathExpr.(Fields{ii}).Info = [FileNames{ii} '-Info.mat'];
end

%% Parse output
if nargin < 1
   varargout = {pars};
else
   varargout = cell(1,nargin);
   f = fieldnames(pars);
   for i = 1:nargin
      idx = ismember(lower(f),lower(varargin{i}));
      if sum(idx) == 1
         varargout{i} = pars.(f{idx});
      end
   end
end

end