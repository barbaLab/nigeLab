%%
function sig = suppressStim(blockObj,nChan,varargin)
%% SUPPRESSSTIM loads raw signal and returns a stimulation-pulse free signal
%
%  sig = suppressStim(blockObj,nChan) returns raw signa from channel nChan
%  cleaned from the stimulation pulses. It identifies the stimulation
%  pulses using the Stim event field if present. If not present, it fails
%  returning an error. Pulses are blanked for the length specified in the
%  Stim file and the amplifier ripple is regressed away using a 3rd order
%  plinomial.
%
%  --------
%   INPUTS
%  --------
%
%   varargin (optional name-value pair arguments) :
%
%  sig = suppressStim(blockObj,nChan,'method',M) uses the cleaning method
%  M. M is a scalar and can be:
%               'regression' blanks the saturation caused by the
%                            stimulaiton and regresses away the ripples
%                            using a 3rd degree polynomial.
%               'blanking' blanks the full artefact, both saturation and
%                          ripples.
%
%  sig = suppressStim(blockObj,nChan,'stimL',SL) overrides the
% stimulation length saved in the Stim file. SL specifies the sample number
% to blank in the stimualtion artefact. Supposed to bea positive integer.
%
%
%  sig = suppressStim(blockObj,nChan,'regrMethod',RM,'regrPars',RP) if
%   using the regression cleaning method, you can specify the regression
%   method RM as a string. Defualt is 'poly3'. RP is a cell array
%   containing the regression function parameters defualt is
%   {'Robust','LAR'};
%
%
%  sig = suppressStim(blockObj,nChan,'stimTS',sTS) specifies the time
%   stamps of the stimulation pulses in the float array sTS. Overrides the
%   Stim event file.
%
%
%  --------
%   OUTPUTS
%  --------
% sig (float), cleaned raw signal
%
%

stimLength = []; % 23
regressionMethod = 'poly3';
regressionPars = {'Robust','LAR'};

p = inputParser;
addRequired(p,'nChan',@isnumeric);
addParameter(p,'method','softpoly',@(c) isstring(c) || ischar(c));
addOptional(p,'stimTS',[],@isnumeric);
addParameter(p,'stimL',stimLength,@isnumeric);
addParameter(p,'regrMethod',regressionMethod,@isstring);
addParameter(p,'regrPars',regressionPars,@iscell);
addParameter(p,'stimIdx','all',@(x) isnumeric(x) | strcmpi(x,'all'));

parse(p,nChan,varargin{:});

% check for stimTS to exist. If not provided load from disk. If not present
% in the nigelObj throw an error
if ismember('stimTS',p.UsingDefaults)
    if isfield(blockObj.Events,'Stim')
        StimTS = blockObj.Events.Stim.data.ts;
        % often times a lien of zeros is created at the beginning of the
        % file for allocation purposes. This takes care of it.
        StimTS(StimTS==0) = [];
    else
        error('nigelab:removeStim','Stim field not present in Events!\n Please provide stimTS explicitely.');
    end
else
    
end

if strcmp(p.Results.stimIdx,'all')
    stimIdx = 1:numel(StimTS);
else
    stimIdx = p.Results.stimIdx;
end

if ismember('stimL',p.UsingDefaults)
    stimLength = blockObj.Events.Stim.data.snippet;
    stimLength = stimLength(:,2);
    stimLength(stimLength==0) = [];
elseif isscalar(p.Results.stimL)
    stimLength = ones(size(StimTS))*p.Results.stimL;
elseif size(p.Results.stimL,1) ~= size(StimTS,1)
    error('nigelab:removeStim','Number of stimulation pulses(stimTS) and stimulation durations(stimL) does not correspond!');
end

% load signal
fs = blockObj.SampleRate;
sig = blockObj.Channels(nChan).Raw(:);

[StimI,I] = unique(floor(StimTS*fs));
stimLength = ceil(stimLength(I)*fs);
stimSamples = arrayfun(@(i) StimI(i):StimI(i)+stimLength(i),1:numel(StimI),'UniformOutput',false);
% fprintf('%.3d%%',0)

switch p.Results.method
    case 'salpa'
        [sig, ~] = nigeLab.utils.SALPA3( single(sig(:)),StimI(stimIdx),30,fs/3 );
    case {'softpoly','spline','blanking','none'}
        sig = softpoly(sig,stimIdx,fs,stimSamples,stimLength,p);
    case 'other'
        
end
    
end


function sig = softpoly(sig,stimIdx,fs,stimSamples,stimLength,p)
for ii = stimIdx(:)'
    
    lastValidSample =  sig(stimSamples{ii}(1));
    if ii==numel(stimIdx)
        % last stim needs to be handled separatly
        IntervalOfInterest = stimSamples{ii}(1):min(length(sig),stimSamples{ii}(end)+fs/2);
    else
        IntervalOfInterest = stimSamples{ii}(1):min(stimSamples{ii+1}(1),stimSamples{ii}(end)+fs/2);
    end
    % get the smoothed first derivative
    transformSig = [0 conv(abs(diff(sig(IntervalOfInterest))),gausswin(round(5*stimLength(ii))),'same')];
    StimArt = transformSig > prctile(transformSig,99);
    StimArt(1:find(StimArt,1)) = true;
    % find steep transients
    %     SteepParts = (transformSig > 100*iqr(transformSig));
    %     St = IntervalOfInterest(conv(SteepParts,[-1 1],'same')<0);
    %     Ed = IntervalOfInterest(conv(SteepParts,[-1 1],'same')>0);
    
    %     idx = St > IntervalOfInterest(fs/20) & St < IntervalOfInterest(end - fs/20);
    % %     St(idx)=[];
    %     Ed(idx)=[];
    %     if sum(St<IntervalOfInterest(round(end/2)))>1 % if there are two peaks at the beginning, merge them
    %         idx = St > IntervalOfInterest(fs/20) & St < IntervalOfInterest(end - fs/20);
    %         St(2) = [];Ed(1) = [];St(1) = IntervalOfInterest(1);
    %     end
    %     for jj = 1:numel(St)
    %         a = sig(St(jj));
    %         b = sig(Ed(jj));
    %         sig(St(jj):Ed(jj))  = sigmf(St(jj):Ed(jj),[.2,floor(St(jj)/2+Ed(jj)/2)])*(b-a)+a;
    % %         sig(St(jj)+1:Ed(jj)) = sig(St(jj));
    %     end
    
    
    IntervalStrt = IntervalOfInterest(~StimArt);
    IntervalStrt = IntervalStrt(1);
    % find the extent of the pulse
    %     [val] = max(transformSig);
    %     [~,locs_,width] = findpeaks(val-transformSig,'MinPeakHeight',val/2,'NPeaks',1);
    %     % Account for possible saturation in the next ms
    % %     offsIdx = IntervalOfInterest(1)+locs;
    % %     SatOffs = sum(sig(offsIdx)==sig(offsIdx:offsIdx+fs/1000));
    %     % find the start of amplifier recovery curve
    %
    %     % find the second peak of the derivative, ie where the amp starts the recovery
    %     [val,I] = max(transformSig(locs_+1:end));
    %     [~,locs2_,width] = findpeaks(val-transformSig(locs_+I+1:end),'MinPeakHeight',val/2,'NPeaks',1);
    %
    %     IntervalStrt =  locs_ + locs2_ + I + 1 + IntervalOfInterest(1)-1;
    %
    %
    % %         IntervalStrt = find(...
    % %             diff(...
    % %             sign(...
    % %             sig(IntervalOfInterest(locs:end)) - lastValidSample)),1);
    %
    % %         IntervalStrt =  IntervalStrt + IntervalOfInterest(1)-1;
    %
    %     % replace the porper stimulation artefact with a constant value
    %     sig(IntervalOfInterest(1):IntervalStrt) = lastValidSample;
    %
    %     [~,I] = max(abs(sig(IntervalOfInterest)));
    % find the end of the amplifier saturation deflection
    %     IntervalEnd = find(...
    %         diff(...
    %         sign(...
    %         (sig(IntervalOfInterest(I) : IntervalOfInterest(end))) - ...
    %         lastValidSample ) ),...
    %         1)+IntervalOfInterest(I);
    
    IntervalEnd = IntervalOfInterest(~StimArt);
    IntervalEnd = IntervalEnd(end);
    %     if isempty(IntervalEnd)
    %        IntervalEnd = IntervalOfInterest(end);
    %     end
    %
    % regress away a polinomial to flatten the amplifier deflaction
    regressX = double(IntervalStrt : IntervalEnd);
    StimArt = IntervalOfInterest(StimArt);
    %     [~,I]=max(sig(regressX));
    switch p.Results.method
        case 'softpoly'
            try
                
                if numel(IntervalOfInterest) ~= (fs/2+numel(stimSamples{ii}))
                    wndw = ones(1,numel(regressX));
                else
                    wndw = tukeywin(numel(regressX),0.1)';
                    wndw = [ones(1,round(numel(wndw)/2)) wndw(round(end/2)+1:end)];
                end
                % if regression fails go with blanking
                [f,gof] = createFitPoly9(regressX, sig(regressX),fs);
                
                %                 I_ = find(f(regressX(I:end))<0,1);
                %                 if ~isempty(I_)
                %                     wndw(I+I_:end)=0;
                %                 end
                %                 [~,I] = findpeaks( sqrt((sig(regressX)-f2(regressX)').^2), 'NPeaks',1);
                %                 if I<2
                %                     f1 = @(x) sig(x) - sig(stimIdx{ii}(1));
                %                 else
                %                     [f1] = createFitSpline(regressX(1:I), sig(regressX(1:I) ));
                %                 end
                
                %                 f = @(x) [f1(x(x<regressX(I)));f2(x(x>=regressX(I)))];
            catch er
                f = @(x) [sig(x) - sig(stimSamples{ii}(1))]';
            end
            
            % Bad fit correction
            rmse = sqrt((sig(regressX) - f(regressX)').^2);
            badfitStrt = rmse >  prctile(rmse,99) & (regressX < regressX(round(fs/50)) );
            badfitEnd  = rmse >  prctile(rmse,99) & (regressX > regressX(end - round(fs/50)));
            
            badfitStrt = [find(badfitStrt,1) find(badfitStrt,1,'last')];badfitStrt = regressX(badfitStrt);
            badfitEnd = [find(badfitEnd,1) find(badfitEnd,1,'last')];badfitEnd = regressX(badfitEnd);
            
            sig(regressX) = (sig(regressX) - f(regressX)'.* wndw );
            
            if ~isempty(badfitEnd)
                sig(badfitEnd(1):badfitEnd(2)) = fitSigm(sig(badfitEnd(1)-1),sig(badfitEnd(end)+1),badfitEnd(1):badfitEnd(2));
            end
            
            if ~isempty(badfitStrt)
                sig(StimArt(1):badfitStrt(2)) = fitSigm(sig(StimArt(1)),sig(badfitStrt(2)),StimArt(1):badfitStrt(2));
            else
                sig(StimArt) = fitSigm(sig(StimArt(1)),sig(StimArt(end)),StimArt);
            end
            
        case 'blanking'
            f = @(x) sig(x(end+1))*ones(size(x));
            sig(regressX) = f(regressX);
            sig(StimArt) = fitSigm(sig(StimArt(1)),sig(StimArt(end)),StimArt);
            
            
            
        case 'none'
            sig(StimArt) = fitSigm(sig(StimArt(1)),sig(StimArt(end)),StimArt);
            
            
        case 'spline'
            [f, gof] = createFitSpline(regressX, sig(regressX));
            wndw = ones(1,length(regressX));
            
            
            % Bad fit
            rmse = sqrt((sig(regressX) - f(regressX)').^2);
            badfitStrt = rmse >  prctile(rmse,99) & (regressX < regressX(round(fs/50)) );
            badfitEnd  = rmse >  prctile(rmse,99) & (regressX > regressX(end - round(fs/50)));
            
            badfitStrt = [find(badfitStrt,1) find(badfitStrt,1,'last')];badfitStrt = regressX(badfitStrt);
            badfitEnd = [find(badfitEnd,1) find(badfitEnd,1,'last')];badfitEnd = regressX(badfitEnd);
            
            sig(regressX) = (sig(regressX) - f(regressX)'.* wndw );
            
            if ~isempty(badfitEnd)
                sig(badfitEnd(1):badfitEnd(2)) = fitSigm(sig(badfitEnd(1)-1),sig(badfitEnd(end)+1),badfitEnd(1):badfitEnd(2));
            end
            
            if ~isempty(badfitStrt)
                sig(StimArt(1):badfitStrt(2)) = fitSigm(sig(StimArt(1)),sig(badfitStrt(2)),StimArt(1):badfitStrt(2));
            else
                sig(StimArt) = fitSigm(sig(StimArt(1)),sig(StimArt(end)),StimArt);
            end
    end
    
%     fprintf('\b\b\b\b%.3d%%',round(ii/numel(stimIdx)*100))
    
end


end

















%% Helper fcns
function [fitresult, gof] = createFitPoly9(regressX, sigReg,fs)
%CREATEFIT(REGRESSX,SIGREG,FS)
overshoot = round(fs/50);
%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( [regressX regressX(end)+(1:overshoot)], [sigReg sigReg(end)*ones(1,overshoot)] );

% Set up fittype and options.
ft = fittype( 'poly9' );

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, 'Normalize', 'on' );
end

function [fitresult, gof] = createFitSpline(regressX, sigReg,fs)
%CREATEFIT(REGRESSX,SIGREG,FS)
%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( regressX, sigReg );

% Set up fittype and options.
ft = fittype( 'smoothingspline' );
opts = fitoptions( 'Method', 'SmoothingSpline' );
opts.SmoothingParam = 0.99999996;
opts.Normalize = 'on';

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );
end

function f = fitLine(a,b,x)
n1 = x(1);
n2 = x(end);
f = @(x) 1/(n2-n1) *( a*(n2-x) - b*(n1-x));
end

function sig = fitSigm(a,b,x)
sig =  sigmf(x,[.05,floor(x(1)/2+x(end)/2)])*(b-a)+a;
end

function sig = demean(sig)

sig = sig-mean(sig);
end