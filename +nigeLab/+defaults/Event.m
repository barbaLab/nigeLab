function varargout = Event(varargin)
%% EVENT    Template for initializing parameters related to EVENTS
%
%  pars = nigeLab.defaults.Event(); Return full pars struct
%  --> Returns pars, a struct with one substructure for each declared Event
%  Typical Example to configure nigelab to extraxct Trials create a Trials
%  struct with the following fields: 
%       Source, the name(or partial name) of the Stream to use in the
%               detection
%       DetectionType, Rising (edge), Falling (edge) or Both
%       Threshold, optional. Threshold value to find trials
%       Debounce, optional. Debouncing value for digital triggers
%       Tag, optional. A shorter name for the event.
%       MinEvtDistance, optional. Minimum event distance in ms.

%% Change values here
pars = struct;


pars.BeginTrial = struct('Source','trial-running',...
                    'DetectionType','Rising',...
                    'Debounce',0,...
                    'Tag','BTrial');
                
pars.EndTrial = struct('Source','trial-running',...
                        'DetectionType','Falling',...
                        'Debounce',0.1,...
                        'Tag','BTrial');

% Specify here the Events Names used to build the Trial field e.g 
% {'BeginTrial','EndTrial'} will result in a Trial field made of a Nx2
% matrix with all the timestamps of BeginTrial in the first column and
% EndTrial in the second.
pars.Trial.Fields       = {'BeginTrial','EndTrial'};
 pars.Trial.MinDistance = .5;      




%% Error parsing (do not change)

AllFields = {'Source','DetectionType','Threshold','Debounce','Tag','MinEvtDistance'};

Names = setdiff(fields(pars),'Trial');
pars.EvtNames = Names;
for f = Names(:)'
    for ff = AllFields
        if ~isfield(pars.(f{:}),ff{:})
            pars.(f{:}).(ff{:}) = [];
        end
    end
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