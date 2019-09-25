function [class,temp]=DoSPC(parsin,features)
%% CRC_DOSPC Do SPC with already-known features
%
%
% By: Max Murphy    v1.1    08/10/2017  Updated a lot of it, some of the
%                                       code had never been doing what it
%                                       said it was doing.
%                   v1.0    08/08/2017  Modified for R2017a
%% Select paths
localpath = fileparts(mfilename('fullpath'));
temppath = nigeLab.defaults.Tempdir;

%% DEFAULTS
pars.TEMPLATE = 'center';
pars.FNAME_IN = 'tmp_data';              % Input name for cluster.exe
pars.FNAME_OUT = 'data_tmp_curr.mat';    % Read-out from cluster.exe
pars.RANDOMSEED = 147;                   % Random seed
pars.ABS_KNN = 15;                       % Absolute (min) K-Nearest Neighbors
pars.REL_KNN = 0.0001;                   % Relative K-Nearest Neighbors
pars.SWCYC = 75;                    % Swendsen-Wang cycles
pars.TSTEP = 0.001;                 % Increments for vector of temperatures
pars.MAXTEMP = 0.300;               % Max. temperature for SPC
pars.MINTEMP = 0.000;               % Min. temperature for SPC
pars.NMINCLUS = 3;                  % Absolute minimum cluster size diff
pars.RMINCLUS = 0.005;              % Relative minimum cluster size diff
pars.MAX_SPK = 1000;                % Max. # of features for SPC
pars.TEMPSD = 2;                    % # of SD for template matching
pars.NCLUS_MAX = 9;

N = size(features,1);               % Number of spikes
K = size(features,2);               % Number of features or dimensions

nm = fieldnames(parsin);
for ii=1:numel(nm)
    pars.(upper(nm{ii})) = parsin.(nm{ii});
end

%% SELECT PARAMETERS
n_feat   = min(pars.MAX_SPK,N);
min_clus = max(pars.NMINCLUS,pars.RMINCLUS*n_feat);
n_knn    = max(pars.ABS_KNN,ceil(pars.REL_KNN*N));

if n_feat < N
   ind = sort(RandSelect(1:N,n_feat));
else
   ind = 1:N;
end

%% CHECK TO MAKE SURE "BAD" FILES ARE NOT STILL PRESENT
fprintf(1,'Beginning SPC...');

cleanup(temppath,pars);

inspk_aux = features(ind,:);
save(fullfile(temppath, pars.FNAME_IN),'inspk_aux','-ascii');

% if exist(fullfile(temppath,[pars.FNAME_IN '.dg_01.lab']), 'file')
%    delete( sprintf('%s.dg_01.lab',fullfile(temppath,pars.FNAME_IN )));
% end
% 
% if exist(fullfile(temppath,[pars.FNAME_IN '.dg_01']), 'file')
%    delete( sprintf('%s.dg_01',    fullfile(temppath,pars.FNAME_IN )));
% end


%% PRINT INPUT FILE FOR SPC
fprintf(1,' writing input...');
fid=fopen(sprintf('%s.run',fullfile(temppath,pars.FNAME_OUT)),'wt');
fprintf(fid,'NumberOfPoints: %s\n',num2str(n_feat));
fprintf(fid,'DataFile: %s\n',pars.FNAME_IN);
fprintf(fid,'OutFile: %s\n', pars.FNAME_OUT);
fprintf(fid,'Dimensions: %s\n',num2str(K));
fprintf(fid,'MinTemp: %s\n',num2str(pars.MINTEMP));
fprintf(fid,'MaxTemp: %s\n',num2str(pars.MAXTEMP));
fprintf(fid,'TempStep: %s\n',num2str(pars.TSTEP));
fprintf(fid,'SWCycles: %s\n',num2str(pars.SWCYC));
fprintf(fid,'KNearestNeighbours: %s\n',num2str(n_knn));
fprintf(fid,'MSTree|\n');
fprintf(fid,'DirectedGrowth|\n');
fprintf(fid,'SaveSuscept|\n');
fprintf(fid,'WriteLables|\n');
fprintf(fid,'WriteCorFile~\n');
if pars.RANDOMSEED ~= 0
   fprintf(fid,'ForceRandomSeed: %s\n',num2str(pars.RANDOMSEED));
end
fclose(fid);

%% EXECUTE CLUSTERING (DEPENDS ON OS)
fprintf(1,' executing cluster.exe...');
[str,~,~] = computer;
switch str
   case {'PCWIN','PCWIN64'}
      if exist(fullfile(temppath,'tmp_cluster.exe'),'file')==0
          copyfile(fullfile(localpath,'cluster.exe'),fullfile(temppath,'tmp_cluster.exe'));
      end
      oldfold = pwd;cd(temppath);
      [~,~] = dos(sprintf('%s "%s.run" ', fullfile('tmp_cluster.exe'), pars.FNAME_OUT));
      cd(oldfold);
      fprintf(1,' cleaning up files...');
      delete(fullfile(temppath,'tmp_cluster.exe'));
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

%% READ OUTPUT FROM COMPILED CLUSTER.EXE
if exist(fullfile(temppath,[pars.FNAME_OUT '.dg_01.lab']),'file')
   clu = load(fullfile(temppath,[pars.FNAME_OUT '.dg_01.lab']));
   tree = load(fullfile(temppath,[pars.FNAME_OUT '.dg_01']));
   delete(fullfile(temppath,[pars.FNAME_OUT '.dg_01.lab']));
else
   clu=nan;
   tree=[];
end

delete(fullfile(temppath, [pars.FNAME_OUT '.dg_01']));
delete(fullfile(temppath, pars.FNAME_IN));

delete(fullfile(temppath,'*.run'));
delete(fullfile(temppath,'*.edges'));
delete(fullfile(temppath,'*.mag'));
delete(fullfile(temppath,'*.param'));
if exist(fullfile(temppath,[pars.FNAME_IN '.dg_01.lab']), 'file')
   eval(sprintf('delete ''%s.dg_01.lab''',fullfile(temppath,pars.FNAME_IN)))
end

if exist(fullfile(temppath,[pars.FNAME_IN '.dg_01']), 'file')
   eval(sprintf('delete ''%s.dg_01''',fullfile(temppath,pars.FNAME_IN)))
end


%% ESTIMATE TEMPERATURE
fprintf(1,' finding temperature...');
aux = tree(:,5:end); % First 4 columns are "other" info
aux = aux(:,aux(1,:) <= min_clus);

temp = 2; % Default temp is the lowest non-zero one.
for t = 1:(size(aux,1)-1)
   % Looks for changes in the cluster size > min_clus.
   if any(aux(t,:)>min_clus)
      temp=t;
      break;
   end
end

%% ASSIGN CLUSTERS
% Initialize cluster classes
class = nan(N,1);

% Only check counts for unique cluster assignment numbers
uvec = unique(clu(temp,3:end));
uvec = reshape(uvec,1,numel(uvec));
assignment = 1;

for ii = uvec
   in = ind(abs(clu(temp,3:end)-ii)<eps);
   if isempty(in)
      class(in) = inf;
   else
      class(in) = assignment;
      assignment = assignment + 1;
   end
end
% % Anything assigned to 0 is "out"
% class(class >= pars.NCLUS_MAX) = pars.NCLUS_MAX;

class(class > pars.NCLUS_MAX) = nan; % Cast as "unassigned" again
remvec = find(isnan(class));
remvec = reshape(remvec,1,numel(remvec));

%% FORCE TEMPLATE MATCHING
if ~isempty(remvec)
   fprintf(1,' building templates...');
   f_in  = features(~isnan(class),:);   % already-classified spikes
   
   centers = zeros(nanmax(class), K); % init. cluster centers
   sd   = zeros(1,nanmax(class));     % init. cluster radii
   
   uvec = unique(class(~isnan(class))); % go through unique instances
   uvec = reshape(uvec,1,numel(uvec));
   
   % Get centroids (medroids, really)
   for ii = uvec
      f = features(abs(class-ii)<eps,:);
      if size(f,1) > 1
         centers(ii,:) = median(f);
         sd(ii)        = sqrt(sum(var(f,1)));
      else
         if ~isempty(features)
            centers(ii,:) = f;
            sd(ii) = sqrt(sum(f.^2));
         end
      end
   end
   
   switch pars.TEMPLATE
      case 'center'
         fprintf(1,' matching templates using L2 center...');
         for ii=remvec
            % L2 distance formula:
            distances = sqrt(sum((ones(size(centers,1),1)...
               *features(ii,:)- centers).^2,2).');
            
            % Identify any within cluster radius
            conforming = find(distances < pars.TEMPSD*sd);
            
            % If belongs, find minimum distance
            if ~isempty(conforming)
               [~,imin] = min(distances(conforming));
               class(ii) = conforming(imin);
               
            else % Otherwise just throw it out
               class(ii) = pars.NCLUS_MAX;
            end
         end
      case 'proportions'
         fprintf(1,' matching templates using proportional clusters...');
         p = zeros(pars.NCLUS_MAX,1);
         for ii = 1:pars.NCLUS_MAX
            p(ii) = sum(abs(class(ind)-ii)<eps)/numel(ind);
         end
         class(remvec) = ...
            proportional_clustering(features(remvec,:),centers,p);
         
      otherwise
         error('%s is an invalid template-matching strategy.',...
            pars.TEMPLATE);
   end
end


% Set anything in pars.NCLUS_MAX to 0 since it is "out"
class(abs(class-pars.NCLUS_MAX)<eps) = 0;
class = class + 1;


fprintf(1,'complete.\n');


end

function cleanup(temppath,pars)
warning off
delete(fullfile(temppath, [pars.FNAME_OUT '.dg_01']));
delete(fullfile(temppath, [pars.FNAME_OUT '.dg_01.lab']));
delete(fullfile(temppath, pars.FNAME_IN));

delete(fullfile(temppath,'*.run'));
delete(fullfile(temppath,'*.edges'));
delete(fullfile(temppath,'*.mag'));
delete(fullfile(temppath,'*.param'));
if exist(fullfile(temppath,[pars.FNAME_IN '.dg_01.lab']), 'file')
   eval(sprintf('delete ''%s.dg_01.lab''',fullfile(temppath,pars.FNAME_IN)))
end

if exist(fullfile(temppath,[pars.FNAME_IN '.dg_01']), 'file')
   eval(sprintf('delete ''%s.dg_01''',fullfile(temppath,pars.FNAME_IN)))
end
warning on
end
function [out,skip] = RandSelect(in, num)
%% Randomly selects specified subset of indices from "in"

N = length(in);

out = in;
if num>N
    warning('Not a random subset.')
    skip = true;
    return;
end

num_remove = N - num;
if num_remove > 10 * num
    temp = in;
    out = [];
    for ii = 1:num
        sel = randi(length(temp));
        out = [out, temp(sel)];
        temp = temp(temp~=temp(sel));
    end
    skip = false;
    return;
end


for ii = 1:num_remove
    remov = randi(length(out));
    vec = 1:length(out);
    vec = vec(vec~=remov);
    out = out(vec);
end
skip = false;
end