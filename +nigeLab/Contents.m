%+NIGELAB Tools for neurophysiological data analyses
% MATLAB Version 9.2.0.538062 (R2017a) 06-Aug-2020
%
% See repository wiki for more-detailed reference.
%
% Classes
%  @nigelObj             - Superclass of nigeLab data access objects.
%  @Animal               - Object that manages recordings from a single animal. These could be from the same session, or across multiple days.
%  @Block                - Object containing all data for a single experimental recording.
%  @Sort                 - User interface for "cluster-cutting" to manually classify spikes.
%  @Tank                 - Object that contains all data for a given experiment.
%
% Packages
%  +defaults             - Package with default configuration files for parameters in `.Pars` struct property sub-fields.
%  +evt                  - Package with custom eventdata for Events/Listeners
%  +libs                 - Package with "library" of different UI classes etc
%  +sounds               - Package with sound files (if initialized repo with Git-LFS) and function to play them
%  +utils                - Package with miscellaneous utility functions
%  +workflow             - Package with custom workflow functions (for example, shortcuts to use with `scoreVideo` UI)
%
% Folders
%  setup - Scripts to ensure all dependencies are installed.
%  temp  - Temporary scripts that are invoked on remote workers, for example.