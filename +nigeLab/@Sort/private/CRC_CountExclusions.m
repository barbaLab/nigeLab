function CRC_CountExclusions(obj,ch)
%% CRC_COUNTEXCLUSIONS Gets a total percentage of detected spikes excluded.

% Get units that do not belong to a cluster
restricted_by_radius = ~obj.Data.spk.include.cur{ch};
outlier = obj.Data.cl.num.class.cur{ch}==1;

% Get total number of units counted as potential spikes
total_n_spikes_detected = numel(obj.Data.spk.include.in{ch});

% Return the percent excluded
exc = sum(restricted_by_radius | outlier)/total_n_spikes_detected * 100;

% Update the label with this percentage
set(obj.Exclusions,'String',sprintf('Features (%0.3g%% excluded)',exc));

end