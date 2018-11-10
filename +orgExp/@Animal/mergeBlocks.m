function mergeBlocks(animalObj,ind)
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
                        ismember( BlockFieldsToMerge_, fieldnames(animalObj.Blocks(5))));
                
   ChannelsFieldsToMerge_={ 'rawData';
                            'amp_settle_data';
                            'charge_recovery_data';
                            'compliance_limit_data';
                            'Filtered';
                            'LFPData';
                        };
    ChannelsFieldsToMerge = ChannelsFieldsToMerge_(...
                            isfield( animalObj.Blocks(5).Channels, ChannelsFieldsToMerge_));
                        
    for ii=ind(2:end)
        for kk=1:numel(BlockFieldsToMerge)
            for jj=1:TargetBlock.(['num' BlockFieldsToMerge{kk}])
                for ll=1:numel(ChannelsFieldsToMerge)
                TargetBlock.(BlockFieldsToMerge{kk})(jj).(ChannelsFieldsToMerge{ll}) = append(...
                TargetBlock.(BlockFieldsToMerge{kk})(jj).(ChannelsFieldsToMerge{ll}),...
                animalObj.Blocks(ii).(BlockFieldsToMerge{kk})(jj).(ChannelsFieldsToMerge{ll}));
                end
            end
        end
    end
    
end
