function flag = doReReference(animalObj)
%% DOREREFERENCE  Do common-average re-reference for all blocks in animalObj
%
%  a = nigeLab.Animal();
%  doRawExtraction(a);
%  doUnitFilter(a);
%  flag = doReReference(a);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% LOOP THROUGH EACH BLOCK IN ANIMAL AND DO COMMON AVERAGE RE-REFERENCE
B=animalObj.Blocks;
flag = false(1,numel(B));
for ii=1:numel(B)
    flag(ii) = doReReference(B(ii));
end
fprintf(1,'CAR completed for: %s \n.',animalObj.Name);
end

