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
if exist(channelInfoFile,'file')==0
   error('Bad filename: %s',channelInfoFile);
end
in = load(channelInfoFile);
if ~ismember('info',fieldnames(in))
   error('Bad MatFile. Must contain ''info'' struct.');
else
   info = in.info; clear in;
   data_present = true;
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
raw_channels = struct;
analogIO_channels = struct;
digIO_channels = struct;
num_raw_channels = nan;
num_digIO_channels = nan;
num_analogIO_channels = nan;
probes = nan;
num_probes = nan;
num_raw_samples = nan;
num_analogIO_samples = nan;
num_digIO_samples = nan;
   

%%
for out = DesiredOutputs'
   header.(out{:}) = eval(out{:});
end

%%
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
         };
   end
end