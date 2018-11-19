classdef Animal < handle
%% Animal object 

%% PUBLIC PROPERTIES
   properties (Access = public)
      Name         % Animal identification code
      ElecConfig   %Electrode configuration structure
      RecType      % Intan TDT or other
     
   end
   
   properties (Access = public) %debugging purpose, is private
      DIR         % directory with raw binary data in intan format
      Blocks       % Children (BLOCK)
      SaveLoc
      ExtractFlag
      DEF = 'P:/Rat'
   end
%% PUBLIC METHODS
   methods (Access = public)
      function animalObj = Animal(varargin)
         %% Creates an animal object with the related Blocks

         
         %% LOAD DEFAULT ID SETTINGS
         animalObj = def_params(animalObj);
         
         %% PARSE VARARGIN
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue
            end
            p = findprop(animalObj,varargin{iV});
            if isempty(p)
               continue
            end
            animalObj.(varargin{iV}) = varargin{iV+1};
         end
         
         %% LOOK FOR ANIMAL DIRECTORY
         if isempty(animalObj.DIR)
            animalObj.DIR = uigetdir(animalObj.DEF,'Select directory with the the recordings');
            if animalObj.DIR == 0
               error('No animal selected. Object not created.');
            end
         else
            if exist(animalObj.DIR,'dir')==0
               error('%s is not a valid block directory.',animalObj.DIR);
            end
         end
         
         %% INITIALIZE ANIMAL OBJECT
         animalObj.init;
         
      end
      
      function addBlock(animalObj,BlockPath)

         newBlock= orgExp.Block('PATH',BlockPath,...
             'SaveLoc',animalObj.SaveLoc);
         animalObj.Blocks = [animalObj.Blocks newBlock];
      end
      
      function save(animalObj)
          B=animalObj.Blocks;
          for ii=1:numel(B)
              B(ii).save;
          end
          save(animalObj.SaveLoc,'animalObj');
      end
      
%       updateID(blockObj,name,type,value)    % Update the file or folder identifier
      table = list(animalObj)         % List of recordings currently associated with the animal
      updateContents(blockObj,fieldname)    % Update files for specific field
      out = animalGet(animalObj,prop)       % Get a specific BLOCK property
      flag = animalSet(animalObj,prop)      % Set a specific BLOCK property
      convert(animalObj)                % Convert raw data to Matlab BLOCK
      filterData(animalObj)
      CAR(animalObj)
      linkToData(animalObj)
      extractLFP(animalObj)
      mergeBlocks(animalObj,ind)
      removeBlocks(animalObj,ind)
      spikeDetection(animalObj)
      freeSpace(animalObj,ask)
   end
   
   methods (Access = public, Hidden = true)
      updateNotes(blockObj,str) % Update notes for a recording
   end

%% PRIVATE METHODS
   methods (Access = 'private')
      init(animalObj) % Initializes the ANIMAL object
      def_params(animalObj)
   end
end