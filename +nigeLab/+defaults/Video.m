function pars = Video(name)
%% VIDEO  Template for initializing parameters related to experiment trigger synchronization
%
%  pars = nigeLab.defaults.Video();
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

% Stream Names: Most-flexible naming
% pars.VidStreamName = []; % For "no video streams" case
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
pars.user = 'MM'; % Who did the scoring?
pars.vars = {'Trial','Reach','Grasp','Support','Pellets','PelletPresent','Outcome','Forelimb'}; % Variables to score
pars.varType = [0,1,1,1,2,3,4,5]; % must have same number of elements as VARS (Variable "Types" for behaviorData table)
                              % options: 
                              % -> 0: Trial "onset" guess 
                              % -> 1: Timestamps 
                              % -> 2: Counts (0 - 9) 
                              % -> 3: No (0) or Yes (1)
                              % -> 4: Unsuccessful (0) or Successful (1)
                              % -> 5: Left (0) or Right (1)

%% THESE PARAMETERS STAY CONSTANT PROBABLY
% Paths information
pars.File = [];

% Metadata parsing
pars.Delimiter = '_'; % Break filename "variables" by this
pars.IncludeChar = '$'; % Include data from these variables
pars.ExcludeChar = '&'; % Exclude data from these variables
pars.Meta = [];

%% PARSE INPUT (DON'T CHANGE)
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

if nargin > 0
   if isfield(pars,name)
      pars = pars.(name);
   end
end
                              
end