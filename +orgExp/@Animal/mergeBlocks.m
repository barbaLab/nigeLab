function mergeBlocks(animalObj,ind)
    if nargin<2
        warning('Not enough input args, no blocks merged.');
       return; 
    end
    TargetBlock=animalObj.Blocks(ind(1));
    
    BlockFieldsToMerge={ 'Channels';
%                          'DACChannels';
%                          'ADCChannels';
%                          'DigInChannels';
%                          'DigOutChannels';
                        };
                
   ChannelsFieldsToMerge={ 'rawData';
                            'amp_settle_data';
                            'charge_recovery_data';
                            'compliance_limit_data';
                            'Filtered';
                            'LFPData';
                        };
    
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
