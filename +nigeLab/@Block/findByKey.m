function [b,idx] = findByKey(blockObjArray,keyStr,keyType)
%FINDBYKEY  Returns the block corresponding to keyStr from array
%
%  example:
%  blockObjArray = tankObj{:,:}; % Get all blocks from tank
%  b = findByKey(blockObjArray,keyStr); % Find specific block
%  [b,idx] = findByKey(blockObjArray,keyStr);  % Returns block and
%                 corresponding index into array that relates to
%                 that block (useful for arrays that are matched
%                 with block).
%
%  b = findByKey(blockObjArray,privateKey,'Private');
%  --> By default, uses 'Public' key to find the Block; this would
%      find the associated 'Private' key that matches the contents
%      of privateKey.
%
%  keyStr : Can be char array or cell array. If it's a cell array,
%           then b is returned as a row vector with number of
%           elements corresponding to number of cell elements.
%
%  keyType : (optional) Char array. Should be 'Private' or
%                          'Public' (default if not specified)

if nargin < 2
   error(['nigeLab:' mfilename ':tooFewInputs'],...
      'Need to provide block array and hash key at least.');
else
   if isa(keyStr,'nigeLab.Block')
      keyStr = getKey(keyStr);
   end
   if ~iscell(keyStr)
      keyStr = {keyStr};
   end
end

if nargin < 3
   keyType = 'Public';
else
   if ~ischar(keyType)
      error(['nigeLab:' mfilename ':badInputType2'],...
         'Unexpected class for ''keyType'' (%s): should be char.',...
         class(keyType));
   end
   % Ensure it is the correct capitalization
   keyType = lower(keyType);
   keyType(1) = upper(keyType(1));
   if ~ismember(keyType,{'Public','Private'})
      error(['nigeLab:' mfilename ':badKeyType'],...
         'keyType must be ''Public'' or ''Private''');
   end
end

b = nigeLab.Block.Empty(); % Initialize empty Block array
idx = [];

% Loop through array of blocks, breaking the loop if an actual
% block is found. If block index is greater than the size of
% array, then returns an empty double ( [] )
nBlockKeys = numel(keyStr);
if nBlockKeys > 1
   cur = 0;
   while ((numel(b) < numel(keyStr)) && (cur < nBlockKeys))
      cur = cur + 1;
      [b_tmp,idx_tmp] = findByKey(blockObjArray,keyStr(cur),keyType);
      b = [b,b_tmp]; %#ok<*AGROW>
      idx = [idx,idx_tmp];
   end
   return;
end

% If any of the keys match, return the corresponding block.
thisKey = getKey(blockObjArray,keyType);
idx = find(ismember(thisKey,keyStr),1,'first');
if ~isempty(idx)
   b = blockObjArray(idx);
end

end