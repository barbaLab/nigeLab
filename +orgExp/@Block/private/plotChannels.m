function h = plotChannels(varargin)
%% PLOTCHANNELS Plot all the waveforms of channels in a particular folder.
%
%   h = plotChannels('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs.
%
%   ->'DIR'     :   Default (none) // Specify as path to folder containing
%                                     single-channel files to plot.
%
%   ->'SPK'     :   Default (none) // Specify as path to folder containing
%                                     spike files to super-impose on plot.
%
%   ->'LEN'     :   Default (1 second) // Number of seconds of data to pull
%                                         in and plot.
%
%   ->'OFFSET'  :   Default (100 seconds) // Number of seconds offset from
%                                            the start to the plotted
%                                            waveform.
%
%   ->'STIMTS_ID':  Default ('_StimTS.mat') // ID of Stim/Phase file.
%
%   ->'DEF_DIR' :   Default ('P:\Rat') // Default folder for UI search.
%
%   ->'F_ID'    :   Default ('*.mat') // ID to gather all files within
%                                        specified folder.
%
%   ->'INCREMENT'   :   Default (150) // Spacing between signals on plot.
%
%   ->'CMAP_FILE'   :   Default ('hotcoldmap.mat') // Custom colormap file
%                                                     that contains "cm," a
%                                                     colormap variable
%                                                     that has 64 rows and
%                                                     3 columns with values
%                                                     between 0 and 1.
%
%   ->'AUTOSAVE'    :   Default (true) // If set to false, does not
%                                         automatically save figure and
%                                         jpeg copy in the base block
%                                         folder.
%
%   ->'CLOSE_FIG'   :   Default (false) // If set to true, automatically
%                                          closes figures after making.
%
%   ->'TAG'         :   Default []  // Can specify as a string to replace
%                                      the traditional name; still prefixes
%                                      the file with the base block name.
%   
%   --------
%    OUTPUT
%   --------
%      h        :   Handle to figure with all channels plotted and labeled.
%
% By:   Max Murphy  v1.2.1  08/03/2017  Fixed bug for detecting spike
%                                       channel when plotting only using
%                                       spikes in the "Spikes" but not
%                                       "Clusters" folder.
%                   v1.2    08/02/2017  Added cluster plot number as a text
%                                       label for highlighted spikes. Added
%                                       optional TAG for saving the figure,
%                                       and automatically appends the SPK
%                                       method.
%                   v1.1    07/31/2017  Added adaptive highlighting for
%                                       different spike amplitudes.
%                   v1.0    07/27/2017  Original version (R2017a)

%% DEFAULTS
% Output
AUTOSAVE = true;
SAVE_ID = 'Single_Channel_Preview';

% Directory
DEF_DIR = 'P:\Extracted_Data_To_Move\Rat\Intan';
F_ID = '*Ch*.mat';
STIMTS_ID = '_StimTS.mat';
SORT_ID = '*sort*.mat';
SPK_ID = '*ptrain*.mat';
CLU_ID = '*clus*.mat';
SPK_METHOD_ID = [3 2];              % Number of '_' delimited indexes from end
TAG = [];

% Plotting
INCREMENT = 150;                % Spacing between signals 
CMAP_FILE = 'hotcoldmap.mat';   % Colormap file
SPK_WIN = 0.001;                % Spike half-width (sec)
STIM_WIN = 0.004;               % Stim window + blanking (sec)
CLOSE_FIG = false;              % Close figure after saving?

% Amount to pull in
LEN = 1;                        % Duration to plot (seconds)
OFFSET = 100;                   % Offset from start (seconds)

% Other params for older file formats
VER = 'new';                    % set to 'old' for PRE- CombRestrictClusters stuff
FS = 24414.0625;                % Default fs (if not present)
SCALED = true;                  % New files are scaled to uV
CH_IND = [6 4];                 % Indices "back" from end of filename for CH
SPKCH_IND = [8 6];              % Same, but for spikes


%% PARSE VARARGIN
for iV=1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if ~SCALED
    INCREMENT = INCREMENT * 1e-6;
end

%% GET DIRECTORY INFO
if exist('DIR','var')==0
    DIR = uigetdir(DEF_DIR,'Select single-channel data folder');
end

if exist(DIR,'dir')==0
    error('Invalid directory choice.');
end

F = dir(fullfile(DIR,F_ID));
N = numel(F);

pnum = nan(N,1);
for iF = 1:N
   pnum(iF) = str2double(F(iF).name(regexp(F(iF).name,'[P]\d')+1));
end

[p_unique,~,p_ind] = unique(pnum);


load(CMAP_FILE,'cm');
if exist('cm','var')==0
    error('Bad CMAP_FILE. Check that variable is called "cm".');
end

%% CONSTRUCT FIGURE AND AXES OBJECT
if nargout > 0
    h = axes('NextPlot','add');
else
    figure('Name','Single-Channel Data', ...
       'Units','Normalized', ...
       'Position',[0.05*rand+0.1,0.05*rand+0.1,0.8,0.8]);
    axes('NextPlot','add');
end

%% IF STIMTS IS PRESENT LOAD THAT AS WELL
block = strsplit(F(1).folder,filesep);
basename = block{end-1};
block = strjoin(block(1:end-1),filesep);

% Check if StimTS file exists and has correct parameters
if exist(fullfile(block,[basename STIMTS_ID]),'file')~=0
    load(fullfile(block,[basename STIMTS_ID]),'StimTS');
    if ~isfield(StimTS,'peak_val') || ~isfield(StimTS,'peak_train')
        StimTS = nan;
    else
        if abs(numel(StimTS.peak_val)-numel(StimTS.peak_train))>eps
            StimTS = nan;
        end
    end
    
else
    StimTS = nan;
end

%% CHECK FOR SPIKE DIRECTORY
if exist('SPK','var')==0
    str = questdlg('Superimpose spikes?','Select spike directory?','Yes');
    if strcmp(str,'Yes')
        SPK = uigetdir(block,'Select spike directory');
        spkf = dir(fullfile(SPK,SPK_ID));
        spkf = [spkf; dir(fullfile(SPK,CLU_ID))];
        spkf = [spkf; dir(fullfile(SPK,SORT_ID))];
        if isempty(spkf)
            spkts = nan;
        end
    else
        spkf = nan;
        spkts = nan;
    end
else
    spkf = dir(fullfile(SPK,SPK_ID));
    spkf = [spkf; dir(fullfile(SPK,CLU_ID))];
    if isempty(spkf)
        spkts = nan;
    end
end

%% LOOP THROUGH AND PLOT WAVEFORMS
ch = nan(N,1);
for iF = 1:N
    f = matfile(fullfile(F(iF).folder,F(iF).name));
    ch(iF) = str2double(F(iF).name((end-CH_IND(1)):(end-CH_IND(2))));
    if abs(iF-1)<eps
        try
            fs = f.fs;
        catch
            fprintf(1,'No ''fs'' variable. Using default FS: %d\n',FS);
            fs = FS;
        end
        istart = double(round(fs * OFFSET));
        istop = double(round(fs*(OFFSET + LEN)));
        t = linspace(OFFSET,OFFSET+LEN,istop-istart+1);
        X = nan(N,numel(t));
    end
    X(iF,:) = f.data(1,istart:istop);
end
n_Probe = max(ch);
r = rms(X,2);
hvec = linspace((mean(r)-2*std(r)),(mean(r)+2*std(r)),64);
hvec(1) = -inf; hvec(64) = inf;
[~,~,ic] = histcounts(r,hvec);

for iF = 1:N
    plot(t,X(iF,:)+(ch(iF)-1)*INCREMENT + (p_ind(iF)-1)*(n_Probe+1)*INCREMENT, ...
        'Color',cm(ic(iF),:), ...
        'LineWidth',1.75);
end

set(gca,'YTick',(ch-1)*INCREMENT + (p_ind-1).*(n_Probe+1).*INCREMENT);
set(gca,'YTickLabel',strrep({F.name},'_',' '));
name = strsplit(F(1).folder,filesep);
name = name{end};
name = strsplit(name,'_');
name = strjoin(name([1:2,end]),'_');
xlabel('Time (sec)');

%% ADD STIM TIMES
if isstruct(StimTS)
    ind = StimTS.peak_train >= min(t) & StimTS.peak_train <= max(t);
    StimTimes = StimTS.peak_train(ind);
    StimVals = StimTS.peak_val(ind);
    y = zeros(size(StimVals));
    ind = StimVals > 0;
    y(ind) = 1;
    y = y*INCREMENT*(max(ch)+1);
    y = y-INCREMENT;
    
    plot(StimTimes(ind),y(ind),'LineStyle','none',...
                       'Marker','o',...
                       'MarkerFaceColor',[1.0 0.4 0.4],...
                       'MarkerSize',8,...
                       'MarkerEdgeColor','k');
    plot(StimTimes(~ind),y(~ind),'LineStyle','none',...
                            'Marker','sq',...
                            'MarkerFaceColor',[0.4 0.4 1.0],...
                            'MarkerSize',8,...
                            'MarkerEdgeColor','k');
                        
    Stims = StimTimes(ind); 
    for iStims= 1:numel(Stims)
        for iN = 1:N
            yStims = [(ch(iN)-1)*INCREMENT-INCREMENT/2, ...
                      (ch(iN)-1)*INCREMENT+INCREMENT/2, ...
                      (ch(iN)-1)*INCREMENT+INCREMENT/2, ...
                      (ch(iN)-1)*INCREMENT-INCREMENT/2];
            fill([Stims(iStims),Stims(iStims),...
                  Stims(iStims)+STIM_WIN, Stims(iStims)+STIM_WIN], ...
                  yStims,'r','FaceAlpha',0.7,'EdgeColor','none'); 
        end
    end
end
ylim([0-1.5*INCREMENT,...
   max((ch-1)*INCREMENT + (p_ind-1).*(n_Probe+1).*INCREMENT)+0.5*INCREMENT]);
%% ADD SPIKES
ftype = 'NoSpikes';
if isstruct(spkf)
    
    if strcmpi(VER,'new')
        tempf = strsplit(spkf(1).folder,filesep);
        tempf = tempf{end};
        tempf = strsplit(tempf,'_');
        tempf = strjoin(tempf((end-SPK_METHOD_ID(1)):(end-SPK_METHOD_ID(2))),'-');

        if strcmp(spkf(1).folder((end-7):end),'Clusters')
            ftype = 'Clusters';
            clustfile = true;
            spikefolder = strrep(spkf(1).folder,'Clusters','Spikes');
            tempf = strsplit(spikefolder,'_');
            spikefolder = strjoin(tempf([1:(end-3),(end-1):end]),'_');
            cluf = spkf;
            for iF = 1:numel(cluf)
                cluf(iF).name = strrep(cluf(iF).name,'ptrain','clus');
            end
            spkf = dir(fullfile(spikefolder,SPK_ID));
            if isempty(spkf)
                spikefolder = strjoin(tempf,'_');
                spikefolder = strrep(spikefolder,'_SPC','');
                spikefolder = strrep(spikefolder,'_CAR','');
                spkf = dir(fullfile(spikefolder,SPK_ID));
            end
        elseif strcmp(spkf(1).folder((end-5):end),'Sorted')
            ftype = 'Sorted';
            clustfile = true;
            spikefolder = strrep(spkf(1).folder,'Sorted','Spikes');
            tempf = strsplit(spikefolder,'_');
            spikefolder = strjoin(tempf([1:(end-3),(end-1):end]),'_');
            cluf = spkf;
            for iF = 1:numel(cluf)
                cluf(iF).name = strrep(cluf(iF).name,'ptrain','sort');
            end
            spkf = dir(fullfile(spikefolder,SPK_ID));
            if isempty(spkf)
                spikefolder = strjoin(tempf,'_');
                spikefolder = strrep(spikefolder,'_SPC','');
                spikefolder = strrep(spikefolder,'_CAR','');
                spkf = dir(fullfile(spikefolder,SPK_ID));
            end
        else
            ftype = 'Spikes';
            clustfile = false;
        end
        
        for iS = 1:numel(spkf)
            
            spk = load(fullfile(spkf(iS).folder,spkf(iS).name));
            spki = find(spk.peak_train);
            spka = spk.peak_train(spki);

            if isfield(spk,'pars')
                spkts = spki/spk.pars.FS;
            else
                spkts = spki/FS;
            end

            
            
            spkch = str2double(spkf(iS).name((end-CH_IND(1)):(end-CH_IND(2))));
            if clustfile
                clu = load(fullfile(cluf(iS).folder,cluf(iS).name));
                clunum = clu.class(spkts>=min(t) & spkts<=max(t));
            end
            
            spkts = spkts(spkts>=min(t) & spkts<=max(t));
            

            for iT = 1:numel(spkts)
                hh = spka(iT);
                y = [(spkch-1)*INCREMENT-hh*2/3,(spkch-1)*INCREMENT+hh*1/3, ...
                     (spkch-1)*INCREMENT+hh*1/3,(spkch-1)*INCREMENT-hh*2/3];
                fill([spkts(iT)-SPK_WIN,spkts(iT)-SPK_WIN,...
                      spkts(iT)+SPK_WIN,spkts(iT)+SPK_WIN], ...
                      y + (p_ind(iS)-1).*(n_Probe+1).*INCREMENT,...
                      'y','FaceAlpha',0.5,'EdgeColor','none'); 

                if clustfile
                    
                    text(double(spkts(iT)-SPK_WIN), ...
                        double((spkch-1)*INCREMENT+hh*1/3) + ...
                        (p_ind(iS)-1).*(n_Probe+1).*INCREMENT, ...
                        num2str(clunum(iT)), ...
                        'FontWeight','bold', ...
                        'FontName','Arial');
%                 else
%                     text(double(spkts(iT)-SPK_WIN), ...
%                         double((spkch-1)*INCREMENT+hh*1/3) + ...
%                         (p_ind(iS)-1).*(n_Probe+1).*INCREMENT, ...
%                         'all', ...
%                         'FontWeight','bold', ...
%                         'FontName','Arial');
                end
            end
        end
        temp = strsplit(spkf(1).folder,filesep);
        temp = temp{end};
        temp = strsplit(temp,'_');
        temp = strjoin(temp((end-SPK_METHOD_ID(1)):(end-SPK_METHOD_ID(2))),'-');

        temp = strsplit(temp,'-');
        temp = temp{2};
        name = [name '-' temp];

        xlim([min(t) max(t)]);
    else
        temp = strsplit(spkf(1).folder,filesep);
        temp = temp{end};
        temp = strsplit(temp,'_');
        temp = strjoin(temp((end-SPK_METHOD_ID(1)):(end-SPK_METHOD_ID(2))),'-');

        clustfile = true;
        for iS = 1:numel(spkf)
            spk = load(fullfile(spkf(iS).folder,spkf(iS).name));
            spki = find(spk.peak_train);
            spka = spk.peak_train(spki);

            if isfield(spk,'pars')
                spkts = spki/spk.pars.FS;
            else
                spkts = spki/FS;
            end

            if (strcmp(spkf(1).folder((end-7):end),'Clusters') || ...
                strcmp(spkf(1).folder((end-5):end),'Sorted'))
                clustfile = true;
                spkch = str2double(spkf(iS).name((end-SPKCH_IND(1)):(end-SPKCH_IND(2))));
            else
                clustfile = false;
                spkch = str2double(spkf(iS).name((end-CH_IND(1)):(end-CH_IND(2))));
            end
            spkts = spkts(spkts>=min(t) & spkts<=max(t));


            for iT = 1:numel(spkts)
                hh = spka(iT);
                y = [(spkch-1)*INCREMENT-hh*2/3,(spkch-1)*INCREMENT+hh*1/3, ...
                     (spkch-1)*INCREMENT+hh*1/3,(spkch-1)*INCREMENT-hh*2/3];
                fill([spkts(iT)-SPK_WIN,spkts(iT)-SPK_WIN,...
                      spkts(iT)+SPK_WIN,spkts(iT)+SPK_WIN], ...
                      y + (p_ind(iS)-1).*(n_Probe+1).*INCREMENT,...
                      'y','FaceAlpha',0.5,'EdgeColor','none'); 

                if clustfile
                    text(double(spkts(iT)-SPK_WIN), ...
                        double((spkch-1)*INCREMENT+hh*1/3) + ...
                        (p_ind(iS)-1).*(n_Probe+1).*INCREMENT, ...
                        spkf(iS).name((end-5):(end-4)), ...
                        'FontWeight','bold', ...
                        'FontName','Arial');
%                 else
%                     text(double(spkts(iT)-SPK_WIN), ...
%                         double((spkch-1)*INCREMENT+hh*1/3) + ...
%                         (p_ind(iS)-1).*(n_Probe+1).*INCREMENT, ...
%                         'all', ...
%                         'FontWeight','bold', ...
%                         'FontName','Arial');
                end
            end
        end
        if clustfile
            name = [name '-' temp];
        else
            temp = strsplit(temp,'-');
            temp = temp{2};
            name = [name '-' temp];
        end
        xlim([min(t) max(t)]);
    end
end

%% SAVE FIGURE, IF APPLICABLE
title([strrep(name,'_',' ') ' ' ftype ' Preview']);
if AUTOSAVE
    if isempty(TAG)
        savefig(gcf,fullfile(block,[name '_' ftype '_' SAVE_ID '.fig']));
        saveas(gcf,fullfile(block,[name '_' ftype '_' SAVE_ID '.jpeg']));
    else
        savefig(gcf,fullfile(block,[TAG '.fig']));
        saveas(gcf,fullfile(block,[TAG 'jpeg']));
    end
    if CLOSE_FIG
        delete(gcf);
    end
end

end