function pars = Event()
%% EVENT    Template for initializing parameters related to EVENTS
%
%   pars = nigeLab.defaults.Event;
%
% By: MAECI 2018 collaboration (MM, FB)

%%
pars = struct;
% Just some ideas for now:
pars.Events = {...
   'Stim';           % 1)  Stimulation times and data
   'Sync';           % 2)  Sync LED times
   'User';           % 3)  User digital marker onsets
   'LPellet';        % 4)  Left pellet beam break onsets
   'LButtonDown';    % 5)  Left-button press onset
   'LButtonUp';      % 6)  Left-button press offset
   'RPellet';        % 7)  Right pellet beam break onsets
   'RButtonDown';    % 8)  Right-button press onset
   'RButtonUp';      % 9)  Right-button press offset
   'Beam';           % 10) Reach beam break
   'Nose';           % 11) Nose-poke beam break
   'Epoch';          % 12) Onsets mid-trial epochs
   };            
   
% This should match number of elements of Events:
pars.Fields = {...
   'Stim';        % 1) 
   'Video';       % 2)
   'DigIO';       % 3)
   'DigIO';       % 4)
   'DigIO';       % 5)
   'DigIO';       % 6)
   'DigIO';       % 7)
   'DigIO';       % 8)
   'DigIO';       % 9)
   'DigIO';       % 10) All beam breaks (Pellets, Beam, Nose) could be 
   'DigIO';       % 11) 'AnalogIO' as well?
   'DigIO';       % 12) Could be 'Notes' ?
   };
        
%% DO ERROR PARSING
if numel(pars.Events) ~= numel(pars.Fields)
   error('Dimension mismatch for pars.Events (%d) and pars.Type (%d).',...
      numel(pars.Events), numel(pars.Fields));
end
               
                              
end