function hashString = makeHash(n)
%% MAKEHASH  Utility to make random hashstring for naming a "row"
%
%  hashString = nigeLab.utils.MAKEHASH(n);
%  --> returns [n x 1] cell array of random hashStrings
%  --> if n is not included, default value is 1 (still returns cell)
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
if nargin < 1
   n = 1;
end

%%
hashNum = randi(10,n,8) + OFFSET_NUM - 1;
hashAlpha = randi(26,n,8) + OFFSET_ALPHA - 1;
hashIndex = randperm(16);
hash = [hashNum,hashAlpha];
hashString = cellstr(char(hash(:,hashIndex)));

end