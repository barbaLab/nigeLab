function flag = initChannels(blockObj,header)
%% INITCHANNELS   Initialize header information for channels
%
%  flag = blockObj.initChannels;
%  flag = blockObj.initChannels(header);
%  --> Uses custom-defined 'header' struct

%% GET HEADER INFO DEPENDING ON RECORDING TYPE
flag = false;
if nargin < 2
   header = nigeLab.parseHeader();
end

%% ASSIGN DATA FIELDS USING HEADER INFO
blockObj.Channels = header.raw_channels;
blockObj.RecSystem = nigeLab.utils.AcqSystem(header.acqsys);
blockObj.Meta.Header = nigeLab.utils.fixNamingConvention(header);

if ~blockObj.parseProbeNumbers % Depends on recording system
   warning('Could not properly parse probe identifiers.');
   return;
end
blockObj.NumChannels = header.num_raw_channels;
blockObj.NumProbes = header.num_probes;
blockObj.SampleRate = header.sample_rate;
blockObj.Samples = header.num_raw_samples;

%% SET CHANNEL MASK (OR IF ALREADY SPECIFIED MAKE SURE IT IS CORRECT)
blockObj.parseChannelID();
if isfield(header,'Mask')
   blockObj.Mask = reshape(find(header.Mask),1,numel(header.Mask));
elseif isempty(blockObj.Mask)
   blockObj.Mask = 1:blockObj.NumChannels;
else
   blockObj.Mask(blockObj.Mask > blockObj.NumChannels) = [];
   blockObj.Mask(blockObj.Mask < 1) = [];
   blockObj.Mask = reshape(blockObj.Mask,1,numel(blockObj.Mask));
end

flag = true;

end