function [out,criterio] = SORT_skwedt(SpikeMat,sdd,REM,INPCA)
% this function sorts detected spikes using mixtures of multivariate skew-t
% distributions. SpikeMat is matrix of detected spikes, sdd is settings,
% REM contains spikes after statistical filtering. INPCA is a logical value
% which determines whether considering noise spikes in computing PCA or not.

% default values for REM and INPCA
if nargin < 3
    REM = [];
    INPCA = true;
end

if nargin < 4
    INPCA = true;
end

% removing REM if it is given in wrong format
if ~islogical(REM) || length(REM) ~= size(SpikeMat,1)
    REM = [];
end

seed = sdd.random_seed;

g_max = sdd.g_max;
g_min = sdd.g_min;

% removing outliers using given REM
if ~INPCA && ~isempty(REM)
    SpikeMat(REM,:) = [];
end

% returns principal component scores in SpikeMat and the principal
% component variances in latent
[~,SpikeMat,latent] = pca(SpikeMat);

% choosing number of pca coefficients shuch that 0.95 of variance is covered
h = find(cumsum(latent)/sum(latent) > 0.95);
h = h(1);

% limiting number of pca coefficients (h) by n_pca_max
if h > sdd.n_pca_max
    h = sdd.n_pca_max;
end

% considering first "h" pca scores
SpikeMat = SpikeMat(:,1:h);

if ~isempty(REM) && INPCA
    SpikeMat(REM,:) = [];
end

% initial value for nu parameter
nu = sdd.nu;
L_max = -inf;

g = g_max; % j

nrow = @(x) size(x,1);
ncol = @(x) size(x,2);


n_feat = ncol(SpikeMat);
n_spike = nrow(SpikeMat);


% initialization

% simple clustering method
rng(seed)

% running FCM on SpikeMat. initial value for mu is considered cluster
% centers returned from fcm function. this step is done only for first g (g_max)
[mu,U] = fcm(SpikeMat,g,[2,20,1,0]);

% Estimate starting point for Sigma and Pi from simple clustering method
% performed before
rep=reshape(repmat(1:g,n_spike,1),g*n_spike,1);
rep_data=repmat(SpikeMat,g,1);
diffs=rep_data-mu(rep,:); % X - mu
clear rep_data;
[~,idx] = max(U);
U=U';

mu = mat2cell(mu,ones(size(mu,1),1))';
shape = cell(1, g); Sigma = cell(1, g);
for j=1:g
    shape{j} = sign(sum((SpikeMat(idx == j, :) - repmat(mu{j}, [nrow(SpikeMat(idx == j, :)), 1])).^3, 1));
    Sigma{j}=(((U(:,j)*ones(1,n_feat)).*diffs(rep==j,:))'*diffs(rep==j,:))/sum(U(:,j));
end


pii=sum(U) /sum(sum(U));


delta = cell(1, g);
Delta = cell(1, g);
Gama = cell(1, g);

% running clustering algorithm for g in [g_max, ...,g_min]
while(g >= g_min)
    for k = 1 : g
        delta{k} = shape{k} ./ sqrt(1 + shape{k} * transpose(shape{k}));
        Delta{k} = transpose(matrix_sqrt(Sigma{k}) * transpose(delta{k}));
        Gama{k} = Sigma{k} - transpose(Delta{k}) * Delta{k};
    end

    if sdd.uni_Gama
        Gama_uni = plus(Gama{:}) / g;
        Gama(:) = {Gama_uni};
    end
    Delta_old = Delta;
    criterio = 1;
    count = 0;
    lkante = 1;

    % starting EM algorithm to find optimum set of parameters. EM algorithm
    % ends when maximum change among all parameters is smaller than a
    % error, or when reaching "max_iter".
    while ((criterio > sdd.error) && (count <= sdd.max_iter))
        count = count + 1;
        tal = zeros(n_spike, g);
        S1 = zeros(n_spike, g);
        S2 = zeros(n_spike, g);
        S3 = zeros(n_spike, g);
        for j = 1 : g
            % Expectation
            Dif = SpikeMat - repmat(mu{j}, [n_spike, 1]);
            Mtij2 = 1./(1 + Delta{j} * (Gama{j} \ transpose(Delta{j})));
            Mtij = sqrt(Mtij2);
            mtuij = sum(repmat(Mtij2 .* (Delta{j} / Gama{j}), [n_spike, 1]) .* Dif, 2);
            A = mtuij ./ Mtij;

            dj = (pdist2(SpikeMat,mu{j},'mahalanobis',Sigma{j})).^2;

            E = (2 .* (nu).^(nu./2) .* gamma((n_feat + nu + 1)./2) .* ((dj + nu + A.^2)).^(-(n_feat + nu + 1)./2))./(gamma(nu./2) .* (sqrt(pi)).^(n_feat + 1) .* sqrt(det(Sigma{j})) .* dmvt_ls(SpikeMat, mu{j}, Sigma{j}, shape{j}, nu));
            u = ((4 .* (nu).^(nu./2) .* gamma((n_feat + nu + 2)./2) .* (dj + nu).^(-(n_feat + nu + 2)./2))./(gamma(nu./2) .* sqrt(pi.^n_feat) .* sqrt(det(Sigma{j})) .* dmvt_ls(SpikeMat, mu{j}, Sigma{j}, shape{j}, nu))) .* tcdf(sqrt((n_feat + nu + 2) ./ (dj + nu)) .* A, n_feat + nu + 2);

            d1 = dmvt_ls(SpikeMat, mu{j}, Sigma{j}, shape{j}, nu);
            if sum(d1 == 0)
                d1(d1 == 0) = 1/intmax;
            end
            d2 = d_mixedmvST(SpikeMat, pii, mu, Sigma, shape, nu);
            if sum(d2 == 0)
                d2(d2 == 0) = 1/intmax;
            end

            tal(:, j) = d1 .* pii(j)./d2;
            S1(:, j) = tal(:, j) .* u;
            S2(:, j) = tal(:, j) .* (mtuij .* u + Mtij .* E);
            S3(:, j) = tal(:, j) .* (mtuij.^2 .* u + Mtij2 + Mtij .* mtuij .* E);

            % maximization
            pii(j) = (1./n_spike) .* sum(tal(:, j));

            mu{j} = sum(S1(:, j) .* SpikeMat - S2(:, j) .* repmat(Delta_old{j}, [n_spike, 1]), 1)./sum(S1(:, j));
            Dif = SpikeMat - mu{j};
            Delta{j} = sum(S2(:, j) .* Dif, 1)./sum(S3(:, j));

            sum2 = zeros(n_feat);
            for i = 1 : n_spike
                sum2 = sum2 + (S1(i, j) .* (transpose(SpikeMat(i, :) - mu{j})) * (SpikeMat(i, :) - mu{j}) - ...
                    S2(i, j) .* (transpose(Delta{j}) * (SpikeMat(i, :) - mu{j})) - ...
                    S2(i, j) .* (transpose(SpikeMat(i, :) - mu{j}) * (Delta{j})) + ...
                    S3(i, j) .* (transpose(Delta{j}) * (Delta{j})));
            end

            Gama{j} = sum2 ./ sum(tal(:, j));

            if ~sdd.uni_Gama
                Sigma{j} = Gama{j} + transpose(Delta{j}) * Delta{j};
                shape{j} = (Delta{j} / matrix_sqrt(Sigma{j})) / (1 - Delta{j} / Sigma{j} * transpose(Delta{j})).^(1/2);
            end
        end

        logvero_ST = @(nu) -1*sum(log(d_mixedmvST(SpikeMat, pii, mu, Sigma, shape, nu)));
        options = optimset('TolX', 0.000001);
        nu = fminbnd(logvero_ST, 0, 100, options);
        pii(g) = 1 - (sum(pii) - pii(g));

        zero_pos = pii == 0;
        pii(zero_pos) = 1e-10;
        pii(pii == max(pii)) = max(pii) - sum(pii(zero_pos));

        lk = sum(log(d_mixedmvST(SpikeMat, pii, mu, Sigma, shape, nu)));
        criterio = abs((lk./lkante) - 1);

        lkante = lk;
        % mu_old = mu;
        Delta_old = Delta;
        % Gama_old = Gama;


    end
    % computing log likelihood function as a criterion to find the best g.
    [~, cl] = max(tal, [], 2);
    L = 0;
    for j = 1 : g
        L = L + sum(log(pii(j) .* dmvt_ls(SpikeMat(cl == j,:), mu{j}, Sigma{j}, shape{j}, nu)));
    end

    % for first g (g_max) L_max has been -inf, for next iterations
    % (g_max-1, ..., g_min) L is compared to largest L between all previous
    % iters.
    if L > L_max
        L_max = L;
        % assigning cluster indices to each spike. if REM is given the
        % outliers must be assigned to cluster 255.
        if isempty(REM)
            [~,out] = max(tal,[],2);
        else
            [~,c_i] = max(tal,[],2);
            cluster_index = zeros(length(REM),1);
            cluster_index(~REM) = c_i;
            cluster_index(REM) = 255; % removed
            out = cluster_index;
        end
    else
        break
    end

    % set smalletst component to zero
    m_pii = min(pii);
    indx_remove = (pii == m_pii) | (pii < 0.01);
    % Purge components
    mu(indx_remove) = [];
    Sigma(indx_remove) = [];
    pii(indx_remove) = [];
    shape(indx_remove) = [];
    g = g-sum(indx_remove);

end
end

function dens = d_mixedmvST (y, pi1, mu, Sigma, lambda, nu)

% y: the data matrix
% pi1: must be of the vector type of dimension g
% mu: must be of type list with g entries. Each entry in the list must be a vector of dimension p
% Sigma: must be of type list with g entries. Each entry in the list must be an matrix p x p
% lambda: must be of type list with g entries. Each entry in the list must be a vector of dimension p
% nu: a number

g = numel(pi1);
dens = 0;
for j = 1 : g
    dens = dens + pi1(j) .* dmvt_ls(y, mu{j}, Sigma{j}, lambda{j}, nu);
end
end

function dens = dmvt_ls (y, mu, Sigma, lambda, nu)
% This function computes Density/CDF of Skew-T with scale location.
% y must be a matrix where each row has
%    a multivariate vector of dimension
%    ncol(y) = p , nrow(y) = sample size.
% mu, lambda: must be of the vector type of
%             the same dimension equal to ncol(y) = p
% lambda: 1 x p
% Sigma: Matrix p x p
nrow = @(x) size(x,1);
ncol = @(x) size(x,2);
n = nrow(y);
p = ncol(y);
mahalanobis_d = (pdist2(y,mu,'mahalanobis',Sigma)).^2;
denst = (gamma((p + nu)./2)./(gamma(nu./2) .* pi.^(p./2))) .* ...
    nu.^(-p./2) .* det(Sigma).^(-1/2) .* ...
    (1 + mahalanobis_d./nu).^(-(p + nu)./2);
dens = 2 .* (denst) .* tcdf(sqrt((p + nu)./(mahalanobis_d + nu)) .* sum(repmat(lambda / matrix_sqrt(Sigma), n, 1) .* (y - mu), 2), nu + p);
end

function Asqrt = matrix_sqrt (A)
% This function returns square root of input matrix (A).

[u, s, v] = svd(A);
d = diag(s);
if (min(d) >= 0)
    Asqrt = transpose(v * (transpose(u) .* sqrt(d)));
else
    error('Matrix square root is not defined.\n')
end
end

function [center, U, obj_fcn] = fcm(data, cluster_n, options)
%FCM Data set clustering using fuzzy c-means clustering.
%
%   [CENTER, U, OBJ_FCN] = FCM(DATA, N_CLUSTER) finds N_CLUSTER number of
%   clusters in the data set DATA. DATA is size M-by-N, where M is the number of
%   data points and N is the number of coordinates for each data point. The
%   coordinates for each cluster center are returned in the rows of the matrix
%   CENTER. The membership function matrix U contains the grade of membership of
%   each DATA point in each cluster. The values 0 and 1 indicate no membership
%   and full membership respectively. Grades between 0 and 1 indicate that the
%   data point has partial membership in a cluster. At each iteration, an
%   objective function is minimized to find the best location for the clusters
%   and its values are returned in OBJ_FCN.
%
%   [CENTER, ...] = FCM(DATA,N_CLUSTER,OPTIONS) specifies a vector of options
%   for the clustering process:
%       OPTIONS(1): exponent for the matrix U             (default: 2.0)
%       OPTIONS(2): maximum number of iterations          (default: 100)
%       OPTIONS(3): minimum amount of improvement         (default: 1e-5)
%       OPTIONS(4): info display during iteration         (default: 1)
%   The clustering process stops when the maximum number of iterations
%   is reached, or when the objective function improvement between two
%   consecutive iterations is less than the minimum amount of improvement
%   specified. Use NaN to select the default value.
%
%   Example
%       data = rand(100,2);
%       [center,U,obj_fcn] = fcm(data,2);
%       plot(data(:,1), data(:,2),'o');
%       hold on;
%       maxU = max(U);
%       % Find the data points with highest grade of membership in cluster 1
%       index1 = find(U(1,:) == maxU);
%       % Find the data points with highest grade of membership in cluster 2
%       index2 = find(U(2,:) == maxU);
%       line(data(index1,1),data(index1,2),'marker','*','color','g');
%       line(data(index2,1),data(index2,2),'marker','*','color','r');
%       % Plot the cluster centers
%       plot([center([1 2],1)],[center([1 2],2)],'*','color','k')
%       hold off;
%
%   See also FCMDEMO, INITFCM, IRISFCM, DISTFCM, STEPFCM.

%   Roger Jang, 12-13-94, N. Hickey 04-16-01
%   Copyright 1994-2002 The MathWorks, Inc.

if nargin ~= 2 & nargin ~= 3,
    error('Too many or too few input arguments!');
end

data_n = size(data, 1);
in_n = size(data, 2);

% Change the following to set default options
default_options = [2;	% exponent for the partition matrix U
    100;	% max. number of iteration
    1e-5;	% min. amount of improvement
    1];	% info display during iteration

if nargin == 2,
    options = default_options;
else
    % If "options" is not fully specified, pad it with default values.
    if length(options) < 4,
        tmp = default_options;
        tmp(1:length(options)) = options;
        options = tmp;
    end
    % If some entries of "options" are nan's, replace them with defaults.
    nan_index = find(isnan(options)==1);
    options(nan_index) = default_options(nan_index);
    if options(1) <= 1,
        error('The exponent should be greater than 1!');
    end
end

expo = options(1);		% Exponent for U
max_iter = options(2);		% Max. iteration
min_impro = options(3);		% Min. improvement
display = options(4);		% Display info or not

obj_fcn = zeros(max_iter, 1);	% Array for objective function

U = initfcm(cluster_n, data_n);			% Initial fuzzy partition
% Main loop
for i = 1:max_iter,
    [U, center, obj_fcn(i)] = stepfcm(data, U, cluster_n, expo);
    if display,
        fprintf('Iteration count = %d, obj. fcn = %f\n', i, obj_fcn(i));
    end
    % check termination condition
    if i > 1,
        if abs(obj_fcn(i) - obj_fcn(i-1)) < min_impro, break; end,
    end
end

iter_n = i;	% Actual number of iterations
obj_fcn(iter_n+1:max_iter) = [];
end

function U = initfcm(cluster_n, data_n)
%INITFCM Generate initial fuzzy partition matrix for fuzzy c-means clustering.
%   U = INITFCM(CLUSTER_N, DATA_N) randomly generates a fuzzy partition
%   matrix U that is CLUSTER_N by DATA_N, where CLUSTER_N is number of
%   clusters and DATA_N is number of data points. The summation of each
%   column of the generated U is equal to unity, as required by fuzzy
%   c-means clustering.
%
%       See also DISTFCM, FCMDEMO, IRISFCM, STEPFCM, FCM.

%   Roger Jang, 12-1-94.
%   Copyright 1994-2002 The MathWorks, Inc.

U = rand(cluster_n, data_n);
col_sum = sum(U);
U = U./col_sum(ones(cluster_n, 1), :);
end

function [U_new, center, obj_fcn] = stepfcm(data, U, cluster_n, expo)
%STEPFCM One step in fuzzy c-mean clustering.
%   [U_NEW, CENTER, ERR] = STEPFCM(DATA, U, CLUSTER_N, EXPO)
%   performs one iteration of fuzzy c-mean clustering, where
%
%   DATA: matrix of data to be clustered. (Each row is a data point.)
%   U: partition matrix. (U(i,j) is the MF value of data j in cluster j.)
%   CLUSTER_N: number of clusters.
%   EXPO: exponent (> 1) for the partition matrix.
%   U_NEW: new partition matrix.
%   CENTER: center of clusters. (Each row is a center.)
%   ERR: objective function for partition U.
%
%   Note that the situation of "singularity" (one of the data points is
%   exactly the same as one of the cluster centers) is not checked.
%   However, it hardly occurs in practice.
%
%       See also DISTFCM, INITFCM, IRISFCM, FCMDEMO, FCM.

%   Copyright 1994-2014 The MathWorks, Inc.

mf = U.^expo;       % MF matrix after exponential modification
center = mf*data./(sum(mf,2)*ones(1,size(data,2))); %new center
dist = distfcm(center, data);       % fill the distance matrix
obj_fcn = sum(sum((dist.^2).*mf));  % objective function
tmp = dist.^(-2/(expo-1));      % calculate new U, suppose expo != 1
U_new = tmp./(ones(cluster_n, 1)*sum(tmp));
end

function out = distfcm(center, data)
%DISTFCM Distance measure in fuzzy c-mean clustering.
%	OUT = DISTFCM(CENTER, DATA) calculates the Euclidean distance
%	between each row in CENTER and each row in DATA, and returns a
%	distance matrix OUT of size M by N, where M and N are row
%	dimensions of CENTER and DATA, respectively, and OUT(I, J) is
%	the distance between CENTER(I,:) and DATA(J,:).
%
%       See also FCMDEMO, INITFCM, IRISFCM, STEPFCM, and FCM.

%	Roger Jang, 11-22-94, 6-27-95.
%       Copyright 1994-2016 The MathWorks, Inc.

out = zeros(size(center, 1), size(data, 1));

% fill the output matrix

if size(center, 2) > 1
    for k = 1:size(center, 1)
        out(k, :) = sqrt(sum(((data-ones(size(data, 1), 1)*center(k, :)).^2), 2));
    end
else	% 1-D data
    for k = 1:size(center, 1)
        out(k, :) = abs(center(k)-data)';
    end
end
end
