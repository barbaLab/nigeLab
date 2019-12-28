function [pct,tag,name] = jobTag2Pct(jobObject,delim)
%% JOBTAG2PCT  Convert tagged CJS communicating job tag to completion %
%
%  pct = JOBTAG2PCT(jobObject); % Default value of delim is '||'
%  pct = JOBTAG2PCT(jobObject,delim); % Override default value of delim
%  pct = JOBTAG2PCT(jobObject.Tag,delim);
%  [pct,tag] = JOBTAG2PCT(jobObject,delim);
%  [pct,tag,name] = JOBTAG2PCT(jobObject,delim);
%
%  --------
%   INPUTS
%  --------
%  jobObject   :     Matlab parallel.job.CJSCommunicatingJob object. Should
%                       have a Tag property that is a char array set using
%                       the configuration properties in
%                       nigeLab.defaults.Notifications().
%
%                    --> Can also be passed as 'tagString' char array
%                       (jobObject.Tag property value) directly.
%
%  delim       :     Delimiter from nigeLab.defaults.Notifications();
%
%  --------
%   OUTPUT
%  --------
%    pct       :     Scalar integer (double format) between 0 and 100.
%
%    tag       :     Char array (name of operation or processing stage)
%
%    name      :     Name of job (e.g. <AnimalID>.<RecID>)

%%
if nargin < 2
   delim = '||';
end
if isa(jobObject,'parallel.job.MJSCommunicatingJob')
   tagString = jobObject.Tag;
elseif ischar(jobObject)
   tagString = jobObject;
end

% Split the tag up; if it has % on the end, remove that:
tmp = strsplit(tagString,{' ',delim,'%'});
% disp(tmp{2}); % for debug

% The second part is a descriptor, third part is % complete
pct = str2double(tmp{3});
tag = tmp{2};   % Name of operation or processing stage
name = tmp{1};  % Name of job (e.g. AnimalID.RecID)
end