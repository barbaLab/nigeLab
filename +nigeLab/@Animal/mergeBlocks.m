function mergeBlocks(animalObj,ind,varargin)
%%
%     BlockFieldsToMerge_                   'Channels'
%     ChannelsFieldsToMerge_                'rawData','stimData','amp_settle_data'
%                                           'charge_recovery_data','compliance_limit_data'
%                                           'Filtered','LFPData';




    if nargin<2
        warning('Not enough input args, no blocks merged.');
       return; 
    end
    TargetBlock=animalObj.Blocks(ind(1));
    
    BlockFieldsToMerge_={ 'Channels';
%                          'DACChannels';
%                          'ADCChannels';
%                          'DigInChannels';
%                          'DigOutChannels';
                        };
   BlockFieldsToMerge = BlockFieldsToMerge_(...
                        ismember( BlockFieldsToMerge_, fieldnames(animalObj.Blocks(ind(1)))));
                
   ChannelsFieldsToMerge_={ 'rawData';
                            'stimData';
                            'amp_settle_data';
                            'charge_recovery_data';
                            'compliance_limit_data';
                            'Filtered';
                            'LFPData';
                        };
                    
for iV = 1:2:numel(varargin)
    eval([(varargin{iV}) '=varargin{iV+1};']);
end
                    
    ChannelsFieldsToMerge = ChannelsFieldsToMerge_(...
                            isfield( animalObj.Blocks(ind(1)).Channels, ChannelsFieldsToMerge_));
    
    fprintf(1,'\nmerging blocks %d to %d... ',ind(1),ind(end));                    
    fprintf(1,'%.3d%%',0)
    progr=0;
    totProgr = numel(ind(2:end))*numel(BlockFieldsToMerge)*...
        TargetBlock.NumChannels*numel(ChannelsFieldsToMerge);
    for ii=ind(2:end)
        for kk=1:numel(BlockFieldsToMerge)
            for jj=1:TargetBlock.(['Num' BlockFieldsToMerge{kk}])
                for ll=1:numel(ChannelsFieldsToMerge)
                TargetBlock.(BlockFieldsToMerge{kk})(jj).(ChannelsFieldsToMerge{ll}) = append(...
                TargetBlock.(BlockFieldsToMerge{kk})(jj).(ChannelsFieldsToMerge{ll}),...
                animalObj.Blocks(ii).(BlockFieldsToMerge{kk})(jj).(ChannelsFieldsToMerge{ll}));
                progr=progr+1;
                fraction_done = 100 * (progr / totProgr);
                if ~floor(mod(fraction_done,5)) % only increment counter by 5%
                    fprintf(1,'\b\b\b\b%.3d%%',floor(fraction_done))
                end
                end
            end
        end
    end
%     TargetBlock.Samples = TargetBlock.Channels(1).(ChannelsFieldsToMerge{1}).lenght;
end
