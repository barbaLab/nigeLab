function header = ReadBlockChannelInfo(channelInfoFile)
% READBLOCKCHANNELINFO  Workflow to parse RC format header
%
%  header = utils.READBLOCKCHANNELINFO(channelInfoFile)
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
   ChannelInfo = in.info; clear in; 
   data_present = true;
   epocSnipInfoFile = strrep(fname,'_ChannelInfo','_EpocSnipInfo');
   if exist(epocSnipInfoFile,'file')~=0
      in = load(fullfile(path,[epocSnipInfoFile ext]),'block');
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
analogIO_channels = [];
digIO_channels = makeRCdigIO(digFields);
num_raw_channels = numel(raw_channels);
num_digIO_channels = numel(digFields);
num_analogIO_channels = 0;
probes = [1;2];
num_probes = 2;

N = getNumSamples(ChannelInfo,path);
num_raw_samples = N;
num_analogIO_samples = 0;
num_digIO_samples = N;
   

if isfield(in,'block')
   duration = in.block.info.duration;
   blocktime = in.block.info.duration;
end

%%
for out = DesiredOutputs'
   header.(out{:}) = eval(out{:});
end

%%
   % Shortcut to all "Desired" outputs that go into the traditional
   % "Intan-like" header for compatibility with the rest of the pipeline
   function DesiredOutputs=DesiredOutputs()
      % DESIREDOUTPUTS  Enumerates a list of variables to return in header
      
      DesiredOutputs = {
         'data_present';
         'sample_rate';
         'frequency_parameters';
         'raw_channels';
         'analogIO_channels';
         'digIO_channels';
         'num_raw_channels';
         'num_digIO_channels';
         'num_analogIO_channels';
         'probes';
         'num_probes';
         'num_raw_samples';
         'num_analogIO_samples';
         'num_digIO_samples';
         'duration';
         'blocktime';
         };
   end

   % Does the actual conversion from "ChannelInfo" array used in 'rc-proj'
   % repository to the "Intan-like" struct array format for channels
   function c = doInfoConversion(info)
      % DOINFOCONVERSION   Helps convert ChannelInfo to "Intan-like" format
      
      n = numel(info);
      probe = {'A','B'};
      % Note that most of these aren't really representative, but rather to
      % fit the existing workflow; for example, there is no "chip_channel"
      % for the TDT system on which this data was acquired.
      c = makeChannelStruct(n,true);
      
      for i = 1:n
         p = info(i).probe;
         ch = info(i).channel;
         ab = probe{p}; % 'A' or 'B' depending on probe number
         name = sprintf('%s-%03g',ab,ch);
         c(i).native_channel_name = name;
         c(i).custom_channel_name = name;
         c(i).native_order = (p-1)*16 + ch;
         c(i).custom_order = c(i).native_order;
         c(i).board_stream = p;
         c(i).chip_channel = ch;
         c(i).port_name = sprintf('Port %s',ab);
         c(i).port_prefix = ab;
         c(i).port_number = p;
         % Impedances weren't collected (couldn't be easily measured using
         % the TDT setup at the time)
         c(i).electrode_impedance_magnitude = nan;
         c(i).electrode_impedance_phase = nan;
         c(i).ml = info(i).ml; % 'M' or 'L' for Medial vs Lateral
         c(i).icms = info(i).icms;              % 'DF', 'PF', 'DF-PF', 'O', 'NR' are options
         c(i).area = info(i).area((end-2):end); % 'RFA' or 'CFA'
      end
   end

   % Returns the number of samples in the digital record, based on what has
   % been already extracted for the raw data streams. 
   function nSamples = getNumSamples(info,path)
      namestr = info(1).file;
      namestr = strsplit(namestr,'_');
      block = strjoin(namestr(1:4),'_');
      raw_folder = fullfile(path,[block '_RawData']);
      F = dir(fullfile(raw_folder,[block '*.mat']));
      m = matfile(fullfile(F(1).folder,F(1).name));
      nSamples = size(m.data,2);
   end

   % Helper function to output an n x 1 struct array in the "Intan-like"
   % struct array format for channels. Specify addExtraInfo as 'true' to
   % add fields for 'icms' 'area' and 'ml' that had been parsed from the
   % probe layout previously from elsewhere.
   function c = makeChannelStruct(n,addExtraInfo)
      % MAKECHANNELSTRUCT  Helper to return struct n x 1 struct array
      if nargin < 2
         addExtraInfo = false;
      end
      
      if addExtraInfo
         c = struct(...
            'native_channel_name',cell(n,1),...
            'custom_channel_name',cell(n,1),...
            'native_order',cell(n,1),...
            'custom_order',cell(n,1),...
            'board_stream',cell(n,1),...
            'chip_channel',cell(n,1),...
            'port_name',cell(n,1),...
            'port_prefix',cell(n,1),...
            'port_number',cell(n,1),...
            'electrode_impedance_magnitude',nan,...
            'electrode_impedance_phase',nan,...
            'ml',cell(n,1),...
            'icms',cell(n,1),...
            'area',cell(n,1));
      else
         c = struct(...
            'native_channel_name',cell(n,1),...
            'custom_channel_name',cell(n,1),...
            'native_order',cell(n,1),...
            'custom_order',cell(n,1),...
            'board_stream',0,...
            'chip_channel',cell(n,1),...
            'port_name',repmat({'Board Digital Inputs'},n,1),...
            'port_prefix',repmat({'DIN'},n,1),...
            'port_number',6,...
            'electrode_impedance_magnitude',0,...
            'electrode_impedance_phase',0);
      end
   end

   % The DIG_IO and alignment etc. is already parsed, so this is just to
   % represent the parsed streams
   function c = makeRCdigIO(names)
      % MAKERCDIGIO  Return RC "digital IO" channel struct 
      
      c = makeChannelStruct(numel(names),false);
      for i = 1:numel(names)    
         c(i).native_channel_name = sprintf('DIN-%02g',i);
         c(i).custom_channel_name = names{i};
         c(i).native_order = i;
         c(i).custom_order = i;
         c(i).chip_channel = i;
      end

   end
end