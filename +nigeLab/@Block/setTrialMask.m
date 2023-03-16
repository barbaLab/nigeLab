function flag = setTrialMask(blockObj,includedTrialIndices)
%SETTRIALMASK    Set the trials to consider for analysis and scoring 
%
%  flag = blockObj.SETTRIALMASK(includedTrialIndices); % no UI
%
%  inputs --
%  --> includedTrialIndices :   (double) indexing array for .Trial, or
%                               (logical) mask of same length as .Trial,
%                                         where TRUE denotes that the
%                                         .Trial element should be kept
%                                         for further processing.
%                               (empty or non existing) set mask to all
%                               Trials;
%
%     --> If blockObj is an array, then includedTrialIndices may be
%           specified as a cell array of indexing vectors, which must 
%           contain one cell per block in the array.
%
%  Sets blockObj.TrialMask property, which is an indexing array (double) that
%  specifies the indices of the Trials to use for analysis
% 

% PARSE INPUT
if nargin < 2
   includedTrialIndices = [];
end

if numel(blockObj) > 1
   flag = true;
   if iscell(includedTrialIndices)
      if numel(blockObj) ~= numel(includedTrialIndices)
         error(['nigeLab:' mfilename ':BlockArrayInputMismatch'],...
            ['%g elements in blockObj array input, ' ...
             'but only %g elements in channel index cell array input'],...
             numel(blockObj),numel(includedTrialIndices));
      end
   end   
   for i = 1:numel(blockObj)
      if iscell(includedTrialIndices)
         flag = flag && blockObj(i).setChannelMask(includedTrialIndices{i});
      else
         flag = flag && blockObj(i).setChannelMask(includedTrialIndices);
      end
   end
   return;
else
   flag = false;
end

% If it is logical, make sure the number of logical elements makes sense
if isempty(includedTrialIndices)
    maskVal = 1:size(blockObj.Trial,1);
elseif islogical(includedTrialIndices) && ...
        (numel(includedTrialIndices) == size(blockObj.Trial,1))
    maskVal = find(includedTrialIndices);
elseif isnumeric(includedTrialIndices) &&...
        max(includedTrialIndices) <= size(blockObj.Trial,1)
    maskVal = includedTrialIndices;
else
    error(['nigeLab:' mfilename ':TrialMaskError'],...
        'Trial mask has wrong format.');
end
blockObj.TrialMask = maskVal;
flag = true;

end