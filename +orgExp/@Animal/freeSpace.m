function freeSpace(animalObj,ask)

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

B=animalObj.Blocks;
for ii=1:numel(B)
    ask = false;
    B(ii).freeSpace(ask);
end
animalObj.save;

end

