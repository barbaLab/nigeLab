function varargout = Event(varargin)
%% EVENT    Template for initializing parameters related to EVENTS
%
%  pars = nigeLab.defaults.Event(); Return full pars struct
%  --> Returns pars, a struct with the following fields:
%     * Name : Cell array of Event Names
%     * Fields : Cell array of Field names corresponding to pars.Name
%     * EventType : Struct "key" defining 'manual' and 'auto' Events
%
%  paramVal = nigeLab.defaults.Event('paramName'); % Return specific value
%
% By: MAECI 2018 collaboration (MM, FB)

%% Change values here
pars = struct;
% "Name" of Events
% pars.Name = {...    % Example A (RHS)
%    'Stim';            % 1)  Stimulation times and data
%    'Sync';            % 2)  Sync LED times
%    'User';            % 3)  User digital marker onsets
%    'LPellet';         % 4)  Left pellet beam break onsets
%    'LButtonDown';     % 5)  Left-button press onset
%    'LButtonUp';       % 6)  Left-button press offset
%    'RPellet';         % 7)  Right pellet beam break onsets
%    'RButtonDown';     % 8)  Right-button press onset
%    'RButtonUp';       % 9)  Right-button press offset
%    'Beam';            % 10) Reach beam break
%    'Nose';            % 11) Nose-poke beam break
%    'Epoch';           % 12) Onsets mid-trial epochs
%    'Reach';           % 13) 
%    'Grasp';           % 14)
%    'Support';         % 15)
%    'Complete';        % 16)
%    };        
pars.Name = {...        % Example B (RHD)
   'trial-running';     % 1) Trial running "HIGH" events
   'beam-break';        % 2) Beam break events
   'nose-poke';         % 3) Nose-poke beam break
   'Init';              % 4) "Initialize" trial (e.g. tone cue or whatever)
   'Nose';              % 5) Nose poke through reach slot scored onset
   'Reach';             % 6) Reach scored onset
   'Grasp';             % 7) Grasp scored onset
   'Support';           % 8) Support scored onset
   'Complete';          % 9) Complete scored onset
   };    
% pars.Name = {... % Example B (KUMC: "RC" project -- MM) Note: each 'Event' with different timestamps needs its own 'Events' element
%    'Reach';       % 1)
%    'Grasp';       % 2)
%    'Support';     % 3)
%    'Complete';    % 4)
%    };            
   
% This should match number of elements of Events:
% pars.Fields = {...    % Example A (RHS)
%    'Stim';            % 1) 
%    'DigEvents';       % 2)
%    'DigEvents';       % 3)
%    'DigEvents';       % 4)
%    'DigEvents';       % 5)
%    'DigEvents';       % 6)
%    'DigEvents';       % 7)
%    'DigEvents';       % 8)
%    'DigEvents';       % 9)
%    'DigEvents';       % 10) All beam breaks (Pellets, Beam, Nose) could be 
%    'DigEvents';       % 11) 'AnalogIO' as well?
%    'DigEvents';       % 12) Could be 'Notes' ?
%    'ScoredEvents';    % 13)
%    'ScoredEvents';    % 14)
%    'ScoredEvents';    % 15)
%    'ScoredEvents';    % 16)
%    };

pars.Fields = {...    % Example B (RHD) -- Audio task
   'DigEvents';       % 1)
   'DigEvents';       % 2)
   'DigEvents';       % 3)
   'ScoredEvents';    % 4)
   'ScoredEvents';    % 5)
   'ScoredEvents';    % 6)
   'ScoredEvents';    % 7)
   'ScoredEvents';    % 8)
   'ScoredEvents';    % 9)
   };

% pars.Fields = {...   % KUMC: "RC" project (MM)
%    'ScoredEvents';   % 1) % Should match one of the elements from
%    'ScoredEvents';   % 2) % defaults.Block cell array "Fields"
%    'ScoredEvents';   % 3)
%    'ScoredEvents';   % 4)
%    };

% Key that defines whether events are 'manual' (e.g. video scoring) or 
% 'auto' (e.g. parsed from stream in some way). Should have one entry for
% any unique entry to 'pars.Fields'; "extra" keys are okay. Any data that
% will have video scoring must have at least one key with the 'manual' type
% included in 'pars.Fields'.

% pars.EventType = struct(... % KUMC: "RC" project (MM)
%    'ScoredEvents','manual');

% pars.EventType = struct(... % Example A
%    'ScoredEvents','manual',...
%    'DigEvents','auto',...
%    'Stim','auto');

pars.EventType = struct(... % Example B
   'ScoredEvents','manual',...
   'DigEvents','auto');

% For automatic detection

% pars.TrialDetectionInfo = struct(... % For sync using parsed 'Paw_Likelihood' (RC)
%    'Field','VidStreams',...
%    'Source','Front',... % "source camera" (unused for "non-VidStreams")
%    'Name','Paw_Likelihood',...
%    'Debounce',0.250,...  % Debounce time (seconds)
%    'Threshold',0.6,...   % Threshold for ( > value) to HIGH
%    'Type','Rising'); % Can be 'Rising', 'Falling', 'All' (edge transition type)
%                      % Can also be 'Level' for analog value changes in discrete steps
% pars.EventDetectionType = []; % For RC

pars.MaxTrialDistance = 1.5; % Maximum time between within-trial events

% pars.TrialDetectionInfo = struct(... % For sync using LED (Example A)
%    'Field','DigIO',...
%    'Name','TrialRunning',...
%    'Source',[],...
%    'Debounce',0.250,... % debounce time (seconds)
%    'Threshold',0.5,...  % threshold for > value --> HIGH
%    'Type','Rising');
% pars.EventDetectionType = {... % Example A (RHS)
%    'Rising';    % 1)
%    'Rising';    % 2) 
%    'Rising';    % 3)
%    'Falling';   % 4)
%    'Falling';   % 5)
%    'Rising';    % 6)
%    'Falling';   % 7)
%    'Falling';   % 8)
%    'Rising';    % 9)
%    'Falling';   % 10)
%    'Falling';   % 11)
%    'Level';     % 12) (skip 13-16 because not 'auto' field)
%    };
% pars.EventSource = {... % Example A (RHS)
%    'Channels';   % 1) 'Stim' is associated with channels
%    'Streams';    % 2) 
%    'Streams';    % 3)
%    'Streams';    % 4)
%    'Streams';    % 5)
%    'Streams';    % 6)
%    'Streams';    % 7)
%    'Streams';    % 8)
%    'Streams';    % 9)
%    'Streams';    % 10)
%    'Streams';    % 11)
%    'Streams';    % 12) (skip 13-16 because not 'auto' field)
%    };
pars.TrialDetectionInfo = struct(... % For sync using LED (Example B)
   'Field','DigIO',...
   'Name','trial-running',...
   'Source',[],...
   'Debounce',0.100,...% Used in parsing other 'auto' events as well
   'Threshold',0.5,... % Used in parsing other 'auto' events as well
   'Type','Rising');
pars.EventDetectionType = {... % Example B (RHD)
   'Falling';    % 1)
   'Rising';     % 2) 
   'Rising';     % 3) (skip 4-7 because not 'auto' fields)
   };
pars.EventSource = {...
   'Streams';    % 1)
   'Streams';    % 2) 
   'Streams';    % 3) (skip 4-7 because not 'auto' fields)
   };
pars.UseAutoAsDefaultScoredEvent = {... % Example B (RHD)
   'Complete'; ... % 1) trial-running already related to special "Trial" field
   'Reach'; ...    % 2) beam-break
   'Init'          % 3) nose-poke: should be essentially same as trial-running
};

%% Error parsing (do not change)
% Check that number of elements of Name matches that of Fields
if numel(pars.Name) ~= numel(pars.Fields)
   error('Dimension mismatch for pars.Events (%d) and pars.Fields (%d).',...
      numel(pars.Name), numel(pars.Fields));
end

% Check that the appropriate event "keys" exist
u = unique(pars.Fields);
f = fieldnames(pars.EventType);
idx = find(~ismember(u,f),1,'first');
if ~isempty(idx)
   error('Missing %s EventType key (should be ''manual'' or ''auto'')', u{idx});
end

% Check that entries of pars.EventType are valid
nAuto = 0;
for iF = 1:numel(f)
   if ~ismember(lower(pars.EventType.(f{iF})),{'manual','auto'})
      error('Bad EventType (%s): ''%s''. Must be ''manual'' or ''auto''.',...
         f{iF},pars.EventType.(f{iF}));
   elseif strcmpi(pars.EventType.(f{iF}),'auto')
      nAuto = nAuto + sum(ismember(pars.Fields,f{iF}));
   end
end

% Check to make sure that there are the right number of elements in
% 'EventDetectionType'
if numel(pars.EventDetectionType) ~= nAuto
   error(['Invalid number of elements of pars.EventDetectionType (%g): '...
          'should be %g based on pars.Fields + pars.EventType'],...
          numel(pars.EventDetectionType));
end

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
                              
end