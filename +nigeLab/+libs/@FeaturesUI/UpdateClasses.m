function UpdateClasses(obj,~,evt)
%% UPDATECLASSES  Listens for and updates the classes for a given channel
%
%  addlistener(obj.SpikeImage,'ClassAssigned',@obj.UPDATECLASSES);

%%
obj.Data.class{obj.ChannelSelector.Channel}(evt.subs) = evt.class;
obj.PlotFeatures;

% update quality indxes
% obj.SilScores =  zeros(numel(obj.SilDist),obj.NCLUS_MAX);
obj.PlotQuality;
end
