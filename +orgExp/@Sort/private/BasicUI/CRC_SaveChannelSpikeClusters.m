function CRC_SaveChannelSpikeClusters(obj,ch)
%% CRC_SAVECHANNELSPIKECLUSTERS  Save clusters for a given channel.

% Check for output folder existence
fprintf(1,'Please wait, saving channel %d...',ch);
if exist(obj.Data.files.sort.folder,'dir')==0
   mkdir(obj.Data.files.sort.folder);
end

% Get appropriate output concatenation
fname = sprintf('%s_%s_%s.mat',...
   obj.Data.files.prefix{ch},...
   obj.Data.SORT_ID,...
   obj.Data.files.spk.ch{ch});

% Make full file name
save_name = fullfile(obj.Data.files.sort.folder,fname);

% Get the class for this channel
class = obj.Data.cl.num.class.cur{ch}; 
tag = obj.Data.cl.tag.name{ch};

save(save_name,'class','tag','-v7.3');

fprintf(1,'complete.\n');

end