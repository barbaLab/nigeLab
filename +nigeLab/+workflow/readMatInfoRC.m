function header = readMatInfoRC(channelInfoFile)
% READMATINFORC  Workflow to parse RC format header
%
%  header = utils.READMATINFORC(channelInfoFile)
%
%  --------
%   INPUTS
%  --------
%  channelInfoFile   :  Data file from TDT extraction in the base level of
%                          the hierarchical "block" format from the old
%                          (CPLTOOLS) version of extraction process.
%
%  --------
%   OUTPUT
%  --------
%   header           :  Header struct as returned by the "READ" functions.
%
%  See also READRHDHEADER, READRHSHEADER, READTDTHEADER

%% Check that input is valid
acqsys = 'TDT';
digFields = {'Paw','Beam'};
if exist(channelInfoFile,'file')==0
   error('Bad filename: %s',channelInfoFile);
else
   [path,fname,ext] = fileparts(channelInfoFile);
end
in = load(channelInfoFile);
if ~ismember('info',fieldnames(in))
   error('Bad MatFile. Must contain ''info'' struct.');
else
   % match naming convention from 'rc-proj'  repo
   ChannelInfo = in.info;
   data_present = true;
   fnameEpoc = strrep(fname,'_ChannelInfo','_EpocSnipInfo');
   epocSnipInfoFile = fullfile(path,[fnameEpoc ext]);
   
   if exist(epocSnipInfoFile,'file')~=0
      in = load(epocSnipInfoFile,'block');
   end
   if isfield(in,'block')
      if isfield(in.block,'epocs')
         if ~isfield(in.block.epocs,'BeaR') && ~isfield(in.block.epocs,'BeaL')
            digFields(2) = [];
         end 
         if isfield(in.block.epocs,'Pres')
            digFields = [digFields, 'SuccessPress'];
         end
      end
   end

end

namestr = ChannelInfo.file;
namestr = strsplit(namestr,'_');
blockName = strjoin(namestr(1:4),'_');

%% MANUALLY SET DUE TO KNOWN EXPERIMENTAL SETUP
FS = 24414.0625; % TDT
FC = [300 5000]; % Cutoff frequencies used in recording

%%
header = struct; % Has fields from DESIREDOUTPUTS as defined below
sample_rate = FS;
frequency_parameters = struct(...
   'amplifier_sample_rate',FS,...
   'board_adc_sample_rate',FS,...
   'board_dig_in_sample_rate',FS,...
   'desired_dsp_cutoff_frequency',FC(1),... % not actually "desired" :(
   'desired_lower_bandwidth',FC(1),... % not actually "desired" :(
   'desired_upper_bandwidth',FC(2));
raw_channels = doInfoConversion(ChannelInfo);
analogIO_channels = nigeLab.utils.initChannelStruct('Streams',0);
digIO_channels = makeRCdigIO(digFields);
num_raw_channels = numel(raw_channels);
num_digIO_channels = numel(digFields);
num_analogIO_channels = 0;
probes = [1;2];
num_probes = 2;

N = getNumSamples(path,blockName);
num_raw_samples = N;
num_analogIO_samples = 0;
num_digIO_samples = N;
   

if isfield(in,'block')
   duration = in.block.info.duration;
   blocktime = in.block.info.duration;
end

%%

DesiredOutputs = nigeLab.utils.initDesiredHeaderFields('RC').';
for fieldOut = DesiredOutputs %  DesiredOutputs defined in nigeLab.utils
   fieldOutVal = eval(fieldOut{:});
   header.(fieldOut{:}) = fieldOutVal;
end

fChannelMask = fullfile(path,[blockName '_ChannelMask.mat']);
if exist(fChannelMask,'file')~=0
   in = load(fChannelMask,'ChannelMask');
   if isfield(in,'ChannelMask')
      header.Mask = in.ChannelMask;
   end
end

return
end

%% Helper functions

   % Does the actual conversion from "ChannelInfo" array used in 'rc-proj'
   % repository to the "Intan-like" struct array format for channels
   function c = doInfoConversion(info)
      % DOINFOCONVERSION   Helps convert ChannelInfo to "Intan-like" format
      
      n = numel(info);
      probe = {'A','B'};
      % Note that most of these aren't really representative, but rather to
      % fit the existing workflow; for example, there is no "chip_channel"
      % for the TDT system on which this data was acquired.
      c = makeChannelStruct(n,'Channels');
      
      for i = 1:n
         p = info(i).probe;
         ch = info(i).channel;
         ab = probe{p}; % 'A' or 'B' depending on probe number
         name = sprintf('%s-%03g',ab,ch);
         c(i).native_channel_name = name;
         c(i).custom_channel_name = name;
         c(i).native_order = ch;
         c(i).custom_order = c(i).native_order;
         c(i).board_stream = p;
         c(i).chip_channel = (p-1)*16 + ch;
         c(i).port_name = sprintf('Port %s',ab);
         c(i).port_prefix = ab;
         c(i).port_number = p;
         c(i).probe = p;
         % Impedances weren't collected (couldn't be easily measured using
         % the TDT setup at the time)
         c(i).electrode_impedance_magnitude = nan;
         c(i).electrode_impedance_phase = nan;
         c(i).ml = info(i).ml; % 'M' or 'L' for Medial vs Lateral
         c(i).icms = info(i).icms;              % 'DF', 'PF', 'DF-PF', 'O', 'NR' are options
         c(i).area = info(i).area((end-2):end); % 'RFA' or 'CFA'
         [c(i).chNum,c(i).chStr] = nigeLab.utils.getChannelNum(name);
      end
   end

   % Returns the number of samples in the digital record, based on what has
   % been already extracted for the raw data streams. 
   function nSamples = getNumSamples(blockPath,blockName)
      raw_folder = fullfile(blockPath,[blockName '_RawData']);
      F = dir(fullfile(raw_folder,[blockName '*.mat']));
      m = matfile(fullfile(F(1).folder,F(1).name));
      nSamples = size(m.data,2);
   end

   % Helper function to output an n x 1 struct array in the "Intan-like"
   % struct array format for channels. Specify addExtraInfo as 'true' to
   % add fields for 'icms' 'area' and 'ml' that had been parsed from the
   % probe layout previously from elsewhere.
   function c = makeChannelStruct(n,FieldType)
      % MAKECHANNELSTRUCT  Helper to return struct n x 1 struct array
      if nargin < 2
         FieldType = 'Channels';
      end
      
      switch FieldType
         case 'Channels'
            c = nigeLab.utils.initChannelStruct(FieldType,n,...
                  'electrode_impedance_magnitude',nan,...
                  'electrode_impedance_phase',nan,...
                  'signal',nigeLab.utils.signal('Raw'),...
                  'ml',cell(1,n),...
                  'icms',cell(1,n),...
                  'area',cell(1,n));
         case 'Streams'
            c = nigeLab.utils.initChannelStruct(FieldType,n,...
                  'board_stream',0,...
                  'port_name',{'Board Digital Inputs'},...
                  'port_prefix',{'DIN'},...
                  'port_number',6,...
                  'electrode_impedance_magnitude',0,...
                  'electrode_impedance_phase',0,...
                  'signal',nigeLab.utils.signal('DigIn'));
         otherwise
            error('Unrecognized FieldType: %s',FieldType);
      end
   end

   % The DIG_IO and alignment etc. is already parsed, so this is just to
   % represent the parsed streams
   function c = makeRCdigIO(names)
      % MAKERCDIGIO  Return RC "digital IO" channel struct 
      
      c = makeChannelStruct(numel(names),'Streams');
      for i = 1:numel(names)    
         c(i).native_channel_name = sprintf('DIN-%02g',i);
         c(i).custom_channel_name = names{i};
         c(i).native_order = i;
         c(i).custom_order = i;
         c(i).chip_channel = i;
      end

   end
