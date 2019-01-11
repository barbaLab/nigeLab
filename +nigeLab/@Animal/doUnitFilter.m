function flag = doUnitFilter(animalObj)
%% DOUNITFILTER   Do multi-unit bandpass filter on each block in animalObj
%
%  a = nigeLab.Animal();
%  doRawExtraction(a);
%  flag = doUnitFilter(a);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% DO BANDPASS FILTER ON EACH BLOCK IN ANIMAL
B=animalObj.Blocks;
flag = false(1,numel(B));
for ii=1:numel(B)
    flag(ii) = doUnitFilter(B(ii));
end
fprintf(1,'Bandpass filtering completed for: %s \n.',animalObj.Name);
flag = all(flag);

end

