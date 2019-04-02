function flag = updatePaths(tankObj,SaveLoc)

flag = false;
A=tankObj.Animals;
if nargin ==2
    tankObj.Paths.SaveLoc = SaveLoc;
end
for ii=1:numel(A)
    if nargin <2
        p = A(ii).Paths.SaveLoc;
    else
        p = fullfile(SaveLoc,A(ii).Name); 
    end
    A(ii).updatePaths(p);
end
flag = true;

end