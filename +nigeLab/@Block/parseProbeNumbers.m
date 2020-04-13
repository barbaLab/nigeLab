function flag = parseProbeNumbers(blockObj)
%PARSEPROBENUMBERS    Function to parse probe numbers depending on recType
%
%  flag = blockObj.PARSEPROBENUMBERS;

% PARSE BASED ON RECORDING TYPE
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
      for iCh = 1:blockObj.NumChannels
         blockObj.Channels(iCh).probe = probe(iCh);
      end
      
      probeSize = getProbeSize(probe);
      if probeSize == 0
         flag = true;
         return;
      end
      
      for iCh = 1:numel(blockObj.Channels)
         [blockObj.Channels(iCh).chNum,...
          blockObj.Channels(iCh).chStr] = getChannelNum(...
               blockObj.Channels(iCh).custom_channel_name,probeSize,true);
      end
      
   case {'TDT','nigelBlock'}
      for iCh = 1:blockObj.NumChannels
         blockObj.Channels(iCh).probe = blockObj.Channels(iCh).port_number;
      end
      probeSize = getProbeSize([blockObj.Channels.probe]);
      if probeSize == 0
         flag = true;
         return;
      end
      
      for iCh = 1:blockObj.NumChannels
         [blockObj.Channels(iCh).chNum,...
               blockObj.Channels(iCh).chStr] = getChannelNum(...
               blockObj.Channels(iCh).custom_channel_name,probeSize,false);
      end
   case 'Matfile'
      if ~blockObj.OnRemote
         linkStr = nigeLab.utils.getNigeLink('nigeLab.defaults.Block',19,...
            'custom load function');
         nigeLab.utils.cprintf('[1.000,0.345,0.000]*','\nMatfile detected!\n');
         nigeLab.utils.cprintf('Text','->\tBe sure you handled everything\n');
         fprintf(1,'\tcorrectly in your %s!\n',linkStr);
      end
      
   otherwise
      error(['nigeLab:' mfilename ':UnsupportedRecType'],...
         '''%s'' is not a supported RecType.',blockObj.RecType);
end
flag = true;

   function [chNum,chString] = getChannelNum(channelName,probeSize,zIndex)
      %GETCHANNELNUM  Get numeric and string values for channel NUMBER
      
      if nargin < 3
         zIndex = true; % Zero-indexed channel names
      end
      numericIndex = regexp(channelName, '\d');
      str = channelName(numericIndex);
      num = str2double(str);
      
      if zIndex
         chNum = rem(num,probeSize);
      else
         chNum = rem(num-1,probeSize)+1;
      end
      chString = num2str(chNum,'%03g');
   end

   function probeSize = getProbeSize(probe)
      %GETPROBESIZE Return max. # channels per probe
      u = unique(probe);
      nPerProbe = zeros(1,numel(u));
      for i = 1:numel(u)
         nPerProbe(i) = sum(probe == u(i));
      end
      switch max(nPerProbe)
         case 0
            probeSize = 0;
         case num2cell(1:16)
            probeSize = 16;
         case num2cell(17:32)
            probeSize = 32;
         case num2cell(33:64)
            probeSize = 64;
         otherwise
            probeSize = max(nPerProbe);
      end
   end

end