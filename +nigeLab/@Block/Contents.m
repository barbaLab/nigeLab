% @BLOCK Object containing all data for a single experimental recording.
% MATLAB Version 9.2.0.538062 (R2017a) 06-Aug-2020
%
% Method Files
%   addScoringMetadata       - Appends scoring metadata to Block record
%   alignVideoManual         - Manually obtain offset between video and neural record,
%   analyzeERS               - performs the event relater power spectrum analysis on the data provided 
%   analyzeLFPSyncIndex      - Get synchronization index for different LFP bands
%   analyzeRMS               - Get RMS for full recording for each type of stream
%   checkActionIsValid       - Return true if correct 'Status' evaluates true.
%   checkMask                - Check to ensure that the channel mask matches extracted data
%   checkSpikeFile           - Check to make sure spike file is correct format, and CONVERT it
%   clearScoringMetadata     - Deletes 'Scoring' table for 'fieldName'
%   doAutoClustering         - Cluster spikes based on extracted waveform features
%   doBehaviorSync           - Get event times from synchronized optiTrack record.
%   doEventDetection         - "Detects" putative Trial events
%   doEventHeaderExtraction  - Creates "header" for scored behavioral events
%   doLFPExtraction          - Decimates files to retrieve LFPs.
%   doRawExtraction          - Extract matfiles from binary recording files
%   doReReference            - Perform common-average re-referencing (CAR)
%   doSD                     - Detects spikes after raw extraction and unit filter
%   doTrialVidExtraction     - Extract Trial Videos 
%   doUnitFilter             - Filter raw data using spike bandpass filter
%   doVidInfoExtraction      - Get video metadata for associated behavioral vids
%   doVidSyncExtraction      - Get time-series for sync event cross-correlation
%   getChannelsEventData     - Returns event-data related to individual Channels
%   getClus                  - Retrieve list of spike Clusters class indices for each spike
%   getEventData             - Retrieve data for a given event
%   getEventsIndex           - Returns index to correct element of Events.(field)
%   getNumBlocks             - Helper function to make it easier to count total blocks
%   getOperationField        - Gets the field associatied with a given operation
%   getScoringMetadata       - Returns table row corresponding to 'scoringID' for
%   getSort                  - Retrieve list of spike Sorted class indices for each spike
%   getSpikeFeatures         - Return spike features
%   getSpikes                - Retrieve list of spike peak sample indices
%   getSpikeTimes            - Retrieve list of spike times (seconds)
%   getSpikeTrain            - Retrieve list of spike peak sample indices
%   getStatus                - Returns the operations performed on the block to date
%   getStream                - Returns stream struct field corresponding to streamName
%   getStreamsEventData      - GETCHANNELSEVENTDATA  Returns the event data for a 'Streams' Event
%   getStreamsFieldIndex     - Returns indices for each Streams of a given field
%   getTag                   - Retrieve list of spike tags for each spike on a channel
%   getTrialStartStopTimes   - Returns neural times of "trial" start and stop times
%   getVideoFileList         - Returns name of .csv file and table field of .Meta
%   guessVidStreamAlignment  - GUESSALIGNMENT  Compute "best guess" offset using
%   init                     - Initialize BLOCK object
%   initChannels             - Initialize header information for channels
%   initEvents               - Initialize events struct for nigeLab.Block class object
%   initStreams              - Initialize Streams struct for nigeLab.Block class object
%   initVideos               - Initialize Videos struct for nigeLab.Block class object
%   intan2Block              - Convert Intan binary to nigeLab.Block file structure
%   linkChannelsField        - Connect the data saved on the disk to Channels
%   linkEventsField          - Connect data to Events, return true if missing a file
%   linkField                - Connect the data saved on the disk to a Field of Block
%   linkNotes                - Connect notes metadata saved on the disk to the structure
%   linkProbe                - Connect probe metadata saved on the disk to the structure
%   linkStreamsField         - Connect the data saved on the disk to Streams
%   linkTime                 - Connect the data saved on the disk to Time property
%   linkVideosField          - Connect the data saved on the disk to Videos
%   list                     - Give list of current files associated with field.
%   loadRemote               - Static method to load Block on remote worker
%   matchChannelID           - Use master identifier to match channel indices by ID
%   matchProbeChannel        - Return index for a given probe/channel combo
%   notifyStatus             - Emits the `StatusChanged` event notification to Block
%   parseHeader              - Parse header from recording file or from folder hierarchy
%   parseHierarchy           - Parse header structure from pre-extracted file hierarchy
%   parseNotes               - Update metadata using notes
%   parseProbeNumbers        - Function to parse probe numbers depending on recType
%   parseSpikeTagIdx         - Get index given a cell array of spike tags
%   parseVidFileExpr         - Parses expression for finding matched videos
%   parseVidFileName         - Get video file info from video file
%   plotOverlay              - Overlay multi-channel values, superimposed on image
%   plotSpikes               - Show all spike clusters for a given channel.
%   plotWaves                - Plot multi-channel waveform snippets for BLOCK
%   reportProgress           - Utility function to report progress on block operations.
%   saveChannelSpikingEvents - Save spike events for a nigeLab.Block Channel
%   scoreVideo               - Locates successful grasps in behavioral video.
%   setChannelMask           - Set included channels to use for subsequent analyses
%   setEventData             - Set 'Event' file data (on disk file)
%   setOverlay               - Set overlay values for plotting
%   splitMultiAnimals        - Returns a uiw.widget.Tree object with the split
%   subsref                  - Overload indexing operators for BLOCK (subscripted reference)
%   takeNotes                - View or update notes on current BLOCK.
%   tdt2Block                - PARSE INPUT
%   testbench                - For development to work with protected methods on ad hoc basis
%   updateStatus             - Updates Status property of nigeLab.Block class object
%   updateVidInfo            - Update the video info associated with Block object
%
% Class File
%   Block                    - Object containing all data for a single experimental recording.