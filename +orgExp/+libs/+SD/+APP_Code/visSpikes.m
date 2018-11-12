function [sort_n,sort_ind] = visSpikes(spikes,class,varargin)
%% VISSPIKES   Visualize spike cluster assignments
%
%  [sort_n,sort_ind] = visSpikes(spikes,class,'NAME',value,...)
%
%  --------
%   INPUTS
%  --------
%   spikes     :     nSpikes x nSamples (per spike) matrix
%
%   class      :     Class (integer) assigned to each spike 
%                       (vector: nSpikes x 1)
%
%  varargin    :     (Optional) 'NAME', value input argument pairs
%
%     -> MAX_PLOT_CLUS || 5 (def) [max. # of spike clusters to plot]
%
%     -> PLOT_SPIKES || false (def) [whether or not to plot spikes at all]
%
%     -> SPIKE_YLIM || [-250 150] (def) [y-limit of spike plots]
%
%     -> N_SPIKES_MAX || 250 (def) [max. # of spikes to plot]
%
%  --------
%   OUTPUT
%  --------
%   sort_n     :     Number of elements in each cluster (sorted in
%                    descending order of cluster size).
%
%   sort_ind   :     Original cluster class assignments.
%
% By: Max Murphy  v1.0  01/09/2018  Original version (R2017a)

%% DEFAULTS
MAX_PLOT_CLUS = 9;
N_SPIKES_MAX = 500;
PLOT_SPIKES = true;
SPIKE_YLIM = [-250 150];
PROP_YLIM = [0.0 1.0];

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%%
if abs(min(class)<=eps)
   n = zeros(max(class)+1,1);
   for ii = 0:(numel(n)-1)
      n(ii+1) = sum(class==ii);
   end
   [sort_n,sort_ind] = sort(n,'descend');
   
   if PLOT_SPIKES
      N = min(MAX_PLOT_CLUS,numel(unique(class)));
      for ii = 1:N
         str = sprintf('Class %03d',sort_ind(ii)-1);
         xo = max(randn(1) * 0.075,-0.25);
         yo = max(randn(1) * 0.075,-0.25);
         figure('Name',[str ' (spikes)'],...
            'Units','Normalized',...
            'Color','w',...
            'Position',[0.25 + xo, 0.25 + yo, 0.5, 0.5]);
         spike_subset = spikes(class==(sort_ind(ii)-1),:);
         col = get(gca,'ColorOrder');
         col = col(rem(ii-1,size(col,1))+1,:);
         ind = RandSelect(1:size(spike_subset,1),N_SPIKES_MAX);
         subplot(2,1,1);
         plot(spike_subset(ind,:).','Color',col,'LineWidth',1.5);
         title(str,'FontName','Arial','FontSize',16);
         ylim(SPIKE_YLIM);
         xlim([1,size(spikes,2)]);
         
         set(gca,'FontName','Arial');
         set(gca,'FontSize',12);
         set(gca,'TickDir','out');
         box off;
         
         subplot(2,1,2);
         bvec = 1:N;
         yvec = cumsum(sort_n(1:N))./sum(sort_n);
         b = bvec(ii);
         y = yvec(ii);
         bvec(ii) = [];
         yvec(ii) = [];
         bar(bvec,yvec,0.95,...
              'EdgeColor','none',...
              'FaceColor','k');
         hold on;
         bar(b,y,0.95,...
            'EdgeColor',[0.66 0.66 0.66],...
            'FaceColor',col,...
            'LineWidth',2.5);
         hold off;
         title(sprintf('N = %d',sort_n(ii)),...
            'FontName','Arial',...
            'FontSize',14,...
            'FontWeight','bold');
         ylim(PROP_YLIM);
         xlim([0.5 N+0.5]);
         ylabel('Proportion','FontName','Arial','FontSize',14);
         
         set(gca,'FontName','Arial');
         set(gca,'FontSize',12);
         set(gca,'TickDir','out');
         set(gca,'XTick',1:N);
         box off;
      end
   end
else
   n = zeros(max(class),1);
   for ii = 1:(numel(n))
      n(ii) = sum(class==ii);
   end
   [sort_n,sort_ind] = sort(n,'descend');
   
   if PLOT_SPIKES
      N = min(MAX_PLOT_CLUS,numel(unique(class)));
      for ii = 1:N
         str = sprintf('Class %03d',sort_ind(ii));
         xo = max(randn(1) * 0.075,-0.25);
         yo = max(randn(1) * 0.075,-0.25);
         figure('Name',[str ' (spikes)'],...
            'Units','Normalized',...
            'Color','w',...
            'Position',[0.25 + xo, 0.25 + yo, 0.5, 0.5]);
         
         subplot(2,1,1);
         spike_subset = spikes(class==sort_ind(ii),:);
         col = get(gca,'ColorOrder');
         col = col(rem(ii-1,size(col,1))+1,:);
         ind = RandSelect(1:size(spike_subset,1),N_SPIKES_MAX);
         plot(spike_subset(ind,:).','Color',col,'LineWidth',1.5);
         title(str,'FontName','Arial','FontSize',16);
         ylim(SPIKE_YLIM);
         xlim([1,size(spikes,2)]);
         
         set(gca,'FontName','Arial');
         set(gca,'FontSize',12);
         set(gca,'TickDir','out');
         box off;
         
         subplot(2,1,2);
         bvec = 1:N;
         yvec = cumsum(sort_n(1:N))./sum(sort_n);
         b = bvec(ii);
         y = yvec(ii);
         bvec(ii) = [];
         yvec(ii) = [];
         bar(bvec,yvec,0.95,...
              'EdgeColor','none',...
              'FaceColor','k');
         hold on;
         bar(b,y,0.95,...
            'EdgeColor',[0.66 0.66 0.66],...
            'FaceColor',col,...
            'LineWidth',2.5);
         hold off;
         title(sprintf('N = %d',sort_n(ii)),...
            'FontName','Arial',...
            'FontSize',14,...
            'FontWeight','bold');
         ylim(PROP_YLIM);
         xlim([0.5 N+0.5]);
         ylabel('Proportion','FontName','Arial','FontSize',14);
         
         set(gca,'FontName','Arial');
         set(gca,'FontSize',12);
         set(gca,'TickDir','out');
         set(gca,'XTick',1:N);
         box off;
      end
   end
end



end