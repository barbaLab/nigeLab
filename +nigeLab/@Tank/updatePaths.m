function flag = updatePaths(tankObj,SaveLoc)
%% Script to update the path tree of the tank Object.

flag = false;
A=tankObj.Animals;
if nargin ==2
    tankObj.Paths.SaveLoc = SaveLoc;
else
    tankObj.Paths.SaveLoc = fullfile(fileparts(tankObj.Paths.SaveLoc),...
        tankObj.Name);
end
for ii=1:numel(A)
%     if nargin <2
%         p = A(ii).Paths.SaveLoc;
%     else
%         p = fullfile(SaveLoc,A(ii).Name);
%     end      

p = fullfile(tankObj.Paths.SaveLoc,A(ii).Name); 

    A(ii).updatePaths(p);
end
flag = true;
tankObj.save;
end