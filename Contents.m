%NIGELAB Tools for neurophysiological data analyses
% MATLAB Version 9.2.0.538062 (R2017a) 06-Aug-2020
%
% See repository wiki for more-detailed reference.
%
% Classes
%  +nigeLab/@nigelObj             - Superclass of nigeLab data access objects.
%  +nigeLab/@Animal               - Object that manages recordings from a single animal. These could be from the same session, or across multiple days.
%  +nigeLab/@Block                - Object containing all data for a single experimental recording.
%  +nigeLab/@Sort                 - User interface for "cluster-cutting" to manually classify spikes.
%  +nigeLab/@Tank                 - Object that contains all data for a given experiment.
%
% Packages
%  +nigeLab/+defaults             - Package with default configuration files for parameters in `.Pars` struct property sub-fields.
%  +nigeLab/+evt                  - Package with custom eventdata for Events/Listeners
%  +nigeLab/+libs                 - Package with "library" of different UI classes etc
%  +nigeLab/+sounds               - Package with sound files (if initialized repo with Git-LFS) and function to play them
%  +nigeLab/+utils                - Package with miscellaneous utility functions
%  +nigeLab/+workflow             - Package with custom workflow functions (for example, shortcuts to use with `scoreVideo` UI)
%
% Folders
%  <a href="help('+nigeLab/setup')">setup</a> - Scripts to ensure all dependencies are installed.
%
% Scripts
%  example_murphy_thesis - Example walkthrough to initialize tank for Murphy thesis data used for EKF model.