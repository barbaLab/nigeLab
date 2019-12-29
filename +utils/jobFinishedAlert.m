function jobFinishedAlert(src,~)
%% JOBFINISHEDALERT  Specify completion of a queued MJS job.
%
%   Used as callback for MJS 'FinishedFcn' property.
%
% By: Max Murphy    v1.0    06/09/2017  Original version (R2017a)
%     Max Murphy    v1.1    07/09/2019  Updated for NigeLab

%% ALERT THAT JOB IS DONE
fprintf(1,'\n\t* * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n');
fprintf(1,'\n\t\tMJS Job %d: %s %s.\n\n', src.ID, src.Name, src.State);
if isempty(src.Tasks(1).Error)
   nigeLab.sounds.play('alert',4);
   fprintf(1,'\t\t->\t Success!\n\n');
else
   fprintf(1,'\t\t\t\t :(\n\n');
   nigeLab.sounds.play('alert',0.5);
   fprintf(1,'\t %s\n\n',src.Tasks(1).Error.message);
end
fprintf(1,'\t* * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n');


end