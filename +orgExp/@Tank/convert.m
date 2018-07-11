function flag = convert(tankObj)
%% CONVERT  Convert raw data files to Matlab TANK-BLOCK structure object
%
A=tankObj.Animals;
for aa=1:numel(A)
   A(aa).convert; 
end
flag=true;