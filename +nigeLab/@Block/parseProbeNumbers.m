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
      % from a dual-headstage plugged into 2 different electrode arrays.
      portStream = nan(numel(blockObj.Channels),2);
      for iCh = 1:numel(blockObj.Channels)
         portStream(iCh,:) = [blockObj.Channels(iCh).port_number, ...
                              blockObj.Channels(iCh).board_stream];
      end
      [~,~,probe] = unique(portStream,'rows');
      for iCh = 1:numel(blockObj.Channels)
         blockObj.Channels(iCh).probe = probe(iCh);
      end
   case 'TDT'
      for iCh = 1:numel(blockObj.Channels)
         blockObj.Channels(iCh).probe = blockObj.Channels(iCh).port_number;
      end
   otherwise
      warning('%s is not a supported RecType.',blockObj.RecType);
      return;
end
flag = true;

end