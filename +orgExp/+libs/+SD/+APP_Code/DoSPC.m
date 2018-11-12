function [class,clu,tree,temp] = DoSPC(features,pars,varargin)
%% DOSPC Do SPC with already-known features
%
%   class = DOSPC(features,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   features    :   Matrix where each column is a vector of features
%                   corresponding to a single variable for each spike.
%                   (i.e. each column is the PCA coeffs, or wavelet coeffs,
%                    or some other extracted spike feature).
%
%     pars      :   (Optional) parameters struct for SPC (see DEFAULTS).
%
%   varargin    :   (Optional) 'NAME',value input argument pairs.
%
%   --------
%    OUTPUT
%   --------
%    class      :   Cluster assignments for each feature.
%
%    clu        :   Cluster assignments from SPC.
%
%    tree       :   Number of assignments per cluster.
%
%    temp       :   Selected "temperature" to use for SPC cluster assigns.
%
% By: Max Murphy    v1.1    08/10/2017  Updated a lot of it, some of the
%                                       code had never been doing what it
%                                       said it was doing.
%                   v1.0    08/08/2017  Modified for R2017a

%% DEFAULTS
if exist('pars','var')==0
   pars = init_pars;
end
                            
%% DATA SIZE
MAIN = true;                        % Used for recursion
N = size(features,1);               % Number of features
K = size(features,2);               % Number of features

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% SELECT PARAMETERS
n_feat   = min(pars.SPC_MAX_SPK,N);
min_clus = max(pars.SPC_NMINCLUS,pars.SPC_RMINCLUS*n_feat);
n_knn    = max(pars.SPC_ABS_KNN,ceil(pars.SPC_REL_KNN*N));

batch_limit = pars.SPC_TEMPLATE_PROP*N;


if n_feat < N
   batch_flag = n_feat < batch_limit;
   rng(pars.SPC_RANDOMSEED);
   if pars.SPC_RANDOMIZE
      ind = sort(RandSelect(1:N,n_feat));
   else
      ind = 1:n_feat;
   end
else
   batch_flag = false;
   ind = 1:N;
end

%% CHECK TO MAKE SURE "BAD" FILES ARE NOT STILL PRESENT
if MAIN && pars.SPC_VERBOSE
   fprintf(1,'Beginning SPC...');
end

inspk_aux = features(ind,:);
save(pars.SPC_FNAME_IN,'inspk_aux','-ascii');

if exist(fullfile(pwd,[pars.SPC_FNAME_IN '.dg_01.lab']), 'file')
    eval(sprintf('delete ''%s.dg_01.lab''',fullfile(pwd,pars.SPC_FNAME_IN)))
end

if exist(fullfile(pwd,[pars.SPC_FNAME_IN '.dg_01']), 'file')
    eval(sprintf('delete ''%s.dg_01''',fullfile(pwd,pars.SPC_FNAME_IN)))
end

%% PRINT INPUT FILE FOR SPC
if MAIN && pars.SPC_VERBOSE
   fprintf(1,' writing input...');
end
fid=fopen(sprintf('%s.run',pars.SPC_FNAME_OUT),'wt');
fprintf(fid,'NumberOfPoints: %s\n',num2str(n_feat));
fprintf(fid,'DataFile: %s\n',pars.SPC_FNAME_IN);
fprintf(fid,'OutFile: %s\n',pars.SPC_FNAME_OUT);
fprintf(fid,'Dimensions: %s\n',num2str(K));
fprintf(fid,'MinTemp: %s\n',num2str(pars.SPC_MINTEMP));
fprintf(fid,'MaxTemp: %s\n',num2str(pars.SPC_MAXTEMP));
fprintf(fid,'TempStep: %s\n',num2str(pars.SPC_TSTEP));
fprintf(fid,'SWCycles: %s\n',num2str(pars.SPC_SWCYC));
fprintf(fid,'KNearestNeighbours: %s\n',num2str(n_knn));
fprintf(fid,'MSTree|\n');
fprintf(fid,'DirectedGrowth|\n');
fprintf(fid,'SaveSuscept|\n');
fprintf(fid,'WriteLables|\n');
fprintf(fid,'WriteCorFile~\n');
if pars.SPC_RANDOMSEED ~= 0
    fprintf(fid,'ForceRandomSeed: %s\n',num2str(pars.SPC_RANDOMSEED));
end    
fclose(fid);

%% EXECUTE CLUSTERING (DEPENDS ON OS)
if MAIN && pars.SPC_VERBOSE
   fprintf(1,' executing cluster.exe...');
end
[str,~,~] = computer;
switch str
    case {'PCWIN','PCWIN64'}
          if exist([pwd '\cluster.exe'],'file')==0
             directory = which('cluster.exe');
             if isempty(directory)
                error('cluster.exe could not be found.');
             end
                
             copyfile(directory,[pwd filesep 'tmp_cluster.exe']);                 
          end
          [~,~] = dos(sprintf('tmp_cluster.exe %s.run', pars.SPC_FNAME_OUT));
          if MAIN && pars.SPC_VERBOSE
            fprintf(1,' cleaning up files...');
          end
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
if exist([pars.SPC_FNAME_OUT '.dg_01.lab'],'file')
    clu=load([pars.SPC_FNAME_OUT '.dg_01.lab']);
    tree=load([pars.SPC_FNAME_OUT '.dg_01']);
    delete([pars.SPC_FNAME_OUT '.dg_01.lab']);
else
    clu=nan;
    tree=[];
end

delete([pars.SPC_FNAME_OUT '.dg_01']);
delete('*.run');
delete('*.edges');
delete('*.mag');
delete('*.param');
delete(pars.SPC_FNAME_IN);
if exist(fullfile(pwd,[pars.SPC_FNAME_IN '.dg_01.lab']), 'file')
    eval(sprintf('delete ''%s.dg_01.lab''',fullfile(pwd,pars.SPC_FNAME_IN)))
end

if exist(fullfile(pwd,[pars.SPC_FNAME_IN '.dg_01']), 'file')
    eval(sprintf('delete ''%s.dg_01''',fullfile(pwd,pars.SPC_FNAME_IN)))
end


%% ESTIMATE TEMPERATURE
if MAIN && pars.SPC_VERBOSE
   fprintf(1,' finding temperature...');
end
aux = tree(:,5:end); % First 4 columns are "other" info
if isempty(aux)
   class = zeros(N,1);
   clu = nan;
   tree = nan; 
   temp = nan;
   return;
end
aux = aux(:,aux(1,:) <= min_clus);

switch pars.SPC_TEMP_METHOD
   case 'iterate'
      temp = 2; % Default temp is the lowest non-zero one.
      for t = 1:(size(aux,1)-1)
          % Looks for changes in the cluster size > min_clus.
          if any(aux(t,:)>min_clus)
              temp=t;
              break;
          end
      end
   case 'max'
      [~,temp] = max(aux(:,2));
   case 'cost'
      cost = -log(1000*aux(:,1)) + ...
              log(aux(:,2)) + ...
              log(2*aux(:,3)) + ...
              sum(sqrt(aux(:,4:7)),2);
      [~,temp] = max(cost);
   case 'nclus'
      temp = find(tree(:,4) <= pars.SPC_NCLUS_MAX,1,'last');
   case 'neo'
      iTree = 6;
      Y = tree(:,iTree) - mean(tree(:,iTree));
      y = Y(2:(end-1));
      yb = Y(1:(end-2));
      yf = Y(3:end);
      yneo = [0; y.^2 - yb.*yf; 0];
      [~,temp] = max(yneo);
      while ((iTree<=10) && (tree(temp,4)<pars.SPC_NCLUS_MIN))
         iTree = iTree + 1;
         Y = tree(:,iTree) - mean(tree(:,iTree));
         y = Y(2:(end-1));
         yb = Y(1:(end-2));
         yf = Y(3:end);
         yneo = [0; y.^2 - yb.*yf; 0];
         [~,temp] = max(yneo);
      end
      if (iTree > 10)
         iTree = 6;
         Y = tree(:,iTree) - mean(tree(:,iTree));
         y = Y(2:(end-1));
         yb = Y(1:(end-2));
         yf = Y(3:end);
         yneo = [0; y.^2 - yb.*yf; 0];
         yneo(tree(:,4)<pars.SPC_NCLUS_MIN) = -inf;
         [~,temp] = max(yneo);
      end
   otherwise
      error('%s is an invalid temperature estimation method.',pars.SPC_TEMP_METHOD);
end

%% ASSIGN CLUSTERS
% Initialize cluster classes
if MAIN
   class = nan(N,1);
else
   class = nan(size(features,1),1);
end

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

class(class > pars.SPC_NCLUS_MAX) = nan; % Cast as "unassigned" again

if MAIN && ~pars.SPC_RANDOMIZE
   if pars.SPC_VERBOSE
      h = waitbar(min(max(ind)/batch_limit,1),'Please wait, executing recursion...');
   end
   while batch_flag
      % Do SPC on next batch of spikes
      ind = (max(ind)+1):min((max(ind)+n_feat),numel(class));
      class(ind) = DoSPC(features(ind,:),pars,'N',N,'MAIN',false);      
      batch_flag = (max(ind) < batch_limit);
      if pars.SPC_VERBOSE
         waitbar(min(max(ind)/batch_limit,1));
      end
   end
   if pars.SPC_VERBOSE
      delete(h);
   end
   
   % Consolidate clusters
   if pars.SPC_VERBOSE
      fprintf(1,' consolidating clusters...');
   end
   red_pars = init_reduction_params(pars);
   class(1:max(ind)) = ReduceClusters(features(1:max(ind),:),...
                                      class(1:max(ind)),...
                                      red_pars,...
                                      'CLUSTER_METHOD','spc');
else % Stop short of template match if a recursion
   class(isnan(class)) = 0;
   return;
end

class(abs(class)<=eps) = nan; % Turn "out" clusters into NaN
remvec = find(isnan(class));
remvec = reshape(remvec,1,numel(remvec));

%% FORCE TEMPLATE MATCHING
if ((~isempty(remvec)) && (~pars.SPC_DISCARD_EXTRA_CLUS))
   if pars.SPC_VERBOSE
      fprintf(1,' building templates...');
   end
   
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
   
   switch pars.SPC_TEMPLATE
      case 'center'
         if pars.SPC_VERBOSE
            fprintf(1,' matching templates using L2 center...');
         end
         for ii=remvec
            % L2 distance formula:
            distances = sqrt(sum((ones(size(centers,1),1)...
               *features(ii,:)- centers).^2,2).');
            
            % Identify any points within cluster radius
            conforming = find(distances < pars.SPC_TEMPSD*sd);
            
            % If belongs, find minimum distance
            if ~isempty(conforming)
               [~,imin] = min(distances(conforming));
               class(ii) = conforming(imin);
               
            else % Otherwise just throw it out
               class(ii) = 0;
            end
         end
      case 'proportions'
         if pars.SPC_VERBOSE
            fprintf(1,' matching templates using proportional clusters...');
         end
         p = zeros(pars.SPC_NCLUS_MAX,1);
         for ii = 1:pars.SPC_NCLUS_MAX
            p(ii) = sum(abs(class(ind)-ii)<eps)/numel(ind);
         end
         class(remvec) = ...
            proportional_clustering(features(remvec,:),centers,p);
         
      otherwise
         error('%s is an invalid template-matching strategy.',...
            pars.SPC_TEMPLATE);
   end
end


% Set anything in pars.SPC_NCLUS_MAX to 0 since it is "out"
class(abs(class-pars.SPC_NCLUS_MAX)<eps) = 0;

% If template matching is not performed, set NaN clusters to "out"
class(isnan(class)) = 0;

if pars.SPC_VERBOSE
   fprintf(1,'complete.\n');
   beep;
end

   function red_pars = init_reduction_params(cur_pars)
      red_pars = struct;
      red_pars.SPC_VERBOSE = true;
      red_pars.SPC_TEMPLATE = 'center';
      red_pars.SPC_DISCARD_EXTRA_CLUS = false;         % If true, don't do template match
      red_pars.SPC_FNAME_IN = cur_pars.SPC_FNAME_IN;   % Input name for cluster.exe
      red_pars.SPC_FNAME_OUT = cur_pars.SPC_FNAME_OUT; % Read-out from cluster.exe
      red_pars.SPC_RANDOMSEED = 147;                   % Random seed
      red_pars.SPC_RANDOMIZE = true;                   % Use random subset for SPC?
      red_pars.SPC_ABS_KNN = 3;                        % Absolute (min) K-Nearest Neighbors
      red_pars.SPC_REL_KNN = 0.0001;                   % Relative K-Nearest Neighbors
      red_pars.SPC_SWCYC = 200;                   % Swendsen-Wang cycles
      red_pars.SPC_TSTEP = 0.001;                 % Increments for vector of temperatures
      red_pars.SPC_MAXTEMP = 0.300;               % Max. temperature for SPC
      red_pars.SPC_TEMPLATE_PROP = 0.25;          % Proportion for SPC before starting template match
      red_pars.SPC_MINTEMP = 0.000;               % Min. temperature for SPC
      red_pars.SPC_NMINCLUS = 7;                  % Absolute minimum cluster size diff
      red_pars.SPC_RMINCLUS = 0.006;              % Relative minimum cluster size diff
      red_pars.SPC_MAX_SPK = 1000;                % Max. # of spikes per SPC batch
      red_pars.SPC_TEMPSD = 2.00;                 % # of SD for template matching
      red_pars.SPC_NCLUS_MIN = 3;                % For use with 'neo' option
      red_pars.SPC_NCLUS_MAX = 300;              % Max. # of clusters
      red_pars.SPC_TEMP_METHOD = 'neo';           % Method of finding temperature
   end

   function pars = init_pars
      pars = struct;
      pars.SPC_VERBOSE = true;
      pars.SPC_TEMPLATE = 'center';
      pars.SPC_DISCARD_EXTRA_CLUS = false;         % If true, don't do template match
      pars.SPC_FNAME_IN = 'tmp_data';              % Input name for cluster.exe
      pars.SPC_FNAME_OUT = 'data_tmp_curr.mat';    % Read-out from cluster.exe
      pars.SPC_RANDOMSEED = 147;                   % Random seed
      pars.SPC_RANDOMIZE = false;                  % Use random subset for SPC?
      pars.SPC_ABS_KNN = 10;                       % Absolute (min) K-Nearest Neighbors
      pars.SPC_REL_KNN = 0.0001;                   % Relative K-Nearest Neighbors
      pars.SPC_SWCYC = 100;                   % Swendsen-Wang cycles
      pars.SPC_TSTEP = 0.001;                 % Increments for vector of temperatures
      pars.SPC_MAXTEMP = 0.300;               % Max. temperature for SPC
      pars.SPC_MINTEMP = 0.000;               % Min. temperature for SPC
      pars.SPC_NMINCLUS = 7;                  % Absolute minimum cluster size diff
      pars.SPC_RMINCLUS = 0.006;              % Relative minimum cluster size diff
      pars.SPC_MAX_SPK = 1000;                % Max. # of spikes per SPC batch
      pars.SPC_TEMPLATE_PROP = 0.25;          % Proportion for SPC before starting template match
      pars.SPC_TEMPSD = 1.50;                 % # of SD for template matching
      pars.SPC_NCLUS_MIN = 25;                % For use with 'neo' option
      pars.SPC_NCLUS_MAX = 1000;              % Max. # of clusters
      pars.SPC_TEMP_METHOD = 'neo';           % Method of finding temperature
                                  % ('iterate', 'max', 'cost', 'nclus', or 'neo')
   end

end