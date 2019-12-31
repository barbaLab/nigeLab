function pars = doActions(name)
% DOACTIONS  Default method to return "dependencies" for doActions
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

%%
pars = struct;
pars.doAutoClustering = doAction({'Spikes'},true);
pars.doBehaviorSync= doAction({'Video'});
pars.doEventDetection = doAction();
pars.doEventHeaderExtraction = doAction({'Video'});
pars.doLFPExtraction = doAction({'Raw'},true);
pars.doRawExtraction = doAction({},true);
pars.doReReference = doAction({'Filt'},true);
pars.doSD = doAction({'CAR'},true);
pars.doUnitFilter = doAction({'Raw'},true);
pars.doVidInfoExtraction = doAction({'Video'});
pars.doVidSyncExtraction = doAction({'Video'});

if nargin > 0
   pars = pars.(name);
end

   function doStruct = doAction(required,en)
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
      
      doStruct = struct;
      doStruct.required = required;
      doStruct.enabled = en;
   end

end