function flag = setTrialMask(blockObj,includedChannelIndices)
%SETCHANNELMASK    Set included channels to use for subsequent analyses
%
%  flag = blockObj.SETCHANNELMASK(includedChannelIndices); % no UI
%
%  inputs --
%  --> includedChannelIndices : (double) indexing array for .Channels, or
%                               (logical) mask of same size as .Channels,
%                                         where TRUE denotes that the
%                                         .Channels element should be kept
%                                         for further processing.
%
%     --> If blockObj is an array, then includedChannelIndices may be
%           specified as a cell array of indexing vectors, which must 
%           contain one cell per block in the array.
%
%  Sets blockObj.TrialMask property, which is an indexing array (double) that
%  specifies the indices of the blockObj.Channels struct array that are to
%  be included for subsequent analyses 
%     (e.g. blockObj.Channels(blockObj.Mask).(fieldOfInterest) ... would
%           return only the "good" channels for that recording).

% PARSE INPUT
if nargin < 2
   includedChannelIndices = nan;
end

if numel(blockObj) > 1
   flag = true;
   if iscell(includedChannelIndices)
      if numel(blockObj) ~= numel(includedChannelIndices)
         error(['nigeLab:' mfilename ':BlockArrayInputMismatch'],...
            ['%g elements in blockObj array input, ' ...
             'but only %g elements in channel index cell array input'],...
             numel(blockObj),numel(includedChannelIndices));
      end
   end   
   for i = 1:numel(blockObj)
      if iscell(includedChannelIndices)
         flag = flag && blockObj(i).setChannelMask(includedChannelIndices{i});
      else
         flag = flag && blockObj(i).setChannelMask(includedChannelIndices);
      end
   end
   return;
else
   flag = false;
end

% If it is logical, make sure the number of logical elements makes sense
if islogical(includedChannelIndices)
   numel(includedChannelIndices) == size(blockObj.Trial,1)
end
blockObj.TrialMask = find(maskVal);


waitfor(h);
flag = true;

end