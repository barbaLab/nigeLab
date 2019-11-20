function [channelNum,channelString] = getChannelNum(channelName)
%% GETCHANNELNUM  Get numeric and string values for channel NUMBER
%
%  [channelNum,channelString] = nigeLab.utils.GETCHANNELNUM(channelName);
%
%  NOTE: by convention, we are calling this on the **CUSTOM_CHANNEL_NAME**
%        field, not **NATIVE_CHANNEL_NAME**

%%
numericIndex = regexp(channelName, '\d');
channelString = channelName(numericIndex);
channelNum = str2double(channelString);
end