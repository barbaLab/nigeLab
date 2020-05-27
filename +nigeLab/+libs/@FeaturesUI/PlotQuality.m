function PlotQuality(obj)
%% PLOTFEATURES  Plot cluster features from SORT UI in 3D and 2D.
if ~isvalid(obj.Figure)
    return;
end
set(obj.Figure,'Pointer','watch');
obj.UpdateSil;
% indx = obj.QualityIndx.UserData{2};
curCh = obj.ChannelSelector.Channel;
cl = obj.Data.class{curCh};
silh = obj.SilScores;
obj.QualityBars=[];
% Create the bars:  group silhouette values into clusters, sort values
% within each cluster.  Concatenate all the bars together, separated by
% empty bars.  Locate each tick midway through each group of bars
n = length(cl(obj.rsel));
space = max(floor(.02*n), 2);
bars = NaN(space,1);
clS = bars;
tcks(1) = length(bars);
for i = 1:max(cl)
    tmp =  -sort(-silh( cl(obj.rsel) == i) );
    bars = [bars;tmp; NaN(space,1);];
    tcks(i) = length(bars);
    clS = [clS; ones(size(tmp))*i;NaN(space,1);];
end
tcks = tcks - 0.5*(diff([space tcks]) + space - 1);


% Loop through each subset of 3 features
cla(obj.Silhouette);
cnames = cellstr(num2str((0:max(cl)-1)'));
obj.QualityBars = bar(obj.Silhouette,bars, 1.0);
Y = obj.QualityBars.XData;
cla(obj.Silhouette);
hold(obj.Silhouette,'on');
for ii=1:obj.NCLUS_MAX
    if ii==1
        col = [0.15 0.15 0.15];
    else
        col= obj.COLS{ii};
    end
    %    if sum(clS==ii) > obj.MINSPIKES
    if sum(clS==ii)==0,continue;end
    bb = bar(obj.Silhouette,Y(clS==ii),bars(clS==ii), 1.0,'FaceColor',col,'EdgeColor','none');
    if ~obj.VisibleClusters(ii),bb.Visible = 'off';end
    %    end
    
    
    %    I = 0.5:1/sum(indx)/2:1.5;
    %    I = I(2:2:end)+ii-1;
end

% ylim(obj.Silhouette,[-.5 .5]);
set(obj.Silhouette, 'Ylim', [-.5 .5] ,'Xlim',[1 length(bars)], 'XDir','reverse', 'XTick',tcks, 'XTickLabel',cnames);
set(obj.Figure,'Pointer','arrow');

end
