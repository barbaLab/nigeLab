function [pct,str] = jobTag2Pct(jobObject,delim)
%% JOBTAG2PCT  Convert tagged CJS communicating job tag to completion %
%
%  pct = JOBTAG2PCT(jobObject,delim);
%
%  --------
%   INPUTS
%  --------
%  jobObject   :     Matlab parallel.job.CJSCommunicatingJob object. Should
%                       have a Tag property that is a char array set using
%                       the configuration properties in
%                       nigeLab.defaults.Notifications().
%
%  delim       :     Delimiter from nigeLab.defaults.Notifications();
%
%  --------
%   OUTPUT
%  --------
%    pct       :     Scalar integer (double format) between 0 and 100.

%%
tagString = jobObject.Tag;

% Split the tag up; if it has % on the end, remove that:
tmp = strsplit(tagString,{delim,'%'});
% disp(tmp{2}); % for debug

% The second part should be the completion percentage
pct = str2double(tmp{2});
str = tmp{1};
end