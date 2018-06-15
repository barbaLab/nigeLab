classdef Tank < handle
%% TANK  Create a datastore for a related group of experimental recordings
%
%  tankObj = TANK;
%  tankObj = TANK('NAME','VALUE',...);   
%
%  ex: 
%  tankObj = TANK('DIR','P:\Your\Recording\Directory\Here');
%
%  TANK Properties:
%     Name - Name of experimental TANK.
%
%  TANK Methods:
%     Tank - TANK Class object constructor.
%
%     get - Get a specific property from the TANK object.
%
%     list - List Block objects in the TANK.
%
%     set - Set a specific property of the TANK object. Returns a boolean
%           flag as true if property is set successfully.
%
% By: Max Murphy  v1.0  06/14/2018

   %% PUBLIC PROPERTIES
   properties (Access = public)
      Name	% Name of experiment (TANK)
      
   end
   %% PRIVATE PROPERTIES
   properties (Access = private)
      Block	% Children (BLOCK)
      DIR   % Directory of the TANK
      DEF = 'R:/Rat'; % Default for UI TANK selection
   end
   
   %% PUBLIC METHODS
   methods (Access = public)
      function tankObj = Tank(varargin)
         %% TANK  Construct Tank Class object
         %
         %  tankObj = TANK;
         %  tankObj = TANK('NAME',Value,...);
         %
         %  ex: 
         %  tankObj = TANK('DIR','P:\Your\Block\Directory\Here');
         %
         %  List of 'NAME', Value input argument pairs:
         %
         %  -> 'DIR' : (def: none) Specify as string with full directory of
         %              recording BLOCK. Specifying this will skip the UI
         %              selection portion, so it's useful if you are
         %              looping the expression.
         %
         % By: Max Murphy  v1.0  06/14/2018
         
         %% PARSE VARARGIN
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue
            end
            p = findprop(tankObj,varargin{iV});
            if isempty(p)
               continue
            end
            tankObj.(varargin{iV}) = varargin{iV+1};
         end
         
         %% LOOK FOR BLOCK DIRECTORY
         if isempty(tankObj.DIR)
            tankObj.DIR = uigetdir(tankObj.DEF,'Select recording BLOCK');
            if tankObj.DIR == 0
               error('No block selected. Object not created.');
            end
         else
            if exist(tankObj.DIR,'dir')==0
               error('%s is not a valid block directory.',tankObj.DIR);
            end
         end
         
         %% INITIALIZE TANK OBJECT
         tankObj.init;
         
      end
      
      blockList = list(tankObj)    % List Blocks in TANK
      out = tankGet(tankObj,prop)  % Get a specific TANK property
      flag = tankSet(tankObj,prop) % Set a specific TANK property
   end
   %% PRIVATE METHODS
   methods (Access = private)
      init(tankObj) % Initializes the TANK object.
   end
end