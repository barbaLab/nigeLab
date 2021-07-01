function varargout = Video(varargin)
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
pars.UseVideoPromptOnEmpty = false;

% % % -- For Video Scoring -- % % %

pars.VidFilePath    = { ... % "Includes" for where videos might be. Stops after first non-empty path.
   'P:\foo\bar'
   };

% Unique key denotes the research key that will be used to identify and
% match videos with Blocks. It tells the system what Block's Meta fields to 
% use to find it's matching Videos. A good key might be 
% {'AnimalID','BlockID'}. E.g a block having AnimalID = A00 and
% BlockID = B00 will link all the videos whose name start with A00_B00
pars.UniqueKey.vars = {'AnimalID','Phase','RecDate'};
pars.UniqueKey.cat = '_';

% As in other customizable naming conventions, metadata can be acquired
% from the file name. 
pars.NamingConvention={'$AnimalID','$Phase','$RecDate','$CameraID','$Counter'};
pars.FileExt = '.MP4';
pars.Delimiter   = '_'; 

pars.SpecialMeta = struct;
pars.SpecialMeta.SpecialVars = {'VideoID'}; 

pars.SpecialMeta.VideoID.cat = '-';
pars.SpecialMeta.VideoID.vars = {'AnimalID','Phase','RecDate','CameraID'};

pars.IncludeChar='$';
pars.DiscardChar='~';

pars.GroupingVar = 'CameraID';
pars.IncrementingVar = 'Counter';

pars.VideoEventCamera = 'CamA';

pars.CustomSort = @nigeLab.utils.orderGoProVideos;

% % Information for "Trial Video" export
% pars.ROI.CamA.Width = 512;   % (Standardized) cropped frame width, in pixels
% pars.ROI.CamA.Height = 512;  % (Standardized) cropped frame height, in pixels
% % Note: KUMC Z620 workstation for running DeepLabCut seems to max out for
% %                 images of size 600 x 600.

pars.PreTrialBuffer = 0.25;  % Time before "trial" to start video frame for
                             % a given scoring "trial." It is useful to
                             % start at an earlier frame.
pars.PostTrialBuffer = 0.25; % Time in seconds after "trial" 

% % % -- For Video Alignment -- % % %
pars.Alignment_FS = struct('TDT',125,'RHD',100,'RHS',100);

pars.ValueShortcutFcn = @nigeLab.workflow.defaultVideoScoringShortcutFcn;
pars.VideoScoringStringsFcn = @nigeLab.workflow.defaultVideoScoringStrings;
pars.ForceToZeroFcn = @nigeLab.workflow.defaultForceToZeroFcn;
pars.ScoringHotkeyFcn = @nigeLab.workflow.defaultHotkeyFcn;
pars.ScoringHotkeyHelpFcn = @nigeLab.workflow.defaultHotkeyHelpFcn;

%% Error parsing (do not change)
% pars.HasVidStreams = ...
%    pars.HasVidStreams && ...
%    pars.HasVideo && ...
%    (~isempty(pars.VidStreamName));
% 
% if pars.HasVidStreams
%    dyVar = cellfun(@(x)x(2:end),pars.DynamicVars,'UniformOutput',false);
%    if ~ismember('CameraID',dyVar)
%       error(['nigeLab:' mfilename ':BadConfig'],...
%          '[DEFAULTS/VIDEO]: ');
%    end
%    
% end



%% Parse output
if nargin < 1
   varargout = {pars};
else
   varargout = cell(1,nargin);
   f = fieldnames(pars);
   for i = 1:nargin
      idx = ismember(lower(f),lower(varargin{i}));
      if sum(idx) == 1
         varargout{i} = pars.(f{idx});
      end
   end
end

%%
   % Helper function to isolate this part of parameters
   function [VarsToScore,VarType,VarDefs] = setScoringVars()
      % SETSCORINGVARS  Variables for video scoring are set here
      %
      %  [VarsToScore,VarType] = setScoringVars();
      
      % varsToScore = []; % Must be left empty if no videos to score
      varsToScore = {... % KUMC: "RC" project (MM)
         'Pellets';           % 1) [0,1,2,3,4,5,6,7,8,9+]
         'PelletPresent';     % 2) Yes / No
         'Stereotyped';       % 3) Yes / No
         'Outcome';           % 4) Successful / Unsuccessful
         'Door';              % 5) L / R
         'Forelimb';          % 6) L / R
      };

      % varType = []; % Must be left empty if no videos to score
      varType = [2 3 3 4 5 5];    % Should have same number as VarsToScore
                                  % NOTE: VarType will be added to by any
                                  %       Event variable that is 
      % Default values; again, should correspond 1-to-1 with elements of
      % varType and varsToScore. Set value to nan so that the shortcut will
      % not update its value when this is called even if the value is
      % unset.
      varDefs = [1, 1, 0, 0, nan, nan]; 
      
      [VarsToScore,VarType,VarDefs] = prependEventVars(varsToScore,varType,varDefs);
      
   end

   % Helper function that does the prepending
   function [toScore,type,def] = prependEventVars(vToScore,vType,vDefs)
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
            vDefs = [inf(1,numel(vn)), vDefs];
         end
      end
      
      % Assign output
      toScore = vToScore;
      type = vType;
      def = vDefs;
   end
   
                              
end