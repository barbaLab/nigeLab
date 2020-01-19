function ts = getSpikeTimes(blockObj,ch,clusterIndex)
%GETSPIKETIMES  Retrieve list of spike times (seconds)
%
%  ts = GETSPIKETIMES(blockObj,ch);
%  ts = GETSPIKETIMES(blockObj,ch,class);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class in orgExp package.
%
%    ch        :     Channel index for retrieving spikes.
%                    -> If not specified, returns a cell array with spike
%                          indices for each channel.
%                    -> Can be given as a vector.
%
% clusterIndex :     (Optional) Specify the class of spikes to retrieve,
%                       based on sorting or clustering. If not specified,
%                       depends on if sorting has been done. 
%                       Otherwise it gets all spikes. 
%                       If class is specified, it will check to make sure 
%                       that there are actually classes associated with the
%                       spike and issue a warning if that part hasn't been 
%                       done yet.
%                       -> Can be given as a vector.
%                       -> Non-negative integer.
%
%  --------
%   OUTPUT
%  --------
%     ts       :     Vector of spike times (sec)
%                    -> If ch is a vector, returns a cell array of
%                       corresponding spike sample times.

% PARSE INPUT
if nargin < 2
   ch = 1:blockObj(1).NumChannels;
end

if nargin < 3
   clusterIndex = nan;
end

% ITERATE ON MULTIPLE CHANNELS
if (numel(ch) > 1)
   ts = cell(size(ch));
   if numel(clusterIndex)==1
      clusterIndex = repmat(clusterIndex,1,numel(ch));
   elseif numel(clusterIndex) ~= numel(ch)
      [fmt,idt,~] = blockObj.getDescriptiveFormatting();
      nigeLab.utils.cprintf('Errors*',...
         '%s[GETSPIKETIMES]::%s ',idt,blockObj.Name);
      nigeLab.utils.cprintf(fmt(1:(end-1)),...
         'Clusters (%d) must match number of channels (%d).',...
         numel(clusterIndex),numel(ch));
      ts = [];
      return;
   end
   for ii = 1:numel(ch)
      ts{ii} = getSpikeTimes(blockObj,ch(ii),clusterIndex(ii)); 
   end   
   return;
end

% ITERATE ON MULTIPLE BLOCKS
if numel(blockObj) > 1
   ts = [];
   for ii = 1:numel(blockObj)
      ts = [ts; getSpikeTimes(blockObj(ii),ch,clusterIndex)]; %#ok<AGROW>
   end 
   return;
end

% GET SPIKE PEAK SAMPLES AND CONVERT TO TIMES
if isempty(clusterIndex)
   ts = getEventData(blockObj,'Spikes','ts',ch);
elseif isnan(clusterIndex)
   ts = getEventData(blockObj,'Spikes','ts',ch);
elseif strcmpi(clusterIndex,'all')
   ts = getEventData(blockObj,'Spikes','ts',ch);
else
   ts = getEventData(blockObj,'Spikes','ts',ch,'tag',clusterIndex);
end
if isempty(ts)
   ts = zeros(0,1);
end
end