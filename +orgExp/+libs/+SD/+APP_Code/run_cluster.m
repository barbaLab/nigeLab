function [clu, tree] = run_cluster(handles,ch)
%% RUN_CLUSTER Run the compiled executable cluster.exe to do SPC
%
%   [clu,tree] = RUN_CLUSTER(handles,nclust)
%
%   --------
%    INPUTS
%   --------
%    handles        :       Parameter handles structure.
%
%      ch           :       Channel index (string).
%
% Modified by Max Murphy v1.1   01/30/2017  Added ch to allow parfor to
%                                           utilize all workers on local
%                                           machine. Suppressed dos output
%                                           that used to display in the
%                                           command window from the .run
%                                           and .lab files.

%%
dim=handles.par.inputs;
fname=handles.par.fname;
fname_in=handles.par.fname_in;

% DELETE PREVIOUS FILES
if exist(fullfile(pwd,[fname '.dg_01.lab']), 'file')
    eval(sprintf('delete ''%s.dg_01.lab''',fullfile(pwd,fname)))
end

if exist(fullfile(pwd,[fname '.dg_01']), 'file')
    eval(sprintf('delete ''%s.dg_01''',fullfile(pwd,fname)))
end

dat=load(fname_in);
n=length(dat);
fid=fopen(sprintf('%s.run',fname),'wt');
fprintf(fid,'NumberOfPoints: %s\n',num2str(n));
fprintf(fid,'DataFile: %s\n',fname_in);
fprintf(fid,'OutFile: %s\n',fname);
fprintf(fid,'Dimensions: %s\n',num2str(dim));
fprintf(fid,'MinTemp: %s\n',num2str(handles.par.mintemp));
fprintf(fid,'MaxTemp: %s\n',num2str(handles.par.maxtemp));
fprintf(fid,'TempStep: %s\n',num2str(handles.par.tempstep));
fprintf(fid,'SWCycles: %s\n',num2str(handles.par.SWCycles));
fprintf(fid,'KNearestNeighbours: %s\n',num2str(handles.par.KNearNeighb));
fprintf(fid,'MSTree|\n');
fprintf(fid,'DirectedGrowth|\n');
fprintf(fid,'SaveSuscept|\n');
fprintf(fid,'WriteLables|\n');
fprintf(fid,'WriteCorFile~\n');
if handles.par.randomseed ~= 0
    fprintf(fid,'ForceRandomSeed: %s\n',num2str(handles.par.randomseed));
end    
fclose(fid);

[str,~,~] = computer;
handles.par.system=str;
switch handles.par.system
    case {'PCWIN','PCWIN64'}
            if exist([pwd '\cluster.exe'],'file')==0
                directory = which('cluster.exe');
                copyfile(directory,[pwd filesep 'cluster_' ch '.exe']);                 
            end
            [~,~] = dos(sprintf('cluster_%s.exe %s.run', ch, fname));
    case 'MAC'
        if exist([pwd '/cluster_mac.exe'],'file')==0
            directory = which('cluster_mac.exe');
            copyfile(directory,pwd);
        end
        run_mac = sprintf('./cluster_mac.exe %s.run',fname);
	    unix(run_mac);
    otherwise  %(GLNX86, GLNXA64, GLNXI64 correspond to linux)
        if exist([pwd '/cluster_linux.exe'],'file')==0
            directory = which('cluster_linux.exe');
            copyfile(directory,pwd);
        end
        run_linux = sprintf('./cluster_linux.exe %s.run',fname);
	    unix(run_linux);
end

if exist([fname '.dg_01.lab'],'file')
    clu=load([fname '.dg_01.lab']);
    tree=load([fname '.dg_01']);
else
    clu=nan;
    tree=[];
end
delete([fname '.dg_01.lab']);
delete([fname '.dg_01']);
delete(sprintf('*%s*.run',ch));
delete(sprintf('*%s*.edges',ch));
delete(sprintf('*%s*.mag',ch));
delete(sprintf('*%s*.param',ch));
delete(fname_in); 

end
