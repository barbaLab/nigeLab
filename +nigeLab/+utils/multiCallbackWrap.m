function multiCallbackWrap(ObjH, EventData, fcnList)
%% wrapper to define multiple funtions in a single callback
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

for iFcn = 1:length(fcnList)
    if iscell(fcnList{iFcn})
        thisFunction = fcnList{iFcn};
    else
        thisFunction = fcnList(iFcn);
    end
    feval(thisFunction{1}, ObjH, EventData,thisFunction{2:end});
end

end