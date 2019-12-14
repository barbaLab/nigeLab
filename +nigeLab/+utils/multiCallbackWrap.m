function multiCallbackWrap(ObjH, EventData,fcnList)
% MULTICALLBACKWRAP  Wraps multiple funtions into a single callback
% usage :
% fcnList = {@myfunc0, @myfunc1, @myfunc2};
% obj = uicontrol(...
%     'Callback', {@nigeLab.Utils.multiCallbackWrap, fcnList});
%
% or if input arguments are needed
%
% fcnList = {{@(x1,...xn)myfunc0(x1,...xn),arg00,arg01,...,arg0n},
%            {@(x1,...xn)myfunc1(x1,...xn),arg10,arg11,...,arg1n},
%            {@(x1,...xn)myfunc2(x1,...xn),arg20,arg21,...,arg2n},
%           };
% obj = uicontrol(...
%     'Callback', {@nigeLab.Utils.multiCallbackWrap, fcnList});

if ~isscalar(fcnList)
   for iFcn = 1:numel(fcnList)
      nigeLab.utils.multiCallbackWrap(ObjH,EventData,fcnList{iFcn});
   end
   return;
end

if iscell(fcnList)
   thisFunction = fcnList{1};
   argsIn = fcnList;
   argsIn(1) = [];
else
   thisFunction = fcnList;
   argsIn = {};
end

% If function handle is empty, continue
if isempty(thisFunction)
   return;
end   

feval(thisFunction, ObjH, EventData, argsIn{:});
   
end


end