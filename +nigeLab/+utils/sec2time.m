function [timeString,t,timeString_long] = sec2time(nSeconds,SHORT_STRING_FORMAT,LONG_STRING_FORMAT,TS_FORMAT)
%SEC2TIME   Convert a time string or char into a double of seconds
%
%  [timeString,t,timeString_long] = SEC2TIME(nSeconds);
%
%  [...] = SEC2TIME(__,SHORT_STRING_FORMAT);
%  --> Default SHORT_STRING_FORMAT is '%02g:%02g:%02g' (affects 1st output)
%
%  [...] = SEC2TIME(__,LONG_STRING_FORMAT);
%  --> Default LONG_STRING_FORMAT is '%02g h, %02g m, %02g s' (affects 3rd output)
%
%  [...] = SEC2TIME(__,TS_FORMAT);
%  --> Default TS_FORMAT is 'uuuu-MM-dd_HHmmss' (affects parsing)
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
%  timeString_long:     (Optional) String in "long format" :
%                       '%02g h, %02g m, %02g s'

% DEFAULTS
SEC_PER_HR = 3600;
SEC_PER_MIN = 60;

if nargin < 2
   SHORT_STRING_FORMAT = '%02g:%02g:%02g';
end

if nargin < 3
   LONG_STRING_FORMAT = '%02g h, %02g m, %02g s';
end

if nargin < 4
   TS_FORMAT = 'uuuu-MM-dd_HHmmss';
end

t = struct;
x = nSeconds;
    t.hrs             = floor(x/SEC_PER_HR);
x = nSeconds - SEC_PER_HR*t.hrs;
    t.mins            = floor(x/SEC_PER_MIN);
y = x - SEC_PER_MIN*t.mins;
    t.secs            = y;
    
% Get time of "occurrence"
timestamp = datetime;
timestamp.Format = TS_FORMAT;
t.timestamp = timestamp;

timeString = sprintf(SHORT_STRING_FORMAT,t.hrs,t.mins,round(t.secs));
if nargout > 2
   timeString_long = sprintf(LONG_STRING_FORMAT,...
      t.hrs,t.mins,round(t.secs));
end

end