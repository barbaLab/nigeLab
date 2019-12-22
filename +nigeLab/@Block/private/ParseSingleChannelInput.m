function flag = ParseSingleChannelInput(blockObj,ch)
%PARSESINGLECHANNELINPUT    Validates index for selecting a single channel
%   
%  flag = ParseSingleChannelInput(blockObj,ch);

%% 
flag = false;
if numel(ch) > 1
   warning('Channel arg must be a scalar.');
   return;
end

if ch < 1
   warning('Channel arg must be a positive integer (not %d).',ch);
   return;
end

if ch > blockObj.NumChannels
   warning('Channel arg must be <= %d (total # channels). Was %d.',...
      blockObj.NumChannels,ch);
   return;
end

flag = true;

end

