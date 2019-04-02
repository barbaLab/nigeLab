function flag = updatePaths(animalObj,SaveLoc)

flag = false;
B=animalObj.Blocks;

if nargin <2
    SaveLoc = animalObj.Paths.SaveLoc;
else
    animalObj.Paths.SaveLoc = SaveLoc;
end

for ii=1:numel(B)
    B(ii).genPaths(SaveLoc);
end
animalObj.save;
flag = true;

end