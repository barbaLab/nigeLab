function class = proportional_clustering(features,centers,p,varargin)
%% PROPORTIONAL_CLUSTERING  Match templates while maintaining proportions
%
%   class = PROPORTIONAL_CLUSTERING(features,centers,p,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   features    :   N observations (rows) by K features (variables; cols)
%                   matrix of features to match to the "cluster centers" in
%                   centers matrix.
%
%    centers    :   C (rows) by K features (variables; cols)
%                   matrix of target cluster centers.
%
%      p        :   C (rows) by 1 vector of cluster proportions.
%
%   --------
%    OUTPUT
%   --------
%     class     :   N observations (rows) by 1 vector of class (cluster)
%                   assignments for each observation in features.
%
% By: Max Murphy    v1.0    08/11/2017  Original version (R2017a)

%% DEFAULTS
N = size(features,1);
K = size(features,2);
C = size(centers,1);

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if abs(size(centers,2)-K) > eps
    error('Centers and features must have same # variables (columns).');
end

class = zeros(N,1);

%% GET NUMBER FOR EACH CLUSTER CENTER
p = round(p * N);
pdiff = N - sum(p);
p(1) = p(1) + pdiff;

[~,size_order] = sort(p,'ascend'); 

%% GET "PREFERRED" CLUSTER CENTERS
distances = nan(N,C);
prefs = nan(N,C);

for iN = 1:N
    distances(iN,:) = sqrt(sum((ones(size(centers,1),1)...
                      * features(iN,:)- centers).^2,2).');
    
    [distances(iN,:),prefs(iN,:)] = sort(distances(iN,:),'ascend');
    
end

%% ASSIGN CLUSTERS
orig = 1:N;
full = false(1,C);
assigned = [];
for iP = 1:C % Go sequentially through each "preference"
    for iC = reshape(size_order,1,numel(size_order)) % Each time, assign smallest guys first
        orig = setdiff(orig,assigned); % Remove assigned observations
        assigned = [];
        this = prefs(orig,iP); % Get rankings for "this" pref. ranking
        dists = distances(orig,iP);
        if ~full
            [~,ind]  = sort(dists(abs(this-iC)<eps),'ascend');
            assigned = orig(ind(1:min(p(iC),numel(ind))));
            class(assigned)  = iC;
        end
    end
end



end