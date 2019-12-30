function flag = linkToData(tankObj)
%LINKTODATA  Links data of all Animals in the Tank to the correct files
%
%  flag = tankObj.linkToData();

flag = true;
A=tankObj.Animals;
for ii=1:numel(A)
    flag = flag && A(ii).linkToData;
end
tankObj.save;
end