% +WORKFLOW Package with custom workflow functions (for example, shortcuts to use with `scoreVideo` UI)
% MATLAB Version 9.2.0.538062 (R2017a) 06-Aug-2020
%
% Files
%   behaviorData2BlockEvents       - Convert behaviorData table to EVENT data files
%   defaultForceToZeroFcn          - Function that forces all values for a given Trial
%   defaultHotkeyFcn               - Default function mapping hotkeys for video scoring
%   defaultHotkeyHelpFcn           - Default function mapping hotkeys for video scoring
%   defaultVideoScoringShortcutFcn - Handles shortcuts during video scoring
%   defaultVideoScoringStrings     - Default function that returns a string based
%   mat2Block                      - Default function for nigeLab.Block.MatFileWorkflow.ExtractFcn
%   mat2BlockRC                    - nigeLab.Block.MatFileWorkflow.ExtractFcn for 'RC' project
%   rc2Block                       - Convert from RC format to BLOCK format
%   readMatInfo                    - Function to read a nigeLab block header previously stored in a matfile
%   readMatInfoRC                  - Workflow to parse RC format header
