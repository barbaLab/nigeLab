classdef Block < handle
   %% BLOCK    Creates datastore for an electrophysiology recording.
   %
   %  blockObj = BLOCK();
   %  blockObj = BLOCK('NAME','VALUE',...);
   %
   %  ex:
   %  blockObj = BLOCK('DIR','P:\Your\Recording\Directory\Here');
   %
   %  BLOCK Properties:
   %     Name - Name of recording BLOCK.
   %
   %     Graphics - Struct that contains pointers to graphics files.
   %
   %     Status - Completion status for each element of BLOCK/FIELDS.
   %
   %     Channels - Struct that contains data fields.
   %                 -> blockObj.Channels(7).Raw(1:10) First 10 samples of
   %                                                    channel 7 from the
   %                                                    raw waveform.
   %                 -> blockObj.Channels(1).Spikes.peak_train  Spike
   %                                                           peak_train
   %                                                           for chan 1.
   %
   %     Meta - Struct containing metadata info about recording BLOCK.
   %
   %  BLOCK Methods:
   %     Block - Class constructor. Call as blockObj = BLOCK(varargin)
   %
   %     doRawExtraction - Convert from raw data binaries to BLOCK format.
   %
   %     doUnitFilter - Apply bandpass filter for unit activity.
   %
   %     doReReference - Apply common average re-reference for de-noising.
   %
   %     doSD - Run spike detection and feature extraction.
   %
   %     doLFPExtraction - Use cascaded lowpass filter to decimate raw data
   %                       to a rate more suitable for LFP analyses.
   %
   %     doVidInfoExtraction - Get video metadata if there are related
   %                           behavioral videos associated with a
   %                           recording.
   %
   %     doVidSyncExtraction - Get time-series of "digital HIGH" times
   %                           based on detection of ON/OFF state of a
   %                           video element, such as a flashing LED.
   %
   %     doBehaviorSync - Get synchronization signal from digital inputs.
   %
   %     plotWaves -    Make a preview of the filtered waveform for all
   %                    channels, and include any sorted, clustered, or
   %                    detected spikes for those channels as highlighted
   %                    marks at the appropriate time stamp.
   %
   %     plotSpikes -   Display all spikes for a particular channel as a
   %                    SPIKEIMAGE object.
   %
   %     linkToData - Link block object to existing data structure.
   %
   %     clearSpace - Remove extracted RAW data, and extracted FILTERED
   %                  data if CAR channels are present.
   %
   %     analyzeRMS - Get RMS for all channels of a desired type of stream.
   %
   % Started by: Max Murphy  v1.0  06/13/2018  Original version (R2017b)
   % Expanded by: MAECI 2018 collaboration (Federico Barban & Max Murphy)
   
   %% PROPERTIES
   
   properties (SetAccess = public, GetAccess = public)
      Name  % Name of the recording block
      Meta  % Metadata about the recording

      Channels   % Struct array of neurophysiological stream data
      Events     % Struct array of asynchronous events
      Streams    % Struct array of non-electrode data streams
      
      Graphics   % Struct for associated graphics objects
      
      Pars
   end
   
   properties (SetAccess = public, Hidden = true)
      UserData % Allow UserData property to exist
   end
   
   properties (SetAccess = private, GetAccess = public)
      SampleRate  % Recording sample rate
      Samples     % Total number of samples in original record
      Time        % Points to Time File
      
      RMS         % RMS noise table for different waveforms
      Fields      % List of property field names
      
      Mask        % Vector of indices of included elements of Channels
      
      NumProbes         = 0   % Number of electrode arrays
      NumChannels       = 0   % Number of electrodes on all arrays
      
      
      Status      % Completion status for each element of BLOCK/FIELDS
      Paths       % Detailed paths specifications for all the saved files
      Probes      % Probe configurations associated with saved recording
      Notes       % Notes from text file
      
      RecType     % Intan / TDT / other
      FileExt     % .rhd, .rhs, or other
   end
   
   properties (SetAccess = private, GetAccess = public, Hidden = true)
      Date              % Date of recording
      Month             % Month of recording
      Day               % Day of recording
      
      FieldType         % Indicates types for each element of Field
      FileType          % Indicates DiskData file type for each Field
      
      NumADCchannels    = 0   % Number of ADC channels
      NumDACChannels    = 0   % Number of DAC channels
      NumDigInChannels  = 0   % Number of digital input channels
      NumDigOutChannels = 0   % Number of digital output channels
      NumAnalogIO
      NumDigIO
      
      BlockPars         % Parameters struct for block construction
      EventPars         % Parameters struct for events
      ExperimentPars    % Parameters struct for experimental notes
      FiltPars          % Parameters struct for unit bandpass filter
      LFPPars           % Parameters struct for LFP extraction & analyses
      PlotPars          % Parameters struct for graphical plots
      ProbePars         % Parameters struct for parsing probe layout info
      QueuePars         % Parameters struct for queueing jobs to server
      SDPars            % Parameters struct for spike detection
      SortPars          % Parameters for nigeLab.Sort interface
      SPCPars           % Parameters for super paramagnetic clustreing
      SyncPars          % Parameters struct for digital sync stream
      TDTPars           % Parameters struct for parsing TDT info
      VideoPars         % Parameters struct for associating videos
      
      RecFile       % Raw binary recording file
      AnimalLoc     % Saving path for extracted/processed data
      SaveFormat    % saving format (MatFile,HDF5,dat, current: "Hybrid")
   end
  
   properties (SetAccess = private, GetAccess = private)      
      ForceSaveLoc      % Flag to force make non-existent directory      
      RecLocDefault     % Default location of raw binary recording
      AnimalLocDefault  % Default location of BLOCK
      ChannelID         % Unique channel ID for BLOCK
      Verbose = true;   % Whether to report list of files and fields.
      
      Delimiter        % Delimiter for name metadata for dynamic variables
      DynamicVarExp    % Expression for parsing BLOCK names from raw file
      IncludeChar      % Character indicating included name elements
      DiscardChar      % Character indicating discarded name elements
      NamingConvention % How to parse dynamic name variables for Block
      DCAmpDataSaved    % Flag indicating whether DC amplifier data saved
   end
   
   events
      channelCompleteEvent
      processCompleteEvent
   end
   
   %% METHODS
   methods (Access = public)
      % Overloaded methods:
      function blockObj = Block(varargin)
         %% BLOCK Create a datastore object based on CPL data structure
         %
         %  blockObj = BLOCK;
         %  blockObj = BLOCK('NAME',Value,...);
         %
         % By: Max Murphy  v1.0  08/25/2017
         %     F. Barban   v2.0  11/2018
         
         %% PARSE VARARGIN
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue;
            end
            % Check to see if it matches any of the listed properties
            if isprop(blockObj,varargin{iV})
               blockObj.(varargin{iV}) = varargin{iV+1};
            end            
         end
         
         %% LOAD DEFAULT BLOCK PARAMETERS
         [pars,blockObj.Fields] = nigeLab.defaults.Block;
         allNames = fieldnames(pars);
         allNames = reshape(allNames,1,numel(allNames));
         for name_ = allNames
            % Check to see if it matches any of the listed properties
            if isprop(blockObj,name_{:})
               blockObj.(name_{:}) = pars.(name_{:});
            end
         end
         
         %% LOOK FOR BLOCK DIRECTORY
         if isempty(blockObj.RecFile)
            [file,path]= uigetfile(fullfile(blockObj.RecLocDefault,'*.*'),...
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
         if ~blockObj.init()
            error('Block object construction unsuccessful.');
         end
         
      end
      function save(blockObj)
         %% SAVE  Overload save of BLOCK
         save(fullfile([blockObj.Paths.SaveLoc.dir '_Block.mat']),'blockObj','-v7');
      end
%       function disp(blockObj)
%          %% DISP  Overload display of BLOCK contents
%          if any([blockObj.Verbose])
%             builtin('disp',blockObj);
%          end
%       end    
      function varargout = subsref(blockObj,s)
         %% SUBSREF  Overload indexing operators for BLOCK
         switch s(1).type
            case '.'

               [varargout{1:nargout}] = builtin('subsref',blockObj,s);

               
            case '()'
               if isscalar(blockObj) && ~isnumeric(s(1).subs{1})
                  s(1).subs=[{1} s(1).subs];
               end
               if length(s) == 1                  
                  nargsi=numel(s(1).subs);
                  nargo = 1;
                  
                  if nargsi > 0
                  Out = sprintf('blockObj(%d)',s.subs{1});
                  end
                  if nargsi > 1
                  end
                  if nargsi > 2
                     Shrt = nigeLab.defaults.Shortcuts();
                     
                     if ischar( s(1).subs{2} )
                        longCommand = sprintf(Shrt{strcmp(Shrt(:,1),s(1).subs{2}),2},s(1).subs{3});
                     
                     elseif isnumeric( s(1).subs{1} )
                        longCommand = sprintf(Shrt{s(1).subs{1},2},s(1).subs{2});
                     end
                     
                     Out = sprintf('%s.%s',Out,longCommand);
                     indx = ':';
                     
                     if nargsi > 3
                        indx = sprintf('[%s]',num2str(s(1).subs{4}));                        
                     end
                     Out = sprintf('%s(%s)',Out,indx);
                  end
                  
                  [varargout{1:nargo}] = eval(Out);
                  
                  
%                elseif length(s) == 2 && strcmp(s(2).type,'.')
%                % Implement obj(ind).PropertyName
%                ...
%                elseif length(s) == 3 && strcmp(s(2).type,'.') && strcmp(s(3).type,'()')
%                % Implement obj(indices).PropertyName(indices)
%                ...
               else
               % Use built-in for any other expression
               [varargout{1:nargout}] = builtin('subsref',blockObj,s);
               end
            case '{}'
              warning('{} indexing not supported')
            otherwise
               error('Not a valid indexing expression')
         end
      end
      function n = numArgumentsFromSubscript(blockObj,s,indexingContext)
         %% NUMARGUMENTSFROMSUBSCRIPT  Parse # args based on subscript type
         dot = strcmp({s(1:min(length(s),2)).type}, '.');
         if sum(dot) < 2
            if indexingContext == matlab.mixin.util.IndexingContext.Statement &&...
                  any(dot) && any(strcmp(s(dot).subs,methods(blockObj)))

               mc = metaclass(blockObj);
               calledmethod=(strcmp(s(dot).subs,{mc.MethodList.Name}));
               n = numel(mc.MethodList(calledmethod).OutputNames);
            else
               n = builtin('numArgumentsFromSubscript',blockObj,s,indexingContext);
            end
         else
            n = builtin('numArgumentsFromSubscript',blockObj,s,indexingContext);
         end
      end
      
      % Methods for data extraction:
      flag = doRawExtraction(blockObj)  % Extract raw data to Matlab BLOCK
      flag = doUnitFilter(blockObj)     % Apply multi-unit activity bandpass filter
      flag = doReReference(blockObj)    % Do virtual common-average re-reference
      flag = doSD(blockObj)             % Do spike detection for extracellular field
      flag = doLFPExtraction(blockObj)  % Extract LFP decimated streams
      flag = doVidInfoExtraction(blockObj,vidFileName) % Get video information
      flag = doBehaviorSync(blockObj)      % Get sync from neural data for external triggers
      flag = doVidSyncExtraction(blockObj) % Get sync info from video
      flag = doAutoClustering(blockObj,chan,unit) % Do automatic spike clustiring
      
      % Methods for parsing channel info
      flag = parseProbeNumbers(blockObj) % Get numeric probe identifier
      flag = setChannelMask(blockObj,includedChannelIndices) % Set "mask" to look at
      
      % Methods for parsing spike info:
      tagIdx = parseSpikeTagIdx(blockObj,tagArray); % Get tag ID vector
      ts = getSpikeTimes(blockObj,ch,class);    % Get spike times (sec)
      idx = getSpikeTrain(blockObj,ch,class);   % Get spike sample indices
      spikes = getSpikes(blockObj,ch,class,type);    % Get spike waveforms
      sortIdx = getSort(blockObj,ch,suppress);  % Get spike sorted classes
      clusIdx = getClus(blockObj,ch,suppress);  % Get spike cluster classes
      [tag,str] = getTag(blockObj,ch);          % Get spike sorted tags
      flag = saveChannelSpikingEvents(blockObj,ch,spk,feat,art); % Save spikes for a channel
      flag = checkSpikeFile(blockObj,ch); % Check a spike file for compatibility
      
      % Method for getting event info:
      [data,blockIdx] = getEventData(blockObj,type,field,ch,matchValue,matchField) % Retrieve event data
      
      % Computational methods:
      [tf_map,times_in_ms] = analyzeERS(blockObj,options) % Event-related synchronization (ERS)
      analyzeLFPSyncIndex(blockObj)  % LFP synchronization index
      rms_out = analyzeRMS(blockObj,type,sampleIndices)  % Compute RMS for channels
      
      % Methods for producing graphics:
      flag = plotWaves(blockObj)          % Plot stream snippets
      flag = plotSpikes(blockObj,ch)      % Show spike clusters for a single channel
      flag = plotOverlay(blockObj)        % Plot overlay of values on skull
      
      % Methods for associating/displaying info about blocks:
      L = list(blockObj) % List of current associated files for field or fields
      flag = updateVidInfo(blockObj) % Update video info
      flag = linkToData(blockObj,suppressWarning) % Link to existing data
      flag = linkField(blockObj,fieldIndex)     % Link field to data
      flag = linkChannelsField(blockObj,field,fType)  % Link Channels field data
      flag = linkEventsField(blockObj,field)    % Link Events field data
      flag = linkStreamsField(blockObj,field)   % Link Streams field data
      flag = linkTime(blockObj);     % Link Time stream
      flag = linkNotes(blockObj);    % Link notes metadata
      flag = linkProbe(blockObj);    % Link probe metadata
      
      flag = linkRaw(blockObj);  % Link raw data
      flag = linkFilt(blockObj); % Link filtered data
      flag = linkStim(blockObj); % Link stimulation data
      flag = linkLFP(blockObj);  % Link LFP data
      flag = linkCAR(blockObj);  % Link CAR data
      flag = linkSpikes(blockObj);   % Link Spikes data
      flag = linkClusters(blockObj); % Link Clusters data
      flag = linkSorted(blockObj);   % Link Sorted data
      flag = linkADC(blockObj);      % Link ADC data
      flag = linkDAC(blockObj);      % Link DAC data
      flag = linkDigIO(blockObj);    % Link Digital-In and Digital-Out data
      
      % Methods for storing & parsing metadata:
      h = takeNotes(blockObj)             % View or update notes on current recording
      parseNotes(blockObj,str)            % Update notes for a recording
      
      % Methods for parsing Fields info:
      fType = getFieldType(blockObj,field); % Get file type corresponding to field
      opOut = updateStatus(blockObj,operation,value,channel) % Indicate completion of phase
      status = getStatus(blockObj,operation,channel)  % Retrieve task/phase status
      
      % Miscellaneous utilities:
      N = getNumBlocks(blockObj); % This is just to make it easier to count total # blocks
   
   end
   
   methods (Access = public, Hidden = true) % Can make things PRIVATE later
      flag = intan2Block(blockObj,fields,paths) % Convert Intan to BLOCK
      flag = tdt2Block(blockObj) % Convert TDT to BLOCK
      
      flag = rhd2Block(blockObj,recFile,saveLoc) % Convert *.rhd to BLOCK
      flag = rhs2Block(blockObj,recFile,saveLoc) % Convert *.rhs to BLOCK
      
      flag = genPaths(blockObj,tankPath) % Generate paths property struct
      flag = findCorrectPath(blockObj,paths)   % Find correct Animal path
      flag = getSaveLocation(blockObj,saveLoc) % Prompt to set save dir
      paths = getFolderTree(blockObj,paths)     % returns a populated path struct
      
      clearSpace(blockObj,ask,usrchoice)     % Clear space on disk      

      flag = init(blockObj) % Initializes the BLOCK object
      flag = initChannels(blockObj);   % Initialize Channels property
      flag = initEvents(blockObj);     % Initialize Events property 
      flag = initStreams(blockObj);    % Initialize Streams property
      
      meta = parseNamingMetadata(blockObj); % Get metadata struct from recording name
      channelID = parseChannelID(blockObj); % Get unique ID for a channel
      masterIdx = matchChannelID(blockObj,masterID); % Match unique channel ID
   end
end