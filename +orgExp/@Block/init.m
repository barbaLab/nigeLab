function init(blockObj,varargin)
%% INIT Initialize BLOCK object
%
%  blockObj.INIT;
%
%  By: Max Murphy v1.0  08/25/2017  Original version (R2017a)
%      Federico Barban v2.0 07/08/2018

[Pars,blockObj.Fields] = orgExp.defaults.Block;

[~,blockObj.Name,blockObj.File_extension] = fileparts(blockObj.Path);
nameParts=strsplit(blockObj.Name,{Pars.Delimiter '.'});
expression = sprintf('\\%c\\w*|\\%c\\w*',Pars.includeChar,Pars.discardChar);
[splitStr]=regexp(Pars.namingConvention,expression,'match');
include=find(cellfun(@(x) x(1)=='$',splitStr));
P = properties(blockObj);

for ii=include
    eval(sprintf('%s=nameParts{ii};',upper( deblank( splitStr{ii}(2:end)))));
    Prop = P(ismember(upper(P), upper( deblank( splitStr{ii}(2:end)))) );
    if ~isempty(Prop)
        blockObj.(Prop{:}) = nameParts{ii};
    end
end

if isempty(blockObj.Recording_date)
    YY = YEAR(end-1:end);
    MM = MONTH;
    DD = sprintf('%.2d',str2double(DAY));
    blockObj.Recording_date = [YY MM DD];
end

blockObj.setSaveLocation(blockObj.SaveLoc);
blockObj.SaveFormat = Pars.SaveFormat;

if exist(blockObj.SaveLoc,'dir')==0
    mkdir(fullfile(blockObj.SaveLoc));
end


switch blockObj.File_extension
    case '.rhd' 
        blockObj.RecType='Intan';
        header=orgExp.libs.RHD_read_header('NAME',blockObj.Path,'VERBOSE',blockObj.Verbose);
    case '.rhs'
        blockObj.RecType='Intan';
        header=orgExp.libs.RHS_read_header('NAME',blockObj.Path,'VERBOSE',blockObj.Verbose);
    otherwise
        blockObj.RecType='other';
end

blockObj.Channels = header.amplifier_channels;
blockObj.numChannels = header.num_amplifier_channels;
blockObj.numProbes = header.num_probes;
% blockObj.dcAmpDataSaved = header.dc_amp_data_saved;
blockObj.numADCchannels = header.num_board_adc_channels;
% blockObj.numDACChannels = header.num_board_dac_channels;
blockObj.numDigInChannels = header.num_board_dig_in_channels;
blockObj.numDigOutChannels = header.num_board_dig_out_channels;
blockObj.Sample_rate = header.sample_rate;
blockObj.Samples = header.num_amplifier_samples;

% blockObj.DACChannels = header.board_dac_channels;
blockObj.ADCChannels = header.board_adc_channels;
blockObj.DigInChannels = header.board_dig_in_channels;
blockObj.DigOutChannels = header.board_dig_out_channels;
blockObj.Sample_rate = header.sample_rate;
blockObj.Samples = header.num_amplifier_samples;

blockObj.updateStatus('init');

%% CHECK WHETHER TO PROCEED with conversion
% choice = questdlg('Do file conversion (can be long)?',...
%     'Continue?',...
%     'Yes','Cancel','Yes');
% if strcmp(choice,'Cancel')
%     warning('File conversion aborted. Process canceled.');
% else
%     blockObj.convert();
% end

%       % Give chance to alter save location based on default settings
%       setSaveLocation(tankObj);


%% LOOK FOR NOTES
% notes = dir(fullfile(blockObj.DIR,'*Description.txt'));
% if ~isempty(notes)
%    blockObj.Notes.File = fullfile(notes.folder,notes.name);
%    fid = fopen(blockObj.Notes.File,'r');
%    blockObj.Notes.String = textscan(fid,'%s',...
%       'CollectOutput',true,...
%       'Delimiter','\n');
%    fclose(fid);
% else
%    blockObj.Notes.File = [];
%    blockObj.Notes.String = [];
% end

%% Convert and attach raw files

% %% ADD PUBLIC BLOCK PROPERTIES
% path = strsplit(blockObj.DIR,filesep);
% blockObj.Name = path{numel(path)};
% finfo = strsplit(blockObj.Name,blockObj.ID.Delimiter);
%
% for iL = 1:numel(blockObj.Fields)
%    blockObj.updateContents(blockObj.Fields{iL});
% end

%% ADD CHANNEL INFORMATION??????
% if ismember('CAR',blockObj.Fields(blockObj.Status))
%    blockObj.Channels.Board = sort(blockObj.CAR.ch,'ascend');
% elseif ismember('Filt',blockObj.Fields(blockObj.Status))
%    blockObj.Channels.Board = sort(blockObj.Filt.ch,'ascend');
% elseif ismember('Raw',blockObj.Fields(blockObj.Status))
%    blockObj.Channels.Board = sort(blockObj.Raw.ch,'ascend');
% end

% % Check for user-specified MASKING
% if ~isempty(blockObj.MASK)
%    if abs(numel(blockObj.MASK)-numel(blockObj.Channels.Board))<eps
%       blockObj.Channels.Mask = blockObj.MASK;
%    else
%       warning('Wrong # of elements in specified MASK.');
%       fprintf(1,'Using all channels by default.\n');
%       blockObj.Channels.Mask = true(size(blockObj.Channels.Board));
%    end
% else
%    blockObj.Channels.Mask = true(size(blockObj.Channels.Board));
% end

% % Check for user-specified REMAPPING
% if ~isempty(blockObj.REMAP)
%    if abs(numel(blockObj.REMAP)-numel(blockObj.Channels.Board))<eps
%       blockObj.Channels.Probe = blockObj.REMAP;
%    else
%       warning('Wrong # of elements in specified REMAP.');
%       fprintf(1,'Using board channels by default.\n');
%       blockObj.Channels.Probe = blockObj.Channels.Board;
%    end
% else
%    blockObj.Channels.Probe = blockObj.Channels.Board;
% end

blockObj.save;
end