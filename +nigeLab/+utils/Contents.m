% +UTILS Package with miscellaneous utility functions
% MATLAB Version 9.2.0.538062 (R2017a) 06-Aug-2020
%
% Files
%   AcqSystem                  - Enumeration of properties for different acquisition systems
%   add2struct                 - Adds fields of `structToAdd` into `structToKeep`
%   addStructField             - Add field(s) to an existing struct.
%   addTableVar                - Append a variable (column) to a table with optional values
%   applyScaleOpts             - Returns the data with scaling options applied to it
%   assignParentStruct         - Utility to assign parent when load creates a struct
%   binaryStream2ts            - Returns list of transition times for a signal
%   buildWorkerConfigScript    - Programmatically creates a worker config file
%   checkForWorker             - Checks for worker to determine if this is being run on
%   cleanupNigel               - Deletes all nigelFiles at the specified `tankPath` (input)
%   cprintf                    - displays styled formatted text in the Command Window
%   cubehelix                  - Generate an RGB colormap of Dave Green's CubeHelix colorscheme. With range and domain control.
%   debouncePointProcess       - Remove point process events that are too close
%   exportVideoFrames          - Export `nframes` random images from video for training
%   extractTrials              - Extract candidate trial onsets for video scoring
%   fastsmooth                 - Smooths vector X
%   findGoodCluster            - Find and/or wait for available workers.
%   findjobj                   - findjobj Find java objects contained within a specified java container or Matlab GUI handle
%   findjobj_fast              - 
%   fixNamingConvention        - Remove '_' and switch to CamelCase
%   fread_QString              - Read Qt style QString
%   freehanddraw               - [LINEOBJ,XS,YS] = FREEHANDDRAW(ax_handle,line_options)
%   get_axes_width             - pixels = get_axes_width(h)
%   getChannelNum              - Get numeric and string values for channel NUMBER
%   getDropDownRadioStreams    - Return inputs to uidropdownradiobox for
%   getFirstNonEmptyCell       - out = utils.getFirstNonEmptyCell(in);
%   getLastDispText            - Returns the last nChar characters printed to cmd window
%   getMatlabBuiltinIcon       - Return icon CData for a .gif Matlab builtin icon
%   getNigelDate               - Returns today's date in standardized "nigeLab" format
%   getNigeLink                - Returns html link string for a given class/method name. The
%   getNigelPath               - Returns the path to nigeLab
%   getNormPixelDim            - "Fix" normalized dimensions based on minimum pixel
%   getopt                     - - Process paired optional arguments as 'prop1',val1,'prop2',val2,...
%   getParamField              - f = utlis.getParamField(p,'paramName');
%   getR                       - Get covariance matrix of two one-dimensional time-series.
%   getUNCPath                 - Returns UNC-formatted path of the input path
%   ginput                     - Graphical input from mouse.
%   initCamOpts                - Return default options struct for selecting a camera stream
%   initCellArray              - [var1,var2,...] = utils.initCellArray(dim1,dim2,...);
%   initChannelStruct          - Initialize STREAMS channel struct with correct fields
%   initDataArray              - [var1,var2,...] = utils.initDataArray(dim1,dim2,...);
%   initDesiredHeaderFields    - Returns array of desired header fields 
%   initEmpty                  - [var1,var2,...] = utils.initEmpty; % Initialize empty array
%   initEventData              - [var1,var2,...] = utils.initEventData(nEvent,nSnippet);
%   initFalseArray             - [var1,var2,...] = utils.initFalseArray(dim1,dim2,...); 
%   initNaNArray               - [var1,var2,...] = utils.initNaNArray(dim1,dim2,...);
%   initOnesArray              - [var1,var2,...] = utils.initOnesArray(dim1,dim2,...);
%   initScaleOpts              - Return default scale options struct for scaling streams
%   initSpikeTriggerStruct     - Initialize "spike trigger" struct
%   initTrueArray              - [var1,var2,...] = utils.initTrueArray(dim1,dim2,...); 
%   initZerosArray             - [var1,var2,...] = utils.initZerosArray(dim1,dim2,...);
%   InstallMex                 - - Compile and install Mex file
%   interp1qr                  - Quicker 1D linear interpolation
%   jobFinishedAlert           - Specify completion of a queued MJS job.
%   jobTag2Pct                 - Convert tagged CJS communicating job tag to completion %
%   ListenerMonitor            - Object that listens to... listeners.
%   load_ratskull_plot_img     - utils.load_ratskull_plot_img;
%   loadTable                  - Load a Table variable without needing specific name
%   makeDiskFile               - Short-hand function to create file on disk
%   makeHash                   - Utility to make random hashstring for naming a "row"
%   matchEpochStartStopTimes   - Match epoch start and stop time vectors
%   matchWindowedPointElements - Returns matched elements according to
%   mtb                        - Move variable to base workspace
%   multiCallbackWrap          - Wraps multiple funtions into a single callback
%   parseParams                - p = utils.parseParams(cfg_key,arg_pairs);
%   parseR                     - Parse correlation matrix to guess Video Start offset
%   plural                     - Utility function to optionally pluralize words depending on 'n'
%   printLinkFieldString       - Standardized Command Window print command for link
%   printWarningLoop           - Warning function to count down before **SOMETHING**
%   reduce_plot                - h = reduce_plot(varargin)
%   reduce_to_width            - [x_reduced, y_reduced] = reduce_to_width(x, y, width, lims)
%   reportProgress             - Utility function to report progress on block operations.
%   sec2time                   - Convert a time string or char into a double of seconds
%   setParamField              - p = utils.setParamField(p,'paramName',paramValue);
%   shortenedName              - Returns a shortened version of filename string (for
%   shortenedPath              - Returns a shortened version of path file string (for
%   signal                     - Handle class that enumerates signal properties for grouping
%   simplePlot                 - Make a "simple" line plot using just (2D) vertex data
%   ToString                   - Universal to string convertor
%   uiAxesSelectionRadio       - Create selection radio buttons to label axes
%   uidropdownbox              - Create a dropdown box to let user select a string
%   uidropdownradiobox         - Create a dropdown box to let user select a string.
%   uiGetGrid                  - Returns [x,y,w,h] graphics position vector for (nRow,nCol)
%   uiGetHorizontalSpacing     - Get spacing in x-direction for array of graphics
%   uiGetVerticalSpacing       - Get spacing in y-direction for array of graphics
%   uiHandle                   - Handle class to store data for simple selector UI
%   uiMakeEditArray            - Make array of edit boxes that corresponds to set of labels
%   uiMakeLabels               - Make labels at equally spaced increments along left of panel
%   uiMakeUIControlArray       - Makes equally-spaced uiControl grid array
%   uiPanelizeAxes             - Returns axes cell array, with panelized axes objects
%   uiPanelizeTickBoxes        - Returns axes cell array, with panelized axes objects
%   uiPanelizeToggleButtons    - UIPANELIZETICKBOXES Returns axes cell array, with panelized axes objects
