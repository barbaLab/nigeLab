% MARK CLUSTERS IN TEMPERATURE DIAGRAM

function temperature_diag(par,tree,clustering_results,temperature_ax,classes,auto_sort_info)

par.min.clus = clustering_results(1,5);

% creates cluster-temperature vector to plot in the temperature diagram
nclasses = max(classes);
class_plot = [];
for i=1:nclasses
    ind = find(classes==i);
    classgui_plot(i) = classes(ind(1));
    class_plot(i) = clustering_results(ind(1),4);
    if class_plot(i) == 0 %null original cluster
		class_plot(i) =1; %plot like they were from cluster 1
    end
    temp_plot(i) = clustering_results(ind(1),3);  
end

num_temp = floor((par.maxtemp ... 
-par.mintemp)/par.tempstep);     % total number of temperatures 

tree(num_temp+1,2) = par.mintemp+(num_temp)*par.tempstep; %added for handle selection of max temp

temperature = tree(clustering_results(1,1)+1,2);

colors = [[0.0 0.0 1.0];[1.0 0.0 0.0];[0.0 0.5 0.0];[0.620690 0.0 0.0];[0.413793 0.0 0.758621];[0.965517 0.517241 0.034483];
    [0.448276 0.379310 0.241379];[1.0 0.103448 0.724138];[0.545 0.545 0.545];[0.586207 0.827586 0.310345];
    [0.965517 0.620690 0.862069];[0.620690 0.758621 1.]]; 
maxc = size(colors,1);

% draw temperature diagram and mark clusters 
cla(temperature_ax);
switch par.temp_plot
    case 'lin'
        % draw diagram
        hold(temperature_ax, 'on');
        if ~isempty(auto_sort_info)
            [xp, yp] = find(auto_sort_info.peaks);
            ptemps = par.mintemp+(xp)*par.tempstep;
            psize = tree(sub2ind(size(tree), xp,yp+4));
            plot(temperature_ax,ptemps,psize,'xk','MarkerSize',7,'LineWidth',0.9);
            area(temperature_ax,par.mintemp+par.tempstep.*[auto_sort_info.elbow,num_temp],max(ylim(temperature_ax)).*[1 1],'LineStyle','none','FaceColor',[0.9 0.9 0.9]);
        end
        plot(temperature_ax, [par.mintemp par.maxtemp-par.tempstep],[par.min.clus2 par.min.clus2],'k:',...
            par.mintemp+(1:num_temp)*par.tempstep, ...
            tree(1:num_temp,5:size(tree,2)),[temperature temperature],[1 tree(1,5)],'k:')
        % mark clusters
        for i=1:min(size(tree,2)-4,length(class_plot))
            tree_clus = tree(temp_plot(i),4+class_plot(i));
            tree_temp = tree(temp_plot(i)+1,2);
            plot(temperature_ax, tree_temp,tree_clus,'.','color',colors(mod(classgui_plot(i)-1,maxc)+1,:),'MarkerSize',20);
        end
        set(get(gca,'ylabel'),'vertical','Baseline');
    case 'log'
        % draw diagram
        set(temperature_ax,'yscale','log');
        hold(temperature_ax, 'on');
        if ~isempty(auto_sort_info)
            [xp, yp] = find(auto_sort_info.peaks);
            ptemps = par.mintemp+(xp)*par.tempstep;
            psize = tree(sub2ind(size(tree), xp,yp+4));
            semilogy(temperature_ax,ptemps,psize,'xk','MarkerSize',7,'LineWidth',0.9);
            area(temperature_ax,par.mintemp+par.tempstep.*[auto_sort_info.elbow,num_temp],max(ylim(temperature_ax)).*[1 1],'LineStyle','none','FaceColor',[0.9 0.9 0.9],'basevalue',1);
        end
        semilogy(temperature_ax, [par.mintemp par.maxtemp-par.tempstep], ...
            [par.min.clus par.min.clus],'k:',...
            par.mintemp+(1:num_temp)*par.tempstep, ...
            tree(1:num_temp,5:size(tree,2)),[temperature temperature],[1 tree(1,5)],'k:')
        % mark clusters
        for i=1:length(class_plot)
            if class_plot(i)+4>size(tree,2)
                continue
            end
            tree_clus = tree(temp_plot(i),4+class_plot(i));
            tree_temp = tree(temp_plot(i)+1,2);
            semilogy(temperature_ax, tree_temp,tree_clus,'.','color',colors(mod(classgui_plot(i)-1,maxc)+1,:),'MarkerSize',20);
        end
        set(get(temperature_ax,'ylabel'),'vertical','Baseline');
end

% xlim(temperature_plot, [0 par.maxtemp])
xlabel(temperature_ax, 'Temperature','FontSize',8); 
ylabel(temperature_ax, 'Clusters size','FontSize',8);