classdef Block < nigeLab.nigelObj
   % BLOCK    Object containing all data for a single experimental recording.
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
   
   % HIDDEN,TRANSIENT,DEPENDENT,PUBLIC
   properties (Dependent,Access=public)
      ChannelID            double   % [NumChannels x 2] array of channel and probe numbers
      NumChannels (1,1)    double   % Total number of channels 
      NumProbes   (1,1)    double   % Total number of Probes
      Shortcut             struct   % nigeLab.defaults.Shortcuts() output (transient)
      Trial                double   % Timestamp list of trials
%       Time
   end
   
   % PUBLIC
   properties (GetAccess=public,SetAccess=?nigeLab.nigelObj)
      Channels struct                        % Struct array of neurophysiological stream data
      Events   struct = repmat(struct('Ts',[],'Tag',[],'Name',[],'Duration',[],...
                                'Data',[],'Trial',[]),0,1);                        % Struct array of asynchronous events
      Streams  struct                        % Struct array of non-electrode data streams
      Cameras                                % Array of nigeLab.libs.nigelCamera
   end
   
   % RESTRICTED:nigelObj/PUBLIC
   properties (GetAccess = public,SetAccess=?nigeLab.nigelObj)
      FileType       cell  =  nigeLab.nigelObj.Default('FileType','Block')  % Indicates DiskData file type for each Field
      Mask           {logical,double}        % Vector of indices of included elements of Channels
      TrialMask      {logical,double}        % Logical vector of masking for trials (if applicable)
      Notes          struct                  % Notes from text file
      Probes         struct                  % Probe configurations associated with saved recording
      Paths          struct                  % Struct containing all paths for data
      RMS            table                   % RMS noise table for different waveforms
      SampleRate     double                  % Recording sample rate
      Samples        double                  % Total number of samples in original record
      Scoring (1,1)  struct                  % Metadata about any scoring done
      Status  (1,1)  struct                  % Completion status for each element of BLOCK/FIELDS
   end
   
   % RESTRICTED:nigelObj
   properties (Access=?nigeLab.nigelObj)
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
   
   % TRANSIENT,PROTECTED
   properties (Transient,Access=protected)
      ChannelID_        % (Transient) store for .ChannelID property
      NumChannels_      % (Transient) store for .NumChannels property
      NumProbes_        % (Transient) store for .NumProbes property
      Shortcut_         % (Transient) store for .Shortcut property
      TrialField_       % (Transient) store for .TrialField property
      VideoHeader_      % (Transient) store for .VideoHeader property
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
         blockObj.Key = nigeLab.nigelObj.InitKey;
      end
      
      % % % (DEPENDENT) GET/SET.PROPERTY METHODS % % % % % % % % % % % %
      % [DEPENDENT] Returns .ChannelID property
      function value = get.ChannelID(blockObj)
         %GET.CHANNELID  Returns .ChannelID property
         %
         %  value = get(blockObj,'ChannelID');
         %  --> Returns [NumChannels x 2] array of [probe, channel]
         %      numeric ID (e.g. 1 2 corresponds to probe 1 channel 2)
         
         if ~isempty(blockObj.ChannelID_)
            value = blockObj.ChannelID_;
            return;
         end
         
         value = zeros(0,2);
         if isempty(blockObj.Channels)
            return;
         end
         
         % Get Probe index of each recording channel
         probeNum = [blockObj.Channels.probe].';
         if numel(probeNum) < blockObj.NumChannels
            % Parse and check that parsing worked
            if ~blockObj.parseProbeNumbers  
               return;
            else
               probeNum = [blockObj.Channels.probe].';
            end
         end
         
         % Get index of each channel within a probe
         channelNum = [blockObj.Channels.chNum].'; % Parsed with .probe
         
         % Combine into output matrix
         value = [probeNum, channelNum];
         blockObj.ChannelID_ = value;
      end
      function set.ChannelID(obj,value)
         % Does nothing
         obj.ChannelID_ = value;
      end
           
      % [DEPENDENT] Returns .NumChannels property
      function value = get.NumChannels(blockObj)
         %GET.NUMCHANNELS  Returns total number of Channels
         %
         %  value = get(blockObj,'NumChannels');
         %  --> Returns number of elements in .Channels array
         if isempty(blockObj.NumChannels_)
            value = numel(blockObj.Channels);
            blockObj.NumChannels_ = value;
         else
            value = blockObj.NumChannels_;
         end
      end
      function set.NumChannels(blockObj,value)
         % Does nothing
         blockObj.NumChannels_ = value;
      end
      
      % [DEPENDENT] Returns .NumProbes property
      function value = get.NumProbes(blockObj)
         %GET.NUMPROBES  Returns total number of Probes
         %
         %  value = get(blockObj,'NumProbes');
         %  --> Returns number of probes
         
         if ~isempty(blockObj.NumProbes_)
            value = blockObj.NumProbes_;
            return;
         end
         
         value = 0;
         switch blockObj.RecType
            case {'Intan','TDT','nigelBlock'}
               C = blockObj.ChannelID;
               value = numel(unique(C(:,1)));
            case 'Matfile'
               value = blockObj.MatFileWorkflow.Pars.NumProbes;
             case ''
                 value = 0;
            otherwise
               error(['nigeLab:' mfilename ':UnsupportedRecType'],...
                  '''%s'' is not a supported RecType.',blockObj.RecType);
         end
         blockObj.NumProbes_ = value;
      end
      function set.NumProbes(blockObj,value)
         %SET.NUMPROBES  Assigns .NumProbes property
         blockObj.NumProbes_ = value;
      end
      
      % [DEPENDENT] Returns .Shortcut property
      function value = get.Shortcut(blockObj)
         %GET.SHORTCUT  Returns .Shortcut_
         if isempty(blockObj.Shortcut_)
            blockObj.Shortcut_ = nigeLab.defaults.Shortcuts();
         end
         value = blockObj.Shortcut_;
      end
      function set.Shortcut(blockObj,value)
         %SET.SHORTCUT  Assigns .Shortcut (nigeLab.defaults.Shortcuts())
         %
         %  set(blockObj,'Shortcut',value);
         blockObj.Shortcut_ = value;
      end
      
      % [DEPENDENT] Returns .Trial property
      function value = get.Trial(blockObj)
         %GET.TRIAL  Returns .Trial property
         %
         %  value = get(blockObj,'Trial');
         %  --> Returns vector of time stamps of trial onsets
         
         if isempty(blockObj.Events)
            value = [];
            return;
         end
         TrialStrt = [blockObj.Events(strcmp({blockObj.Events.Name},blockObj.Pars.Event.Trial.Fields{1})).Ts];
         TrialEnd  = [blockObj.Events(strcmp({blockObj.Events.Name},blockObj.Pars.Event.Trial.Fields{2})).Ts];
         idx = (TrialEnd - TrialStrt) > blockObj.Pars.Event.Trial.MinDistance;
         value = [TrialStrt(idx)' TrialEnd(idx)'];
      end
      function set.Trial(~,~)
          error(['You cannot set manually the Trial field.' newline 'Please add relevant events to the Event structure.']);
      end
      
%       % [DEPENDENT] Returns .Time property
%       function value = get.Time(blockObj)
%           if isfield(blockObj.Meta,'Time')
%             value = blockObj.Meta.Time;
%           else
%               nigeLab.utils.cprintf('Error','The Meta field');
%               nigeLab.utils.cprintf('*Error','Time');
%               nigeLab.utils.cprintf('Error',['is not present.\n' ...
%                   'It might have never been extracted or is not correctly linked.'...
%                   'Please use <a href="matlab:help nigeLab.Block.linkToData">blockObj.linkToData(''Time'')</a>'...
%                   ' or consider rerunning <a href="matlab:help nigeLab.Block.doRawExtraction">blockObj.doRawExtraction</a>\n']);
%           end
%       end
%       function set.Time(~,~)
%         mess = ['Error setting the Block property Time.\n' ...
%             'Please use <a href="matlab:help nigeLab.Block.linkToData">blockObj.linkToData(''Time'')</a>'...
%             ' or consider rerunning <a href="matlab:help nigeLab.Block.doRawExtraction">blockObj.doRawExtraction</a>\n'];
%         nigeLab.utils.cprintf('Error',mess);
%       end
      % % % % % % % % % % END (DEPENDENT) GET/SET.PROPERTY METHODS % % %

      % Overloaded method to get 'end' indexing
      function ind = end(obj,k,n)
          if n>2
              % called by {}
              warning(['nigeLab:' mfilename 'unsupportedOperator'],...
                  '""end"" operator not supported in this context.\nThis may lead to unexpexted behavior.');
              ind = builtin('end',obj,k,n);
          else
              ind = builtin('end',obj,k,n);
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
         switch indexingContext
             case 'Statement'
                 if numel(s)==1 && strcmpi(s.type,'{}') 
                         n = 1;
                         return;
                 elseif numel(s)>1 && strcmpi(s(1).type,'{}') 
                     % illegal, error handling is offloaded tu subsref
                     n = 1;
                     return;
                 else
%                      n = numel(blockObj);
               n = builtin('numArgumentsFromSubscript',...
                     blockObj,s,indexingContext);
                 end
             otherwise
                 n = builtin('numArgumentsFromSubscript',...
                     blockObj,s,indexingContext);
         end

%          dot = strcmp({s(1:min(length(s),2)).type}, '.');
%          if sum(dot) < 2
%             isValidForArgsOut = ...
%                (indexingContext == matlab.mixin.util.IndexingContext.Statement) || ...
%                (indexingContext == matlab.mixin.util.IndexingContext.Expression);
%             if  isValidForArgsOut &&...
%                   any(dot) && any(strcmp(s(dot).subs,methods(blockObj)))
%                
%                mc = metaclass(blockObj);
%                calledmethod=(strcmp(s(dot).subs,{mc.MethodList.Name}));
%                n = numel(mc.MethodList(calledmethod).OutputNames);
%             else
%                n = builtin('numArgumentsFromSubscript',...
%                   blockObj,s,indexingContext);
%             end
%          else
%             n = builtin('numArgumentsFromSubscript',...
%                blockObj,s,indexingContext);
%          end
      end
   end
   
   % SEALED,PUBLIC
   methods (Sealed,Access=public)
      % Returns colormaps for different things
      function C = getColorMap(obj,type,N)
         %GETCOLORMAP  Returns colormaps for different things
         %
         %  C = getColorMap(obj,type,N);
         %
         %  obj  : nigelObj object
         %
         %  type : 'Trial' or 'EventTimes' or 'Meta' etc. (case-based)
         %     * If not specified, 'Trial' is the default
         %
         %  N    : Number of colormap rows to return
         %     * If not specified, depends on 'type' argument
         
         if nargin < 2
            type = 'Trial';
         end
         
         switch type
            case 'Trial'
               if nargin < 3
                  N = numel(obj.Trial);
               end
               C = nigeLab.utils.cubehelix(max(N,1),0.25,N/5,...
                  3.0,0.6,[0.3 0.7],[0.25 0.75]);
            case 'EventTimes'
               if nargin < 3
                  N = sum(obj.Pars.Video.VarType == 1);
               end
               C = nigeLab.utils.cubehelix(N,2.0,1.5,...
                  3.0,0.6,[0.3 0.7],[0.25 0.75]);
            case 'Meta'
               if nargin < 3
                  N = sum(obj.Pars.Video.VarType > 1);
               end
               C = nigeLab.utils.cubehelix(N,1.0,1.5,...
                  3.0,0.6,[0.3 0.7],[0.25 0.75]);
         end
      end
   end
   
   % PROTECTED
   methods (Access=protected)
      % Modify inherited superclass name parsing method
      function meta = parseNamingMetadata(blockObj,fName,pars)
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
            fName = blockObj.Input;
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
               pars.SpecialMeta.SpecialVars,{'AnimalID','BlockID'});  
         else
            pars = nigeLab.defaults.Block;
            pars.SpecialMeta.SpecialVars = union(...
               pars.SpecialMeta.SpecialVars,{'AnimalID','BlockID'});
         end
         
         % % % % Run supermethod@superclass % % % % %
         meta = parseNamingMetadata@nigeLab.nigelObj(...
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
               if blockObj.Verbose
                  [fmt,idt] = getDescriptiveFormatting(blockObj);
                  nigeLab.utils.cprintf('Errors*','%s[BLOCK/PARSE]: ',idt);
                  nigeLab.utils.cprintf(fmt,...
                     'Unable to parse date from %s name (%s).\n',...
                     upper(obj.Type),fName);
               end
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
         blockObj.Meta = nigeLab.nigelObj.MergeStructs(blockObj.Meta,meta);
      end
      
      % Modify inherited ID file saving method
      function flag = saveIDFile(blockObj)
         %SAVEIDFILE  Save small folder identifier file
         %
         %  flag = blockObj.saveIDFile();
         %  --> Returns true if save was successful
         %
         %  Adds the following fields to .nigelBlock file via `propList`:
         %     * 'FileExt'
         %     * 'RecType'
         %     * 'RecFile'
         %     * 'HasVideoTrials'
         
         BLOCK_PROPS = {'FileExt', 'RecType', 'Input'};
         flag = saveIDFile@nigeLab.nigelObj(blockObj,BLOCK_PROPS);
         if ~flag
            % Missing RecFile or IDFile
            return;
         end
         
      end
   end
  
   % PUBLIC
   methods (Access=public)

      % Methods for data extraction:
      sig  = execStimSuppression(blockObj,nChan)          % removes stimulation pulses from raw signal and returns a cleaned one
      flag = checkActionIsValid(blockObj,nDBstackSkip);     % Throw error if appropriate processing not yet complete
      flag = doAutoClustering(blockObj,chan,unit,useSort)   % Do automatic spike clustiring
      flag = doBehaviorSync(blockObj)                       % Get sync from neural data for external triggers
      flag = doEventDetection(blockObj,behaviorData,vidOffset,forceHeaderExtraction)         % Detect "Trials" for candidate behavioral Events
      flag = doLFPExtraction(blockObj)       % Extract LFP decimated streams
      flag = doRawExtraction(blockObj)       % Extract raw data to Matlab BLOCK
      flag = doReReference(blockObj)         % Do virtual common-average re-reference
      flag = doSD(blockObj)                  % Do spike detection for extracellular field
      flag = doUnitFilter(blockObj)          % Apply multi-unit activity bandpass filter

      % Methods for streams info
      stream = getStream(blockObj,streamName,scaleOpts); % Returns stream data corresponding to streamName
      
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
      [idx,field] = getEventsIndex(blockObj,field,eventName); % Returns index to Events field as well as name of Events.(field)
      [data,blockIdx] = getEventData(blockObj,field,prop,ch,matchValue,matchField) % Retrieve event data
      [flag,idx] = setEventData(blockObj,fieldName,eventName,propName,value,rowIdx,colIdx);
      function flag = addEvent(obj,thisEvent)
      %%    Adds events to the Event struct. It also takes care of 
      %     harmonizing the struct fields and returns an error if some 
      %     required fields are not present
          if ~isscalar(thisEvent)
              flag = addEvent(obj,thisEvent(1)) & addEvent(obj,thisEvent(2:end));
              return;
          end
          switch class(thisEvent)
              case 'struct'
                  ... nothing to see here
              case 'nigeLab.evt.evtChanged'
                  thisEvent = thisEvent.toStruct;
          end
          evtFields = fieldnames(obj.Events);
          str = strjoin(evtFields,', ');
          if ~isstruct(thisEvent)
              error('Events needs to be structures with the fields: %s',str);
          end
          thisFields = fieldnames(thisEvent);
          if ~all(ismember(evtFields,thisFields))
              error('Events needs to be structures with the fields: %s',str);
          end
          fToRemove = setdiff(thisFields,evtFields);
          obj.Events = [obj.Events rmfield(thisEvent,fToRemove)];
          flag = true;
      end
      function flag = deleteEvent(obj,thisEvent)
          if isempty(thisEvent)
            flag = false;
            return;
          end
          if ~isscalar(thisEvent)
              flag = deleteEvent(obj,thisEvent(1)) & deleteEvent(obj,thisEvent(2:end));
              return;
          end
      %% Removes an event from the struct field.
          switch class(thisEvent)
              case 'struct'
                  ...
              case 'nigeLab.evt.evtChanged'
                  thisEvent = thisEvent.toStruct;
          end
          if isnan(thisEvent.Ts)
              Alltrials = [obj.Events.Trial];
              idx = Alltrials == thisEvent.Trial;
          else
              Alltimes = [obj.Events.Ts];
              idx = Alltimes == thisEvent.Ts;
          end
          if ~any(idx)
              flag = false;
              return;
          end
          idx2 = strcmp([obj.Events(idx).Name],thisEvent.Name);          
          idx(idx) = idx(idx) & idx2;
          obj.Events(idx) = [];
          flag = true;
      end
      function flag = modifyEvent(obj,thisEvent)
          if ~isscalar(thisEvent)
              modifyEvent(obj,thisEvent(2:end));
              thisEvent = thisEvent(1);
          end
      %% Removes an event from the struct field.
          switch class(thisEvent)
              case 'struct'
                  ...
              case 'nigeLab.evt.evtChanged'
                  thisEvent = thisEvent.toStruct;
          end
          % find index of evt to change
          if isnan(thisEvent.Ts)
              Alltrials = [obj.Events.Trial];
              idx = Alltrials == thisEvent.OldEvt.Trial;
          else
              Alltimes = [obj.Events.Ts];
              idx = Alltimes == thisEvent.OldEvt.Time; % OldEvt has Time instead of Ts, super inconvenient but it is what it is
          end
          if ~any(idx)
              return;
          end
          idx2 = strcmp([obj.Events(idx).Name],thisEvent.OldEvt.Name);          
          idx(idx) = idx(idx) & idx2;
          obj.Events(idx) = rmfield(thisEvent,{'OldEvt','Idx'});
          flag = true;
      end
      function evt  = filterEvt(blockObj,varargin)
      % FILTEREVT Returns events filtered on queries given as input.
      % Queries are provided as an arbitrary number of cellarrays
      % containing an arbitrary number of key-values couples. Each
      % additional filter provides an additional layer of selection on the
      % previously filtered event data.
      % Events typically contain the following fields: 
      %     Ts          -> Timestamp in seconds
      %     Name        -> Human readable Event name
      %     Tag         -> Shorter version of Name
      %     Duration    -> Duration in samples of the Event. Usually 1 for
      %                    most events (impulsive events)
      %     Data        -> Additional data if needed (like 1 or 0).
      %     Trial       -> Trial # associated w/ the Event
      %
      % Examples:
      %
      % evt = blockObj.filterEvt({'Name','Success','Data',1},... Filter 1
      %                         {'Name','Grasp'});             % Filter 2
      
          ev = [blockObj.Events];

          for jj=1:(nargin-1)
              thisFilt = varargin{jj};
              ev_ = ev;
              for ii = 1:2:numel(thisFilt)
                  if isempty(ev_)
                      break;
                  end
                  field = thisFilt{ii};
                  val = thisFilt{ii+1};
                  if ischar(val)
                      idx = strcmp([ev_.(field)],val);
                  else
                      if iscell([ev_.(field)])
                          idx = cellfun(@(x) all(x==val),[ev_.(field)]);
                      else
                          idx = arrayfun(@(x) all(x==val),[ev_.(field)]);
                      end
                  end
                  ev_=ev_(idx);
              end
              isLabel = all(isnan([ev_.Ts]));
              if isLabel
                  allTrials = [ev.Trial];
                  theseTrials = [ev_.Trial];
                  idx = ismember(allTrials,theseTrials);
                  ev = ev(idx);
              else
                  ev = ev(idx);
              end
          end

          [~,idx] = sort([ev.Trial]);
          evt = ev(idx);

      end

      % Computational methods:
      [tf_map,times_in_ms] = analyzeERS(blockObj,options) % Event-related synchronization (ERS)
      analyzeLFPSyncIndex(blockObj)  % LFP synchronization index
      rms_out = analyzeRMS(blockObj,type,sampleIndices)  % Compute RMS for channels
      
      % Methods for visualizing data:
      flag = plotWaves(blockObj,ax,field,idx,computeRMS)          % Plot stream snippets
      flag = plotSpikes(blockObj,ch)      % Show spike clusters for a single channel
      flag = plotOverlay(blockObj)        % Plot overlay of values on skull
      
      % Methods for associating/displaying info about blocks:
      L = list(blockObj,keyIdx) % List of current associated files for field or fields
      flag = linkField(blockObj,fieldIndex)     % Link field to data
      flag = linkChannelsField(blockObj,field,fType)  % Link Channels field data
      flag = linkEventsField(blockObj,field)    % Link Events field data
      flag = linkStreamsField(blockObj,field)   % Link Streams field data
      flag = linkVideosField(blockObj,field)    % Link Videos field data
      flag = linkMetaField(blockObj,field)    % Link Videos field data
      flag = linkTime(blockObj)     % Link Time stream
      flag = linkNotes(blockObj)    % Link notes metadata
      flag = linkProbe(blockObj)    % Link probe metadata
      function flag = linkToData(blockObj, suppressWarning)
         flag = false;
         if nargin < 2
             suppressWarning = false;
         end
          % Local function to return folder path
          parseFolder = @(idx) nigeLab.utils.getUNCPath(blockObj.Paths.(blockObj.Fields{idx}).dir);
            % PARSEFOLDER  Local function to return correct folder location
           
         
         switch class(suppressWarning)
            case 'char'
               field = {suppressWarning};
               f = intersect(field,blockObj.Fields);
               if isempty(f)
                  error(['nigeLab:' mfilename ':BadInputChar'],...
                     'Invalid field: %s (%s)',field{:},blockObj.Name);
               end
               field = f;
               suppressWarning = true;
            case 'cell'
               field = suppressWarning;
               f = intersect(field,blockObj.Fields);
               if isempty(f)
                  error(['nigeLab:' mfilename ':BadInputChar'],...
                     'Invalid field: %s (%s)',field{:},blockObj.Name);
               end
               field = f;
               suppressWarning = true;
            case 'logical'
               field = blockObj.Fields;
            otherwise
               error(['nigeLab:' mfilename ':BadInputClass'],...
                  'Unexpected class for ''suppressWarning'': %s',...
                  class(suppressWarning));
         end
         
         % ITERATE ON EACH FIELD AND LINK THE CORRECT DATA TYPE
         N = numel(field);
         warningRef = false(1,N);
         warningFold = false(1,N);
         for ii = 1:N
            fieldIndex = find(ismember(blockObj.Fields,field{ii}),1,'first');
            if isempty(fieldIndex)
               error(['nigeLab:' mfilename ':BadField'],...
                  'Invalid field: %s (%s)',field{ii},blockObj.Name);
            end
            pcur = parseFolder(fieldIndex);
            if exist(pcur,'dir')==0
               warningFold(ii) = true;
            elseif isempty(dir([pcur filesep '*.mat']))
               warningRef(ii) = true;
            else
               warningRef(ii) = linkField(blockObj,fieldIndex);
            end
         end
         
         % GIVE USER WARNINGS
         % Notify user about potential missing folders:
         if any(warningFold)
            warningIdx = find(warningFold);
            nigeLab.utils.cprintf('UnterminatedStrings',...
               'Some folders are missing. \n');
            nigeLab.utils.cprintf('text',...
               '\t-> Rebuilding folder tree ... %.3d%%',0);
            for ii = 1:numel(warningIdx)
               fieldIndex = find(ismember(blockObj.Fields,field{warningIdx(ii)}),...
                  1,'first');
               pcur = parseFolder(fieldIndex);
               [~,~,~] = mkdir(pcur);
               fprintf(1,'\b\b\b\b%.3d%%',round(100*ii/sum(warningFold)));
            end
            fprintf(1,'\n');
         end
         
         % If any element of a given "Field" is missing, warn user that there is a
         % missing data file for that particular "Field":
         if any(warningRef) && ~suppressWarning
            warningIdx = find(warningRef);
            nigeLab.utils.cprintf('UnterminatedStrings',...
               ['Double-check that data files are present. \n' ...
               'Consider re-running doExtraction.\n']);
            for ii = 1:numel(warningIdx)
               nigeLab.utils.cprintf('text',...
                  '\t%s\t-> Could not find all %s data files.\n',...
                  blockObj.Name,field{warningIdx(ii)});
            end
         end
         if strcmp(blockObj.Type,'Block')
            updateStatus(blockObj,'notify'); % Just emits the event in case listeners
         end
         save(blockObj);
         flag = true; 
      
      end
      
      % Methods for storing & parsing metadata:
      h = takeNotes(blockObj)             % View or update notes on current recording
      parseNotes(blockObj,str)            % Update notes for a recording
      header = parseHeader(blockObj,fid)  % Parse header depending on structure
      
      % Methods for parsing Fields info:
      [fieldIdx,n] = getStreamsFieldIndex(blockObj,field,type) % Get index into Streams for a given Field
      notifyStatus(blockObj,field,status,channel) % Triggers event notification to blockObj
      opOut = updateStatus(blockObj,operation,value,channel) % Indicate completion of phase
      status = getStatus(blockObj,operation,channel)  % Retrieve task/phase status
      
      % Miscellaneous utilities:
      N = getNumBlocks(blockObj) % This is just to make it easier to count total # blocks
      str = reportProgress(blockObj,str_expr,pct,notification_mode,tag_str) % Update the user of progress
      checkMask(blockObj) % Just to double-check that empty channels are masked appropriately
      idx = matchProbeChannel(blockObj,channel,probe); % Match Channels struct index to channel/probe combo
      flag = clearSpace(blockObj,ask,Choice);
   end
   
   % HIDDEN,PUBLIC
   methods (Hidden,Access=public)
% Start Deprecated % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%       flag = getSaveLocation(blockObj,saveLoc) % Prompt to set save dir
%       --> Deprecated (inherited from `nigelObj`)
%       paths = getFolderTree(blockObj,paths,useRemote) % returns a populated path struct
%       --> Deprecated (inherited from `nigelObj`)
%       [name,meta] = parseNamingMetadata(blockObj); % Get metadata struct from recording name
%       --> Deprecated (inherited from `nigelObj`)
%       parseRecType(blockObj)              % Parse the recording type
%       --> Deprecated (inherited from `nigelObj`)
% % % % % % % % % % % % % % % % % % % % % % % % % % End Deprecated % % % %
      % Returns `paths` struct from folder tree heirarchy
      function paths = getFolderTree(obj,paths)
         %GETFOLDERTREE  Returns paths struct that parses folder names
         %
         %  paths = GETFOLDERTREE(obj);
         %  paths = GETFOLDERTREE(obj,paths);
         %  paths = GETFOLDERTREE(obj,paths,useRemote);
         %
         %  --------
         %   INPUTS
         %  --------
         %  obj       : nigeLab.Block class object
         %
         %    paths        : (optional) struct similar to output from this
         %                   function. This should be passed if paths has
         %                   already been extracted, to preserve paths that
         %                   are not extrapolated directly from
         %                   GETFOLDERTREE.
               
         if ~isfield(obj.HasParsInit,'Block')
            obj.updateParams('Block');
         elseif ~obj.HasParsInit.Block
            obj.updateParams('Block');
         end
         F = fieldnames(obj.Pars.Block.PathExpr);
         del = obj.Pars.Block.Delimiter;
         
         for iF = 1:numel(F) % For each field, update field type
            p = obj.Pars.Block.PathExpr.(F{iF});
            
            if contains(p.Folder,'%s') % Parse for spikes stuff
               % Get the current "Spike Detection method," which gets
               % added onto the front part of the _Spikes and related
               % folders
               
               % default. No attribute in teh name
               p.Folder = sprintf(strrep(p.Folder,'\','/'),...
                   '');
               if ~isfield(obj.HasParsInit,'SD')
                  obj.updateParams('SD');
               elseif ~obj.HasParsInit.SD
                  obj.updateParams('SD');
               end
               
               % Look for ID in Pars
               ParsFields = fieldnames(obj.Pars);
               ParsWithID = find(cellfun(@(F) isfield(obj.Pars.(F),'ID'),ParsFields))';
               for ii=ParsWithID
                   if isfield(obj.Pars.(ParsFields{ii}).ID,(F{iF}))
                       % if found put the ID in the foldername path
                       p.Folder = sprintf(strrep(p.Folder,'\','/'),...
                           obj.Pars.(ParsFields{ii}).ID.(F{iF}));
                       break;
                   end
               end
                             
            end
            
            % Set folder name for this particular Field
            paths.(F{iF}).dir = nigeLab.utils.getUNCPath(...
               obj.Out.Folder,[p.Folder]);
            
            % Parse for both old and new versions of file naming convention
            paths.(F{iF}).file = nigeLab.utils.getUNCPath(...
               paths.(F{iF}).dir,[p.File]);
            paths.(F{iF}).f_expr = p.File;
            paths.(F{iF}).info = nigeLab.utils.getUNCPath(...
               paths.(F{iF}).dir,[p.Info]);
            
         end
         
      end

       function flag = genPaths(obj)
           
           flag = false;
           if isempty(obj.Out.SaveLoc)
               [fmt,idt,type] = obj.getDescriptiveFormatting();
               dbstack;
               nigeLab.utils.cprintf('Errors*',obj.Verbose,...
                   '%s[GENPATHS]: ',idt);
               nigeLab.utils.cprintf(fmt,obj.Verbose,...
                   'Tried to build [%s].Paths using empty base\n',type);
               return;
           end
           
         
         if exist(obj.Out.Folder,'dir')==0
            mkdir(obj.Out.Folder);
         end
         
         paths = struct;
         paths = obj.getFolderTree(paths);
         % Iterate on all the fieldnames, making the folder if it doesn't exist yet
         F = fieldnames(paths);
         for ff=1:numel(F)
             if exist(paths.(F{ff}).dir,'dir')==0
                 mkdir(paths.(F{ff}).dir);
             end
         end
         flag = true;
          obj.Paths = paths;
         [fmt,idt,type] = obj.getDescriptiveFormatting();
         nigeLab.utils.cprintf(fmt,obj.Verbose,...
            '%s[GENPATHS]: Paths updated for %s (%s)\n',...
            idt,upper(type),obj.Name);
         nigeLab.utils.cprintf(fmt(1:(end-1)),obj.Verbose,...
            '\t%s%sObj.Ouput is now %s\n',...
            idt,lower(type),nigeLab.utils.shortenedPath(obj.Output));
       end
       
      flag = intan2Block(blockObj,fields,paths) % Convert Intan to BLOCK
      flag = tdt2Block(blockObj) % Convert TDT to BLOCK
      flag = rhd2Block(blockObj,recFile,saveLoc) % Convert *.rhd to BLOCK
      flag = rhs2Block(blockObj,recFile,saveLoc) % Convert *.rhs to BLOCK
      flag = init(blockObj) % Initializes the BLOCK object
      flag = initChannels(blockObj,header);   % Initialize Channels property
      flag = initEvents(blockObj);     % Initialize Events property
      flag = initStreams(blockObj,header);    % Initialize Streams property
      flag = initVideos(blockObj,forceNewParams);     % Initialize Videos property
      masterIdx = matchChannelID(blockObj,masterID); % Match unique channel ID
      header = parseHierarchy(blockObj)   % Parse header from file hierarchy
      blocks = splitMultiAnimals(blockObj,varargin)  % splits block with multiple animals in it
   
          
      function lockData(blockObj,fieldType)
         %LOCKDATA  Lock all data of a given fieldType
         %
         %  lockData(blockObj,fieldType);
         %
         %  --> default `fieldType` (if not specified) is 'Events'
         
         if nargin < 2
            fieldType = 'Events';
         end
         
         if numel(blockObj) > 1
            for i = 1:numel(blockObj)
               lockData(blockObj(i),fieldType);
            end
            return;
         end
         
         idx = getFieldTypeIndex(blockObj,fieldType);
         idx = find(idx);
         if isempty(idx)
            return;
         end
         for i = 1:numel(idx)
            f = blockObj.Fields{idx(i)};
            if ~isfield(blockObj.(fieldType),f)
               continue;
            end
            for j = 1:numel(blockObj.(fieldType).(f))
               if isempty(blockObj.(fieldType).(f)(j).data)
                  continue;
               end
               lockData(blockObj.(fieldType).(f)(j).data);
            end
         end
      end
      
      function unlockData(blockObj,fieldType)
         %UNLOCKDATA  Unlock all data of a given fieldType
         %
         %  unlockData(blockObj,fieldType)
         %
         %  --> default `fieldType` (if not specified) is 'Events'
         
         if nargin < 2
            fieldType = 'Events';
         end
         
         if numel(blockObj) > 1
            for i = 1:numel(blockObj)
               unlockData(blockObj(i),fieldType);
            end
            return;
         end
         
         idx = getFieldTypeIndex(blockObj,fieldType);
         idx = find(idx);
         if isempty(idx)
            return;
         end
         for i = 1:numel(idx)
            f = blockObj.Fields{idx(i)};
            if ~isfield(blockObj.(fieldType),f)
               continue;
            end
            for j = 1:numel(blockObj.(fieldType).(f))
               if isempty(blockObj.(fieldType).(f)(j).data)
                  continue;
               end
               unlockData(blockObj.(fieldType).(f)(j).data);
            end
         end
      end
   end
   
   % HIDDEN,PRIVATE
   methods (Hidden,Access=?nigeLab.nigelObj)
      eventData = getStreamsEventData(blockObj,field,prop,eventName,matchProp,matchValue)
      eventData = getChannelsEventData(blockObj,field,prop,ch,matchProp,matchValue)
      
      % used to filter blovks based on Metadata values, from {} interface
      function val = filterMeta(nigelObj,varargin)
          if ~isQuery(varargin)
              error(['nigeLab:' mfilename ':badSubscriptReference'],...
                  'Wrong input format for queries.');
          end
          if numel(varargin) == 2
              val = compare(nigelObj.Meta.(varargin{1}), varargin{2});
              return
          end
          val = filterMeta(nigelObj,varargin{1:2}) & filterMeta(nigelObj,varargin{3:end});

          function val = isQuery(subs)
              val = ~mod(numel(subs),2);
              val = val & all(cellfun(@ischar,subs(1:2:end)));
          end
          function val = compare(val1,val2)
              if isnumeric(val1) && isnumeric(val2)
                  val = all(val1 == val2);
              elseif (ischar(val1) || isstring(val1)) && (ischar(val2) || isstring(val2))
                  val = strcmpi(val1,val2);
              end
          end

      end

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
            n = max(n,0,'omitnan');
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
   
   % SEALED,HIDDEN,PUBLIC
   methods (Sealed,Hidden,Access=public)
      varargout = testbench(blockObj,varargin); % Testbench with access to protected methods
      
      function SDargsout = testSD(blockobj,SDFun,data,SDPars)
          SDargsout = cell(1,nargout(SDFun));
          [SDargsout{:}] = feval(SDFun,data,SDPars);
      end
   end
   % % % % % % % % % % END METHODS% % %
end