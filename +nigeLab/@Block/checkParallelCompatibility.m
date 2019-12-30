function flag = checkParallelCompatibility(blockObj)
%CHECKPARALLELCOMPATIBILITY  Checks based on user preference and
%                             license/installation, whether the user can
%                             use parallel tools or not.

%% Check combination of user preference and installed toolkit/license
nigeLab.utils.cprintf('Comments','Checking parallel compatibility...');
blockObj.updateParams('Queue');
qPars = blockObj.Pars.Queue;

pFlag = qPars.UseParallel; % Check user preference for using Parallel
rFlag = qPars.UseRemote;   % Check user preference for using Remote
uFlag = pFlag && rFlag;

lFlag = license('test','Distrib_Computing_Toolbox'); % Check if toolbox is licensed
dFlag = ~isempty(ver('distcomp'));  % Check if distributed-computing toolkit is installed

if (pFlag || rFlag) && ~(dFlag && lFlag) % If user indicates they want to run parallel or remote
   str = nigeLab.utils.getNigeLink('nigeLab.defaults.Queue',14,'configured');
   fprintf(1,['\n-->\tnigeLab is %s to use parallel or remote processing, '...
              'but encountered the following issue(s):\n'],str);
   if ~lFlag
      nigeLab.utils.cprintf('SystemCommands',['This machine does not '...
         'have the Parallel Computing Toolbox license.\n']);
   end
   
   if ~dFlag
      nigeLab.utils.cprintf('SystemCommands',['This machine does not '...
         'have the Distributed Computing Toolbox installed.\n']);
   end
   nigeLab.utils.cprintf('Magenta*',' UseParallel==false');
   nigeLab.utils.cprintf('Text','(disabled)\n');
else
   nigeLab.utils.cprintf('Magenta*',' UseParallel==true');
   nigeLab.utils.cprintf('Text','(enabled)\n');
end
   
flag = uFlag && lFlag && dFlag;

blockObj.UseParallel = flag;

end