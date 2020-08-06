% @ANIMAL Object that manages recordings from a single animal. These could be from the same session, or across multiple days.
% MATLAB Version 9.2.0.538062 (R2017a) 06-Aug-2020
%
% Method Files
%   getNumBlocks      - Just makes it easier to count all blocks (common to TANK)
%   init              - Initialize nigeLab.Animal class object
%   list              - Give list of properties associated with this block
%   listBlocks        - WIP Returns a nested table with the protocols associated with the rat and different infos
%   mergeBlocks       - BlockFieldsToMerge_                   'Channels'
%   parseProbes       - Parse .Probes property struct fields using child "blocks"
%   splitMultiAnimals - Split blocks with multiple animals recorded in the
%   subsref           - Overloaded function modified so that BLOCK can be
%
% Class File
%   Animal            - Object that manages recordings from a single animal. These could be from the same session, or across multiple days.

