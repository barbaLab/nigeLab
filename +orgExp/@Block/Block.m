classdef Block < handle
   %% BLOCK    Creates datastore for an electrophysiology recording.
   %
   %  blockObj = BLOCK;
   %  blockObj = BLOCK('NAME','VALUE',...);
   %
   %  ex:
   %  blockObj = BLOCK('DIR','P:\Your\Recording\Directory\Here');
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
   %                blockObj.Graphics.Spikes.Build.
   %
   %     Status - Completion status for each element of BLOCK/FIELDS.
   %
   %     Channels - List of channels from board, from probe, and masking.
   %
   %  BLOCK Methods:
   %     Block - Class constructor. Call as blockObj = BLOCK(varargin)
   %
   %     updateID - Update the File or Folder ID for a particular Field, which
   %                is listed in blockObj.Fields. Call as
   %                blockObj.UpdateID(name,type,value); name is the name of the
   %                field, type is the ID type ('File' or 'Folder'), and value
   %                is the new ID. For example:
   %                blockObj.UpdateID('Spikes','Folder','pca-PT_Spikes') would
   %                change where the BLOCK finds its spikes files.
   %
   %     updateContents - Using current information for File and Folder ID
   %                      string identifiers, update the list of files
   %                      associated with a particular information field.
   %
   %     plotWaves -    Make a preview of the filtered waveform for all
   %                    channels, and include any sorted, clustered, or
   %                    detected spikes for those channels as highlighted
   %                    marks at the appropriate time stamp.
   %
   %     plotSpikes -   Display all spikes for a particular channel as a
   %                    SPIKEIMAGE object.
   %
   %     loadSpikes -   Call as x = blockObj.LoadSpikes(channel) to load spikes
   %                    file contents to the structure x.
   %
   %     loadClusters - Call as x = blockObj.LoadClusters(channel) to load
   %                    class file contents to the structure x.
   %
   %     loadSorted -   Call as x = blockObj.LoadSorted(channel) to load class file
   %                    contents to the structure x.
   %
   %     set - Set a specific property of the BLOCK object.
   %
   %     get - Get a specific property of the BLOCK object.
   %
   % By: Max Murphy  v1.0  06/13/2018  Original version (R2017b)
   
   %% PUBLIC PROPERTIES
   
   properties (Access = public)
      Name
      Recording_date
      Recording_time
      Recording_ID
   end
   
   properties (Access = public)
      DACChannels
      ADCChannels
      DigInChannels
      DigOutChannels
      Verbose = true; % Whether to report list of files and fields.
      Channels    % list of channels with various metadata and recording
      % data inside it.
      %
      % [ [ might actually be a better idea to create a
      %     special channel class? ] ]
      
      % Graphics - Graphical objects associated with BLOCK object.
      % -> Spikes : SPIKEIMAGE object. Once constructed, can
      %             call as blockObj.Graphics.Spikes.Build to
      %             recreate the spikes figure.
      % -> Waves : AXES object. Destroyed when figure is
      %            closed.
      Graphics    % Graphical objects associated with block
   end
   
   properties (SetAccess = private)
      
      Sample_rate
      Time
      File_extension   % Intan TDT or other
      RecType
      
      numChannels       = 0
      numProbes         = 0
      numADCchannels    = 0
      numDACChannels    = 0
      numDigInChannels  = 0
      numDigOutChannels = 0
   end
   
   properties (SetAccess = immutable,GetAccess = private)
      dcAmpDataSaved
      Date
      Month
      Day
   end
   
   
   %% PRIVATE PROPERTIES
   properties (SetAccess = private,GetAccess = public)
      Fields      % List of property field names
      SD_pars
      Filt_pars
      LFP_pars
      Corresponding_animal
      RecFile       % Raw binary recording file
      SaveLoc       % Saving path for extracted/processed data
      SaveFormat    % saving format (MatFile,HDF5,dat, current: "Hybrid")
      Downsampled_rate % Rate for down-sampling LFP data
      
      Samples
      
      
      Mask  % Whether to include channels or not
   end
   
   properties (Access = private)
      Status      % Completion status for each element of BLOCK/FIELDS
      paths       % Detailed paths specifications for all the saved files
      Notes       % Notes from text file
   end
   
   %% METHODS
   methods (Access = public)
      function blockObj = Block(varargin)
         %% BLOCK Create a datastore object based on CPL data structure
         %
         %  blockObj = BLOCK;
         %  blockObj = BLOCK('NAME',Value,...);
         %
         %  ex:
         %  blockObj = BLOCK('RecLoc','P:\Your\Block\Directory\Here');
         %
         %  List of 'NAME', Value input argument pairs:
         %
         %  -> 'RecLoc' : (def: none) Specify as string with full directory of
         %              recording BLOCK. Specifying this will skip the UI
         %              selection portion, so it's useful if you are
         %              looping the expression.
         %
         %  -> 'Verbose' : (def: true) Setting this to false suppresses
         %                  output list of files and folders associated
         %                  with the CPL_BLOCK object during
         %                  initialization.
         %
         %
         %  -> 'MASK' : (def: []) If specified, use as a nChannels x 1
         %              logical vector of true/false for channels to
         %              include/exclude.
         %
         %  -> 'REMAP' : (def: []) If specified, use as a nChannels x 1
         %               double vector of channel mappings.
         %
         % By: Max Murphy  v1.0  08/25/2017
         %     F. Barban   v2.0  11/2018
         
         %% PARSE VARARGIN
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue;
            end
            P = properties(blockObj);
            Prop = P{ismember(upper(P), upper( deblank( varargin{iV+1}))) };
            if isempty(Prop)
               continue;
            end
            blockObj.(Prop) = varargin{iV+1};
         end
         
         %% LOOK FOR BLOCK DIRECTORY
         [pars,~] = orgExp.defaults.Block;
         if isempty(blockObj.RecFile)
            [file,path]= uigetfile(fullfile(pars.RecLocDefault,'*.*'),...
               'Select recording BLOCK');
            blockObj.RecFile = fullfile(path,file);
            if blockObj.RecFile == 0

               error('No block selected. Object not created.');
            end
         else
            if exist(blockObj.RecFile,'file')==0
               error('%s is not a valid block file.',blockObj.RecFile);
            end
         end
         
         %% INITIALIZE BLOCK OBJECT
         blockObj.init();
         
      end
      
      function save(blockObj)
         save(blockObj.SaveLoc,'blockObj');
      end
      
      function disp(blockObj)
         if blockObj.Verbose
            builtin('disp',blockObj);
         end
      end
      
      function varargout=subsref(blockObj,S)
          Out = 'blockObj';
          ii=1;
          while ii<=numel(S)
              switch S(ii).type
                  case '()'
                      if ii==1
                          nargs=numel(S(ii).subs);
                          if nargs<2
                              error('Not enough input arguments');
                          end
                          for jj=3:nargs
                              ind=numel(S)+1;
                             S(ind).subs{1}=S(ii).subs{jj};
                             S(ind).type = '()';
                          end
                          Shrt = orgExp.defaults.Shortcuts();
                          if ischar( S(ii).subs{1} )
                              longCommand = sprintf(Shrt{strcmp(Shrt(:,1),S(ii).subs{1}),2},S(ii).subs{2});
                          elseif isnumeric( S(ii).subs{1} )
                              longCommand = sprintf(Shrt{S(ii).subs{1},2},S(ii).subs{2});
                          end
                          Out = sprintf('%s.%s',Out,longCommand);
                      else
                          Out = sprintf('%s(S(%d).subs{:})',Out,ii);
                      end
                  case '.'
                      Out = sprintf('%s.(S(%d).subs)',Out,ii);
                  otherwise
              end
              ii=ii+1;
          end
          Out = eval(Out);
          varargout = {Out};
      end
      
      % Methods for data processing:
      doRawExtraction(blockObj)  % Extract raw data to Matlab BLOCK
      qExtraction(blockObj)      % Queue extraction to Isilon
      doUnitFilter(blockObj)     % Apply multi-unit activity bandpass filter
      qUnitFilter(blockObj)      % Queue filter to Isilon
      doReReference(blockObj)    % Do virtual common-average re-reference
      qReReference(blockObj)     % Queue CAR to Isilon
      doSpikeDetection(blockObj) % Do spike detection for extracellular field
      qSD(blockObj)              % Queue SD to Isilon
      doLFPExtraction(blockObj)  % Extract LFP decimated streams
      qLFPExtraction(blockObj)   % Queue LFP decimation to Isilon
      
      % Methods for data analysis:
      [tf_map,times_in_ms] = analyzeERS(blockObj,options) % Event-related synchronization (ERS)
      analyzeLFPSyncIndex(blockObj)                       % LFP synchronization index
      
      % Methods for data visualization:
      flag = plotWaves(blockObj,WAV,SPK)  % Plot stream snippets
      flag = plotSpikes(blockObj,ch)      % Show spike clusters for a single channel
      
      % Methods for quickly accessing data [deprecated?]:
      out = loadSpikes(blockObj,ch)       % Load spikes for a given channel
      out = loadClusters(blockObj,ch)     % Load clusters file for a given channel
      out = loadSorted(blockObj,ch)       % Load sorting file for a given channel
      L = list(blockObj) % List of current associated files for field or fields
      
      
      
      
   end
   methods (Access = public, Hidden = true)
      % Other utility methods:
      updateNotes(blockObj,str) % Update notes for a recording
      varargout = blockGet(blockObj,prop) % Get a specific BLOCK property
      flag = blockSet(blockObj,prop,val)  % Set a specific BLOCK property
      flag = setSaveLocation(blockObj,saveLoc)
      RHD2Block(blockObj)
      RHS2Block(blockObj)
      linkToData(blockObj)
      genPaths(blockObj)
      operations = updateStatus(blockObj,operation,value)
      Status = getStatus(blockObj,stage)
      
      flag = clearSpace(blockObj,ask)  % Clear space on disk
      
      updateID(blockObj,name,type,value)  % Update the file or folder identifier
      updateContents(blockObj,fieldname)  % Update files for specific field
      takeNotes(blockObj)                 % View or update notes on current recording
   end
   
   %% PRIVATE METHODS
   methods (Access = 'private') % debugging purpose, is private
      init(blockObj) % Initializes the BLOCK object
      
   end
end