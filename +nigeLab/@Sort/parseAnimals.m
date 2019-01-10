function flag = parseAnimals(sortObj,animalObj)
%% PARSEANIMALS  Add blocks to Sort object from Animal objects
%
%  flag = PARSEANIMALS(sortObj,nigelObj);
%
%  --------
%   INPUTS
%  --------
%   sortObj    :     nigeLab.Sort class object that is under construction.
%
%   animalObj  :     nigeLab.Animal class objects
%
%
% By: Max Murphy  v1.0    2019/01/08  Original version (R2017a)

%% CONCATENATE ALL BLOCKS AND THEN PARSE BLOCK ARRAY
blockObjArray = [];
for ii = 1:numel(animalObj)
   blockObjArray = [blockObjArray; animalObj(ii).Blocks]; %#ok<AGROW>
end
flag = parseBlocks(sortObj,blockObjArray);

end