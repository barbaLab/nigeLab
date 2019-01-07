function linkToData(animalObj)

B=animalObj.Blocks;
for ii=1:numel(B)
    B(ii).linkToData;
end
animalObj.save;

end

