function flag = checkForWorker(mode)
% CHECKFORWORKER  Checks for worker to determine if this is being run on
%                 local machine or remote server. Also uses the settings in
%                 nigeLab.defaults.Queue as a heuristic if no input
%                 arguments are provided.
%
%  flag = nigeLab.utils.checkForWorker();  Return true if on REMOTE
%
%  flag = nigeLab.utils.checkForWorker('config');
%  --> Runs procedurally generated configuration script, configW (?)

if nargin < 1
    flag = false;
    qParams = nigeLab.defaults.Queue;
    if ~qParams.UseParallel && ~qParams.UseRemote
       flag = false;
       return;
    end
    
    if    qParams.UseParallel...              check user preference
            && license('test','Distrib_Computing_Toolbox')... check if toolbox is licensed
            && ~isempty(ver('distcomp'))...           and check if it's installed
            
        job = getCurrentJob;
        
        % if job is empty, we are running locally. 
        % Or at least not on a worker.
        flag = ~isempty(job);            
        
    elseif   (~license('test','Distrib_Computing_Toolbox')... 
               || isempty(ver('distcomp')))...
            && qParams.UseParallel
         
       % Prompt the user to install the correct toolboxes
            
        nigeLab.utils.cprintf('SystemCommands','Parallel computing toolbox might be uninstalled or unlicensed on this machine.\n');
        nigeLab.utils.cprintf('Comments','But no worries: your code will still be executed serially.\n');
        nigeLab.utils.cprintf('Comments','However, depending on recording size, this can take substantially longer.\n');
    end
    
elseif strcmpi(mode,'config')  % nargin > 0
    %% in config mode checkForWorker and run the config script
    flag = false;
    if nigeLab.utils.checkForWorker()
        configW;     % run the programmatically generated configuration script; this is generated in qOperations
        flag = true;
    end
    
end