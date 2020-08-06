% @SORT User interface for "cluster-cutting" to manually classify spikes
% MATLAB Version 9.2.0.538062 (R2017a) 06-Aug-2020
%
% Method Files
%   getAllSpikeData  - Concatenate all spike data for a given channel
%   initData         - Initialize data structure for Spike Sorting UI
%   initParams       - Initialize parameters structure for Spike Sorting UI.
%   initUI           - Initialize graphics handles for Spike Sorting UI
%   parseAnimals     - Add blocks to Sort object from Animal objects
%   parseBlocks      - Add blocks to Sort object
%   parseChannelName - Get unique channel/probe combination for identifier
%   saveData         - Save data on the disk
%   setAxesPositions - Determine axes spacing for spike plots
%   setChannel       - Set the channel for UI elements
%   setClass         - Set class on current channel
%
% Class File
%   Sort             - User interface for "cluster-cutting" to manually classify spikes
