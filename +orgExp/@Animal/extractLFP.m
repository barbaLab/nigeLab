function extractLFP(animalObj)

B=animalObj.Blocks;
for ii=1:numel(B)
    B(ii).extractLFP;
end
animalObj.save;

end

