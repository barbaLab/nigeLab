function flag = doReReference(tankObj)
%% DOREREFERENCE  Do common-average re-reference for all animals in tankObj
%
%  tank = nigeLab.Tank();
%  doRawExtraction(tank);
%  doUnitFilter(tank);
%  flag = doReReference(tank);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% LOOP THROUGH EACH ANIMAL IN TANK AND DO COMMON AVERAGE RE-REFERENCE
A=tankObj.Children;
flag = false(1,numel(A));
for ii=1:numel(A)
    flag(ii) = doReReference(A(ii));
end
fprintf(1,'CAR completed for: %s \n.',tankObj.Name);
flag = all(flag);

end

