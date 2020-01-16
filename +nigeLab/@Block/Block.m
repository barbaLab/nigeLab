classdef Block < nigeLab.nigelObj
   % BLOCK    Creates datastore for an electrophysiology recording.
   %
   %  blockObj = nigeLab.Block();
   %     --> select Block path information from UI
   %  blockObj = nigeLab.Block(blockPath);
   %     --> blockPath can be set as [] or char array with location
   %  blockObj = nigeLab.Block(blockPath,animalPath);
   %     --> animalPath can be [] or char array with location
   %  blockObj = nigeLab.Block(__,'PropName1',propVal1,...);
   %     --> allows specification of properties in constructor
   %
   %  ex:
   %  blockObj = nigeLab.Block([],'P:\Your\Recording\Directory\Here');
   %
   %  BLOCK Properties:
   %     Name - Name of recording BLOCK.
   %
   %     Animal - "Parent" nigeLab.Animal object
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
   %     Empty - Create an Empty BLOCK object or array
   
   % % % PROPERTIES % % % % % % % % % %   
   % HIDDEN,TRANSIENT,PUBLIC
   properties (Hidden,Transient,Access=public)
      CurrentJob                % parallel.job.MJSCommunicatingJob
   end
   
   % PUBLIC
   properties (Access=public)
      Channels struct                        % Struct array of neurophysiological stream data
      Events   struct                        % Struct array of asynchronous events
      Streams  struct                        % Struct array of non-electrode data streams
      Videos                                 % Array of nigeLab.libs.VideosFieldType
   end
   
   % RESTRICTED:nigelObj/PUBLIC
   properties (GetAccess = public,SetAccess = ?nigeLab.nigelObj)
      FileType    cell=nigeLab.nigelObj.Default('FileType','Block')  % Indicates DiskData file type for each Field
      Mask {logical,double}% Vector of indices of included elements of Channels
      Notes       struct   % Notes from text file
      Probes      struct  % Probe configurations associated with saved recording
      RMS         table   % RMS noise table for different waveforms
      SampleRate  double   % Recording sample rate
      Samples     double   % Total number of samples in original record
      Scoring     struct   % Metadata about any scoring done
      Status      struct   % Completion status for each element of BLOCK/FIELDS
      Time        char     % Points to Time File
   end
   
   % RESTRICTED:nigelObj
   properties (Access=?nigeLab.nigelObj)
      MultiAnimals = 0      % Flag for many animals contained in one block
      % Handles ad hoc workflows
      MatFileWorkflow struct = nigeLab.Block.Default('MatFileWorkflow');   
      %                           Struct with fields below:
      %                            --> ReadFcn     function handle to external
      %                                            matfile header loading function
      %                            --> ConvertFcn  function handle to "convert"
      %                                            old (pre-extracted) blocks to
      %                                            nigeLab format
      %                            --> ExtractFcn  function handle to use for
      %                                            'do' extraction methods
      %                             --> Pars   struct with misc. loaded
      %                                        parameters. Must include:
      %                                         * .NumChannels
   end
   
   % TRANSIENT,RESTRICTED:nigelObj
   properties (Transient,Access=?nigeLab.nigelObj)
      MultiAnimalsLinkedBlocks nigeLab.Block  % Pointer to blocks from same recording
   end
   % % % % % % % % % % END PROPERTIES %
   
   % % % METHODS% % % % % % % % % % % %
   % NO ATTRIBUTES (overloaded methods)
   methods
      % BLOCK class constructor
      function blockObj = Block(blockPath,blockSavePath,varargin)
         % BLOCK    Creates datastore for an electrophysiology recording.
         %
         %  blockObj = nigeLab.Block();
         %     --> select Block path information from UI
         %  blockObj = nigeLab.Block(blockPath);
         %     --> blockPath can be set as [] or char array with location
         %  blockObj = nigeLab.Block(blockPath,animalPath);
         %     --> blockSavePath can be [] or char array with location
         %        where block will be saved ( the folder containing the
         %        block folder hierarchy )
         %  blockObj = nigeLab.Block(__,'PropName1',propVal1,...);
         %     --> allows specification of properties in constructor
         %  blockObj = nigeLab.Block(__,'$ParsField.ParamName',paramVal);
         %     --> sets value of blockObj.Pars.(ParsField).(ParamName)
         %           equal to paramVal by default.
         %
         %  ex:
         %  blockObj = nigeLab.Block([],'P:\Your\Rec\Directory\Here');
         
         if nargin < 1
            blockPath = '';
         end
         if nargin < 2
            blockSavePath = '';
         end
         blockObj@nigeLab.nigelObj('Block',blockPath,blockSavePath,varargin{:}); 
         if isempty(blockObj) % Handle empty init case
            return;
         end
         if isstruct(blockPath) % Handle loadobj case
            return;
         end
         blockObj.addPropListeners();
         if ~blockObj.init()
            error(['nigeLab:' mfilename ':BadInit'],...
               'Block object construction unsuccessful.');
         end
      end

      % Overloaded NUMARGUMENTSFROMSUBSCRIPT method for parsing indexing.
      function n = numArgumentsFromSubscript(blockObj,s,indexingContext)
         % NUMARGUMENTSFROMSUBSCRIPT  Parse # args based on subscript type
         %
         %  n = blockObj.numArgumentsFromSubscript(s,indexingContext);
         %
         %  s  --  struct from SUBSTRUCT method for indexing
         %  indexingContext  --  matlab.mixin.util.IndexingContext Context
         %                       in which the result applies.
         
         dot = strcmp({s(1:min(length(s),2)).type}, '.');
         if sum(dot) < 2
            isValidForArgsOut = ...
               (indexingContext == matlab.mixin.util.IndexingContext.Statement) || ...
               (indexingContext == matlab.mixin.util.IndexingContext.Expression);
            if  isValidForArgsOut &&...
                  any(dot) && any(strcmp(s(dot).subs,methods(blockObj)))
               
               mc = metaclass(blockObj);
               calledmethod=(strcmp(s(dot).subs,{mc.MethodList.Name}));
               n = numel(mc.MethodList(calledmethod).OutputNames);
            else
               n = builtin('numArgumentsFromSubscript',...
                  blockObj,s,indexingContext);
            end
         else
            n = builtin('numArgumentsFromSubscript',...
               blockObj,s,indexingContext);
         end
      end     
   end
   
   % PROTECTED
   methods (Access=protected)
      % Modify inherited superclass name parsing method
      function [name,meta] = parseNamingMetadata(blockObj,fName,pars)
         %PARSENAMINGMETADATA  Parse metadata from file or folder name
         %
         %  name = PARSENAMINGMETADATA(obj);
         %
         %  --------
         %   INPUTS
         %  --------
         %     obj      :     nigeLab.Block class object
         %
         %   fName      :     (char array) Full filename of Input
         %
         %    pars      :     Pars struct with following fields:
         %                    --> 'VarExprDelimiter' (splits fName into 
         %                          chunks used for parsing variables)
         %                    --> 'DynamicVarExp' (char regular expression
         %                          that uses IncludeChar and ExcludeChar
         %                          to get the dynamic variable tokens to
         %                          keep or exclude)
         %                    --> 'IncludeChar' (char indicating you keep
         %                          that dynamically parsed variable)
         %                    --> 'ExcludeChar' (char indicating to discard
         %                          that dynamically parsed variable)
         %                    --> 'SpecialMeta' (struct containing a "list"
         %                          field, 'SpecialVars', which is a cell
         %                          array of other fieldnames. These are
         %                          all structs with the fields 'vars' and
         %                          'cat', which indicate which variables
         %                          should be stuck together and what
         %                          character to stick them together with)
         %                    --> 'NamingConvention' (cell array of char
         %                          arrays indicating how the parsed
         %                          dynamic variables should be stuck back
         %                          together in order to create Block name)
         %                    --> 'Concatenater' char used to concatenate
         %                          elements indicated by NamingConvention
         %
         %  --------
         %   OUTPUT
         %  --------
         %    name         :     Name of the obj
         %
         %    meta         :     Metadata struct parsed from name
         
         if nargin < 2
            fName = blockObj.RecFile;
         end
         
         if nargin < 3
            pars = blockObj.getParams('Block');
            if isempty(pars)
               blockObj.updateParams('Block');
               pars = blockObj.Pars.Block;
            end
         end
         
         if isdir(fName)
            fName = blockObj.Input;
         end
         
         % Make sure that 'AnimalID' and 'RecID' are in SpecialMeta
         if isfield(pars.SpecialMeta,'SpecialVars')
            pars.SpecialMeta.SpecialVars = union(...
               pars.SpecialMeta.SpecialVars,{'AnimalID','RecID'});  
         else
            pars = nigeLab.defaults.Block;
            pars.SpecialMeta.SpecialVars = union(...
               pars.SpecialMeta.SpecialVars,{'AnimalID','RecID'});
         end
         
         % % % % Run supermethod@superclass % % % % %
         [name,meta] = parseNamingMetadata@nigeLab.nigelObj(...
            blockObj,fName,pars);
         
         % % % % Parse additional parameters for BLOCK % % % % 
         
         % If RecordingDate isn't one of the specified "template" 
         % variables from .Pars.(obj.Type).NamingConvention property, then 
         % parse it from Year, Month, and Day (meta variables). 
         % This will be helpful for handling file names for TDT recording 
         % blocks, which don't automatically append RecDate and RecTime
         f = fieldnames(meta);
         if sum(ismember(f,{'RecDate'})) < 1
            if isfield(meta,'Year') && ...
                  isfield(meta,'Month') && ...
                  isfield(meta,'Day')
               YY = meta.Year((end-1):end);
               MM = meta.Month;
               DD = sprintf('%.2d',str2double(meta.Day));
               meta.RecDate = [YY MM DD];
            else
               meta.RecDate = 'YYMMDD';
               nigeLab.utils.cprintf('UnterminatedStrings',...
                  'Unable to parse date from %s name (%s).\n',...
                  upper(obj.Type),fName);
            end
         end
         % Also needs `RecTime` for DashBoard
         if ~isfield(meta,'RecTime')
            meta.RecTime = 'hhmmss';
         end
         % Also needs `RecTime` for DashBoard
         if ~isfield(meta,'RecTime')
            meta.RecTime = 'hhmmss';
         end
         % Get `FileExt` if it was parsed
         blockObj.FileExt = meta.FileExt;

      end
   end
   
   % SEALED,PUBLIC
   methods (Sealed,Access=public)
% Start Deprecated % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%       setProp(blockObj,varargin) % Set property for all blocks in array
%       --> Deprecated (inherited from `nigelObj`)
%       [blockObj,idx] = findByKey(blockObjArray,keyStr,keyType); % Find block from block array based on public or private hash
%       --> Deprecated (inherited from `nigelObj`)
%       flag = updatePaths(blockObj,SaveLoc)     % updates the path tree and moves all the files
%       --> Deprecated (inherited from `nigelObj`)
%       [flag,p] = updateParams(blockObj,paramType,forceFromDefaults) % Update parameters
%       --> Deprecated (inherited from `nigelObj`)
%       fieldIdx = checkCompatibility(blockObj,requiredFields) % Checks if this block is compatible with required field names
%       --> Deprecated (inherited from `nigelObj`)
%       flag = checkParallelCompatibility(blockObj,isUpdated) % Check if parallel can be run
%       --> Deprecated (inherited from `nigelObj`)
%       flag = linkToData(blockObj,suppressWarning) % Link to existing data
%       --> Deprecated (inherited from `nigelObj`) 
% % % % % % % % % % % % % % % % % % % % % % % % % % End Deprecated % % % %

      % "Property" methods:
      N = NumChannels(blockObj); % Returns number of recording channels (electrode sites) used in Block
      N = NumProbes(blockObj);   % Returns number of electrode arrays (probes) used in Block
      C = ChannelID(blockObj);   % Returns [NumChannels x 2] array of [.Channels.probe, .Channels.chNum]

      % Scoring videos:
      fig = scoreVideo(blockObj) % Score videos manually to get behavioral alignment points
      fig = alignVideoManual(blockObj,digStreams,vidStreams); % Manually obtain alignment offset between video and digital records
      offset = guessVidStreamAlignment(blockObj,digStreamInfo,vidStreamInfo);
      addScoringMetadata(blockObj,fieldName,info); % Add scoring metadata to table for tracking scoring on a video for example
      info = getScoringMetadata(blockObj,fieldName,hashID); % Retrieve row of metadata scoring
      
      % Methods for data extraction:
      checkActionIsValid(blockObj,nDBstackSkip);  % Throw error if appropriate processing not yet complete
      flag = doRawExtraction(blockObj)  % Extract raw data to Matlab BLOCK
      flag = doEventDetection(blockObj,behaviorData,vidOffset) % Detect "Trials" for candidate behavioral Events
      flag = doEventHeaderExtraction(blockObj,behaviorData,vidOffset)  % Create "Header" for behavioral Events
      flag = doUnitFilter(blockObj)     % Apply multi-unit activity bandpass filter
      flag = doReReference(blockObj)    % Do virtual common-average re-reference
      flag = doSD(blockObj)             % Do spike detection for extracellular field
      flag = doLFPExtraction(blockObj)  % Extract LFP decimated streams
      flag = doVidInfoExtraction(blockObj,vidFileName) % Get video information
      flag = doBehaviorSync(blockObj)      % Get sync from neural data for external triggers
      flag = doVidSyncExtraction(blockObj) % Get sync info from video
      flag = doAutoClustering(blockObj,chan,unit) % Do automatic spike clustiring
      
      % Methods for streams info
      stream = getStream(blockObj,streamName,source,scaleOpts); % Returns stream data corresponding to streamName
      
      % Methods for parsing channel info
      flag = parseProbeNumbers(blockObj) % Get numeric probe identifier
      flag = setChannelMask(blockObj,includedChannelIndices) % Set "mask" to look at
      
      % Methods for parsing spike info:
      tagIdx = parseSpikeTagIdx(blockObj,tagArray) % Get tag ID vector
      ts = getSpikeTimes(blockObj,ch,class)    % Get spike times (sec)
      idx = getSpikeTrain(blockObj,ch,class)   % Get spike sample indices
      spikes = getSpikes(blockObj,ch,class,type)   % Get spike waveforms
      features = getSpikeFeatures(blockObj,ch,class) % Get extracted features
      sortIdx = getSort(blockObj,ch,suppress)  % Get spike sorted classes
      clusIdx = getClus(blockObj,ch,suppress)  % Get spike cluster classes
      [tag,str] = getTag(blockObj,ch)          % Get spike sorted tags
      flag = saveChannelSpikingEvents(blockObj,ch,spk,feat,art) % Save spikes for a channel
      flag = checkSpikeFile(blockObj,ch) % Check a spike file for compatibility
      
      % Method for accessing event info:
      idx = getEventsIndex(blockObj,field,eventName);
      [data,blockIdx] = getEventData(blockObj,field,prop,ch,matchValue,matchField) % Retrieve event data
      flag = setEventData(blockObj,fieldName,eventName,propName,value,rowIdx,colIdx);
      
      % Computational methods:
      [tf_map,times_in_ms] = analyzeERS(blockObj,options) % Event-related synchronization (ERS)
      analyzeLFPSyncIndex(blockObj)  % LFP synchronization index
      rms_out = analyzeRMS(blockObj,type,sampleIndices)  % Compute RMS for channels
      
      % Methods for visualizing data:
      flag = plotWaves(blockObj)          % Plot stream snippets
      flag = plotSpikes(blockObj,ch)      % Show spike clusters for a single channel
      flag = plotOverlay(blockObj)        % Plot overlay of values on skull
      
      % Methods for associating/displaying info about blocks:
      L = list(blockObj,keyIdx) % List of current associated files for field or fields
      flag = updateVidInfo(blockObj) % Update video info
      flag = linkField(blockObj,fieldIndex)     % Link field to data
      flag = linkChannelsField(blockObj,field,fType)  % Link Channels field data
      flag = linkEventsField(blockObj,field)    % Link Events field data
      flag = linkStreamsField(blockObj,field)   % Link Streams field data
      flag = linkVideosField(blockObj,field)    % Link Videos field data
      flag = linkTime(blockObj)     % Link Time stream
      flag = linkNotes(blockObj)    % Link notes metadata
      flag = linkProbe(blockObj)    % Link probe metadata
      
      % Methods for storing & parsing metadata:
      h = takeNotes(blockObj)             % View or update notes on current recording
      parseNotes(blockObj,str)            % Update notes for a recording
      header = parseHeader(blockObj,fid)  % Parse header depending on structure
      
      % Methods for parsing Fields info:
      fileType = getFileType(blockObj,field) % Get file type corresponding to field
      [fieldType,n] = getFieldType(blockObj,field) % Get type corresponding to field
      [fieldIdx,n] = getFieldTypeIndex(blockObj,fieldType) % Get index of all fields of a given type
      [fieldIdx,n] = getStreamsFieldIndex(blockObj,field,type) % Get index into Streams for a given Field
      notifyStatus(blockObj,field,status,channel) % Triggers event notification to blockObj
      opOut = updateStatus(blockObj,operation,value,channel) % Indicate completion of phase
      status = getStatus(blockObj,operation,channel)  % Retrieve task/phase status
      
      % Miscellaneous utilities:
      N = getNumBlocks(blockObj) % This is just to make it easier to count total # blocks
      str = reportProgress(blockObj,str_expr,pct,notification_mode,tag_str) % Update the user of progress
      checkMask(blockObj) % Just to double-check that empty channels are masked appropriately
      idx = matchProbeChannel(blockObj,channel,probe); % Match Channels struct index to channel/probe combo
   end
   
   % HIDDEN,PUBLIC
   methods (Hidden,Access=public)
% Start Deprecated % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%       flag = genPaths(blockObj,tankPath,useRemote) % Generate paths property struct
%       --> Deprecated (inherited from `nigelObj`)
%       flag = getSaveLocation(blockObj,saveLoc) % Prompt to set save dir
%       --> Deprecated (inherited from `nigelObj`)
%       paths = getFolderTree(blockObj,paths,useRemote) % returns a populated path struct
%       --> Deprecated (inherited from `nigelObj`)
%       [name,meta] = parseNamingMetadata(blockObj); % Get metadata struct from recording name
%       --> Deprecated (inherited from `nigelObj`)
%       parseRecType(blockObj)              % Parse the recording type
%       --> Deprecated (inherited from `nigelObj`)
% % % % % % % % % % % % % % % % % % % % % % % % % % End Deprecated % % % %

      flag = intan2Block(blockObj,fields,paths) % Convert Intan to BLOCK
      flag = tdt2Block(blockObj) % Convert TDT to BLOCK
      flag = rhd2Block(blockObj,recFile,saveLoc) % Convert *.rhd to BLOCK
      flag = rhs2Block(blockObj,recFile,saveLoc) % Convert *.rhs to BLOCK
      flag = init(blockObj) % Initializes the BLOCK object
      flag = initChannels(blockObj,header);   % Initialize Channels property
      flag = initEvents(blockObj);     % Initialize Events property
      flag = initStreams(blockObj,header);    % Initialize Streams property
      flag = initVideos(blockObj);     % Initialize Videos property
      masterIdx = matchChannelID(blockObj,masterID); % Match unique channel ID
      header = parseHierarchy(blockObj)   % Parse header from file hierarchy
      blocks = splitMultiAnimals(blockObj,varargin)  % splits block with multiple animals in it
   end
   
   % HIDDEN,PRIVATE
   methods (Hidden,Access=private)
      eventData = getStreamsEventData(blockObj,field,prop,eventName,matchProp,matchValue)
      eventData = getChannelsEventData(blockObj,field,prop,ch,matchProp,matchValue)
   end
   
   % STATIC,PUBLIC
   methods (Static,Access=public)
      % Overloaded method to instantiate "Empty" Blocks from constructor
      function blockObj = Empty(n)
         % EMPTY  Creates "empty" block or block array
         %
         %  blockObj = nigeLab.Block.Empty();  % Makes a scalar
         %  blockObj = nigeLab.Block.Empty(n); % Make n-element array Block
         
         if nargin < 1
            n = [0, 0];
         else
            n = nanmax(n,0);
            if isscalar(n)
               n = [0, n];
            end
         end
         
         blockObj = nigeLab.Block(n);
      end
   end
   
   % STATIC,SEALED,PUBLIC
   methods (Static,Sealed,Access=public)
      field = getOperationField(operation); % Get field associated with operation
      blockObj = loadRemote(targetBlockFile); % Load block on remote worker
   end
   % % % % % % % % % % END METHODS% % %
end