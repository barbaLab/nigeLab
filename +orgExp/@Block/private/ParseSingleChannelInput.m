function flag = ParseSingleChannelInput(blockObj,ch)
%% PARSESINGLECHANNELINPUT    Parse validity of channel input
%   
%  flag = ParseSingleChannelInput(blockObj,ch);
%
% By: Max Murphy  v1.0  12/06/2018  Original version (R2017a)

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

