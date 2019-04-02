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


 for iCh = chan
    [inspk] = blockObj.getSpikes(iCh,nan,'feat');                    %Extract spike features.
    class = blockObj.getSort(iCh);
    if ~ischar(unit)
       inspk = inspk(ismember(class,unit));
    end
    if size(inspk,1) < 15
        	cprintf('err','Channel %.3d: Not enough Spikes!\nLess than 15 spikes detected.',1);
         continue;
    end

    par.inputs = size(inspk,2);                               % number of inputs to the clustering
    ipermut = randperm(length(inspk));     
    inspk_aux = inspk(ipermut,:);
   
    
    %Interaction with SPC
    fname_in = par.fname_in;
    save(fname_in,'inspk_aux','-ascii');                      %Input file for SPC

    [clu,tree] = nigeLab.utils.SPC.run_cluster(par);
    
    blockObj.updateStatus('Clusters',true,iCh);
 end
    flag = true;
end

