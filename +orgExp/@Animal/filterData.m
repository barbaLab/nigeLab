function filterData(animalObj)

B=animalObj.Blocks;
for ii=1:numel(B)
    B(ii).filterData;
end

end

