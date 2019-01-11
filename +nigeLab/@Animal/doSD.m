function flag = doSD(animalObj)
%% DOSD  Do spike detection on all blocks for this animal.
%
%  a = nigeLab.Animal();
%  doRawExtraction(a);
%  doUnitFilter(a);
%  doReReference(a);
%  flag = doSD(a);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% RUN SPIKE DETECTION FOR EACH BLOCK IN ANIMAL
B=animalObj.Blocks;
flag = false(1,numel(B));
for ii=1:numel(B)
    flag(ii) = doSD(B(ii));
end
fprintf(1,'Spike detection completed for: %s \n.',animalObj.Name);
flag = all(flag);

end

