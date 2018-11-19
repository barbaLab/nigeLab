function CAR(animalObj)
%CAR Summary of this function goes here
%   Detailed explanation goes here

B=animalObj.Blocks;
for ii=1:numel(B)
    B(ii).CAR;
end
fprintf(1,'Animal %s, done.',animalObj.Name);
end

