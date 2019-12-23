function flag = linkToData(animalObj)
%LINKTODATA  Link data of all Blocks in Animal to the correct files
%
%  flag = animalObj.linkToData();

flag = true;
B=animalObj.Blocks;
for ii=1:numel(B)
   flag = flag && B(ii).linkToData;
end
animalObj.save;

end

