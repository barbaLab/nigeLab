function CRC_ResetPushCallback(~,~,obj)
%% CRC_RESETPUSHCALLBACK   Callback function for RESET pushbutton

% Get current channel
ch = obj.Data.UI.ch;

% Reset all channel settings to "read-in" status
obj.Data.cl.num.class.cur{ch} = obj.Data.cl.num.class.in{ch};
obj.Data.cl.num.assign.cur{ch} = 1:obj.Data.NCLUS_MAX;
obj.Data.cl.sel.cur(ch,:) = obj.Data.cl.sel.in(ch,:);
obj.Data.cl.sel.base(ch,:) = obj.Data.cl.sel.in(ch,:);
obj.Data.spk.include.cur{ch} = obj.Data.spk.include.in{ch};

% Update the UI
CRC_UpdateClusterAssignments(obj);
CRC_PlotSpikes(obj);
CRC_PlotFeatures(obj);
CRC_ResetFeatureAxes(obj);

% If debugging, update handles in base workspace
if obj.Data.DEBUG
   handles = obj.Data;
   CRC_mtb(handles);
end
        
end