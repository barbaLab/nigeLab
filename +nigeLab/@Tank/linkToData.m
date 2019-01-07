function linkToData(tankObj)

A=tankObj.Animals;
for ii=1:numel(A)
    A(ii).linkToData;
end
tankObj.save;
end

