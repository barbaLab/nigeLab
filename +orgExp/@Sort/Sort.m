function h = Sort(varargin)
%% SORT  Use "cluster-cutting" to manually curate and sort Spikes
%
%  CRC;
%  h = CRC;
%  h = CRC('NAME',value,...);
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs.
%
%       -> 'DIR' \\ Directory containing CLUSTERED spike files.
%
%       -> 'OUT_ID' \\ Appended tag that replaces 'Clusters' folder
%                      identifier for the sorted output. (Default:
%                      'Sorted')
%
%       -> 'FORCE_NEXT' \\ (Default: false) Set true to automatically jump
%                          to next channel on clicking CONFIRM CHANNEL.
%
%       -> 'T_RES' \\ (Default: 1) Time resolution for tracking cluster
%                     quality through recording (units: minutes).
%
%       -> 'FS_DEF' \\ (Default: 24414.0625 Hz) Should always use fs
%                       associated with recording file, but in case it is
%                       not present will default to this value for
%                       displaying any temporal values.
%
%       -> 'SD_MIN' \\ (Default: 0) Minimum # standard deviations from
%                       cluster medroid (in feature-space) to allow spikes.
%
%       -> 'SD_MAX' \\ (Default: 10) Max # SD from cluster medroid to allow
%                       spikes. If tick boxes are unchecked, then the value
%                       is compared to inf instead.
%
%       -> 'NPOINTS'\\ (Default: 8)Number of circle edge points to plot.
%
%       -> 'NZTICK' \\ (Default: 9) # Z-tick labels for time-axis.
%
%       -> 'DEBUG' \\ Causes most actions to spit out the handles struct
%                     variable to the base workspace for debugging.
%
%   --------
%    OUTPUT
%   --------
%      h       :     Handle to ClusterUI object for debugging.
%
%   Provides a graphical interface to combine and/or restrict spikes
%   included in each cluster. Works with spikes that have been extracted
%   using the KMEANS version of QSD.
%
% By: Max Murphy    v2.1    10/03/2017  Added ability to handle multiple
%                                       probes that have redundant input
%                                       channel names.
%                   v2.0    08/21/2017  Plots are done differently now, so
%                                       that all spikes are plotted using
%                                       imagesc instead of a random subset
%                                       using plot. Imagesc is much faster
%                                       and lets you see everything better.
%                                       Working on adding "cutting" tool
%                                       using imline to select subsets of
%                                       spikes for new clusters.
%                   v1.3    08/20/2017  Tried to switch code to
%                                       object-oriented design with class
%                                       definitions, etc.
%                   v1.2    08/09/2017  Fixed bug with cluster radius norm.
%                   v1.1    08/08/2017  Changed features display to have a
%                                       drop-down menu that allows you to
%                                       select which features to look at.
%                   v1.0    08/04/2017  Original version (R2017a)

%% SET STATE VARIABLES
% Get location where file is run from and add
srcpath = which(mfilename);
[srcpath,~,~] = fileparts(srcpath);
addpath(genpath(srcpath));

%% INITIALIZE HANDLES STRUCTURE
if nargin > 0
   handles = CRC_Init(varargin);
else
   handles = CRC_Init;
end

%% MAKE INTERFACE
h = CRC_ClusterUI(handles);                 

end