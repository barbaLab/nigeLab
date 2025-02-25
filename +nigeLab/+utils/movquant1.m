function quant_X = movquant1(X, p, n, step, dim, padding)
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
sX = size(X);

if nargin < 5 || isempty(dim)
    % operate across first non-singleton dimension; same default as medfilt1.
    dim = find(sX > 1, 1);
end


if nargin < 6 || isempty(padding)
    padding = 'zeropad';
end

N = sX(dim);
win_left_len = floor(n/2);
win_right_len = floor(n/2-0.5);
quant_X = zeros(size(X));

ii=1;

if strcmp(padding, 'zeropad')
    padconst = 0;
elseif strcmp(padding, 'truncate')
    padconst = nan;
end

X_ax_pad = [padconst * ones(win_left_len, 1); X(:); padconst * ones(win_right_len, 1)];

% Initial sorting
[sorted_win, sorted_win_idces] = sort(X_ax_pad(1:n));

% Calculate quantile value at first sample

N_win = length(sorted_win);

if p < 0.5/N_win
    quant_X(ii) = sorted_win(1);
elseif p > (N_win-0.5)/N_win
    quant_X(ii) = sorted_win(N_win);
else
    % simple linear interpolation between the two neighboring data
    idx1 = floor(N_win*p+0.5);
    x1 = (idx1-0.5)/N_win;
    y1 = sorted_win(idx1);
    x2 = (idx1+0.5)/N_win;
    y2 = sorted_win(idx1+1);
    quant_X(ii) = y1 + (y2-y1)*(p-x1)/(x2-x1);
end

% Now we only need to remove one element from the sorted array at each step
% and insert a new one at the correct position
iter = floor(2:step:N);
for jj = iter
    % 1. Remove the oldest element
    sorted_win_trimmed = sorted_win(sorted_win_idces ~= 1);
    sorted_win_idces_trimmed = sorted_win_idces(sorted_win_idces ~= 1);
    sorted_win_idces_trimmed = sorted_win_idces_trimmed - 1;
    % if isnan(sorted_win(sorted_win_idces == 1))
    %     numnan = numnan - 1;
    % end

    % 2. Insert the new entry at the right positions
    value_to_insert = X_ax_pad(jj+n-1);

    index_to_insert = find(sorted_win_trimmed > value_to_insert, 1);
    if isempty(index_to_insert)
        % Found new maximum

        sorted_win = [sorted_win_trimmed; value_to_insert];
        sorted_win_idces = [sorted_win_idces_trimmed; n];
    elseif index_to_insert == 1
        sorted_win = [value_to_insert; sorted_win_trimmed];
        sorted_win_idces = [n; sorted_win_idces_trimmed];
    else
        sorted_win = ...
            [sorted_win_trimmed(1:index_to_insert-1); value_to_insert; sorted_win_trimmed(index_to_insert:end)];
        sorted_win_idces = ...
            [sorted_win_idces_trimmed(1:index_to_insert-1); n; sorted_win_idces_trimmed(index_to_insert:end)];
    end

    % 3. Calculate quantile value


    if p < 0.5/N_win
        quant_X(jj) = sorted_win(1);
    elseif p > (N_win-0.5)/N_win
        quant_X(jj) = sorted_win(N_win);
    else
        % simple linear interpolation between the two neighboring data
        idx1 = floor(N_win*p+0.5);
        x1 = (idx1-0.5)/N_win;
        y1 = sorted_win(idx1);
        x2 = (idx1+0.5)/N_win;
        y2 = sorted_win(idx1+1);
        quant_X(jj) = y1 + (y2-y1)*(p-x1)/(x2-x1);
    end
end
end