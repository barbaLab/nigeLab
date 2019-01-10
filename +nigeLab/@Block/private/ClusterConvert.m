function ClusterConvert(blockObj)
%% WIP
warning(['ClusterConvert function was called.' newline 'Work in progress! Might not work as expected'])
CLUSTER_LIST = {'CPLMJS'; ...
            'CPLMJS2'; ... % MJS profiles to use
            'CPLMJS3'};
        NWR          = [1 2];     % Number of workers to use
        WAIT_TIME    = 60;        % Wait time for looping if using findGoodCluster
        INIT_TIME    = 2;         % Wait time before initializing findGoodCluster
        UNC_PATH = {'\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data\'; ...
            '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\'};
        
switch blockObj.RecType
    case 'Intan'
        F = dir(fullfile(blockObj.DIR,'*.rh*'));
        Name = strsplit(blockObj.DIR,filesep);
        Name = Name{numel(Name)};
        
        if numel(F) > 1
            ind = listdlg('PromptString','Select files to extract:',...
                'SelectionMode','multiple',...
                'ListString',{F.name}.');
            temp = F;
            F = cell(numel(ind),1);
            iCount = 1;
            for iF = ind
                F{iCount} = temp(iF).name;
                iCount = iCount + 1;
            end
            clear temp
        else
            F = {F.name};
        end
        
        ftype = cell(numel(F),1);
        for iF = 1:numel(F)
            ftype{iF} = F{iF}(end-2:end);
        end
        
        
        
        %% GET CLUSTER WITH AVAILABLE WORKERS
        for iF = 1:numel(F)
            if exist('CLUSTER','var')==0 % Otherwise, use "default" profile
                fprintf(1,'Searching for Idle Workers...');
                CLUSTER = findGoodCluster('CLUSTER_LIST',CLUSTER_LIST,...
                    'NWR',NWR, ...
                    'WAIT_TIME',WAIT_TIME, ...
                    'INIT_TIME',INIT_TIME);
                fprintf(1,'Beating them into submission...');
            end
            
            myCluster = parcluster(CLUSTER);
            fprintf(1,'Creating Job...');
            j = createCommunicatingJob(myCluster, ...
                'AttachedFiles', ATTACHED_FILES,...
                'Type', 'pool', ...
                'Name', ['Intan extraction ' Name], ...
                'NumWorkersRange', NWR, ...
                'FinishedFcn', @JobFinishedAlert, ...
                'Type','pool', ...
                'Tag', ['Extracting INTAN files for: ' Name '...']);
            
            IN_ARGS = {blockObj,'NAME',fullfile(DIR,F{iF}),...
                'GITINFO',gitInfo,...
                'SAVELOC',SAVELOC,...
                'STIM_SUPPRESS',STIM_SUPPRESS,...
                'STIM_P_CH',STIM_P_CH,...
                'STIM_BLANK',STIM_BLANK,...
                'STATE_FILTER',STATE_FILTER,...
                'FILE_TYPE',ftype{iF}};
            
            switch ftype{iF}
                case 'rhs'
                    createTask(j, @intanRHS2Block, 0,{IN_ARGS});
                case 'rhd'
                    createTask(j, @intanRHD2Block, 0,{IN_ARGS});
                otherwise
                    error('Invalid file type (%s).',ftype{iF});
            end
            
            fprintf(1,'Submitting...');
            submit(j);
            pause(WAIT_TIME);
            fprintf(1,'complete.\n');
            
        end
    case 'TDT'
        
    otherwise
        error('%s is not a supported acquisition system (case-sensitive).');
end