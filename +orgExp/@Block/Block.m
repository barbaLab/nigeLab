classdef Block < handle
%% BLOCK    Creates datastore for an electrophysiology recording.
%
%  obj = BLOCK;
%  obj = BLOCK('NAME','VALUE',...);
%
%  ex: 
%  obj = BLOCK('DIR','P:\Your\Recording\Directory\Here');
%
%  BLOCK Properties:
%     Name - Name of recording BLOCK.
%
%     Fields - List of property field names that may have files associated
%              with them.
%
%     Graphics - Graphics objects that are associated with BLOCK
%                object. Currently contains Spikes subfield, which is a
%                SPIKEIMAGE object that is available after calling the
%                PLOTSPIKES method. The Waves subfield is only available
%                after calling the PLOTWAVES method. To recall the
%                SPIKEIMAGE object once it has been constructed, call as
%                obj.Graphics.Spikes.Build.
%
%  BLOCK Methods:
%     Block - Class constructor. Call as obj = BLOCK(varargin)
%
%     UpdateID - Update the File or Folder ID for a particular Field, which
%                is listed in obj.Fields. Call as
%                obj.UpdateID(name,type,value); name is the name of the
%                field, type is the ID type ('File' or 'Folder'), and value
%                is the new ID. For example:
%                obj.UpdateID('Spikes','Folder','pca-PT_Spikes') would
%                change where the BLOCK finds its spikes files.
%
%     UpdateContents - Using current information for File and Folder ID
%                      string identifiers, update the list of files
%                      associated with a particular information field.
%
%     PlotWaves -    Make a preview of the filtered waveform for all 
%                    channels, and include any sorted, clustered, or 
%                    detected spikes for those channels as highlighted 
%                    marks at the appropriate time stamp.
%
%     PlotSpikes -   Display all spikes for a particular channel as a
%                    SPIKEIMAGE object.
%
%     LoadSpikes -   Call as x = obj.LoadSpikes(channel) to load spikes
%                    file contents to the structure x.
%
%     LoadClusters - Call as x = obj.LoadClusters(channel) to load 
%                    class file contents to the structure x.
%
%     LoadSorted -   Call as x = obj.LoadSorted(channel) to load class file
%                    contents to the structure x.
%
% By: Max Murphy  v1.0  06/13/2018  Original version (R2017b)

%% PUBLIC PROPERTIES
   properties (Access = public)
      Name        % Base name of block
      
      Fields      % List of property field names
      
      % Graphics - Graphical objects associated with BLOCK object.
      % -> Spikes : SPIKEIMAGE object. Once constructed, can
      %             call as obj.Graphics.Spikes.Build to
      %             recreate the spikes figure.
      % -> Waves : AXES object. Destroyed when figure is
      %            closed.
      Graphics    % Graphical objects associated with block
      
      Status      % Completion status for each element of BLOCK/FIELDS
      
      Channels    % List of channels from board, from probe, and masking.
   end

%% PRIVATE PROPERTIES
   properties (Access = private)
      DIR         % Full directory of block
      Raw         % Raw Data files
      Filt        % Filtered files
      CAR         % CAR-filtered files
      DS          % Downsampled files
      Spikes      % Spike detection files
      Clusters    % Unsupervised clustering files
      Sorted      % Sorted spike files
      MEM         % LFP spectra files
      Digital     % "Digital" (extra) input files
      ID          % Identifier structure for different elements
      Notes       % Notes from text file
   end
   
   properties(Access = private)
      DEF = 'P:/Rat'; % Default for UI BLOCK selection
      CH_ID = 'Ch';   % Channel index ID
      CH_FIELDWIDTH = 3; % Number of characters in channel number 
                         % (example: Example_Raw_Ch_001.mat would be 3)
      VERBOSE = true; % Whether to report list of files and fields.
      MASK  % Whether to include channels or not
      REMAP % Mapping of channel numbers to actual numbers on probe
   end
   
   methods (Access = public)
      function obj = Block(varargin)
         %% BLOCK Create a datastore object based on CPL data structure
         %
         %  obj = BLOCK;
         %  obj = BLOCK('NAME',Value,...);
         %
         %  ex: 
         %  obj = BLOCK('DIR','P:\Your\Block\Directory\Here');
         %
         %  List of 'NAME', Value input argument pairs:
         %
         %  -> 'DIR' : (def: none) Specify as string with full directory of
         %              recording BLOCK. Specifying this will skip the UI
         %              selection portion, so it's useful if you are
         %              looping the expression.
         %
         %  -> 'VERBOSE' : (def: true) Setting this to false suppresses
         %                  output list of files and folders associated
         %                  with the CPL_BLOCK object during
         %                  initialization.
         %
         %  -> 'DEF' : (def: 'P:/Rat') If you are using the UI selection
         %              interface a lot, and typically working with a more
         %              specific project directory, you can specify this to
         %              change where the default UI selection directory
         %              starts. Alternatively, just change the property in
         %              the code under private properties.
         %
         %  -> 'CH_ID' : (def: 'Ch') If you have a different file name
         %               identifier that precedes the channel number for
         %               that particular file, specify this on object
         %               construction.
         %
         %               ex: 
         %               obj.List('Raw')
         %               
         %               Current Raw files stored in [obj.Name]:
         %               -> Example_Raw_Chan_001.mat
         %
         %               In this case, you would specify 'Chan' during
         %               construction of obj:
         %               obj = Block('CH_ID','Chan');
         %
         %  -> 'CH_FIELDWIDTH' : (def: 3) Number of characters in the
         %                        channel number in the file name.
         %
         %  -> 'MASK' : (def: []) If specified, use as a nChannels x 1
         %              logical vector of true/false for channels to
         %              include/exclude.
         %
         %  -> 'REMAP' : (def: []) If specified, use as a nChannels x 1
         %               double vector of channel mappings.
         %
         % By: Max Murphy  v1.0  08/25/2017
         
         %% PARSE VARARGIN
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue
            end
            p = findprop(obj,varargin{iV});
            if isempty(p)
               continue
            end
            obj.(varargin{iV}) = varargin{iV+1};
         end
         
         %% LOOK FOR BLOCK DIRECTORY
         if isempty(obj.DIR)
            obj.DIR = uigetdir(obj.DEF,'Select recording BLOCK');
            if obj.DIR == 0
               error('No block selected. Object not created.');
            end
         else
            if exist(obj.DIR,'dir')==0
               error('%s is not a valid block directory.',obj.DIR);
            end
         end
         
         %% CONSTRUCT BLOCK OBJECT
         obj.Init;
         
      end
      
      UpdateID(obj,name,type,value) % Update the file or folder identifier
      List(obj,name) % List of current associated files for field or fields
      PlotWaves(obj,WAV,SPK) % Plot stream snippets
      PlotSpikes(obj,ch) % Show spike clusters for a single channel
      out = LoadSpikes(obj,ch) % Load spikes for a given channel
      out = LoadClusters(obj,ch) % Load clusters file for a given channel
      out = LoadSorted(obj,ch) % Load sorting file for a given channel
      UpdateContents(obj,fieldname) % Update files for specific field
      TakeNotes(obj) % View or update notes on current recording
      
   end
   
   methods (Access = public, Hidden = true)
      UpdateNotes(obj,str) % Update notes for a recording
   end
   
   methods (Access = 'private')
      Init(obj) % Initializes the BLOCK object
   end
end