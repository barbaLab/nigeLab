function ExtractIntanList(List)
%% EXTRACTINTANLIST  Loop through and extract Intan .rhd files using cluster.
%
%   EXTRACTINTANLIST(List)
%
%   --------
%    INPUTS
%   --------
%     List      :       N x k char array of N strings containing the full
%                       file (path, name and extension) of the desired .rhd
%                       files to extract.
%
% By: Max Murphy    v1.0    01/31/2017

%% DEFAULTS
clc;
TANK_LOC = 'R:/Rat/Intan';
SAVE_LOC = 'P:/RatElectrophysiology/Cortex/BehaviorallyDrivenSUactivity/UnilateralReach';

%% PATH INFO
UNC_Paths = {'//kumc.edu/data/research/SOM RSCH/NUDOLAB/Processed_Data/', ...
             '//kumc.edu/data/research/SOM RSCH/NUDOLAB/Recorded_Data/'}; %Can be switched by user preference
TANK_LOC = [UNC_Paths{2} TANK_LOC((find(TANK_LOC == '/',1,'first')+1):end)];
SAVE_LOC = [UNC_Paths{1} SAVE_LOC((find(SAVE_LOC == '/',1,'first')+1):end)];

% poolobj = gcp('nocreate'); % If no pool, do not create new one.
% if isempty(poolobj)
%     poolobj = parpool(Cluster,MYCLUSTER.NumWorkers,'IdleTimeout',Inf); %#ok<NASGU>
% else
%     poolobj = gcp; %#ok<NASGU>
% end

for iL = 1:size(List,1)
    fname = fullfile(TANK_LOC,List(iL,1:6),List(iL,:)); %#ok<PFBNS>
    INTAN2single_ch('NAME', fname, ...
                    'SAVELOC', SAVE_LOC); 
    clc
end

end