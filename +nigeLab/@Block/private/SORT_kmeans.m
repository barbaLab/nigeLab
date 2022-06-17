
function [classes,temp] = SORT_kmeans(inspk,par)
warning off
GPUavailable = false;
if par.UseGPU
   try
      inspk = gpuArray(inspk(:,:));     % we need inspk as column for KMEANS
      GPUavailable = true;
   catch
      warning('gpuArray non available. Computing on CPU;');
   end
end

switch par.NClus
   % set Klist, list of K to try with KMEANS
   case 'best'
      Klist = 1:pars.MaxNClus;
      if GPUavailable
         % sadly evalcluster is broken with gpuArrays, at least on 2017a
         % workarouund, compute the cluster solution outside evalclust and
         % use it only to evaluate the solution.
         
         ClustSolutions = zeros(numel(inspk),numel(Klist));
         for ii=Klist
            ClustSolutions(:,ii) = gather(kmeans(inspk,Klist(ii)));
         end
         evals = evalclusters(inspk,ClustSolutions,'Silhouette');
         classes = evals.OptimalY;
      else
         inspk = inspk(:);
         evals = evalclusters(inspk,'kmeans','Silhouette','Klist',Klist);
         classes = evals.OptimalY;
      end
      
   case 'max'
      Klist = min(par.NMaxClus,ceil(size(inspk,1)/100));
      classes = kmeans(inspk,Klist);
end

temp = par.NMaxClus;
end
