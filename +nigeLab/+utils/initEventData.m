function varargout = initEventData(nEvent,nSnippet,type)
%INITEVENTDATA   [var1,var2,...] = utils.initEventData(nEvent,nSnippet);
%
%  [var1,...,varK] = nigeLab.utils.initEventData(nEvent,nSnippet);
%  --> `nEvent` is a scalar integer that is the total number of events
%                 * This is the total number of rows in the 'Event' file
%
%  --> `nSnippet` is a scalar integer that is the total number of snippet
%                 columns. For example, a spike waveform with 30 samples
%                 would set this value to 30. 'EventTimes' files should set
%                 this to zero or one (there will always be one "snippet"
%                 column so that all 'Event' DiskData files have at least 5
%                 columns; if unused, the snippet column just contains
%                 NaNs)
%                 * The number of columns in the 'Event' file equals 
%                    >> max(nSnippet+4, 5) 
%
%  [var1,...,varK] = nigeLab.utils.initEventData(nEvent,nSnippet,type);
%  --> `type` is a scalar integer:
%     * 0 : default value (e.g. Channels events)
%     * 1 : EventTimes events (e.g. 'Reach' or 'Init')
%     * 2 : "Special" file (e.g. 'Header')
%
%  [var1,...,varK] = nigeLab.utils.initEventData(nEvent,nSnippet,ts);
%  --> `ts` is [nEvent x 1] column vector of event times (seconds, relative
%        to NEURAL record onset).
%     * If `ts` is column vector, it is duplicated as the times for all
%        output variables to be initialized.
%     * If `ts` is a matrix, then as long as its # of rows match nEvent and
%        the number of columns matches or exceeds the number of requested 
%        output arguments, each output will be assigned the corresponding
%        column of `ts` during initialization.
%        + If there are more columns of `ts` than output arguments, excess
%           columns of `ts` are ignored.
%
%  -- Outputs --
%  Each requested output argument generates an initialized data array that
%  should be saved to the 'Event' DiskData "data" property
%
%  # Example: Parse Trial Onsets #
%        ```
%           import nigeLab.utils.*; % Import utility functions
%
%           % Import stream data for "trial-running" indicator:
%           stream = getStream(blockObj,'trial-running'); 
%           data = stream.data;
%           fs = stream.fs;
%
%           % Parameterize event detection:
%           thr = 0.5;        % Threshold to binarize stream signal
%           db = 0.100;       % Debounce time (seconds)
%
%           % Use imported `nigeLab.utils.binaryStream2ts` to get times:
%           ts_on = binaryStream2ts(data,fs,thr,'rising',db);
%           ts_off = binaryStream2ts(data,fs,thr,'falling',db);
%
%           % Make sure that trial "onsets" and "offsets" are matched,
%           % using `nigeLab.utils.matchEpochStartStopTimes`:
%           T = matchEpochStartStopTimes(ts_on,ts_off);
%        
%           % Initialize event data using `nigeLab.utils.initEventData`:
%           [InitData,CompleteData] = initEventData(100,1,T);
%
%           % Assign values to the correct event indices:
%           initIndex = getEventsIndex(blockObj,'ScoredEvents','Init');
%           compIndex = getEventsIndex(blockObj,'ScoredEvents','Complete');
%           blockObj.Events.ScoredEvents(initIndex).data = InitData;
%           blockObj.Events.ScoredEvents(compIndex).data = CompleteData;
%        ```

% Parse input
nargo = max(nargout,1);
if nargin < 3
   type = 0;
   ts = nan(nEvent,nargo);
elseif numel(type) == nEvent
   % Ensure that timestamp values are a column vector:
   ts = reshape(type,nEvent,1);
   ts = repmat(ts,1,nargo);
   type = 1;
elseif (size(type,1) == nEvent) && (size(type,2) >= nargo)
   ts = type;
   type = 1;
else
   ts = nan(nEvent,nargo);
end

% Do this way so either nSnippet of 0 or 1 works (must have at least 5 col)
nCol = max(nSnippet+4,5); 
varargout = cell(nargo,1);
for iV = 1:nargo
   varargout{iV} = nan(nEvent,nCol);
   varargout{iV}(:,1) = type;
   % Initialize 'tag' (3rd column) as mask that indicates the values should
   % be used: since they will be defaulted to "auto" or "NaN" values, then
   % this should only be flipped to ones (true) when the value
   % corresponding to that specific trial has been scored. Otherwise, this
   % vector can serve as an indicator that the value has never been scored,
   % so that if `doEventDetection` is re-run, it is okay to overwrite (the
   % non-scored) value since we won't be ruining somebody's behavior
   % scoring...
   varargout{iV}(:,3) = zeros(nEvent,1);
   varargout{iV}(:,4) = ts(:,iV); % Fourth column is timestamps
   if type == 1
      varargout{iV}(:,2) = (1:nEvent).';
   end
end


end