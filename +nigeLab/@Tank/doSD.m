function flag = doSD(tankObj)
%% DOSD   Do spike detection on all animals associated with tankObj
%
%  tank = nigeLab.Tank();
%  doRawExtraction(tank);
%  doUnitFilter(tank);
%  doReReference(tank);
%  flag = doSD(tank);
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% RUN SPIKE DETECTION FOR EACH ANIMAL IN BLOCK
A=tankObj.Animals;
flag = false(1,numel(A));
for ii=1:numel(A)
    flag(ii) = doSD(A(ii));
end
fprintf(1,'Spike detection completed for: %s \n.',tankObj.Name);
flag = all(flag);

end

