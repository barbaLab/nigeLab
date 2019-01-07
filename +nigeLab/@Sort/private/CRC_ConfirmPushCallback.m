function CRC_ConfirmPushCallback(src,~,obj)
%% CRC_CONFIRMPUSHCALLBACK Callback function for CONFIRM pushbutton

% Update all assignments
ch = obj.Data.UI.ch;
obj.Data.cl.num.assign.cur{ch} = 1:obj.Data.NCLUS_MAX;
obj.Data.cl.sel.base(ch,:) = obj.Data.cl.sel.cur(ch,:);
obj.Data.files.submitted(obj.Data.UI.ch) = true;

% Set "in" and "out" spikes
obj.Data.spk.include.cur{ch}(obj.Data.cl.num.class.cur{ch}==1) = true;
% Not currently using: may bring back later if have other "restriction"
% obj.Data.spk.include.cur{ch}(obj.Data.cl.num.class.cur{ch}==1) = false; 
obj.Data.spk.include.cur{ch}(obj.Data.cl.num.class.cur{ch}>1) = true;

% Update the button as feedback
src.FontWeight = 'normal';
src.ForegroundColor = 'w';
src.BackgroundColor = 'b';

% Update the rest of the UI
clu_list = obj.Data.cl.num.assign.cur{ch};
for iC = 1:obj.Data.NCLUS_MAX
   A = sort(vertcat(obj.Data.cl.sel.cur{ch, ...
      obj.Data.cl.num.assign.cur{ch}==iC}),'ascend');
   if iC > 1
      A = A(obj.Data.spk.include.cur{ch}(A));
   end
   
   % Redo all assignments
   obj.SpikeImage.Clusters{iC} = obj.SpikeImage.Spikes(A,:);
   
   % Redo all condensed image plots
   [obj.SpikeImage.C{iC}, obj.SpikeImage.Assignments{iC}] = ...
      obj.SpikeImage.CRC_UpdateImage(iC);
   
   % Plot image on appropriate axis
   obj.SpikeImage.CRC_ReDraw(iC,clu_list(iC));
end


CRC_UpdateClusterAssignments(obj)

if obj.Data.FORCE_NEXT
   obj.Data.UI.ch = min(ch + 1,obj.Data.files.N);
   chanpop.Value = obj.Data.UI.ch;
   CRC_ChannelPopCallback(chanpop);
end

if ~any(~obj.Data.files.submitted)
   obj.Submit.FontWeight = 'bold';
   obj.Submit.BackgroundColor = [0 1 0];
   obj.Submit.ForegroundColor = 'k';
end

% If debugging, update obj.Data in base workspace
if obj.Data.DEBUG
   handles = obj.Data;
   CRC_mtb(handles);
end

end