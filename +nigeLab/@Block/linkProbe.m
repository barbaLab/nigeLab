function flag = linkProbe(blockObj)
%LINKPROBE  Connect probe metadata saved on the disk to the structure
%
%  blockObj = nigeLab.Block;
%  flag = linkProbe(blockObj);
%
% flag returns true if blockObj.Probes is empty.
%
% See also: nigeLab, nigeLab.Block, nigeLab.Block/takeNotes,
%           nigeLab.Block/parseNotes

% Check that the block is set up to parse Probe metadata
blockObj.checkCompatibility('Probes');

% Get probe ane notes info structs
updateParams(blockObj,'Probe');
probe = blockObj.Pars.Probe;

% Initialize the update flags
flag = false;
updateFlag = false(1,blockObj.NumChannels);
if isempty(get(blockObj,'Probes'))
   blockObj.Probes = struct;
end

if isfield(blockObj.Notes,'Probes')
   nigeLab.utils.printLinkFieldString(...
      blockObj.getFieldType('Probes'),'Probes',true);
   probePorts = fieldnames(blockObj.Notes.Probes);
   % Get the correct file associated with this recording in terms of
   % experimental probes. 
   for ii = 1:numel(probePorts)
      probeName = blockObj.Notes.Probes.(probePorts{ii}).name;
      probeFile = sprintf(probe.Str,probeName);
      fName = fullfile(blockObj.Output,[blockObj.Name ...
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

      if numel(fieldnames(blockObj.Probes))==0
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
      

      fraction_done = 100 * (iCh / max(blockObj.Mask));
      fprintf(1,'\b\b\b\b\b%.3d%%\n',round(fraction_done))
   end
end

end