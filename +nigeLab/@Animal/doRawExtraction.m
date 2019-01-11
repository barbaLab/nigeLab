function flag = doRawExtraction(animalObj)
%% DORAWEXTRACTION  Convert raw data files to Matlab TANK-BLOCK structure object
%
%  a = nigeLab.Animal();
%  flag = doRawExtraction(a);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% LOOP THROUGH EACH BLOCK IN ANIMAL AND EXTRACT RAW DATA
B=animalObj.Blocks;
flag = false(1,numel(B));
for ii=1:numel(B)
    flag = doRawExtraction(B(ii));
end
fprintf(1,'Raw conversion completed for: %s \n.',animalObj.Name);
flag = all(flag);
end