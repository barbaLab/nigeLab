function extractLFP(blockObj)
%% Decimates files to retrieve LFPs.
% Sampling frequency chosen for the downsampled files is 1000Hz
% Band of interest in LFPs is up to 250Hz.

        DownSampleFreq=1000; 
        DecimateCascadeM=[5 3 2];
        DecimateCascadeN=[3 5 5];
        
        for ii=1:blockObj.numChannels
            lfp=double(blockObj.Channels(ii).rawData);
            for jj=1:numel(DecimateCascadeM)
                lfp=decimate(lfp,DecimateCascadeM(jj),DecimateCascadeN(jj));
            end
            pnum  = num2str(blockObj.Channels(ii).port_number);
            chnum = blockObj.Channels(ii).custom_channel_name(regexp(blockObj.Channels(ii).custom_channel_name, '\d'));
            fname = sprintf(strrep(blockObj.paths.LW_N,'\','/'), pnum, chnum);
            save(fullfile(fname),'lfp','-v7.3');
            blockObj.Channels(ii).LFPData=orgExp.libs.DiskData(matfile(fullfile(fname)));
        end
        blockObj.Downsampled_rate=DownSampleFreq;
        blockObj.updateStatus('LFP',true);
        blockObj.save;
end

