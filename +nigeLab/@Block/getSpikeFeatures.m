function features = getSpikeFeatures(blockObj,ch,clusterIndex)
%GETSPIKEFEATURES  Return spike features
%
%  features = blockobj.getSpikeFeatures(ch);
%  features = blockObj.getSpikeFeatures(ch,clusterIndex);
%
%  See Also:
%  NIGELAB.BLOCK/GETSPIKES

%% ERROR CHECKING
if nargin < 2
   error(['nigeLab:' mfilename ':MissingInputArguments'],...
      'Must at least specify ''ch'' input arg');
end

if ~ParseSingleChannelInput(blockObj,ch)
   error(['nigeLab:' mfilename ':InvalidChannelIndex'],...
      'Invalid value of ''ch'' input:  %g',ch);
end

if nargin < 3
   clusterIndex = nan;
end

%%
features = getSpikes(blockObj,ch,clusterIndex,'Features');

end