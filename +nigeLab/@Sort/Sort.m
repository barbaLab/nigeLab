classdef Sort < handle
%% SORT  Use "cluster-cutting" to manually curate and sort Spikes
%
%  nigeLab.Sort;
%  sortObj = nigeLab.Sort;
%  sortObj = nigeLab.Sort(nigelObj);
%
%   --------
%    INPUTS
%   --------
%   nigelObj  :     (Optional) If not provided, a UI for generation or
%                       loading of the correct orgExpObj pops up.
%                       Otherwise, the Sort class object parses which
%                       orgExpObj is given (based on object class), and
%                       presents the Sort interface based on that.
%
%   --------
%    OUTPUT
%   --------
%   Provides a graphical interface to combine and/or restrict spikes
%   included in each cluster. Works with spikes that have been extracted
%   using the NIGELAB workflow.
%
% Originally by: Max Murphy
% Modified by: Max Murphy & Fred Barban
%
%                   v3.0    01/07/2019  Integrate from "CRC" to orgExp.Sort
%                   v2.1    10/03/2017  Added ability to handle multiple
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
   
   %% PROPERTIES
   properties (Access = public)
      data     % Array of orgExp block objects
      handles  % Graphics handles
   end
   
   properties (Access = private)
      pars  % Parameters
   end
   
   %% METHODS
   methods (Access = public)
      function sortObj = Sort(nigelObj)
         %% SORT  Sort class object constructor
         %
         %  nigeLab.Sort;
         %  sortObj = nigeLab.Sort;
         %  sortObj = nigeLab.Sort(nigelObj);
         %
         % By: Max Murphy & Fred Barban 2019-01-07                           
         
         %% INITIALIZE PARAMETERS
         if ~initParams(sortObj)
            error('Sort object parameterization unsuccessful.');
         end
         
         %% INITIALIZE INPUT DATA
         if nargin > 0
            if ~initData(sortObj,nigelObj)
               error('OrgExpObj array not created successfully.');
            end
         else
            if ~initData(sortObj)
               error('OrgExpObj array not created successfully.');
            end
         end
         
         %% INITIALIZE GRAPHICAL INTERFACE
         if ~initUI(sortObj)
            error('Error constructing graphical interface for sorting.');
         end

      end
      
   end
   
   methods (Access = private)
      
      flag = initParams(sortObj);
      flag = initData(sortObj,orgExpObj);
      flag = initUI(sortObj);
      
   end
   
end