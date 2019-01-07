function CRC_DoSPC(src,~,obj)
%% CRC_DOSPC Do SPC with already-known features
%
%   CRC_DOSPC(src,~,obj)
%
%   --------
%    INPUTS
%   --------
%     src       :   UIcontrol, in this case a pushbutton.
%
%     obj       :   ClusterUI object from CRC UI.
%
% By: Max Murphy    v1.1    08/10/2017  Updated a lot of it, some of the
%                                       code had never been doing what it
%                                       said it was doing.
%                   v1.0    08/08/2017  Modified for R2017a

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

% Max. # of clusters
clu_available = unique(obj.Available);
pars.NCLUS_MAX = numel(clu_available)+1;

%% GET FEATURES
cluster = obj.Data.UI.cl;
ch = obj.Data.UI.ch;

% Use interpolated time-series for clustering
features = obj.SpikeImage.Clusters{cluster};

N = size(features,1);               % Number of features
K = size(features,2);               % Number of features

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

inspk_aux = features(ind,:);
save(pars.FNAME_IN,'inspk_aux','-ascii');

if exist(fullfile(pwd,[pars.FNAME_IN '.dg_01.lab']), 'file')
   eval(sprintf('delete ''%s.dg_01.lab''',fullfile(pwd,pars.FNAME_IN)))
end

if exist(fullfile(pwd,[pars.FNAME_IN '.dg_01']), 'file')
   eval(sprintf('delete ''%s.dg_01''',fullfile(pwd,pars.FNAME_IN)))
end

%% PRINT INPUT FILE FOR SPC
fprintf(1,' writing input...');
fid=fopen(sprintf('%s.run',pars.FNAME_OUT),'wt');
fprintf(fid,'NumberOfPoints: %s\n',num2str(n_feat));
fprintf(fid,'DataFile: %s\n',pars.FNAME_IN);
fprintf(fid,'OutFile: %s\n',pars.FNAME_OUT);
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
      if exist([pwd '\cluster.exe'],'file')==0
         directory = which('cluster.exe');
         if isempty(directory)
            error('cluster.exe could not be found.');
         end
         
         copyfile(directory,[pwd filesep 'tmp_cluster.exe'],'f');
      end
      [~,~] = dos(sprintf('tmp_cluster.exe %s.run', pars.FNAME_OUT));
      fprintf(1,' cleaning up files...');
      delete('tmp_cluster.exe');
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
if exist([pars.FNAME_OUT '.dg_01.lab'],'file')
   clu=load([pars.FNAME_OUT '.dg_01.lab']);
   tree=load([pars.FNAME_OUT '.dg_01']);
   delete([pars.FNAME_OUT '.dg_01.lab']);
else
   clu=nan;
   tree=[];
end

delete([pars.FNAME_OUT '.dg_01']);
delete('*.run');
delete('*.edges');
delete('*.mag');
delete('*.param');
delete(pars.FNAME_IN);
if exist(fullfile(pwd,[pars.FNAME_IN '.dg_01.lab']), 'file')
   eval(sprintf('delete ''%s.dg_01.lab''',fullfile(pwd,pars.FNAME_IN)))
end

if exist(fullfile(pwd,[pars.FNAME_IN '.dg_01']), 'file')
   eval(sprintf('delete ''%s.dg_01''',fullfile(pwd,pars.FNAME_IN)))
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

%% UPDATE OBJECT WITH NEW SPIKES
for iN = 1:pars.NCLUS_MAX
   inds = class==iN;
   if iN > 1
      cnum = clu_available(iN-1);
      obj.SpikeImage.Clusters{cnum}=features(inds,:);
      obj.Data.cl.sel.cur{ch,cnum}=obj.Data.cl.sel.cur{ch,cluster}(inds);
      class(inds) = [];
      obj.Data.cl.sel.cur{ch,cluster}(inds) = [];
      obj.Data.cl.num.assign.cur{ch}(cnum) = cnum;
      obj.Data.cl.num.class.cur{ch}(obj.Data.cl.sel.cur{ch,cnum})=cnum;
      
      [obj.SpikeImage.C{cnum},obj.SpikeImage.Assignments{cnum}] = ...
         obj.SpikeImage.CRC_UpdateImage(cnum);
      obj.SpikeImage.CRC_ReDraw(cnum,cnum);
      
   else
      obj.SpikeImage.Clusters{cluster}=features(inds,:);
   end
end

[obj.SpikeImage.C{cluster},obj.SpikeImage.Assignments{cluster}] = ...
         obj.SpikeImage.CRC_UpdateImage(cluster);
obj.SpikeImage.CRC_ReDraw(cluster,cluster);

set(src,'Enable','off');

fprintf(1,'complete.\n');


end