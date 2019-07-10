function flag = updatePaths(animalObj,SaveLoc)

flag = false;
B=animalObj.Blocks;

if nargin ==2
    animalObj.Paths.SaveLoc = SaveLoc;
end

for ii=1:numel(B)
    
    p = fullfile(animalObj.Paths.SaveLoc,B(ii).Name);
    B(ii).updatePaths(p);
   
end
animalObj.save;
flag = true;

end
