function freeSpace(tankObj,ask)

if nargin<2
    ask=true;
end

if ask
    promptMessage = sprintf('Do you want to delete the extracted raw files from tank %s?\nThis procedure is irreversible.',tankObj.Name);
    button = questdlg(promptMessage, 'Are you sure?', 'Cancel', 'Continue', 'Cancel');
    if strcmpi(button, 'Cancel')
        return;
    end
end

A=tankObj.Animals;
for ii=1:numel(A)
    ask = false;
    A(ii).freeSpace(ask);
end
tankObj.save;

end

