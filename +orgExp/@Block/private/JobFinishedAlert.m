function JobFinishedAlert(src,~)
%% JOBFINISHEDALERT  Specify completion of a queued MJS job.
%
%   Used as callback for MJS 'FinishedFcn' property.
%
% By: Max Murphy    v1.0    06/09/2017  Original version (R2017a)

%% ALERT THAT JOB IS DONE
beep;
beep;
fprintf(1,'\n\t* * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n');
beep;
fprintf(1,'\n\t\tMJS Job %d: %s %s.\n\n', src.ID, src.Name, src.State);
if isempty(src.Tasks(1).Error)
    fprintf(1,'\t\t->\t Success!\n\n');
else
    fprintf(1,'\t\t\t\t :(\n\n');
    fprintf(1,'\t %s\n\n',src.Tasks(1).Error.message);
end
beep;
fprintf(1,'\t* * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n');
beep;
beep;

end