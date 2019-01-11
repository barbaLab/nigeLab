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
notes = nigeLab.defaults.Experiment();
blockObj.updateParams('Probe');

% Initialize the update flags
flag = false;
updateFlag = false(1,blockObj.NumChannels);

if isfield(notes,'Probes')
   fprintf(1,'\nLinking PROBES...000%%\n');
   probePorts = fieldnames(notes.Probes);
   % Get the correct file associated with this recording in terms of
   % experimental probes. 
   for ii = 1:numel(probePorts)
      probeName = notes.Probes.(probePorts{ii}).name;
      probeFile = sprintf(probe.Str,probeName);
      fName = fullfile(blockObj.paths.MW,[blockObj.Name ...
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
      notes.Probes.(probePorts{ii}).Ch = readtable(fName);
   end
   
   % For each channel, update metadata from probe config file
   for iCh = blockObj.Mask

      if ~exist(fullfile(fname),'file')
         flag = true;
      else
         updateFlag(iCh) = true;
         curCh = blockObj.Channels(iCh).chip_channel;
         streamIdx = blockObj.Channels(iCh).board_stream;
         % Go through all ports (or boards, really)
         for ii = 1:numel(probePorts)
            % If this is the correct one
            if notes.Probes.(probePorts{ii}).stream==streamIdx
               % Get the metadata for the correct channel
               ch = notes.Probes.(probePorts{ii}).Ch;
               v = ch.Properties.VariableNames;
               if strcmp(blockObj.FileExt,'.rhs')
                  probeInfo = ch(RHD2RHS(ch.RHD_Channel)==curCh,:);
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
blockObj.updateStatus('Meta',updateFlag);

end