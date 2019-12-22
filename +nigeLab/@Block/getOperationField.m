function field = getOperationField(operation)
%GETOPERATIONFIELD  Gets the field associatied with a given operation
%
%  <strong>Example: </strong>
%
%     operation = 'doRawExtraction';
%     field = nigeLab.Block.getOperationField(operation);
%     >> field
%        ans = 
%           'Raw'

%% This is just an enumeration basically
switch operation
   case 'doRawExtraction'
      field = {'Raw','DigIO','AnalogIO','Stim','Time'};
   case 'doEventDetection'
      field = 'DigEvents';
   case 'doEventHeaderExtraction'
      field = 'ScoredEvents';
   case 'doUnitFilter'
      field = 'Filt';
   case 'doReReference'
      field = 'CAR';
   case 'doSD'
      field = {'Spikes','SpikeFeatures'};
   case 'doLFPExtraction'
      field = 'LFP';
   case 'doVidInfoExtraction'
      field = '';
   case 'doBehaviorSync'
      field = '';
   case 'doVidSyncExtraction'
      field = '';
   case 'doAutoClustering'
      field = 'Clusters';
   otherwise
      error(['nigeLab:' mfilename ':unexpectedMethodName'],...
         'No Field associated with %s (currently)',operation);

end