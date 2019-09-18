function ExitFeatures(obj,src,evt)
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


if isvalid(obj.HighDimUI)
    delete(obj.HighDimUI.Figure);
end

if isvalid(obj.Figure)
   delete(obj.Figure);
end

end