function flag = checkParallelCompatibility(animalObj)
%CHECKPARALLELCOMPATIBILITY  Checks based on user preference and
%                             license/installation, whether the user can
%                             use parallel tools or not.

%% Check combination of user preference and installed toolkit/license
animalObj.updateParams('Queue');
qPars = animalObj.Pars.Queue;

pFlag = qPars.UseParallel; % Check user preference for using Parallel
rFlag = qPars.UseRemote;   % Check user preference for using Remote
uFlag = pFlag && rFlag;

lFlag = license('test','Distrib_Computing_Toolbox'); % Check if toolbox is licensed
dFlag = ~isempty(ver('distcomp'));  % Check if distributed-computing toolkit is installed

if (pFlag || rFlag) && ~(dFlag && lFlag) % If user indicates they want to run parallel or remote
   str = nigeLab.utils.getNigeLink('nigeLab.defaults.Queue',14,'configured');
   fprintf(1,['nigeLab is %s to use parallel or remote processing, '...
              'but encountered the following issue(s):\n'],str);
   if ~lFlag
      nigeLab.utils.cprintf('SystemCommands',['This machine does not '...
         'have the Parallel Computing Toolbox license.\n']);
   end
   
   if ~dFlag
      nigeLab.utils.cprintf('SystemCommands',['This machine does not '...
         'have the Distributed Computing Toolbox installed.\n']);
   end
end
   
flag = uFlag && lFlag && dFlag;

animalObj.UseParallel = flag;

%% Update all "Child" data objects
B = animalObj.Blocks; % All Blocks
setProp(B,'UseParallel',flag);

end