qParams = nigeLab.defaults.Queue;
if    qParams.UseParallel...              check user preference
   && license('test','Distrib_Computing_Toolbox')... check if toolbox is licensed
   && ~isempty(ver('distcomp'))...           and check if it's installed
 
    job = getCurrentJob;
    if ~isempty(job) % we are on a remote worker
        configW;     % run the programmatically generated configuration script
    end
    
elseif   (~license('test','Distrib_Computing_Toolbox')... check if toolbox is licensed
           || isempty(ver('distcomp')) ) && qParams.UseParallel ...
    
       nigeLab.utils.cprintf('SystemCommands','Parallel computing toolbox might be uninstalled or unlicesend on thi machine.');
       nigeLab.utils.cprintf('Comments','But no worries: your code will still be executed serially. This might be slower...\n');
end