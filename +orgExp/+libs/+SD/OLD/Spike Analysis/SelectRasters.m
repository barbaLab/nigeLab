function varargout = SelectRasters(varargin)
%% SELECTRASTERS    Align grasp times to spike times for all profiles
%
%   SELECTRASTERS('NAME',value,...)
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
%
%   --------
%    OUTPUT
%   --------
%   Mat file containing aligned output data and statistics relevant to
%   recorded spike trains, by area, for only user-specified "excitatory,"
%   "inhibitory," or "both" for stimulus-dependent cell activation.
%
%
% See also: MERGEWAVES, SORTCLUSTERS, PLOTSPIKERASTERS, ALIGN
%   By: Max Murphy  v1.2    01/10/2017  Added varargout to keep track of
%                                       optional input 'PROCESSING'
%                   v1.1    01/05/2017  Reduced # spikes for export;
%                                       changed it to a random subsection
%                                       when there are greater than 200
%                                       spikes, rather than the first 200
%                                       spikes in general.
%                   v1.0    01/02/2017  Original Version

%% DEFAULTS
clearvars -except varargin; close all force; clc

% Alignment parameters
E_PRE       = 4;                     % Epoch pre-alignment (sec)
E_POST      = 2;                     % Epoch post-alignment (sec)

% Spike plotting parameters
MAXSPIKES = 200;
TVEC       = (1:32)./24414.0625 * 1e3;

% Raster Line Format
LINEFORMAT = struct;
    LINEFORMAT.Color = [0.05 0.05 0.05];
    LINEFORMAT.LineWidth = 1.25;
    LINEFORMAT.LineStyle = '-';
    
% Directory info
MDIR  = 'Data/Processed Recording Files/Merged'; % Directory of names
ODIR  = 'Data/Selected';                         % Output directory
IDIR  = 'Data/Aligned';                          % Input directory

G_ID  = 'graspdata';                             % Aligned data input ID
C_ID  = 'clusterdata';                           % Cluster data input ID
O_ID  = 'selected';                              % Selected data output ID
F_ID  = 'selectedrasters';                        % Figure ID

% Other
COL   = {'Successes'; 'Failures'; 'ReachSuccesses'; 'ReachFailures'};
CTYPE = {[1 1 1]; ...
         [1 1 0]; ...
         [0.25 1 0.25]; ...
         [0.5 0.5 1]; ...
         [0.8 0.5 0.7]; ...
         [1 0.7 0]};
CLUSTTYPE = {'Flagged', ...
             'Excited', ...
             'Inhibited', ...
             'Both', ...
             'High Activity'};
FLABEL = {'Successful Grasps'; ...
          'Failure Grasps'; ...
          'Successful Reaches'; ...
          'Failure Reaches'};


%% ADD HELPER FUNCTIONS
pname = mfilename('fullpath');
fname = mfilename;
pname = pname(1:end-length(fname));

addpath([pname 'libs']);
clear pname fname

%% PARSE VARARGIN
for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% SELECT RECORDING
% If pre-specified in optional arguments, skip this step.
if exist('NAME', 'var') == 0
    NAME = uigetdir(MDIR);
    NAME = strsplit(NAME, '\');
    NAME = NAME{end};
    
    if NAME == 0 % Must select a directory
        error('Must select a valid directory.');
    elseif exist([IDIR '/' NAME(1:5)], 'dir') == 0
        error('Must select a valid directory.');
    end
    
    G = dir([IDIR '/' NAME(1:5) '/' NAME '_' G_ID '.mat']);
    C = dir([IDIR '/' NAME(1:5) '/' NAME '_' C_ID '.mat']);
    
    if (isempty(G) || isempty(C)) % Must contain valid files
        error([MDIR '/' NAME ' does not contain any files formatted ' ...
               C_ID ' or ' G_ID '. Check SP_ID or verify that directory' ...
               ' contains appropriate files.']);
    end
    
else    % If a pre-specified path exists, must be a valid path.
    
    if NAME == 0 % Must select a directory
        error('Must select a valid directory.');
    elseif exist([IDIR '/' NAME(1:5)], 'dir') == 0
        error('Must select a valid directory.');
    end
    
    G = dir([IDIR '/' NAME(1:5) '/' NAME '_' G_ID '.mat']);
    C = dir([IDIR '/' NAME(1:5) '/' NAME '_' C_ID '.mat']);
    
    if (isempty(G) || isempty(C)) % Must contain valid files
        error([MDIR '/' NAME ' missing files formatted ' ...
               C_ID ' or ' G_ID '. Check SP_ID or verify that directory' ...
               ' contains appropriate files.']);
    end
end

%% LOAD DATA
G = load([IDIR '/' NAME(1:5) '/' G(1).name]);
C = load([IDIR '/' NAME(1:5) '/' C(1).name]);
ClusterData = C.ClusterData;
clear C

%% DEFINE VARIABLES
nClusters = size(G.GraspData,1);
nrow = ceil(sqrt(nClusters));
ncol = nrow;
ClusterTypes = ones(nClusters,1);
SAVEFLAG = true;

%% POPULATE FIGURE AND CONFIGURE GUI
MainFig = figure('Name', 'Manual Cluster Determinations', ...
                   'Units', 'Normalized', ...
                   'Position', [0.1 0.1 0.8 0.8], ...
                   'Color', 'w', ...
                   'NumberTitle', 'off', ...
                   'ToolBar', 'none', ...
                   'MenuBar', 'none');
   
%% CREATE CLUSTER SUBPLOT PANEL     
ClustPanel = uipanel(MainFig, 'Units', 'normalized', ...
                             'Position', [0.05, 0.05, 0.75, 0.9], ...
                             'BackgroundColor', 'w', ...
                             'ForegroundColor', 'k', ...
                             'BorderType', 'line', ...
                             'BorderWidth', 3, ...
                             'HighlightColor', 'k', ...
                             'ShadowColor', 'w', ...
                             'FontSize', 14, ...
                             'Title', 'Spike Clusters');

BehavGroup  = uitabgroup(ClustPanel);
    GStab   = uitab(BehavGroup, 'Title', 'Grasp Successes', ...
                                'BackgroundColor', 'w', ...
                                'UserData', 1, ...
                                'ButtonDownFcn', @SwitchTab);
    GFtab   = uitab(BehavGroup, 'Title', 'Grasp Failures', ...
                                'BackgroundColor', 'w', ...
                                'UserData', 2, ...
                                'ButtonDownFcn', @SwitchTab);
    RStab   = uitab(BehavGroup, 'Title', 'Reach Successes', ...
                                'BackgroundColor', 'w', ...
                                'UserData', 3, ...
                                'ButtonDownFcn', @SwitchTab);
    RFtab   = uitab(BehavGroup, 'Title', 'Reach Failures', ...
                                'BackgroundColor', 'w', ...
                                'UserData', 4, ...
                                'ButtonDownFcn', @SwitchTab);
                         
%% CREATE SAVE AND EXIT BUTTONS
uicontrol(MainFig, 'Style', 'pushbutton', ...
                            'Units', 'normalized', ...
                            'Position', [0.825, 0.4, 0.15, 0.1], ...
                            'FontSize', 16, ...
                            'BackgroundColor', 'b', ...
                            'ForegroundColor', 'w', ...
                            'String', 'EXPORT', ...
                            'Callback', @ExportFunction);

uicontrol(MainFig, 'Style', 'pushbutton', ...
                            'Units', 'normalized', ...
                            'Position', [0.825, 0.25, 0.15, 0.1], ...
                            'FontSize', 16, ...
                            'BackgroundColor', 'g', ...
                            'String', 'SAVE', ...
                            'Callback', @SaveFunction);
                        
uicontrol(MainFig, 'Style', 'pushbutton', ...
                            'Units', 'normalized', ...
                            'Position', [0.825, 0.10, 0.15, 0.1], ...
                            'FontSize', 16, ...
                            'ForegroundColor', 'w', ...
                            'BackgroundColor', 'r', ...
                            'String', 'EXIT', ...
                            'Callback', @ExitFunction);
                        
%% CREATE TYPE SELECTION LIST
TypeList = uicontrol(MainFig, 'Style', 'listbox', ...
                           'Units', 'Normalized', ...
                           'Position', [0.825, 0.55, 0.15, 0.3], ...
                           'String', CLUSTTYPE, ...
                           'FontSize', 16);
                        
%% MAKE OUTPUT DIRECTORY AND SAVE
if exist([ODIR '/' NAME(1:5)],'dir')==0
    mkdir([ODIR '/' NAME(1:5)]);
end

%% UPDATE 'PROCESSING' VARIABLE IF IT EXISTS
if exist('PROCESSING', 'var')~=0
    PROCESSING.SelectedProgress{ismember(PROCESSING.Recording, NAME)} = ...
        'Complete';
    varargout{1} = PROCESSING;
end

%% OTHER FUNCTIONS
    % Switching tab to different behavior
    function SwitchTab(src,~)
        data = G.GraspData.(COL{src.UserData});
        nEvents = numel(data{1});
        if nEvents >= 10
            for ii = 1:nClusters
                if ~any(~cellfun(@isempty,data{ii}))
                    continue
                end
                subplot(nrow,ncol,ii,'Parent',BehavGroup.SelectedTab); ...
                plotSpikeRaster(data{ii}, ...
                                'PlotType','vertline', ...
                                'LineFormat',LINEFORMAT); ...
                hold on;
                line([0 0],[0 nEvents + 1], ...
                     'Color', 'm', ...
                     'LineWIdth', 2, ...
                     'LineStyle', '--'); 
                hold off;
                set(gca,'Xlim',[-E_PRE E_POST]); 
                set(gca,'Color', CTYPE{ClusterTypes(ii)});
                set(gca,'ButtonDownFcn', @SetClusterType);
                set(gca,'UserData',ii);
                temp = get(gca, 'Children');
                for ik = 1:length(temp)
                    set(temp(ik),'UserData',ii);
                    set(temp(ik),'ButtonDownFcn',@SetClusterType);
                end
            end
        end 
        
    end

    % Clicking a raster plot
    function SetClusterType(src,~)
        if ClusterTypes(src.UserData)==1
            set(gca,'Color',CTYPE{TypeList.Value+1});
            ClusterTypes(src.UserData) = TypeList.Value+1;
            
        elseif (ClusterTypes(src.UserData)>1 && ...
                ClusterTypes(src.UserData)~=TypeList.Value+1)
            set(gca,'Color',CTYPE{TypeList.Value+1});
            ClusterTypes(src.UserData) = TypeList.Value+1;
            
        else
            ClusterTypes(src.UserData) = 1;
            set(gca,'Color',CTYPE{ClusterTypes(src.UserData)});
        end
    end

    % Exit this function
    function ExitFunction(~,~)
        if SAVEFLAG
            msg = questdlg('Exit without saving?', 'Double-Checking', ...
                           'Yes', 'No', 'No');
                       
            if strcmp(msg, 'No')
                return
            else
                disp('Exited manual scoring without saving.');
            end
        else
            disp('Exited manual scoring.');
        end
        delete(MainFig);
    end

    % Save assignments
    function SaveFunction(~,~)
        disp('Saving data...');
        BehaviorRelation = cell(nClusters,1);
        for iC = 1:nClusters
            if ClusterTypes(iC) > 1
                BehaviorRelation{iC,1} = CLUSTTYPE{ClusterTypes(iC)-1};
            else
                BehaviorRelation{iC,1} = 'Unrelated';
            end
        end
        SelectedRasters = table(ClusterTypes,BehaviorRelation);
        save([ODIR '/' NAME(1:5) '/' NAME '_' O_ID '.mat'], ...
              'SelectedRasters', '-v7.3');
        SAVEFLAG = false;
        disp('...complete!');
        
        msg = questdlg('Exit?', 'Quit', 'Yes', 'No', 'Yes');
        if strcmp(msg, 'Yes')
            delete(MainFig);
            clear
            return
        end
    end

    % Export selected types
    function ExportFunction(~,~)
        disp('Please wait, generating export figure...');
        ntab = BehavGroup.SelectedTab.UserData;
        vec = find(ClusterTypes>1);
        nplot = numel(vec);
        prow = ceil(sqrt(nplot*2));
        pcol = prow;
        if rem(pcol,2)==1
            pcol = pcol + 1;
            prow = ceil(nplot*2/pcol);
        end
        
        data = G.GraspData.(COL{BehavGroup.SelectedTab.UserData});
        
        
        
        figure('Name', FLABEL{ntab}, ...
               'Units', 'Normalized', ...
               'Position', [0.1 0.1 0.8 0.8], ...
               'Color', 'w');
    
        for ii = 1:nplot
            subplot(prow,pcol,2*(ii-1) + 1); 
            plotSpikeRaster(data{vec(ii)}, ...
                            'PlotType','vertline', ...
                            'LineFormat',LINEFORMAT); ...
            hold on;
            line([0 0],[0  numel(data{1}) + 1], ...
                 'Color', 'm', ...
                 'LineWIdth', 2, ...
                 'LineStyle', '--'); 
            hold off;
            set(gca,'Xlim',[-E_PRE E_POST]); 
            set(gca,'Color', CTYPE{ClusterTypes(vec(ii))});
            if strcmp(ClusterData.Hemisphere(vec(ii)), 'L')
                tempside = 'Left';
            else
                tempside = 'Right';
            end
            
            if strcmp(ClusterData.ML(vec(ii)), 'M')
                tempML = 'Medial';
            elseif strcmp(ClusterData.ML(vec(ii)), 'L')
                tempML = 'Lateral';
            else
                tempML = '';
            end
            
            title([tempside ' ' tempML ' ' ...
                   ClusterData.Area(vec(ii),:)], ...
                   'Color', 'k');
               
            subplot(prow,pcol,2*ii);
            SpikeTemplate = mean(ClusterData.Waveforms{vec(ii)});
            
            nspk = size(ClusterData.Waveforms{vec(ii)},1);
            if nspk >= MAXSPIKES
                spkvec = RandSelect(1:nspk,MAXSPIKES);
                plot(TVEC, ClusterData.Waveforms{vec(ii)}(spkvec,:).', ...
                     'Color', [0.94 0.95 0.94]);
            else
                plot(TVEC, ClusterData.Waveforms{vec(ii)}.', ...
                     'Color', [0.94 0.95 0.94]);
            end
            hold on;
            plot(TVEC, SpikeTemplate, ...
                                 'LineWidth', 2.5, ...
                                 'Color', 'k', ...
                                 'LineStyle', '--');
            set(gca,'Color', CTYPE{ClusterTypes(vec(ii))} * 0.90);
            set(gca, 'XLim', [min(TVEC) max(TVEC)]);
            set(gca, 'YLim', [-120 120]);
            title(['Ch' ClusterData.Channel(vec(ii),:) ...
                    '-' ClusterData.ICMS{vec(ii)}], 'Color', 'k');

            hold off
        end
        disp('-> Figure generated.');
        supt = suptitle([strrep(NAME,'_',' ') ': ' FLABEL{ntab}]);
        supt.Color = 'k';
        
        
        msg = questdlg('Save Figure?', 'Save?', ...
                       'Yes', 'No', 'No');
        
        if strcmp(msg, 'Yes')
            clear msg
            if exist([ODIR '/' NAME(1:5) '/' NAME], 'dir')==0
                mkdir([ODIR '/' NAME(1:5) '/' NAME]);
            end

            disp('Please wait, save in progress (box will pop up when done)');
            savefig(gcf,[ODIR '/' NAME(1:5) '/' NAME '/' NAME '_' ...
                lower(strrep(FLABEL{ntab}, ' ', '')) '_' F_ID '.fig']);
            saveas(gcf,[ODIR '/' NAME(1:5) '/' NAME '/' NAME '_' ...
                lower(strrep(FLABEL{ntab}, ' ', '')) '_' F_ID '.jpeg']);

            disp('-> figure export complete.');
            msg = questdlg('Save complete. Close figure?', 'Close?', ...
                           'Yes', 'No', 'Yes');
            if strcmp(msg, 'Yes')
                delete(gcf);
                return
            end
        end
        
    end

%% INITIALIZE
SwitchTab(GStab);


end