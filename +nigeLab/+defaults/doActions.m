function pars = doActions(name)
% DOACTIONS  Default method to return "dependencies" for doActions
%
%  pars = nigeLab.defaults.doActions();  Return all as struct
%  
%  pars = nigeLab.defaults.doActions('doMethodName');  Return specific flag
%
%  Each field is the name of some 'doMethod'
%  Each field contains a cell array of fields that must evaluate to 'true'
%  from `updateParams` method of Block in order for that `doMethod` to run
%  correctly.

%%
pars = struct;

pars.doAutoClustering = {'Spikes'};
pars.doBehaviorSync = {'Video'};
pars.doEventDetection = {};  % Can be run without video (dig/analog stream)
pars.doEventHeaderExtraction = {'Video'};
pars.doLFPExtraction = {'Raw'};
pars.doRawExtraction = {};
pars.doReReference = {'Filt'};
pars.doSD = {'CAR'};
pars.doUnitFilter = {'Raw'};
pars.doVidInfoExtraction = {'Video'};
pars.doVidSyncExtraction = {'Video'};

if nargin > 0
   pars = pars.(name);
end


end