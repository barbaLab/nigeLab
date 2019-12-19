function Recluster(obj)
par = nigeLab.defaults.AutoClustering;

ch = obj.Parent.UI.ch;
unit = obj.Spikes.CurClass;
classes = obj.Spikes.Class;
inspk = obj.Parent.spk.feat{ch};
spks =  obj.Parent.spk.spikes{ch};
%% runs automatic clustering algorithms

fprintf(1,'Performing reclustering...');

    offs = numel(unique(classes))-1;
    subsetIndex = find(ismember(classes,unit));

    spks = spks(subsetIndex,:);
    inspk = inspk(subsetIndex,:);
    if size(inspk,1) < 15
       nigeLab.utils.cprintf('err','Channel %.3d: Not enough Spikes!\nLess than 15 spikes detected.',1);
         return;
    end
    
%% TODO, permuting spikes
%     if par.permut == 'y'
%        if par.match == 'y'
%           naux = min(par.max_spk,size(inspk,1));
%           ipermut = randperm(length(inspk));
%           ipermut(naux+1:end) = [];
%        else
%           ipermut = randperm(length(inspk));
%        end
%        inspk_aux = inspk(ipermut,:);
%     else
%        if par.match == 'y'
%           naux = min(par.max_spk,size(inspk,1));
%           inspk_aux = inspk(1:naux,:);
%        else
%           inspk_aux = inspk;
%        end
%     end
    
%% Perfomring clustering

[coeff,score,~,~,expl,~] = pca(spks);
inspk=[inspk score(:,1:find(cumsum(expl)>95,1))];

%     [classes,temp] = nigeLab.utils.SPC.DoSPC(par,inspk);
try
    inspk = gpuArray(inspk);
catch
    warning('gpuArray non available. Computing on CPU;');
end
classes = gather(kmeans(inspk,9-offs));
classes(classes~=1)=classes(classes~=1)+offs;
classes(classes==1)=unit;
%% Moving spikes
   uclass = unique(classes);
   if iscolumn(uclass),uclass=uclass';end
for ii= uclass
   iMove = classes==ii;
   obj.Spikes.CurClass = ii;
   evtData = nigeLab.evt.assignmentEventData(subsetIndex(iMove),...
      ii,unit);
   obj.UpdateClusterAssignments(nan,evtData);
end
fprintf(1,' done.\n');

end
