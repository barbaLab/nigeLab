function parseProbes(animalObj)
%PARSEPROBES  Parse .Probes property struct fields using child "blocks"
%
%  animalObj.parseProbes();
%
%  In use as a listener callback (handle is animalObj.PropListener(3)).
%  Also called in `nigeLab.Animal/addChildBlock` at the end, if the mask
%  size has increased or if the number of non-empty Child Blocks is equal
%  to the mask size.

if ~isfield(animalObj.HasParsInit,'Animal')
   animalObj.updateParams('Animal');
elseif ~animalObj.HasParsInit.Animal
   animalObj.updateParams('Animal');
end

if isempty(animalObj.Children)
   nigeLab.utils.cprintf('Comments',...
      'No child blocks of Animal: %s -- skipped probe parsing\n',...
      animalObj.Name);
   return;
end

% Get all possible unique probe/channel number combinations for this Animal
C = [];
B = animalObj.Children(~isempty(animalObj.Children));
B = B([B.IsMasked]);
for b = B
   if isempty(b)
      continue;
   end
   if isempty(C)
      C = b.ChannelID;
      C_red = C;
   else
      C = union(C,b.ChannelID,'rows');
      C_red = intersect(C_red,b.ChannelID,'rows');
   end
end

if isempty(C)
   nigeLab.utils.cprintf('Comments',...
      'No non-empty Child Blocks of Animal: %s -- skipped probe parsing\n',...
      animalObj.Name);
   return;
end


% Get the probe struct array for all probe/channel combos in this animal's
% recordings
animalObj.Probes = probeStructArray(C);

% Get the aggregate "mask" for this animal (an indexing array)
animalObj.Mask = find(ismember(C,C_red,'rows'));

% Assign each channel a hash ID so it can be easily linked to parent
for b = B
   bC = b.ChannelID;   
   for iCh = 1:size(bC,1)
      pCh = bC(iCh,:);
      idx = find(ismember(C,pCh,'rows'),1,'first');
      b.Channels(iCh).ID = animalObj.Probes(idx).ID;
      
   end
   
   % Also, remove child channels that are not present in all recordings
   % (if parameter is set as such).
   if animalObj.Pars.Animal.UnifyChildMask
      setChannelMask(b,ismember(bC,C_red,'rows'));
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