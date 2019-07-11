classdef Tank < handle
%% TANK  Class to handle each nigeLab.Animal for a whole experiment
%
%  tankObj = TANK;
%  tankObj = TANK('NAME','VALUE',...);   
%
%  ex: 
%  tankObj = TANK('RecDir','P:\Your\Recording\Directory\Here');
%
%  TANK Properties:
%     Name - Name of experimental TANK.
%
%  TANK Methods:
%     Tank - TANK Class object constructor.
%
%     convert - Convert raw data files to Matlab BLOCK hierarchical format.
%
%     createMetadata - Creates metadata file in Processed TANK parent
%                      folder.
%
%     list - List Block objects in the TANK.
%
%     tankGet - Get a specific property from the TANK object.
%
%     tankSet - Set a property of the TANK object. Returns a boolean
%               flag as true if property is set successfully.
%
% By: Max Murphy  v1.0  06/14/2018

   %% PUBLIC PROPERTIES
   properties (GetAccess = public, SetAccess = public)
      Name	% Name of experiment (TANK)
      Animals                 % Children (ANIMAL)
   end
   
   properties (SetAccess = private, GetAccess = public)
       Paths         % Detailed paths specifications for all the saved files
   end
   
   %% PRIVATE PROPERTIES
   properties (GetAccess = public, SetAccess = private, Hidden = true) %debugging purposes, is private
      RecDir                  % Directory of the TANK
      SaveLoc                 % Top folder
      Pars                    % Parameters struct
      
      BlockNameVars           % Metadata variables from BLOCK names
      BlockStatusFlag         % Flag to indicate if blocks are at same step
      CheckBeforeConversion   % Flag to ask for confirmation before convert
      DefaultSaveLoc          % Default for save location
      DefaultTankLoc          % Default for UI TANK selection
      Delimiter               % Filename metadata delimiter
      RecType                 % Acquisition system used for this Tank
                              % Currently supported formats
                              % ---------------------------
                              % Intan  ('Intan')
                              % TDT    ('TDT')         
                              
      ExtractFlag             % Flag to indicate if extraction is needed
      ParallelFlag            % Flag to run things via parallel architecture
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
         %  tankObj = TANK('RecDir','P:\Your\Block\Directory\Here');
         %
         %  List of 'NAME', Value input argument pairs:
         %
         %  -> 'RecDir' : (def: none) Specify as string with full directory of
         %              recording BLOCK. Specifying this will skip the UI
         %              selection portion, so it's useful if you are
         %              looping the expression.
         %
         % By: Max Murphy  v1.0  06/14/2018
         
         %% LOAD OTHER PRIVATE DEFAULT SETTINGS
%          tankObj = def_params(tankObj);
         tankObj.updateParams('Tank');
         tankObj.updateParams('all');
         
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
         if isempty(tankObj.RecDir)
            tankObj.RecDir = uigetdir(tankObj.Pars.DefaultTankLoc,...
                                   'Select TANK folder');
            if tankObj.RecDir == 0
               error('No block selected. Object not created.');
            end
         else
            if exist(tankObj.RecDir,'dir')==0
               error('%s is not a valid block directory.',tankObj.RecDir);
            end
         end
         
         %% INITIALIZE TANK OBJECT
         if ~tankObj.init
            error('Could not initialize TANK object.');
         end
         
      end
      
      function addAnimal(tankObj,AnimalFolder)
         %% ADDANIMAL   Method to add animal to nigeLab.Tank Animals property
          if nargin<2
              AnimalFolder=[];
          end
          if isempty(AnimalFolder)
            AnimalFolder = uigetdir(tankObj.RecDir,...
                                   'Select animal folder');
            if AnimalFolder == 0
               error('No animal selected. Object not created.');
            end
         else
            if exist(AnimalFolder,'dir')==0
               error('%s is not a valid block directory.',AnimalFolder);
            end
         end
          
         newAnimal= nigeLab.Animal('RecDir',AnimalFolder,...
             'TankLoc',tankObj.Paths.SaveLoc);
         tankObj.Animals = [tankObj.Animals newAnimal];
      end
      
      function save(tankObj)
         %% SAVE  Method to save a nigeLab.Tank class object
          A=tankObj.Animals;
          for ii=1:numel(A)
              A(ii).save;
          end
         save(fullfile([tankObj.Paths.SaveLoc '_Tank.mat']),'tankObj','-v7');
         tankObj.Animals = A;

      end
      
      function tankObj = saveobj(tankObj)
         tankObj.Animals = [];         
      end
      
      function Status = getStatus(tankObj,operation)
         if nargin <2
            tmp = tankObj.list;
            Status = tmp.Status;
         else
            if ~iscell(operation),operation={operation};end
            for aa =1:numel(tankObj.Animals)
               tmp =  tankObj.Animals(aa).getStatus(operation);
               if numel(operation)==1,tmp=all(tmp,2);end
               Status(aa,:) = all(tmp,1);
            end
         end
      end
      
      % Extraction methods
      flag = doRawExtraction(tankObj)  % Extract raw data from all Animals/Blocks
      flag = doReReference(tankObj)    % Do CAR on all Animals/Blocks
      flag = doLFPExtraction(tankObj)  % Do LFP extraction on all Animals/Blocks
      flag = doSD(tankObj)             % Do spike detection on all Animals/Blocks
      
      % Utility
      linkToData(tankObj)
      blockList = list(tankObj)       % List Blocks in TANK
%       out = tankGet(tankObj,prop)     % Get a specific TANK property
%       flag = tankSet(tankObj,prop)    % Set a specific TANK property      
      flag = updatePaths(tankObj,SaveLoc)
      N = getNumBlocks(tankObj) % Get the total number of blocks in TANK
      runFun(tankObj,f) % Run function f on all child blocks in tank
      
   end
   %% PRIVATE METHODS
   methods (Access = public, Hidden = true)
      flag = init(tankObj)                 % Initializes the TANK object.
      flag = genPaths(animalObj,tankPath) % Generate paths property struct
      flag = findCorrectPath(animalObj,paths)   % Find correct Animal path
      flag = getSaveLocation(animalObj,saveLoc) % Prompt to set save dir

%       ClusterConvert(tankObj)
%       LocalConvert(tankObj)
%       SlowConvert(tankObj)
      clearSpace(tankObj,ask)   % Clear space in all Animals/Blocks
   end

   methods (Static)
      function tankObj = loadobj(tankObj)
         BL = dir(fullfile(tankObj.Paths.SaveLoc,'*_Animal.mat'));
         load(fullfile(BL(1).folder,BL(1).name),'animalObj');
            tankObj.Animals = animalObj;
         for ii=2:numel(BL)
            load(fullfile(BL(ii).folder,BL(ii).name),'animalObj');
            tankObj.Animals(ii) = animalObj;
         end
      end
      
      
   end
   
end