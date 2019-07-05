function [avg,t,err] = CPL_getRawAverage(data,fs,ts,varargin)
%% CPL_GETRAWAVERAGE Average using aligned times
%
%  avg = CPL_GETRAWAVERAGE(data,idx);
%  [avg,t,err] = CPL_GETRAWAVERAGE(data,idx,'NAME',value,...);
%  
%  --------
%   INPUTS
%  --------
%    data      :     Data stream to average coherently using equal-length
%                    snippets centered at different time points.
%
%     fs       :     Sample rate of data.
%
%     ts       :     Times around which to average data.
%
%  varargin    :     (Optional) 'NAME' value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%    avg       :     "Triggered" average snippet of data.
%
%     t        :     Timestamps corresponding to snippet epoch.
%
%    err       :     Standard error of the mean (SEM).
%
% By: Max Murphy  v1.0  05/07/2018  Original version (R2017b)

%% DEFAULTS
E_PRE = 0.2;   % seconds before
E_POST = 0.2;  % seconds after
DOWNSAMPLE = 100; 

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% DO CONVERSIONS TO SAMPLE INDEXES
e_pre = round(E_PRE * fs);
e_post = round(E_POST * fs);

vec = -e_pre : DOWNSAMPLE : e_post;

t = vec ./ fs;

ti = round(ts * fs);

%% GET INDEXING BLOCK
V = repmat(vec,numel(ti),1) + ti;
vi = V <= 0 | V > numel(data);

idx = ~any(vi,2);
V = V(idx,:);

%% GET MATRIX OF SAMPLES
D = data(V);
avg = mean(D,1);
err = std(D,[],1)/sqrt(size(D,1));

end