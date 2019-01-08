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
   
   %% PUBLIC PROPERTIES
   
   properties (Access = public)
      Name  % Name of the recording block
      Meta  % Metadata about the recording
   end
   
   properties (Access = public)
      DACChannels       % Struct containing info about DAC channels
      ADCChannels       % Struct containing info about ADC channels
      DigInChannels     % Struct containing info about digital inputs
      DigOutChannels    % Struct containing info about digital outputs
      Verbose = true;   % Whether to report list of files and fields.
      Channels          % Struct that contains fields with data
      Graphics          % Graphical objects associated with block
   end
   
   properties (SetAccess = private)
      
      SampleRate  % Recording sample rate
      Time        % Points to Time File
      FileExt     % .rhd, .rhs, or other
      RecType     % Intan / TDT / other
      
      NumChannels       = 0   % Number of channels on all electrodes
      NumProbes         = 0   % Number of electrodes
      NumADCchannels    = 0   % Number of ADC channels
      NumDACChannels    = 0   % Number of DAC channels
      NumDigInChannels  = 0   % Number of digital input channels
      NumDigOutChannels = 0   % Number of digital output channels
      
      RMS                     % RMS noise table for different waveforms
   end
   
   properties (SetAccess = immutable,GetAccess = private)
      DCAmpDataSaved    % Flag indicating whether DC amplifier data saved
      Date              % Date of recording
      Month             % Month of recording
      Day               % Day of recording
   end
   
   properties (SetAccess = immutable,GetAccess = public)
      RecLocDefault     % Default location of raw binary recording
      SaveLocDefault    % Default location of BLOCK
      ForceSaveLoc      % Flag to force make non-existant directory
      ProbeChannel      % String for probe and channel number parsing
      
      Delimiter        % Delimiter for name metadata for dynamic variables
      DynamicVarExp    % Expression for parsing BLOCK names from raw file
      IncludeChar      % Character indicating included name elements
      DiscardChar      % Character indicating discarded name elements
      NamingConvention % How to parse dynamic name variables for Block
   end
   
   
   %% PRIVATE PROPERTIES
   properties (SetAccess = private,GetAccess = public)
      Fields      % List of property field names
      
      SDPars      % Parameters struct for spike detection
      FiltPars    % Parameters struct for unit bandpass filter
      LFPPars     % Parameters struct for LFP extraction & analyses
      SyncPars    % Parameters struct for digital synchronization stream
      VidPars     % Parameters struct for associating videos
      PlotPars    % Parameters struct for graphical plots
      QueuePars   % Parameters struct for queueing jobs to server
      ExpPars     % Parameters struct for experimental notes
      ProbePars   % Parameters struct for parsing probe layout info
      
      RecFile       % Raw binary recording file
      SaveLoc       % Saving path for extracted/processed data
      SaveFormat    % saving format (MatFile,HDF5,dat, current: "Hybrid")
      
      Samples  % Total number of samples in original record
      Mask     % Whether to include channels or not
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
         % By: Max Murphy  v1.0  08/25/2017
         %     F. Barban   v2.0  11/2018
         
         %% PARSE VARARGIN
         P = properties(blockObj);
         for iV = 1:2:numel(varargin) % Can specify properties on construct
            if ~ischar(varargin{iV})
               continue;
            end
            % Check to see if it matches any of the listed properties
            idx = ismember(upper(P), upper( deblank( varargin{iV})));
            if sum(idx)==1 % Should only be one match
               Prop = P{idx};
               blockObj.(Prop) = varargin{iV+1};
            end
            
         end
         
         %% LOAD DEFAULT BLOCK PARAMETERS
         [pars,blockObj.Fields] = nigeLab.defaults.Block;
         allNames = fieldnames(pars);
         allNames = reshape(allNames,1,numel(allNames));
         for varName = allNames
            str = varName{1}; % remove from cell container
            
            % Check to see if it matches any of the listed properties
            idx = ismember(upper(P), upper( deblank( str)));
            if sum(idx)==1 % Should only be one match
               Prop = P{idx};
               blockObj.(Prop) = pars.(str);
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
         save(fullfile([blockObj.paths.TW '_Block.mat']),'blockObj','-v7.3');
      end
      
      function disp(blockObj)
         %% DISP  Overload display of BLOCK contents
         if blockObj.Verbose
            builtin('disp',blockObj);
         end
      end
      
      % Federico I will let you comment this :) -MM
%       function varargout=subsref(blockObj,S) 
%          %% overrrides builtin subsref to allow shortcuts
%          % Only explicetly handles operator () called as first argoument
%          % Ohter cases are handled by builtin subsref directly.
% 
%          nOper = numel(S);
%          
%          if nOper == 1 && strcmp(S(1).type,'()') && numel(S(1).subs) > 2
%             nargs=numel(S(1).subs);
%             for jj=3:nargs
%                ind=numel(S)+1;
%                S(ind).subs{1}=S(1).subs{jj};
%                S(ind).type = '()';
%             end
%             Shrt = nigeLab.defaults.Shortcuts();
%             if ischar( S(1).subs{1} )
%                longCommand = sprintf(Shrt{strcmp(Shrt(:,1),S(1).subs{1}),2},S(1).subs{2});
%             elseif isnumeric( S(1).subs{1} )
%                longCommand = sprintf(Shrt{S(1).subs{1},2},S(1).subs{2});
%             end
%             Out = sprintf('blockObj.%s',longCommand);
%             Out = eval(Out);
%             varargout = {Out};
%          else
%             [varargout{1:nargout}] = builtin('subsref',blockObj,S);
%          end
%             
%          
% %          
% %          ii=1;
% %           while ii<=numel(S)
% %               switch S(ii).type
% %                   case '()'
% %                       if ii==1
% %                           nargs=numel(S(ii).subs);
% %                           switch nargs
% %                              case 1
% %                                 Out = blockObj(S(ii).subs{:});
% %                                 varargout = {Out};
% %                                 ii=ii+1;
% %                                 continue;
% %                              case 2
% %                              otherwise
% %                           
% %                           for jj=3:nargs
% %                               ind=numel(S)+1;
% %                              S(ind).subs{1}=S(ii).subs{jj};
% %                              S(ind).type = '()';
% %                           end
% %                           Shrt = nigeLab.defaults.Shortcuts();
% %                           if ischar( S(ii).subs{1} )
% %                               longCommand = sprintf(Shrt{strcmp(Shrt(:,1),S(ii).subs{1}),2},S(ii).subs{2});
% %                           elseif isnumeric( S(ii).subs{1} )
% %                               longCommand = sprintf(Shrt{S(ii).subs{1},2},S(ii).subs{2});
% %                           end
% %                           Out = sprintf('%s.%s',Out,longCommand);
% %                           Out = eval(Out);
% %                           varargout = {Out};
% %                           end
% %                       else
% %                          % retrieve methods output info
% %                          finfo = functions(eval(sprintf('@blockObj.%s',S.subs)));
% %                          fwspace = finfo.workspace{1};
% %                          wspacefields = fieldnames(fwspace);
% %                          mc = metaclass(fwspace.(wspacefields{1}));
% %                          methodsIndx=strcmp({mc.MethodList.Name},S.subs);
% %                          nout = numel(mc.MethodList(methodsIndx).OutputNames);
% %                          
% %                          % call builtin subsref with appropiate number of nouts
% %                          if nout
% %                             varargout = {builtin('subsref',blockObj,S)};
% %                          else
% %                             builtin('subsref',blockObj,S);
% %                          end
% %                          break;
% %                       end
% %                   case '.'                     
% %                     % retrieve method's output info 
% %                      finfo = functions(eval(sprintf('@blockObj.%s',S(ii).subs)));
% %                      fwspace = finfo.workspace{1};
% %                      wspacefields = fieldnames(fwspace);
% %                      mc = metaclass(fwspace.(wspacefields{1}));
% %                      methodsIndx=strcmp({mc.MethodList.Name},S(ii).subs);
% %                      nout = numel(mc.MethodList(methodsIndx).OutputNames);
% %                      
% %                      % call builtin subsref with appropiate number of nouts
% %                      if nout
% %                         varargout = {builtin('subsref',blockObj,S)};
% %                      else 
% %                         builtin('subsref',blockObj,S);                        
% %                      end
% %                       break;
% %                  case '{}'
% %                  case '[]'
% %                end
% %               ii=ii+1;
% %           end
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
         if numel(dot) < 2
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
      
      flag = parseProbeNumbers(blockObj) % Get numeric probe identifier
      flag = setChannelMask(blockObj,includedChannelIndices) % Set "mask" to look at
      
      ts = getSpikeTimes(blockObj,ch,class);    % Get spike times (sec)
      idx = getSpikeTrain(blockObj,ch,class);   % Get spike sample indices
      spikes = getSpikes(blockObj,ch,class);    % Get spike waveforms
      class = getSort(blockObj,ch);             % Get spike sorted classes
      
      [tf_map,times_in_ms] = analyzeERS(blockObj,options) % Event-related synchronization (ERS)
      analyzeLFPSyncIndex(blockObj)                       % LFP synchronization index
      analyzeRMS(blockObj,type)
      
      flag = plotWaves(blockObj)          % Plot stream snippets
      flag = plotSpikes(blockObj,ch)      % Show spike clusters for a single channel
      flag = plotOverlay(blockObj)        % Plot overlay of values on skull
      
      L = list(blockObj) % List of current associated files for field or fields
      flag = linkToData(blockObj,preExtractedFlag) % Link to existing data
      flag = updatePaths(blockObj,tankPath) % Update associated paths
      flag = updateVidInfo(blockObj) % Update video info
      
      h = takeNotes(blockObj)             % View or update notes on current recording
      parseNotes(blockObj,str)            % Update notes for a recording
   end
   methods (Access = public, Hidden = true)
      flag = rhd2Block(blockObj,recFile,saveLoc) % Convert *.rhd to BLOCK
      flag = rhs2Block(blockObj,recFile,saveLoc) % Convert *.rhs to BLOCK
      
      flag = genPaths(blockObj,tankPath)  % Generate paths property struct
      flag = findCorrectPath(blockObj)    % Find correct TANK
      flag = setSaveLocation(blockObj,saveLoc) % Set save location
      
      operations = updateStatus(blockObj,operation,value) % Indicate completion of phase
      Status = getStatus(blockObj,stage)  % Retrieve task/phase status
      flag = clearSpace(blockObj,ask)     % Clear space on disk      

   end
   
   %% PRIVATE METHODS
   methods (Access = 'private') % debugging purpose, is private
      flag = init(blockObj) % Initializes the BLOCK object
      
   end
end