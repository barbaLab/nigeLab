function CountExclusions(obj,ch)
%% COUNTEXCLUSIONS Gets a total percentage of detected spikes excluded.

% Get units that do not belong to a cluster
noise_spikes = obj.Data.class{ch}==1; % "1" is "OUT" cluster

% Get total number of units counted as potential spikes
total_n_spikes_detected = numel(obj.Data.class{ch});

% Return the percent excluded
exc = sum(noise_spikes)/total_n_spikes_detected * 100;

% Update the label with this percentage
set(obj.Exclusions,'String',sprintf('Features (%0.3g%% excluded)',exc));

end