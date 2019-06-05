function flag = doAutoClustering(blockObj,chan,unit)
flag = false;
par = nigeLab.defaults.SPC;
%% runs automatic clustering algorithms
switch nargin
   case 1
      chan = blockObj.Mask;
      unit = 'all';
   case 2
      unit = 'all';
end

fprintf(1,'Performing auto clustering... %.3d%%',0);

ProgressPath = fullfile(tempdir,['doAutoClustering',blockObj.Name]);
fid = fopen(ProgressPath,'wb');
fwrite(fid,numel(blockObj.Mask),'int32');
fclose(fid);

 for iCh = chan
    [inspk] = blockObj.getSpikes(iCh,nan,'feat');                    %Extract spike features.
    SuppressText = true;
    classes = blockObj.getSort(iCh,SuppressText);
    offs = max(unique(classes));
    if ~ischar(unit)
       ind = find(ismember(classes,unit));
    else
       ind = 1:numel(classes);
    end
    
    inspk = inspk(ind,:);
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
       ind = ipermut;
    else
       if par.match == 'y'
          naux = min(par.max_spk,size(inspk,1));
          
       else
          naux  = size(inspk,1);
       end
       inspk_aux = inspk(1:naux,:);
       ind = 1:naux;
    end
    

    [temp,classes_] = SPCrun(par,inspk_aux);
    if isempty(temp),temp=0;end

    %     setappdata(handles.temperature_plot,'auto_sort_info',auto_sort);
    % definition of clustering_results
    
    
%     nigeLab.utils.SPC.temperature_diag(par,tree,clustering_results,gca,classes,auto_sort);
      classes(ind) = classes_; 
      [temp,classes]=checkclasses(temp,classes);
      saveSorted(blockObj,classes,iCh,temp);
    
    blockObj.updateStatus('Clusters',true,iCh);
  pc = 100 * (iCh / blockObj.NumChannels);
   if ~floor(mod(pc,5)) % only increment counter by 5%
      fprintf(1,'\b\b\b\b%.3d%%',floor(pc))
   end
   fid = fopen(fullfile(ProgressPath),'ab');
   fwrite(fid,1,'uint8');
   fclose(fid);
end
fprintf(1,'\b\b\b\bDone.\n');
    flag = true;
end

function saveSorted(blockObj,classes,iCh,temp)
      if not(iscolumn(classes)),classes=classes';end
      ts = getSpikeTimes(blockObj,iCh);
      n = numel(ts);
      data = [zeros(n,1) classes temp*ones(n,1) ts ];
      
      % initialize the 'Sorted' DiskData file
      fType = blockObj.getFileType('Clusters');
      fName = fullfile(sprintf(strrep(blockObj.Paths.Clusters.file,'\','/'),...
         num2str(blockObj.Channels(iCh).probe),...
         blockObj.Channels(iCh).chStr));
      if exist(blockObj.Paths.Clusters.dir,'dir')==0
         mkdir(blockObj.Paths.Clusters.dir);
      end
      blockObj.Channels(iCh).Clusters = nigeLab.libs.DiskData(fType,...
         fName,data,'access','w');
end

function [Temp,classes] = SPCrun(par,inspk_aux)
       %Interaction with SPC
    workdir = fullfile(fullfile(fileparts(fileparts(mfilename('fullpath')))),'+utils','+SPC');

    par.fname_in = fullfile(par.fname_in);
    save(fullfile(workdir,par.fname_in),'inspk_aux','-ascii');                      %Input file for SPC

    [clu,tree] = nigeLab.utils.SPC.run_cluster(par);
        
    [clust_num,temp,auto_sort] = nigeLab.utils.SPC.find_temp(tree,clu, par);
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
    
    [Temp,classes]=checkclasses(current_temp,classes);
    
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
    if isempty(classes_names),return;end
    if sum(classes_names) ~= classes_names(end)*(classes_names(end)+1)/2
       for i= 1:length(classes_names)
          c = classes_names(i);
          if c~= i
             classes(classes == c) = i;
          end
          Temp(i) = temp(i);
       end
    end
    
end