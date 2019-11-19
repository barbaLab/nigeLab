function [timeString,t] = sec2time(nSeconds)
%% SEC2TIME   Convert a time string or char into a double of seconds
%
%  [timeString,t] = TIME2SEC(nSeconds);
%
%  --------
%   INPUTS
%  --------
%  nSeconds       :     (Double) Number of seconds for a given duration
%                                time string or character.
%
%  --------
%   OUTPUT
%  --------
%  timeString     :     String or char in format 'hh:mm:ss'
%
%     t           :     (Optional) Output struct with fields containing
%                             information in numeric format.
%
% By: Max Murphy  v1.0  06/29/2018  Original version (R2017b)

%% DEFAULTS
SEC_PER_HR = 3600;
SEC_PER_MIN = 60;

TS_FORMAT = 'uuuu-MM-dd_HHmmss';

t = struct;
x = nSeconds;
    t.hrs             = floor(x/SEC_PER_HR);
x = nSeconds - SEC_PER_HR*t.hrs;
    t.mins            = floor(x/SEC_PER_MIN);
y = x - SEC_PER_MIN*t.mins;
    t.secs            = y;
    
%% Get time of "occurrence"
timestamp = datetime;
timestamp.Format = TS_FORMAT;
t.timestamp = timestamp;

timeString = sprintf('%02g:%02g:%02g',t.hrs,t.mins,round(t.secs));

end