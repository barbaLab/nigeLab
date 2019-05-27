function [clu, tree] = run_cluster(par, multi_files)
dim = par.inputs;
currdir = fullfile(fileparts(mfilename('fullpath')));
fname = fullfile(currdir,par.fnamespc);
fname_in = fullfile(currdir,par.fname_in);

% DELETE PREVIOUS FILES
if exist([fname '.dg_01.lab'],'file')
    delete([fname '.dg_01.lab']);
    delete([fname '.dg_01']);
end

dat = load(fname_in);
n = length(dat);
fid = fopen(sprintf('%s.run',fname),'wt');
fprintf(fid,'NumberOfPoints: %s\n',num2str(n));
fprintf(fid,'DataFile: %s\n',par.fname_in);
fprintf(fid,'OutFile: %s\n',par.fnamespc);
fprintf(fid,'Dimensions: %s\n',num2str(dim));
fprintf(fid,'MinTemp: %s\n',num2str(par.mintemp));
fprintf(fid,'MaxTemp: %s\n',num2str(par.maxtemp));
fprintf(fid,'TempStep: %s\n',num2str(par.tempstep));
fprintf(fid,'SWCycles: %s\n',num2str(par.SWCycles));
fprintf(fid,'KNearestNeighbours: %s\n',num2str(par.KNearNeighb));
fprintf(fid,'MSTree|\n');
fprintf(fid,'DirectedGrowth|\n');
fprintf(fid,'SaveSuscept|\n');
fprintf(fid,'WriteLables|\n');
fprintf(fid,'WriteCorFile~\n');
if par.randomseed ~= 0
    fprintf(fid,'ForceRandomSeed: %s\n',num2str(par.randomseed));
end    
fclose(fid);

system_type = computer;
switch system_type
    case {'PCWIN'}    
%         if exist([pwd '\cluster.exe'])==0
%             directory = which('cluster.exe');
%             copyfile(directory,pwd);
%         end
        exec = (fullfile(currdir,'cluster.exe'));
        [status,result] = dos(sprintf('cd %s & "%s" %s.run',currdir,exec,par.fnamespc));
        %[status,result] = dos(sprintf('cluster.exe %s.run',fname));
    case {'PCWIN64'}    
%         if exist([pwd '\cluster_64.exe'])==0
%             directory = which('cluster_64.exe');
%             copyfile(directory,pwd);
%         end
        exec = (fullfile(currdir,'cluster_64.exe'));
        [status,result] = dos(sprintf('cd %s & "%s" %s.run',currdir,exec,par.fnamespc));
        %[status,result] = dos(sprintf('cluster_64.exe %s.run',fname));
    case {'MAC'}

        exec = (fullfile(currdir,'cluster_mac.exe'));
        fileattrib(exec,'+x')
        run_mac = sprintf('cd %s & .%s %s.run',currdir,exec,fname);
	    [status,result] = unix(run_mac);
   case {'MACI','MACI64'}
      
        exec = (fullfile(currdir,'cluster_mac.exe'));
        fileattrib(exec,'+x')
        run_maci = sprintf('cd %s & .%s %s.run',currdir,exec,fname);
	    [status,result] = unix(run_maci);
    case {'GLNX86'}      
       
        exec = (fullfile(currdir,'cluster_linux.exe'));
        run_linux = sprintf(' cd %s & ''%s'' %s.run',currdir,exec,fname);
        fileattrib(exec,'+x')        
	    [status,result] = unix(run_linux);
        
    case {'GLNXA64', 'GLNXI64'}
        exec = (fullfile(currdir,'cluster_linux64.exe'));
        run_linux = sprintf(' cd %s & ''%s'' %s.run',currdir,exec,fname);
        fileattrib(exec,'+x')
        
        [status,result] = unix(run_linux);
    otherwise 
    	ME = MException('MyComponent:NotSupportedArq', '%s type of computer not supported.',com_type);
    	throw(ME)
end

if status ~= 0
    disp(result)
end



if exist('multi_files','var') && multi_files==true
	log_name = [par.filename 'spc_log.txt'];
	f = fopen(log_name,'w');
	fprintf(f,['----------\nSPC result of file: ' par.filename '\n']);
	fprintf(f,result);
	fclose(f);
else
	log_name = fullfile(currdir,'spc_log.txt');
	f = fopen(log_name,'w');
	fprintf(f,result);
	fclose(f);
end

clu = load([fname '.dg_01.lab']);
tree = load([fname '.dg_01']); 

try
delete(sprintf('%s.run',fname));    
delete([fname '*.mag']);
delete([fname '*.edges']);
delete([fname '*.param']);
end

if exist([fname '.knn'],'file')
    delete([fname '.knn']);
end

delete(fname_in); 
