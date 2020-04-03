%% Clean up nigel's mess
function cleanupNigel(tankPath)
% CLEANUPNIGEL deletes all nigelFiles in the define tankFolder. 
% ie deletes all _Pars.mat files, all Block, Animals and Tank files and all
% .nigelObj files. 

d = dir(fullfile(tankPath));
[tankPath,tankName] = fileparts(tankPath);
tankName = strrep(tankName,'_Tank','');
d = append(d,...
    fullfile(tankPath,[tankName '_Pars.mat']));

d = append(d,...
    dir(fullfile(tankPath,'.nigelTank')));
d = append(d,...
    dir(fullfile(tankPath,'_Pars.mat')));
d = append(d,...
    dir(fullfile(tankPath,'_Animal.mat')));

d = append(d,...
    dir(fullfile(tankPath,'*','.nigelAnimal')));
d = append(d,...
    dir(fullfile(tankPath,'*','_Block.mat')));
d = append(d,...
    dir(fullfile(tankPath,'*','_Pars.mat')));


d = append(d,...
    dir(fullfile(tankPath,'*','*','.nigelBlock')));


for ii=d'
   delete(fullfile(ii.folder,ii.name)) 
end

function c = append(a,b)
    a = reshape(a,1,numel(a));
    b = reshape(a,1,numel(b));
    c = [a,b];
