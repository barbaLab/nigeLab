function [output, varargout] = SUPPR_logLIRA(signal, pars)
% SUPPR_logLIRA(signal, stimIdxs, sampleRate, varargin)
%logLIRA LOGarithmic Linear Interpolation for Removal of Artifacts.
%   output = LOGLIRA(signal, stimIdxs, sampleRate) returns the input signal
%   without the artifacts caused by electrical stimulation. The stimIdxs
%   are the indexes of stimulation onsets. The sampleRate should be expressed
%   in Hz.
%
%   [output, blankingPeriods] = LOGLIRA(signal, stimIdxs, sampleRate) returns a vector
%   containing all the blanking periods determined by the algorithm for each stimulus
%   onset, in samples.

%   [output, blankingPeriods, skippedTrials] = LOGLIRA(signal, stimIdxs, sampleRate) returns
%   the indices of the trials that the algorithm skipped. Such trials are blanked completely.
%   If none, an empty vector is returned.
%
%   [...] = LOGLIRA(..., blankingPeriod) specifies the minimum time after the
%   stimulus onset that is discarded. It must be expressed in seconds. By
%   default it is 1 ms.
%
%   [...] = LOGLIRA(..., 'PARAM1', val1, 'PARAM2', val2, ...) specifies optional
%   parameter name/value pairs. Parameters are:
%
%       'SaturationVoltage' - It specifies the recording system operating range
%                             in mV as specified in the datasheet. This is useful
%                             to properly detect saturation. Choices are:
%                   default - 95% of the input signal absolute value maximum.
%                1x1 scalar - The operating range is assumed to be symmetric with
%                             respect to 0.
%          1x2 or 2x1 array - The operating range is the specified one.
%
%      'MinClippedNSamples' - It is the minimum number of consecutive clipped samples
%                             to mark the artifact as a clipped one. It should be a
%                             1x1 positive integer. By default, it is 2.
%
%              'RandomSeed' - It is the random seed provided to Matlab's Random
%                             Number Generator to ensure reproducibility. It must
%                             be a positive integer.

    %% 0) Check and parse input arguments
    warning('off', 'signal:findpeaks:largeMinPeakHeight');

    pars.saturationVoltage = pars.saturationVoltage * max(abs(signal)) / 1e3; %setting the saturation voltage

    validNumPosCheck = @(x) isnumeric(x) && (x >= 0);

    parser = inputParser();
    addRequired(parser, 'signal', @isnumeric);
    addRequired(parser, 'stimIdxs', @(x) isnumeric(x) && all(x > 0));
    addRequired(parser, 'sampleRate', validNumPosCheck);
    addOptional(parser, 'blankingPeriod', 1e-3, validNumPosCheck);
    addParameter(parser, 'saturationVoltage', 0.95 * max(abs(signal)) / 1e3, @isnumeric);
    addParameter(parser, 'minClippedNSamples', [], validNumPosCheck);
    addParameter(parser, 'randomSeed', randi(1e5), @(x) x >= 0);

    parse(parser, signal, pars.stimIdxs, pars.sampleRate, pars.blankingPeriod, pars.saturationVoltage, pars.minClippedNSamples, pars.randomSeed);

    signal = parser.Results.signal;
    stimIdxs = parser.Results.stimIdxs;
    sampleRate = parser.Results.sampleRate;
    blankingPeriod = parser.Results.blankingPeriod;
    saturationVoltage = parser.Results.saturationVoltage;
    minClippedNSamples = parser.Results.minClippedNSamples;
    randomSeed = parser.Results.randomSeed;

    output = signal;
    varargout{1} = zeros(size(stimIdxs));
    varargout{2} = false(size(stimIdxs));

    rng(randomSeed);

    waitbarFig = waitbar(0, 'Starting...', 'Name', 'logLIRA');

    %% 1) Find signal IAI and check if artifacts requires correction
    minArtifactDuration = 0.04;
    SARemovalDuration = 0.002;
    checkDuration = 0.005;
    checkThreshold = 30;
    checkStdThreshold = 2;

    blankingNSamples = round(blankingPeriod * sampleRate);
    IAI = [diff(stimIdxs), length(signal) - stimIdxs(end)];

    checkNSamples = round(checkDuration * sampleRate);
    checkSamples = repmat(0:(checkNSamples - 1), [1, numel(stimIdxs)]);
    artifactSamples = reshape(repmat(stimIdxs, [checkNSamples, 1]), 1, []);

    % Pad signal begin and end
    paddedSignal = signal;
    if stimIdxs(1) < checkNSamples
        padSize = checkNSamples - stimIdxs(1) + 1;
        padVector = ones(1, padSize) * paddedSignal(1);
        paddedSignal = [padVector, paddedSignal];
        artifactSamples = artifactSamples + padSize;
    end

    if IAI(end) < checkNSamples
        padSize = checkNSamples - IAI(end) + 1;
        padVector = ones(1, padSize) * paddedSignal(end);
        paddedSignal = [paddedSignal, padVector];
    end
    
    preArtifacts = paddedSignal(artifactSamples - flip(checkSamples) - 1);
    preArtifacts = reshape(preArtifacts, checkNSamples, []);
    postArtifacts = paddedSignal(artifactSamples + checkSamples + blankingNSamples);
    postArtifacts = reshape(postArtifacts, checkNSamples, []);

    hasArtifact = abs(preArtifacts(end, :) - postArtifacts(1, :)) > checkThreshold | ...
                    std(postArtifacts, 0, 1) > checkStdThreshold * std(preArtifacts, 0, 1) | ...
                    blankingNSamples >= IAI;

    SARemovalNSamples = round(SARemovalDuration * sampleRate);
    SARemovalData = zeros(numel(stimIdxs), SARemovalNSamples);
    SARemovalSamples = zeros(numel(stimIdxs), SARemovalNSamples);

    %% 2) Clean each artifact iteratively
    minArtifactNSamples = round(minArtifactDuration * sampleRate) + blankingNSamples;

    for idx = 1:numel(stimIdxs)
        % Identify samples to clean
        data = signal((1:IAI(idx)) + stimIdxs(idx) - 1);

        if hasArtifact(idx)
            endIdx = [];
            if minArtifactNSamples < IAI(idx) 
                smoothData = smoothdata(data(minArtifactNSamples:end), 'movmean', round(5 * 1e-3 * sampleRate));
                endIdx = find(abs(smoothData - median(data(minArtifactNSamples:end))) < 1, 1) + minArtifactNSamples - 1;
            end
                
            endIdx = min([IAI(idx), endIdx]);

            % Find artifact shape
            [artifact, blankingNSamples] = fitArtifact(data(1:endIdx), sampleRate, blankingPeriod, ...
                'saturationVoltage', saturationVoltage, 'minClippedNSamples', minClippedNSamples);
        else
            blankingNSamples = round(blankingPeriod * sampleRate);
            artifact = data(1:blankingNSamples);
        end

        if ~isempty(blankingNSamples) && (length(artifact) - SARemovalNSamples) > blankingNSamples
            % Get data for secondary artifacts removal after blanking
            SARemovalSamples(idx, :) = (1:SARemovalNSamples) + blankingNSamples;
            SARemovalData(idx, :) = data(SARemovalSamples(idx, :)) - artifact(SARemovalSamples(idx, :));
            varargout{1}(idx) = blankingNSamples;
        elseif ~hasArtifact(idx)
            varargout{1}(idx) = blankingNSamples;
        else
            artifact = data;
            varargout{1}(idx) = length(artifact);
            varargout{2}(idx) = true;
        end

        % Correct artifact to avoid discontinuities
        if ~hasArtifact(idx) || IAI(idx) > endIdx
            correctionX = [0, length(artifact) + 1];
            correctionY = [output(correctionX(1) + stimIdxs(idx) - 1), output(correctionX(end) + stimIdxs(idx) - 1)];
            correction = interp1(correctionX, correctionY, 1:length(artifact), 'linear');
        else
            correction = output(stimIdxs(idx) - 1) * ones(1, length(artifact));
        end

        % Update output signal
        output((1:length(artifact)) + stimIdxs(idx) - 1) = data(1:length(artifact)) - artifact + correction;

        % Update progress bar
        waitbar(idx / numel(stimIdxs), waitbarFig, 'Removing stimulation artifacts...');
    end

    varargout{2} = find(varargout{2} == true);
    if ~isempty(varargout{2})
        warning('logLIRA:logLIRA:skippedTrials', 'Some trials were skipped and blanked completely: %d/%d.', numel(varargout{2}), numel(stimIdxs));
    end

    %% 3) Remove secondary artifacts after blanking
    waitbar(0, waitbarFig, 'Mitigating secondary artifacts...');
    
    minClusterSize = 100;
    rng(randomSeed);
    
    warning('off', 'all');
    clusterCommand = "run_umap(SARemovalData, 'metric', 'correlation', 'cluster_detail', 'very low', 'verbose', 'none', 'randomize', 'false')";
    [~, ~, ~, labels, ~] = evalc(clusterCommand);
    
    for clusterIdx = 1:max(labels)
        if sum(labels == clusterIdx) >= minClusterSize
            selectedSARemovalSamples = SARemovalSamples(labels == clusterIdx, :) + stimIdxs(labels == clusterIdx)' - 1;
            selectedSARemovalSamples = reshape(selectedSARemovalSamples', [1, numel(selectedSARemovalSamples)]);
            
            % fig = figure();
            % tiledlayout(3, 1);
            % nexttile();
            % plot(reshape(output(selectedSARemovalSamples), [], sum(labels == clusterIdx)));
            % nexttile();
            % plot(mean(SARemovalData(labels == clusterIdx, :), 1));
            % nexttile();
            % plot(reshape(output(selectedSARemovalSamples) - repmat(mean(SARemovalData(labels == clusterIdx, :), 1), [1, sum(labels == clusterIdx)]), [], sum(labels == clusterIdx)));
            % uiwait(fig);

            output(selectedSARemovalSamples) = output(selectedSARemovalSamples) - repmat(mean(SARemovalData(labels == clusterIdx, :), 1), [1, sum(labels == clusterIdx)]);
            waitbar(clusterIdx / max(labels), waitbarFig, 'Mitigating secondary artifacts...');
        end
    end

    close(waitbarFig);
    warning('on', 'all');
end