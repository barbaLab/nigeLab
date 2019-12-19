function flag = linkToData(animalObj)
flag = true;
B=animalObj.Blocks;
for ii=1:numel(B)
   flag = flag && B(ii).linkToData;
end
animalObj.save;

end

