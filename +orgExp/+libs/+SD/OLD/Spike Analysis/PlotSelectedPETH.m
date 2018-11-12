function PlotSelectedPETH(varargin)
%% PETH Construct peri-event time histogram and get smoothed rate for all
%
%   PETH('NAME', value, ...)
%
%   --------
%    INPUTS
%   --------
%   varargin        :       'NAME', value optional input argument pairs.
%                           --------------------------------------------
%                           'NAME' : String specifying directory with split
%                                    clusters. If left empty (default), a
%                                    dialog box will prompt user for the
%                                    correct directory.
%           
%                               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               %                                   %
%                               %   NOTE:                           %
%                               % Input file 'RC_PSTH_Data.mat'     %
%                               % was created by running PETH.m     %
%                               % in a loop and putting outputs     %
%                               % into a cell store.                %
%                               %                                   %
%                               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   --------
%    OUTPUT
%   --------
%   Creates figure of the PETH for each cluster that demonstrates
%   significant task-related modulation. 
%
% See also: SORTCLUSTERS, MERGEWAVES, ALIGN, PLOTSPIKERASTER
%   By: Max Murphy  v1.0 02/08/2017     Original Version (R2016b)

%% DEFAULTS
clc;
% Most likely constants to change
    % Continuing
    NSTART  = 1;
    
    % PETH parameters
    BINSIZE = 0.025;                      % Bin size (sec): per Hyland '98
    E_PRE   = 4;                          % Pre-event time (sec)
    E_POST  = 2;                          % Post-event time (sec)
    
    % Figure
    YMAX    = 80;                         % Max rate to plot
    DEV_SCL = 5;                          % Number of SD from mean   
    COL = {[0 0 1]; ...
           [1 0 0]; ...
           [0 0 0.8]; ...
           [0.8 0 0]};
    
    % Filtering
    WN = 0.2;               % Lowpass normalized cut-off frequency
    RP = 0.001;             % Passband ripple
    RS = 60;                % Stopband attenuation
    F_ORD = 8;              % Filter order
    EVAL_ALL = false;       % Evaluate all profiles (true) or just those 
                            % pre-filtered using selection criteria in PETH

% Directory information
    % Input
    IDIR  = 'Data/PSTH';                  % Input data directory
    I_ID  = 'PSTH_Data';                  % Input ID

    % Output
    F_ID  = 'PETH';                       % Figure ID
    SEL_ID= 'SelectClusts';               % Selected Directory ID
    REJ_ID= 'RejectClusts';               % Rejected Directory ID
    
%% PARSE VARARGIN
for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% SELECT FILE
% If pre-specified in optional arguments, skip this step.
if exist('NAME', 'var') == 0
    [NAME,IDIR,~] = uigetfile(['*' I_ID '*.mat'], ...
                           'Select Combined PSTH Mat File', ...
                           IDIR);
    if NAME == 0 % Must select a directory
        error('Must select a valid file.');
    end
    load([IDIR  NAME]);
else    % If a pre-specified path exists, must be a valid path.
    
    if NAME == 0  % Must select a directory
        error('Must select a valid rat name.');
    end
    load([IDIR filesep NAME '.mat']);
end
  
%% FIGURES

TVEC    = -E_PRE:BINSIZE:E_POST;       
[b,a]   = ellip(F_ORD,RP,RS,WN,'low');


for iR = NSTART:nRecordings
    Animal = Processing.Recording{iR}(1:5);
    Name = Processing.Recording{iR};
    load(['Data' filesep 'Aligned' filesep ...
          Animal filesep Name ...
          '_clusterdata.mat']);
    load(['Data' filesep 'Aligned' filesep ...
          Animal filesep Name ...
          '_graspdata.mat']);
      
    nTrials = [numel(SuccessTimes), ...
               numel(FailureTimes), ...
               numel(ReachSuccessTimes), ...
               numel(ReachFailureTimes)];
    nClusters = size(GraspData,1);
    cnames = RateData{iR}.Properties.VariableNames(1:4);
    
    for iCl = 1:nClusters
        

        if EVAL_ALL
            flag = true;
        else
            vec = zeros(1,numel(cnames));
            for iCo = 1:numel(cnames)
                vec(iCo) = ismember(iCl,info{iR}.UseRows{iCo});
            end

            if ~any(vec)
                flag = false;
            else
                flag = true;
                vec = find(vec);
                vec = reshape(vec,1,numel(vec));

            end
        end

        if flag
            figure('Name',[strrep(Name,'_',' ') ' Cluster ' num2str(iCl)] , ...
                       'Units', 'Normalized', ...
                       'Position', [0.1 0.1 0.8 0.8], ...
                       'Color', 'w');

            nrow = ceil(sqrt(numel(cnames)));
            ncol = nrow;

            for iCo = 1:numel(cnames) % Plot even ones that were rejected

                subplot(nrow,ncol,iCo); 
                rate = RateData{iR}.(cnames{iCo})(iCl,:);
                bar(TVEC(1:end-1)+BINSIZE/2, ...
                    rate/nTrials(iCo)/BINSIZE, ...
                    1,'FaceColor',COL{iCo},'EdgeColor',COL{iCo});
                
                hold on;
                line([0 0],[0 YMAX], ...
                     'Color', COL{iCo}, ...
                     'LineWidth', 2, ...
                     'LineStyle', ':'); 

                line([min(TVEC) max(TVEC)], ...
                     [RateData{iR}.SpikeRate(iCl) RateData{iR}.SpikeRate(iCl)], ...
                     'Color', 'k', ...
                     'LineWidth', 4, ...
                     'LineStyle', '--');

                dev = RateData{iR}.SpikeDev(iCl);
                mu = RateData{iR}.SpikeRate(iCl);
                smoothed = filtfilt(b,a,rate/nTrials(iCo)/BINSIZE);

                plot(TVEC(1:end-1)+BINSIZE/2, smoothed, ...
                    'LineWidth', 3, 'Color', [0.9 0.9 0.9]);
                line([min(TVEC) max(TVEC)], ...
                   [mu-dev*DEV_SCL mu-dev*DEV_SCL], ...
                   'Color', 'm', ...
                   'LineWidth', 2, ...
                   'LineStyle', '-.');

                line([min(TVEC) max(TVEC)], ...
                   [mu+dev*DEV_SCL mu+dev*DEV_SCL], ...
                   'Color', 'm', ...
                   'LineWidth', 2, ...
                   'LineStyle', '-.');

                hold off;
                set(gca,'Xlim',[-E_PRE E_POST]); 
                set(gca,'Ylim',[0 YMAX]);
                title(info{iR}.Conditions{iCo});
                xlabel('Time (sec)');
                ylabel('Spikes/sec');
            end

            suptitle([strrep(Name,'_',' ') ': Cluster ' num2str(iCl) ' ' ...
                        ClusterData.Hemisphere(iCl) ' ' ...
                        ClusterData.ML(iCl) ' ' ...
                        ClusterData.Area(iCl,:) ': ' ...
                        ClusterData.Channel(iCl,:) '-' ClusterData.ICMS{iCl}]);
                
            if exist([IDIR filesep Name(1:5) filesep ...
                      Name filesep REJ_ID],'dir')==0
                  mkdir([IDIR filesep Name(1:5) filesep ...
                      Name filesep REJ_ID]);
            end
            
            if exist([IDIR filesep Name(1:5) filesep ...
                      Name filesep SEL_ID],'dir')==0
                  mkdir([IDIR filesep Name(1:5) filesep ...
                      Name filesep SEL_ID]);
            end
            
            msg = questdlg('Select or Reject this cluster.', ...
                           'Manual cluster selection', ...
                           'Select','Reject','Abort','Select');
            
            if strcmp(msg,'Select')
                if exist([IDIR filesep Name(1:5) filesep Name filesep ...
                    REJ_ID filesep Name '_C' num2str(iCl) '_' F_ID '.fig'], 'file')~=0
                    delete([IDIR filesep Name(1:5) filesep Name filesep ...
                        REJ_ID filesep Name '_C' num2str(iCl) '_' F_ID '.fig']);
                    delete([IDIR filesep Name(1:5) filesep Name filesep ...
                        REJ_ID filesep Name '_C' num2str(iCl) '_' F_ID '.jpeg']);
                end
                
                savefig(gcf,[IDIR filesep Name(1:5) filesep Name filesep ...
                    SEL_ID filesep Name '_C' num2str(iCl) '_' F_ID '.fig']);
                saveas(gcf,[IDIR filesep Name(1:5) filesep Name filesep ...
                    SEL_ID filesep Name '_C' num2str(iCl) '_' F_ID '.jpeg']);
                delete(gcf);
            elseif strcmp(msg,'Reject')
                if exist([IDIR filesep Name(1:5) filesep Name filesep ...
                    SEL_ID filesep Name '_C' num2str(iCl) '_' F_ID '.fig'], 'file')~=0
                    delete([IDIR filesep Name(1:5) filesep Name filesep ...
                        SEL_ID filesep Name '_C' num2str(iCl) '_' F_ID '.fig']);
                    delete([IDIR filesep Name(1:5) filesep Name filesep ...
                        SEL_ID filesep Name '_C' num2str(iCl) '_' F_ID '.jpeg']);
                end
                savefig(gcf,[IDIR filesep Name(1:5) filesep Name filesep ...
                    REJ_ID filesep Name '_C' num2str(iCl) '_' F_ID '.fig']);
                saveas(gcf,[IDIR filesep Name(1:5) filesep Name filesep ...
                    REJ_ID filesep Name '_C' num2str(iCl) '_' F_ID '.jpeg']);
                delete(gcf);
            else
                clc;
                disp('Process aborted. Figure not saved.');
                delete(gcf);
                return;
            end
        end
    end
end
end