function spikeDetection(animalObj)

B=animalObj.Blocks;
for ii=1:numel(B)
    B(ii).spikeDetection;
end

end

