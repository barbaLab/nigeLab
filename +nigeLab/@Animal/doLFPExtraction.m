function flag = doLFPExtraction(animalObj)
%% DOLFPEXTRACTION  Do LFP extraction on all blocks for this animal.
%
%  a = nigeLab.Animal();
%  doRawExtraction(a);
%  flag = doLFPExtraction(a);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% LOOP THROUGH EACH BLOCK IN ANIMAL AND DO DECIMATION
B=animalObj.Blocks;
flag = false(1,numel(B));
for ii=1:numel(B)
    flag(ii) = doLFPExtraction(B(ii));
end
animalObj.save;
fprintf(1,'LFP extraction completed for: %s \n.',animalObj.Name);
flag = all(flag);
end

