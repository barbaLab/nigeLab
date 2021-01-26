
function sig = SUPPR_softpoly(sig,p)
    for ii = p.StimIdx(:)'

        lastValidSample =  sig(p.StimSamples{ii}(1));
        if ii==numel(p.StimIdx)
            % last stim needs to be handled separatly
            IntervalOfInterest = p.StimSamples{ii}(1):min(length(sig),p.StimSamples{ii}(end)+p.fs/2);
        else
            IntervalOfInterest = p.StimSamples{ii}(1):min(p.StimSamples{ii+1}(1),p.StimSamples{ii}(end)+p.fs/2);
        end
        % get the smoothed first derivative
        transformSig = [0 conv(abs(diff(sig(IntervalOfInterest))),gausswin(round(5*p.StimLength(ii))),'same')];
        StimArt = transformSig > prctile(transformSig,99);
        StimArt(1:find(StimArt,1)) = true;

        IntervalStrt = IntervalOfInterest(~StimArt);
        IntervalStrt = IntervalStrt(1);

        IntervalEnd = IntervalOfInterest(~StimArt);
        IntervalEnd = IntervalEnd(end);

        % regress away a polinomial to flatten the amplifier deflaction
        regressX = double(IntervalStrt : IntervalEnd);
        StimArt = IntervalOfInterest(StimArt);
        %     [~,I]=max(sig(regressX));
        try

            if numel(IntervalOfInterest) ~= (p.fs/2+numel(p.StimSamples{ii}))
                wndw = ones(1,numel(regressX));
            else
                wndw = tukeywin(numel(regressX),0.1)';
                wndw = [ones(1,round(numel(wndw)/2)) wndw(round(end/2)+1:end)];
            end
            % if regression fails go with blanking
            [f,gof] = createFitPoly9(regressX, sig(regressX),p.fs);


        catch er
            f = @(x) [sig(x) - sig(p.StimSamples{ii}(1))]';
        end

        % Bad fit correction
        rmse = sqrt((sig(regressX) - f(regressX)').^2);
        idx = min(length(regressX),round(p.fs/50))-1;
        badfitStrt = rmse >  prctile(rmse,99) & (regressX < regressX(idx) );
        badfitEnd  = rmse >  prctile(rmse,99) & (regressX > regressX(end - idx));

        badfitStrt = [find(badfitStrt,1) find(badfitStrt,1,'last')];badfitStrt = regressX(badfitStrt);
        badfitEnd = [find(badfitEnd,1) find(badfitEnd,1,'last')];badfitEnd = regressX(badfitEnd);

        sig(regressX) = (sig(regressX) - f(regressX)'.* wndw );

        if ~isempty(badfitEnd)
            sig(badfitEnd(1):badfitEnd(2)) = fitSigm(sig(badfitEnd(1)-1),sig(badfitEnd(end)+1),badfitEnd(1):badfitEnd(2));
        end

        if ~isempty(badfitStrt)
            sig(StimArt(1):badfitStrt(2)) = fitSigm(sig(StimArt(1)),sig(badfitStrt(2)),StimArt(1):badfitStrt(2));
        else
            sig(StimArt(1):regressX(1)) = fitSigm(sig(StimArt(1)),sig(regressX(1)),StimArt(1):regressX(1));
        end


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

function sig = fitSigm(a,b,x)
sig =  sigmf(x,[.05,floor(x(1)/2+x(end)/2)])*(b-a)+a;
end


%% Actually Unused
function sig = demean(sig)

sig = sig-mean(sig);
end

function f = fitLine(a,b,x)
n1 = x(1);
n2 = x(end);
f = @(x) 1/(n2-n1) *( a*(n2-x) - b*(n1-x));
end
