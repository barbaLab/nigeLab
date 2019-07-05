function flag = parseProbeNumbers(blockObj)
%% PARSEPROBENUMBERS    Function to parse probe numbers depending on recType
%
%  flag = blockObj.PARSEPROBENUMBERS;
%
% By: Max Murphy  v1.0  2019/01/07  Original version (R2017a)

%% PARSE BASED ON RECORDING TYPE
flag = false;
switch blockObj.RecType
   case 'Intan'
      % Make assumptions that 2 unique board_stream ID in same port are
      % from a dual-headstage plugged into 2 different electrode arrays
      % (since that is the typical use-case at Nudo Lab)
      portStream = nan(numel(blockObj.Channels),2);
      for iCh = 1:numel(blockObj.Channels)
         portStream(iCh,:) = [blockObj.Channels(iCh).port_number, ...
            blockObj.Channels(iCh).board_stream];
      end
      
      [~,~,probe] = unique(portStream,'rows');
      for iCh = 1:numel(blockObj.Channels)
         blockObj.Channels(iCh).probe = probe(iCh);
         
         [blockObj.Channels(iCh).chNum,...
            blockObj.Channels(iCh).chStr] = getChannelNum(...
            blockObj.Channels(iCh).custom_channel_name);
      end
      
      
   case 'TDT'
      for iCh = 1:numel(blockObj.Channels)
         blockObj.Channels(iCh).probe = blockObj.Channels(iCh).port_number;
         [blockObj.Channels(iCh).chNum,...
            blockObj.Channels(iCh).chStr] = getChannelNum(...
            blockObj.Channels(iCh).custom_channel_name);
      end
      
   otherwise
      warning('%s is not a supported RecType.',blockObj.RecType);
      return;
end
flag = true;

   function [channelNum,channelString] = getChannelNum(channelName)
      %% GETCHANNELNUM  Get numeric and string values for channel NUMBER
      numericIndex = regexp(channelName, '\d');
      channelString = channelName(numericIndex);
      channelNum = str2double(channelString);
   end

end