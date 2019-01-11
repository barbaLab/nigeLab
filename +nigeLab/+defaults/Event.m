function pars = Event()
%% EVENT    Template for initializing parameters related to EVENTS
%
%   pars = nigeLab.defaults.Event;
%
% By: MAECI 2018 collaboration (MM, FB)

%%
pars = struct;
% Just some ideas for now:
pars.Events = {'Stim'; ...          % Stimulation times and data
               'Sync'; ...          % Sync LED times
               'User'; ...          % User digital marker onsets
               'LPellet'; ...       % Left pellet beam break onsets
               'LButtonDown'; ...   % Left-button press onset
               'LButtonUp'; ...     % Left-button press offset
               'RPellet'; ...       % Right pellet beam break onsets
               'RButtonDown'; ...   % Right-button press onset
               'RButtonUp'; ...     % Right-button press offset
               'Beam'; ...          % Reach beam break
               'Nose'; ...          % Nose-poke beam break
               'Epoch'};            % Onsets mid-trial epochs
 
pars.Type = [4, 5, 3, 5, 5, 5, 5, 5, 5, 5, 5, 3];
            
pars.TypeID = {{'value'}; ...                         % Type 1
               {'value', 'tag'}; ...                  % Type 2
               {'value', 'tag', 'ts'}; ...            % Type 3
               {'value', 'tag', 'ts', 'snippet'}; ... % Type 4
               {'value', 'ts'}};                      % Type 5
               
if numel(pars.Events) ~= numel(pars.Type)
   error('Dimension mismatch for pars.Events (%d) and pars.Type (%d).',...
      numel(pars.Events), numel(pars.Type));
end
               
                              
end