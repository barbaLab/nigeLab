function quant_X = mymovquant(X, p, n)
%% MOVQUANT - calculate moving quantile
%   Input parameters:
%      X - N-dimensional array
%      p - Quantile to calculate. Must be between 0 and 1 (both included).
%      n - Width of the moving window
%      step - samples to skip to center the window (pitch of the moving window)
%      dim - dimension to operate across. Default: first non-singleton dimension of X.
%      nanflag - 'includenan' (default): if there is a NaN in the moving window, NaN is also
%                 returned for the quantile. 'omitnan': if there is a NaN in the moving window,
%                 it is omitted for the quantile calculation, and a NaN is only returned for
%                 the quantile if there are no data available at all.
%      padding - 'zeropad' (default): pad both ends of the signal with zero. 'truncate': pad
%                 both ends of the signal with NaN. The resulting output depends on the nanflag
%                 provided.
%
% Eike Petersen, December 2020.
% Modified by Tommaso Lambresa 2024


quant_X = zeros(size(X));
remainder = mod(length(X), n);
num_windows = floor(length(X) / n)+1;
X_ax_pad = [X; zeros(n - remainder,1)];

% Reshape the signal into a matrix where each column is a window
X_matrix = reshape(X_ax_pad', n, num_windows);

% Compute the quantile for each column
quant = quantile(X_matrix, p, 1);  
max_Xwin = max(X_matrix,[],1);
critical_values = find(max_Xwin == quant); % sampling frequency too small so the quantile value is the last of each window
% Replace the last value with the last but one
if ~isempty(critical_values)
    data2sort = X_matrix(:,critical_values);
    sorted_win = sort(data2sort);
    quant(critical_values)=sorted_win(end-1,:);
end


quant_vector = repmat(quant, n, 1);  % Repeat each quantile value for each sample in the window
quant_vector = quant_vector(:);  % Convert to a row vector

quant_X = quant_vector(1:length(X));
end