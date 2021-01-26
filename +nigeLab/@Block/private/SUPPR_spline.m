
function sig = SUPPR_spline(sig,p)
for ii = p.stimIdx(:)'
    
    lastValidSample =  sig(p.stimSamples{ii}(1));
    if ii==numel(stimIdx)
        % last stim needs to be handled separatly
        IntervalOfInterest = p.stimSamples{ii}(1):min(length(sig),p.stimSamples{ii}(end)+p.fs/2);
    else
        IntervalOfInterest = p.stimSamples{ii}(1):min(p.stimSamples{ii+1}(1),p.stimSamples{ii}(end)+p.fs/2);
    end
    % get the smoothed first derivative
    transformSig = [0 conv(abs(diff(sig(IntervalOfInterest))),gausswin(round(5*p.stimLength(ii))),'same')];
    StimArt = transformSig > prctile(transformSig,99);
    StimArt(1:find(StimArt,1)) = true;
    
    
    IntervalStrt = IntervalOfInterest(~StimArt);
    IntervalStrt = IntervalStrt(1);
    
    IntervalEnd = IntervalOfInterest(~StimArt);
    IntervalEnd = IntervalEnd(end);
    
    % regress away a polinomial to flatten the amplifier deflaction
    regressX = double(IntervalStrt : IntervalEnd);
    StimArt = IntervalOfInterest(StimArt);
    
    
    [f, gof] = createFitSpline(regressX, sig(regressX));
    wndw = ones(1,length(regressX));
    
    
    % Bad fit
    rmse = sqrt((sig(regressX) - f(regressX)').^2);
    badfitStrt = rmse >  prctile(rmse,99) & (regressX < regressX(round(p.fs/50)) );
    badfitEnd  = rmse >  prctile(rmse,99) & (regressX > regressX(end - round(p.fs/50)));
    
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


end



function [fitresult, gof] = createFitSpline(regressX, sigReg)
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


function sig = fitSigm(a,b,x)
sig =  sigmf(x,[.05,floor(x(1)/2+x(end)/2)])*(b-a)+a;
end



