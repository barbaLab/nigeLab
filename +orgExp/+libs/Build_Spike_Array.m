function [peak_train,spikes] = Build_Spike_Array(data,ts,p2pamp,pars)
%% BUILD_SPIKE_ARRAY    Creates array of spike snippet waveforms
%
%   peak_train = BUILD_SPIKE_ARRAY(data,ts,pars)
%
%   --------
%    INPUTS
%   --------
%     data      :       1 x N filtered data vector, with artifact
%                       removed already.
%
%      ts       :       Spike times (samples)
%
%     p2pamp    :       Vector of spike amplitudes (should be same length
%                       as ts).
%
%     pars      :       Parameter struct from SPIKEDETECTCLUSTER. Contains
%                       the fields:
%
%       ->      w_pre   \\  Samples prior to peak detection for snippet.
%
%       ->      w_post  \\  Samples after peak detection for snippet.
%
%       ->      ls      \\  Total length of spike (samples).
%
%       ->      numpoints \\ Number of points in data.
%
%   --------
%    OUTPUT
%   --------
%   peak_train  :       Sparse vector of spike times and p2pamp for that
%                       spike.
%
%   spikes      :       Matrix, where each row is a new spike waveform
%                       snippet and each column is a subsequent sample.
%
% Adapted by: Max Murphy    v1.0    08/03/2017  Original version (R2017a)

%% 
nspk = numel(ts);
spikes = zeros(nspk,pars.ls+4);
data = [data(:,:), zeros(1, pars.w_post)]; % Add zeros in case of spikes at end of record
for ispk = 1:nspk                          % Eliminates artifacts
     try
         spikes(ispk,:) = data((ts(ispk)-double(pars.w_pre) - 1): ...
                               (ts(ispk)+double(pars.w_post) +2));

         if strcmp(pars.PKDETECT,'both')
             p2pamp(ispk) = max(spikes(ispk,:)) - ...
                                 min(spikes(ispk,:));
         end
     catch ME
         if strcmp(ME.identifier,'MATLAB:subsassigndimmismatch')
             clc;
             fprintf(1,['\nlength(spikes(ispk,:)) = %d\n'...
                 'length(data((spikesTime(ispk) - w_pre - 1):' ...
                 '(spikesTime(ispk) + w_post+2))) = %d\n'],...
                 numel(spikes(ispk,:)), ...
                 numel(data((ts(ispk) - pars.w_pre - 1): ...
                               (ts(ispk) + pars.w_post+2))));

             i1 = ts(ispk)-pars.w_pre-1;
             i2 = ts(ispk)+pars.w_post+2;

             fprintf(1,['\n\tls = %d' ...
                '\n\tispk = %d' ...
                '\n\tspikesTime(ispk) = %d' ...
                '\n\tw_pre = %d' ...
                '\n\tw_post = %d' ...
                '\n\tspikesTime(ispk)-w_pre-1 = %d', ...
                '\n\tspikesTime(ispk)+w_post+2 = %d\n\n'], ...
                pars.ls,ispk,ts(ispk),pars.w_pre,pars.w_post,i1,i2);

         end

         rethrow(ME);
     end
end

if strcmp(pars.PKDETECT,'both')
    % Reject spikes that don't meet the minimum peak-to-peak amplitude
    % criterion. This is probably implemented elsewhere, but the code
    % hadn't been working properly insofar as storing the amplitude values,
    % so I've crudely implemented it here. (-- MM 1/30/2017)

    ts  = ts(abs(p2pamp) > pars.P2PAMP); 
    spikes = spikes(abs(p2pamp) > pars.P2PAMP,:);
    p2pamp = p2pamp(abs(p2pamp) > pars.P2PAMP);
end

peak_train = sparse(ts,1,p2pamp,pars.npoints,1);

end