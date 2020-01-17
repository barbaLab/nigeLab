function spikes = getSpikes(blockObj,ch,clusterIndex,type)
%GETSPIKES  Retrieve list of spike peak sample indices
%
%  spikes = GETSPIKES(blockObj,ch);
%  spikes = GETSPIKES(blockObj,ch,class);
%  features = GETSPIKES(blockObj,ch,class,'feat');
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class in orgExp package.
%                       -> If given as an array, uses the same value for ch
%                             for each block (without checking if it is the
%                             same channel/probe ID combination on each
%                             block).
%
%    ch        :     Channel index for retrieving spikes. Must be given as
%                       a SCALAR positive integer.
%
% clusterIndex :     (Optional) Specify the class of spikes to retrieve,
%                       based on sorting or clustering. If not specified,
%                       gets all spikes on channel. Otherwise, it will
%                       check to make sure that there are actually classes
%                       associated with the spike and issue a warning if
%                       that part hasn't been done yet.
%                       -> Can be given as a vector.
%                       -> Non-negative integer.
%                       -> Default is NaN
%                       -> Can be specified as {'fieldName', [vector]}
%                          * 'fieldName' : e.g. 'Clusters' or 'Sorted'
%                          * [vector] : e.g. standard clusterIndex numeric
%                                            array
%                       -> If cell is not used (just the cluster index
%                          numeric vector is provided), then the selector
%                          defaults to using 'Sorted' if that exists,
%                          otherwise 'Clusters' if that exists.
%
%   type       :     (Optional) Specify the type of snippets to retrieve.
%                       -> 'feat' : Retrieves the features extracted during
%                                   spike detection (currently defaulted to
%                                   Wavelet coefficients).
%                       -> 'spikes' : Retrieves the waveform.
%
%  --------
%   OUTPUT
%  --------
%   spikes     :     Spike waveform snippets from the FILT or CARFILT data,
%                       corresponding to each identified spike wave peak
%                       (or subset that matches class vector elements).
%
%  -- OR (if `type` is 'feat') --
%
%  features    :     Feature coefficients used for semi-automated
%                       clustering and sorting. Only returned if 'feat' is
%                       specified for type variable.

% ERROR CHECKING
if nargin < 2
   error(['nigeLab:' mfilename ':MissingInputArguments'],...
      'Must at least specify ''ch'' input arg');
end

if ~ParseSingleChannelInput(blockObj,ch)
   error(['nigeLab:' mfilename ':InvalidChannelIndex'],...
      'Invalid value of ''ch'' input:  %g',ch);
end

% PARSE INPUTS
if nargin < 4
   type = 'spikes';
end

if nargin < 3
   clusterIndex = nan;
end

% If multiple blocks, use recursion
spikes = [];
if (numel(blockObj) > 1)
   for ii = 1:numel(blockObj)
      spikes = [spikes; getSpikes(blockObj(ii),ch,clusterIndex,type)]; %#ok<AGROW>
   end
   return;
end

% RETRIEVE SPIKES OR FEATURES
switch lower(type) % Could add expansion for things like 'pw' and 'pp' etc.
   case {'feat','spikefeat','features','spikefeatures'}
      % Variable is still called "spikes"
      spikes = getEventData(blockObj,'SpikeFeatures','snippet',ch);
   otherwise % Default is 'spikes'
      spikes = getEventData(blockObj,'Spikes','snippet',ch);
end
if isempty(spikes)
   return;
end

% USE CLUSTERINDEX TO REDUCE SET
switch class(clusterIndex)
   case 'cell' % isnan does not work on 'cell' inputs
      % If cell, specifies {'clusterType',[clusterIndicesToKeep]}
      if numel(clusterIndex) ~= 2
         error(['nigeLab:' mfilename ':badInputSyntax'],...
            ['If clusterIndex is a cell, it must have two elements:\n' ...
            '-->\t{''Sorted'',[clusterIndices]}, or\n',...
            '-->\t{''Clusters'',[clusterIndices]}']);
      end
      
      % Handle cases where good inputs are given but in wrong order
      if ischar(clusterIndex{1})
         clusterType = clusterIndex{1};
         clusterIndex = clusterIndex{2};
      elseif ischar(clusterIndex{2})
         clusterType = clusterIndex{2};
         clusterIndex = clusterIndex{1};
      else
         error(['nigeLab:' mfilename ':badInputSyntax'],...
            ['If clusterIndex is a cell, it must have two elements:\n' ...
            '-->\t{''Sorted'',[clusterIndices]}, or\n',...
            '-->\t{''Clusters'',[clusterIndices]}']);
      end
      
      switch lower(clusterType)
         case {'s','sort','sorted','sorts','sorting'}
            c = blockObj.getSort(ch);
         case {'clusters','clu','clust','cluster','clus','c','cl'}
            c = blockObj.getClus(ch);
         otherwise
            error(['nigeLab:' mfilename ':UnexpectedString'],...
               'Unexpected "clustering" type: %s',clusterType);
      end
   otherwise
      % Otherwise, must be numeric (or NaN to skip)
      if isnan(clusterIndex)
         return; % Returns all spikes or features if this arg is unused
      end
      
      if isnumeric(clusterIndex)
         if getStatus(blockObj,'Sorted',ch)
            c = blockObj.getSort(ch);
         elseif getStatus(blockObj,'Clusters',ch)
            c = blockObj.getClus(ch);
         else
            return; % do nothing
         end
      else
         error(['nigeLab:' mfilename ':UnexpectedClass'],...
            'Unexpected class for ''clusterIndex'': %s',...
            class(clusterIndex));
      end
end

% Return the reduced subset of spikes
spikes = spikes(ismember(c,clusterIndex),:);

end