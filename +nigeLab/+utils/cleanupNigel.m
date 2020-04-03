function cleanupNigel(tankPath)
%CLEANUPNIGEL Deletes all nigelFiles at TOP-LEVEL of `tankPath` (input)
%
%   nigeLab.utils.cleanupNigel(tankPath);
%   ```
%       nigeLab.utils.cleanupNigel('/path/to/TANK');
%   ```
%       * The above would clear the following filetypes in /path/to/TANK:
%           + *_Pars.mat
%           + *_Block.mat
%           + *_Animals.mat
%           + *_Tank.mat
%           + *.nigelBlock
%           + *.nigelAnimal
%           + *.nigelTank
%
% -- Input --
%   tankPath    :       (char array) Path of TANK folder to clean

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

% Iterates on elements of struct array `d`
for ii=d'
   delete(fullfile(ii.folder,ii.name)) 
end

function c = append(a,b)
    a = reshape(a,1,numel(a));
    b = reshape(a,1,numel(b));
    c = [a,b];
