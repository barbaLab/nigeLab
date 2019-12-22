function parseProbes(animalObj)
%PARSEPROBES  Parse .Probes property struct fields using child "blocks"
%
%  animalObj.parseProbes();

animalObj.updateParams('Animal');

if isempty(animalObj.Blocks)
   nigeLab.utils.cprintf('Comments',...
      'No child blocks of Animal: %s -- skipped probe parsing\n',...
      animalObj.Name);
   return;
end

% Get all possible unique probe/channel number combinations for this Animal
channelID = [];
B = animalObj.Blocks(~isempty(animalObj.Blocks));
for b = B
   if isempty(b)
      continue;
   end
   if isempty(channelID)
      channelID = b.parseChannelID;
      channelID_red = channelID;
   else
      channelID = union(channelID,b.parseChannelID,'rows');
      channelID_red = intersect(channelID_red,b.parseChannelID,'rows');
   end
end

if isempty(channelID)
   nigeLab.utils.cprintf('Comments',...
      'No non-empty Child Blocks of Animal: %s -- skipped probe parsing\n',...
      animalObj.Name);
   return;
end


% Get the probe struct array for all probe/channel combos in this animal's
% recordings
animalObj.Probes = probeStructArray(channelID);

% Get the aggregate "mask" for this animal (an indexing array)
animalObj.Mask = find(ismember(channelID,channelID_red,'rows'));

% Assign each channel a hash ID so it can be easily linked to parent
for b = B
   bChannelID = b.parseChannelID;   
   for iCh = 1:size(bChannelID,1)
      pCh = bChannelID(iCh,:);
      idx = find(ismember(channelID,pCh,'rows'),1,'first');
      b.Channels(iCh).ID = animalObj.Probes(idx).ID;
      
   end
   
   % Also, remove child channels that are not present in all recordings
   % (if parameter is set as such).
   if animalObj.Pars.Animal.UnifyChildBlockMask
      setChannelMask(b,ismember(bChannelID,channelID_red,'rows'));
   end
end

   % Helper function to create "Probes" struct array
   function p = probeStructArray(channelID)
      % PROBESTRUCTARRAY   Fields: PCh (combo of probe number and channel
      %                                 number [probe channel])
      %                            ID  (unique alphanumeric channel Hash)
      p = struct('PCh',num2cell(channelID,2),...
                 'ID',nigeLab.utils.makeHash(size(channelID,1)));
   end
   
end