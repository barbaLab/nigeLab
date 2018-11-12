function ViewSelectedPETH(varargin)
%% ViewSelectedPETH  View screened selected PETH in tabbed format
%
%   ViewSelectedPETH('NAME', value, ...)
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
    % PETH parameters
    BINSIZE = 0.025;                      % Bin size (sec): per Hyland '98
    E_PRE   = 4;                          % Pre-event time (sec)
    E_POST  = 2;                          % Post-event time (sec)
    
    % Figure
    YMAX    = 80;                         % Max rate to plot
    DEV_SCL = 5;                          % Number of SD from mean   
    COL = {[0.2 0.4 1.0]; ...
           [1.0 0.2 0.2]; ...
           [0.0 0.0 0.7]; ...
           [0.7 0.0 0.0]};
    
    % Filtering
    WN = 0.2;               % Lowpass normalized cut-off frequency
    RP = 0.001;             % Passband ripple
    RS = 60;                % Stopband attenuation
    F_ORD = 8;              % Filter order

% Directory information
    % Input
    IDIR  = 'Data/PSTH';                  % Input data directory
    I_ID  = 'PSTH_Data';                  % Input ID

    % Output
    F_ID  = 'PETH';                       % Figure ID
    SEL_ID= 'SelectClusts';               % Selected Directory ID
    
%% PARSE VARARGIN
for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

global Rec
global handles
global info nRecordings
global RateData Processing

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

temp = cell2mat(Processing.Recording);
temp = mat2cell(temp(:,1:5),ones(1,size(temp,1)),5);
[Animal,~,A_ind] = unique(temp);


Rec       = cell(numel(Animal),1);
iCount    = zeros(numel(Animal),1);
for iA = 1:nRecordings
    iAA = A_ind(iA);
    iCount(iAA) = iCount(iAA) + 1;
    Rec{iAA}{iCount(iAA),1} = Processing.Recording{iA};
    Rec{iAA}{iCount(iAA),2} = [ ...
        IDIR Animal{iAA} filesep Processing.Recording{iA} filesep ...
        'SelectClusts' filesep Processing.Recording{iA} '*.fig'];
    listing = dir(Rec{iAA}{iCount(iAA),2});
    Rec{iAA}{iCount(iAA),3} = ...
        numel(listing);
    
    Rec{iAA}{iCount(iAA),4} = [];
    for iC = 1:numel(listing)
        fname = strsplit(listing(iC).name,'_');
        cnum = round(str2double(fname{5}(2:end)));
        Rec{iAA}{iCount(iAA),4} = ...
                [Rec{iAA}{iCount(iAA),4}; cnum];  
    end
    Rec{iAA}{iCount(iAA),5} = iA;
end

%% CONSTRUCT UI

MainFig = figure('Name', 'PETH Viewer UI', ...
           'Units', 'Normalized', ...
           'Position', [0.1 0.1 0.8 0.8], ...
           'Color', 'w');

ClustPanel = uipanel(MainFig, 'Units', 'normalized', ...
                             'Position', [0.01, 0.01, 0.98, 0.9]);
                         
%% CREATE TAB GROUP
AnimalGroup = uitabgroup(ClustPanel, ...
                            'SelectionChangedFcn',@AnimalChangedCB);   

Anitab = cell(numel(Animal),1);
AniGroup = cell(numel(Animal),1);
Dtab = cell(numel(Animal),1);
DGroup = cell(numel(Animal),1);
PTab = cell(numel(Animal),1);
for iA = 1:numel(Animal)
    Anitab{iA} = uitab(AnimalGroup,'Title',Animal{iA}, ...
                                   'UserData', iA);
      
    AniGroup{iA} = uitabgroup(Anitab{iA},...
                                'UserData', iA, ...
                                'SelectionChangedFcn',@AniChangedCB);
    Dtab{iA} = cell(size(Rec{iA},1),1);
    DGroup{iA} = cell(size(Rec{iA},1),1);
    PTab{iA} = cell(size(Rec{iA},1),1);
    for iD = 1:size(Rec{iA},1)  
        mdstr = strrep(Rec{iA}{iD,1}(12:16),'_','');
        Dtab{iA}{iD} = uitab(AniGroup{iA}, 'Title', mdstr, ...
                                           'UserData',iD);                   
        DGroup{iA}{iD} = uitabgroup(Dtab{iA}{iD}, ...
                           'UserData', iD, ...
                           'SelectionChangedFcn',@DayChangedCB);
        PTab{iA}{iD} = cell(Rec{iA}{iD,3});
        for iC = 1:Rec{iA}{iD,3}
        PTab{iA}{iD}{iC} = uitab(DGroup{iA}{iD}, ...
              'TooltipString',['Cluster ' num2str(Rec{iA}{iD,4}(iC)) ], ...
              'Title',['C' num2str(Rec{iA}{iD,4}(iC))], ...
              'UserData',[iA,iD,iC, ...
              Rec{iA}{iD,4}(iC),Rec{iA}{iD,5}], ...
              'ButtonDownFcn',@SwitchTab);

        end
        DGroup{iA}{iD}.SelectedTab = PTab{iA}{iD}{1};
    end
end
     
TitleLabel = uicontrol('Style','text',...
                'Units', 'Normalized', ...
                'FontSize', 36, ...
                'FontWeight', 'bold', ...
                'FontName', 'Arial', ...
                'BackgroundColor', 'w', ...
                'ForegroundColor', 'k', ...
                'HorizontalAlignment', 'center', ...
                'Position',[0.01 0.92 0.98 0.07],...
                'String','');

%% DEFINE HANDLES TO PASS

[b,a]   = ellip(F_ORD,RP,RS,WN,'low');


handles         =   struct;                  
handles.TVEC    = -E_PRE:BINSIZE:E_POST;       
handles.b       = b;
handles.a       = a;
handles.YMAX    = YMAX;
handles.BINSIZE = BINSIZE;
handles.COL     = COL;
handles.E_PRE   = E_PRE;
handles.E_POST  = E_POST;
handles.DEV_SCL = DEV_SCL;




clear  YMAX BINSIZE COL E_PRE E_POST DEV_SCL E_PRE E_POST a b

    function SwitchTab(src,~)

        thAnimal = Rec{src.UserData(1)}{src.UserData(2),1}(1:5);
        thRec = Rec{src.UserData(1)}{src.UserData(2),1};
        c = load(['Data' filesep 'Aligned' filesep ...
              thAnimal filesep thRec ...
              '_clusterdata.mat']);
        g = load(['Data' filesep 'Aligned' filesep ...
              thAnimal filesep thRec ...
              '_graspdata.mat']);

        nTrials = [numel(g.SuccessTimes), ...
                   numel(g.FailureTimes), ...
                   numel(g.ReachSuccessTimes), ...
                   numel(g.ReachFailureTimes)];

        cnames = RateData{src.UserData(5)}.Properties.VariableNames(1:4);

        nrow = ceil(sqrt(numel(cnames)));
        ncol = nrow;
        
        
        if isempty(get(subplot(nrow,ncol,1,'Parent',src),'Children'))
            
        
            for iCo = 1:numel(cnames) % Plot even ones that were rejected

                subplot(nrow,ncol,iCo,'Parent',src); 
                cla; % Clear this axes
                rate = RateData{src.UserData(5)}.(cnames{iCo})(src.UserData(4),:);
                bar(handles.TVEC(1:end-1)+handles.BINSIZE/2, ...
                    rate/nTrials(iCo)/handles.BINSIZE, ...
                    1,'FaceColor',handles.COL{iCo},'EdgeColor',handles.COL{iCo});

                hold on;
                line([0 0],[0 handles.YMAX], ...
                     'Color', handles.COL{iCo}, ...
                     'LineWidth', 2, ...
                     'LineStyle', ':'); 

                line([min(handles.TVEC) max(handles.TVEC)], ...
                     [RateData{src.UserData(5)}.SpikeRate(src.UserData(4)) RateData{src.UserData(5)}.SpikeRate(src.UserData(4))], ...
                     'Color', 'k', ...
                     'LineWidth', 4, ...
                     'LineStyle', '--');

                dev = RateData{src.UserData(5)}.SpikeDev(src.UserData(4));
                mu = RateData{src.UserData(5)}.SpikeRate(src.UserData(4));
                smoothed = filtfilt(handles.b,handles.a,rate/nTrials(iCo)/handles.BINSIZE);

                plot(handles.TVEC(1:end-1)+handles.BINSIZE/2, smoothed, ...
                    'LineWidth', 3, 'Color', [0.9 0.9 0.9]);
                line([min(handles.TVEC) max(handles.TVEC)], ...
                   [mu-dev*handles.DEV_SCL mu-dev*handles.DEV_SCL], ...
                   'Color', 'm', ...
                   'LineWidth', 2, ...
                   'LineStyle', '-.');

                line([min(handles.TVEC) max(handles.TVEC)], ...
                   [mu+dev*handles.DEV_SCL mu+dev*handles.DEV_SCL], ...
                   'Color', 'm', ...
                   'LineWidth', 2, ...
                   'LineStyle', '-.');

                hold off;
                set(gca,'Xlim',[-handles.E_PRE handles.E_POST]); 
                set(gca,'Ylim',[0 handles.YMAX]);
                title(info{src.UserData(5)}.Conditions{iCo});
                xlabel('Time (sec)');
                ylabel('Spikes/sec');
            end
        end
        set(TitleLabel,'String',[strrep(thRec,'_',' ') ': Cluster ' num2str(src.UserData(4)) ' ' ...
                c.ClusterData.Hemisphere(src.UserData(4)) ' ' ...
                c.ClusterData.ML(src.UserData(4)) ' ' ...
                c.ClusterData.Area(src.UserData(4),:) ': ' ...
                c.ClusterData.Channel(src.UserData(4),:) '-' c.ClusterData.ICMS{src.UserData(4)}]);
            
        
    end

    function AnimalChangedCB(~,eventdata)
        thTab = eventdata.NewValue;
        SwitchTab(DGroup{thTab.UserData}{1}.SelectedTab);
    end

    function AniChangedCB(src,eventdata)
        thTab = eventdata.NewValue;
        SwitchTab(DGroup{src.UserData}{thTab.UserData}.SelectedTab);
    end

    function DayChangedCB(~,eventdata)
        thTab = eventdata.NewValue;
        SwitchTab(thTab);
    end

SwitchTab(DGroup{1}{1}.SelectedTab);

end