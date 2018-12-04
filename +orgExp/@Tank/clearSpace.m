function flag = clearSpace(tankObj,ask)
%% CLEARSPACE   Delete the raw data folder to free some storage space
%
%  tank = orgExp.Tank;
%  flag = clearSpace(tank);
%  flag = clearSpace(tank,ask);
%
%  --------
%   INPUTS
%  --------
%    tankObj   :     orgExp TANK class.
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

%% ASK TO CONFIRM FILE DELETION
A=tankObj.Animals;
flag = false(1,numel(A));
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

%% PROCEED WITH REMOVING FILES
for ii=1:numel(A)
    ask = false;
    flag(ii) = A(ii).freeSpace(ask);
end
tankObj.save;
fprintf(1,'Finished clearing space for: %s \n.',tankObj.Name);

end

