function flag = doRawExtraction(tankObj)
%% DORAWEXTRACTION   Convert raw data files to Matlab BLOCKS
%
%  tank = nigeLab.Tank();
%  flag = doRawExtraction(tank);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% LOOP THROUGH EACH ANIMAL IN TANK AND EXTRACT RAW DATA
A=tankObj.Animals;
flag = false(1,numel(A));
for ii=1:numel(A)
   flag(ii) = doRawExtraction(A(ii)); 
end
fprintf(1,'Raw conversion completed for: %s \n.',tankObj.Name);

end