function header = ReadMatInfo(path)
%% Function to read a nigeLab block header previously stored in a matfile
% define here your own function! Parse the data according to nigeLab
% header format!

tmp=load(path);
header = struct();

%% RAW_CHANNELS STRUCT IS MANDATROY!
header.raw_channels          = tmp.info;
header.num_raw_channels      = numel(tmp.info);
%% Remember to handle fields probe  and chNum! Both are numeric values.
% example below
for iCh = 1:header.num_raw_channels
   [header.raw_channels(iCh).chNum,...
      header.raw_channels(iCh).chStr] = getChannelNum(...
      header.raw_channels(iCh).custom_channel_name);
   header.raw_channels(iCh).native_order = iCh;
end

%% other required fields

header.num_analogIO_channels = 0;
header.num_digIO_channels    = 0;
header.num_probes            = numel(unique([header.raw_channels.probe]));
header.sample_rate           = header.raw_channels(1).fs;
tmp = dir(fullfile(fileparts(path),'*01.mat'));
m=matfile(fullfile(tmp.folder,tmp.name));
header.num_raw_samples       = length(m.data);


end

   function [channelNum,channelString] = getChannelNum(channelName)
      %% GETCHANNELNUM  Get numeric and string values for channel NUMBER
      numericIndex = regexp(channelName, '\d');
      channelString = channelName(numericIndex);
      channelNum = str2double(channelString);
   end