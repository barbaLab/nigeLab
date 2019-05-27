function Recluster(obj)
par = nigeLab.defaults.SPC;

ch = obj.Parent.UI.ch;
unit = obj.Spikes.CurClass;
classes = obj.Spikes.Class;
inspk = obj.Parent.spk.feat{ch};

%% runs automatic clustering algorithms

fprintf(1,'Performing reclustering...');

    offs = max(unique(classes))-1;
    subsetIndex = find(ismember(classes,unit));

    
    inspk = inspk(subsetIndex,:);
    if size(inspk,1) < 15
       nigeLab.utils.cprintf('err','Channel %.3d: Not enough Spikes!\nLess than 15 spikes detected.',1);
         return;
    end

    par.inputs = size(inspk,2);                               % number of inputs to the clustering
    
    if par.permut == 'y'
       if par.match == 'y'
          naux = min(par.max_spk,size(inspk,1));
          ipermut = randperm(length(inspk));
          ipermut(naux+1:end) = [];
       else
          ipermut = randperm(length(inspk));
       end
       inspk_aux = inspk(ipermut,:);
    else
       if par.match == 'y'
          naux = min(par.max_spk,size(inspk,1));
          inspk_aux = inspk(1:naux,:);
       else
          inspk_aux = inspk;
       end
    end
    

    [temp,classes_] = SPCrun(par,inspk_aux);
    

    %     setappdata(handles.temperature_plot,'auto_sort_info',auto_sort);
    % definition of clustering_results
    
    
%     nigeLab.utils.SPC.temperature_diag(par,tree,clustering_results,gca,classes,auto_sort);
      classes = ones(size(classes_));
      classes(classes_~=0) = classes_(classes_~=0)+offs;
%       classes_ = 1+classes_+(classes_~=0)*offs; 

   uclass = unique(classes);
for ii= uclass
   iMove = classes==ii;
   obj.Spikes.CurClass = ii;
   evtData = nigeLab.evt.assignmentEventData(subsetIndex(iMove),...
      ii,unit);
   obj.UpdateClusterAssignments(nan,evtData);
end
fprintf(1,' done.\n');

end

function [Temp,classes] = SPCrun(par,inspk_aux)
       %Interaction with SPC
    workdir = fullfile(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath'))))),'+utils','+SPC');

    par.fname_in = fullfile(par.fname_in);
    save(fullfile(workdir,par.fname_in),'inspk_aux','-ascii');                      %Input file for SPC

    [clu,tree] = nigeLab.utils.SPC.run_cluster(par);
        
    [clust_num temp auto_sort] = nigeLab.utils.SPC.find_temp(tree,clu, par);
    current_temp = max(temp);
    classes = zeros(1,size(clu,2)-2);
%     for c =1: length(clust_num)
%        aux = clu(temp(c),3:end) +1 == clust_num(c);
%        classes(aux) = c;
%     end
% Same but vectorized
 classes = sum( (clu(temp,3:end) +1 == clust_num) .* (1:numel(clust_num))',1);

    
    if par.permut == 'n'
       classes = [classes zeros(1,max(size(spikes,1)-size(clu,2)-2,0))];
    end
    
    [Temp,classes]=checkclasses(temp,classes);
    
%     clustering_results = [];
%     clustering_results(:,1) = repmat(current_temp,length(classes),1); % temperatures
%     clustering_results(:,2) = classes'; % classes
%     
%     for i=1:max(classes)
%        clustering_results(classes==i,3) = Temp(i);
%        clustering_results(classes==i,4) = clust_num(i); % original classes
%     end
%     
%     clustering_results(:,5) = repmat(par.min_clus,length(classes),1);
%     

    
end

function [Temp,classes]=checkclasses(temp,classes)

    Temp = temp;
    % Classes should be consecutive numbers
    classes_names = nonzeros(sort(unique(classes)));
%     if sum(classes_names) ~= classes_names(end)*(classes_names(end)+1)/2
       for i= 1:length(classes_names)
          c = classes_names(i);
          if c~= i
             classes(classes == c) = i;
          end
          Temp(i) = temp(i);
       end
%     end
    
end