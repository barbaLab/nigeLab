function analyzeLFPSyncIndex(blockObj)
if ~isfield(blockObj.Channels,'psd')
    for nCh=1:blockObj.numChannels
        [pxx,~] = pwelch(blockObj.Channels(nCh).LFPData(:),[],[],[],blockObj.Downsampled_rate);
        blockObj.Channels(nCh).psd=pxx;
        blockObj.Channels(nCh).syncIdx = computeSyncIdx(blockObj.Channels(nCh).LFPData(:),[0 4],[4 100],win*60*Downsampled_rate,Downsampled_rate);

    end
end

win=1; %s
overlap = 0; %s

% pdelta = bandpower(pxx,f,[0 4],'psd');
% ptheta = bandpower(pxx,f,[4 11],'psd');
% pbeta = bandpower(pxx,f,[11 30],'psd');
% pgammaLow = bandpower(pxx,f,[30 55],'psd');
% pgammaHigh = bandpower(pxx,f,[55 130],'psd');
%ptot(U) = bandpower(pxx,f,'psd');
% ptot = bandpower(pxx,f,[0 130],'psd');



end

function syncIdx = computeSyncIdx(data,lowFreqRange,highFreqRange,win_samples,fs)
% lowFreqRange = [0.5 4];
% highFreqRange = [0.5 10];
nSamples = length(data);
syncIdx = zeros(floor(nSamples./win_samples),1);
for ii = 1:length(syncIdx)
    %[curPSD,curF] = pwelch(data((1:win_samples)+((ii-1)*win_samples)),welchWinSamples,welchOverlap,nfft,sfLFP);
%     DataWind=data((1:win_samples)+((ii-1)*win_samples)); 
%     nfft=max(256,2^nextpow2(length(DataWind)));
%     [curPSD,curF] = pwelch(data((1:win_samples)+((ii-1)*win_samples)),[],[],nfft,fs);
    %[curPSD,curF]=periodogram(DataWind,[],nfft,fs);
    %[curPSD,curF]=pwelch(DataWind,win_samples);
    highFreqPower = sum(curPSD(curF>highFreqRange(1)&curF<=highFreqRange(2)));
    lowFreqPower = sum(curPSD(curF>lowFreqRange(1)&curF<=lowFreqRange(2)));
    syncIdx(ii) = lowFreqPower./highFreqPower;   
end
end