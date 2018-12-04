function flag = doLFPExtraction(tankObj)
%% DOLFPEXTRACTION  Do LFP extraction on all animals in this tank.
%
%  tank = orgExp.Tank();
%  doRawExtraction(tank);
%  flag = doLFPExtraction(tank);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% LOOP THROUGH EACH ANIMAL IN TANK AND DO DECIMATION
A=tankObj.Animals;
flag = false(1,numel(A));
for ii=1:numel(A)
   flag(ii) = extractLFP(A(ii));
end
fprintf(1,'LFP extraction completed for: %s \n.',tankObj.Name);

end

