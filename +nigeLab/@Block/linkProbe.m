function flag = linkProbe(blockObj)
%% LINKPROBE  Connect probe metadata saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = LINKPROBE(b);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE PROBE INFORMATION
% Get probe ane notes info structs
probe = nigeLab.defaults.Probe();
blockObj.updateParams('Probe');

% Initialize the update flags
flag = false;
updateFlag = false(1,blockObj.NumChannels);

if isfield(blockObj.Notes,'Probes')
   nigeLab.utils.printLinkFieldString(blockObj.getFieldType('Probes'),'Probes');
   probePorts = fieldnames(blockObj.Notes.Probes);
   % Get the correct file associated with this recording in terms of
   % experimental probes. 
   for ii = 1:numel(probePorts)
      probeName = blockObj.Notes.Probes.(probePorts{ii}).name;
      probeFile = sprintf(probe.Str,probeName);
      fName = fullfile(blockObj.Paths.Probes.dir,[blockObj.Name ...
                        probe.Delimiter probeFile]);
      if exist(fName,'file')==0
         % If the electrode file doesn't exist from default location
         eName = fullfile(probe.ElectrodesFolder,probeFile);
         if exist(eName,'file')==0
            % Create one using template
            copyfile(fullfile(probe.Folder,probe.File),fName,'f');
         else
            % Otherwise copy over the existing electrode file
            copyfile(eName,fName,'f');
         end
      end
      
      % Assign to ".Ch" field because later, can add things like ".Imp"
      % etc. for impedance values and other things associated with the
      % probes.
      blockObj.Probes.(probePorts{ii}).Ch = readtable(fName);
      blockObj.updateStatus('Probes',true,ii);
   end
   
   % For each channel, update metadata from probe config file
   for iCh = blockObj.Mask

      if isempty(blockObj.Probes)
         flag = true;
      else
         curCh = blockObj.Channels(iCh).chip_channel;
         streamIdx = blockObj.Channels(iCh).board_stream;
         % Go through all ports (or boards, really)
         for ii = 1:numel(probePorts)
            % If this is the correct one
            if blockObj.Notes.Probes.(probePorts{ii}).stream==streamIdx
               % Get the metadata for the correct channel
               ch = blockObj.Probes.(probePorts{ii}).Ch;
               v = ch.Properties.VariableNames;
               if strcmp(blockObj.FileExt,'.rhs')
                  probeInfo = ch(RHD2RHS(ch.RHD_Channel,blockObj.NumChannels)==curCh,:);
               else
                  probeInfo = ch(ch.RHD_Channel==curCh,:);
               end

               % Assign all the included variables (columns) to channel
               % metadata.
               for iV = 1:numel(v)
                  blockObj.Channels(iCh).(v{iV})=probeInfo.(v{iV});
               end
               break;
            end
         end
      end
      

      fraction_done = 100 * (iCh / blockObj.NumChannels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
   end
end

end