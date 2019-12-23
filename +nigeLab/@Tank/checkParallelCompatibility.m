function flag = checkParallelCompatibility(tankObj)
%CHECKPARALLELCOMPATIBILITY  Checks based on user preference and
%                             license/installation, whether the user can
%                             use parallel tools or not.

%% Check combination of user preference and installed toolkit/license
tankObj.updateParams('Queue');
qPars = tankObj.Pars.Queue;

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

tankObj.UseParallel = flag;

if (nargout < 1)
   nigeLab.utils.cprintf('Comments','Tank (%s) flagged for ',tankObj.Name);
   if flag
      nigeLab.utils.cprintf('*Strings','Parallel Processing\n');
   else
      
      nigeLab.utils.cprintf('*Strings','Serial Processing\n');
   end
end

%% Update all "Child" data objects
A = tankObj.Animals; % All Animals
setProp(A,'UseParallel',flag);
for i = 1:numel(A)
   B = A.Blocks; % All Blocks
   setProp(B,'UseParallel',flag);
end

end