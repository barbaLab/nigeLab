function flag = clearSpace(animalObj,ask)
%% CLEARSPACE   Delete the raw data folder to free some storage space
%
%  a = orgExp.Animal;
%  flag = clearSpace(a);
%  flag = clearSpace(a,ask);
%
%  --------
%   INPUTS
%  --------
%  animalObj   :     orgExp ANIMAL class.
%
%    ask       :     True or false. CAUTION: setting this to false and
%                       running the CLEARSPACE method will automatically
%                       delete the rawData folder and its contents, without
%                       prompting to continue.
%
%  --------
%   OUTPUT
%  --------
%    flag      :     Boolean flag to report whether data was deleted.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
B=animalObj.Blocks;
flag = false(1,numel(B));

if nargin<2
    ask=true;
end

if ask
    promptMessage = sprintf('Do you want to delete the extracted raw files from animal %s?\nThis procedure is irreversible.',animalObj.Name);
    button = questdlg(promptMessage, 'Are you sure?', 'Cancel', 'Continue', 'Cancel');
    if strcmpi(button, 'Cancel')
        return;
    end
end


for ii=1:numel(B)
    ask = false;
    flag(ii) = B(ii).freeSpace(ask);
end
animalObj.save;
fprintf(1,'Finished clearing space for: %s \n.',animalObj.Name);

end

