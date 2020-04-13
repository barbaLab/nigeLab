function ExitFeatures(obj,~,~)
%% EXITFEATURES    Exit the scoring interface
         
% Remove the channel selector UI, if it exists
% if isvalid(obj.ChannelSelector.Figure)
%    delete(obj.ChannelSelector.Figure);
%    clear obj.ChannelSelector
% end
% 
% % Remove the spike interface, if it exists
% if isvalid(obj.SpikeImage.Figure)
%    delete(obj.SpikeImage.Figure);
%    clear obj.SpikeImage
% end

if ~isempty(obj.HighDimsUI)
   if isvalid(obj.HighDimsUI)
       delete(obj.HighDimsUI.Figure);
   end
end

if ~isempty(obj.Figure)
   if isvalid(obj.Figure)
      delete(obj.Figure);
   end
end
end