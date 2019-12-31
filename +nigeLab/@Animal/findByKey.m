function [a,idx] = findByKey(animalObjArray,keyStr,keyType)
%FINDBYKEY  Returns the animal corresponding to keyStr from array
%
%  example:
%  animalObjArray = tankObj{:}; % Get all animals from tank
%  a = findByKey(animalObjArray,keyStr); % Find specific animal
%  [a,idx] = findByKey(animalObjArray,keyStr); % Return index into
%                                   animal array as well
%
%  a = findByKey(animalObjArray,privateKey,'Private');
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
      'Need to provide animal array and hash key at least.');
else
   if isa(keyStr,'nigeLab.Animal')
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

a = nigeLab.Animal.Empty(); % Initialize empty Animal array
idx = [];

% Loop through array of animals, breaking the loop if an actual
% animal is found. If animal index is greater than the size of
% array, then returns an empty double ( [] )
nAnimalKeys = numel(keyStr);
if nAnimalKeys > 1
   cur = 0;
   while ((numel(a) < numel(keyStr)) && (cur < nAnimalKeys))
      cur = cur + 1;
      [a_tmp,idx_tmp] = findByKey(animalObjArray,keyStr(cur),keyType);
      a = [a,a_tmp];%#ok<*AGROW>
      idx = [idx, idx_tmp];
   end
   return;
end

% If any of the keys match, return the corresponding block.
thisKey = getKey(animalObjArray,keyType);
idx = find(ismember(thisKey,keyStr),1,'first');
if ~isempty(idx)
   a = animalObjArray(idx);
end

end