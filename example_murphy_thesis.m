%EXAMPLE_MURPHY_THESIS  Steps on initializing data in Murphy EKF model
%
%  Usage (Command Window):
%  ```
%  >> example_murphy_thesis;
%  ```
%
%  ```
%  >> help('example_murphy_thesis');
%  ```
%
% See also: nigeLab, nigeLab.defaults

% Parameters changed from defaults:
%  defaults.Queue.UseParallel: false -> true
%  defaults.Queue.UseRemote: false -> true
%  defaults.Queue.RemoteRepoPath: {'T:\Communal_Code\nigeLab'} ->
%                                 {'T:\Comunal_Code\MurphyThesis'}
%
%     note: Remote Repo is the same as nigeLab but just to be sure it is on
%           the correct git version, this is a separate copy of the
%           corresponding nigeLab version that is kept separate from the
%           "working" version on KUMC Isilon.
%
%  
%
clear; clc;

tankRecPath = 'R:\Rat\Intan\MurphyThesis';
tankSavePath = 'P:\Rat\BilateralReach\Thesis';

tankObj = Tank(tankRecPath,tankSavePath);