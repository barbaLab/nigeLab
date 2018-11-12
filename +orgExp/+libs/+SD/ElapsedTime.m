function t = ElapsedTime(InputTic)
%% ELAPSEDTIME  Give time elapsed in hours, minutes, and seconds.
%
%   t = ELAPSEDTIME(InputTic)
%
%   --------
%    INPUTS
%   --------
%   InputTic        :       Input tic time value.
%
%   --------
%    OUTPUT
%   --------
%      t            :       Output struct containing the fields
%                           -hrs    : Number of hours elapsed
%                           -mins   : Number of minutes elapsed
%                           -secs   : Number of seconds elapsed
%
%   Also reads out the time in hours, minutes, and seconds that has elapsed
%   since InputTic (displayed in command window).
%
% By: Max Murphy    v1.1    01/30/2017  Fixed singular detection using
%                                       round and tolerance for matching,
%                                       rather than an exact match with
%                                       floating precision values.
%                   v1.0    01/29/2017  Original Version

%% DEFAULTS
HR_C = 3600;
MN_C = 60;
SC_C = 60;

%% Get elapsed time
x = toc(InputTic);

t = struct;
    t.hrs             = floor(x/HR_C);
    t.mins            = floor((x-t.hrs*HR_C)/MN_C);
    t.secs            = mod(x,SC_C);

%% Read elapsed time in hours, minutes, seconds to command window
fprintf(1, '-----------------------------\n');
fprintf(1, '%4.0f hour%s,\n', t.hrs, plural(t.hrs));
fprintf(1, '%4.0f minute%s,\n', t.mins, plural(t.mins));
fprintf(1, '%4.1f second%s.\n', t.secs, plural(t.secs));
fprintf(1, '-----------------------------\n');

    function s = plural(n)
    %% PLURAL Utility function to optionally pluralize words. 
    % 
    %   s = plural(n)
    % DEFAULTS
    TOL = eps;
    % DETERMINE IF SINGULAR RETURN '' ELSE RETURN 'S'
    if (abs(round(n)-1) < TOL)
        s = '';
    else
        s = 's';
    end
    end
                               
end