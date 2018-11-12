function adHocCAR(varargin)
%% ADHOCCAR Perform re-referencing on all filtered single-channel data
%
%   ADHOCCAR('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs.
%                   - ANY parameter in DEFAULTS
%                   - DIR: (none default; if specified, skips user
%                           selection interface for picking filtered data
%                           folder).
%                   - USE_CHANS: (none default; if specified, only takes
%                                 those channels in the re-referencing)
%   --------
%    OUTPUT
%   --------
%   The re-referenced, filtered data in a _FilteredCAR folder in the same
%   directory as the rest of the files associated with that recording
%   block.
%
% By: Max Murphy    v1.2    07/27/2017  Added parfor saving to take
%                                       advantage of Isilon RAM.
%                   v1.1    06/02/2017  Added minor changes to annotations
%                                       and usability.
%                   v1.0    03/01/2017

%% DEFAULTS

% Unlikely to change
DEF_DIR = 'P:\Rat\';            % Default search dir
FILT_FOLDER = '_Filtered';      % Folder name for unit-filtered files
CAR_FOLDER  = '_FilteredCAR';   % Folder name for CAR files
F_ID    = '_Filt_';             % ID Tag for unit-filtered files
CAR_ID  = '_FiltCAR_';          % ID Tag for CAR files
FS      = 20000;                % Default sampling frequency (if not found)
USE_CLUSTER = false;            % If true, need to change DIR start.
UNC_PATH = '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\';
           
%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET DIRECTORY INFO

if ~USE_CLUSTER
    if exist('DIR','var')==0
        DIR = uigetdir(DEF_DIR, ...
            'Select recording block to re-reference');
        if DIR == 0
            error('Must select a directory.');
        end

    end

    if exist(DIR,'dir')==0
        error('Invalid directory name. Check path.');
    end
else
    DIR = [UNC_PATH DIR((find(DIR == filesep,1,'first')+1):end)]; %#ok<NODEF>
    myJob = getCurrentJob;
end

temp = dir([DIR filesep '*' FILT_FOLDER]);
if isempty(temp)
    temp = strsplit(DIR, filesep);
    Block = strjoin(temp(1:end-1),filesep);
    Car_Folder = strrep(temp{end},FILT_FOLDER,CAR_FOLDER);
else
    Block = DIR;
    DIR = [Block filesep temp(1).name];
    Car_Folder = strrep(temp(1).name,FILT_FOLDER,CAR_FOLDER);
end
clear temp

%% GET FILTERED FILE NAMES & CHANNELS
F = dir(fullfile(DIR,['*' F_ID '*.mat']));
nCh = numel(F);

Name = cell(nCh,1);
Ch   = nan(1,nCh);
for iF = 1:nCh
    Name{iF,1} = F(iF).name(1:end-4);
    Ch(1,iF) = str2double(Name{iF}(end-2:end));
    if isnan(Ch(1,iF))
        Ch(1,iF) = str2double(Name{iF}(end-1:end));
    end
end
name = strsplit(Name{1},'_');
idate = regexp(Name{1},'\d\d\d\d[_]\d\d[_]\d\d','ONCE');
if isempty(idate)
   if numel(name) > 5
       name = strjoin(name(1:2),'_');
   else
       name = name{1};
   end
else
   name = [name{1} '_' Name{1}(idate:(idate+9))];
end

%% GET NUMBER OF PROBES AND PROBE ASSIGNMENTS
pval = nan(nCh,1);
for iN = 1:nCh
    pval(iN) = str2double(Name{iN}(regexp(Name{iN},'[P]\d')+1));
end
pnum = numel(unique(pval));

%% GET CHANNELS TO USE
if exist('USE_CHANS','var')~=0
    usech = false(size(Ch));
    for iCh = 1:numel(Ch)
        if ismember(Ch(iCh),USE_CHANS)
            usech(iCh) = true;
        end
    end
    Ch = Ch(usech);
end

if USE_CLUSTER
    set(myJob,'Tag',['Loading filtered channels for ' name '...']); %#ok<*UNRCH>
end

%% LOAD FILTERED CHANNELS
clc;
Data = cell(pnum,1);
pCh = cell(pnum,1);
for iP = 1:pnum
   iCount = 0;
   pCh{iP} = Ch(abs(pval-iP)<eps);
   pCh{iP} = reshape(pCh{iP},1,numel(pCh{iP}));
   for iCh = pCh{iP}
      iCount = iCount + 1;
      fprintf(1,'\n\t Loading %s...', Name{abs(Ch-iCh)<eps});
      x = load(fullfile(DIR,...
         [Name{abs(Ch-iCh)<eps & abs(pval.'-iP)<eps} '.mat']));
      if iCount == 1
         Data{iP} = nan(numel(pCh{iP}),numel(x.data));
         if isfield(x,'fs')
            FS = x.fs;
         end
      end
      Data{iP}(iCount,:) = x.data;
      fprintf(1,'complete.\n');
   end
end
clear x

if USE_CLUSTER
    set(myJob,'Tag',['Re-referencing and saving data for ' name '...']);
end

%% DO RE-REFERENCING

for iP = 1:pnum
    refData = mean(Data{iP},1);
    iCount = 1;
    for iCh = pCh{iP}
        Data{iP}(iCount,:) = Data{iP}(iCount,:) - refData;
        iCount = iCount + 1;
    end
end

if exist(fullfile(Block,Car_Folder),'dir')==0
    mkdir(fullfile(Block,Car_Folder));
end

fname = cell(numel(Ch),pnum);
for iP = 1:pnum
   iCount = 0;
   for iCh = pCh{iP}
       iCount = iCount + 1;
       fname{iCount,iP} = strrep(F(abs(Ch-iCh)<eps & ...
                                   abs(pval.'-iP)<eps).name,F_ID,CAR_ID);
   end
end

clc;
if USE_CLUSTER
   for iP = 1:pnum
       parfor iCh = 1:numel(pCh{iP})
           fprintf(1,'\n\t Saving %s...',fname{iCh,iP});
           % Put data into proper format
           fs = FS;
           data = Data{iP}(iCh,:); %#ok<NASGU>
           parsavedata(fullfile(Block,Car_Folder,fname{iCh,iP}), ...
                           'data',data,'fs',fs);
           fprintf(1,'complete.\n');
       end
   end
else
    fs = FS;
    for iP = 1:pnum
       for iCh = 1:numel(pCh{iP})
           fprintf(1,'\n\t Saving %s...',fname{iCh,iP});
           % Put data into proper format
           data = Data(iCh,:); %#ok<NASGU>
           save(fullfile(Block,Car_Folder,fname{iCh,iP}),'data','fs','-v7.3');
           fprintf(1,'complete.\n');
       end
    end
end

if USE_CLUSTER
    set(myJob,'Tag',['Complete: ad hoc CAR for ' name]);
end

end