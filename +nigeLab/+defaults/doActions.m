function varargout = doActions(varargin)
% DOACTIONS  Returns default "dependencies" for doActions
%
%  pars = nigeLab.defaults.doActions();  Return all as struct
%  
%  pars = nigeLab.defaults.doActions('doMethodName');  Return specific flag
%
%  Each field is the name of some 'doMethod'
%  Each field contains a struct with the following fields:
%     
%     * 'required' :  cell array of fields that must evaluate to 'true'
%                     from `updateParams` method of Block. Otherwise,
%                     that `doMethod` will throw an error when called.
%  
%     * 'enabled'  :  true or false. If false, will be greyed out in
%                     nigeLab.libs.DashBoard.

%% Set "dependencies" for checking that stages are valid for `doMethods`
pars = struct;
pars.doAutoClustering = doAction({'Spikes'},true);
pars.doBehaviorSync= doAction({},false,{'Raw','Video'});
pars.doEventDetection = doAction({'Raw'},true);
pars.doEventHeaderExtraction = doAction({},false,{'Raw','Video'});
pars.doLFPExtraction = doAction({'Raw'},true);
pars.doRawExtraction = doAction({},true);
pars.doReReference = doAction({'Filt'},true);
pars.doSD = doAction({'CAR'},true);
pars.doUnitFilter = doAction({'Raw'},true);
pars.doVidInfoExtraction = doAction({},true,{});
pars.doVidSyncExtraction = doAction({},false,{'Raw','Video'});

%% Parse output
if nargin < 1
   varargout = {pars};
else
   varargout = cell(1,nargin);
   f = fieldnames(pars);
   for i = 1:nargin
      idx = ismember(lower(f),lower(varargin{i}));
      if sum(idx) == 1
         varargout{i} = pars.(f{idx});
      end
   end
end

% Helper function to make `doAction` param struct
   function doStruct = doAction(required,en,to_check_on_batch_run)
      %DOACTION  Helper function to create doAction struct
      %
      %  doStruct = doAction({'field1',...,'fieldk'}); Sets required fields
      %  doStruct = doAction(__,true); Sets 'enabled' to true
      
      if nargin < 1
         required = {};
      end
      
      if nargin < 2
         en = false;
      end
      
      if nargin < 3
         to_check_on_batch_run = {};
      end
      
      if ~isempty(to_check_on_batch_run) && ~isempty(required)
         error(['nigeLab:' mfilename ':BadConfig'],...
            '[DOACTIONS]: If .batch has members, .required should be empty.');
      end
      
      doStruct = struct;
      doStruct.required = required;
      doStruct.enabled = en;
      doStruct.batch = to_check_on_batch_run;
      
   end

end