function pars = Animal()
% ANIMAL  Template for initializing parameters for nigeLab.Animal class
%
%   pars = nigeLab.defaults.Animal;

%%
pars = struct;
pars.DefaultRecLoc = 'R:/';
pars.DefaultSaveLoc = 'P:/';
pars.SaveLocPrompt = 'Set Processed Animal Location';
pars.SupportedFormats = {'.rhs','.rhd','tdt'};
pars.FolderIdentifier = '.nigelAnimal';
pars.OnlyBlockFoldersAtAnimalLevel = true; % false if other kinds of folders exist there
pars.UnifyChildBlockMask = true;  % Set false to allow different recordings to include unique channels

end

