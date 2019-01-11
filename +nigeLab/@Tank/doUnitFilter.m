function flag = doUnitFilter(tankObj)
%% DOUNITFILTER   Do multi-unit bandpass filter on each block in animalObj
%
%  tank = nigeLab.Tank();
%  doRawExtraction(tank);
%  flag = doUnitFilter(tank);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% DO BANDPASS FILTER ON EACH BLOCK IN TANK
A=tankObj.Animals;
flag = false(1,numel(A));
for ii=1:numel(A)
    flag(ii) = doUnitFilter(A(ii));
end
fprintf(1,'Bandpass filtering completed for: %s \n.',tankObj.Name);
flag = all(flag);

end

