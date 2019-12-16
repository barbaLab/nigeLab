function flag = linkToData(tankObj)
flag = true;
A=tankObj.Animals;
for ii=1:numel(A)
    flag = flag && A(ii).linkToData;
end
tankObj.save;
end

