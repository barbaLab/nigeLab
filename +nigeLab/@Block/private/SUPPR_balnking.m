
function sig = SUPPR_balnking(sig,p)
for ii = p.stimIdx(:)'
    
    lastValidSample =  sig(p.stimSamples{ii}(1));
    if ii==numel(p.stimIdx)
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
    
    f = @(x) sig(x(end+1))*ones(size(x));
    sig(regressX) = f(regressX);
    sig(StimArt) = fitSigm(sig(StimArt(1)),sig(StimArt(end)),StimArt);
    
    
    
end


end
