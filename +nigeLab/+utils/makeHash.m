function hashString = makeHash(nigelObj,mode,n)
%% MAKEHASH  Utility to make random hashstring for naming a "row"
%
%  hashString = nigeLab.utils.MAKEHASH(n);
%  --> mode can be either 'random' or 'unique', if omitted in 'random'
%  --> in Random mode a number of outputs, n, can be specified.
%      in this case it returns [n x 1] cell array of random hashStrings
%      if n is not included, default value is 1 (still returns cell)
%  --> default nigelObj is Block.
% TODO unique moethod for Block!
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
OFFSET_ALPHA = 97; % double('a')

%%

if nargin <1
    nigelObj = nigeLab.Block.Empty(1);
elseif nargin <2
    mode = 'random';
    n = 1;
elseif nargin < 3
    if isnumeric(mode)
        n = mode;
        mode = 'random';
    else
        n =1;
    end
else
end


switch class(nigelObj)
    %% depending on the class do something different
    case  'nigeLab.Block'
        if strcmp(mode,'random')
            hashString = GenRandomStrings(n,OFFSET_ALPHA,OFFSET_NUM);
            hashString = cellfun(@(x) ['BB' x(3:end)],hashString,'UniformOutput',false);
        elseif strcmp(mode,'unique')
            hashString = makeHash(nigelObj,'random',1);
        end
    case  'nigeLab.Animal'
        if all(isempty(nigelObj.Blocks)) || strcmp(mode,'random')
            hashString=GenRandomStrings(n,OFFSET_ALPHA,OFFSET_NUM);
        elseif strcmp(mode,'unique')
            blockStrings = nigelObj.Blocks.getKey;
            hash = xorcascade(blockStrings);
            hashString = char(mod(hash,42)+OFFSET_NUM);
        end
        hashString = cellfun(@(x) ['AA' x(3:end)],hashString,'UniformOutput',false);
end
end

function hash = xorcascade(x)
if numel(x) == 1
    hash = int8(x{1});
    return
end
hash = bitxor(int8(x{1}),xorcascade(x(2:end)));
end



function hashString=GenRandomStrings(n,OFFSET_ALPHA,OFFSET_NUM)
hashNum = randi(10,n,8) + OFFSET_NUM - 1;
hashAlpha = randi(26,n,8) + OFFSET_ALPHA - 1;
% Set the first column to ALWAYS be a letter so that hash always returns
% valid variable or field names for convenience
hashIndex = randperm(15)+1;
hash = [hashAlpha(:,1),hashNum,hashAlpha(:,2:8)];
hashString = cellstr(char(hash(:,[1,hashIndex])));
end