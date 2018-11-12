function rmChannels(F,p_list,ch_list)
%% RMCHANNELS  Remove channels for a set of recordings
%
%  RMCHANNELS(F,p_list,ch_list);
%
%  --------
%   INPUTS
%  --------
%     F        :     Struct obtained by calling 'dir' function on a
%                    directory that contains a set of recording blocks of
%                    interest. Should contain all the recording blocks that
%                    you want to remove the same probe number and channel
%                    number from.
%
%   p_list     :     Cell array, where each element is a string of probe
%                    names (e.g. {'P1'; 'P2'; 'P2}). Each probe element
%                    corresponds to the channel list element of the same
%                    index.
%
%   ch_list    :     Cell array, where each element is a string of channel
%                    names (e.g. {'011';'012';'015'}). Each channel element
%                    corresponds to the probe list element of the same
%                    index.
%
%  --------
%   OUTPUT
%  --------
%  PERMANENTLY DELETES the channel files (filtered and raw) associated with
%  this block, for those probe and channel combinations.
%
%  NOTE: THIS SHOULD ALWAYS BE DONE BEFORE DOING CAR (if "bad" channels
%           were not  excluded manually during the recording).
%
% By: Max Murphy  v1.0  08/17/2018  Original version (R2017b)

%% CHECK THAT PROBE LIST AND CHANNEL LIST MATCH NUMBER OF ELEMENTS
if numel(p_list)~=numel(ch_list)
   error('Dimension mismatch for probe list (%g) and channel list (%g).',...
      numel(p_list),numel(ch_list));
end

%% LOOP THROUGH DIRECTORY STRUCT AND DELETE SPECIFIED CHANNELS

h = waitbar(0,'Please wait, deleting files...');
for iF = 1:numel(F)
   
   DIR = fullfile(F(iF).folder,F(iF).name);
   
   for ii = 1:numel(ch_list)
      try
         fname = fullfile(DIR,[F(iF).name '_RawData'],...
            [F(iF).name '_Raw_' p_list{ii} '_Ch_' ch_list{ii} '.mat']);
         if exist(fname,'file')~=0
            delete(fname);
         end
         
         fname = fullfile(DIR,[F(iF).name '_Filtered'],...
            [F(iF).name '_Filt_' p_list{ii} '_Ch_' ch_list{ii} '.mat']);
         if exist(fname,'file')~=0
            delete(fname);
         end
         
         fname = fullfile(DIR,[F(iF).name '_FilteredCAR'],...
            [F(iF).name '_FiltCAR_' p_list{ii} '_Ch_' ch_list{ii} '.mat']);
         if exist(fname,'file')~=0
            delete(fname);
         end
         
      catch
         fprintf(1,'No channel %s on probe %s for %s.',...
            ch_list{ii},p_list{ii},F(iF).name);
      end
   end
   waitbar(iF/numel(F));
end
delete(h);

str = cell2mat([p_list, repmat({'-Ch-'},numel(p_list),1), ch_list]);
disp('Removed:');
disp(str);
disp('from the following recordings:');
disp({F.name}.');

end