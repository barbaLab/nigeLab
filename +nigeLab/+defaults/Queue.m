function varargout = Queue(varargin)
%% QUEUE  Template for initializing parameters for submitting jobs to queue
%
%  pars = nigeLab.defaults.Queue;
%  pars = nigeLab.defaults.Queue(paramName);  % returns a single parameter
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
pars = struct;

% Only specify this field if you want to force use of a single cluster
% pars.Cluster = 'CPLMJS'; 
pars.UseParallel = true; % set to false to switch to serial processing mode
pars.UseRemote = true;
% pars.UseParallel = false;
% pars.UseRemote = false;

% UNC path and cluster list for Matlab Distributed Computing Toolbox
pars.UNCPath.RecDir = '//kumc.edu/data/research/SOM RSCH/NUDOLAB/Recorded_Data/'; 
pars.UNCPath.SaveLoc = '//kumc.edu/data/research/SOM RSCH/NUDOLAB/Processed_Data/';

pars.ClusterList = {'CPLMJS'; 'CPLMJS2'; 'CPLMJS3'};
pars.NWorkerMinMax = [1,1]; % Min & Max # workers to assign to a job
pars.WaitTimeSec = 1; % Time to wait between checking for new cluster
pars.InitTimeSec = 5; % Time to wait when initializing cluster

% pars.RemoteRepoPath = '';
% Note: package & method directories not allowed on Matlab Path-
% pars.RemoteRepoPath = {'//KUMC-NAS01/home-kumc/m053m716/MyRepos/nigeLab',...
%    '//KUMC-NAS01/home-kumc/m053m716/MyRepos/nigeLab/+nigeLab',...
%    '//KUMC-NAS01/home-kumc/m053m716/MyRepos/nigeLab/+nigeLab/@Block',...
%    '//KUMC-NAS01/home-kumc/m053m716/MyRepos/nigeLab/+nigeLab/@Block/private',...
%    '//KUMC-NAS01/home-kumc/m053m716/MyRepos/nigeLab/+nigeLab/+defaults',...
%    '//KUMC-NAS01/home-kumc/m053m716/MyRepos/nigeLab/+nigeLab/+defaults/+AutoClustering',...
%    '//KUMC-NAS01/home-kumc/m053m716/MyRepos/nigeLab/+nigeLab/+evt',...
%    '//KUMC-NAS01/home-kumc/m053m716/MyRepos/nigeLab/+nigeLab/+utils'};
% pars.RemoteRepoPath = {'//kumc.edu/data/research/SOM RSCH/NUDOLAB/Scripts_Circuits/Communal_Code/nigeLab/',...
%             '//kumc-data01/research/SOM RSCH/NUDOLAB/Scripts_Circuits/Communal_Code/nigeLab/',...
%             '//kumc-data02/research/SOM RSCH/NUDOLAB/Scripts_Circuits/Communal_Code/nigeLab/',...
%             '//kumc-data03/research/SOM RSCH/NUDOLAB/Scripts_Circuits/Communal_Code/nigeLab/',...
%             '//kumc-data04/research/SOM RSCH/NUDOLAB/Scripts_Circuits/Communal_Code/nigeLab/'};
pars.RemoteRepoPath = {'//kumc.edu/data/research/SOM RSCH/NUDOLAB/Scripts_Circuits/Communal_Code/nigeLab/'};

%% Parse output
if nargin < 1
   varargout = {pars};
else
   varargout = cell(1,nargin);
   f = fieldnames(pars);
   for i = 1:nargin
      idx = ismember(lower(f),lower(varargin{i}));
      if sum(idx) == 1
         varargout{i} = pars.(f{idx});
      end
   end
end


end

