function pars = Video(name)
%% VIDEO  Template for initializing parameters related to experiment trigger synchronization
%
%  pars = nigeLab.defaults.Video();
%  --> Returns struct with following fields:
%     * HasVideo: (true or false)
%     * HasVidStreams: (true or false)
%     * VidStreamName: Name for signal associated with each VidStream.
%        + [] : (No VidStreams)
%        + {'Paw_Likelihood'} : Single-level cell array (all cams the same)
%        + {{'Src1Name1','Src1Name2',...,'Src1NameK'};
%            ...
%           {'SrcXName1','SrcXName2',...,'SrcXNameL'}}; : (multi sources)
%        + NOTE: this cell array format is matched for VidStreamGroup
%                and VidStreamSubGroup parameters as well.
%     * VidStreamGroup (see above): e.g. 'Marker' or 'Sync' (so far)
%     * VidStreamSubGroup (see above): 
%        + For 'Marker' Group: 'p','x','y','z' (marker likelihood, bases)
%        + For 'Sync' Group: 'discrete', or 'analog'
%     * CameraSourceVar:
%        + [] : Only one view or it's not important to parse
%        + 'View': Dynamic variable name to parse Camera Source from
%                  filename. e.g. for some cases, one of the '_' delimited
%                  variables can take values such as 'Left-A' or 'Right-B';
%                  this will then be used to co-register naming schema so
%                  that VidStreamName cell arrays are matched according to
%                  a key for different 'Source Types'. For example, in the
%                  reach task, the ceiling-down view ('Top-A') will parse
%                  different markers and syncs than door views ('Left-A'
%                  etc). This is a way to reconcile the different number of
%                  variables per "View" (although it doesn't have to be
%                  called that explicitly).
%     * CameraKey: 
%        + If CameraSourceVar is [], then this should just be a scalar
%          struct with the fields 'Index' (1) and 'Source' (name of camera
%          view or label or whatever, for file name).
%        + If CameraSourceVar specifies a Dynamic variable camera source, 
%          this is much more important! It becomes a struct array with the
%          fields 'Index' and 'Source'; each array element specifies a
%          pairing, where 'Index' gives the index to a sub-cell for
%          VidStreamName, etc. that is matched for a given 'View' name
%          parsed from CameraSourceVar. For example, 'Left-A' thru
%          'Right-C' might all take Index values of 1, while 'Top-A' might
%          take Index value of 2, in the example given above for
%          'CameraSourceVar'. 
%     * VidStreamSource:
%        + If CameraSourceVar is non-empty, this should just be [].
%        + If CameraSourceVar is empty, this is used for "backwards
%           compatibility;" for example in the "RC" project, DLC had
%           already been used to get "VidStreams" for Paw presence
%           likelihood. So the 'Front' camera source was set here as the
%           VidStreamSource. In the previous examples, VidStreamSource
%           should match to each of the different VidStreams to be parsed,
%           so it will have many more elements.
%
%     * This should be filled out more in the future ...
%
%     * VarType: Important for video scoring. Note that all values of
%                 nigeLab.default.Event('Names') will be automatically
%                 pre-appended as an array of ones(1,numel(Names)) to the
%                 start of VarType. This specifies parsing for video
%                 scoring, among other things.
%     * VarsToScore: Elements of VarType should match the names here, which
%                    are metadata that are scored manually from videos.
%                    Event (timestamps) are specified in
%                    nigeLab.defaults.Event('Name') and will be
%                    automatically added.
%
%  paramVal = nigeLab.defaults.Video('paramName');
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%% MAIN PARAMETERS TO CHANGE GO HERE
% Note: to set up video scoring currently (2019-11-23), it is necessary to
% change parameters **HERE** and also in **nigeLab.defaults.Event** (where
% the relevant behavioral scoring markers are setup). VidStreams are for
% analyses that extract markers or synchronization endpoints from the
% videos, not for things like "beam-break" etc. that are in the separate
% FieldType of Streams.
pars = struct;
pars.HasVideo = true;
pars.HasVidStreams = true;

% % % -- For Video Scoring -- % % %

% Stream Names: Most-flexible naming
% pars.VidStreamName = []; % For "no video streams" case

% IMPORTANT: DO NOT GIVE THESE REDUNDANT NAMES WITH OTHER "STREAMS" (e.g.
% make sure they have _Likelihood or _X on the end. Otherwise it messes up
% some of the convenient built-in parsing for methods like
% blockObj.getStream etc)
pars.VidStreamName = {'Paw_Likelihood'}; % KUMC: "RC"
% pars.VidStreamName = {{'D1_Likelihood','D1_X','D1_Y','D1_Z',...
%                        'D2_Likelihood','D2_X','D2_Y','D2_Z',...
%                        'D3_Likelihood','D3_X','D3_Y','D3_Z',...
%                        'D4_Likelihood','D4_X','D4_Y','D4_Z',... % KUMC: "Murphy"
%                        'D5_Likelihood','D5_X','D5_Y','D5_Z',...
%                        'W_Likelihood','W_X','W_Y','W_Z',...
%                        'LED_Trial_Sync'}; ...
%                       {'Nose_Likelihood','Nose_X','Nose_Y',...
%                        'Head_Likelihood','Head_X','Head_Y',...
%                        'Tail_Likelihood','Tail_X','Tail_Y',...
%                        'LED_L_Trial_Sync','LED_R_Trial_Sync'}};
   
% Stream Groups: 'Marker' or 'Sync' (only 2 so far)
% pars.VidStreamGroup = []; % For "no video streams" case
pars.VidStreamGroup = {'Marker'}; % KUMC: "RC" (only 1 cell level because only 1 camera on recording)
% pars.VidStreamGroup = {{'Marker','Marker','Marker','Marker',... 
%                        'Marker','Marker','Marker','Marker',...
%                        'Marker','Marker','Marker','Marker',... % KUMC: "Murphy"
%                        'Marker','Marker','Marker','Marker',...
%                        'Marker','Marker','Marker','Marker',...
%                        'Marker','Marker','Marker','Marker',...
%                        'Sync'};... % 2nd cell is due to different signals on "Top-A" camera 
%                       {'Marker','Marker','Marker',... 
%                        'Marker','Marker','Marker',...
%                        'Marker','Marker','Marker',... % KUMC: "Murphy"
%                        'Sync','Sync'}};


% SubGroups: 'p', 'x', 'y', 'z' (Marker) and 'discrete' or 'analog' (Sync)

% pars.VidStreamSubGroup = []; % For "no video streams" case
pars.VidStreamSubGroup = {'p'}; % KUMC: "RC" (No 2nd cell if CameraSourceVar is [])
% pars.VidStreamSubGroup = {{'p','x','y','z',... % KUMC: "Murphy"
%                           'p','x','y','z',...
%                           'p','x','y','z',...
%                           'p','x','y','z',...
%                           'p','x','y','z',...
%                           'p','x','y','z',...
%                           'discrete'};...
%                          {'p','x','y'... % (Different for Top-A)
%                           'p','x','y',...
%                           'p','x','y',...
%                           'discrete',...
%                           'discrete'}};

% Sources: Should match CAMERA-SOURCE, which is defaulted to being parsed
%           using the matching 'pars.DynamicVars' metadata variable set in
%           'pars.CameraSourceVar'. If left as [], then
%           'pars.VidStreamSource' can be assigned manually and should have
%           the same number of elements as the other "VidStream" params.

% pars.CameraSourceVar = 'View'; % KUMC: "Murphy"
pars.CameraSourceVar = []; % KUMC: "RC"

% CameraKey: Gives indexing into which cell array applies to which camera
% pars.CameraKey = struct('Index',{1;1;1;1;1;1;2},... % KUMC: "Murphy"
%    'Source',{'Left-A';'Left-B';'Left-C';'Right-A';'Right-B';'Right-C';'Top-A'});
pars.CameraKey = struct('Index',1,'Source','Front'); % KUMC: "RC"
% pars.VideoEventCamera = 'Top-A'; % KUMC: "Murphy"
pars.VideoEventCamera = 'Front';

% pars.VidStreamSource = [];  % If pars.CameraSourceVar is non-empty
pars.VidStreamSource = {'Front'}; % KUMC: "RC"

% Depends on location of video files. If you are switching back and forth a
% lot, may be convenient to add elements to this array so you don't forget
% to toggle it.
pars.VidFilePath    = { ... % "Includes" for where videos might be. Stops after first non-empty path.
   'K:\Rat\Video\BilateralReach\Murphy'; 
   'K:\Rat\Video\BilateralReach\RC';
   };
                      
pars.FileExt = '.avi';
% For DynamicVars expressions, see 'Metadata parsing' below
% pars.DynamicVars = {'$AnimalID','$Year','$Month','$Day','$RecID','&View','&MovieID'}; % KUMC: "Murphy"
pars.DynamicVars = {'$AnimalID','$Year','$Month','$Day','&MovieID'}; % KUMC: "RC"
pars.MovieIndexVar = 'MovieID'; % KUMC: "RC" (and in general)

% Information about video scoring
% pars.OutcomeEvent = [];
pars.OutcomeEvent = 'Outcome'; % special Event type for progress-tracking
pars.User = 'MM'; % Who did the scoring?
pars.TrialBuffer = -0.25;  % Time before "trial" to start video frame for
                            % a given scoring "trial." It is useful to
                            % start at an earlier frame, because the
                            % VideoReader object is faster at reading the
                            % "next" frame rather than going backwards, for
                            % whatever reason (it seems).
      
[pars.VarsToScore,pars.VarType] = setScoringVars();

% % % -- For Video Alignment -- % % %
pars.Alignment_FS = struct('TDT',125,'RHD',100,'RHS',100);

%% Less-likely to change these parameters


% Paths information
pars.File = [];

% Metadata parsing
pars.Delimiter = '_'; % Break filename "variables" by this
pars.IncludeChar = '$'; % Include data from these variables
pars.ExcludeChar = '&'; % Exclude data from these variables
pars.Meta = [];

pars.ValueShortcutFcn = @nigeLab.workflow.defaultVideoScoringShortcutFcn;
pars.VideoScoringStringsFcn = @nigeLab.workflow.defaultVideoScoringStrings;
pars.ForceToZeroFcn = @nigeLab.workflow.defaultForceToZeroFcn;
pars.ScoringHotkeyFcn = @nigeLab.workflow.defaultHotkeyFcn;
pars.ScoringHotkeyHelpFcn = @nigeLab.workflow.defaultHotkeyHelpFcn;

%% Error parsing (do not change)
pars.HasVidStreams = ...
   pars.HasVidStreams && ...
   pars.HasVideo && ...
   (~isempty(pars.VidStreamName));

if pars.HasVidStreams
   n = numel(pars.VidStreamName);
   
   if ~isempty(pars.CameraSourceVar)
      pars.VidStreamField = cell(n,1);
      pars.VidStreamFieldType = cell(n,1);
      
      % Check that the CameraSourceVar is good
      dyVar = cellfun(@(x)x(2:end),pars.DynamicVars,'UniformOutput',false);
      idx = ismember(dyVar,pars.CameraSourceVar);
      if sum(idx) ~= 1
         error('CameraSourceVar (%s) is not a member of pars.DynamicVars (%s)',...
            pars.CameraSourceVar,dyVar);
      end
      
      % For each Cell corresponding to a different subset of markings,
      % double-check
      for i = 1:numel(pars.VidStreamName)
         n = numel(pars.VidStreamName{i});
         m = numel(pars.VidStreamGroup{i});
         if n ~= m
            error(['Number of elements of pars.VidStreamName{%g} (%g) must ' ...
               'equal number of elements of pars.VidStreamGroup{%g} (%g).'],...
               i,n,i,m);
         end
         m = numel(pars.VidStreamSubGroup{i});
         if n ~= m
            error(['Number of elements of pars.VidStreamName{%g} (%g) must ' ...
               'equal number of elements of pars.VidStreamSubGroup{%g} (%g).'],...
               i,n,i,m);
         end
         pars.VidStreamField{i} = repmat({'VidStreams'},1,n);
         pars.VidStreamFieldType{i}= repmat({'Streams'},1,n);
      end
      pars.VidStream = [];
   else
      m = numel(pars.VidStreamGroup);
      if n ~= m
         error(['Number of elements of pars.VidStreamName (%g) must ' ...
            'equal number of elements of pars.VidStreamGroup (%g).'],...
            n,m);
      end
      m = numel(pars.VidStreamSubGroup);
      if n ~= m
         error(['Number of elements of pars.VidStreamName (%g) must ' ...
            'equal number of elements of pars.VidStreamSubGroup (%g).'],...
            n,m);
      end

      m = numel(pars.VidStreamSource);
      if n ~= m
         error(['Number of elements of pars.VidStreamName (%g) must ' ...
            'equal number of elements of pars.VidStreamSource (%g).'],...
            n,m);
      end

      pars.VidStreamField = repmat({'VidStreams'},1,n);
      pars.VidStreamFieldType= repmat({'Videos'},1,n);
      pars.VidStream = nigeLab.utils.signal(...
         pars.VidStreamGroup,...
         pars.VidStreamField,...
         pars.VidStreamFieldType,...
         pars.VidStreamSource,...
         pars.VidStreamName,...
         pars.VidStreamSubGroup); 
   end

end

eventType = nigeLab.defaults.Event('EventType');
f = fieldnames(eventType);
% Check which one is the 'manual' "key" if variables should be scored
if (~isempty(pars.VarsToScore))
   pars.ScoringEventFieldName = [];
   for i = 1:numel(f)
      if strcmpi(eventType.(f{i}),'manual')
         pars.ScoringEventFieldName = f{i};
         break;
      end
   end
   if isempty(pars.ScoringEventFieldName)
      error(['Parameter configuration suggests videos should be scored, ' ...
             'but ''pars.EventType'' key is set up incorrectly.']);
   end
else
   pars.ScoringEventFieldName = [];   
end




% Check that number of elements of VarsToScore matches number of elements
% of VarType.
if numel(pars.VarsToScore) ~= numel(pars.VarType)
   error('Dimension mismatch for pars.VarsToScore (%d) and pars.VarType (%d).',...
      numel(pars.VarsToScore), numel(pars.VarType));
end

if nargin > 0
   if isfield(pars,name)
      pars = pars.(name);
   end
end

   % Helper function to isolate this part of parameters
   function [VarsToScore,VarType] = setScoringVars()
      % SETSCORINGVARS  Variables for video scoring are set here
      %
      %  [VarsToScore,VarType] = setScoringVars();
      
      % varsToScore = []; % Must be left empty if no videos to score
      varsToScore = {... % KUMC: "RC" project (MM)
         'Pellets';           % 1)
         'PelletPresent';     % 2)
         'Stereotyped';       % 3)
         'Outcome';           % 4)
         'Forelimb';          % 5)
      };

      % varType = []; % Must be left empty if no videos to score
      varType = [2 3 3 4 5];      % Should have same number as VarsToScore
                                  % NOTE: VarType will be added to by any
                                  %       Event variable that is 
                                  
      [VarsToScore,VarType] = prependEventVars(varsToScore,varType);
      
   end

   % Helper function that does the prepending
   function [toScore,type] = prependEventVars(vToScore,vType)
      % PREPENDEVENTVARS Pre-append VarType and VarsToScore based on values
      %     in nigeLab.defaults.Event('Name'); and
      %     nigeLab.defaults.Event('Fields').
      
      vName = nigeLab.defaults.Event('Name');
      vField = nigeLab.defaults.Event('Fields');
      evType = nigeLab.defaults.Event('EventType');
      
      fnames = fieldnames(evType);
      for ii = 1:numel(fnames)
         if strcmpi(evType.(fnames{ii}),'manual')
            vn = vName(ismember(lower(vField),lower(fnames{ii})));
            vToScore = [vn; vToScore]; %#ok<*AGROW>
            vType = [ones(1,numel(vn)), vType];
         end
      end
      
      % Assign output
      toScore = vToScore;
      type = vType;
   end
   
                              
end