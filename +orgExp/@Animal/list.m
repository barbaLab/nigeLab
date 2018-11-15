function L = list(animalObj)
%% LIST  Give list of properties asso

jj=1;
for ii=animalObj.Blocks
    tmp=ii.list;
    I=ismember(tmp.Properties.VariableNames,'Animals');
    L_(jj,:)=[tmp(1,I),tmp(1,~I)];
    jj=jj+1;
end
L_ = addvars(L_,[1:numel(animalObj.Blocks)]','NewVariableNames','N', 'Before', 1);
% L_.Properties.VariableNames(1)={'Animals'};
if nargout==0
    disp(L_);
else
    L=L_;
end



end