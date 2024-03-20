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
%% INSTALL Script to install logLIRA on first-time use. Adding the required add-ons UMAP.
installLogLIRA();

%% 0) Check and parse input arguments
warning('off', 'signal:findpeaks:largeMinPeakHeight');

%     pars.saturationVoltage = pars.saturationVoltage * max(abs(signal)) / 1e3; %setting the saturation voltage
%
%     validNumPosCheck = @(x) isnumeric(x) && (x >= 0);
%
%     parser = inputParser();
%     addRequired(parser, 'signal', @isnumeric);
%     addRequired(parser, 'stimIdxs', @(x) isnumeric(x) && all(x > 0));
%     addRequired(parser, 'sampleRate', validNumPosCheck);
%     addOptional(parser, 'blankingPeriod', 1e-3, validNumPosCheck);
%     addParameter(parser, 'saturationVoltage', 0.95 * max(abs(signal)) / 1e3, @isnumeric);
%     addParameter(parser, 'minClippedNSamples', [], validNumPosCheck);
%     addParameter(parser, 'randomSeed', randi(1e5), @(x) x >= 0);
%
%     parse(parser, signal, pars.stimIdxs, pars.sampleRate, pars.blankingPeriod, pars.saturationVoltage, pars.minClippedNSamples, pars.randomSeed);
%
%     signal = parser.Results.signal;
%     stimIdxs = parser.Results.stimIdxs;
%     sampleRate = parser.Results.sampleRate;
%     blankingPeriod = parser.Results.blankingPeriod;
%     saturationVoltage = parser.Results.saturationVoltage;
%     minClippedNSamples = parser.Results.minClippedNSamples;
%     randomSeed = parser.Results.randomSeed;

stimIdxs = pars.stimIdxs;
sampleRate = pars.sampleRate;
blankingPeriod = pars.blankingPeriod;
saturationVoltage = pars.saturationVoltage;
minClippedNSamples = pars.minClippedNSamples;
randomSeed = pars.randomSeed;

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


    function [peakIdx, varargout] = findArtifactPeak(data, sampleRate, blankingPeriod, varargin)
        %FINDARTIFACTPEAK Find peak location and detect wether the signal is clipped or not.
        %
        %   peakIdx = FINDARTIFACTPEAK(data, sampleRate, blankingPeriod) returns
        %   the index where the peak of the artifact is found. The peak is defined as the
        %   last point after which it becomes possible to recover data. Blanking period
        %   should be expressed in seconds.
        %
        %   [peakIdx, isClipped] = FINDARTIFACTPEAK(data, sampleRate, blankingPeriod)
        %   returns a boolean flag true if data are clipped, false otherwise.
        %
        %   [peakIdx, isClipped, polarity] = FINDARTIFACTPEAK(data, sampleRate, blankingPeriod)
        %   returns the polarity of the artifact. A positive polarity means that
        %   the signal decays towards the baseline from larger values, while a
        %   negative polarity means that the signal goes back to baseline from
        %   smaller values.
        %
        %   [...] = FINDARTIFACTPEAK(..., saturationVoltage) specifies the recording
        %   system operating range in mV as specified in the datasheet. This is useful
        %   to properly detect saturation. If a scalare is provided, then the operating
        %   range is assumed to be symmetric with respect to 0, otherwise specify lower
        %   and upper boundaries through an array. By default, 95% of the input data absolute
        %   value maximum is employed.
        %
        %   [...] = FINDARTIFACTPEAK(..., saturationVoltage, minClippedNSamples)
        %   specifies the minimum number of consecutive clipped samples to mark the
        %   artifact as a clipped one. It should be a 1x1 positive integer. By default,
        %   it is 2.

        %% 0) Check and parse input arguments
        if nargin < 3
            throw(MException('logLIRA:findArtifactPeak:NotEnoughParameters', 'The parameters data, sampleRate, and blankingPeriod are required.'));
        end

        if nargin < 4 || isempty(varargin{1})
            saturationVoltage = 0.95 * max(abs(data)) / 1e3;
        else
            saturationVoltage = varargin{1};
        end

        if nargin < 5 || isempty(varargin{2})
            minClippedNSamples = 2;
        else
            minClippedNSamples = varargin{2};
        end

        if isscalar(saturationVoltage)
            saturationVoltage = [-saturationVoltage, saturationVoltage];
        end

        saturationVoltage = [min(saturationVoltage), max(saturationVoltage)] * 1e3;

        %% 1) Find peakIdx
        blankingSamples = 1:round(blankingPeriod * sampleRate);

        maxValue = max(data(blankingSamples)) * 0.975;
        minValue = min(data(blankingSamples)) * 0.975;

        [~, maxIdx] = findpeaks([0, flip(data(blankingSamples))], 'NPeaks', 1, 'MinPeakHeight', maxValue);
        [~, minIdx] = findpeaks([0, -flip(data(blankingSamples))], 'NPeaks', 1, 'MinPeakHeight', abs(minValue));

        maxIdx = (length(blankingSamples) + 1) - maxIdx + 1;
        minIdx = (length(blankingSamples) + 1) - minIdx + 1;

        peakIdx = [minIdx, maxIdx];
        polarity = [-1, 1];
        peakCheck = islocalmax(data) | islocalmin(data);
        peakCheck = peakCheck(peakIdx);

        peakIdx = peakIdx(peakCheck);
        polarity = polarity(peakCheck);

        if length(peakIdx) > 1
            polarity = maxIdx > minIdx;
            peakIdx = peakIdx(polarity + 1);

            if polarity == 0
                polarity = -1;
            end
        end

        %% 2) Detect clipping
        startClippingIdxs = [];
        endClippingIdxs = [];
        isClipped = false;

        for i = 1:numel(saturationVoltage)
            clippedIdxs = find((-1)^i * data > (-1)^i * saturationVoltage(i));

            if ~isempty(clippedIdxs)
                clippedIntervals = [true, diff(clippedIdxs) ~= 1];
                startClippingIdxs = [startClippingIdxs, clippedIdxs(clippedIntervals)];
                endClippingIdxs = [endClippingIdxs, clippedIdxs(clippedIntervals([2:end, 1]))];
            end
        end

        if ~isempty(startClippingIdxs) && ~isempty(endClippingIdxs)
            samplesCheck = abs(endClippingIdxs - startClippingIdxs) + 1 >= minClippedNSamples;

            startClippingIdxs = unique(startClippingIdxs(samplesCheck));
            endClippingIdxs = unique(endClippingIdxs(samplesCheck));

            if ~isempty(startClippingIdxs) && ~isempty(endClippingIdxs)
                isClipped = true;
                peakIdx = max([peakIdx, max(endClippingIdxs)]);
                polarity = sign(data(peakIdx) - median(data));
            end
        end

        %% 3) Return output values
        varargout{1} = isClipped;
        varargout{2} = polarity;

        %% 4) Plot
        % fig = figure();
        % hold('on');
        % plot(data);
        % scatter(startClippingIdxs, data(startClippingIdxs), 'green');
        % scatter(endClippingIdxs, data(endClippingIdxs), 'red');
        % scatter(peakIdx, data(peakIdx), 'black', 'Marker', '*');
        % uiwait(fig);

    end

    function [artifact, varargout] = fitArtifact(data, sampleRate, varargin)
        %FITARTIFACT Fit the artifact shape.
        %   artifact = FITARTIFACT(data, sampleRate) computes the stimulus artifact
        %   shape from the input data, discarding all the high frequency components
        %   usually related to spiking activity. By default, a 1 ms blanking period
        %   is assumed after the stimulus onset. Input data are expected to
        %   start from the stimulus onset.
        %
        %   [artifact, blankingNSamples] = FITARTIFACT(data, sampleRate) returns
        %   the number of blanked samples, where the input data were not modified.
        %   An empty array will be returned if all data are blanked.
        %
        %   [artifact, blankingNSamples, peakIdx] = FITARTIFACT(data, sampleRate) returns
        %   the index where the peak of the artifact is found. The peak is defined as the
        %   last point after which it becomes possible to recover data.
        %
        %   [...] = FITARTIFACT(..., blankingPeriod) specifies the time after the
        %   stimulus onset that is not affected by this function. It must be
        %   expressed in seconds. By default it is 1 ms.
        %
        %   [...] = FITARTIFACT(..., 'PARAM1', val1, 'PARAM2', val2, ...) specifies optional
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

        %% 0) Check and parse input arguments
        validNumPosCheck = @(x) isnumeric(x) && (x >= 0);

        parser = inputParser();
        addRequired(parser, 'data', @isnumeric);
        addRequired(parser, 'sampleRate', validNumPosCheck);
        addOptional(parser, 'blankingPeriod', 1e-3, validNumPosCheck);
        addParameter(parser, 'saturationVoltage', [], @(x) isempty(x) || isnumeric(x));
        addParameter(parser, 'minClippedNSamples', [], @(x) isempty(x) || (isnumeric(x) && (x >= 0)));

        parse(parser, data, sampleRate, varargin{:});

        data = double(parser.Results.data);
        sampleRate = parser.Results.sampleRate;
        blankingPeriod = parser.Results.blankingPeriod;
        saturationVoltage = parser.Results.saturationVoltage;
        minClippedNSamples = parser.Results.minClippedNSamples;

        blankingNSamples = round(blankingPeriod * sampleRate);
        output2 = data;

        %% 1) Find peakIdx
        peakIdx = findArtifactPeak(data, sampleRate, blankingPeriod, saturationVoltage, minClippedNSamples);
        blankingNSamples = max([blankingNSamples, peakIdx]);

        if blankingNSamples >= length(output2)
            % Skip the current trial if it gets blanked completely
            artifact = output2;
            varargout{1} = [];
            varargout{2} = peakIdx;
            return;
        end

        %% 2) Select interpolating points and extract the artifact shape
        interpXDuration = 0.05;
        nInterpXPoints = 42;

        interpX = logspace(log10(1), log10(interpXDuration * 1e3), nInterpXPoints) - 1;
        interpX = unique(round(interpX * 1e-3 * sampleRate));
        interpX = interpX + blankingNSamples + 1;

        interpX(interpX > length(output2)) = [];

        largestIPI = interpX(end) - interpX(end-1);
        nExtraInterpX = floor((length(output2) - interpX(end)) / largestIPI);
        if nExtraInterpX > 0
            interpX = [interpX, interpX(end) + largestIPI * (1:nExtraInterpX)];
        end

        IPI = [interpX(1), diff(interpX), length(output2) - interpX(end)];

        minHalfInterval = 2;
        maxHalfInterval = 15;
        interpY = zeros(1, numel(interpX));
        for i = 1:numel(interpY)
            if floor(IPI(i) / 2) >= minHalfInterval && floor(IPI(i + 1) / 2) >= minHalfInterval
                intervalSamples = -min(maxHalfInterval, floor(IPI(i) / 2)):min(maxHalfInterval, floor(IPI(i + 1) / 2));
            else
                intervalSamples = 0;
            end
            interpY(i) = mean(output2(intervalSamples + interpX(i)));
        end

        keyX = [blankingNSamples + 1, length(output2)];
        keyY = output2(keyX);

        [interpX, keptIdxs, ~] = unique([keyX, interpX]);   % Unique automatically sorts
        interpY = [keyY, interpY];
        interpY = interpY(keptIdxs);

        output2 = interp1(interpX, interpY, 1:length(output2), 'linear');

        %% 3) Restore original data in the blanking period
        blankingSamples = 1:blankingNSamples;
        output2(blankingSamples) = data(blankingSamples);

        %% 4) Return output2 values
        artifact = output2;
        varargout{1} = blankingNSamples;
        varargout{2} = peakIdx;

        %% 5) Plot
        % t = 0:1/sampleRate:(length(data)/sampleRate - 1/sampleRate);
        % t = t*1e3;

        % fig = figure();
        % tiledlayout(2, 1);

        % ax = nexttile();
        % hold('on');
        % plot(t, data);
        % plot(t, artifact, 'Color', 'magenta')
        % scatter(1e3*(peakIdx/sampleRate - 1/sampleRate), artifact(peakIdx), 25, 'black', 'Marker', '*');
        % patch([0, blankingPeriod, blankingPeriod, 0] * 1e3, [min(ax.YLim), min(ax.YLim), max(ax.YLim), max(ax.YLim)], [0.8, 0.8, 0.8], 'FaceAlpha', 0.3, 'LineStyle', 'none');
        % title('Raw Data');
        % xlabel('Time (ms)');
        % ylabel('Voltage (\mu{V})');

        % residuals = data-artifact;
        % ax = nexttile();
        % hold('on')
        % plot(t, residuals, 'Color', 'b')
        % scatter(1e3*(peakIdx/sampleRate - 1/sampleRate), residuals(peakIdx), 25, 'black', 'Marker', '*');
        % patch([0, blankingPeriod, blankingPeriod, 0] * 1e3, [min(ax.YLim), min(ax.YLim), max(ax.YLim), max(ax.YLim)], [0.8, 0.8, 0.8], 'FaceAlpha', 0.3, 'LineStyle', 'none');
        % title('Residuals');
        % xlabel('Time (ms)');
        % ylabel('Voltage (\mu{V})');
        % set(gcf,'Visible','on');
        % uiwait(fig);

    end

    function installLogLIRA()
        fprintf('Installing logLIRA... ');

        requiredAddons = {'Uniform Manifold Approximation and Projection (UMAP)'};
        installedAddons = matlab.addons.installedAddons();
        for i = 1:numel(requiredAddons)
            if ~contains(requiredAddons{i}, installedAddons.Name)
                fprintf('Aborted.\n');
                error('logLIRA:install:missingAddOn', '%s not found. Install it via Matlab Add-On Manager.', requiredAddons{i});
            end
        end

        if contains(pwd(), strsplit(path, pathsep))
            fprintf('Skipped.\n');
            fprintf('logLIRA already installed.\n');
        else
            addpath(pwd());
            status = savepath();
            if status == 0
                fprintf('Done.\n');
            else
                fprintf('Aborted.\n');
                fprintf('Matlab path could not be saved.\n');
            end
        end
    end

end