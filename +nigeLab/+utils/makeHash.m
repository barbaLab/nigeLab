function hashString = makeHash(nigelObj,keyMode,n)
%MAKEHASH  Utility to make random hashstring for naming a "row"
%
%  hashString = nigeLab.utils.MAKEHASH(nigelObj,keyMode,n);
%  --> keyMode can be either 'random' or 'unique', if omitted in 'random'
%  --> default nigelObj is Block.
%
%  hashString = nigeLab.utils.MAKEHASH(n);
%  --> Automatically sets keyMode to 'random'
%  --> in random keyMode a number of outputs, n, can be specified.
%      in this case it returns [n x 1] cell array of random hashStrings
%      if n is not included, default value is 1 (still returns cell)
%
% TODO unique method for Block!
%
%  e.g.
%  hashString = nigeLab.utils.makeHash(1);
%  T = table('FB','in progress','2019-11-25',...
%        {'VariableNames'},{'User','Status','Date'},...
%        {'RowNames'},hashString);
%
%  .
%  .
%  .
%
%  T(hashString{1},:).Status = 'complete';

%%
OFFSET_NUM = 48; % double('0') (numeric zero)
% OFFSET_ALPHA = 97; % double('a')

%%
if nargin <1
   nigelObj = nigeLab.Block.Empty(1);
   keyMode = 'random';
   n = 1;
elseif nargin <2
   keyMode = 'random';
   n = 1;
elseif nargin < 3
   if isnumeric(keyMode)
      n = keyMode;
      keyMode = 'random';
   else
      n = 1;
   end
else
   % Do nothing if all inputs are given
end

% Validate "mode"
if ~ismember(lower(keyMode),{'random','unique'})
   error(['nigeLab:' mfilename ':UnexpectedString'],...
      'Invalid ''mode'' (%s): should be ''random'' or ''unique''',keyMode);
end


%% Depending on input class,
switch class(nigelObj)
   %% depending on the class do something different
   case  'nigeLab.Block'
      if strcmpi(keyMode,'random')
         hashString = GenRandomStrings(n);
      elseif strcmpi(keyMode,'unique') 
         % placeholder?
%          if numel(nigelObj) > 1
%             hashString = [];
%             for i = 1:numel(nigelObj)
%                hashString = [hashString; nigeLab.utils.makeHash(...
%                   nigelObj(i),'unique',1)]; %#ok<*AGROW>
%             end
%             return;
%          end
         hashString = GenUniqueRandomStrings(n);
         hashString = prependSignature(hashString,'BB');
      end
   case  'nigeLab.Animal'
      if all(isempty(nigelObj.Children)) || strcmp(keyMode,'random')
         hashString=GenRandomStrings(n);
      elseif strcmpi(keyMode,'unique')
         blockStrings = nigelObj.Children.getKey;
         hash = xorcascade(blockStrings);
         hashString = char(mod(hash,42)+OFFSET_NUM);
      end
      hashString = prependSignature(hashString,'AA');
   case  'struct' % e.g. 'Channels'
      n = numel(nigelObj);
      if strcmpi(keyMode,'random')
         hashString = GenRandomStrings(n);
      elseif strcmpi(keyMode,'unique')
         hashString = GenUniqueRandomStrings(n);
      end
   otherwise
      if isnumeric(nigelObj)
         n = nigelObj;
         if strcmpi(keyMode,'random')
            hashString = GenRandomStrings(n);
         elseif strcmpi(keyMode,'unique')
            hashString = GenUniqueRandomStrings(n);
         end
      end
end
end

function hashString = prependSignature(hashString,sig)
%PREPENDSIGNATURE  Prepends the characters in sig to start of hashString
%
%  hashString = prependSignature(hashString,sig);
%
%  sig  -- char array to put on start (e.g. 'BB' for block)
%  hashString  -- cell array of char vectors

if ~ischar(sig)
   error(['nigeLab:' mfilename ':invalidSignature'],...
      '''sig'' input must be a char array');
end

k = numel(sig);
hashString = cellfun(@(x) [sig x((k+1):end)],hashString,...
            'UniformOutput',false);
end

% Function to use for example to get ANIMAL "ID" from BLOCK "CHILD"
% hash "ID" combinations:
function hash = xorcascade(x)
%XORCASCADE  Very simple helper function to get unique hash from "sub-hash"
%
%  hash = xorcascade(x);

if numel(x) == 1
   hash = int8(x{1});
   return
end
hash = bitxor(int8(x{1}),xorcascade(x(2:end)));
end

% Function that does the random string generation (not really a "proper
% hash" but whatever, this is more for anonymization or unique "ID"
% linking)
function hashString = GenRandomStrings(n,nNum,nAlpha)
%GENRANDOMSTRINGS  Create the random strings for "hashes"
%
%  hashString = GenRandomStrings(n);
%  hashString = GenRandomStrings(n,nNum);
%  hashString = GenRandomStrings(n,nNum,nAlpha);
%
%  n        --  Number of returned random strings
%  nNum     --  Number of numeric characters per string
%  nAlpha   --  Number of alphabetical characters per string
%
%  hashString  --  Cell array of random strings

OFFSET_NUM = 48; % double('0') (numeric zero)
OFFSET_ALPHA = 97; % double('a')

if nargin < 2
   nNum = 8;
end
if nargin < 3
   nAlpha = 8;
else
   nAlpha = max(nAlpha,1); % Must have at least 1 alphabetical element
end
nTotal = nNum + nAlpha;
hashNum = randi(10,n,nNum) + OFFSET_NUM - 1;
hashAlpha = randi(26,n,nAlpha) + OFFSET_ALPHA - 1;
% Set the first column to ALWAYS be a letter so that hash always returns
% valid variable or field names for convenience
hashIndex = randperm(nTotal-1)+1;
hash = [hashAlpha(:,1),hashNum,hashAlpha(:,2:nAlpha)];
hashString = cellstr(char(hash(:,[1,hashIndex])));
end

% Function that iterates to validate that unique random strings are made
function hashString = GenUniqueRandomStrings(n,nNum,nAlpha)
%GENUNIQUERANDOMSTRINGS  Create the random strings for UNIQUE "hashes"
%
%  hashString = GenUniqueRandomStrings(n);
%  hashString = GenUniqueRandomStrings(n,nNum);
%  hashString = GenUniqueRandomStrings(n,nNum,nAlpha);
%
%  n        --  Number of returned random strings
%  nNum     --  Number of numeric characters per string (optional)
%  nAlpha   --  Number of alphabetical characters per string (optional)
%
%  hashString  --  Cell array of UNIQUE random strings

if nargin < 2
   nNum = 8;
end
if nargin < 3
   nAlpha = 8;
else
   nAlpha = max(nAlpha,1); % Must have at least 1 alphabetical element
end

hashString = [];
while n > 0
   tmp = [hashString; GenRandomStrings(n,nNum,nAlpha)];
   hashString = unique(tmp);
   n = numel(hashString) - n;
end

end