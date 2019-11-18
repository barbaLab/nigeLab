function flag = checkForWorker(mode)
if nargin < 1
    flag = false;
    qParams = nigeLab.defaults.Queue;
    if    qParams.UseParallel...              check user preference
            && license('test','Distrib_Computing_Toolbox')... check if toolbox is licensed
            && ~isempty(ver('distcomp'))...           and check if it's installed
            
        job = getCurrentJob;
        flag = ~isempty(job);            % if job is empyty, we are running locally. Or at least not on a worker.
        
    elseif   (~license('test','Distrib_Computing_Toolbox')... 
            || isempty(ver('distcomp')) ) && qParams.UseParallel ...
            %% otherwise prompt the user to install the toolboxes.
            
        nigeLab.utils.cprintf('SystemCommands','Parallel computing toolbox might be uninstalled or unlicesend on thi machine.\n');
        nigeLab.utils.cprintf('Comments','But no worries: your code will still be executed serially. This might be slower...\n');
    end
    
elseif strcmpi(mode,'config')  % nargin > 0
    %% in config mode checkForWorker and run the config script
    flag = false;
    if nigeLab.utils.checkForWorker()
        configW;     % run the programmatically generated configuration script
        flag = true;
    end
    
end