function SingleChannelFormat(varargin)
%% SINGLECHANNELFORMAT  Format single channel files in Filt or Raw folder
%
%   (Gives them correct naming convention to work with QSD and
%   SPIKEDETECTCLUSTER)
%
% By: Max Murphy    v1.0    02/16/2017  Original version (R2016a)

%% DEFAULTS
FILTDIR = 'Filtered';
RAWDIR = 'RawData';

FILT_ID = 'Filt';
RAW_ID = 'Raw';
PROBE_ID = 'P';

DEFDIR = pwd;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET DIRECTORY TO CHANGE FILE NAMES
if exist('DIR','var')==0
    DEFDIR = strrep(DEFDIR,'\',filesep);
    DIR = uigetdir(DEFDIR,'Select directory to convert'); 

    if DIR == 0 
        error('Must select directory.');
    end
end

%% GET RAW OR FILTERED
temp = strsplit(DIR,'_');
if strcmp(temp{end},FILTDIR)
    fid = FILT_ID;
    fdir = FILTDIR;
elseif strcmp(temp{end},RAWDIR)
    fid = RAW_ID;
    fdir = RAWDIR;
else
    error('Must specify valid folder name (or rename folder).');
end

%% CHECK FOR RAW/FILT TAG
F = dir([DIR filesep '*.mat']);
temp = strsplit(F(1).name,'_');
repdir = strsplit(DIR,filesep);
repdir = repdir{end};
repdir = strrep(repdir, fdir, '');

% if ~strcmp(temp{end-3},fid)
    for iF = 1:numel(F)
        temp = strsplit(F(iF).name,'_');
        F(iF).nameUpdate = strjoin([repdir ...
            {fid} temp(end-1:end)],'_');
    end
% end

%% CHECK FOR PROBE TAG
temp = strsplit(F(1).nameUpdate,'_');

% if ~((abs(numel(temp{end-2})-2)<eps) && ...
%       strcmp(temp{end-2}(1),PROBE_ID))
    for iF = 1:numel(F)
        temp = strsplit(F(iF).nameUpdate,'_');
        F(iF).nameUpdate = strjoin([temp(1:end-2) ...
            {[PROBE_ID '1']} temp(end-1:end)],'_');
    end
% end

%% UPDATE NAMES
for iF = 1:numel(F)
    movefile([DIR filesep F(iF).name],[DIR filesep F(iF).nameUpdate]);
end

end