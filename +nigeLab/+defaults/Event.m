function pars = Event()
%% EVENT    Template for initializing parameters related to EVENTS
%
%   pars = nigeLab.defaults.Event;
%
% By: MAECI 2018 collaboration (MM, FB)

%%
pars = struct;
% Just some ideas for now:
% pars.Events = {...    % Example A (RHS)
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
%    };           
pars.Events = {... % Example B (KUMC: "RC" project -- MM) Note: each 'Event' with different timestamps needs its own 'Events' element
   'Reach';       % 1)
   'Grasp';       % 2)
   'Support';     % 3)
   'Complete';    % 4)
   'Sync';        % 5)
   };            
   
   
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
%    };

pars.Fields = {...   % KUMC: "RC" project (MM)
   'ScoredEvents';   % 1)
   'ScoredEvents';   % 2)
   'ScoredEvents';   % 3)
   'ScoredEvents';   % 4)
   'ScoredEvents';   % 5)
   };

pars.VarsToScore = {... % KUMC: "RC" project (MM)
   'Reach';             % 1) 
   'Grasp';             % 2)
   'Support';           % 3)
   'Complete';          % 4)
   'Pellets';           % 5)
   'PelletPresent';     % 6)
   'Stereotyped';       % 7)
   'Outcome';           % 8)
   'Forelimb';          % 9)
};

pars.VarType = [1 1 1 1 2 3 3 4 5]; % Should have same number as VarsToScore
        
%% DO ERROR PARSING FOR NUMBER OF ELEMENTS IN FIELDS AND EVENTS
if numel(pars.Events) ~= numel(pars.Fields)
   error('Dimension mismatch for pars.Events (%d) and pars.Fields (%d).',...
      numel(pars.Events), numel(pars.Fields));
end
      
if numel(pars.VarsToScore) ~= numel(pars.VarType)
   error('Dimension mismatch for pars.VarsToScore (%d) and pars.VarType (%d).',...
      numel(pars.VarsToScore), numel(pars.VarType));
end
                              
end