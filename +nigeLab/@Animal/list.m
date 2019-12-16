function L = list(animalObj,keyIdx)
%% LIST  Give list of properties associated with this block
%
%  L = animalObj.list();

if nargin < 2
   keyIdx = [];
end

if numel(animalObj) > 1
   L_ = [];
   for i = 1:numel(animalObj)
      L_ = [L_; animalObj(i).list(i)];
   end
   L_.Properties.RowNames=cellstr(num2str((1:size(L_,1))'));
   if nargout > 0  
      L = L_;
   else
      disp(L_);
   end
   return;
end

L_ = [];
for n = 1:numel(animalObj.Blocks)
   tmp = animalObj.Blocks(n).list([keyIdx, n]);
   I=ismember(tmp.Properties.VariableNames,'Animals');
   % Rearranges the order of columns:
   L_ = [L_; tmp(1,I),tmp(1,~I)]; %#ok<*AGROW>

end

if isempty(keyIdx)
   rowIdx = num2str((1:n)');
else
   rowIdx = num2str([ones(n,1)*keyIdx, (1:n)']);
end
   
L_.Properties.RowNames=cellstr(rowIdx);
% L_.Properties.VariableNames(1)={'Animals'};

if nargout==0
   disp(L_);
else
   L=L_;
end



end